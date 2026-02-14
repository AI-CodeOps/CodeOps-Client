/// Dialog for creating a single Jira issue from a remediation task.
///
/// Pre-fills fields from the [RemediationTask] and [Project] parameters,
/// allows editing all fields, and creates the issue via [JiraService].
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
import 'assignee_picker.dart';

/// A dialog that creates a single Jira issue from a [RemediationTask].
///
/// Fields are pre-filled from the task and project configuration:
/// - Summary from [RemediationTask.title]
/// - Description from [RemediationTask.description]
/// - Project key from [Project.jiraProjectKey]
/// - Issue type from [Project.jiraDefaultIssueType]
/// - Labels from [Project.jiraLabels]
/// - Component from [Project.jiraComponent]
///
/// On successful creation, closes the dialog and shows the new issue key.
class CreateIssueDialog extends ConsumerStatefulWidget {
  /// The remediation task to create a Jira issue for.
  final RemediationTask task;

  /// The CodeOps project providing Jira default settings.
  final Project project;

  /// Creates a [CreateIssueDialog].
  const CreateIssueDialog({
    super.key,
    required this.task,
    required this.project,
  });

  @override
  ConsumerState<CreateIssueDialog> createState() => _CreateIssueDialogState();
}

class _CreateIssueDialogState extends ConsumerState<CreateIssueDialog> {
  late final TextEditingController _summaryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _componentController;
  final _labelController = TextEditingController();

  String _projectKey = '';
  String _issueTypeName = '';
  String? _priorityName;
  JiraUser? _assignee;
  final List<String> _labels = [];

  bool _creating = false;
  String? _error;

