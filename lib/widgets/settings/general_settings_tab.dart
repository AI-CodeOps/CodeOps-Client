/// General settings tab with system-wide agent defaults.
///
/// Includes default model, concurrent agents, timeout, temperature,
/// auto-retry toggle, and queue behavior radio.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/agent_config_providers.dart';
import '../../providers/settings_providers.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Tab content for system-wide agent configuration defaults.
class GeneralSettingsTab extends ConsumerStatefulWidget {
  /// Creates a [GeneralSettingsTab].
  const GeneralSettingsTab({super.key});

  @override
  ConsumerState<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends ConsumerState<GeneralSettingsTab> {
  bool _autoRetry = true;
  bool _parallelQueue = true;

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(claudeModelProvider);
    final concurrent = ref.watch(maxConcurrentAgentsProvider);
    final timeout = ref.watch(agentTimeoutMinutesProvider);
    final modelsAsync = ref.watch(anthropicModelsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('General Agent Settings',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'System-wide defaults applied when agents do not have per-agent overrides.',
            style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Default Model.
          _FieldRow(
            label: 'Default Model',
            child: modelsAsync.when(
              loading: () => DropdownButton<String>(
                value: model,
                isExpanded: true,
                dropdownColor: CodeOpsColors.surface,
                items: _fallbackModelItems(model),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(claudeModelProvider.notifier).state = v;
                  }
                },
              ),
              error: (_, __) => DropdownButton<String>(
                value: model,
                isExpanded: true,
                dropdownColor: CodeOpsColors.surface,
                items: _fallbackModelItems(model),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(claudeModelProvider.notifier).state = v;
                  }
                },
              ),
              data: (models) {
                // Use fetched models, or fallback when cache is empty.
                final items = models.isEmpty
                    ? _fallbackModelItems(model)
                    : models
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.displayName,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList();

                // Ensure current value is in the list.
                if (!items.any((i) => i.value == model)) {
                  items.insert(
                    0,
                    DropdownMenuItem(
                      value: model,
                      child: Text(model, style: const TextStyle(fontSize: 13)),
                    ),
                  );
                }

                return DropdownButton<String>(
                  value: model,
                  isExpanded: true,
                  dropdownColor: CodeOpsColors.surface,
                  items: items,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(claudeModelProvider.notifier).state = v;
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Concurrent Agents.
          _FieldRow(
            label: 'Concurrent Agents ($concurrent)',
            child: Slider(
              value: concurrent.toDouble(),
              min: AppConstants.maxConcurrentAgentsMin.toDouble(),
              max: AppConstants.maxConcurrentAgentsMax.toDouble(),
              divisions: AppConstants.maxConcurrentAgentsMax -
                  AppConstants.maxConcurrentAgentsMin,
              label: '$concurrent',
              onChanged: (v) =>
                  ref.read(maxConcurrentAgentsProvider.notifier).state =
                      v.round(),
            ),
          ),
          const SizedBox(height: 24),

          // Default Timeout.
          _FieldRow(
            label: 'Default Timeout ($timeout min)',
            child: Slider(
              value: timeout.toDouble(),
              min: AppConstants.agentTimeoutMinutesMin.toDouble(),
              max: AppConstants.agentTimeoutMinutesMax.toDouble(),
              divisions:
                  (AppConstants.agentTimeoutMinutesMax -
                          AppConstants.agentTimeoutMinutesMin) ~/
                      5,
              label: '$timeout min',
              onChanged: (v) =>
                  ref.read(agentTimeoutMinutesProvider.notifier).state =
                      v.round(),
            ),
          ),
          const SizedBox(height: 24),

          // Default Temperature.
          _FieldRow(
            label: 'Default Temperature (0.0)',
            child: Slider(
              value: 0.0,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '0.0',
              onChanged: (_) {
                // Temperature is per-agent only — this is display-only default.
              },
            ),
          ),
          const SizedBox(height: 24),

          // Auto-Retry.
          SwitchListTile(
            title: const Text('Auto-Retry Failed Agents',
                style: TextStyle(fontSize: 13)),
            subtitle: const Text(
              'Automatically retry agents that fail or time out',
              style:
                  TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
            ),
            value: _autoRetry,
            onChanged: (v) => setState(() => _autoRetry = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // Queue Behavior.
          const Text('Queue Behavior',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textSecondary)),
          const SizedBox(height: 8),
          ListTile(
            leading: Radio<bool>(
              value: true,
              groupValue: _parallelQueue,
              onChanged: (v) => setState(() => _parallelQueue = v ?? true),
            ),
            title: const Text('Parallel', style: TextStyle(fontSize: 13)),
            subtitle: const Text(
              'Run agents concurrently up to the limit',
              style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () => setState(() => _parallelQueue = true),
          ),
          ListTile(
            leading: Radio<bool>(
              value: false,
              groupValue: _parallelQueue,
              onChanged: (v) => setState(() => _parallelQueue = v ?? true),
            ),
            title: const Text('Sequential', style: TextStyle(fontSize: 13)),
            subtitle: const Text(
              'Run agents one at a time',
              style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () => setState(() => _parallelQueue = false),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _fallbackModelItems(String current) {
    return [
      DropdownMenuItem(
        value: 'claude-sonnet-4-20250514',
        child: const Text('Claude Sonnet 4', style: TextStyle(fontSize: 13)),
      ),
      DropdownMenuItem(
        value: 'claude-opus-4-20250514',
        child: const Text('Claude Opus 4', style: TextStyle(fontSize: 13)),
      ),
      DropdownMenuItem(
        value: 'claude-haiku-4-20250514',
        child: const Text('Claude Haiku 4', style: TextStyle(fontSize: 13)),
      ),
    ];
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
