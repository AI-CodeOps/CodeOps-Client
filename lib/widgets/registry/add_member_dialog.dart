/// Dialog for adding a service to a solution.
///
/// Shows a searchable list of team services not already in the
/// solution, with role selection and optional notes field.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_enums.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../shared/notification_toast.dart';

/// Dialog for adding a service member to a solution.
///
/// Filters out services already in the solution via
/// [existingMemberServiceIds]. On submit, calls
/// [RegistryApi.addSolutionMember].
class AddMemberDialog extends ConsumerStatefulWidget {
  /// The solution to add a member to.
  final String solutionId;

  /// Service IDs already in the solution (to exclude from selection).
  final Set<String> existingMemberServiceIds;

  /// Creates an [AddMemberDialog].
  const AddMemberDialog({
    super.key,
    required this.solutionId,
    required this.existingMemberServiceIds,
  });

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedServiceId;
  SolutionMemberRole _selectedRole = SolutionMemberRole.supporting;
  late final TextEditingController _notesController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(registryApiProvider);
      await api.addSolutionMember(
        widget.solutionId,
        serviceId: _selectedServiceId!,
        role: _selectedRole,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      ref.invalidate(registrySolutionFullDetailProvider(widget.solutionId));
      ref.invalidate(registrySolutionHealthProvider(widget.solutionId));
      if (mounted) {
        showToast(context,
            message: 'Member added', type: ToastType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Failed to add member: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(registryServicesProvider);
    final allServices = servicesAsync.valueOrNull?.content ?? [];
    final availableServices = allServices
        .where((s) => !widget.existingMemberServiceIds.contains(s.id))
        .toList();

    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 480),
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
                    const Icon(Icons.person_add_outlined,
                        size: 20, color: CodeOpsColors.primary),
                    const SizedBox(width: 10),
                    const Text(
                      'Add Member',
                      style: TextStyle(
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
                      // Service selector
                      DropdownButtonFormField<String>(
                        initialValue: _selectedServiceId,
                        decoration: const InputDecoration(
                          labelText: 'Service *',
                          isDense: true,
                        ),
                        isExpanded: true,
                        dropdownColor: CodeOpsColors.surface,
                        items: availableServices.map((svc) {
                          return DropdownMenuItem(
                            value: svc.id,
                            child: Text(
                              svc.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: CodeOpsColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedServiceId = v),
                        validator: (v) =>
                            v == null ? 'Select a service' : null,
                      ),
                      const SizedBox(height: 16),
                      // Role selector
                      DropdownButtonFormField<SolutionMemberRole>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role *',
                          isDense: true,
                        ),
                        isExpanded: true,
                        dropdownColor: CodeOpsColors.surface,
                        items: SolutionMemberRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(
                              role.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: CodeOpsColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedRole = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Optional notes about this member',
                          isDense: true,
                        ),
                        maxLength: 500,
                        maxLines: 2,
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
                              : const Text('Add Member'),
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

/// Shows the [AddMemberDialog].
Future<void> showAddMemberDialog(
  BuildContext context, {
  required String solutionId,
  required Set<String> existingMemberServiceIds,
}) {
  return showDialog(
    context: context,
    builder: (_) => AddMemberDialog(
      solutionId: solutionId,
      existingMemberServiceIds: existingMemberServiceIds,
    ),
  );
}
