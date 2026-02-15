/// Directives management page with master-detail layout.
///
/// Left panel shows a filterable list of directives. Right panel
/// displays an inline editor for the selected directive.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/directive.dart';
import '../models/enums.dart';
import '../providers/directive_providers.dart';
import '../providers/project_providers.dart';
import '../providers/team_providers.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';
import '../widgets/shared/notification_toast.dart';
import '../widgets/shared/search_bar.dart';

/// The directives page replacing the `/directives` placeholder.
class DirectivesPage extends ConsumerStatefulWidget {
  /// Creates a [DirectivesPage].
  const DirectivesPage({super.key});

  @override
  ConsumerState<DirectivesPage> createState() => _DirectivesPageState();
}

class _DirectivesPageState extends ConsumerState<DirectivesPage> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel: directive list.
        Expanded(
          flex: 2,
          child: _DirectiveList(),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: CodeOpsColors.border,
        ),
        // Right panel: editor.
        Expanded(
          flex: 3,
          child: _DirectiveEditor(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Directive list (left panel)
// ---------------------------------------------------------------------------

class _DirectiveList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directivesAsync = ref.watch(filteredDirectivesProvider);
    final categoryFilter = ref.watch(directiveCategoryFilterProvider);
    final scopeFilter = ref.watch(directiveScopeFilterProvider);
    final selected = ref.watch(selectedDirectiveProvider);

    return Column(
      children: [
        // Header.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Directives',
                    style: TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Refresh',
                    onPressed: () =>
                        ref.invalidate(teamDirectivesProvider),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: () => _createNew(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CodeOpsSearchBar(
                hint: 'Search directives...',
                onChanged: (value) {
                  ref.read(directiveSearchQueryProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<DirectiveCategory?>(
                      value: categoryFilter,
                      dropdownColor: CodeOpsColors.surface,
                      underline: const SizedBox.shrink(),
                      isExpanded: true,
                      hint: const Text(
                        'All Categories',
                        style: TextStyle(
                            color: CodeOpsColors.textSecondary, fontSize: 12),
                      ),
                      style: const TextStyle(
                          color: CodeOpsColors.textSecondary, fontSize: 12),
                      items: [
                        const DropdownMenuItem<DirectiveCategory?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...DirectiveCategory.values.map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        ref
                            .read(directiveCategoryFilterProvider.notifier)
                            .state = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<DirectiveScope?>(
                      value: scopeFilter,
                      dropdownColor: CodeOpsColors.surface,
                      underline: const SizedBox.shrink(),
                      isExpanded: true,
                      hint: const Text(
                        'All Scopes',
                        style: TextStyle(
                            color: CodeOpsColors.textSecondary, fontSize: 12),
                      ),
                      style: const TextStyle(
                          color: CodeOpsColors.textSecondary, fontSize: 12),
                      items: [
                        const DropdownMenuItem<DirectiveScope?>(
                          value: null,
                          child: Text('All Scopes'),
                        ),
                        ...DirectiveScope.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.displayName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        ref.read(directiveScopeFilterProvider.notifier).state =
                            value;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Directive cards.
        Expanded(
          child: directivesAsync.when(
            loading: () =>
                const LoadingOverlay(message: 'Loading directives...'),
            error: (error, _) => ErrorPanel.fromException(
              error,
              onRetry: () => ref.invalidate(teamDirectivesProvider),
            ),
            data: (directives) {
              if (directives.isEmpty) {
                return EmptyState(
                  icon: Icons.rule,
                  title: 'No directives',
                  subtitle: 'Create a directive to add rules for agents.',
                  actionLabel: 'New Directive',
                  onAction: () => _createNew(context, ref),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: directives.length,
                itemBuilder: (context, index) {
                  final directive = directives[index];
                  final isSelected = selected?.id == directive.id;
                  return _DirectiveCard(
                    directive: directive,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(selectedDirectiveProvider.notifier).state =
                          directive;
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _createNew(BuildContext context, WidgetRef ref) {
    final teamId = ref.read(selectedTeamIdProvider);
    // Create a temporary placeholder and select it.
    ref.read(selectedDirectiveProvider.notifier).state = Directive(
      id: 'new',
      name: '',
      scope: DirectiveScope.team,
      teamId: teamId,
    );
  }
}

// ---------------------------------------------------------------------------
// Directive card
// ---------------------------------------------------------------------------

class _DirectiveCard extends StatelessWidget {
  final Directive directive;
  final bool isSelected;
  final VoidCallback onTap;

  const _DirectiveCard({
    required this.directive,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? CodeOpsColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color:
                    isSelected ? CodeOpsColors.primary : Colors.transparent,
                width: 3,
              ),
              bottom: const BorderSide(color: CodeOpsColors.border, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      directive.name.isEmpty
                          ? 'New Directive'
                          : directive.name,
                      style: TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (directive.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        directive.category!.displayName,
                        style: const TextStyle(
                          color: CodeOpsColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              if (directive.description != null &&
                  directive.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  directive.description!,
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    directive.scope.displayName,
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatTimeAgo(directive.updatedAt),
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Directive editor (right panel)
// ---------------------------------------------------------------------------

class _DirectiveEditor extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DirectiveEditor> createState() => _DirectiveEditorState();
}

class _DirectiveEditorState extends ConsumerState<_DirectiveEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _contentController;
  DirectiveCategory? _category;
  DirectiveScope _scope = DirectiveScope.team;
  bool _saving = false;
  bool _showPreview = false;
  String? _currentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _loadDirective(Directive? directive) {
    if (directive == null || directive.id == _currentId) return;
    _currentId = directive.id;
    _nameController.text = directive.name;
    _descriptionController.text = directive.description ?? '';
    _contentController.text = directive.contentMd ?? '';
    _category = directive.category;
    _scope = directive.scope;
    _showPreview = false;
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDirectiveProvider);

    if (selected == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rule, size: 48, color: CodeOpsColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Select a directive or create a new one',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Sync form fields when selection changes.
    _loadDirective(selected);

    final isNew = selected.id == 'new';

    return Column(
      children: [
        // Editor header.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Row(
            children: [
              Text(
                isNew ? 'New Directive' : 'Edit Directive',
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Preview toggle.
              FilterChip(
                label: const Text('Preview', style: TextStyle(fontSize: 12)),
                selected: _showPreview,
                selectedColor: CodeOpsColors.primaryVariant,
                onSelected: (v) => setState(() => _showPreview = v),
              ),
              const SizedBox(width: 8),
              if (!isNew) ...[
                OutlinedButton.icon(
                  onPressed: () => _assignToProjects(context),
                  icon: const Icon(Icons.assignment, size: 16),
                  label: const Text('Assign'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _deleteDirective(context),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: CodeOpsColors.error),
                  label: const Text('Delete',
                      style: TextStyle(color: CodeOpsColors.error)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                    side: const BorderSide(color: CodeOpsColors.error),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 16),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        // Form.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + category.
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name *',
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<DirectiveCategory?>(
                          initialValue: _category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            isDense: true,
                          ),
                          dropdownColor: CodeOpsColors.surfaceVariant,
                          items: [
                            const DropdownMenuItem<DirectiveCategory?>(
                              value: null,
                              child: Text('None'),
                            ),
                            ...DirectiveCategory.values.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.displayName),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _category = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<DirectiveScope>(
                          initialValue: _scope,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Scope',
                            isDense: true,
                          ),
                          dropdownColor: CodeOpsColors.surfaceVariant,
                          items: DirectiveScope.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: isNew
                              ? (v) {
                                  if (v != null) setState(() => _scope = v);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description.
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Content.
                  const Text(
                    'Content (Markdown)',
                    style: TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: CodeOpsColors.textPrimary,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write directive content in Markdown...',
                        filled: true,
                        fillColor: CodeOpsColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final api = ref.read(directiveApiProvider);
      final selected = ref.read(selectedDirectiveProvider);
      final isNew = selected?.id == 'new';

      if (isNew) {
        final teamId = ref.read(selectedTeamIdProvider);
        final directive = await api.createDirective(
          name: _nameController.text.trim(),
          contentMd: _contentController.text,
          scope: _scope,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _category,
          teamId: teamId,
        );
        ref.invalidate(teamDirectivesProvider);
        ref.read(selectedDirectiveProvider.notifier).state = directive;
        _currentId = directive.id;
        if (mounted) {
          showToast(context,
              message: 'Directive created', type: ToastType.success);
        }
      } else {
        final directive = await api.updateDirective(
          selected!.id,
          name: _nameController.text.trim(),
          contentMd: _contentController.text,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _category,
        );
        ref.invalidate(teamDirectivesProvider);
        ref.read(selectedDirectiveProvider.notifier).state = directive;
        _currentId = directive.id;
        if (mounted) {
          showToast(context,
              message: 'Directive saved', type: ToastType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Save failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteDirective(BuildContext context) async {
    final selected = ref.read(selectedDirectiveProvider);
    if (selected == null || selected.id == 'new') return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Directive',
      message:
          'Are you sure you want to delete "${selected.name}"? '
          'This will remove it from all assigned projects.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      final api = ref.read(directiveApiProvider);
      await api.deleteDirective(selected.id);
      ref.invalidate(teamDirectivesProvider);
      ref.read(selectedDirectiveProvider.notifier).state = null;
      _currentId = null;
      if (mounted) {
        showToast(context,
            message: 'Directive deleted', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Delete failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _assignToProjects(BuildContext context) async {
    final selected = ref.read(selectedDirectiveProvider);
    if (selected == null || selected.id == 'new') return;

    await showDialog(
      context: context,
      builder: (_) => _AssignDialog(directiveId: selected.id),
    );
  }
}

// ---------------------------------------------------------------------------
// Assign to projects dialog
// ---------------------------------------------------------------------------

class _AssignDialog extends ConsumerStatefulWidget {
  final String directiveId;

  const _AssignDialog({required this.directiveId});

  @override
  ConsumerState<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<_AssignDialog> {
  final _assigned = <String, bool>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      final projects = ref.read(teamProjectsProvider).valueOrNull ?? [];
      for (final p in projects) {
        final assignments =
            ref.read(projectDirectivesProvider(p.id)).valueOrNull ?? [];
        final match = assignments.where((a) =>
            a.directiveId == widget.directiveId);
        if (match.isNotEmpty) {
          _assigned[p.id] = match.first.enabled ?? true;
        }
      }
    } catch (_) {
      // Non-critical — assignments just won't be pre-populated.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(teamProjectsProvider);

    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Assign to Projects'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : projectsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (projects) {
                  if (projects.isEmpty) {
                    return const Center(
                      child: Text('No projects in this team'),
                    );
                  }
                  return ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final isAssigned = _assigned.containsKey(project.id);
                      final isEnabled = _assigned[project.id] ?? false;

                      return ListTile(
                        title: Text(
                          project.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        leading: Checkbox(
                          value: isAssigned,
                          onChanged: (v) async {
                            if (v == true) {
                              await _assign(project.id);
                            } else {
                              await _remove(project.id);
                            }
                          },
                          activeColor: CodeOpsColors.primary,
                        ),
                        trailing: isAssigned
                            ? Switch(
                                value: isEnabled,
                                onChanged: (v) => _toggle(project.id, v),
                                activeTrackColor: CodeOpsColors.success,
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close',
              style: TextStyle(color: CodeOpsColors.textSecondary)),
        ),
      ],
    );
  }

  Future<void> _assign(String projectId) async {
    try {
      final api = ref.read(directiveApiProvider);
      await api.assignToProject(
        projectId: projectId,
        directiveId: widget.directiveId,
      );
      setState(() => _assigned[projectId] = true);
      ref.invalidate(projectDirectivesProvider(projectId));
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Failed to assign: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _remove(String projectId) async {
    try {
      final api = ref.read(directiveApiProvider);
      await api.removeFromProject(projectId, widget.directiveId);
      setState(() => _assigned.remove(projectId));
      ref.invalidate(projectDirectivesProvider(projectId));
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Failed to remove: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _toggle(String projectId, bool enabled) async {
    try {
      final api = ref.read(directiveApiProvider);
      await api.toggleDirective(projectId, widget.directiveId, enabled);
      setState(() => _assigned[projectId] = enabled);
      ref.invalidate(projectDirectivesProvider(projectId));
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Failed to toggle: $e', type: ToastType.error);
      }
    }
  }
}
