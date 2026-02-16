/// Info dialog explaining the temperature parameter for LLM agents.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A simple informational dialog explaining temperature settings.
class TemperatureHelpDialog extends StatelessWidget {
  /// Creates a [TemperatureHelpDialog].
  const TemperatureHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Temperature'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temperature controls the randomness of the model\'s output.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            _TemperatureRow(
              value: '0.0',
              label: 'Deterministic',
              description:
                  'Most predictable and consistent. Best for analysis, code review, and structured output.',
              color: CodeOpsColors.secondary,
            ),
            const SizedBox(height: 12),
            _TemperatureRow(
              value: '0.5',
              label: 'Balanced',
              description:
                  'Mix of consistency and variety. Good for general-purpose tasks.',
              color: CodeOpsColors.warning,
            ),
            const SizedBox(height: 12),
            _TemperatureRow(
              value: '1.0',
              label: 'Creative',
              description:
                  'Maximum variety and creativity. Best for brainstorming and exploratory tasks.',
              color: CodeOpsColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'For QA analysis agents, 0.0 is recommended for reproducible results.',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: CodeOpsColors.textTertiary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class _TemperatureRow extends StatelessWidget {
  final String value;
  final String label;
  final String description;
  final Color color;

  const _TemperatureRow({
    required this.value,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(description,
                  style: const TextStyle(
                      fontSize: 12, color: CodeOpsColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
