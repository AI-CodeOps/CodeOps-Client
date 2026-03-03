/// Script execution console for Courier.
///
/// Displays console output from `console.log()`, test results (pass/fail),
/// and script execution errors with timestamps and clear button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/courier_ui_providers.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScriptConsole
// ─────────────────────────────────────────────────────────────────────────────

/// Bottom panel showing script execution output, test results, and errors.
///
/// Reads from [scriptConsoleProvider] and renders each [ConsoleEntry] with
/// color-coded type indicators and timestamps.
class ScriptConsole extends ConsumerWidget {
  /// Creates a [ScriptConsole].
  const ScriptConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(scriptConsoleProvider);

    return Container(
      key: const Key('script_console'),
      decoration: const BoxDecoration(
        color: CodeOpsColors.background,
        border: Border(
          top: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar.
          _ConsoleHeader(
            entryCount: entries.length,
            onClear: () =>
                ref.read(scriptConsoleProvider.notifier).state = [],
          ),
          const Divider(
              height: 1, thickness: 1, color: CodeOpsColors.border),
          // Entries.
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'No console output',
                      key: Key('console_empty'),
                      style: TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: const Key('console_list'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _ConsoleEntryRow(entry: entries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ConsoleHeader
// ─────────────────────────────────────────────────────────────────────────────

class _ConsoleHeader extends StatelessWidget {
  final int entryCount;
  final VoidCallback onClear;

  const _ConsoleHeader({required this.entryCount, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          const Icon(Icons.terminal, size: 14, color: CodeOpsColors.textSecondary),
          const SizedBox(width: 6),
          const Text(
            'Console',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          if (entryCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: CodeOpsColors.primary.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$entryCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            key: const Key('console_clear_button'),
            onPressed: entryCount > 0 ? onClear : null,
            icon: const Icon(Icons.delete_outline, size: 14),
            iconSize: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Clear console',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ConsoleEntryRow
// ─────────────────────────────────────────────────────────────────────────────

class _ConsoleEntryRow extends StatelessWidget {
  final ConsoleEntry entry;

  const _ConsoleEntryRow({required this.entry});

  static final _timeFmt = DateFormat('HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.type) {
      ConsoleEntryType.log => (Icons.chevron_right, CodeOpsColors.textSecondary),
      ConsoleEntryType.error => (Icons.error_outline, CodeOpsColors.error),
      ConsoleEntryType.testPass => (Icons.check_circle_outline, CodeOpsColors.success),
      ConsoleEntryType.testFail => (Icons.cancel_outlined, CodeOpsColors.error),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp.
          Text(
            _timeFmt.format(entry.timestamp),
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          // Type icon.
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          // Message.
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: entry.type == ConsoleEntryType.error
                    ? CodeOpsColors.error
                    : CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
