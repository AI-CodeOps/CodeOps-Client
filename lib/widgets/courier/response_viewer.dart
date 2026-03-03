/// Response viewer for Courier.
///
/// Right pane of the Courier three-pane layout. Displays the HTTP response
/// after a request is sent, including body (Pretty/Raw/Preview/Visualize),
/// headers, cookies, and test results tabs. Handles empty, loading, and
/// error states.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/courier_providers.dart';
import '../../providers/courier_ui_providers.dart';
import '../../services/courier/http_execution_service.dart';
import '../../theme/colors.dart';
import '../scribe/scribe_editor.dart';
import 'response_cookies_tab.dart';
import 'response_headers_tab.dart';
import 'response_status_bar.dart';
import 'response_test_results_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ResponseViewer
// ─────────────────────────────────────────────────────────────────────────────

/// Right pane — HTTP response viewer.
///
/// Shows empty state until a request is sent, then displays the response body,
/// headers, cookies, and test results in a tabbed layout with a status bar.
class ResponseViewer extends ConsumerStatefulWidget {
  /// Creates a [ResponseViewer].
  const ResponseViewer({super.key});

  @override
  ConsumerState<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends ConsumerState<ResponseViewer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionStateProvider);
    final result = ref.watch(executionResultProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status bar.
        const ResponseStatusBar(),
        // Tab bar.
        _ResponseTabBar(
          controller: _tabController,
          result: result,
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        // Content.
        Expanded(
          child: _buildContent(execState, result),
        ),
      ],
    );
  }

  Widget _buildContent(ExecutionState execState, HttpExecutionResult? result) {
    // Loading state.
    if (execState.status == ExecutionStatus.running) {
      return const _LoadingState();
    }

    // Error state (from execution, not HTTP error codes).
    if (execState.status == ExecutionStatus.error) {
      return _ErrorState(error: execState.error ?? 'Unknown error');
    }

    // Error in result (network/timeout/SSL).
    if (result != null && result.error != null) {
      return _ErrorState(error: result.error!);
    }

    // No result yet — empty state.
    if (result == null) {
      return const _EmptyState();
    }

    // Response received.
    return TabBarView(
      controller: _tabController,
      children: [
        _ResponseBodyTab(result: result),
        ResponseHeadersTab(headers: result.responseHeaders),
        ResponseCookiesTab(headers: result.responseHeaders),
        const ResponseTestResultsTab(results: []),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ResponseTabBar
// ─────────────────────────────────────────────────────────────────────────────

class _ResponseTabBar extends StatelessWidget {
  final TabController controller;
  final HttpExecutionResult? result;

  const _ResponseTabBar({required this.controller, this.result});

  @override
  Widget build(BuildContext context) {
    final headerCount = result?.responseHeaders.length ?? 0;
    final cookieCount = result?.responseHeaders.entries
            .where((e) => e.key.toLowerCase() == 'set-cookie')
            .length ??
        0;

    return Container(
      color: CodeOpsColors.surface,
      child: TabBar(
        key: const Key('response_tab_bar'),
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: CodeOpsColors.primary,
        unselectedLabelColor: CodeOpsColors.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        indicatorColor: CodeOpsColors.primary,
        indicatorWeight: 2,
        tabs: [
          const Tab(text: 'Body', height: 36),
          Tab(
            height: 36,
            child: Text(headerCount > 0
                ? 'Headers ($headerCount)'
                : 'Headers'),
          ),
          Tab(
            height: 36,
            child:
                Text(cookieCount > 0 ? 'Cookies ($cookieCount)' : 'Cookies'),
          ),
          const Tab(text: 'Test Results', height: 36),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('response_empty_state'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.send_outlined,
            size: 48,
            color: CodeOpsColors.textTertiary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          const Text(
            'Click Send to get a response',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Or press Ctrl+Enter',
            style:
                TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LoadingState
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('response_loading_state'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(CodeOpsColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sending request...',
            style: TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorState
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final tip = _troubleshootingTip(error);

    return Center(
      key: const Key('response_error_state'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: CodeOpsColors.error),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.error,
              ),
            ),
            if (tip != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CodeOpsColors.warning.withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: CodeOpsColors.warning.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: CodeOpsColors.warning),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        tip,
                        key: const Key('error_tip'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: CodeOpsColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _troubleshootingTip(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('connection error') || lower.contains('could not connect')) {
      return 'Could not connect. Check the URL and your network connection.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'Request timed out. Increase timeout in the Settings tab.';
    }
    if (lower.contains('ssl') || lower.contains('certificate')) {
      return 'SSL certificate verification failed. Disable SSL verification in Settings.';
    }
    if (lower.contains('dns') || lower.contains('resolve')) {
      return 'Could not resolve hostname. Check the URL for typos.';
    }
    if (lower.contains('cancelled')) {
      return null; // No tip for user-initiated cancellation.
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ResponseBodyTab
// ─────────────────────────────────────────────────────────────────────────────

/// Body view mode.
enum _BodyViewMode { pretty, raw, preview, visualize }

class _ResponseBodyTab extends StatefulWidget {
  final HttpExecutionResult result;

  const _ResponseBodyTab({required this.result});

  @override
  State<_ResponseBodyTab> createState() => _ResponseBodyTabState();
}

class _ResponseBodyTabState extends State<_ResponseBodyTab> {
  _BodyViewMode _viewMode = _BodyViewMode.pretty;
  bool _wordWrap = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final body = widget.result.body ?? '';
    final isLarge = body.length > 1024 * 1024; // >1MB

    return Column(
      key: const Key('response_body_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Body toolbar.
        _BodyToolbar(
          viewMode: _viewMode,
          wordWrap: _wordWrap,
          searchQuery: _searchQuery,
          onViewModeChanged: (m) => setState(() => _viewMode = m),
          onWordWrapToggled: () =>
              setState(() => _wordWrap = !_wordWrap),
          onSearchChanged: (q) => setState(() => _searchQuery = q),
          onCopy: () =>
              Clipboard.setData(ClipboardData(text: body)),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Large response warning.
        if (isLarge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: CodeOpsColors.warning.withAlpha(15),
            child: Row(
              children: [
                const Icon(Icons.warning_amber,
                    size: 14, color: CodeOpsColors.warning),
                const SizedBox(width: 6),
                Text(
                  'Large response (${(body.length / (1024 * 1024)).toStringAsFixed(1)} MB). '
                  'Syntax highlighting disabled for performance.',
                  key: const Key('large_response_warning'),
                  style: const TextStyle(
                      fontSize: 11, color: CodeOpsColors.warning),
                ),
              ],
            ),
          ),
        // Body content.
        Expanded(
          child: body.isEmpty
              ? const Center(
                  child: Text(
                    'Empty response body',
                    key: Key('body_empty'),
                    style: TextStyle(
                        fontSize: 12, color: CodeOpsColors.textTertiary),
                  ),
                )
              : _buildBodyView(body, isLarge),
        ),
      ],
    );
  }

  Widget _buildBodyView(String body, bool isLarge) {
    switch (_viewMode) {
      case _BodyViewMode.pretty:
        return _PrettyView(
          body: body,
          contentType: _contentType,
          wordWrap: _wordWrap,
          disableHighlighting: isLarge,
        );
      case _BodyViewMode.raw:
        return _RawView(body: body, wordWrap: _wordWrap);
      case _BodyViewMode.preview:
        return _PreviewView(
            body: body, contentType: _contentType);
      case _BodyViewMode.visualize:
        return _VisualizeView(body: body);
    }
  }

  String get _contentType {
    final ct = widget.result.responseHeaders.entries
        .where(
            (e) => e.key.toLowerCase() == 'content-type')
        .map((e) => e.value)
        .firstOrNull;
    return ct ?? '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BodyToolbar
// ─────────────────────────────────────────────────────────────────────────────

class _BodyToolbar extends StatelessWidget {
  final _BodyViewMode viewMode;
  final bool wordWrap;
  final String searchQuery;
  final ValueChanged<_BodyViewMode> onViewModeChanged;
  final VoidCallback onWordWrapToggled;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCopy;

  const _BodyToolbar({
    required this.viewMode,
    required this.wordWrap,
    required this.searchQuery,
    required this.onViewModeChanged,
    required this.onWordWrapToggled,
    required this.onSearchChanged,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          // View mode toggle buttons.
          _ViewModeButton(
            key: const Key('view_pretty'),
            label: 'Pretty',
            active: viewMode == _BodyViewMode.pretty,
            onTap: () => onViewModeChanged(_BodyViewMode.pretty),
          ),
          const SizedBox(width: 2),
          _ViewModeButton(
            key: const Key('view_raw'),
            label: 'Raw',
            active: viewMode == _BodyViewMode.raw,
            onTap: () => onViewModeChanged(_BodyViewMode.raw),
          ),
          const SizedBox(width: 2),
          _ViewModeButton(
            key: const Key('view_preview'),
            label: 'Preview',
            active: viewMode == _BodyViewMode.preview,
            onTap: () => onViewModeChanged(_BodyViewMode.preview),
          ),
          const SizedBox(width: 2),
          _ViewModeButton(
            key: const Key('view_visualize'),
            label: 'Visualize',
            active: viewMode == _BodyViewMode.visualize,
            onTap: () => onViewModeChanged(_BodyViewMode.visualize),
          ),
          const SizedBox(width: 12),
          // Search field.
          SizedBox(
            width: 160,
            height: 24,
            child: TextField(
              key: const Key('body_search_field'),
              onChanged: onSearchChanged,
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search body...',
                hintStyle: const TextStyle(
                    fontSize: 11, color: CodeOpsColors.textTertiary),
                prefixIcon: const Icon(Icons.search,
                    size: 14, color: CodeOpsColors.textTertiary),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 28, minHeight: 0),
                filled: true,
                fillColor: CodeOpsColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: CodeOpsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: CodeOpsColors.border),
                ),
                isDense: true,
              ),
            ),
          ),
          const Spacer(),
          // Word wrap toggle.
          IconButton(
            key: const Key('word_wrap_toggle'),
            onPressed: onWordWrapToggled,
            icon: Icon(
              Icons.wrap_text,
              size: 14,
              color: wordWrap
                  ? CodeOpsColors.primary
                  : CodeOpsColors.textTertiary,
            ),
            iconSize: 14,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Toggle word wrap',
          ),
          // Copy button.
          IconButton(
            key: const Key('copy_body_button'),
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 14),
            iconSize: 14,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Copy body',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ViewModeButton
// ─────────────────────────────────────────────────────────────────────────────

class _ViewModeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ViewModeButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? CodeOpsColors.primary.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? CodeOpsColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active
                ? CodeOpsColors.primary
                : CodeOpsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PrettyView
// ─────────────────────────────────────────────────────────────────────────────

class _PrettyView extends StatelessWidget {
  final String body;
  final String contentType;
  final bool wordWrap;
  final bool disableHighlighting;

  const _PrettyView({
    required this.body,
    required this.contentType,
    required this.wordWrap,
    this.disableHighlighting = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = _formatBody(body, contentType);
    final language = disableHighlighting
        ? 'plaintext'
        : _detectLanguage(contentType);

    return ScribeEditor(
      key: const Key('pretty_view'),
      content: formatted,
      language: language,
      readOnly: true,
      showLineNumbers: true,
      wordWrap: wordWrap,
      fontSize: 12,
    );
  }

  /// Attempts to pretty-print the body based on content type.
  static String _formatBody(String body, String contentType) {
    if (_isJson(contentType) || _looksLikeJson(body)) {
      try {
        final parsed = jsonDecode(body);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      } catch (_) {
        return body;
      }
    }
    return body;
  }

  static String _detectLanguage(String contentType) {
    final ct = contentType.toLowerCase();
    if (ct.contains('json')) return 'json';
    if (ct.contains('xml')) return 'xml';
    if (ct.contains('html')) return 'html';
    if (ct.contains('yaml')) return 'yaml';
    if (ct.contains('javascript')) return 'javascript';
    if (ct.contains('css')) return 'css';
    return 'plaintext';
  }

  static bool _isJson(String ct) => ct.toLowerCase().contains('json');
  static bool _looksLikeJson(String body) {
    final trimmed = body.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RawView
// ─────────────────────────────────────────────────────────────────────────────

class _RawView extends StatelessWidget {
  final String body;
  final bool wordWrap;

  const _RawView({required this.body, required this.wordWrap});

  @override
  Widget build(BuildContext context) {
    return ScribeEditor(
      key: const Key('raw_view'),
      content: body,
      language: 'plaintext',
      readOnly: true,
      showLineNumbers: true,
      wordWrap: wordWrap,
      fontSize: 12,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PreviewView
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  final String body;
  final String contentType;

  const _PreviewView({required this.body, required this.contentType});

  @override
  Widget build(BuildContext context) {
    final ct = contentType.toLowerCase();

    // HTML preview — render as selectable text with basic formatting note.
    if (ct.contains('html')) {
      return SingleChildScrollView(
        key: const Key('preview_html'),
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          body,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: CodeOpsColors.textPrimary,
          ),
        ),
      );
    }

    // For other types, show a message and the raw body.
    return Center(
      key: const Key('preview_unsupported'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.preview,
              size: 32, color: CodeOpsColors.textTertiary),
          const SizedBox(height: 8),
          Text(
            'Preview not available for ${ct.isEmpty ? 'this content type' : ct}',
            style: const TextStyle(
                fontSize: 12, color: CodeOpsColors.textTertiary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use Pretty or Raw view instead',
            style: TextStyle(
                fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VisualizeView
// ─────────────────────────────────────────────────────────────────────────────

class _VisualizeView extends StatelessWidget {
  final String body;

  const _VisualizeView({required this.body});

  @override
  Widget build(BuildContext context) {
    // Try to parse as JSON array for table visualization.
    try {
      final parsed = jsonDecode(body);
      if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
        return _JsonTable(data: parsed.cast<Map<String, dynamic>>());
      }
    } catch (_) {
      // Not a JSON array.
    }

    return const Center(
      key: Key('visualize_unsupported'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.table_chart, size: 32, color: CodeOpsColors.textTertiary),
          SizedBox(height: 8),
          Text(
            'Visualization requires a JSON array response',
            style:
                TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
          ),
          SizedBox(height: 4),
          Text(
            'e.g. [{"id": 1, "name": "..."}, ...]',
            style:
                TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _JsonTable
// ─────────────────────────────────────────────────────────────────────────────

class _JsonTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _JsonTable({required this.data});

  @override
  Widget build(BuildContext context) {
    // Collect all unique keys for columns.
    final columns = <String>{};
    for (final row in data) {
      columns.addAll(row.keys);
    }
    final cols = columns.toList()..sort();

    return SingleChildScrollView(
      key: const Key('json_table'),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(CodeOpsColors.surface),
          dataRowColor: WidgetStateProperty.all(Colors.transparent),
          border: TableBorder.all(color: CodeOpsColors.border, width: 0.5),
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: CodeOpsColors.textSecondary,
          ),
          columns: cols
              .map((c) => DataColumn(label: Text(c)))
              .toList(),
          rows: data.map((row) {
            return DataRow(
              cells: cols.map((c) {
                final val = row[c];
                return DataCell(Text(
                  val?.toString() ?? '',
                  overflow: TextOverflow.ellipsis,
                ));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
