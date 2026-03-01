/// Log viewer page with live log stream.
///
/// Full-featured log viewer at `/logger/viewer` providing:
/// - [LoggerSidebar] for sub-page navigation
/// - [LogFilterBar] for source, level, time range, and text filters
/// - [LogEntryList] with auto-scroll, zebra striping, and expandable rows
/// - Auto-polling with configurable pause/resume
/// - Status bar with entry count and pagination
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/log_entry_list.dart';
import '../../widgets/logger/log_filter_bar.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The log viewer page with sidebar, filter bar, and log stream.
class LogViewerPage extends ConsumerStatefulWidget {
  /// Creates a [LogViewerPage].
  const LogViewerPage({super.key});

  @override
  ConsumerState<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends ConsumerState<LogViewerPage> {
  /// Polling interval for live log updates.
  static const _pollInterval = Duration(seconds: 5);

  Timer? _pollTimer;
  bool _isPaused = false;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Starts the polling timer for live updates.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_isPaused && mounted) {
        ref.invalidate(loggerLogsProvider);
      }
    });
  }

  /// Toggles the pause/resume state for polling.
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      _autoScroll = !_isPaused;
    });
  }

  /// Refreshes all log viewer data.
  void _refresh() {
    ref.invalidate(loggerSourcesProvider);
    ref.invalidate(loggerLogsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return Row(
        children: [
          const LoggerSidebar(),
          const VerticalDivider(width: 1, color: CodeOpsColors.border),
          const Expanded(
            child: EmptyState(
              icon: Icons.group_off,
              title: 'No team selected',
              subtitle: 'Select a team to view logs.',
            ),
          ),
        ],
      );
    }

    final sourcesAsync = ref.watch(loggerSourcesProvider);
    final logsAsync = ref.watch(loggerLogsProvider);

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              // Header bar.
              _buildHeader(),

              // Filter bar.
              sourcesAsync.when(
                data: (sources) => LogFilterBar(
                  sources: sources,
                  isPaused: _isPaused,
                  onTogglePause: _togglePause,
                ),
                loading: () => LogFilterBar(
                  sources: const [],
                  isPaused: _isPaused,
                  onTogglePause: _togglePause,
                ),
                error: (_, __) => LogFilterBar(
                  sources: const [],
                  isPaused: _isPaused,
                  onTogglePause: _togglePause,
                ),
              ),

              // Log entries.
              Expanded(
                child: logsAsync.when(
                  data: (logs) => LogEntryList(
                    logs: logs,
                    autoScroll: _autoScroll,
                    onLoadMore: logs.isLast
                        ? null
                        : () {
                            ref
                                .read(loggerLogPageProvider.notifier)
                                .state++;
                          },
                    onLoadPrevious: logs.page == 0
                        ? null
                        : () {
                            ref
                                .read(loggerLogPageProvider.notifier)
                                .state--;
                          },
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: CodeOpsColors.primary,
                    ),
                  ),
                  error: (error, _) => ErrorPanel.fromException(
                    error,
                    onRetry: _refresh,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the top header bar with title, auto-scroll toggle, and refresh.
  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.list_alt,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Log Viewer',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),

          // Auto-scroll toggle.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Auto-scroll',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                child: Switch(
                  value: _autoScroll,
                  onChanged: (value) => setState(() => _autoScroll = value),
                  activeThumbColor: CodeOpsColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Refresh button.
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }
}
