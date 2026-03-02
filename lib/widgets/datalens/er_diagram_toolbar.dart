/// Toolbar for the ER diagram canvas.
///
/// Provides controls for notation style, zoom, layout, expand/collapse,
/// and export. Sits above the [ErDiagramCanvas] in the ER diagram page.
library;

import 'package:flutter/material.dart';

import '../../models/datalens_er_models.dart';
import '../../theme/colors.dart';

/// Toolbar displayed above the ER diagram canvas.
///
/// Contains controls for:
/// - Notation toggle (Crow's Foot / IDEF1X)
/// - Zoom (in, out, fit, reset)
/// - Auto-layout
/// - Expand all / Collapse all
/// - Export (PNG, SVG)
class ErDiagramToolbar extends StatelessWidget {
  /// Current notation style.
  final ErNotation notation;

  /// Current zoom percentage (1.0 = 100%).
  final double zoom;

  /// Called when the notation toggle is tapped.
  final ValueChanged<ErNotation>? onNotationChanged;

  /// Called when auto-layout is requested.
  final VoidCallback? onAutoLayout;

  /// Called when zoom-to-fit is requested.
  final VoidCallback? onZoomToFit;

  /// Called when zoom reset (100%) is requested.
  final VoidCallback? onZoomReset;

  /// Called when expand-all is requested.
  final VoidCallback? onExpandAll;

  /// Called when collapse-all is requested.
  final VoidCallback? onCollapseAll;

  /// Called when PNG export is requested.
  final VoidCallback? onExportPng;

  /// Called when SVG export is requested.
  final VoidCallback? onExportSvg;

  /// Creates an [ErDiagramToolbar].
  const ErDiagramToolbar({
    super.key,
    required this.notation,
    required this.zoom,
    this.onNotationChanged,
    this.onAutoLayout,
    this.onZoomToFit,
    this.onZoomReset,
    this.onExpandAll,
    this.onCollapseAll,
    this.onExportPng,
    this.onExportSvg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CodeOpsColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Notation toggle.
          _NotationToggle(
            notation: notation,
            onChanged: onNotationChanged,
          ),

          const SizedBox(width: 4),
          const _VerticalSeparator(),
          const SizedBox(width: 4),

          // Zoom controls.
          _ToolbarButton(
            icon: Icons.zoom_in,
            tooltip: 'Zoom to Fit',
            onPressed: onZoomToFit,
          ),
          _ToolbarButton(
            icon: Icons.center_focus_strong,
            tooltip: 'Reset View (100%)',
            onPressed: onZoomReset,
          ),
          const SizedBox(width: 4),
          Text(
            '${(zoom * 100).round()}%',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textSecondary,
            ),
          ),

          const SizedBox(width: 4),
          const _VerticalSeparator(),
          const SizedBox(width: 4),

          // Layout.
          _ToolbarButton(
            icon: Icons.auto_fix_high,
            tooltip: 'Auto Layout',
            onPressed: onAutoLayout,
          ),

          // Expand / Collapse.
          _ToolbarButton(
            icon: Icons.unfold_more,
            tooltip: 'Expand All',
            onPressed: onExpandAll,
          ),
          _ToolbarButton(
            icon: Icons.unfold_less,
            tooltip: 'Collapse All',
            onPressed: onCollapseAll,
          ),

          const SizedBox(width: 4),
          const _VerticalSeparator(),
          const SizedBox(width: 4),

          // Export.
          _ToolbarButton(
            icon: Icons.image_outlined,
            tooltip: 'Export PNG',
            onPressed: onExportPng,
          ),
          _ToolbarButton(
            icon: Icons.code,
            tooltip: 'Export SVG',
            onPressed: onExportSvg,
          ),

          const Spacer(),

          // Table count.
          const Icon(Icons.table_chart, size: 14, color: CodeOpsColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            'Tables',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notation Toggle
// ─────────────────────────────────────────────────────────────────────────────

/// Segmented toggle for switching between notation styles.
class _NotationToggle extends StatelessWidget {
  final ErNotation notation;
  final ValueChanged<ErNotation>? onChanged;

  const _NotationToggle({required this.notation, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NotationChip(
          label: "Crow's Foot",
          isSelected: notation == ErNotation.crowsFoot,
          onTap: () => onChanged?.call(ErNotation.crowsFoot),
        ),
        const SizedBox(width: 2),
        _NotationChip(
          label: 'IDEF1X',
          isSelected: notation == ErNotation.idef1x,
          onTap: () => onChanged?.call(ErNotation.idef1x),
        ),
      ],
    );
  }
}

/// A single chip in the notation toggle.
class _NotationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NotationChip({
    required this.label,
    required this.isSelected,
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
          color: isSelected
              ? CodeOpsColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? CodeOpsColors.primary : CodeOpsColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected
                ? CodeOpsColors.primary
                : CodeOpsColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Toolbar Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// A single toolbar icon button.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      color: onPressed != null
          ? CodeOpsColors.textSecondary
          : CodeOpsColors.textTertiary,
      splashRadius: 16,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}

/// Vertical separator between toolbar button groups.
class _VerticalSeparator extends StatelessWidget {
  const _VerticalSeparator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      child: VerticalDivider(width: 1, color: CodeOpsColors.border),
    );
  }
}
