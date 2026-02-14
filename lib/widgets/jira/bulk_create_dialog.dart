/// Dialog for creating multiple Jira issues from a list of remediation tasks.
///
/// Provides shared fields (project, type, labels, component), per-task editing
/// of summary and priority, a sub-task toggle with parent key, progress tracking,
/// and a results summary upon completion.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/jira_models.dart';
import '../../models/project.dart';
import '../../models/remediation_task.dart';
import '../../providers/jira_providers.dart';
import '../../services/jira/jira_mapper.dart';
import '../../theme/colors.dart';
import '../shared/notification_toast.dart';

/// A dialog for bulk-creating Jira issues from a list of [RemediationTask]s.
///
/// Displays a task list with checkboxes (all selected by default), shared fields
/// for project key, issue type, labels, and component, plus per-task editable
/// summary and priority. Supports creating issues as sub-tasks under a parent.
///
/// Progress is shown via a progress bar during creation. On completion, a
/// results summary shows the number of created vs failed issues.
class BulkCreateDialog extends ConsumerStatefulWidget {
  /// The remediation tasks to create Jira issues for.
  final List<RemediationTask> tasks;

  /// The CodeOps project providing Jira default settings.
  final Project project;

  /// Creates a [BulkCreateDialog].
  const BulkCreateDialog({
    super.key,
    required this.tasks,
    required this.project,
  });

  @override
  ConsumerState<BulkCreateDialog> createState() => _BulkCreateDialogState();
}

class _BulkCreateDialogState extends ConsumerState<BulkCreateDialog> {
  late final Set<int> _selectedIndices;
  late final List<TextEditingController> _summaryControllers;
  late final List<String?> _perTaskPriority;
  final _componentController = TextEditingController();
  final _labelController = TextEditingController();
  final _parentKeyController = TextEditingController();

  String _projectKey = '';
  String _issueTypeName = '';
  final List<String> _labels = [];
  bool _createAsSubTasks = false;

  // Metadata.
  List<JiraProject> _jiraProjects = [];
  List<JiraIssueType> _issueTypes = [];
  List<JiraPriority> _priorities = [];

  // Creation state.
  bool _creating = false;
  bool _done = false;
  int _progressCurrent = 0;
  int _progressTotal = 0;
  final List<JiraIssue> _createdIssues = [];
  final List<String> _failedTasks = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIndices = Set<int>.from(
      List.generate(widget.tasks.length, (i) => i),
    );
    _summaryControllers = widget.tasks
        .map((t) => TextEditingController(text: t.title))
        .toList();
    _perTaskPriority = List<String?>.filled(widget.tasks.length, null);

    _projectKey = widget.project.jiraProjectKey ?? '';
    _issueTypeName = widget.project.jiraDefaultIssueType ?? 'Task';
    _componentController.text = widget.project.jiraComponent ?? '';
    if (widget.project.jiraLabels != null) {
      _labels.addAll(widget.project.jiraLabels!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMetadata());
  }

  @override
  void dispose() {
    for (final c in _summaryControllers) {
      c.dispose();
    }
    _componentController.dispose();
    _labelController.dispose();
    _parentKeyController.dispose();
    super.dispose();
  }

  /// Loads Jira projects, priorities, and issue types.
  Future<void> _loadMetadata() async {
    try {
      final projects = await ref.read(jiraProjectsProvider.future);
      final priorities = await ref.read(jiraPrioritiesProvider.future);
      if (mounted) {
        setState(() {
          _jiraProjects = projects;
          _priorities = priorities;
        });
      }
      if (_projectKey.isNotEmpty) {
        await _loadIssueTypes(_projectKey);
      }
    } catch (_) {
      // Best-effort metadata loading.
    }
  }

  /// Loads issue types for [projectKey].
  Future<void> _loadIssueTypes(String projectKey) async {
    try {
      final types =
          await ref.read(jiraIssueTypesProvider(projectKey).future);
      if (mounted) {
        setState(() {
          _issueTypes = types;
          if (!types.any((t) => t.name == _issueTypeName) &&
              types.isNotEmpty) {
            _issueTypeName = types.first.name;
          }
        });
      }
    } catch (_) {
      // Best-effort.
    }
  }

