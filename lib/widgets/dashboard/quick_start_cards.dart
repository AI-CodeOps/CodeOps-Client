/// Quick-start action cards for the home dashboard.
///
/// Four cards that navigate to primary workflows: Audit, Bug Investigation,
/// Compliance Check, and Dependency Scan.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';

/// A row of quick-start action cards for common workflows.
class QuickStartCards extends StatelessWidget {
  /// Creates a [QuickStartCards] widget.
  const QuickStartCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickCard(
          icon: Icons.security,
          title: 'Run Audit',
          route: '/audit',
        ),
        const SizedBox(width: 16),
        _QuickCard(
          icon: Icons.bug_report_outlined,
          title: 'Investigate Bug',
          route: '/bugs',
        ),
        const SizedBox(width: 16),
        _QuickCard(
          icon: Icons.verified_outlined,
          title: 'Compliance Check',
          route: '/compliance',
        ),
        const SizedBox(width: 16),
        _QuickCard(
          icon: Icons.inventory_2_outlined,
          title: 'Scan Dependencies',
          route: '/dependencies',
        ),
      ].map((child) {
        if (child is SizedBox) return child;
        return Expanded(child: child);
      }).toList(),
    );
  }
}

class _QuickCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String route;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.route,
  });

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CodeOpsColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? CodeOpsColors.primary : CodeOpsColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: CodeOpsColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 32,
                color: _hovered
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _hovered
                      ? CodeOpsColors.textPrimary
                      : CodeOpsColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
