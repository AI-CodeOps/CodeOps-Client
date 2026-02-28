/// Create / edit form dialog for a service profile.
///
/// Collects service name, image, command, health check, resource limits,
/// restart policy, and other configuration fields. Returns a
/// [CreateServiceProfileRequest] for create mode or an
/// [UpdateServiceProfileRequest] for edit mode.
library;

import 'package:flutter/material.dart';

import '../../models/fleet_enums.dart';
import '../../models/fleet_models.dart';
import '../../theme/colors.dart';

/// A dialog that collects service profile configuration.
///
/// When [existing] is provided, the form is pre-populated for editing
/// and returns an [UpdateServiceProfileRequest]. Otherwise returns a
/// [CreateServiceProfileRequest].
class ServiceProfileFormDialog extends StatefulWidget {
  /// Existing profile detail for edit mode; null for create mode.
  final FleetServiceProfileDetail? existing;

  /// Creates a [ServiceProfileFormDialog].
  const ServiceProfileFormDialog({super.key, this.existing});

  /// Shows the dialog and returns the result.
  ///
  /// Returns a [CreateServiceProfileRequest] for create or
  /// [UpdateServiceProfileRequest] for edit, or `null` if cancelled.
  static Future<Object?> show(
    BuildContext context, {
    FleetServiceProfileDetail? existing,
  }) {
    return showDialog<Object>(
      context: context,
      builder: (_) => ServiceProfileFormDialog(existing: existing),
    );
  }

  @override
  State<ServiceProfileFormDialog> createState() =>
      _ServiceProfileFormDialogState();
}

