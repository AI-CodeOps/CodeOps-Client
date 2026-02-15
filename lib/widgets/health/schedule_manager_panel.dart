/// Health monitoring schedule management panel.
///
/// Lists existing schedules and provides a dialog for creating new ones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/health_snapshot.dart';
import '../../providers/health_providers.dart';
import '../../theme/colors.dart';

/// Displays and manages health monitoring schedules for a project.
class ScheduleManagerPanel extends ConsumerStatefulWidget {
  /// The project ID to manage schedules for.
  final String projectId;

  /// Creates a [ScheduleManagerPanel].
  const ScheduleManagerPanel({super.key, required this.projectId});

  @override
  ConsumerState<ScheduleManagerPanel> createState() =>
      _ScheduleManagerPanelState();
}

class _ScheduleManagerPanelState extends ConsumerState<ScheduleManagerPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(healthSchedulesProvider(widget.projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with expand/collapse toggle
        Row(
          children: [
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              tooltip: _isExpanded ? 'Collapse' : 'Expand',
            ),
            Text(
              'Health Schedules',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Schedule'),
              onPressed: () => _showCreateDialog(context),
            ),
          ],
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          schedulesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text(
              'Failed to load schedules: $e',
              style:
                  const TextStyle(color: CodeOpsColors.error, fontSize: 13),
            ),
            data: (schedules) {
              if (schedules.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No schedules configured.',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return Column(
                children: schedules
                    .map((s) => _ScheduleRow(
                          schedule: s,
                          onToggle: (active) => _toggleSchedule(s.id, active),
                          onDelete: () => _deleteSchedule(s.id),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _toggleSchedule(String scheduleId, bool active) async {
    try {
      final api = ref.read(healthMonitorApiProvider);
      await api.updateSchedule(scheduleId, active);
      ref.invalidate(healthSchedulesProvider(widget.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update schedule: $e')),
        );
      }
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content:
            const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: CodeOpsColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ref.read(healthMonitorApiProvider);
      await api.deleteSchedule(scheduleId);
      ref.invalidate(healthSchedulesProvider(widget.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete schedule: $e')),
        );
      }
    }
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateScheduleDialog(projectId: widget.projectId),
    ).then((_) {
      ref.invalidate(healthSchedulesProvider(widget.projectId));
    });
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ScheduleRow extends StatelessWidget {
  final HealthSchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ScheduleRow({
    required this.schedule,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = schedule.isActive ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CodeOpsColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              schedule.scheduleType.displayName,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Cron expression
          if (schedule.cronExpression != null) ...[
            Text(
              schedule.cronExpression!,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Agent types
          Expanded(
            child: Wrap(
              spacing: 4,
              children: (schedule.agentTypes ?? []).map((type) {
                return Chip(
                  label: Text(type.displayName),
                  labelStyle: const TextStyle(fontSize: 10),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),

          // Last/next run
          if (schedule.lastRunAt != null)
            Tooltip(
              message:
                  'Last: ${DateFormat('M/d HH:mm').format(schedule.lastRunAt!)}',
              child: const Icon(Icons.history, size: 14,
                  color: CodeOpsColors.textTertiary),
            ),
          const SizedBox(width: 8),

          // Active toggle
          Switch(
            value: isActive,
            onChanged: onToggle,
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: CodeOpsColors.error,
            onPressed: onDelete,
            tooltip: 'Delete schedule',
          ),
        ],
      ),
    );
  }
}

class _CreateScheduleDialog extends ConsumerStatefulWidget {
  final String projectId;

  const _CreateScheduleDialog({required this.projectId});

  @override
  ConsumerState<_CreateScheduleDialog> createState() =>
      _CreateScheduleDialogState();
}

class _CreateScheduleDialogState
    extends ConsumerState<_CreateScheduleDialog> {
  ScheduleType _scheduleType = ScheduleType.daily;
  final _cronController = TextEditingController();
  final Set<AgentType> _selectedAgents = {
    AgentType.security,
    AgentType.codeQuality,
  };
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _cronController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_selectedAgents.isEmpty) {
      setState(() => _error = 'Select at least one agent type.');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final api = ref.read(healthMonitorApiProvider);
      await api.createSchedule(
        projectId: widget.projectId,
        scheduleType: _scheduleType,
        agentTypes: _selectedAgents.toList(),
        cronExpression:
            _cronController.text.isNotEmpty ? _cronController.text : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to create schedule: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Health Schedule'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schedule type dropdown
            const Text('Schedule Type',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            DropdownButton<ScheduleType>(
              value: _scheduleType,
              isExpanded: true,
              dropdownColor: CodeOpsColors.surface,
              items: ScheduleType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.displayName),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _scheduleType = v);
              },
            ),
            const SizedBox(height: 16),

            // Cron expression (conditional)
            if (_scheduleType != ScheduleType.onCommit) ...[
              const Text('Cron Expression (optional)',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                controller: _cronController,
                decoration: const InputDecoration(
                  hintText: '0 0 * * *',
                  isDense: true,
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
            ],

            // Agent type multi-select
            const Text('Agent Types',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: AgentType.values.map((type) {
                final selected = _selectedAgents.contains(type);
                return FilterChip(
                  label: Text(type.displayName,
                      style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedAgents.add(type);
                      } else {
                        _selectedAgents.remove(type);
                      }
                    });
                  },
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: CodeOpsColors.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _create,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
