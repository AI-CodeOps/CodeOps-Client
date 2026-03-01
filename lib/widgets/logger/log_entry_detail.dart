/// Expanded log entry detail panel.
///
/// Shows the full log message, metadata fields (source, service, host,
/// logger, thread), stack trace, custom fields (JSON), correlation/trace
/// IDs with navigation links, and a copy-to-clipboard button.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';
import 'log_level_badge.dart';

/// Displays full details for a single [LogEntryResponse].
///
/// Rendered as an expandable panel below the log entry row.
/// Includes metadata table, stack trace block, custom fields,
/// and action buttons for copying and trace navigation.
class LogEntryDetail extends StatelessWidget {
  /// The log entry to display.
  final LogEntryResponse entry;

  /// Creates a [LogEntryDetail].
  const LogEntryDetail({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          left: BorderSide(color: CodeOpsColors.primary, width: 3),
          bottom: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with level badge and actions.
          Row(
            children: [
              LogLevelBadge(level: entry.level),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.message,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                color: CodeOpsColors.textSecondary,
                tooltip: 'Copy log entry',
                onPressed: () => _copyEntry(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metadata table.
          _buildMetadataTable(),

          // Correlation / trace IDs.
          if (entry.correlationId != null || entry.traceId != null) ...[
            const SizedBox(height: 12),
            _buildTraceSection(context),
          ],

          // Stack trace.
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 12),
            _buildStackTrace(),
          ],

          // Custom fields (JSON).
          if (entry.customFields != null &&
              entry.customFields!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCustomFields(),
          ],
        ],
      ),
    );
  }

  /// Builds the metadata key-value table.
  Widget _buildMetadataTable() {
    final rows = <MapEntry<String, String>>[
      MapEntry('Source', '${entry.sourceName} (${entry.sourceId.length > 8 ? entry.sourceId.substring(0, 8) : entry.sourceId})'),
      MapEntry('Service', entry.serviceName),
      MapEntry('Timestamp', entry.timestamp.toIso8601String()),
    ];
    if (entry.hostName != null) {
      rows.add(MapEntry('Host', entry.hostName!));
    }
    if (entry.ipAddress != null) {
      rows.add(MapEntry('IP Address', entry.ipAddress!));
    }
    if (entry.loggerName != null) {
      rows.add(MapEntry('Logger', entry.loggerName!));
    }
    if (entry.threadName != null) {
      rows.add(MapEntry('Thread', entry.threadName!));
    }
    if (entry.exceptionClass != null) {
      rows.add(MapEntry('Exception', entry.exceptionClass!));
    }
    if (entry.exceptionMessage != null) {
      rows.add(MapEntry('Exception Message', entry.exceptionMessage!));
    }

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: rows.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${e.key}: ',
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
            Flexible(
              child: Text(
                e.value,
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Builds the trace/correlation ID section with clickable links.
  Widget _buildTraceSection(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (entry.correlationId != null)
          InkWell(
            onTap: () => context.go('/logger/traces/${entry.correlationId}'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, size: 14, color: CodeOpsColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Correlation: ${entry.correlationId}',
                  style: const TextStyle(
                    color: CodeOpsColors.primary,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        if (entry.traceId != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_tree,
                size: 14,
                color: CodeOpsColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'Trace: ${entry.traceId}',
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        if (entry.spanId != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.segment,
                size: 14,
                color: CodeOpsColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'Span: ${entry.spanId}',
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Builds the stack trace code block.
  Widget _buildStackTrace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stack Trace',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CodeOpsColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: SelectableText(
            entry.stackTrace!,
            style: const TextStyle(
              color: CodeOpsColors.error,
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the custom fields JSON block.
  Widget _buildCustomFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Fields',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CodeOpsColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: SelectableText(
            entry.customFields!,
            style: const TextStyle(
              color: CodeOpsColors.secondary,
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Copies a formatted representation of the entry to the clipboard.
  void _copyEntry(BuildContext context) {
    final buffer = StringBuffer()
      ..writeln('[${entry.level.displayName.toUpperCase()}] ${entry.timestamp.toIso8601String()}')
      ..writeln('Service: ${entry.serviceName}')
      ..writeln('Source: ${entry.sourceName}')
      ..writeln('Message: ${entry.message}');
    if (entry.correlationId != null) {
      buffer.writeln('Correlation ID: ${entry.correlationId}');
    }
    if (entry.traceId != null) {
      buffer.writeln('Trace ID: ${entry.traceId}');
    }
    if (entry.stackTrace != null) {
      buffer.writeln('Stack Trace:\n${entry.stackTrace}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log entry copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