class _ServiceProfileFormDialogState extends State<ServiceProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serviceNameCtrl;
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _imageNameCtrl;
  late final TextEditingController _imageTagCtrl;
  late final TextEditingController _commandCtrl;
  late final TextEditingController _workingDirCtrl;
  late final TextEditingController _envVarsCtrl;
  late final TextEditingController _portsCtrl;
  late final TextEditingController _healthCmdCtrl;
  late final TextEditingController _healthIntervalCtrl;
  late final TextEditingController _healthTimeoutCtrl;
  late final TextEditingController _healthRetriesCtrl;
  late final TextEditingController _memoryLimitCtrl;
  late final TextEditingController _cpuLimitCtrl;
  late final TextEditingController _startOrderCtrl;
  RestartPolicy? _restartPolicy;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _serviceNameCtrl = TextEditingController(text: e?.serviceName ?? '');
    _displayNameCtrl = TextEditingController(text: e?.displayName ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _imageNameCtrl = TextEditingController(text: e?.imageName ?? '');
    _imageTagCtrl = TextEditingController(text: e?.imageTag ?? '');
    _commandCtrl = TextEditingController(text: e?.command ?? '');
    _workingDirCtrl = TextEditingController(text: e?.workingDir ?? '');
    _envVarsCtrl = TextEditingController(text: e?.envVarsJson ?? '');
    _portsCtrl = TextEditingController(text: e?.portsJson ?? '');
    _healthCmdCtrl = TextEditingController(text: e?.healthCheckCommand ?? '');
    _healthIntervalCtrl = TextEditingController(
        text: e?.healthCheckIntervalSeconds?.toString() ?? '');
    _healthTimeoutCtrl = TextEditingController(
        text: e?.healthCheckTimeoutSeconds?.toString() ?? '');
    _healthRetriesCtrl =
        TextEditingController(text: e?.healthCheckRetries?.toString() ?? '');
    _memoryLimitCtrl =
        TextEditingController(text: e?.memoryLimitMb?.toString() ?? '');
    _cpuLimitCtrl =
        TextEditingController(text: e?.cpuLimit?.toString() ?? '');
    _startOrderCtrl =
        TextEditingController(text: e?.startOrder?.toString() ?? '');
    _restartPolicy = e?.restartPolicy;
  }

  @override
  void dispose() {
    _serviceNameCtrl.dispose();
    _displayNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageNameCtrl.dispose();
    _imageTagCtrl.dispose();
    _commandCtrl.dispose();
    _workingDirCtrl.dispose();
    _envVarsCtrl.dispose();
    _portsCtrl.dispose();
    _healthCmdCtrl.dispose();
    _healthIntervalCtrl.dispose();
    _healthTimeoutCtrl.dispose();
    _healthRetriesCtrl.dispose();
    _memoryLimitCtrl.dispose();
    _cpuLimitCtrl.dispose();
    _startOrderCtrl.dispose();
    super.dispose();
  }

  /// Parses an optional integer from a text field.
  int? _parseInt(TextEditingController ctrl) {
    final t = ctrl.text.trim();
    return t.isEmpty ? null : int.tryParse(t);
  }

  /// Parses an optional double from a text field.
  double? _parseDouble(TextEditingController ctrl) {
    final t = ctrl.text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  /// Returns a trimmed string or null if empty.
  String? _trimOrNull(TextEditingController ctrl) {
    final t = ctrl.text.trim();
    return t.isEmpty ? null : t;
  }

  /// Validates and submits the form.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEdit) {
      final request = UpdateServiceProfileRequest(
        displayName: _trimOrNull(_displayNameCtrl),
        description: _trimOrNull(_descriptionCtrl),
        imageName: _trimOrNull(_imageNameCtrl),
        imageTag: _trimOrNull(_imageTagCtrl),
        command: _trimOrNull(_commandCtrl),
        workingDir: _trimOrNull(_workingDirCtrl),
        envVarsJson: _trimOrNull(_envVarsCtrl),
        portsJson: _trimOrNull(_portsCtrl),
        healthCheckCommand: _trimOrNull(_healthCmdCtrl),
        healthCheckIntervalSeconds: _parseInt(_healthIntervalCtrl),
        healthCheckTimeoutSeconds: _parseInt(_healthTimeoutCtrl),
        healthCheckRetries: _parseInt(_healthRetriesCtrl),
        restartPolicy: _restartPolicy,
        memoryLimitMb: _parseInt(_memoryLimitCtrl),
        cpuLimit: _parseDouble(_cpuLimitCtrl),
        startOrder: _parseInt(_startOrderCtrl),
      );
      Navigator.of(context).pop(request);
    } else {
      final request = CreateServiceProfileRequest(
        serviceName: _serviceNameCtrl.text.trim(),
        imageName: _imageNameCtrl.text.trim(),
        displayName: _trimOrNull(_displayNameCtrl),
        description: _trimOrNull(_descriptionCtrl),
        imageTag: _trimOrNull(_imageTagCtrl),
        command: _trimOrNull(_commandCtrl),
        workingDir: _trimOrNull(_workingDirCtrl),
        envVarsJson: _trimOrNull(_envVarsCtrl),
        portsJson: _trimOrNull(_portsCtrl),
        healthCheckCommand: _trimOrNull(_healthCmdCtrl),
        healthCheckIntervalSeconds: _parseInt(_healthIntervalCtrl),
        healthCheckTimeoutSeconds: _parseInt(_healthTimeoutCtrl),
        healthCheckRetries: _parseInt(_healthRetriesCtrl),
        restartPolicy: _restartPolicy,
        memoryLimitMb: _parseInt(_memoryLimitCtrl),
        cpuLimit: _parseDouble(_cpuLimitCtrl),
        startOrder: _parseInt(_startOrderCtrl),
      );
      Navigator.of(context).pop(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(_isEdit ? 'Edit Service Profile' : 'Create Service Profile'),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Required Fields ──
                if (!_isEdit) ...[
                  TextFormField(
                    controller: _serviceNameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Service Name *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _imageNameCtrl,
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'Image Name' : 'Image Name *',
                  ),
                  validator: _isEdit
                      ? null
                      : (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageTagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image Tag',
                    hintText: 'latest',
                  ),
                ),
                const SizedBox(height: 12),

                // ── Optional Fields ──
                TextFormField(
                  controller: _displayNameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Display Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commandCtrl,
                  decoration: const InputDecoration(labelText: 'Command'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _workingDirCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Working Directory'),
                ),
                const SizedBox(height: 12),

                // ── Restart Policy ──
                DropdownButtonFormField<RestartPolicy>(
                  value: _restartPolicy,
                  decoration:
                      const InputDecoration(labelText: 'Restart Policy'),
                  dropdownColor: CodeOpsColors.surfaceVariant,
                  items: RestartPolicy.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _restartPolicy = v),
                ),
                const SizedBox(height: 12),

                // ── Health Check ──
                TextFormField(
                  controller: _healthCmdCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Health Check Command'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _healthIntervalCtrl,
                        decoration:
                            const InputDecoration(labelText: 'HC Interval (s)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _healthTimeoutCtrl,
                        decoration:
                            const InputDecoration(labelText: 'HC Timeout (s)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _healthRetriesCtrl,
                        decoration:
                            const InputDecoration(labelText: 'HC Retries'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Resource Limits ──
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _memoryLimitCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Memory Limit (MB)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cpuLimitCtrl,
                        decoration:
                            const InputDecoration(labelText: 'CPU Limit'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startOrderCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Start Order'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // ── JSON Fields ──
                TextFormField(
                  controller: _envVarsCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Env Vars (JSON)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _portsCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Ports (JSON)'),
                  maxLines: 2,
                ),
              ],
            ),
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
          child: Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
