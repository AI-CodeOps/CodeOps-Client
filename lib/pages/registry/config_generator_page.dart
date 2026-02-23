/// Config generator page.
///
/// Select a service or solution, choose config types, generate previews
/// in ScribeEditor, copy/download output, and manage stored configs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/config_preview_panel.dart';
import '../../widgets/registry/config_type_selector.dart';
import '../../widgets/registry/stored_configs_list.dart';

/// Main config generator page.
///
/// Provides service/solution mode toggle, source selection dropdowns,
/// config type chips, generate buttons, ScribeEditor preview, and a
/// stored configs list.
class ConfigGeneratorPage extends ConsumerWidget {
  /// Creates a [ConfigGeneratorPage].
  const ConfigGeneratorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(configModeProvider);
    final serviceId = ref.watch(configServiceIdProvider);
    final solutionId = ref.watch(configSolutionIdProvider);
    final environment = ref.watch(configEnvironmentProvider);
    final selectedTypes = ref.watch(selectedConfigTypesProvider);
    final preview = ref.watch(configPreviewProvider);
    final storedAsync = ref.watch(storedConfigsProvider);
    final servicesAsync = ref.watch(registryServicesProvider);
    final solutionsAsync = ref.watch(registrySolutionsProvider);

    final isSolutionMode = mode == ConfigGeneratorMode.solution;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          const Text(
            'Config Generator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Source Selection
          _SectionCard(
            title: 'Source Selection',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode toggle
                Row(
                  children: [
                    const Text(
                      'Mode:',
                      style: TextStyle(
                        fontSize: 13,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _ModeRadio(
                      label: 'Service',
                      selected: !isSolutionMode,
                      onTap: () => ref
                          .read(configModeProvider.notifier)
                          .state = ConfigGeneratorMode.service,
                    ),
                    const SizedBox(width: 16),
                    _ModeRadio(
                      label: 'Solution',
                      selected: isSolutionMode,
                      onTap: () => ref
                          .read(configModeProvider.notifier)
                          .state = ConfigGeneratorMode.solution,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Service or Solution dropdown
                if (!isSolutionMode)
                  servicesAsync.when(
                    data: (page) => _SourceDropdown(
                      label: 'Service',
                      value: serviceId,
                      items: page.content
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: (v) => ref
                          .read(configServiceIdProvider.notifier)
                          .state = v,
                    ),
                    loading: () => const SizedBox(
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (_, __) => const Text(
                      'Failed to load services',
                      style: TextStyle(
                        color: CodeOpsColors.error,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  solutionsAsync.when(
                    data: (page) => _SourceDropdown(
                      label: 'Solution',
                      value: solutionId,
                      items: page.content
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: (v) => ref
                          .read(configSolutionIdProvider.notifier)
                          .state = v,
                    ),
                    loading: () => const SizedBox(
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (_, __) => const Text(
                      'Failed to load solutions',
                      style: TextStyle(
                        color: CodeOpsColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Environment
                _SourceDropdown(
                  label: 'Environment',
                  value: environment,
                  items: const [
                    DropdownMenuItem(value: 'dev', child: Text('dev')),
                    DropdownMenuItem(value: 'staging', child: Text('staging')),
                    DropdownMenuItem(
                        value: 'production', child: Text('production')),
                    DropdownMenuItem(value: 'local', child: Text('local')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(configEnvironmentProvider.notifier).state = v;
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Config Types
          _SectionCard(
            title: 'Config Types',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConfigTypeSelector(
                  selectedTypes: selectedTypes,
                  onToggle: (type) {
                    final current =
                        ref.read(selectedConfigTypesProvider);
                    final updated = Set<ConfigTemplateType>.from(current);
                    if (updated.contains(type)) {
                      updated.remove(type);
                    } else {
                      updated.add(type);
                    }
                    ref.read(selectedConfigTypesProvider.notifier).state =
                        updated;
                  },
                  solutionMode: isSolutionMode,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _canGenerate(
                              isSolutionMode, serviceId, solutionId,
                              selectedTypes)
                          ? () => _generateSelected(
                              ref, isSolutionMode, serviceId, solutionId,
                              environment, selectedTypes, context)
                          : null,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Generate Selected'),
                      style: FilledButton.styleFrom(
                        backgroundColor: CodeOpsColors.primary,
                        disabledBackgroundColor:
                            CodeOpsColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isSolutionMode)
                      OutlinedButton.icon(
                        onPressed: serviceId != null
                            ? () => _generateAll(
                                ref, serviceId, environment, context)
                            : null,
                        icon: const Icon(Icons.all_inclusive, size: 18),
                        label: const Text('Generate All'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CodeOpsColors.textSecondary,
                          side: const BorderSide(color: CodeOpsColors.border),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preview
          _SectionLabel(
            label: 'Preview',
            trailing: preview != null
                ? Text(
                    preview.templateType.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CodeOpsColors.textTertiary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          ConfigPreviewPanel(
            config: preview,
            onRegenerate: preview != null
                ? () => _regenerate(
                    ref, isSolutionMode, serviceId, solutionId,
                    environment, preview.templateType, context)
                : null,
          ),
          const SizedBox(height: 24),

          // Stored Configs
          if (!isSolutionMode && serviceId != null) ...[
            _SectionLabel(
              label: 'Stored Configs',
              trailing: storedAsync.whenOrNull(
                data: (list) => Text(
                  '(${list.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            storedAsync.when(
              data: (configs) => StoredConfigsList(
                configs: configs,
                onView: (c) =>
                    ref.read(configPreviewProvider.notifier).state = c,
                onDelete: (c) => _confirmDelete(ref, c, context),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load stored configs',
                  style: TextStyle(
                    color: CodeOpsColors.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canGenerate(bool solutionMode, String? serviceId,
      String? solutionId, Set<ConfigTemplateType> selectedTypes) {
    if (selectedTypes.isEmpty) return false;
    return solutionMode ? solutionId != null : serviceId != null;
  }

  Future<void> _generateSelected(
    WidgetRef ref,
    bool solutionMode,
    String? serviceId,
    String? solutionId,
    String environment,
    Set<ConfigTemplateType> selectedTypes,
    BuildContext context,
  ) async {
    final api = ref.read(registryApiProvider);

    try {
      if (solutionMode) {
        // Solution mode: only docker-compose supported.
        final result = await api.generateSolutionDockerCompose(
          solutionId!,
          environment: environment,
        );
        ref.read(configPreviewProvider.notifier).state = result;
      } else {
        // Service mode: generate the first selected type for preview.
        final type = selectedTypes.first;
        final result = await api.generateConfig(
          serviceId!,
          type: type,
          environment: environment,
        );
        ref.read(configPreviewProvider.notifier).state = result;
        ref.invalidate(storedConfigsProvider);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $e'),
            backgroundColor: CodeOpsColors.error,
          ),
        );
      }
    }
  }

  Future<void> _generateAll(
    WidgetRef ref,
    String serviceId,
    String environment,
    BuildContext context,
  ) async {
    final api = ref.read(registryApiProvider);

    try {
      final results = await api.generateAllConfigs(
        serviceId,
        environment: environment,
      );
      if (results.isNotEmpty) {
        ref.read(configPreviewProvider.notifier).state = results.first;
      }
      ref.invalidate(storedConfigsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${results.length} configs'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $e'),
            backgroundColor: CodeOpsColors.error,
          ),
        );
      }
    }
  }

  Future<void> _regenerate(
    WidgetRef ref,
    bool solutionMode,
    String? serviceId,
    String? solutionId,
    String environment,
    ConfigTemplateType type,
    BuildContext context,
  ) async {
    final api = ref.read(registryApiProvider);

    try {
      ConfigTemplateResponse result;
      if (solutionMode && solutionId != null) {
        result = await api.generateSolutionDockerCompose(
          solutionId,
          environment: environment,
        );
      } else if (serviceId != null) {
        result = await api.generateConfig(
          serviceId,
          type: type,
          environment: environment,
        );
      } else {
        return;
      }
      ref.read(configPreviewProvider.notifier).state = result;
      ref.invalidate(storedConfigsProvider);
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Regeneration failed: $e'),
            backgroundColor: CodeOpsColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    WidgetRef ref,
    ConfigTemplateResponse config,
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Config'),
        content: Text(
          'Delete "${config.templateType.displayName}" '
          '(${config.environment ?? ""})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(registryApiProvider).deleteTemplate(config.id);
      ref.invalidate(storedConfigsProvider);

      // Clear preview if it was the deleted config.
      final currentPreview = ref.read(configPreviewProvider);
      if (currentPreview?.id == config.id) {
        ref.read(configPreviewProvider.notifier).state = null;
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: CodeOpsColors.error,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionLabel({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _ModeRadio extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected
                ? CodeOpsColors.primary
                : CodeOpsColors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected
                  ? CodeOpsColors.textPrimary
                  : CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const _SourceDropdown({
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            dropdownColor: CodeOpsColors.surface,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select $label',
              hintStyle: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 13,
              ),
            ),
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textPrimary,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
