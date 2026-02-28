/// Dialog for creating a Docker volume.
///
/// Collects a volume name and optional driver. Returns a record of
/// `({String name, String driver})` on submission, or `null` if cancelled.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A dialog that lets the user create a new Docker volume.
///
/// Returns `({String name, String driver})` when submitted,
/// or `null` if cancelled.
class CreateVolumeDialog extends StatefulWidget {
  /// Creates a [CreateVolumeDialog].
  const CreateVolumeDialog({super.key});

  /// Shows the dialog and returns the result.
  static Future<({String name, String driver})?> show(
      BuildContext context) {
    return showDialog<({String name, String driver})>(
      context: context,
      builder: (_) => const CreateVolumeDialog(),
    );
  }

  @override
  State<CreateVolumeDialog> createState() => _CreateVolumeDialogState();
}

class _CreateVolumeDialogState extends State<CreateVolumeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _driverCtrl = TextEditingController(text: 'local');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _driverCtrl.dispose();
    super.dispose();
  }

  /// Validates and submits the form.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop((
      name: _nameCtrl.text.trim(),
      driver:
          _driverCtrl.text.trim().isEmpty ? 'local' : _driverCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Create Volume'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Volume Name *',
                  hintText: 'e.g. my-data-volume',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _driverCtrl,
                decoration: const InputDecoration(
                  labelText: 'Driver',
                  hintText: 'local',
                ),
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
          child: const Text('Create'),
        ),
      ],
    );
  }
}
