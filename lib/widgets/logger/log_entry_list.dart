/// Scrollable log entry list with level coloring and expandable rows.
///
/// Renders a virtualized list of [LogEntryResponse] items with:
/// - Colored level indicators via [LogLevelBadge]
/// - Zebra-striped rows for readability
/// - Click-to-expand detail panels via [LogEntryDetail]
/// - Auto-scroll to bottom on new entries (when enabled)
/// - Status bar showing entry count and page info
library;

import 'package:flutter/material.dart';

import '../../models/health_snapshot.dart';
import '../../models/logger_models.dart';
import '../../theme/colors.dart';
import 'log_entry_detail.dart';
import 'log_level_badge.dart';

/// A scrollable, virtualized list of log entries.
///
/// Supports auto-scroll to the bottom when [autoScroll] is `true`,
/// zebra-striped rows, click-to-expand detail panels, and displays
/// a status bar with entry count and pagination info.
class LogEntryList extends StatefulWidget {
  /// The paginated log entries to display.
  final PageResponse<LogEntryResponse> logs;

  /// Whether to auto-scroll to the latest entry.
  final bool autoScroll;

  /// Callback invoked to load the next page.
  final VoidCallback? onLoadMore;

  /// Callback invoked to load the previous page.
  final VoidCallback? onLoadPrevious;

  /// Creates a [LogEntryList].
  const LogEntryList({
    super.key,
    required this.logs,
    this.autoScroll = false,
    this.onLoadMore,
    this.onLoadPrevious,
  });

  @override
  State<LogEntryList> createState() => _LogEntryListState();
}

class _LogEntryListState extends State<LogEntryList> {
  final ScrollController _scrollController = ScrollController();
  String? _expandedEntryId;

  @override
  void didUpdateWidget(covariant LogEntryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll &&
        widget.logs.content.length != oldWidget.logs.content.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.logs.content;

    return Column(
      children: [
        // Log entries list.
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text(
                    'No log entries found',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isExpanded = _expandedEntryId == entry.id;
                    final isEvenRow = index.isEven;

                    return Column(
                      children: [
                        _LogEntryRow(
                          entry: entry,
                          isEvenRow: isEvenRow,
                          isExpanded: isExpanded,
                          onTap: () {
                            setState(() {
                              _expandedEntryId =
                                  isExpanded ? null : entry.id;
                            });
                          },
                        ),
                        if (isExpanded) LogEntryDetail(entry: entry),
                      ],
                    );
                  },
                ),
        ),

        // Status bar.
        _buildStatusBar(),
      ],
    );
  }

  /// Builds the bottom status bar with entry count and pagination.
  Widget _buildStatusBar() {
    final logs = widget.logs;
    final start = logs.page * logs.size + 1;
    final end = start + logs.content.length - 1;
    final hasMore = !logs.isLast;
    final hasPrevious = logs.page > 0;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(top: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          Text(
            logs.content.isEmpty
                ? '0 entries'
                : 'Showing $start–$end of ${logs.totalElements} entries',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          if (hasPrevious)
            _StatusBarButton(
              label: 'Previous',
              onTap: widget.onLoadPrevious,
            ),
          if (hasPrevious && hasMore) const SizedBox(width: 8),
          if (hasMore)
            _StatusBarButton(
              label: 'Load More',
              onTap: widget.onLoadMore,
            ),
          const SizedBox(width: 12),
          Text(
            'Page ${logs.page + 1} of ${logs.totalPages}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single log entry row with level dot, timestamp, service, and message.
class _LogEntryRow extends StatelessWidget {
  final LogEntryResponse entry;
  final bool isEvenRow;
  final bool isExpanded;
  final VoidCallback onTap;

  const _LogEntryRow({
    required this.entry,
    required this.isEvenRow,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = LogLevelBadge.colorForLevel(entry.level);

    return Material(
      color: isExpanded
          ? CodeOpsColors.surfaceVariant
          : isEvenRow
              ? CodeOpsColors.background
              : CodeOpsColors.surface.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        hoverColor: CodeOpsColors.surfaceVariant.withValues(alpha: 0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: levelColor, width: 3),
              bottom: const BorderSide(
                color: CodeOpsColors.border,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Level dot.
              LogLevelBadge(level: entry.level, compact: true),
              const SizedBox(width: 8),

              // Timestamp.
              SizedBox(
                width: 140,
                child: Text(
                  _formatTimestamp(entry.timestamp),
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Level label.
              SizedBox(
                width: 48,
                child: Text(
                  entry.level.toJson(),
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Service name.
              SizedBox(
                width: 120,
                child: Text(
                  entry.serviceName,
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Message.
              Expanded(
                child: Text(
                  entry.message,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Expand indicator.
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: CodeOpsColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats a [DateTime] as `HH:mm:ss.SSS` for compact display.
  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m:$s.$ms';
  }
}

/// Small text button for the status bar.
class _StatusBarButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _StatusBarButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: CodeOpsColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
