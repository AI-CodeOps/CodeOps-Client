/// Grid of selectable config type chips.
///
/// Maps [ConfigTemplateType] enum values to display labels and icons.
/// In solution mode, only [ConfigTemplateType.dockerCompose] is available.
library;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../theme/colors.dart';

/// Maps each [ConfigTemplateType] to an icon.
IconData _iconFor(ConfigTemplateType type) => switch (type) {
      ConfigTemplateType.dockerCompose => Icons.dock,
      ConfigTemplateType.applicationYml => Icons.settings,
      ConfigTemplateType.applicationProperties => Icons.tune,
      ConfigTemplateType.envFile => Icons.vpn_key,
      ConfigTemplateType.terraformModule => Icons.cloud,
      ConfigTemplateType.claudeCodeHeader => Icons.smart_toy,
      ConfigTemplateType.conventionsMd => Icons.description,
      ConfigTemplateType.nginxConf => Icons.dns,
      ConfigTemplateType.githubActions => Icons.play_circle,
      ConfigTemplateType.dockerfile => Icons.inventory_2,
      ConfigTemplateType.makefile => Icons.build,
      ConfigTemplateType.readmeSection => Icons.article,
    };

/// Maps each [ConfigTemplateType] to a ScribeEditor language identifier.
String languageFor(ConfigTemplateType type) => switch (type) {
      ConfigTemplateType.dockerCompose => 'yaml',
      ConfigTemplateType.applicationYml => 'yaml',
      ConfigTemplateType.applicationProperties => 'properties',
      ConfigTemplateType.envFile => 'ini',
      ConfigTemplateType.terraformModule => 'plaintext',
      ConfigTemplateType.claudeCodeHeader => 'markdown',
      ConfigTemplateType.conventionsMd => 'markdown',
      ConfigTemplateType.nginxConf => 'ini',
      ConfigTemplateType.githubActions => 'yaml',
      ConfigTemplateType.dockerfile => 'dockerfile',
      ConfigTemplateType.makefile => 'makefile',
      ConfigTemplateType.readmeSection => 'markdown',
    };

/// Grid of selectable config type chips.
///
/// Renders a [Wrap] of [FilterChip] widgets for each [ConfigTemplateType].
/// In [solutionMode], only [ConfigTemplateType.dockerCompose] is enabled.
class ConfigTypeSelector extends StatelessWidget {
  /// Currently selected config types.
  final Set<ConfigTemplateType> selectedTypes;

  /// Called when a config type chip is toggled.
  final ValueChanged<ConfigTemplateType> onToggle;

  /// When true, only docker-compose is available (solutions only support it).
  final bool solutionMode;

  /// Creates a [ConfigTypeSelector].
  const ConfigTypeSelector({
    super.key,
    required this.selectedTypes,
    required this.onToggle,
    this.solutionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ConfigTemplateType.values.map((type) {
        final selected = selectedTypes.contains(type);
        final enabled = !solutionMode ||
            type == ConfigTemplateType.dockerCompose;

        return FilterChip(
          avatar: Icon(
            _iconFor(type),
            size: 16,
            color: enabled
                ? (selected
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textSecondary)
                : CodeOpsColors.textTertiary,
          ),
          label: Text(type.displayName),
          selected: selected,
          onSelected: enabled ? (_) => onToggle(type) : null,
          selectedColor: CodeOpsColors.primary.withValues(alpha: 0.15),
          checkmarkColor: CodeOpsColors.primary,
          backgroundColor: CodeOpsColors.surface,
          disabledColor: CodeOpsColors.surface.withValues(alpha: 0.5),
          labelStyle: TextStyle(
            fontSize: 12,
            color: enabled
                ? (selected
                    ? CodeOpsColors.textPrimary
                    : CodeOpsColors.textSecondary)
                : CodeOpsColors.textTertiary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected
                  ? CodeOpsColors.primary
                  : CodeOpsColors.border,
            ),
          ),
        );
      }).toList(),
    );
  }
}
