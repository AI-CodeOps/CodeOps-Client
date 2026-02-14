/// Export service for reports and findings.
///
/// Supports markdown, PDF, ZIP, and CSV export formats with
/// section selection and file save dialogs.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/agent_run.dart';
import '../../models/finding.dart';
import '../../models/qa_job.dart';
import '../../utils/constants.dart';

/// Controls which sections to include in an export.
class ExportSections {
  /// Include executive summary.
  final bool executiveSummary;

  /// Include agent reports.
  final bool agentReports;

  /// Include findings list.
  final bool findings;

  /// Include compliance matrix.
  final bool compliance;

  /// Include trend chart data.
  final bool trend;

  /// Creates [ExportSections] with all sections enabled by default.
  const ExportSections({
    this.executiveSummary = true,
    this.agentReports = true,
    this.findings = true,
    this.compliance = true,
    this.trend = true,
  });

  /// Creates [ExportSections] with all sections enabled.
  const ExportSections.all()
      : executiveSummary = true,
        agentReports = true,
        findings = true,
        compliance = true,
        trend = true;

  /// Creates a copy with modified fields.
  ExportSections copyWith({
    bool? executiveSummary,
    bool? agentReports,
    bool? findings,
    bool? compliance,
    bool? trend,
  }) =>
      ExportSections(
        executiveSummary: executiveSummary ?? this.executiveSummary,
        agentReports: agentReports ?? this.agentReports,
        findings: findings ?? this.findings,
        compliance: compliance ?? this.compliance,
        trend: trend ?? this.trend,
      );
}

/// Export format options.
enum ExportFormat {
  /// Markdown text format.
  markdown,

  /// PDF document format.
  pdf,

  /// ZIP archive containing all assets.
  zip,

  /// CSV spreadsheet for findings.
  csv,
}

/// Exports job reports and findings in various formats.
class ExportService {
  /// Creates an [ExportService].
  const ExportService();

