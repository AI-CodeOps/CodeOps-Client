/// Configuration step for agent thresholds and settings.
///
/// Sliders for concurrent agents (1-6), timeout (5-60), max turns (10-100).
/// Dropdown for Claude model. Number inputs for pass/warn thresholds.
/// Multi-line additionalContext text field. Always valid.
library;

import 'package:flutter/material.dart';

import '../../providers/wizard_providers.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Configuration step for the wizard flow.
class ThresholdStep extends StatelessWidget {
  /// The current job configuration.
  final JobConfig config;

  /// Called when the configuration changes.
  final ValueChanged<JobConfig> onConfigChanged;

  /// Creates a [ThresholdStep].
  const ThresholdStep({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  static const _models = [
    ('claude-sonnet-4-5-20250514', 'Claude Sonnet 4.5'),
    ('claude-sonnet-4-20250514', 'Claude Sonnet 4'),
    ('claude-opus-4-20250514', 'Claude Opus 4'),
    ('claude-haiku-4-20250514', 'Claude Haiku 4'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fine-tune agent behavior and thresholds.',
            style: TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Concurrent Agents
          _SliderRow(
            label: 'Concurrent Agents',
            value: config.maxConcurrentAgents.toDouble(),
            min: AppConstants.maxConcurrentAgentsMin.toDouble(),
            max: AppConstants.maxConcurrentAgentsMax.toDouble(),
            divisions:
                AppConstants.maxConcurrentAgentsMax - AppConstants.maxConcurrentAgentsMin,
            valueLabel: '${config.maxConcurrentAgents}',
            onChanged: (v) => onConfigChanged(
              config.copyWith(maxConcurrentAgents: v.round()),
            ),
          ),
          const SizedBox(height: 16),

          // Agent Timeout
          _SliderRow(
            label: 'Agent Timeout (minutes)',
            value: config.agentTimeoutMinutes.toDouble(),
            min: AppConstants.agentTimeoutMinutesMin.toDouble(),
            max: AppConstants.agentTimeoutMinutesMax.toDouble(),
            divisions:
                AppConstants.agentTimeoutMinutesMax - AppConstants.agentTimeoutMinutesMin,
            valueLabel: '${config.agentTimeoutMinutes}m',
            onChanged: (v) => onConfigChanged(
              config.copyWith(agentTimeoutMinutes: v.round()),
            ),
          ),
          const SizedBox(height: 16),

          // Max Turns
          _SliderRow(
            label: 'Max Turns',
            value: config.maxTurns.toDouble(),
            min: AppConstants.maxTurnsMin.toDouble(),
            max: AppConstants.maxTurnsMax.toDouble(),
            divisions: (AppConstants.maxTurnsMax - AppConstants.maxTurnsMin) ~/ 5,
            valueLabel: '${config.maxTurns}',
            onChanged: (v) => onConfigChanged(
              config.copyWith(maxTurns: v.round()),
            ),
          ),
          const SizedBox(height: 20),

          // Claude Model
          Row(
            children: [
              const SizedBox(
                width: 180,
                child: Text(
                  'Claude Model',
                  style: TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: config.claudeModel,
                  dropdownColor: CodeOpsColors.surface,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _models
                      .map((m) => DropdownMenuItem(
                            value: m.$1,
                            child: Text(m.$2),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      onConfigChanged(config.copyWith(claudeModel: v));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Threshold bar
          const Text(
            'Health Score Thresholds',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _ThresholdBar(
            passThreshold: config.passThreshold,
            warnThreshold: config.warnThreshold,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ThresholdInput(
                  label: 'Pass threshold',
                  value: config.passThreshold,
                  color: CodeOpsColors.success,
                  onChanged: (v) =>
                      onConfigChanged(config.copyWith(passThreshold: v)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ThresholdInput(
                  label: 'Warn threshold',
                  value: config.warnThreshold,
                  color: CodeOpsColors.warning,
                  onChanged: (v) =>
                      onConfigChanged(config.copyWith(warnThreshold: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Additional Context
          const Text(
            'Additional Context',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            maxLines: 4,
            controller: TextEditingController(text: config.additionalContext)
              ..selection = TextSelection.collapsed(
                  offset: config.additionalContext.length),
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText:
                  'Optional context to include in agent prompts...',
              hintStyle: TextStyle(color: CodeOpsColors.textTertiary),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: (v) =>
                onConfigChanged(config.copyWith(additionalContext: v)),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : null,
            activeColor: CodeOpsColors.primary,
            inactiveColor: CodeOpsColors.border,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            valueLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThresholdBar extends StatelessWidget {
  final int passThreshold;
  final int warnThreshold;

  const _ThresholdBar({
    required this.passThreshold,
    required this.warnThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            Expanded(
              flex: warnThreshold,
              child: Container(color: CodeOpsColors.error.withValues(alpha: 0.7)),
            ),
            Expanded(
              flex: passThreshold - warnThreshold,
              child: Container(color: CodeOpsColors.warning.withValues(alpha: 0.7)),
            ),
            Expanded(
              flex: 100 - passThreshold,
              child: Container(color: CodeOpsColors.success.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThresholdInput extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _ThresholdInput({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 48,
          child: TextField(
            controller: TextEditingController(text: value.toString()),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 12,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            ),
            onSubmitted: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed >= 0 && parsed <= 100) {
                onChanged(parsed);
              }
            },
          ),
        ),
      ],
    );
  }
}
