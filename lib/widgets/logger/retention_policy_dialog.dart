/// Create/edit dialog for a retention policy.
///
/// Provides form fields for policy name, source filter, retention days,
/// action (purge/archive), archive destination, and active toggle.
library;

import 'package:flutter/material.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Dialog for creating or editing a [RetentionPolicyResponse].
class RetentionPolicyDialog extends StatefulWidget {
  /// Existing policy to edit, or null for create mode.
  final RetentionPolicyResponse? existing;

  /// Creates a [RetentionPolicyDialog].
  const RetentionPolicyDialog({super.key, this.existing});

  @override
  State<RetentionPolicyDialog> createState() => _RetentionPolicyDialogState();
}

class _RetentionPolicyDialogState extends State<RetentionPolicyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _daysCtrl;
  late final TextEditingController _archiveCtrl;
  late RetentionAction _action;
  late LogLevel? _logLevel;
  late bool _isActive;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _sourceCtrl =
        TextEditingController(text: widget.existing?.sourceName ?? '');
    _daysCtrl = TextEditingController(
      text: widget.existing?.retentionDays.toString() ?? '30',
    );
    _archiveCtrl = TextEditingController(
      text: widget.existing?.archiveDestination ?? '',
    );
    _action = widget.existing?.action ?? RetentionAction.purge;
    _logLevel = widget.existing?.logLevel;
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sourceCtrl.dispose();
    _daysCtrl.dispose();
    _archiveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(
        _isEdit ? 'Edit Retention Policy' : 'Create Retention Policy',
        style: const TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name.
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(
                      color: CodeOpsColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Policy Name',
                    labelStyle:
                        TextStyle(color: CodeOpsColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Source filter.
                TextFormField(
                  controller: _sourceCtrl,
                  style: const TextStyle(
                      color: CodeOpsColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Source Filter (optional)',
                    labelStyle:
                        TextStyle(color: CodeOpsColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Log level filter.
                DropdownButtonFormField<LogLevel?>(
                  initialValue: _logLevel,
                  dropdownColor: CodeOpsColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Log Level Filter',
                    labelStyle:
                        TextStyle(color: CodeOpsColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<LogLevel?>(
                      value: null,
                      child: Text('All Levels',
                          style: TextStyle(
                              color: CodeOpsColors.textPrimary,
                              fontSize: 13)),
                    ),
                    ...LogLevel.values.map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(l.displayName,
                            style: const TextStyle(
                                color: CodeOpsColors.textPrimary,
                                fontSize: 13)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _logLevel = v),
                ),
                const SizedBox(height: 12),

                // Retention days.
                TextFormField(
                  controller: _daysCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: CodeOpsColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Retention Days (1–365)',
                    labelStyle:
                        TextStyle(color: CodeOpsColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1 || n > 365) {
                      return 'Enter 1–365';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Action.
                DropdownButtonFormField<RetentionAction>(
                  initialValue: _action,
                  dropdownColor: CodeOpsColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    labelStyle:
                        TextStyle(color: CodeOpsColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  items: RetentionAction.values
                      .map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.displayName,
                              style: const TextStyle(
                                  color: CodeOpsColors.textPrimary,
                                  fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _action = v);
                  },
                ),
                const SizedBox(height: 12),

                // Archive destination (shown only for archive action).
                if (_action == RetentionAction.archive)
                  TextFormField(
                    controller: _archiveCtrl,
                    style: const TextStyle(
                        color: CodeOpsColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Archive Destination',
                      labelStyle:
                          TextStyle(color: CodeOpsColors.textSecondary),
                      border: OutlineInputBorder(),
                    ),
                  ),

                // Active toggle.
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text(
                    'Active',
                    style: TextStyle(
                        color: CodeOpsColors.textPrimary, fontSize: 13),
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: CodeOpsColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'sourceName':
          _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim(),
      'logLevel': _logLevel,
      'retentionDays': int.parse(_daysCtrl.text.trim()),
      'action': _action,
      'archiveDestination': _archiveCtrl.text.trim().isEmpty
          ? null
          : _archiveCtrl.text.trim(),
      'isActive': _isActive,
    };
    Navigator.of(context).pop(result);
  }
}
