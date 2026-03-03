/// Dialog for smoke-testing all endpoints in a collection.
///
/// Iterates through every request in a collection, executes it, and reports
/// pass/fail based on basic assertions: status code must not be 5xx and
/// response time must be under a configurable threshold.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/courier_enums.dart';
import '../../models/courier_models.dart';
import '../../providers/courier_providers.dart';
import '../../providers/team_providers.dart';
import '../../services/courier/http_execution_service.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

/// Result of testing a single endpoint.
class EndpointTestResult {
  /// Request name or URL.
  final String name;

  /// HTTP method.
  final CourierHttpMethod method;

  /// URL tested.
  final String url;

  /// Response status code, or null on error.
  final int? statusCode;

  /// Response time in ms.
  final int durationMs;

  /// Whether the test passed (not 5xx, under threshold).
  final bool passed;

  /// Error or failure reason.
  final String? error;

  /// Creates an [EndpointTestResult].
  const EndpointTestResult({
    required this.name,
    required this.method,
    required this.url,
    this.statusCode,
    required this.durationMs,
    required this.passed,
    this.error,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Dialog that runs all requests in a collection as a quick smoke test.
///
/// Uses [HttpExecutionService] to fire each request and checks:
/// - Status code is not 5xx
/// - Response time is under [_thresholdMs]
class TestAllEndpointsDialog extends ConsumerStatefulWidget {
  /// The collection ID to test.
  final String collectionId;

  /// The collection name (for display).
  final String collectionName;

  /// Creates a [TestAllEndpointsDialog].
  const TestAllEndpointsDialog({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  ConsumerState<TestAllEndpointsDialog> createState() =>
      _TestAllEndpointsDialogState();
}

class _TestAllEndpointsDialogState
    extends ConsumerState<TestAllEndpointsDialog> {
  static const int _thresholdMs = 5000;

  bool _running = false;
  bool _done = false;
  final _results = <EndpointTestResult>[];
  int _total = 0;
  int _current = 0;

  Future<void> _runAll() async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;

    setState(() {
      _running = true;
      _done = false;
      _results.clear();
    });

    final api = ref.read(courierApiProvider);
    final execService = ref.read(httpExecutionServiceProvider);

    // Fetch collection tree and collect request IDs.
    final tree =
        await api.getCollectionTree(teamId, widget.collectionId);
    final requestIds = <String>[];
    _collectRequestIds(tree, requestIds);

    setState(() => _total = requestIds.length);

    for (var i = 0; i < requestIds.length; i++) {
      if (!mounted) return;
      setState(() => _current = i + 1);

      try {
        final req = await api.getRequest(teamId, requestIds[i]);
        final method = req.method ?? CourierHttpMethod.get;
        final url = req.url ?? '';
        final name = req.name ?? url;

        if (url.isEmpty) {
          _results.add(EndpointTestResult(
            name: name,
            method: method,
            url: url,
            durationMs: 0,
            passed: false,
            error: 'Empty URL',
          ));
          continue;
        }

        final result = await execService.execute(HttpExecutionRequest(
          method: method,
          url: url,
        ));

        final status = result.statusCode;
        final is5xx = status != null && status >= 500;
        final tooSlow = result.durationMs > _thresholdMs;
        final passed = result.error == null && !is5xx && !tooSlow;

        String? error;
        if (result.error != null) {
          error = result.error;
        } else if (is5xx) {
          error = 'Server error ($status)';
        } else if (tooSlow) {
          error = 'Too slow (${result.durationMs}ms > ${_thresholdMs}ms)';
        }

        _results.add(EndpointTestResult(
          name: name,
          method: method,
          url: url,
          statusCode: status,
          durationMs: result.durationMs,
          passed: passed,
          error: error,
        ));
      } catch (e) {
        _results.add(EndpointTestResult(
          name: requestIds[i],
          method: CourierHttpMethod.get,
          url: '',
          durationMs: 0,
          passed: false,
          error: e.toString(),
        ));
      }

      if (mounted) setState(() {});
    }

    if (mounted) {
      setState(() {
        _running = false;
        _done = true;
      });
    }
  }

  void _collectRequestIds(
      List<FolderTreeResponse> tree, List<String> ids) {
    for (final folder in tree) {
      for (final req in folder.requests ?? <RequestSummaryResponse>[]) {
        if (req.id != null) ids.add(req.id!);
      }
      if (folder.subFolders != null) {
        _collectRequestIds(folder.subFolders!, ids);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final passCount = _results.where((r) => r.passed).length;
    final failCount = _results.where((r) => !r.passed).length;

    return Dialog(
      key: const Key('test_all_endpoints_dialog'),
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 520,
        height: 480,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.science_outlined,
                      size: 18, color: CodeOpsColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test All Endpoints — ${widget.collectionName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CodeOpsColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: CodeOpsColors.textTertiary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Progress ────────────────────────────────────────────
              if (_running || _done) ...[
                Row(
                  children: [
                    Text(
                      _done
                          ? 'Complete — $_current/$_total'
                          : 'Running $_current/$_total...',
                      style: const TextStyle(
                          fontSize: 12, color: CodeOpsColors.textSecondary),
                    ),
                    const Spacer(),
                    _CountBadge(
                      key: const Key('pass_count'),
                      label: '$passCount passed',
                      color: CodeOpsColors.success,
                    ),
                    const SizedBox(width: 6),
                    _CountBadge(
                      key: const Key('fail_count'),
                      label: '$failCount failed',
                      color:
                          failCount > 0 ? CodeOpsColors.error : CodeOpsColors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_running)
                  LinearProgressIndicator(
                    value: _total > 0 ? _current / _total : null,
                    backgroundColor: CodeOpsColors.background,
                    color: CodeOpsColors.primary,
                    minHeight: 3,
                  ),
                const SizedBox(height: 8),
              ],

              // ── Results list ────────────────────────────────────────
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          _running
                              ? 'Starting...'
                              : 'Click "Run All" to start testing.',
                          style: const TextStyle(
                              fontSize: 13,
                              color: CodeOpsColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        key: const Key('results_list'),
                        itemCount: _results.length,
                        itemBuilder: (_, i) =>
                            _ResultTile(result: _results[i]),
                      ),
              ),
              const SizedBox(height: 12),

              // ── Actions ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('run_all_button'),
                    onPressed: _running ? null : _runAll,
                    icon: _running
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow, size: 16),
                    label: Text(
                      _running ? 'Running...' : 'Run All',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: CodeOpsColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final EndpointTestResult result;

  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            result.passed ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: result.passed ? CodeOpsColors.success : CodeOpsColors.error,
          ),
          const SizedBox(width: 8),
          Text(
            result.method.displayName,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              result.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: CodeOpsColors.textPrimary),
            ),
          ),
          if (result.statusCode != null)
            Text(
              '${result.statusCode}',
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textSecondary),
            ),
          const SizedBox(width: 8),
          Text(
            '${result.durationMs}ms',
            style: const TextStyle(
                fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CountBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
