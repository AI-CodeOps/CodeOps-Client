/// Card displaying upstream and downstream service dependencies.
///
/// Upstream = services this service depends on.
/// Downstream = services that depend on this service.
/// Clicking a dependency name navigates to that service's detail page.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Card displaying upstream and downstream service dependencies.
///
/// Shows two sections: "Depends on" (upstream) and "Depended on by"
/// (downstream), each with clickable service names for navigation.
class DependencyCard extends StatelessWidget {
  /// Dependencies where this service is the source (depends on target).
  final List<ServiceDependencyResponse> upstreamDependencies;

  /// Dependencies where this service is the target (source depends on this).
  final List<ServiceDependencyResponse> downstreamDependencies;

  /// Creates a [DependencyCard].
  const DependencyCard({
    super.key,
    required this.upstreamDependencies,
    required this.downstreamDependencies,
  });

  int get _totalCount => upstreamDependencies.length + downstreamDependencies.length;

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
                const Icon(Icons.account_tree_outlined, size: 18,
                    color: CodeOpsColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Dependencies',
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
                    '$_totalCount',
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
          if (_totalCount == 0)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                'No dependencies',
                style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
              ),
            )
          else ...[
            // Upstream section
            _DependencySection(
              label: 'Depends on',
              count: upstreamDependencies.length,
              dependencies: upstreamDependencies,
              isUpstream: true,
            ),
            if (upstreamDependencies.isNotEmpty && downstreamDependencies.isNotEmpty)
              const Divider(height: 1, color: CodeOpsColors.border),
            // Downstream section
            _DependencySection(
              label: 'Depended on by',
              count: downstreamDependencies.length,
              dependencies: downstreamDependencies,
              isUpstream: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _DependencySection extends StatelessWidget {
  final String label;
  final int count;
  final List<ServiceDependencyResponse> dependencies;
  final bool isUpstream;

  const _DependencySection({
    required this.label,
    required this.count,
    required this.dependencies,
    required this.isUpstream,
  });

  @override
  Widget build(BuildContext context) {
    if (dependencies.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ($count):',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...dependencies.map((dep) => _DependencyRow(
                dependency: dep,
                isUpstream: isUpstream,
              )),
        ],
      ),
    );
  }
}

class _DependencyRow extends StatelessWidget {
  final ServiceDependencyResponse dependency;
  final bool isUpstream;

  const _DependencyRow({
    required this.dependency,
    required this.isUpstream,
  });

  @override
  Widget build(BuildContext context) {
    // For upstream: display target (the service this depends on)
    // For downstream: display source (the service that depends on this)
    final displayName =
        (isUpstream ? dependency.targetServiceName : dependency.sourceServiceName) ?? 'Unknown';
    final displayId =
        isUpstream ? dependency.targetServiceId : dependency.sourceServiceId;
    final arrow = isUpstream ? '\u2192' : '\u2190'; // → or ←
    final requiredLabel = dependency.isRequired == true ? 'required' : 'optional';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => context.go('/registry/services/$displayId'),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Text(
                arrow,
                style: TextStyle(
                  fontSize: 14,
                  color: isUpstream ? CodeOpsColors.primary : CodeOpsColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: CodeOpsColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${dependency.dependencyType.displayName}, $requiredLabel)',
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
