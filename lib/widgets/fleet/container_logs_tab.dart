/// Logs tab for the container detail page.
///
/// Displays container log output in a scrollable monospace viewer with
/// stream-aware color coding (stdout default, stderr red). Provides
/// a tail-lines selector, auto-scroll toggle, and text search filter.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_models.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'log_line.dart';

/// Displays container logs with filtering and scroll controls.
class ContainerLogsTab extends StatefulWidget {
  /// The list of log entries to display.
  final List<FleetContainerLog> logs;

  /// Callback to reload logs with a new tail count.
  final ValueChanged<int> onTailChanged;

  /// Callback to refresh the logs.
  final VoidCallback onRefresh;

  /// Creates a [ContainerLogsTab].
  const ContainerLogsTab({
    super.key,
    required this.logs,
    required this.onTailChanged,
    required this.onRefresh,
  });

  @override
  State<ContainerLogsTab> createState() => _ContainerLogsTabState();
}

class _ContainerLogsTabState extends State<ContainerLogsTab> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _autoScroll = true;
  int _tailLines = 100;
  String _searchQuery = '';

  @override
  void didUpdateWidget(ContainerLogsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Scrolls to the bottom of the log view.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? widget.logs
        : widget.logs
            .where((log) =>
                (log.content ?? '').toLowerCase().contains(_searchQuery))
            .toList();

    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No logs available',
                    style: TextStyle(color: CodeOpsColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final log = filtered[i];
                    return LogLine(
                      content: log.content ?? '',
                      stream: log.stream,
                      timestamp: log.timestamp,
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Builds the toolbar with tail selector, search, auto-scroll, and refresh.
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          // Tail selector
          const Text('Tail:', style: TextStyle(color: CodeOpsColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _tailLines,
            dropdownColor: CodeOpsColors.surface,
            style: CodeOpsTypography.bodySmall
                .copyWith(color: CodeOpsColors.textPrimary),
            underline: const SizedBox.shrink(),
            isDense: true,
            items: const [
              DropdownMenuItem(value: 50, child: Text('50')),
              DropdownMenuItem(value: 100, child: Text('100')),
              DropdownMenuItem(value: 500, child: Text('500')),
              DropdownMenuItem(value: 1000, child: Text('1000')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _tailLines = v);
                widget.onTailChanged(v);
              }
            },
          ),
          const SizedBox(width: 16),
          // Search
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchController,
                style: CodeOpsTypography.bodySmall
                    .copyWith(color: CodeOpsColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: const TextStyle(
                      color: CodeOpsColors.textTertiary, fontSize: 12),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: CodeOpsColors.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: CodeOpsColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: CodeOpsColors.border),
                  ),
                  filled: true,
                  fillColor: CodeOpsColors.background,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Auto-scroll toggle
          Tooltip(
            message: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            child: IconButton(
              icon: Icon(
                Icons.vertical_align_bottom,
                size: 18,
                color: _autoScroll
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textTertiary,
              ),
              onPressed: () => setState(() => _autoScroll = !_autoScroll),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: CodeOpsColors.textSecondary,
            onPressed: widget.onRefresh,
            tooltip: 'Refresh logs',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
