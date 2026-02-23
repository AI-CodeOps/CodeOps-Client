/// Collapsible legend for the topology viewer.
///
/// Shows health status colors, dependency type edge colors,
/// cluster boundary convention, and required vs optional edge styles.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../theme/colors.dart';

/// Collapsible legend showing topology node and edge conventions.
///
/// Displays health indicator colors, dependency type edge colors,
/// cluster boundary explanation, and required vs optional distinction.
class TopologyLegend extends StatefulWidget {
  /// Creates a [TopologyLegend].
  const TopologyLegend({super.key});

  @override
  State<TopologyLegend> createState() => _TopologyLegendState();
}

class _TopologyLegendState extends State<TopologyLegend> {
  bool _expanded = false;

  static const _healthItems = <(HealthStatus, String)>[
    (HealthStatus.up, 'UP'),
    (HealthStatus.down, 'DOWN'),
    (HealthStatus.degraded, 'Degraded'),
    (HealthStatus.unknown, 'Unknown'),
  ];

  static const _edgeTypes = <(DependencyType, Color, String)>[
    (DependencyType.httpRest, Color(0xFF2196F3), 'solid'),
    (DependencyType.grpc, Color(0xFF9C27B0), 'solid'),
    (DependencyType.kafkaTopic, Color(0xFFFF9800), 'dashed'),
    (DependencyType.databaseShared, Color(0xFF4CAF50), 'solid'),
    (DependencyType.redisShared, Color(0xFFF44336), 'solid'),
    (DependencyType.library_, Color(0xFF009688), 'dotted'),
    (DependencyType.gatewayRoute, Color(0xFF3F51B5), 'solid'),
    (DependencyType.websocket, Color(0xFF00BCD4), 'dashed'),
    (DependencyType.fileSystem, Color(0xFF795548), 'dotted'),
    (DependencyType.other, Color(0xFF9E9E9E), 'dashed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(top: BorderSide(color: CodeOpsColors.divider)),
      ),
      child: Column(
        children: [
          // Toggle row with inline summary
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Inline health dots
                  ..._healthItems.expand((item) {
                    final color =
                        CodeOpsColors.healthStatusColors[item.$1] ??
                            CodeOpsColors.textTertiary;
                    return [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontSize: 10,
                          color: CodeOpsColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ];
                  }),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_more : Icons.expand_less,
                    size: 16,
                    color: CodeOpsColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edge types
                  const Text(
                    'Edge Types',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: _edgeTypes.map((entry) {
                      final (type, color, style) = entry;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 16, height: 3, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '${type.displayName} ($style)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: CodeOpsColors.textTertiary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Conventions
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _ConventionItem(
                        label: 'Required',
                        child: Container(
                          width: 16,
                          height: 0,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: CodeOpsColors.textTertiary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _ConventionItem(
                        label: 'Optional',
                        child: SizedBox(
                          width: 16,
                          height: 2,
                          child: CustomPaint(
                            painter: _DashedPainter(),
                          ),
                        ),
                      ),
                      _ConventionItem(
                        label: 'Solution Group',
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: CodeOpsColors.textTertiary,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Convention legend item.
class _ConventionItem extends StatelessWidget {
  final Widget child;
  final String label;

  const _ConventionItem({required this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Paints a short dashed line for the legend.
class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CodeOpsColors.textTertiary
      ..strokeWidth = 2;
    const dashWidth = 4.0;
    const dashGap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + dashWidth, size.width), size.height / 2),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
