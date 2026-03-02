/// Persona editor page with form fields, split markdown editor/preview.
///
/// Supports create (personaId='new') and edit modes. System-scoped
/// personas are displayed read-only.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:split_view/split_view.dart';

import '../models/enums.dart';
import '../models/persona.dart';
import '../providers/persona_providers.dart';
import '../providers/team_providers.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../widgets/personas/persona_editor.dart';
import '../widgets/personas/persona_preview.dart';
import '../widgets/personas/persona_test_runner.dart';
import '../widgets/shared/confirm_dialog.dart';
import '../widgets/shared/notification_toast.dart';

/// The persona editor page replacing the `/personas/:id/edit` placeholder.
class PersonaEditorPage extends ConsumerStatefulWidget {
  /// The persona ID, or 'new' for create mode.
  final String personaId;

  /// Creates a [PersonaEditorPage].
  const PersonaEditorPage({super.key, required this.personaId});

  @override
  ConsumerState<PersonaEditorPage> createState() => _PersonaEditorPageState();
}

class _PersonaEditorPageState extends ConsumerState<PersonaEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String _contentMd = '';
  AgentType? _agentType;
  Scope _scope = Scope.team;
  bool _isDefault = false;
  bool _loading = true;
  bool _saving = false;
  Persona? _existingPersona;

  bool get _isCreateMode => widget.personaId == 'new';
  bool get _isSystem => _existingPersona?.scope == Scope.system;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadPersona();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPersona() async {
    if (_isCreateMode) {
      setState(() => _loading = false);
      return;
    }

    try {
      final api = ref.read(personaApiProvider);
      final persona = await api.getPersona(widget.personaId);
      if (mounted) {
        setState(() {
          _existingPersona = persona;
          _nameController.text = persona.name;
          _descriptionController.text = persona.description ?? '';
          _contentMd = persona.contentMd ?? '';
          _agentType = persona.agentType;
          _scope = persona.scope;
          _isDefault = persona.isDefault ?? false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showToast(context,
            message: 'Failed to load persona: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Check content size.
    final sizeKb = _contentMd.length / 1024;
    if (sizeKb > AppConstants.maxPersonaSizeKb) {
      showToast(context,
          message:
              'Content too large (${sizeKb.toStringAsFixed(1)} KB). '
              'Max is ${AppConstants.maxPersonaSizeKb} KB.',
          type: ToastType.error);
      return;
    }

    setState(() => _saving = true);

    try {
      final api = ref.read(personaApiProvider);

      if (_isCreateMode) {
        final teamId = ref.read(selectedTeamIdProvider);
        final persona = await api.createPersona(
          name: _nameController.text.trim(),
          contentMd: _contentMd,
          scope: _scope,
          agentType: _agentType,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          teamId: teamId,
          isDefault: _isDefault,
        );
        ref.invalidate(teamPersonasProvider);
        if (mounted) {
          showToast(context,
              message: 'Persona "${persona.name}" created',
              type: ToastType.success);
          context.go('/personas/${persona.id}/edit');
        }
      } else {
        await api.updatePersona(
          widget.personaId,
          name: _nameController.text.trim(),
          contentMd: _contentMd,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isDefault: _isDefault,
        );
        ref.invalidate(teamPersonasProvider);
        ref.invalidate(systemPersonasProvider);
        if (mounted) {
          showToast(context,
              message: 'Persona saved', type: ToastType.success);
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

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Persona',
      message:
          'Are you sure you want to delete "${_nameController.text}"? '
          'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      final api = ref.read(personaApiProvider);
      await api.deletePersona(widget.personaId);
      ref.invalidate(teamPersonasProvider);
      if (mounted) {
        showToast(context,
            message: 'Persona deleted', type: ToastType.success);
        context.go('/personas');
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Delete failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _export() async {
    try {
      final name = _nameController.text.trim().isEmpty
          ? 'persona'
          : _nameController.text.trim().replaceAll(RegExp(r'[^\w\s-]'), '');

      final result = await FilePicker.platform.saveFile(
        fileName: '$name.md',
        allowedExtensions: ['md'],
        type: FileType.custom,
      );
      if (result == null) return;

      await File(result).writeAsString(_contentMd);
      if (mounted) {
        showToast(context,
            message: 'Exported to $result', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Export failed: $e', type: ToastType.error);
      }
    }
  }

  void _test() {
    showPersonaTestRunner(
      context,
      personaName: _nameController.text.trim().isEmpty
          ? 'Untitled'
          : _nameController.text.trim(),
      personaContent: _contentMd,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      );
    }

    return Column(
      children: [
        // Top bar.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Row(
            children: [
              // Back button.
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                tooltip: 'Back to Personas',
                onPressed: () => context.go('/personas'),
              ),
              const SizedBox(width: 12),
              Text(
                _isCreateMode ? 'New Persona' : _nameController.text,
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              if (_isSystem) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.textTertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SYSTEM (Read-Only)',
                    style: TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Actions.
              OutlinedButton.icon(
                onPressed: _test,
                icon: const Icon(Icons.science, size: 18),
                label: const Text('Test'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
              ),
              if (!_isSystem && !_isCreateMode) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: CodeOpsColors.error),
                  label: const Text('Delete',
                      style: TextStyle(color: CodeOpsColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CodeOpsColors.error),
                  ),
                ),
              ],
              if (!_isSystem) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ],
          ),
        ),
        // System banner.
        if (_isSystem)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: CodeOpsColors.warning.withValues(alpha: 0.1),
            child: const Text(
              'System personas are read-only. Duplicate to create an editable copy.',
              style: TextStyle(
                color: CodeOpsColors.warning,
                fontSize: 13,
              ),
            ),
          ),
        // Form fields.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name.
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    enabled: !_isSystem,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      hintText: 'Persona name',
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.length > 100) return 'Max 100 characters';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Agent type.
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<AgentType?>(
                    initialValue: _agentType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Agent Type',
                      isDense: true,
                    ),
                    dropdownColor: CodeOpsColors.surfaceVariant,
                    items: [
                      const DropdownMenuItem<AgentType?>(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...AgentType.values.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ),
                      ),
                    ],
                    onChanged: _isSystem
                        ? null
                        : (v) => setState(() => _agentType = v),
                  ),
                ),
                const SizedBox(width: 12),
                // Scope.
                Expanded(
                  child: DropdownButtonFormField<Scope>(
                    initialValue: _scope,
                    decoration: const InputDecoration(
                      labelText: 'Scope',
                      isDense: true,
                    ),
                    dropdownColor: CodeOpsColors.surfaceVariant,
                    items: Scope.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.displayName),
                          ),
                        )
                        .toList(),
                    onChanged:
                        (_isSystem || !_isCreateMode) ? null : (v) {
                          if (v != null) setState(() => _scope = v);
                        },
                  ),
                ),
                const SizedBox(width: 12),
                // Description.
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _descriptionController,
                    enabled: !_isSystem,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Brief description',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Default toggle.
                Column(
                  children: [
                    const Text(
                      'Default',
                      style: TextStyle(
                        color: CodeOpsColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      onChanged: _isSystem
                          ? null
                          : (v) => setState(() => _isDefault = v),
                      activeTrackColor: CodeOpsColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Split editor / preview.
        Expanded(
          child: SplitView(
            viewMode: SplitViewMode.Horizontal,
            gripColor: CodeOpsColors.border,
            gripSize: 4,
            controller: SplitViewController(weights: [0.5, 0.5]),
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CodeOpsColors.border),
                    right: BorderSide(color: CodeOpsColors.border),
                  ),
                ),
                child: PersonaEditorWidget(
                  initialContent: _contentMd,
                  onChanged: (value) => _contentMd = value,
                  readOnly: _isSystem,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CodeOpsColors.border),
                  ),
                ),
                child: PersonaPreview(
                  content: _contentMd,
                  showValidation: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