  /// Exports a report as markdown.
  Future<String> exportAsMarkdown({
    required QaJob job,
    required List<AgentRun> agentRuns,
    required List<Finding> findings,
    required ExportSections sections,
    String? summaryMd,
  }) async {
    final buffer = StringBuffer();
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    buffer.writeln('# Job Report: ${job.name ?? job.mode.displayName}');
    buffer.writeln();
    buffer.writeln('**Project:** ${job.projectName ?? "N/A"}');
    buffer.writeln('**Branch:** ${job.branch ?? "N/A"}');
    buffer.writeln(
        '**Date:** ${job.completedAt != null ? dateFmt.format(job.completedAt!) : "N/A"}');
    buffer.writeln('**Health Score:** ${job.healthScore ?? "N/A"}');
    buffer.writeln(
        '**Result:** ${job.overallResult?.displayName ?? "N/A"}');
    buffer.writeln();

    if (sections.executiveSummary && summaryMd != null) {
      buffer.writeln('## Executive Summary');
      buffer.writeln();
      buffer.writeln(summaryMd);
      buffer.writeln();
    }

    if (sections.findings && findings.isNotEmpty) {
      buffer.writeln('## Findings (${findings.length})');
      buffer.writeln();
      buffer.writeln(
          '| Severity | Agent | Title | File | Status |');
      buffer.writeln(
          '|----------|-------|-------|------|--------|');
      for (final f in findings) {
        buffer.writeln(
          '| ${f.severity.displayName} '
          '| ${f.agentType.displayName} '
          '| ${f.title} '
          '| ${f.filePath ?? "N/A"} '
          '| ${f.status.displayName} |',
        );
      }
      buffer.writeln();
    }

    if (sections.agentReports && agentRuns.isNotEmpty) {
      buffer.writeln('## Agent Results');
      buffer.writeln();
      for (final run in agentRuns) {
        buffer.writeln(
          '- **${run.agentType.displayName}:** '
          '${run.result?.displayName ?? "N/A"} '
          '(Score: ${run.score ?? "N/A"}, '
          'Findings: ${run.findingsCount ?? 0})',
        );
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Exports a report as PDF.
  Future<List<int>> exportAsPdf({
    required QaJob job,
    required List<AgentRun> agentRuns,
    required List<Finding> findings,
    required ExportSections sections,
    String? summaryMd,
  }) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Title
          widgets.add(pw.Header(
            level: 0,
            text: 'Job Report: ${job.name ?? job.mode.displayName}',
          ));

          // Metadata
          widgets.add(pw.Paragraph(
            text: 'Project: ${job.projectName ?? "N/A"}\n'
                'Branch: ${job.branch ?? "N/A"}\n'
                'Date: ${job.completedAt != null ? dateFmt.format(job.completedAt!) : "N/A"}\n'
                'Health Score: ${job.healthScore ?? "N/A"}\n'
                'Result: ${job.overallResult?.displayName ?? "N/A"}',
          ));

          if (sections.executiveSummary && summaryMd != null) {
            widgets.add(pw.Header(level: 1, text: 'Executive Summary'));
            widgets.add(pw.Paragraph(text: summaryMd));
          }

          if (sections.findings && findings.isNotEmpty) {
            widgets.add(pw.Header(level: 1, text: 'Findings'));
            widgets.add(pw.TableHelper.fromTextArray(
              headers: ['Severity', 'Agent', 'Title', 'File', 'Status'],
              data: findings
                  .map((f) => [
                        f.severity.displayName,
                        f.agentType.displayName,
                        f.title,
                        f.filePath ?? 'N/A',
                        f.status.displayName,
                      ])
                  .toList(),
            ));
          }

          if (sections.agentReports && agentRuns.isNotEmpty) {
            widgets.add(pw.Header(level: 1, text: 'Agent Results'));
            for (final run in agentRuns) {
              widgets.add(pw.Bullet(
                text: '${run.agentType.displayName}: '
                    '${run.result?.displayName ?? "N/A"} '
                    '(Score: ${run.score ?? "N/A"}, '
                    'Findings: ${run.findingsCount ?? 0})',
              ));
            }
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  /// Exports all report data as a ZIP archive.
  Future<List<int>> exportAsZip({
    required QaJob job,
    required List<AgentRun> agentRuns,
    required List<Finding> findings,
    required ExportSections sections,
    String? summaryMd,
    Map<String, String>? agentReportContents,
  }) async {
    final archive = Archive();

    // Add markdown report
    final markdown = await exportAsMarkdown(
      job: job,
      agentRuns: agentRuns,
      findings: findings,
      sections: sections,
      summaryMd: summaryMd,
    );
    final mdBytes = utf8.encode(markdown);
    archive.addFile(ArchiveFile('report.md', mdBytes.length, mdBytes));

    // Add findings CSV
    if (sections.findings && findings.isNotEmpty) {
      final csv = exportFindingsAsCsv(findings);
      final csvBytes = utf8.encode(csv);
      archive.addFile(
          ArchiveFile('findings.csv', csvBytes.length, csvBytes));
    }

    // Add individual agent reports
    if (agentReportContents != null) {
      for (final entry in agentReportContents.entries) {
        final data = utf8.encode(entry.value);
        archive.addFile(ArchiveFile(
          'agents/${entry.key}.md',
          data.length,
          data,
        ));
      }
    }

    final encoded = ZipEncoder().encode(archive);
    return encoded;
  }

  /// Exports findings as a CSV string.
  String exportFindingsAsCsv(List<Finding> findings) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Severity,Agent,Title,File,Line,Status,Description,Recommendation',
    );
    for (final f in findings) {
      buffer.writeln(
        '${_csvEscape(f.id)},'
        '${_csvEscape(f.severity.displayName)},'
        '${_csvEscape(f.agentType.displayName)},'
        '${_csvEscape(f.title)},'
        '${_csvEscape(f.filePath ?? "")},'
        '${f.lineNumber ?? ""},'
        '${_csvEscape(f.status.displayName)},'
        '${_csvEscape(f.description ?? "")},'
        '${_csvEscape(f.recommendation ?? "")}',
      );
    }
    return buffer.toString();
  }

  /// Opens a file save dialog and writes data to the chosen path.
  ///
  /// Returns the saved file path or null if cancelled.
  Future<String?> saveFile({
    required String suggestedName,
    required List<int> data,
    String? dialogTitle,
    List<String>? allowedExtensions,
  }) async {
    final trimmedName = suggestedName.length > AppConstants.maxExportFilenameLength
        ? suggestedName.substring(0, AppConstants.maxExportFilenameLength)
        : suggestedName;

    final result = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle ?? 'Save Export',
      fileName: trimmedName,
      allowedExtensions: allowedExtensions,
      type: allowedExtensions != null ? FileType.custom : FileType.any,
    );

    if (result == null) return null;

    final file = File(result);
    await file.writeAsBytes(data);
    return result;
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
