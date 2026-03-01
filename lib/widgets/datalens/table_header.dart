/// Table metadata header for the Properties panel.
///
/// Displays read-only metadata fields matching DBeaver's table header:
/// table name, comment, tablespace, partition info, object type, owner,
/// and boolean indicators for RLS and partitioning.
library;

import 'package:flutter/material.dart';

import '../../models/datalens_models.dart';
import '../../theme/colors.dart';

/// Displays table metadata in a compact header section.
///
/// Shows a two-column grid of read-only fields from [TableInfo]:
/// name, comment, tablespace, partition key, object type, owner,
/// row-level security, and partitioning status.
class TableHeader extends StatelessWidget {
  /// The table metadata to display.
  final TableInfo table;

  /// Creates a [TableHeader].
  const TableHeader({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Table Name + Object Type
          Row(
            children: [
              Expanded(
                child: _field('Table Name', table.tableName ?? ''),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _field(
                  'Object Type',
                  table.objectType?.displayName ?? 'Table',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Comment + Owner
          Row(
            children: [
              Expanded(
                child: _field('Comment', table.tableComment ?? ''),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _field('Owner', table.owner ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 3: Tablespace + Partition
          Row(
            children: [
              Expanded(
                child: _field('Tablespace', table.tablespace ?? 'pg_default'),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _field('Partition by', table.partitionKey ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 4: Boolean indicators
          Row(
            children: [
              _checkbox('Has Row-Level Security', table.hasRls ?? false),
              const SizedBox(width: 24),
              _checkbox('Partitioned', table.isPartitioned ?? false),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a labeled read-only text field.
  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 12,
            color: value.isEmpty
                ? CodeOpsColors.textTertiary
                : CodeOpsColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Builds a read-only checkbox indicator.
  Widget _checkbox(String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: Checkbox(
            value: value,
            onChanged: null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: CodeOpsColors.textTertiary),
            checkColor: CodeOpsColors.primary,
            activeColor: CodeOpsColors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
