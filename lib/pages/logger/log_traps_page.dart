/// Log traps list page.
///
/// Displays a data table of all configured log traps with toggle
/// switches, severity indicators, pattern summaries, and action
/// buttons. Includes a toolbar for creating new traps and filtering.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The log traps list page with sidebar and data table.
class LogTrapsPage extends ConsumerStatefulWidget {
  /// Creates a [LogTrapsPage].
  const LogTrapsPage({super.key});

  @override
  ConsumerState<LogTrapsPage> createState() => _LogTrapsPageState();
}

class _LogTrapsPageState extends ConsumerState<LogTrapsPage> {
  TrapType? _filterTrapType;
  bool? _filterEnabled;

  /// Refreshes the traps list.
  void _refresh() {
    ref.invalidate(loggerTrapsProvider);
  }

  /// Toggles a trap's active state.
  Future<void> _toggleTrap(String trapId) async {
    final api = ref.read(loggerApiProvider);
    await api.toggleLogTrap(trapId);
    ref.invalidate(loggerTrapsProvider);
  }

  /// Deletes a trap after confirmation.
  Future<void> _deleteTrap(
    BuildContext context,
    LogTrapResponse trap,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Delete Trap',
          style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          'Delete trap "${trap.name}"? This cannot be undone.',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(loggerApiProvider);
      await api.deleteLogTrap(trap.id);
      ref.invalidate(loggerTrapsProvider);
    }
  }

  /// Filters traps by type and enabled state.
  List<LogTrapResponse> _applyFilters(List<LogTrapResponse> traps) {
    var result = traps;
    if (_filterTrapType != null) {
      result = result.where((t) => t.trapType == _filterTrapType).toList();
    }
    if (_filterEnabled != null) {
      result = result.where((t) => t.isActive == _filterEnabled).toList();
    }
    return result;
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
              subtitle: 'Select a team to manage traps.',
            ),
          ),
        ],
      );
    }

    final trapsAsync = ref.watch(loggerTrapsProvider);

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              _buildToolbar(),
              _buildFilterBar(),
              Expanded(
                child: trapsAsync.when(
                  data: (traps) {
                    final filtered = _applyFilters(traps);
                    if (filtered.isEmpty) {
                      return const EmptyState(
                        icon: Icons.notification_add_outlined,
                        title: 'No traps configured',
                        subtitle:
                            'Create a trap to start monitoring log patterns.',
                      );
                    }
                    return _buildTrapsTable(filtered);
                  },
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

  /// Builds the top toolbar with create and refresh buttons.
  Widget _buildToolbar() {
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
            Icons.notification_add,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Log Traps',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.go('/logger/traps/new/edit'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Trap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.primary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: 8),
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

  /// Builds the filter bar.
  Widget _buildFilterBar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          // Trap type filter.
          _CompactFilter<TrapType?>(
            hint: 'All Types',
            value: _filterTrapType,
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              ...TrapType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.displayName),
                  )),
            ],
            onChanged: (v) => setState(() => _filterTrapType = v),
          ),
          const SizedBox(width: 8),

          // Enabled filter.
          _CompactFilter<bool?>(
            hint: 'All Status',
            value: _filterEnabled,
            items: const [
              DropdownMenuItem(value: null, child: Text('All Status')),
              DropdownMenuItem(value: true, child: Text('Enabled')),
              DropdownMenuItem(value: false, child: Text('Disabled')),
            ],
            onChanged: (v) => setState(() => _filterEnabled = v),
          ),
        ],
      ),
    );
  }

  /// Builds the traps data table.
  Widget _buildTrapsTable(List<LogTrapResponse> traps) {
    return Column(
      children: [
        // Column headers.
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: CodeOpsColors.surfaceVariant,
          child: const Row(
            children: [
              SizedBox(width: 60, child: _HeaderText('Enabled')),
              Expanded(flex: 2, child: _HeaderText('Name')),
              SizedBox(width: 80, child: _HeaderText('Type')),
              Expanded(flex: 2, child: _HeaderText('Pattern')),
              SizedBox(width: 120, child: _HeaderText('Last Triggered')),
              SizedBox(width: 70, child: _HeaderText('Matches')),
              SizedBox(width: 150, child: _HeaderText('Actions')),
            ],
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Data rows.
        Expanded(
          child: ListView.builder(
            itemCount: traps.length,
            itemBuilder: (context, index) {
              final trap = traps[index];
              return _buildTrapRow(trap, index);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a single trap row.
  Widget _buildTrapRow(LogTrapResponse trap, int index) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: index.isEven
            ? CodeOpsColors.background
            : CodeOpsColors.surface.withValues(alpha: 0.5),
        border: const Border(
          bottom: BorderSide(color: CodeOpsColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Enabled toggle.
          SizedBox(
            width: 60,
            child: Switch(
              value: trap.isActive,
              onChanged: (_) => _toggleTrap(trap.id),
              activeThumbColor: CodeOpsColors.success,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          // Name.
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  trap.name,
                  style: TextStyle(
                    color: trap.isActive
                        ? CodeOpsColors.textPrimary
                        : CodeOpsColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (trap.description != null &&
                    trap.description!.isNotEmpty)
                  Text(
                    trap.description!,
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Type badge.
          SizedBox(
            width: 80,
            child: _TrapTypeBadge(type: trap.trapType),
          ),

          // Pattern summary.
          Expanded(
            flex: 2,
            child: Text(
              _summarizeConditions(trap.conditions),
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Last triggered.
          SizedBox(
            width: 120,
            child: Text(
              trap.lastTriggeredAt != null
                  ? _formatDateTime(trap.lastTriggeredAt!)
                  : 'Never',
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),

          // Match count.
          SizedBox(
            width: 70,
            child: Text(
              trap.triggerCount.toString(),
              style: TextStyle(
                color: trap.triggerCount > 0
                    ? CodeOpsColors.warning
                    : CodeOpsColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Actions.
          SizedBox(
            width: 150,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  color: CodeOpsColors.textSecondary,
                  tooltip: 'Edit',
                  onPressed: () =>
                      context.go('/logger/traps/${trap.id}/edit'),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.science_outlined, size: 16),
                  color: CodeOpsColors.textSecondary,
                  tooltip: 'Test',
                  onPressed: () =>
                      context.go('/logger/traps/${trap.id}/edit'),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: CodeOpsColors.textTertiary,
                  tooltip: 'Delete',
                  onPressed: () => _deleteTrap(context, trap),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Summarizes a trap's conditions for display.
  String _summarizeConditions(List<TrapConditionResponse> conditions) {
    if (conditions.isEmpty) return '(no conditions)';
    final first = conditions.first;
    final parts = <String>[];
    if (first.pattern != null) parts.add(first.pattern!);
    if (first.threshold != null) parts.add('>${first.threshold}');
    if (first.windowSeconds != null) {
      parts.add('in ${first.windowSeconds}s');
    }
    if (first.logLevel != null) parts.add(first.logLevel!.toJson());
    final summary = parts.isEmpty ? first.field : parts.join(' ');
    if (conditions.length > 1) {
      return '$summary (+${conditions.length - 1} more)';
    }
    return summary;
  }

  /// Formats a [DateTime] for compact display.
  String _formatDateTime(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m/$d $h:$min';
  }
}

/// A compact dropdown for the filter bar.
class _CompactFilter<T> extends StatelessWidget {
  final String hint;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _CompactFilter({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
            fontSize: 11,
          ),
          icon: const Icon(
            Icons.expand_more,
            size: 14,
            color: CodeOpsColors.textTertiary,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

/// Column header text widget.
class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: CodeOpsColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// A colored badge for trap type.
class _TrapTypeBadge extends StatelessWidget {
  final TrapType type;
  const _TrapTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      TrapType.pattern => CodeOpsColors.primary,
      TrapType.frequency => CodeOpsColors.warning,
      TrapType.absence => CodeOpsColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
