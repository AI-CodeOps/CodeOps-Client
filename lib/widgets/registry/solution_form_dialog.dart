/// Dialog for creating or editing a solution.
///
/// Create mode: empty form, calls [RegistryApi.createSolution].
/// Edit mode: pre-filled from [existingSolution], calls
/// [RegistryApi.updateSolution] with status field enabled.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';
import '../shared/notification_toast.dart';

/// Create/edit dialog for solutions.
///
/// When [existingSolution] is null, operates in create mode.
/// When provided, operates in edit mode with pre-filled fields.
class SolutionFormDialog extends ConsumerStatefulWidget {
  /// Existing solution for edit mode. Null for create mode.
  final SolutionResponse? existingSolution;

  /// Creates a [SolutionFormDialog].
  const SolutionFormDialog({super.key, this.existingSolution});

  /// Whether this dialog is in edit mode.
  bool get isEditMode => existingSolution != null;

  @override
  ConsumerState<SolutionFormDialog> createState() => _SolutionFormDialogState();
}

class _SolutionFormDialogState extends ConsumerState<SolutionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _iconNameController;
  late final TextEditingController _colorHexController;
  late final TextEditingController _repoUrlController;
  late final TextEditingController _docsUrlController;

  SolutionCategory? _selectedCategory;
  SolutionStatus? _selectedStatus;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existingSolution;
    _nameController = TextEditingController(text: s?.name ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _iconNameController = TextEditingController(text: s?.iconName ?? '');
    _colorHexController = TextEditingController(text: s?.colorHex ?? '');
    _repoUrlController = TextEditingController(text: s?.repositoryUrl ?? '');
    _docsUrlController = TextEditingController(text: s?.documentationUrl ?? '');
    _selectedCategory = s?.category;
    _selectedStatus = s?.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconNameController.dispose();
    _colorHexController.dispose();
    _repoUrlController.dispose();
    _docsUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(registryApiProvider);
      if (widget.isEditMode) {
        await api.updateSolution(
          widget.existingSolution!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _selectedCategory,
          status: _selectedStatus,
          iconName: _iconNameController.text.trim().isEmpty
              ? null
              : _iconNameController.text.trim(),
          colorHex: _colorHexController.text.trim().isEmpty
              ? null
              : _colorHexController.text.trim(),
          repositoryUrl: _repoUrlController.text.trim().isEmpty
              ? null
              : _repoUrlController.text.trim(),
          documentationUrl: _docsUrlController.text.trim().isEmpty
              ? null
              : _docsUrlController.text.trim(),
        );
        ref.invalidate(
            registrySolutionFullDetailProvider(widget.existingSolution!.id));
        ref.invalidate(registrySolutionsProvider);
        if (mounted) {
          showToast(context,
              message: 'Solution updated', type: ToastType.success);
          Navigator.of(context).pop();
        }
      } else {
        final teamId = ref.read(selectedTeamIdProvider);
        if (teamId == null) return;
        final result = await api.createSolution(
          teamId: teamId,
          name: _nameController.text.trim(),
          category: _selectedCategory!,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          iconName: _iconNameController.text.trim().isEmpty
              ? null
              : _iconNameController.text.trim(),
          colorHex: _colorHexController.text.trim().isEmpty
              ? null
              : _colorHexController.text.trim(),
          repositoryUrl: _repoUrlController.text.trim().isEmpty
              ? null
              : _repoUrlController.text.trim(),
          documentationUrl: _docsUrlController.text.trim().isEmpty
              ? null
              : _docsUrlController.text.trim(),
        );
        ref.invalidate(registrySolutionsProvider);
        if (mounted) {
          showToast(context,
              message: 'Solution "${result.name}" created',
              type: ToastType.success);
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: '${widget.isEditMode ? 'Update' : 'Create'} failed: $e',
            type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined,
                        size: 20, color: CodeOpsColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      widget.isEditMode ? 'Edit Solution' : 'Create Solution',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: CodeOpsColors.textTertiary),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 16, color: CodeOpsColors.border),
              // Form fields
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'Solution name',
                          isDense: true,
                        ),
                        maxLength: 200,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Category
                      DropdownButtonFormField<SolutionCategory>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          isDense: true,
                        ),
                        isExpanded: true,
                        dropdownColor: CodeOpsColors.surface,
                        items: SolutionCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: CodeOpsColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v),
                        validator: (v) =>
                            v == null ? 'Category is required' : null,
                      ),
                      // Status (edit mode only)
                      if (widget.isEditMode) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<SolutionStatus>(
                          initialValue: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            isDense: true,
                          ),
                          isExpanded: true,
                          dropdownColor: CodeOpsColors.surface,
                          items: SolutionStatus.values.map((st) {
                            return DropdownMenuItem(
                              value: st,
                              child: Text(
                                st.displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: CodeOpsColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedStatus = v),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Optional description',
                          isDense: true,
                        ),
                        maxLength: 2000,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Icon name + Color hex
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _iconNameController,
                              decoration: const InputDecoration(
                                labelText: 'Icon Name',
                                hintText: 'e.g. hub',
                                isDense: true,
                              ),
                              maxLength: 50,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _colorHexController,
                              decoration: const InputDecoration(
                                labelText: 'Color Hex',
                                hintText: '#6C63FF',
                                isDense: true,
                              ),
                              maxLength: 7,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Repository URL
                      TextFormField(
                        controller: _repoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Repository URL',
                          hintText: 'https://github.com/...',
                          isDense: true,
                        ),
                        maxLength: 500,
                      ),
                      const SizedBox(height: 16),
                      // Documentation URL
                      TextFormField(
                        controller: _docsUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Documentation URL',
                          hintText: 'https://docs...',
                          isDense: true,
                        ),
                        maxLength: 500,
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(widget.isEditMode
                                  ? 'Save Changes'
                                  : 'Create Solution'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the [SolutionFormDialog].
Future<SolutionResponse?> showSolutionFormDialog(
  BuildContext context, {
  SolutionResponse? existingSolution,
}) {
  return showDialog<SolutionResponse>(
    context: context,
    builder: (_) => SolutionFormDialog(existingSolution: existingSolution),
  );
}