  /// Adds a label from the text input.
  void _addLabel() {
    final label = _labelController.text.trim();
    if (label.isEmpty || _labels.contains(label)) return;
    setState(() {
      _labels.add(label);
      _labelController.clear();
    });
  }

  /// Removes the label at [index].
  void _removeLabel(int index) {
    setState(() => _labels.removeAt(index));
  }

  /// Toggles selection for the task at [index].
  void _toggleTask(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  /// Toggles all tasks on or off.
  void _toggleAll() {
    setState(() {
      if (_selectedIndices.length == widget.tasks.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(
          List.generate(widget.tasks.length, (i) => i),
        );
      }
    });
  }

  /// Creates all selected Jira issues sequentially.
  Future<void> _createAll() async {
    if (_selectedIndices.isEmpty) {
      setState(() => _error = 'Select at least one task.');
      return;
    }
    if (_projectKey.isEmpty) {
      setState(() => _error = 'Project key is required.');
      return;
    }
    if (_createAsSubTasks && _parentKeyController.text.trim().isEmpty) {
      setState(() => _error = 'Parent issue key is required for sub-tasks.');
      return;
    }

    final service = await ref.read(jiraServiceProvider.future);
    if (service == null) {
      setState(() => _error = 'Jira is not configured.');
      return;
    }

    final selectedList = _selectedIndices.toList()..sort();
    setState(() {
      _creating = true;
      _done = false;
      _error = null;
      _progressCurrent = 0;
      _progressTotal = selectedList.length;
      _createdIssues.clear();
      _failedTasks.clear();
    });

    for (final index in selectedList) {
      final task = widget.tasks[index];
      final summary = _summaryControllers[index].text.trim();
      if (summary.isEmpty) {
        setState(() {
          _failedTasks.add('Task ${index + 1}: empty summary');
          _progressCurrent++;
        });
        continue;
      }

      try {
        if (_createAsSubTasks) {
          final request = CreateJiraSubTaskRequest(
            parentKey: _parentKeyController.text.trim().toUpperCase(),
            projectKey: _projectKey,
            summary: summary,
            description: task.description,
            priorityName: _perTaskPriority[index],
          );
          final created = await service.createSubTask(request);
          if (mounted) {
            setState(() {
              _createdIssues.add(created);
              _progressCurrent++;
            });
          }
        } else {
          final request = CreateJiraIssueRequest(
            projectKey: _projectKey,
            issueTypeName: _issueTypeName,
            summary: summary,
            description: task.description,
            priorityName: _perTaskPriority[index],
            labels: _labels.isNotEmpty ? _labels : null,
            componentName: _componentController.text.trim().isNotEmpty
                ? _componentController.text.trim()
                : null,
          );
          final created = await service.createIssue(request);
          if (mounted) {
            setState(() {
              _createdIssues.add(created);
              _progressCurrent++;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _failedTasks.add('Task ${index + 1}: ${_friendlyError(e)}');
            _progressCurrent++;
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _creating = false;
        _done = true;
      });
      if (_failedTasks.isEmpty) {
        showToast(
          context,
          message: 'Created ${_createdIssues.length} Jira issues.',
          type: ToastType.success,
        );
      } else {
        showToast(
          context,
          message:
              '${_createdIssues.length} created, ${_failedTasks.length} failed.',
          type: _createdIssues.isNotEmpty ? ToastType.warning : ToastType.error,
        );
      }
    }
  }

  /// Extracts a short error message.
  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.length > 80) return '${msg.substring(0, 80)}...';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Row(
        children: [
          const Icon(Icons.playlist_add, color: CodeOpsColors.primary, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bulk Create Jira Issues',
              style: TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CodeOpsColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Creating ${_selectedIndices.length} issues',
              style: const TextStyle(
                color: CodeOpsColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 680,
        height: 560,
        child: _done ? _buildResultsSummary() : _buildFormContent(),
      ),
      actions: _done
          ? [
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(_createdIssues),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Done'),
              ),
            ]
          : [
              TextButton(
                onPressed:
                    _creating ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: CodeOpsColors.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _creating ? null : _createAll,
                icon: _creating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add, size: 16),
                label: Text(_creating ? 'Creating...' : 'Create All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
    );
  }

  /// Builds the main form content with shared fields and task list.
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shared fields.
        _buildSharedFields(),
        const SizedBox(height: 12),
        const Divider(color: CodeOpsColors.border, height: 1),
        const SizedBox(height: 8),
        // Sub-task toggle.
        _buildSubTaskToggle(),
        const SizedBox(height: 8),
        // Progress bar (visible during creation).
        if (_creating) ...[
          LinearProgressIndicator(
            value: _progressTotal > 0
                ? _progressCurrent / _progressTotal
                : 0,
            backgroundColor: CodeOpsColors.surfaceVariant,
            valueColor:
                const AlwaysStoppedAnimation<Color>(CodeOpsColors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Text(
            '$_progressCurrent / $_progressTotal',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Task list.
        _buildTaskListHeader(),
        const SizedBox(height: 4),
        Expanded(child: _buildTaskList()),
        // Error.
        if (_error != null) ...[
          const SizedBox(height: 8),
          _buildError(),
        ],
      ],
    );
  }

  /// Builds shared fields: project, type, labels, component.
  Widget _buildSharedFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project + Type row.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildProjectDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildIssueTypeDropdown()),
          ],
        ),
        const SizedBox(height: 10),
        // Labels.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLabelsInput()),
            const SizedBox(width: 12),
            // Component.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Component'),
                  const SizedBox(height: 4),
                  _buildSmallTextField(
                    controller: _componentController,
                    hintText: 'Component name',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the sub-task toggle with parent key field.
  Widget _buildSubTaskToggle() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _createAsSubTasks,
            onChanged: _creating
                ? null
                : (v) => setState(() => _createAsSubTasks = v ?? false),
            activeColor: CodeOpsColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Create as Sub-tasks',
          style: TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 12,
          ),
        ),
        if (_createAsSubTasks) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: _buildSmallTextField(
              controller: _parentKeyController,
              hintText: 'Parent key (e.g. PAY-100)',
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the task list header with select-all toggle.
  Widget _buildTaskListHeader() {
    final allSelected =
        _selectedIndices.length == widget.tasks.length;

    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: allSelected,
            tristate: true,
            onChanged: _creating ? null : (_) => _toggleAll(),
            activeColor: CodeOpsColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_selectedIndices.length}/${widget.tasks.length} tasks selected',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        const Text(
          'Summary',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 120),
        const Text(
          'Priority',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  /// Builds the scrollable task list.
  Widget _buildTaskList() {
    return ListView.separated(
      itemCount: widget.tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final selected = _selectedIndices.contains(index);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? CodeOpsColors.surfaceVariant
                : CodeOpsColors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
            border: selected
                ? Border.all(
                    color: CodeOpsColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: selected,
                  onChanged: _creating ? null : (_) => _toggleTask(index),
                  activeColor: CodeOpsColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _summaryControllers[index],
                  enabled: !_creating && selected,
                  style: TextStyle(
                    color: selected
                        ? CodeOpsColors.textPrimary
                        : CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: _buildPerTaskPriorityDropdown(index, selected),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a per-task priority dropdown.
  Widget _buildPerTaskPriorityDropdown(int index, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _perTaskPriority[index],
          isExpanded: true,
          isDense: true,
          dropdownColor: CodeOpsColors.surfaceVariant,
          hint: const Text(
            'Default',
            style: TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 11,
            ),
          ),
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 11,
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Default', style: TextStyle(fontSize: 11)),
            ),
            ..._priorities.map((p) {
              final display = JiraMapper.mapPriority(p.name);
              return DropdownMenuItem(
                value: p.name,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(display.icon, color: display.color, size: 13),
                    const SizedBox(width: 4),
                    Text(p.name, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              );
            }),
          ],
          onChanged: _creating || !enabled
              ? null
              : (v) => setState(() => _perTaskPriority[index] = v),
        ),
      ),
    );
  }

  /// Builds the results summary shown after creation completes.
  Widget _buildResultsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary stats.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _failedTasks.isEmpty
                ? CodeOpsColors.success.withValues(alpha: 0.08)
                : CodeOpsColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _failedTasks.isEmpty
                  ? CodeOpsColors.success.withValues(alpha: 0.3)
                  : CodeOpsColors.warning.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _failedTasks.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                color: _failedTasks.isEmpty
                    ? CodeOpsColors.success
                    : CodeOpsColors.warning,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                _failedTasks.isEmpty
                    ? 'All ${_createdIssues.length} issues created successfully!'
                    : '${_createdIssues.length} created, ${_failedTasks.length} failed',
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Created issues.
        if (_createdIssues.isNotEmpty) ...[
          const Text(
            'Created Issues',
            style: TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              itemCount: _createdIssues.length + _failedTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                if (index < _createdIssues.length) {
                  final issue = _createdIssues[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CodeOpsColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: CodeOpsColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          issue.key,
                          style: const TextStyle(
                            color: CodeOpsColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issue.fields.summary,
                            style: const TextStyle(
                              color: CodeOpsColors.textPrimary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final failedIndex = index - _createdIssues.length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CodeOpsColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: CodeOpsColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _failedTasks[failedIndex],
                            style: const TextStyle(
                              color: CodeOpsColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ] else if (_failedTasks.isNotEmpty) ...[
          const Text(
            'Failures',
            style: TextStyle(
              color: CodeOpsColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: _failedTasks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: CodeOpsColors.error,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _failedTasks[index],
                          style: const TextStyle(
                            color: CodeOpsColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the Jira project dropdown.
  Widget _buildProjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Project Key'),
        const SizedBox(height: 4),
        _jiraProjects.isEmpty
            ? _buildSmallTextField(
                controller: TextEditingController(text: _projectKey),
                hintText: 'e.g. PAY',
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: CodeOpsColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _jiraProjects.any((p) => p.key == _projectKey)
                        ? _projectKey
                        : null,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: CodeOpsColors.surfaceVariant,
                    hint: const Text(
                      'Select project',
                      style: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    style: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 12,
                    ),
                    items: _jiraProjects.map((p) {
                      return DropdownMenuItem(
                        value: p.key,
                        child: Text('${p.key} - ${p.name}'),
                      );
                    }).toList(),
                    onChanged: _creating
                        ? null
                        : (v) {
                            if (v != null) {
                              setState(() => _projectKey = v);
                              _loadIssueTypes(v);
                            }
                          },
                  ),
                ),
              ),
      ],
    );
  }

  /// Builds the issue type dropdown.
  Widget _buildIssueTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Issue Type'),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _issueTypes.any((t) => t.name == _issueTypeName)
                  ? _issueTypeName
                  : null,
              isExpanded: true,
              isDense: true,
              dropdownColor: CodeOpsColors.surfaceVariant,
              hint: Text(
                _issueTypeName.isNotEmpty ? _issueTypeName : 'Select type',
                style: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
              items: _issueTypes.map((t) {
                return DropdownMenuItem(
                  value: t.name,
                  child: Text(t.name),
                );
              }).toList(),
              onChanged: _creating
                  ? null
                  : (v) {
                      if (v != null) setState(() => _issueTypeName = v);
                    },
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the labels chip input.
  Widget _buildLabelsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Labels'),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ..._labels.asMap().entries.map((entry) {
                return Chip(
                  label: Text(
                    entry.value,
                    style: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 10,
                    ),
                  ),
                  backgroundColor: CodeOpsColors.surface,
                  deleteIcon: const Icon(Icons.close, size: 12),
                  deleteIconColor: CodeOpsColors.textTertiary,
                  onDeleted: () => _removeLabel(entry.key),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  side: const BorderSide(
                    color: CodeOpsColors.border,
                    width: 1,
                  ),
                );
              }),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _labelController,
                  enabled: !_creating,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 11,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add...',
                    hintStyle: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 10,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _addLabel(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a section label.
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: CodeOpsColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Builds a compact text field for shared fields.
  Widget _buildSmallTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      enabled: !_creating,
      style: const TextStyle(
        color: CodeOpsColors.textPrimary,
        fontSize: 12,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: CodeOpsColors.textTertiary,
          fontSize: 11,
        ),
        filled: true,
        fillColor: CodeOpsColors.surfaceVariant,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: CodeOpsColors.primary,
            width: 1,
          ),
        ),
      ),
    );
  }

  /// Builds the error display.
  Widget _buildError() {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: CodeOpsColors.error, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
