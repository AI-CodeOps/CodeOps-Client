/// Filter bar for the log viewer page.
///
/// Provides controls for filtering log entries by source, level,
/// time range, and free-text search. Includes a Pause/Resume toggle
/// for auto-polling and a Clear Filters button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../theme/colors.dart';
import 'log_level_badge.dart';

/// A horizontal filter bar for the log viewer.
///
/// Manages filter state through Riverpod [StateProvider]s so that
/// changes automatically trigger a re-fetch via [loggerLogsProvider].
class LogFilterBar extends ConsumerStatefulWidget {
  /// The available log sources for the source dropdown.
  final List<LogSourceResponse> sources;

  /// Whether live polling is currently paused.
  final bool isPaused;

  /// Callback invoked when the pause/resume button is toggled.
  final VoidCallback onTogglePause;

  /// Creates a [LogFilterBar].
  const LogFilterBar({
    super.key,
    required this.sources,
    required this.isPaused,
    required this.onTogglePause,
  });

  @override
  ConsumerState<LogFilterBar> createState() => _LogFilterBarState();
}

class _LogFilterBarState extends ConsumerState<LogFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(loggerLogSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns `true` if any filter is currently active.
  bool get _hasActiveFilters {
    final level = ref.read(loggerLogLevelFilterProvider);
    final service = ref.read(loggerLogServiceFilterProvider);
    final search = ref.read(loggerLogSearchProvider);
    final startTime = ref.read(loggerLogStartTimeProvider);
    final endTime = ref.read(loggerLogEndTimeProvider);
    return level != null ||
        service != null ||
        search.isNotEmpty ||
        startTime != null ||
        endTime != null;
  }

  /// Clears all active filters and resets the page.
  void _clearFilters() {
    ref.read(loggerLogLevelFilterProvider.notifier).state = null;
    ref.read(loggerLogServiceFilterProvider.notifier).state = null;
    ref.read(loggerLogSearchProvider.notifier).state = '';
    ref.read(loggerLogStartTimeProvider.notifier).state = null;
    ref.read(loggerLogEndTimeProvider.notifier).state = null;
    ref.read(loggerLogPageProvider.notifier).state = 0;
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLevel = ref.watch(loggerLogLevelFilterProvider);
    final selectedService = ref.watch(loggerLogServiceFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          // Source dropdown.
          _FilterDropdown<String?>(
            hint: 'All Sources',
            value: selectedService,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Sources')),
              ...widget.sources.map((s) => DropdownMenuItem(
                    value: s.name,
                    child: Text(s.name),
                  )),
            ],
            onChanged: (value) {
              ref.read(loggerLogServiceFilterProvider.notifier).state = value;
              ref.read(loggerLogPageProvider.notifier).state = 0;
            },
          ),
          const SizedBox(width: 8),

          // Level dropdown.
          _FilterDropdown<LogLevel?>(
            hint: 'All Levels',
            value: selectedLevel,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Levels')),
              ...LogLevel.values.map((l) => DropdownMenuItem(
                    value: l,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: LogLevelBadge.colorForLevel(l),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(l.displayName),
                      ],
                    ),
                  )),
            ],
            onChanged: (value) {
              ref.read(loggerLogLevelFilterProvider.notifier).state = value;
              ref.read(loggerLogPageProvider.notifier).state = 0;
            },
          ),
          const SizedBox(width: 8),

          // Time range selector.
          _TimeRangeButton(
            startTime: ref.watch(loggerLogStartTimeProvider),
            endTime: ref.watch(loggerLogEndTimeProvider),
            onChanged: (start, end) {
              ref.read(loggerLogStartTimeProvider.notifier).state = start;
              ref.read(loggerLogEndTimeProvider.notifier).state = end;
              ref.read(loggerLogPageProvider.notifier).state = 0;
            },
          ),
          const SizedBox(width: 8),

          // Search field.
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: CodeOpsColors.textTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: CodeOpsColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: CodeOpsColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: CodeOpsColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: CodeOpsColors.primary),
                  ),
                ),
                onSubmitted: (value) {
                  ref.read(loggerLogSearchProvider.notifier).state = value;
                  ref.read(loggerLogPageProvider.notifier).state = 0;
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Clear filters button.
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all, size: 18),
              color: CodeOpsColors.textSecondary,
              tooltip: 'Clear Filters',
              onPressed: _clearFilters,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
            ),

          // Pause/Resume toggle.
          IconButton(
            icon: Icon(
              widget.isPaused ? Icons.play_arrow : Icons.pause,
              size: 18,
            ),
            color: widget.isPaused
                ? CodeOpsColors.warning
                : CodeOpsColors.textSecondary,
            tooltip: widget.isPaused ? 'Resume' : 'Pause',
            onPressed: widget.onTogglePause,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// A compact dropdown styled for the filter bar.
class _FilterDropdown<T> extends StatelessWidget {
  final String hint;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 12,
          ),
          icon: const Icon(
            Icons.expand_more,
            size: 16,
            color: CodeOpsColors.textTertiary,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

/// A button that shows time range presets in a popup menu.
class _TimeRangeButton extends StatelessWidget {
  final DateTime? startTime;
  final DateTime? endTime;
  final void Function(DateTime? start, DateTime? end) onChanged;

  const _TimeRangeButton({
    required this.startTime,
    required this.endTime,
    required this.onChanged,
  });

  /// Preset time ranges in hours.
  static const _presets = <int, String>{
    0: 'All Time',
    1: 'Last 1 hour',
    6: 'Last 6 hours',
    24: 'Last 24 hours',
    168: 'Last 7 days',
  };

  /// Returns the label for the currently active preset.
  String get _activeLabel {
    if (startTime == null) return 'All Time';
    final diff = DateTime.now().difference(startTime!).inHours;
    for (final entry in _presets.entries) {
      if (entry.key == 0) continue;
      if ((diff - entry.key).abs() <= 1) return entry.value;
    }
    return 'Custom';
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Time Range',
      color: CodeOpsColors.surface,
      onSelected: (hours) {
        if (hours == 0) {
          onChanged(null, null);
        } else {
          final now = DateTime.now().toUtc();
          onChanged(now.subtract(Duration(hours: hours)), now);
        }
      },
      itemBuilder: (_) => _presets.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: CodeOpsColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CodeOpsColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule,
              size: 14,
              color: CodeOpsColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              _activeLabel,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more,
              size: 14,
              color: CodeOpsColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
