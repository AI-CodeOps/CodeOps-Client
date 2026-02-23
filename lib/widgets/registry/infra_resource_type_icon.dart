/// Icon widget for infrastructure resource types.
///
/// Maps each [InfraResourceType] to an appropriate Material icon
/// with consistent sizing and coloring.
library;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../theme/colors.dart';

/// Icon widget for [InfraResourceType].
///
/// Renders a Material icon matching the infrastructure resource type.
class InfraResourceTypeIcon extends StatelessWidget {
  /// The resource type to display an icon for.
  final InfraResourceType type;

  /// Icon size in logical pixels.
  final double size;

  /// Creates an [InfraResourceTypeIcon].
  const InfraResourceTypeIcon({
    super.key,
    required this.type,
    this.size = 18,
  });

  /// Returns the [IconData] for the given [InfraResourceType].
  static IconData iconFor(InfraResourceType type) => switch (type) {
        InfraResourceType.s3Bucket => Icons.folder,
        InfraResourceType.sqsQueue => Icons.queue,
        InfraResourceType.snsTopic => Icons.campaign,
        InfraResourceType.cloudwatchLogGroup => Icons.monitor,
        InfraResourceType.iamRole => Icons.security,
        InfraResourceType.secretsManagerPath => Icons.vpn_key,
        InfraResourceType.ssmParameter => Icons.settings,
        InfraResourceType.rdsInstance => Icons.storage,
        InfraResourceType.elasticacheCluster => Icons.memory,
        InfraResourceType.ecrRepository => Icons.inventory_2,
        InfraResourceType.cloudMapNamespace => Icons.map,
        InfraResourceType.route53Record => Icons.dns,
        InfraResourceType.acmCertificate => Icons.verified_user,
        InfraResourceType.albTargetGroup => Icons.account_tree,
        InfraResourceType.ecsService => Icons.cloud,
        InfraResourceType.lambdaFunction => Icons.functions,
        InfraResourceType.dynamodbTable => Icons.table_chart,
        InfraResourceType.dockerNetwork => Icons.lan,
        InfraResourceType.dockerVolume => Icons.disc_full,
        InfraResourceType.other => Icons.extension,
      };

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconFor(type),
      size: size,
      color: CodeOpsColors.textSecondary,
    );
  }
}
