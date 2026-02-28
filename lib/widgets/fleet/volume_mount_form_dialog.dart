/// Dialog for adding a volume mount to a service profile.
///
/// Presents a form with fields for container path, host path,
/// volume name, and read-only toggle. Returns a
/// [CreateVolumeMountRequest] on submission.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_models.dart';
import '../../theme/colors.dart';

/// A dialog that collects volume mount configuration from the user.
///
/// Returns a [CreateVolumeMountRequest] when submitted, or `null`
/// if cancelled.
class VolumeMountFormDialog extends StatefulWidget {
  /// Creates a [VolumeMountFormDialog].
  const VolumeMountFormDialog({super.key});

  /// Shows the dialog and returns the result.
  static Future<CreateVolumeMountRequest?> show(BuildContext context) {
    return showDialog<CreateVolumeMountRequest>(
      context: context,
      builder: (_) => const VolumeMountFormDialog(),
    );
  }

  @override
  State<VolumeMountFormDialog> createState() => _VolumeMountFormDialogState();
}

class _VolumeMountFormDialogState extends State<VolumeMountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _containerPathCtrl = TextEditingController();
  final _hostPathCtrl = TextEditingController();
  final _volumeNameCtrl = TextEditingController();
  bool _isReadOnly = false;

  @override
  void dispose() {
    _containerPathCtrl.dispose();
    _hostPathCtrl.dispose();
    _volumeNameCtrl.dispose();
    super.dispose();
  }

  /// Validates and submits the form.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateVolumeMountRequest(
      containerPath: _containerPathCtrl.text.trim(),
      hostPath:
          _hostPathCtrl.text.trim().isEmpty ? null : _hostPathCtrl.text.trim(),
      volumeName: _volumeNameCtrl.text.trim().isEmpty
          ? null
          : _volumeNameCtrl.text.trim(),
      isReadOnly: _isReadOnly ? true : null,
    );
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Add Volume Mount'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _containerPathCtrl,
                decoration: const InputDecoration(
                  labelText: 'Container Path *',
                  hintText: '/var/lib/data',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hostPathCtrl,
                decoration: const InputDecoration(
                  labelText: 'Host Path',
                  hintText: '/host/data',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _volumeNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Volume Name',
                  hintText: 'my-volume',
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Read Only'),
                value: _isReadOnly,
                onChanged: (v) => setState(() => _isReadOnly = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
