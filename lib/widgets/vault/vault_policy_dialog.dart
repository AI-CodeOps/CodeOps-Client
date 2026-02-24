/// Dialog for creating or editing a Vault access policy (CVF-004).
///
/// Supports both create and edit modes. Edit mode pre-populates all fields
/// from an existing [AccessPolicyResponse]. Validates required fields (name,
/// pathPattern, at least one permission) and path format (must start with `/`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_enums.dart';
import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A modal dialog for creating or editing an access policy.
///
/// Pass [policy] to enable edit mode. Omit it for create mode.
class VaultPolicyDialog extends ConsumerStatefulWidget {
  /// The existing policy to edit (null for create mode).
  final AccessPolicyResponse? policy;

  /// Creates a [VaultPolicyDialog].
  const VaultPolicyDialog({super.key, this.policy});

  @override
  ConsumerState<VaultPolicyDialog> createState() => _VaultPolicyDialogState();
}

class _VaultPolicyDialogState extends ConsumerState<VaultPolicyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pathPatternController = TextEditingController();
  final _descriptionController = TextEditingController();

  final Set<PolicyPermission> _selectedPermissions = {};
  bool _isDenyPolicy = false;
  bool _submitting = false;

  bool get _isEditing => widget.policy != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.policy!;
      _nameController.text = p.name;
      _pathPatternController.text = p.pathPattern;
      _descriptionController.text = p.description ?? '';
      _selectedPermissions.addAll(p.permissions);
      _isDenyPolicy = p.isDenyPolicy;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathPatternController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(_isEditing ? 'Edit Policy' : 'Create Policy'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'read-only-db-secrets',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLength: 200,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Path Pattern
                TextFormField(
                  controller: _pathPatternController,
                  decoration: const InputDecoration(
                    labelText: 'Path Pattern *',
                    hintText: '/services/*/db-*',
                    border: OutlineInputBorder(),
                    isDense: true,
                    helperText:
                        'Use * for single-segment wildcards. '
                        'Example: /apps/*/secrets matches /apps/api/secrets '
                        'but not /apps/api/v2/secrets',
                    helperMaxLines: 3,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Path pattern is required';
                    }
                    if (!v.startsWith('/')) {
                      return 'Path must start with /';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                // Permissions
                const Text(
                  'Permissions *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                FormField<Set<PolicyPermission>>(
                  initialValue: _selectedPermissions,
                  validator: (_) {
                    if (_selectedPermissions.isEmpty) {
                      return 'Select at least one permission';
                    }
                    return null;
                  },
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: PolicyPermission.values.map((p) {
                            final selected = _selectedPermissions.contains(p);
                            final color =
                                CodeOpsColors.policyPermissionColors[p] ??
                                    CodeOpsColors.textTertiary;
                            return FilterChip(
                              label: Text(
                                p.displayName,
                                style: TextStyle(fontSize: 11, color: color),
                              ),
                              selected: selected,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedPermissions.add(p);
                                  } else {
                                    _selectedPermissions.remove(p);
                                  }
                                });
                                field.didChange(_selectedPermissions);
                              },
                              checkmarkColor: color,
                              selectedColor: color.withValues(alpha: 0.15),
                              backgroundColor: CodeOpsColors.background,
                              side: BorderSide(
                                color: selected
                                    ? color.withValues(alpha: 0.5)
                                    : CodeOpsColors.border,
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              field.errorText!,
                              style: const TextStyle(
                                color: CodeOpsColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Deny Policy toggle
                Row(
                  children: [
                    Switch(
                      value: _isDenyPolicy,
                      onChanged: (v) => setState(() => _isDenyPolicy = v),
                      activeTrackColor: CodeOpsColors.error,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Deny Policy',
                      style: TextStyle(
                        fontSize: 13,
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message:
                          'Deny policies override allow policies for matching paths',
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                if (_isDenyPolicy)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: CodeOpsColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 14, color: CodeOpsColors.error),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This policy will DENY the selected permissions '
                              'for matching paths, overriding any allow policies.',
                              style: TextStyle(
                                fontSize: 11,
                                color: CodeOpsColors.error,
                              ),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(vaultApiProvider);
      final name = _nameController.text.trim();
      final pathPattern = _pathPatternController.text.trim();
      final description = _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text.trim();
      final permissions = _selectedPermissions.toList();

      if (_isEditing) {
        await api.updatePolicy(
          widget.policy!.id,
          name: name,
          pathPattern: pathPattern,
          description: description,
          permissions: permissions,
          isDenyPolicy: _isDenyPolicy,
        );
      } else {
        await api.createPolicy(
          name: name,
          pathPattern: pathPattern,
          permissions: permissions,
          description: description,
          isDenyPolicy: _isDenyPolicy ? true : null,
        );
      }

      ref.invalidate(vaultPoliciesProvider);
      ref.invalidate(vaultPolicyStatsProvider);
      if (_isEditing) {
        ref.invalidate(vaultPolicyDetailProvider(widget.policy!.id));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Policy updated' : 'Policy created'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${_isEditing ? "update" : "create"}: $e',
            ),
          ),
        );
      }
    }
  }
}
