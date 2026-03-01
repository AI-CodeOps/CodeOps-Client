/// Icon widget for database column types.
///
/// Returns a context-appropriate icon based on the column's data type
/// and category (primary key, foreign key, text, number, timestamp, etc.).
/// Matches the DBeaver column icon convention.
library;

import 'package:flutter/material.dart';

import '../../models/datalens_enums.dart';
import '../../theme/colors.dart';

/// Displays a type-specific icon for a database column.
///
/// Icon selection priority:
/// 1. [ColumnCategory.primaryKey] → key icon (amber)
/// 2. [ColumnCategory.foreignKey] → link icon (blue)
/// 3. Data type based: text → AZ, number → 123, timestamp → clock, etc.
class ColumnTypeIcon extends StatelessWidget {
  /// The PostgreSQL underlying type name (e.g., "varchar", "int4", "uuid").
  final String? udtName;

  /// The column's role (primary key, foreign key, regular, etc.).
  final ColumnCategory? category;

  /// Icon size in logical pixels.
  final double size;

  /// Creates a [ColumnTypeIcon].
  const ColumnTypeIcon({
    super.key,
    this.udtName,
    this.category,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve();
    return Icon(resolved.icon, size: size, color: resolved.color);
  }

  /// Resolves the icon and color for this column.
  _IconData _resolve() {
    // Category overrides take priority.
    if (category == ColumnCategory.primaryKey) {
      return _IconData(Icons.vpn_key, CodeOpsColors.warning);
    }
    if (category == ColumnCategory.foreignKey) {
      return _IconData(Icons.link, const Color(0xFF3B82F6));
    }

    // Data type based.
    final type = (udtName ?? '').toLowerCase();
    return switch (type) {
      // Text types
      'varchar' ||
      'text' ||
      'char' ||
      'bpchar' ||
      'name' ||
      'citext' =>
        _IconData(Icons.sort_by_alpha, CodeOpsColors.textSecondary),
      // Numeric types
      'int2' ||
      'int4' ||
      'int8' ||
      'float4' ||
      'float8' ||
      'numeric' ||
      'money' ||
      'smallint' ||
      'integer' ||
      'bigint' =>
        _IconData(Icons.tag, CodeOpsColors.secondary),
      // Timestamp / date / time types
      'timestamp' ||
      'timestamptz' ||
      'date' ||
      'time' ||
      'timetz' ||
      'interval' =>
        _IconData(Icons.access_time, const Color(0xFFA855F7)),
      // Boolean
      'bool' || 'boolean' =>
        _IconData(Icons.check_box_outlined, CodeOpsColors.success),
      // JSON
      'json' || 'jsonb' =>
        _IconData(Icons.data_object, const Color(0xFFF97316)),
      // UUID
      'uuid' => _IconData(Icons.fingerprint, CodeOpsColors.textSecondary),
      // Binary
      'bytea' => _IconData(Icons.memory, CodeOpsColors.textTertiary),
      // Array types
      _ when type.startsWith('_') =>
        _IconData(Icons.data_array, CodeOpsColors.textSecondary),
      // Default
      _ => _IconData(Icons.circle_outlined, CodeOpsColors.textTertiary),
    };
  }
}

/// Internal data class for icon + color pair.
class _IconData {
  final IconData icon;
  final Color color;

  const _IconData(this.icon, this.color);
}
