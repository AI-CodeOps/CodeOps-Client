/// Dialog for creating or editing an infrastructure resource.
///
/// Provides form fields for all [CreateInfraResourceRequest] /
/// [UpdateInfraResourceRequest] properties with validation and
/// submit handling.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../providers/team_providers.dart';
import '../../services/cloud/registry_api.dart';
import '../../theme/colors.dart';

/// Dialog for creating or editing an infrastructure resource.
///
/// In create mode (existingResource == null), submits a new resource via
/// [RegistryApi.createInfraResource]. In edit mode, submits an update via
/// [RegistryApi.updateInfraResource].
class InfraResourceFormDialog extends ConsumerStatefulWidget {
  /// The existing resource when editing, or null for create mode.
  final InfraResourceResponse? existingResource;

  /// The team ID to create the resource under (used in create mode).
  final String? teamId;

  /// Creates an [InfraResourceFormDialog].
  const InfraResourceFormDialog({
    super.key,
    this.existingResource,
    this.teamId,
  });

  /// Whether the dialog is in edit mode.
  bool get isEditMode => existingResource != null;

  @override
  ConsumerState<InfraResourceFormDialog> createState() =>
      _InfraResourceFormDialogState();
}

class _InfraResourceFormDialogState
    extends ConsumerState<InfraResourceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late InfraResourceType? _resourceType;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _environmentCtrl;
  late final TextEditingController _regionCtrl;
  late final TextEditingController _arnCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _metadataCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existingResource;
    _resourceType = r?.resourceType;
    _nameCtrl = TextEditingController(text: r?.resourceName ?? '');
    _environmentCtrl = TextEditingController(text: r?.environment ?? '');
    _regionCtrl = TextEditingController(text: r?.region ?? '');
    _arnCtrl = TextEditingController(text: r?.arnOrUrl ?? '');
    _descriptionCtrl = TextEditingController(text: r?.description ?? '');
    _metadataCtrl = TextEditingController(text: r?.metadataJson ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _environmentCtrl.dispose();
    _regionCtrl.dispose();
    _arnCtrl.dispose();
    _descriptionCtrl.dispose();
    _metadataCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(registryApiProvider);
      if (widget.isEditMode) {
        await api.updateInfraResource(
          widget.existingResource!.id,
          resourceName:
              _nameCtrl.text.isEmpty ? null : _nameCtrl.text,
          region: _regionCtrl.text.isEmpty ? null : _regionCtrl.text,
          arnOrUrl: _arnCtrl.text.isEmpty ? null : _arnCtrl.text,
          description:
              _descriptionCtrl.text.isEmpty ? null : _descriptionCtrl.text,
          metadataJson:
              _metadataCtrl.text.isEmpty ? null : _metadataCtrl.text,
        );
      } else {
        final teamId =
            widget.teamId ?? ref.read(selectedTeamIdProvider);
        if (teamId == null) return;
        await api.createInfraResource(
          teamId: teamId,
          resourceType: _resourceType!,
          resourceName: _nameCtrl.text,
          environment: _environmentCtrl.text,
          region: _regionCtrl.text.isEmpty ? null : _regionCtrl.text,
          arnOrUrl: _arnCtrl.text.isEmpty ? null : _arnCtrl.text,
          description:
              _descriptionCtrl.text.isEmpty ? null : _descriptionCtrl.text,
          metadataJson:
              _metadataCtrl.text.isEmpty ? null : _metadataCtrl.text,
        );
      }
      ref.invalidate(registryInfraResourcesProvider);
      ref.invalidate(registryOrphanedResourcesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isEditMode ? 'Edit Resource' : 'Add Infrastructure Resource';

    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resource Type
                  if (!widget.isEditMode) ...[
                    const _FieldLabel('Resource Type *'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<InfraResourceType>(
                      initialValue: _resourceType,
                      decoration: _inputDecoration(),
                      dropdownColor: CodeOpsColors.surface,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CodeOpsColors.textPrimary,
                      ),
                      items: InfraResourceType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              ))
                          .toList(),
                      validator: (v) =>
                          v == null ? 'Resource type is required' : null,
                      onChanged: (v) => setState(() => _resourceType = v),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Resource Name
                  const _FieldLabel('Resource Name *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDecoration(hint: 'e.g., codeops-assets'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLength: 300,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Environment
                  if (!widget.isEditMode) ...[
                    const _FieldLabel('Environment *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _environmentCtrl,
                      decoration: _inputDecoration(hint: 'e.g., dev'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: CodeOpsColors.textPrimary,
                      ),
                      maxLength: 50,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Environment is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Region
                  const _FieldLabel('Region'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _regionCtrl,
                    decoration: _inputDecoration(hint: 'e.g., us-east-1'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLength: 30,
                  ),
                  const SizedBox(height: 16),

                  // ARN / URL
                  const _FieldLabel('ARN / URL'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _arnCtrl,
                    decoration: _inputDecoration(
                        hint: 'arn:aws:s3:::my-bucket'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const _FieldLabel('Description'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: _inputDecoration(hint: 'Optional description'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),

                  // Metadata JSON (collapsible)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text(
                      'Metadata JSON',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                    children: [
                      TextFormField(
                        controller: _metadataCtrl,
                        decoration: _inputDecoration(hint: '{"key": "value"}'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: CodeOpsColors.textPrimary,
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: CodeOpsColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.isEditMode ? 'Update' : 'Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: CodeOpsColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.primary),
        ),
        counterStyle: const TextStyle(
          fontSize: 10,
          color: CodeOpsColors.textTertiary,
        ),
      );
}

/// Reusable field label.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CodeOpsColors.textSecondary,
      ),
    );
  }
}
