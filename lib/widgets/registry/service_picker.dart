/// Multi-select service picker for workstation profile creation/editing.
///
/// Shows all team services grouped by [ServiceType] with checkboxes,
/// search filter, and Select All / Clear All actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import 'service_type_icon.dart';

/// Multi-select service picker grouped by service type.
///
/// Reads team services from [registryServicesProvider] and groups them by
/// [ServiceType]. Each group has a header with type icon and count.
class ServicePicker extends ConsumerStatefulWidget {
  /// Currently selected service IDs.
  final Set<String> selectedServiceIds;

  /// Called when the selection changes.
  final ValueChanged<Set<String>> onChanged;

  /// Creates a [ServicePicker].
  const ServicePicker({
    super.key,
    required this.selectedServiceIds,
    required this.onChanged,
  });

  @override
  ConsumerState<ServicePicker> createState() => _ServicePickerState();
}

class _ServicePickerState extends ConsumerState<ServicePicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(registryServicesProvider);

    return servicesAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Failed to load services',
        style: TextStyle(color: CodeOpsColors.error, fontSize: 13),
      ),
      data: (page) {
        final allServices = page.content;
        final filtered = _search.isEmpty
            ? allServices
            : allServices
                .where((s) =>
                    s.name.toLowerCase().contains(_search.toLowerCase()) ||
                    s.slug.toLowerCase().contains(_search.toLowerCase()))
                .toList();

        // Group by type.
        final groups = <ServiceType, List<ServiceRegistrationResponse>>{};
        for (final s in filtered) {
          groups.putIfAbsent(s.serviceType, () => []).add(s);
        }
        final sortedKeys = groups.keys.toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search + actions
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search services...',
                      hintStyle: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: CodeOpsColors.textPrimary,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    final all = allServices.map((s) => s.id).toSet();
                    widget.onChanged(all);
                  },
                  child: const Text('Select All',
                      style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => widget.onChanged({}),
                  child: const Text('Clear All',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.selectedServiceIds.length} of '
              '${allServices.length} selected',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            // Grouped list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final type in sortedKeys) ...[
                    // Group header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          ServiceTypeIcon(type: type, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            type.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CodeOpsColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${groups[type]!.where((s) => widget.selectedServiceIds.contains(s.id)).length}/${groups[type]!.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CodeOpsColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Service rows
                    for (final svc in groups[type]!)
                      _ServiceRow(
                        service: svc,
                        selected:
                            widget.selectedServiceIds.contains(svc.id),
                        onChanged: (checked) {
                          final updated =
                              Set<String>.from(widget.selectedServiceIds);
                          if (checked) {
                            updated.add(svc.id);
                          } else {
                            updated.remove(svc.id);
                          }
                          widget.onChanged(updated);
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final ServiceRegistrationResponse service;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _ServiceRow({
    required this.service,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: selected,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                service.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
            ),
            Text(
              service.slug,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
