/// Response status bar for Courier.
///
/// Compact bar displaying status code (color-coded), response time,
/// response size, and a save dropdown.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/courier_providers.dart';
import '../../services/courier/http_execution_service.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ResponseStatusBar
// ─────────────────────────────────────────────────────────────────────────────

/// Compact status bar at the top of the response pane.
///
/// Displays `[200 OK] | 143 ms | 2.4 KB | [Save ▾]`. Color-codes the status
/// badge: 2xx=green, 3xx=blue, 4xx=amber, 5xx=red.
class ResponseStatusBar extends ConsumerWidget {
  /// Creates a [ResponseStatusBar].
  const ResponseStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(executionResultProvider);

    return Container(
      key: const Key('response_status_bar'),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: result == null
          ? const _PlaceholderBar()
          : _ResultBar(result: result),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlaceholderBar
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderBar extends StatelessWidget {
  const _PlaceholderBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Status: —',
          key: Key('status_placeholder'),
          style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
        ),
        SizedBox(width: 16),
        Text(
          'Time: —',
          style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
        ),
        SizedBox(width: 16),
        Text(
          'Size: —',
          style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ResultBar
// ─────────────────────────────────────────────────────────────────────────────

class _ResultBar extends StatelessWidget {
  final HttpExecutionResult result;

  const _ResultBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final code = result.statusCode;
    final statusColor = _statusColor(code);

    return Row(
      children: [
        // Status badge.
        if (code != null)
          Container(
            key: const Key('status_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withAlpha(100)),
            ),
            child: Text(
              '$code ${result.statusText ?? ''}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          )
        else if (result.error != null)
          Container(
            key: const Key('status_error_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: CodeOpsColors.error.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Error',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CodeOpsColors.error,
              ),
            ),
          ),
        const SizedBox(width: 12),
        // Divider.
        _divider(),
        const SizedBox(width: 12),
        // Response time.
        Text(
          '${result.durationMs} ms',
          key: const Key('response_time'),
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        _divider(),
        const SizedBox(width: 12),
        // Response size.
        Text(
          _formatSize(result.responseSize),
          key: const Key('response_size'),
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        const Spacer(),
        // Save dropdown.
        _SaveResponseDropdown(result: result),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 14,
        color: CodeOpsColors.border,
      );

  /// Returns color for the HTTP status code range.
  static Color _statusColor(int? code) {
    if (code == null) return CodeOpsColors.textTertiary;
    if (code < 200) return CodeOpsColors.textSecondary;
    if (code < 300) return CodeOpsColors.success;
    if (code < 400) return const Color(0xFF60A5FA); // blue
    if (code < 500) return CodeOpsColors.warning;
    return CodeOpsColors.error;
  }

  /// Formats byte size to human-readable string.
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SaveResponseDropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SaveResponseDropdown extends StatelessWidget {
  final HttpExecutionResult result;

  const _SaveResponseDropdown({required this.result});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('save_response_dropdown'),
      tooltip: 'Save response',
      color: CodeOpsColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: CodeOpsColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save',
              style:
                  TextStyle(fontSize: 11, color: CodeOpsColors.textSecondary),
            ),
            SizedBox(width: 2),
            Icon(Icons.arrow_drop_down,
                size: 14, color: CodeOpsColors.textSecondary),
          ],
        ),
      ),
      onSelected: (v) {
        if (v == 'copy' && result.body != null) {
          Clipboard.setData(ClipboardData(text: result.body!));
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'save_file',
          child: Text('Save Response to File',
              style:
                  TextStyle(fontSize: 12, color: CodeOpsColors.textPrimary)),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Text('Copy Response Body',
              style:
                  TextStyle(fontSize: 12, color: CodeOpsColors.textPrimary)),
        ),
      ],
    );
  }
}
