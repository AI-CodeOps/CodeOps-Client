/// Dialog for creating or editing a workstation profile.
///
/// Create mode: empty form, calls [RegistryApi.createWorkstationProfile].
/// Edit mode: pre-filled from [existingProfile], calls
/// [RegistryApi.updateWorkstationProfile]. Includes a [ServicePicker]
/// for selecting which services belong to the profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';
import '../shared/notification_toast.dart';
import 'service_picker.dart';

/// Create/edit dialog for workstation profiles.
///
/// When [existingProfile] is null, operates in create mode.
/// When provided, operates in edit mode with pre-filled fields.
class WorkstationFormDialog extends ConsumerStatefulWidget {
  /// Existing profile for edit mode. Null for create mode.
  final WorkstationProfileResponse? existingProfile;

  /// Creates a [WorkstationFormDialog].
  const WorkstationFormDialog({super.key, this.existingProfile});

  /// Whether this dialog is in edit mode.
  bool get isEditMode => existingProfile != null;

  @override
  ConsumerState<WorkstationFormDialog> createState() =>
      _WorkstationFormDialogState();
}

class _WorkstationFormDialogState extends ConsumerState<WorkstationFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  Set<String> _selectedServiceIds = {};
  bool _isDefault = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController =
        TextEditingController(text: p?.description ?? '');
    _isDefault = p?.isDefault == true;
    _selectedServiceIds = p?.serviceIds?.toSet() ?? {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(registryApiProvider);
      if (widget.isEditMode) {
        await api.updateWorkstationProfile(
          widget.existingProfile!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          serviceIds: _selectedServiceIds.toList(),
          isDefault: _isDefault,
        );
        ref.invalidate(registryWorkstationProfileDetailProvider(
            widget.existingProfile!.id));
        ref.invalidate(registryWorkstationProfilesProvider);
        if (mounted) {
          showToast(context,
              message: 'Profile updated', type: ToastType.success);
          Navigator.of(context).pop();
        }
      } else {
        final teamId = ref.read(selectedTeamIdProvider);
        if (teamId == null) return;
        final result = await api.createWorkstationProfile(
          teamId: teamId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          serviceIds: _selectedServiceIds.toList(),
          isDefault: _isDefault,
        );
        ref.invalidate(registryWorkstationProfilesProvider);
        if (mounted) {
          showToast(context,
              message: 'Profile "${result.name}" created',
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
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
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
                    const Icon(Icons.computer,
                        size: 20, color: CodeOpsColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      widget.isEditMode
                          ? 'Edit Workstation Profile'
                          : 'Create Workstation Profile',
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
                          hintText: 'Profile name',
                          isDense: true,
                        ),
                        maxLength: 100,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
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
                      // Default checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isDefault,
                              onChanged: (v) =>
                                  setState(() => _isDefault = v ?? false),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isDefault = !_isDefault),
                            child: const Text(
                              'Set as default profile',
                              style: TextStyle(
                                fontSize: 13,
                                color: CodeOpsColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.star,
                              size: 14, color: CodeOpsColors.warning),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Service picker label
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CodeOpsColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Service picker
                      ServicePicker(
                        selectedServiceIds: _selectedServiceIds,
                        onChanged: (ids) =>
                            setState(() => _selectedServiceIds = ids),
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
                                  : 'Create Profile'),
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

/// Shows the [WorkstationFormDialog].
Future<WorkstationProfileResponse?> showWorkstationFormDialog(
  BuildContext context, {
  WorkstationProfileResponse? existingProfile,
}) {
  return showDialog<WorkstationProfileResponse>(
    context: context,
    builder: (_) =>
        WorkstationFormDialog(existingProfile: existingProfile),
  );
}
