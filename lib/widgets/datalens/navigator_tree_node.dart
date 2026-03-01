/// Reusable tree node widget for the database navigator.
///
/// Renders a single row in the navigator tree with configurable depth-based
/// indentation, expand/collapse arrow, icon, label, and optional trailing
/// text or badge. Supports selection highlighting and hover effects.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A single node in the database navigator tree.
///
/// Displays an indented row with an optional expand/collapse arrow,
/// a leading icon, a label, and optional trailing text or badge count.
/// Supports selection state, hover highlight, and tap/double-tap callbacks.
class NavigatorTreeNode extends StatefulWidget {
  /// Nesting depth for indentation (0 = root level).
  final int depth;

  /// Whether this node is currently expanded (shows child nodes).
  final bool isExpanded;

  /// Whether this node can be expanded (has children).
  final bool isExpandable;

  /// Whether this node is currently selected.
  final bool isSelected;

  /// Leading icon for this node.
  final IconData icon;

  /// Optional color override for the leading icon.
  final Color? iconColor;

  /// Display label text.
  final String label;

  /// Optional trailing text (e.g., row count, table size).
  final String? trailingText;

  /// Optional trailing badge count.
  final int? badgeCount;

  /// Callback invoked on single tap.
  final VoidCallback? onTap;

  /// Callback invoked on double tap.
  final VoidCallback? onDoubleTap;

  /// Creates a [NavigatorTreeNode].
  const NavigatorTreeNode({
    super.key,
    required this.depth,
    this.isExpanded = false,
    this.isExpandable = false,
    this.isSelected = false,
    required this.icon,
    this.iconColor,
    required this.label,
    this.trailingText,
    this.badgeCount,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<NavigatorTreeNode> createState() => _NavigatorTreeNodeState();
}

class _NavigatorTreeNodeState extends State<NavigatorTreeNode> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final leftPadding = 12.0 + (widget.depth * 20.0);
    final iconColor = widget.iconColor ??
        (widget.isSelected
            ? CodeOpsColors.primary
            : CodeOpsColors.textTertiary);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.only(
            left: leftPadding,
            right: 12,
            top: 4,
            bottom: 4,
          ),
          color: widget.isSelected
              ? CodeOpsColors.primary.withValues(alpha: 0.1)
              : _isHovered
                  ? CodeOpsColors.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
          child: Row(
            children: [
              // Expand/collapse arrow
              if (widget.isExpandable)
                Icon(
                  widget.isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: CodeOpsColors.textTertiary,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 4),
              // Leading icon
              Icon(widget.icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              // Label
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: widget.isSelected
                        ? CodeOpsColors.textPrimary
                        : CodeOpsColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Trailing text
              if (widget.trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    widget.trailingText!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ),
              // Badge count
              if (widget.badgeCount != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: CodeOpsColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.badgeCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