  List<JiraProject> _jiraProjects = [];
  List<JiraIssueType> _issueTypes = [];
  List<JiraPriority> _priorities = [];

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: _buildDescription(),
    );
    _projectKey = widget.project.jiraProjectKey ?? '';
    _issueTypeName = widget.project.jiraDefaultIssueType ?? 'Task';
    _componentController = TextEditingController(
      text: widget.project.jiraComponent ?? '',
    );
    if (widget.project.jiraLabels != null) {
      _labels.addAll(widget.project.jiraLabels!);
    }

    // Load metadata after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMetadata());
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _descriptionController.dispose();
    _componentController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  /// Builds the initial description from the task's fields.
  String _buildDescription() {
    final buffer = StringBuffer();
    if (widget.task.description != null) {
      buffer.writeln(widget.task.description);
    }
    if (widget.task.promptMd != null) {
      if (buffer.isNotEmpty) buffer.writeln('\n---\n');
      buffer.writeln('**Remediation Prompt:**');
      buffer.writeln(widget.task.promptMd);
    }
    return buffer.toString();
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

      // Load issue types for the configured project.
      if (_projectKey.isNotEmpty) {
        await _loadIssueTypes(_projectKey);
      }
    } catch (_) {
      // Metadata loading is best-effort; fields remain editable.
    }
  }

  /// Loads issue types for the given [projectKey].
  Future<void> _loadIssueTypes(String projectKey) async {
    try {
      final types =
          await ref.read(jiraIssueTypesProvider(projectKey).future);
      if (mounted) {
        setState(() {
          _issueTypes = types;
          // Validate current selection.
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

  /// Adds a label from the input field.
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

  /// Creates the Jira issue.
  Future<void> _create() async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty) {
      setState(() => _error = 'Summary is required.');
      return;
    }
    if (_projectKey.isEmpty) {
      setState(() => _error = 'Project key is required.');
      return;
    }

    final service = await ref.read(jiraServiceProvider.future);
    if (service == null) {
      setState(() => _error = 'Jira is not configured.');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      final request = CreateJiraIssueRequest(
        projectKey: _projectKey,
        issueTypeName: _issueTypeName,
        summary: summary,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        assigneeAccountId: _assignee?.accountId,
        priorityName: _priorityName,
        labels: _labels.isNotEmpty ? _labels : null,
        componentName: _componentController.text.trim().isNotEmpty
            ? _componentController.text.trim()
            : null,
      );

      final createdIssue = await service.createIssue(request);

      if (mounted) {
        showToast(
          context,
          message: 'Created ${createdIssue.key}: ${createdIssue.fields.summary}',
          type: ToastType.success,
        );
        Navigator.of(context).pop(createdIssue);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creating = false;
          _error = 'Create failed: ${_friendlyError(e)}';
        });
      }
    }
  }

  /// Extracts a user-friendly error message.
  String _friendlyError(Object error) {
    final msg = error.toString();
    if (msg.length > 100) return '${msg.substring(0, 100)}...';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Row(
        children: [
          Icon(Icons.add_task, color: CodeOpsColors.primary, size: 22),
          SizedBox(width: 10),
          Text(
            'Create Jira Issue',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        height: 520,
        child: ListView(
          children: [
            // Summary.
            _buildLabel('Summary'),
            const SizedBox(height: 4),
            _buildTextField(
              controller: _summaryController,
              hintText: 'Issue summary',
            ),
            const SizedBox(height: 14),
            // Description.
            _buildLabel('Description'),
            const SizedBox(height: 4),
            _buildTextField(
              controller: _descriptionController,
              hintText: 'Detailed description',
              maxLines: 5,
            ),
            const SizedBox(height: 14),
            // Project key + Issue type row.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProjectDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildIssueTypeDropdown()),
              ],
            ),
            const SizedBox(height: 14),
            // Priority.
            _buildPriorityDropdown(),
            const SizedBox(height: 14),
            // Assignee.
            _buildLabel('Assignee'),
            const SizedBox(height: 4),
            AssigneePicker(
              currentAssignee: _assignee,
              onUserSelected: (user) => setState(() => _assignee = user),
            ),
            const SizedBox(height: 14),
            // Labels.
            _buildLabel('Labels'),
            const SizedBox(height: 4),
            _buildLabelsInput(),
            const SizedBox(height: 14),
            // Component.
            _buildLabel('Component'),
            const SizedBox(height: 4),
            _buildTextField(
              controller: _componentController,
              hintText: 'Component name',
            ),
            // Error.
            if (_error != null) ...[
              const SizedBox(height: 12),
              _buildError(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _creating ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _creating ? null : _create,
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
          label: Text(_creating ? 'Creating...' : 'Create Issue'),
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

  /// Builds a section label.
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: CodeOpsColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Builds a styled text field.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: !_creating,
      maxLines: maxLines,
      style: const TextStyle(
        color: CodeOpsColors.textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: CodeOpsColors.textTertiary,
          fontSize: 12,
        ),
        filled: true,
        fillColor: CodeOpsColors.surfaceVariant,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
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

  /// Builds the Jira project dropdown.
  Widget _buildProjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Project Key'),
        const SizedBox(height: 4),
        _jiraProjects.isEmpty
            ? _buildTextField(
                controller: TextEditingController(text: _projectKey),
                hintText: 'e.g. PAY',
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                      fontSize: 13,
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                fontSize: 13,
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

  /// Builds the priority dropdown.
  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Priority'),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _priorityName,
              isExpanded: true,
              dropdownColor: CodeOpsColors.surfaceVariant,
              hint: const Text(
                'Default',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Default'),
                ),
                ..._priorities.map((p) {
                  final display = JiraMapper.mapPriority(p.name);
                  return DropdownMenuItem(
                    value: p.name,
                    child: Row(
                      children: [
                        Icon(display.icon, color: display.color, size: 16),
                        const SizedBox(width: 6),
                        Text(p.name),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: _creating
                  ? null
                  : (v) => setState(() => _priorityName = v),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the labels chip input.
  Widget _buildLabelsInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          ..._labels.asMap().entries.map((entry) {
            return Chip(
              label: Text(
                entry.value,
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 11,
                ),
              ),
              backgroundColor: CodeOpsColors.surface,
              deleteIcon: const Icon(Icons.close, size: 14),
              deleteIconColor: CodeOpsColors.textTertiary,
              onDeleted: () => _removeLabel(entry.key),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              side: const BorderSide(color: CodeOpsColors.border, width: 1),
            );
          }),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _labelController,
              enabled: !_creating,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                hintText: 'Add label...',
                hintStyle: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 11,
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
