/// Dashboard grid layout manager.
///
/// Arranges [DashboardWidgetCard] instances in a responsive grid
/// based on each widget's gridX, gridY, gridWidth, gridHeight values.
/// In edit mode, shows placeholders for empty cells.
library;

import 'package:flutter/material.dart';

import '../../models/logger_models.dart';
import '../../theme/colors.dart';
import 'dashboard_widget_card.dart';

/// A responsive grid that positions dashboard widgets by their grid coordinates.
///
/// Uses a 12-column grid. Each widget occupies gridWidth columns and
/// gridHeight rows. When [isEditMode] is true, the grid shows visual
/// affordances for repositioning.
class DashboardGrid extends StatelessWidget {
  /// The widgets to lay out.
  final List<DashboardWidgetResponse> widgets;

  /// Whether the grid is in edit mode (shows remove buttons, handles).
  final bool isEditMode;

  /// Called when a widget's refresh button is tapped.
  final void Function(DashboardWidgetResponse widget)? onRefreshWidget;

  /// Called when a widget's configure button is tapped.
  final void Function(DashboardWidgetResponse widget)? onConfigureWidget;

  /// Called when a widget's remove button is tapped.
  final void Function(DashboardWidgetResponse widget)? onRemoveWidget;

  /// Creates a [DashboardGrid].
  const DashboardGrid({
    super.key,
    required this.widgets,
    this.isEditMode = false,
    this.onRefreshWidget,
    this.onConfigureWidget,
    this.onRemoveWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (widgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.widgets_outlined,
              size: 48,
              color: CodeOpsColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No widgets yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Add a widget to get started.',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 12;
        const gap = 8.0;
        final cellWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        const cellHeight = 120.0;

        // Build positioned widget cards.
        final positioned = <Widget>[];
        for (final w in widgets) {
          final left = w.gridX * (cellWidth + gap);
          final top = w.gridY * (cellHeight + gap);
          final width =
              w.gridWidth * cellWidth + (w.gridWidth - 1) * gap;
          final height =
              w.gridHeight * cellHeight + (w.gridHeight - 1) * gap;

          positioned.add(
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: DashboardWidgetCard(
                widget: w,
                isEditMode: isEditMode,
                onRefresh: onRefreshWidget != null
                    ? () => onRefreshWidget!(w)
                    : null,
                onConfigure: onConfigureWidget != null
                    ? () => onConfigureWidget!(w)
                    : null,
                onRemove: onRemoveWidget != null
                    ? () => onRemoveWidget!(w)
                    : null,
              ),
            ),
          );
        }

        // Calculate total height needed.
        double maxBottom = 0;
        for (final w in widgets) {
          final bottom =
              (w.gridY + w.gridHeight) * (cellHeight + gap) - gap;
          if (bottom > maxBottom) maxBottom = bottom;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: constraints.maxWidth,
            height: maxBottom.clamp(cellHeight, double.infinity),
            child: Stack(children: positioned),
          ),
        );
      },
    );
  }
}
