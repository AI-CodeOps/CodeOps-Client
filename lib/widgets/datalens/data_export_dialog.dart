/// Export dialog for downloading query results from the data browser.
///
/// Allows the user to select export format (CSV, JSON, SQL INSERT), scope
/// (current page or all rows), and save location via file_picker.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/datalens_models.dart';
import '../../theme/colors.dart';

/// Export format options.
enum ExportFormat {
  /// Comma-separated values.
  csv,

  /// JSON array of objects.
  json,

  /// SQL INSERT statements.
  sql;

  /// Human-readable label.
  String get label => switch (this) {
        ExportFormat.csv => 'CSV',
        ExportFormat.json => 'JSON',
        ExportFormat.sql => 'SQL INSERT',
      };
}

/// Export scope options.
enum ExportScope {
  /// Current page only.
  currentPage,

  /// All rows.
  allRows;

  /// Human-readable label.
  String get label => switch (this) {
        ExportScope.currentPage => 'Current Page',
        ExportScope.allRows => 'All Rows',
      };
}

/// Dialog for exporting data browser results to a file.
///
/// Shows format selection (CSV, JSON, SQL INSERT), scope selection
/// (current page / all rows), and a save button that opens a file picker.
class DataExportDialog extends StatefulWidget {
  /// The query result to export.
  final QueryResult result;

  /// Optional table name for SQL INSERT statements.
  final String? tableName;

  /// Creates a [DataExportDialog].
  const DataExportDialog({
    super.key,
    required this.result,
    this.tableName,
  });

  @override
  State<DataExportDialog> createState() => _DataExportDialogState();
}

class _DataExportDialogState extends State<DataExportDialog> {
  ExportFormat _format = ExportFormat.csv;
  ExportScope _scope = ExportScope.currentPage;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text(
        'Export Data',
        style: TextStyle(
          color: CodeOpsColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            const Text(
              'Format',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...ExportFormat.values.map((f) => RadioListTile<ExportFormat>(
                  value: f,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                  title: Text(
                    f.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: CodeOpsColors.primary,
                )),

            const SizedBox(height: 16),

            // Scope selection
            const Text(
              'Scope',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...ExportScope.values.map((s) => RadioListTile<ExportScope>(
                  value: s,
                  groupValue: _scope,
                  onChanged: (v) => setState(() => _scope = v!),
                  title: Text(
                    s.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: CodeOpsColors.primary,
                )),

            if (_exporting) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(
                  color: CodeOpsColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _exporting ? null : _export,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Export'),
        ),
      ],
    );
  }

  /// Exports the data to a file.
  Future<void> _export() async {
    final extension = switch (_format) {
      ExportFormat.csv => 'csv',
      ExportFormat.json => 'json',
      ExportFormat.sql => 'sql',
    };

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Data',
      fileName: '${widget.tableName ?? 'export'}.$extension',
      type: FileType.any,
    );

    if (result == null) return;

    setState(() => _exporting = true);

    try {
      final content = _generateContent();
      await File(result).writeAsString(content);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Generates the export content string.
  String _generateContent() {
    final columns = widget.result.columns ?? [];
    final rows = widget.result.rows ?? [];

    return switch (_format) {
      ExportFormat.csv => _toCsv(columns, rows),
      ExportFormat.json => _toJson(columns, rows),
      ExportFormat.sql => _toSql(columns, rows),
    };
  }

  /// Converts to CSV.
  String _toCsv(List<QueryColumn> columns, List<List<dynamic>> rows) {
    final buf = StringBuffer();
    buf.writeln(columns.map((c) => _csvEscape(c.name ?? '')).join(','));
    for (final row in rows) {
      buf.writeln(
        List.generate(columns.length, (i) {
          final val = i < row.length ? row[i] : null;
          return _csvEscape(val?.toString() ?? '');
        }).join(','),
      );
    }
    return buf.toString();
  }

  /// Escapes a CSV field.
  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Converts to JSON array of objects.
  String _toJson(List<QueryColumn> columns, List<List<dynamic>> rows) {
    final objects = rows.map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < columns.length; i++) {
        map[columns[i].name ?? 'col_$i'] = i < row.length ? row[i] : null;
      }
      return map;
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(objects);
  }

  /// Converts to SQL INSERT statements.
  String _toSql(List<QueryColumn> columns, List<List<dynamic>> rows) {
    final table = widget.tableName ?? 'table_name';
    final colNames = columns.map((c) => '"${c.name ?? ''}"').join(', ');
    final buf = StringBuffer();
    for (final row in rows) {
      final values = List.generate(columns.length, (i) {
        final val = i < row.length ? row[i] : null;
        if (val == null) return 'NULL';
        if (val is num || val is bool) return val.toString();
        return "'${val.toString().replaceAll("'", "''")}'";
      }).join(', ');
      buf.writeln('INSERT INTO $table ($colNames) VALUES ($values);');
    }
    return buf.toString();
  }
}
