/// Card displaying environment configuration entries for a service.
///
/// Shows environment badge, config key, value preview, and source.
/// Rows can be tapped to expand and view the full config value.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Card displaying environment configuration entries for a service.
///
/// Each row shows an environment badge, config key, truncated value,
/// and config source. Tapping a row expands it to show the full value.
class EnvConfigCard extends StatelessWidget {
  /// The environment configurations to display.
  final List<EnvironmentConfigResponse> configs;

  /// Creates an [EnvConfigCard].
  const EnvConfigCard({super.key, required this.configs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.settings_applications_outlined, size: 18,
                    color: CodeOpsColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Environment Configs',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${configs.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (configs.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                'No environment configs',
                style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
              ),
            )
          else
            ...configs.map((c) => _ConfigRow(config: c)),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatefulWidget {
  final EnvironmentConfigResponse config;

  const _ConfigRow({required this.config});

  @override
  State<_ConfigRow> createState() => _ConfigRowState();
}

class _ConfigRowState extends State<_ConfigRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.config;

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: CodeOpsColors.border, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Environment badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _envColor(c.environment).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _envColor(c.environment).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    c.environment,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _envColor(c.environment),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Config key
                Expanded(
                  flex: 2,
                  child: Text(
                    c.configKey,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Value preview
                if (!_expanded)
                  Expanded(
                    flex: 3,
                    child: Text(
                      c.configValue,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: CodeOpsColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                // Source badge
                if (c.configSource != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    c.configSource!.displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
                // Expand icon
                const SizedBox(width: 8),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: CodeOpsColors.textTertiary,
                ),
              ],
            ),
            // Expanded value
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CodeOpsColors.border),
                  ),
                  child: SelectableText(
                    c.configValue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _envColor(String env) => switch (env.toLowerCase()) {
        'dev' => CodeOpsColors.success,
        'staging' || 'stg' => CodeOpsColors.warning,
        'prod' || 'production' => CodeOpsColors.error,
        _ => CodeOpsColors.primary,
      };
}
