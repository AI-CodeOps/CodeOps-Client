/// Service Identity Kit panel displaying all related data cards.
///
/// Renders port allocations, dependencies, API routes, infrastructure
/// resources, and environment configs in a vertical card layout.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import 'dependency_card.dart';
import 'env_config_card.dart';
import 'infra_resource_card.dart';
import 'port_list_card.dart';
import 'route_list_card.dart';

/// Panel displaying the full Service Identity Kit.
///
/// Takes a [ServiceIdentityResponse] and renders each section
/// (ports, dependencies, routes, infra, env configs) as a card.
class IdentityKitPanel extends StatelessWidget {
  /// The service identity data containing all related resources.
  final ServiceIdentityResponse identity;

  /// Creates an [IdentityKitPanel].
  const IdentityKitPanel({super.key, required this.identity});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortListCard(ports: identity.ports),
        const SizedBox(height: 16),
        DependencyCard(
          upstreamDependencies: identity.upstreamDependencies,
          downstreamDependencies: identity.downstreamDependencies,
        ),
        const SizedBox(height: 16),
        RouteListCard(routes: identity.routes),
        const SizedBox(height: 16),
        InfraResourceCard(resources: identity.infraResources),
        const SizedBox(height: 16),
        EnvConfigCard(configs: identity.environmentConfigs),
      ],
    );
  }
}
