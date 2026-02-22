/// Card displaying infrastructure resources linked to a service.
///
/// Shows resource type icon, name, environment, region, and description
/// for each infrastructure resource.
library;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Card displaying infrastructure resources linked to a service.
///
/// Each row shows a resource type icon, name, environment, region,
/// and optional description.
class InfraResourceCard extends StatelessWidget {
  /// The infrastructure resources to display.
  final List<InfraResourceResponse> resources;

  /// Creates an [InfraResourceCard].
  const InfraResourceCard({super.key, required this.resources});

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
                const Icon(Icons.cloud_outlined, size: 18,
                    color: CodeOpsColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Infrastructure Resources',
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
                    '${resources.length}',
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
          if (resources.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                'No infrastructure resources',
                style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
              ),
            )
          else
            ...resources.map((r) => _ResourceRow(resource: r)),
        ],
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final InfraResourceResponse resource;

  const _ResourceRow({required this.resource});

  ({IconData icon, Color color}) get _typeIcon =>
      switch (resource.resourceType) {
        InfraResourceType.s3Bucket => (icon: Icons.inventory_2_outlined, color: CodeOpsColors.success),
        InfraResourceType.sqsQueue => (icon: Icons.queue_outlined, color: CodeOpsColors.warning),
        InfraResourceType.snsTopic => (icon: Icons.notifications_outlined, color: const Color(0xFFA855F7)),
        InfraResourceType.cloudwatchLogGroup => (icon: Icons.analytics_outlined, color: const Color(0xFF3B82F6)),
        InfraResourceType.iamRole => (icon: Icons.security_outlined, color: CodeOpsColors.warning),
        InfraResourceType.secretsManagerPath => (icon: Icons.lock_outlined, color: CodeOpsColors.error),
        InfraResourceType.ssmParameter => (icon: Icons.settings_outlined, color: CodeOpsColors.textSecondary),
        InfraResourceType.rdsInstance => (icon: Icons.storage_outlined, color: const Color(0xFF3B82F6)),
        InfraResourceType.elasticacheCluster => (icon: Icons.memory_outlined, color: CodeOpsColors.error),
        InfraResourceType.ecrRepository => (icon: Icons.inventory_outlined, color: const Color(0xFFA855F7)),
        InfraResourceType.cloudMapNamespace => (icon: Icons.map_outlined, color: CodeOpsColors.secondary),
        InfraResourceType.route53Record => (icon: Icons.dns_outlined, color: CodeOpsColors.primary),
        InfraResourceType.acmCertificate => (icon: Icons.verified_outlined, color: CodeOpsColors.success),
        InfraResourceType.albTargetGroup => (icon: Icons.account_balance_outlined, color: const Color(0xFF3B82F6)),
        InfraResourceType.ecsService => (icon: Icons.apps_outlined, color: CodeOpsColors.primary),
        InfraResourceType.lambdaFunction => (icon: Icons.bolt_outlined, color: CodeOpsColors.warning),
        InfraResourceType.dynamodbTable => (icon: Icons.table_chart_outlined, color: const Color(0xFF3B82F6)),
        InfraResourceType.dockerNetwork => (icon: Icons.hub_outlined, color: CodeOpsColors.secondary),
        InfraResourceType.dockerVolume => (icon: Icons.save_outlined, color: CodeOpsColors.textSecondary),
        InfraResourceType.other => (icon: Icons.extension_outlined, color: CodeOpsColors.textTertiary),
      };

  @override
  Widget build(BuildContext context) {
    final (:icon, :color) = _typeIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          // Resource type label
          SizedBox(
            width: 120,
            child: Text(
              resource.resourceType.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Resource name
          Expanded(
            flex: 3,
            child: Text(
              resource.resourceName,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Environment
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CodeOpsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              resource.environment,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          // Region
          if (resource.region != null) ...[
            const SizedBox(width: 12),
            Text(
              resource.region!,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
