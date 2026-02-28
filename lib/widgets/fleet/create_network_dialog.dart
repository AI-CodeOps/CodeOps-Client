/// Dialog for creating a Docker network.
///
/// Collects a network name, optional driver, subnet, and gateway.
/// Returns a record on submission, or `null` if cancelled.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A dialog that lets the user create a new Docker network.
///
/// Returns `({String name, String driver, String? subnet, String? gateway})`
/// when submitted, or `null` if cancelled.
class CreateNetworkDialog extends StatefulWidget {
  /// Creates a [CreateNetworkDialog].
  const CreateNetworkDialog({super.key});

  /// Shows the dialog and returns the result.
  static Future<
      ({String name, String driver, String? subnet, String? gateway})?> show(
    BuildContext context,
  ) {
    return showDialog<
        ({String name, String driver, String? subnet, String? gateway})>(
      context: context,
      builder: (_) => const CreateNetworkDialog(),
    );
  }

  @override
  State<CreateNetworkDialog> createState() => _CreateNetworkDialogState();
}

class _CreateNetworkDialogState extends State<CreateNetworkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _driverCtrl = TextEditingController(text: 'bridge');
  final _subnetCtrl = TextEditingController();
  final _gatewayCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _driverCtrl.dispose();
    _subnetCtrl.dispose();
    _gatewayCtrl.dispose();
    super.dispose();
  }

  /// Validates and submits the form.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final subnet = _subnetCtrl.text.trim();
    final gateway = _gatewayCtrl.text.trim();

    Navigator.of(context).pop((
      name: _nameCtrl.text.trim(),
      driver: _driverCtrl.text.trim().isEmpty
          ? 'bridge'
          : _driverCtrl.text.trim(),
      subnet: subnet.isEmpty ? null : subnet,
      gateway: gateway.isEmpty ? null : gateway,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Create Network'),
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
                  labelText: 'Network Name *',
                  hintText: 'e.g. my-app-network',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _driverCtrl,
                decoration: const InputDecoration(
                  labelText: 'Driver',
                  hintText: 'bridge',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subnetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subnet',
                  hintText: 'e.g. 172.18.0.0/16',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gatewayCtrl,
                decoration: const InputDecoration(
                  labelText: 'Gateway',
                  hintText: 'e.g. 172.18.0.1',
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
