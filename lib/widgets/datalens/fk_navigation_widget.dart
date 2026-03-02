/// Foreign key navigation widget for the DataLens data grid.
///
/// Displays a link icon on FK column cells. Clicking navigates to the
/// referenced table and row. Maintains a breadcrumb trail for navigation
/// history so the user can retrace their path.
library;

import 'package:flutter/material.dart';

import '../../models/datalens_models.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

/// A single step in the FK navigation breadcrumb trail.
class FkBreadcrumb {
  /// Schema of the table navigated from.
  final String schemaName;

  /// Table name navigated from.
  final String tableName;

  /// Display label (usually tableName).
  final String label;

  /// The FK column value used for navigation.
  final dynamic fkValue;

  /// Creates an [FkBreadcrumb].
  const FkBreadcrumb({
    required this.schemaName,
    required this.tableName,
    required this.label,
    this.fkValue,
  });
}

/// Callback when the user clicks an FK link to navigate.
typedef FkNavigateCallback = void Function(
  String referencedSchema,
  String referencedTable,
  String referencedColumn,
  dynamic value,
);

/// Callback when the user clicks a breadcrumb to return.
typedef FkBreadcrumbCallback = void Function(int breadcrumbIndex);

// ─────────────────────────────────────────────────────────────────────────────
// FK Cell Indicator
// ─────────────────────────────────────────────────────────────────────────────

/// An FK link icon displayed next to a foreign key cell value.
///
/// When tapped, invokes [onNavigate] with the FK details so the parent
/// can load the referenced row.
class FkCellIndicator extends StatelessWidget {
  /// The cell value (FK column value).
  final dynamic cellValue;

  /// The FK metadata for this column.
  final ForeignKeyInfo foreignKey;

  /// The source column name in the FK.
  final String sourceColumn;

  /// Called when the FK link is tapped.
  final FkNavigateCallback? onNavigate;

  /// Creates an [FkCellIndicator].
  const FkCellIndicator({
    super.key,
    required this.cellValue,
    required this.foreignKey,
    required this.sourceColumn,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (cellValue == null) return const SizedBox.shrink();

    final refTable = foreignKey.referencedTable ?? '?';
    final refColumn = _resolveReferencedColumn();

    return Tooltip(
      message: 'Navigate to $refTable.$refColumn = $cellValue',
      child: InkWell(
        onTap: onNavigate != null
            ? () => onNavigate!(
                  foreignKey.referencedSchema ?? 'public',
                  refTable,
                  refColumn,
                  cellValue,
                )
            : null,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(2),
          child: Icon(
            Icons.link,
            size: 12,
            color: CodeOpsColors.secondary,
          ),
        ),
      ),
    );
  }

  /// Resolves the referenced column name from the FK metadata.
  String _resolveReferencedColumn() {
    final srcCols = foreignKey.columns ?? [];
    final refCols = foreignKey.referencedColumns ?? [];
    final idx = srcCols.indexOf(sourceColumn);
    if (idx >= 0 && idx < refCols.length) {
      return refCols[idx];
    }
    return refCols.isNotEmpty ? refCols.first : '?';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Breadcrumb Trail
// ─────────────────────────────────────────────────────────────────────────────

/// A horizontal breadcrumb trail showing FK navigation history.
///
/// Each breadcrumb represents a table the user navigated through.
/// Clicking a breadcrumb navigates back to that point in the trail.
class FkBreadcrumbTrail extends StatelessWidget {
  /// The breadcrumb entries (oldest first).
  final List<FkBreadcrumb> breadcrumbs;

  /// The current table name (shown at the end, not clickable).
  final String currentTable;

  /// Called when a breadcrumb is tapped to navigate back.
  final FkBreadcrumbCallback? onBreadcrumbTap;

  /// Called when the home/root breadcrumb is tapped.
  final VoidCallback? onHome;

  /// Creates an [FkBreadcrumbTrail].
  const FkBreadcrumbTrail({
    super.key,
    required this.breadcrumbs,
    required this.currentTable,
    this.onBreadcrumbTap,
    this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    if (breadcrumbs.isEmpty) return const SizedBox.shrink();

    return Container(
      color: CodeOpsColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Home icon.
          InkWell(
            onTap: onHome,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.home_outlined,
                size: 14,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),

          // Breadcrumb entries.
          ...breadcrumbs.asMap().entries.expand((entry) => [
                const _BreadcrumbSeparator(),
                _BreadcrumbChip(
                  label: entry.value.label,
                  onTap: onBreadcrumbTap != null
                      ? () => onBreadcrumbTap!(entry.key)
                      : null,
                ),
              ]),

          // Current table (not clickable).
          const _BreadcrumbSeparator(),
          Text(
            currentTable,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Separator chevron between breadcrumbs.
class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: 14,
        color: CodeOpsColors.textTertiary,
      ),
    );
  }
}

/// A single clickable breadcrumb chip.
class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _BreadcrumbChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.secondary,
            decoration: TextDecoration.underline,
            decorationColor: CodeOpsColors.secondary,
          ),
        ),
      ),
    );
  }
}
