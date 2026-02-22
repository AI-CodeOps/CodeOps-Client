/// Service detail page displaying full service information and Identity Kit.
///
/// Accessed via `/registry/services/:id`. Loads the complete service identity
/// from [registryServiceIdentityProvider] and renders a header section with
/// action buttons (Clone, Delete, Check Health) plus the [IdentityKitPanel].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import '../../widgets/registry/identity_kit_panel.dart';
import '../../widgets/registry/service_status_badge.dart';
import '../../widgets/registry/service_type_icon.dart';
import '../../widgets/shared/error_panel.dart';

/// Full-page service detail view with header, metadata, and Identity Kit.
///
/// Takes a [serviceId] from the router path parameters and loads all
/// service data via the [registryServiceIdentityProvider].
class ServiceDetailPage extends ConsumerWidget {
  /// The service UUID extracted from route parameters.
  final String serviceId;

  /// Creates a [ServiceDetailPage].
  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync =
        ref.watch(registryServiceIdentityProvider(serviceId));

    return Column(
      children: [
        // Header bar with back button and title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.divider),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    size: 18, color: CodeOpsColors.textSecondary),
                onPressed: () => context.go('/registry'),
                tooltip: 'Back to services',
              ),
              const SizedBox(width: 8),
              identityAsync.when(
                loading: () => const Text(
                  'Service Detail',
                  style: TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                error: (_, __) => const Text(
                  'Service Detail',
                  style: TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                data: (identity) => Expanded(
                  child: Row(
                    children: [
                      ServiceTypeIcon(
                          type: identity.service.serviceType, size: 22),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          identity.service.name,
                          style: const TextStyle(
                            color: CodeOpsColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      _ActionButtons(
                        serviceId: serviceId,
                        serviceName: identity.service.name,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: identityAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel.fromException(
              e,
              onRetry: () =>
                  ref.invalidate(registryServiceIdentityProvider(serviceId)),
            ),
            data: (identity) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ServiceHeader(service: identity.service),
                      const SizedBox(height: 24),
                      IdentityKitPanel(identity: identity),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Action buttons for Clone, Delete, and Check Health.
class _ActionButtons extends ConsumerWidget {
  final String serviceId;
  final String serviceName;

  const _ActionButtons({required this.serviceId, required this.serviceName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.copy_outlined,
          label: 'Clone',
          onPressed: () => _showCloneDialog(context, ref),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.delete_outline,
          label: 'Delete',
          color: CodeOpsColors.error,
          onPressed: () => _showDeleteDialog(context, ref),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.health_and_safety_outlined,
          label: 'Check Health',
          onPressed: () => _checkHealth(context, ref),
        ),
      ],
    );
  }

  void _showCloneDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: '$serviceName (Copy)');
    final slugController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Clone Service',
            style: TextStyle(color: CodeOpsColors.textPrimary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'New Service Name',
                  labelStyle: TextStyle(color: CodeOpsColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: CodeOpsColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: CodeOpsColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: slugController,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'New Slug (optional)',
                  labelStyle: TextStyle(color: CodeOpsColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: CodeOpsColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: CodeOpsColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: CodeOpsColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(registryApiProvider);
              try {
                final cloned = await api.cloneService(
                  serviceId,
                  newName: nameController.text.trim(),
                  newSlug: slugController.text.trim().isEmpty
                      ? null
                      : slugController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Cloned as "${cloned.name}"'),
                        backgroundColor: CodeOpsColors.success),
                  );
                  context.go('/registry/services/${cloned.id}');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Clone failed: $e'),
                        backgroundColor: CodeOpsColors.error),
                  );
                }
              }
            },
            child: const Text('Clone'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Service',
            style: TextStyle(color: CodeOpsColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete "$serviceName"? '
          'This action cannot be undone.',
          style: const TextStyle(color: CodeOpsColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: CodeOpsColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CodeOpsColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ref.read(registryApiProvider);
              try {
                await api.deleteService(serviceId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Deleted "$serviceName"'),
                        backgroundColor: CodeOpsColors.success),
                  );
                  ref.invalidate(registryServicesProvider);
                  context.go('/registry');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Delete failed: $e'),
                        backgroundColor: CodeOpsColors.error),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkHealth(BuildContext context, WidgetRef ref) async {
    final api = ref.read(registryApiProvider);
    try {
      final health = await api.checkServiceHealth(serviceId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health: ${health.healthStatus.displayName}'),
            backgroundColor: CodeOpsColors
                    .healthStatusColors[health.healthStatus] ??
                CodeOpsColors.textTertiary,
          ),
        );
        ref.invalidate(registryServiceIdentityProvider(serviceId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Health check failed: $e'),
              backgroundColor: CodeOpsColors.error),
        );
      }
    }
  }
}

/// Small outlined action button used in the header bar.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CodeOpsColors.textSecondary;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: c),
      label: Text(label, style: TextStyle(fontSize: 12, color: c)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: c.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

/// Service metadata header card.
///
/// Shows type icon, name, health indicator, slug, status badge, description,
/// repo URL, tech stack, health check URL, timestamps, and counts.
class _ServiceHeader extends StatelessWidget {
  final ServiceRegistrationResponse service;

  const _ServiceHeader({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Type icon, name, health, status
          Row(
            children: [
              ServiceTypeIcon(type: service.serviceType, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.slug,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              ServiceStatusBadge(status: service.status),
            ],
          ),
          // Description
          if (service.description != null) ...[
            const SizedBox(height: 16),
            Text(
              service.description!,
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: CodeOpsColors.border, height: 1),
          const SizedBox(height: 16),
          // Metadata grid
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _MetaItem(
                label: 'Type',
                value: service.serviceType.displayName,
              ),
              if (service.techStack != null)
                _MetaItem(label: 'Tech Stack', value: service.techStack!),
              if (service.repoUrl != null)
                _MetaItem(label: 'Repository', value: service.repoUrl!),
              if (service.healthCheckUrl != null)
                _MetaItem(
                    label: 'Health Check URL',
                    value: service.healthCheckUrl!),
              _MetaItem(
                label: 'Created',
                value: formatDateTime(service.createdAt),
              ),
              _MetaItem(
                label: 'Updated',
                value: formatDateTime(service.updatedAt),
              ),
            ],
          ),
          // Counts
          if ((service.portCount ?? 0) > 0 ||
              (service.dependencyCount ?? 0) > 0 ||
              (service.solutionCount ?? 0) > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: CodeOpsColors.border, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                if (service.portCount != null)
                  _CountChip(
                      label: 'Ports', count: service.portCount!),
                if (service.dependencyCount != null) ...[
                  const SizedBox(width: 16),
                  _CountChip(
                      label: 'Dependencies',
                      count: service.dependencyCount!),
                ],
                if (service.solutionCount != null) ...[
                  const SizedBox(width: 16),
                  _CountChip(
                      label: 'Solutions', count: service.solutionCount!),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Labeled metadata value used in the service header grid.
class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Small chip showing a count badge with label.
class _CountChip extends StatelessWidget {
  final String label;
  final int count;

  const _CountChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CodeOpsColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
