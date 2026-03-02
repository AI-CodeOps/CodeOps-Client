/// Create/edit dialog for an anomaly detection baseline.
///
/// Provides form fields for service name, metric name, training window
/// (hours), and sensitivity threshold (deviation multiplier).
library;

import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';

/// Dialog for creating or editing an [AnomalyBaselineResponse].
class AnomalyBaselineDialog extends StatefulWidget {
  /// Existing baseline to edit, or null for create mode.
  final AnomalyBaselineResponse? existing;

  /// Creates an [AnomalyBaselineDialog].
  const AnomalyBaselineDialog({super.key, this.existing});

  @override
  State<AnomalyBaselineDialog> createState() => _AnomalyBaselineDialogState();
}

class _AnomalyBaselineDialogState extends State<AnomalyBaselineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _serviceCtrl;
  late final TextEditingController _metricCtrl;
  late final TextEditingController _windowCtrl;
  late double _threshold;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _serviceCtrl = TextEditingController(
      text: widget.existing?.serviceName ?? '',
    );
    _metricCtrl = TextEditingController(
      text: widget.existing?.metricName ?? '',
    );
    _windowCtrl = TextEditingController(
      text: _isEdit ? null : '24',
    );
    _threshold = widget.existing?.deviationThreshold ?? 2.0;
  }

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _metricCtrl.dispose();
    _windowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(
        _isEdit ? 'Edit Baseline' : 'Create Baseline',
        style: const TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service name.
              TextFormField(
                controller: _serviceCtrl,
                enabled: !_isEdit,
                style: const TextStyle(
                    color: CodeOpsColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  labelStyle:
                      TextStyle(color: CodeOpsColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Metric name.
              TextFormField(
                controller: _metricCtrl,
                enabled: !_isEdit,
                style: const TextStyle(
                    color: CodeOpsColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Metric Name',
                  labelStyle:
                      TextStyle(color: CodeOpsColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Window hours.
              TextFormField(
                controller: _windowCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: CodeOpsColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Training Window (hours, 1–720)',
                  labelStyle:
                      TextStyle(color: CodeOpsColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1 || n > 720) {
                    return 'Enter 1–720';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sensitivity threshold slider.
              Row(
                children: [
                  const Text(
                    'Sensitivity: ',
                    style: TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _threshold,
                      min: 1.0,
                      max: 5.0,
                      divisions: 8,
                      label: _threshold.toStringAsFixed(1),
                      activeColor: CodeOpsColors.primary,
                      onChanged: (v) => setState(() => _threshold = v),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${_threshold.toStringAsFixed(1)}σ',
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
      'serviceName': _serviceCtrl.text.trim(),
      'metricName': _metricCtrl.text.trim(),
      'windowHours': int.parse(_windowCtrl.text.trim()),
      'deviationThreshold': _threshold,
    };
    Navigator.of(context).pop(result);
  }
}
