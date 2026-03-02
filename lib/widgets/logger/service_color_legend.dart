/// Color legend mapping service names to their assigned colors.
///
/// Displayed alongside the waterfall timeline to help users identify
/// which service each span bar represents.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Horizontal color legend for service-to-color mapping.
class ServiceColorLegend extends StatelessWidget {
  /// Map of service name to assigned color.
  final Map<String, Color> serviceColors;

  /// Creates a [ServiceColorLegend].
  const ServiceColorLegend({super.key, required this.serviceColors});

  @override
  Widget build(BuildContext context) {
    if (serviceColors.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Services: ',
            style: TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: serviceColors.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: entry.value,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: CodeOpsColors.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
