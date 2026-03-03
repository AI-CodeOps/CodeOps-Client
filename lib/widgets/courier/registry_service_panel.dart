/// Service discovery panel for Courier's Registry integration.
///
/// Lists all registered services from the Registry with health status,
/// port, and API route count. Expanding a service reveals the base URL,
/// "Import OpenAPI" / "Quick Test" / "View API Docs" action buttons,
/// and a "Generate Environment" button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../providers/courier_providers.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RegistryServicePanel
// ─────────────────────────────────────────────────────────────────────────────

/// Panel listing registered services for Courier integration.
///
/// Fetches services from [registryServicesForCourierProvider] and renders
/// each with a health dot, name, port, and expandable detail section.
class RegistryServicePanel extends ConsumerStatefulWidget {
  /// Called when the user taps "Quick Test" on a service, providing the
  /// base URL to pre-populate in a new request tab.
  final void Function(String baseUrl)? onQuickTest;

  /// Called when the user taps "Import OpenAPI" on a service.
  final void Function(String serviceId, String serviceName)? onImportOpenApi;

  /// Creates a [RegistryServicePanel].
  const RegistryServicePanel({
    super.key,
    this.onQuickTest,
    this.onImportOpenApi,
  });

  @override
  ConsumerState<RegistryServicePanel> createState() =>
      _RegistryServicePanelState();
}

class _RegistryServicePanelState extends ConsumerState<RegistryServicePanel> {
  String? _expandedServiceId;

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(registryServicesForCourierProvider);

    return Container(
      key: const Key('registry_service_panel'),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(right: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────
          Container(
            key: const Key('registry_panel_header'),
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: CodeOpsColors.border)),
            ),
            child: const Row(
              children: [
                Icon(Icons.dns_outlined,
                    size: 16, color: CodeOpsColors.primary),
                SizedBox(width: 8),
                Text(
                  'Registered Services',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Service list ───────────────────────────────────────────
          Expanded(
            child: servicesAsync.when(
              data: (services) => services.isEmpty
                  ? const Center(
                      child: Text(
                        'No services registered',
                        style: TextStyle(
                            fontSize: 13,
                            color: CodeOpsColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      key: const Key('services_list'),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: services.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: CodeOpsColors.border,
                      ),
                      itemBuilder: (context, index) =>
                          _ServiceTile(
                            service: services[index],
                            isExpanded:
                                _expandedServiceId == services[index].id,
                            onToggle: () => setState(() {
                              _expandedServiceId =
                                  _expandedServiceId == services[index].id
                                      ? null
                                      : services[index].id;
                            }),
                            onQuickTest: widget.onQuickTest,
                            onImportOpenApi: widget.onImportOpenApi,
                          ),
                    ),
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: CodeOpsColors.primary)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(
                          fontSize: 12, color: CodeOpsColors.error))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service tile (collapsed + expanded)
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceTile extends ConsumerWidget {
  final ServiceRegistrationResponse service;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(String baseUrl)? onQuickTest;
  final void Function(String serviceId, String serviceName)? onImportOpenApi;

  const _ServiceTile({
    required this.service,
    required this.isExpanded,
    required this.onToggle,
    this.onQuickTest,
    this.onImportOpenApi,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthColor =
        CodeOpsColors.healthStatusColors[service.lastHealthStatus] ??
            CodeOpsColors.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Collapsed row ────────────────────────────────────────────
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Health dot
                Container(
                  key: const Key('health_dot'),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: healthColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                // Service name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CodeOpsColors.textPrimary,
                        ),
                      ),
                      if (service.techStack != null)
                        Text(
                          service.techStack!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: CodeOpsColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  key: const Key('status_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    service.lastHealthStatus?.name.toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: healthColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: CodeOpsColors.textTertiary,
                ),
              ],
            ),
          ),
        ),

        // ── Expanded detail ──────────────────────────────────────────
        if (isExpanded) _ExpandedDetail(
          service: service,
          onQuickTest: onQuickTest,
          onImportOpenApi: onImportOpenApi,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded detail
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandedDetail extends ConsumerWidget {
  final ServiceRegistrationResponse service;
  final void Function(String baseUrl)? onQuickTest;
  final void Function(String serviceId, String serviceName)? onImportOpenApi;

  const _ExpandedDetail({
    required this.service,
    this.onQuickTest,
    this.onImportOpenApi,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portsAsync = ref.watch(servicePortsForCourierProvider(service.id));
    final routesAsync = ref.watch(serviceApiRoutesProvider(service.id));

    return Container(
      key: const Key('service_detail'),
      padding: const EdgeInsets.fromLTRB(30, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Base URL from port
          portsAsync.when(
            data: (ports) {
              final httpPort = ports
                  .where((p) => p.portType == PortType.httpApi)
                  .toList();
              if (httpPort.isEmpty) {
                return const Text(
                  'No HTTP port allocated',
                  style: TextStyle(
                      fontSize: 11, color: CodeOpsColors.textTertiary),
                );
              }
              final baseUrl =
                  'http://localhost:${httpPort.first.portNumber}';
              return Row(
                children: [
                  const Icon(Icons.link,
                      size: 12, color: CodeOpsColors.textTertiary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: SelectableText(
                      baseUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: CodeOpsColors.secondary,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),

          // Route count
          routesAsync.when(
            data: (routes) => Text(
              '${routes.length} API route${routes.length == 1 ? '' : 's'}',
              key: const Key('route_count'),
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textSecondary),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Last health check
          if (service.lastHealthCheckAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Last checked: ${_formatTime(service.lastHealthCheckAt!)}',
                style: const TextStyle(
                    fontSize: 11, color: CodeOpsColors.textTertiary),
              ),
            ),
          const SizedBox(height: 10),

          // Action buttons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ActionChip(
                key: const Key('import_openapi_button'),
                icon: Icons.download,
                label: 'Import OpenAPI',
                onTap: onImportOpenApi != null
                    ? () => onImportOpenApi!(service.id, service.name)
                    : null,
              ),
              _ActionChip(
                key: const Key('quick_test_button'),
                icon: Icons.play_arrow,
                label: 'Quick Test',
                onTap: () {
                  final ports =
                      ref.read(servicePortsForCourierProvider(service.id));
                  final httpPorts = ports.valueOrNull
                          ?.where((p) => p.portType == PortType.httpApi)
                          .toList() ??
                      [];
                  if (httpPorts.isNotEmpty && onQuickTest != null) {
                    onQuickTest!(
                        'http://localhost:${httpPorts.first.portNumber}');
                  }
                },
              ),
              _ActionChip(
                key: const Key('view_docs_button'),
                icon: Icons.description_outlined,
                label: 'View Docs',
                onTap: () {
                  ref.read(apiDocsServiceIdProvider.notifier).state =
                      service.id;
                  context.go('/registry/api-docs');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${h == 0 ? 12 : h}:$m $ampm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action chip
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionChip({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: CodeOpsColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: CodeOpsColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: CodeOpsColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
