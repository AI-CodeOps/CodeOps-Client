/// Dialog for adding a network configuration to a service profile.
///
/// Presents a form with fields for network name, aliases, and
/// IP address. Returns a [CreateNetworkConfigRequest] on submission.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_models.dart';
import '../../theme/colors.dart';

/// A dialog that collects network configuration from the user.
///
/// Returns a [CreateNetworkConfigRequest] when submitted, or `null`
/// if cancelled.
class NetworkConfigFormDialog extends StatefulWidget {
  /// Creates a [NetworkConfigFormDialog].
  const NetworkConfigFormDialog({super.key});

  /// Shows the dialog and returns the result.
  static Future<CreateNetworkConfigRequest?> show(BuildContext context) {
    return showDialog<CreateNetworkConfigRequest>(
      context: context,
      builder: (_) => const NetworkConfigFormDialog(),
    );
  }

  @override
  State<NetworkConfigFormDialog> createState() =>
      _NetworkConfigFormDialogState();
}

class _NetworkConfigFormDialogState extends State<NetworkConfigFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _networkNameCtrl = TextEditingController();
  final _aliasesCtrl = TextEditingController();
  final _ipAddressCtrl = TextEditingController();

  @override
  void dispose() {
    _networkNameCtrl.dispose();
    _aliasesCtrl.dispose();
    _ipAddressCtrl.dispose();
    super.dispose();
  }

  /// Validates and submits the form.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateNetworkConfigRequest(
      networkName: _networkNameCtrl.text.trim(),
      aliases:
          _aliasesCtrl.text.trim().isEmpty ? null : _aliasesCtrl.text.trim(),
      ipAddress: _ipAddressCtrl.text.trim().isEmpty
          ? null
          : _ipAddressCtrl.text.trim(),
    );
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Add Network'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _networkNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Network Name *',
                  hintText: 'my-network',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aliasesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Aliases',
                  hintText: 'alias1,alias2',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ipAddressCtrl,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: '172.18.0.10',
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}
