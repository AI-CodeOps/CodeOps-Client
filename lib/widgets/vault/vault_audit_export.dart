/// Export dialog and utilities for Vault audit log entries.
///
/// Supports exporting the current filtered audit results as CSV or JSON
/// using the [file_picker] package for save-file dialogs.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/vault_models.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';

/// Provides static methods to export [AuditEntryResponse] lists.
///
/// [showExportDialog] presents a modal with CSV and JSON export buttons.
/// Each calls [exportCsv] or [exportJson] respectively, which open a
/// save-file dialog and write the formatted data.
class VaultAuditExport {
  VaultAuditExport._();

  /// Shows a dialog with CSV and JSON export options.
  static Future<void> showExportDialog(
    BuildContext context,
    List<AuditEntryResponse> entries,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Export Audit Log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entries.length} entries will be exported.',
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await exportCsv(context, entries);
                    },
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text('CSV'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await exportJson(context, entries);
                    },
                    icon: const Icon(Icons.data_object, size: 18),
                    label: const Text('JSON'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Exports [entries] as a CSV file via a save-file dialog.
  static Future<void> exportCsv(
    BuildContext context,
    List<AuditEntryResponse> entries,
  ) async {
    final csv = _buildCsv(entries);
    await _saveFile(
      context,
      content: csv,
      defaultName: 'vault-audit-log.csv',
      allowedExtensions: ['csv'],
    );
  }

  /// Exports [entries] as a JSON file via a save-file dialog.
  static Future<void> exportJson(
    BuildContext context,
    List<AuditEntryResponse> entries,
  ) async {
    final json = _buildJson(entries);
    await _saveFile(
      context,
      content: json,
      defaultName: 'vault-audit-log.json',
      allowedExtensions: ['json'],
    );
  }

  static String _buildCsv(List<AuditEntryResponse> entries) {
    final buf = StringBuffer();
    buf.writeln(
      'ID,Operation,Path,Resource Type,Resource ID,'
      'Success,Error,User ID,IP Address,Correlation ID,Timestamp',
    );
    for (final e in entries) {
      buf.writeln([
        e.id,
        _csvEscape(e.operation),
        _csvEscape(e.path ?? ''),
        _csvEscape(e.resourceType ?? ''),
        _csvEscape(e.resourceId ?? ''),
        e.success,
        _csvEscape(e.errorMessage ?? ''),
        _csvEscape(e.userId ?? ''),
        _csvEscape(e.ipAddress ?? ''),
        _csvEscape(e.correlationId ?? ''),
        formatDateTime(e.createdAt),
      ].join(','));
    }
    return buf.toString();
  }

  static String _buildJson(List<AuditEntryResponse> entries) {
    final list = entries
        .map((e) => {
              'id': e.id,
              'operation': e.operation,
              'path': e.path,
              'resourceType': e.resourceType,
              'resourceId': e.resourceId,
              'success': e.success,
              'errorMessage': e.errorMessage,
              'userId': e.userId,
              'ipAddress': e.ipAddress,
              'correlationId': e.correlationId,
              'createdAt': e.createdAt?.toIso8601String(),
            })
        .toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  static String _csvEscape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static Future<void> _saveFile(
    BuildContext context, {
    required String content,
    required String defaultName,
    required List<String> allowedExtensions,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Audit Log',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (path == null) return;

    await File(path).writeAsString(content);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to $path')),
    );
  }
}
