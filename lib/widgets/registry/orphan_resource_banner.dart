/// Warning banner displaying orphaned infrastructure resources.
///
/// Shows a collapsible list of resources not assigned to any active service,
/// with a reassign button per item and an expand/collapse toggle.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import 'infra_resource_type_icon.dart';

/// Warning banner showing orphaned infrastructure resources.
///
/// Collapsed state shows count and summary. Expanded state lists each
/// orphan with its type icon, name, environment, and a [Reassign] button.
class OrphanResourceBanner extends StatefulWidget {
  /// The list of orphaned resources.
  final List<InfraResourceResponse> orphans;

  /// Called when the user taps "Reassign" on a specific orphan.
  final ValueChanged<InfraResourceResponse>? onReassign;

  /// Creates an [OrphanResourceBanner].
  const OrphanResourceBanner({
    super.key,
    required this.orphans,
    this.onReassign,
  });

  @override
  State<OrphanResourceBanner> createState() => _OrphanResourceBannerState();
}

class _OrphanResourceBannerState extends State<OrphanResourceBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.orphans.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CodeOpsColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: CodeOpsColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.orphans.length} orphan resource${widget.orphans.length == 1 ? '' : 's'} detected \u2014 not assigned to any service',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CodeOpsColors.warning,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: CodeOpsColors.warning,
                  ),
                ],
              ),
            ),
          ),
          // Expanded list
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: widget.orphans.map((orphan) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        InfraResourceTypeIcon(
                          type: orphan.resourceType,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${orphan.resourceType.displayName}: ${orphan.resourceName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CodeOpsColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          orphan.environment,
                          style: const TextStyle(
                            fontSize: 11,
                            color: CodeOpsColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 24,
                          child: OutlinedButton(
                            onPressed: widget.onReassign != null
                                ? () => widget.onReassign!(orphan)
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              foregroundColor: CodeOpsColors.primary,
                              side: const BorderSide(
                                color: CodeOpsColors.primary,
                              ),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            child: const Text('Reassign'),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
