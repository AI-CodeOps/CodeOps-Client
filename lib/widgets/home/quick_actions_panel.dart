// Quick actions panel for the unified dashboard.
//
// Displays a grid of shortcut buttons that navigate to common workflows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dashboard_providers.dart';
import '../../theme/colors.dart';

/// A panel of quick action buttons for the dashboard.
class QuickActionsPanel extends ConsumerWidget {
  /// Creates a [QuickActionsPanel].
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(quickActionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                _ActionChip(action: action),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatefulWidget {
  final QuickAction action;

  const _ActionChip({required this.action});

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.action.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? CodeOpsColors.primary.withValues(alpha: 0.15)
                : CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? CodeOpsColors.primary : CodeOpsColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.action.icon,
                size: 16,
                color: _hovered
                    ? CodeOpsColors.primary
                    : CodeOpsColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.action.label,
                style: TextStyle(
                  color: _hovered
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
