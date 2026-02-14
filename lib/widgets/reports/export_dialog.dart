/// Export dialog widget.
///
/// Allows users to select export format, choose sections, and trigger
/// export via [ExportService].
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agent_run.dart';
import '../../models/finding.dart';
import '../../models/qa_job.dart';
import '../../services/integration/export_service.dart';
import '../../theme/colors.dart';
import '../shared/notification_toast.dart';

/// Shows the export dialog.
Future<void> showExportDialog({
  required BuildContext context,
  required QaJob job,
  required List<AgentRun> agentRuns,
  required List<Finding> findings,
  String? summaryMd,
}) {
  return showDialog(
    context: context,
    builder: (_) => _ExportDialogContent(
      job: job,
      agentRuns: agentRuns,
      findings: findings,
      summaryMd: summaryMd,
    ),
  );
}

class _ExportDialogContent extends ConsumerStatefulWidget {
  final QaJob job;
  final List<AgentRun> agentRuns;
  final List<Finding> findings;
  final String? summaryMd;

  const _ExportDialogContent({
    required this.job,
    required this.agentRuns,
    required this.findings,
    this.summaryMd,
  });

  @override
  ConsumerState<_ExportDialogContent> createState() =>
      _ExportDialogContentState();
}

class _ExportDialogContentState extends ConsumerState<_ExportDialogContent> {
  ExportFormat _format = ExportFormat.markdown;
  ExportSections _sections = const ExportSections.all();
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text(
        'Export Report',
        style: TextStyle(
          color: CodeOpsColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selector
            const Text(
              'Format',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ExportFormat.values.map((fmt) {
                final selected = _format == fmt;
                return ChoiceChip(
                  label: Text(_formatLabel(fmt)),
                  selected: selected,
                  selectedColor: CodeOpsColors.primary.withValues(alpha: 0.2),
                  backgroundColor: CodeOpsColors.surfaceVariant,
                  labelStyle: TextStyle(
                    color: selected
                        ? CodeOpsColors.primary
                        : CodeOpsColors.textSecondary,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected
                        ? CodeOpsColors.primary.withValues(alpha: 0.4)
                        : CodeOpsColors.border,
                  ),
                  onSelected: (_) => setState(() => _format = fmt),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Section checkboxes
            if (_format != ExportFormat.csv) ...[
              const Text(
                'Sections',
                style: TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _SectionCheckbox(
                label: 'Executive Summary',
                value: _sections.executiveSummary,
                onChanged: (v) => setState(() {
                  _sections =
                      _sections.copyWith(executiveSummary: v ?? true);
                }),
              ),
              _SectionCheckbox(
                label: 'Agent Reports',
                value: _sections.agentReports,
                onChanged: (v) => setState(() {
                  _sections = _sections.copyWith(agentReports: v ?? true);
                }),
              ),
              _SectionCheckbox(
                label: 'Findings',
                value: _sections.findings,
                onChanged: (v) => setState(() {
                  _sections = _sections.copyWith(findings: v ?? true);
                }),
              ),
              _SectionCheckbox(
                label: 'Compliance Matrix',
                value: _sections.compliance,
                onChanged: (v) => setState(() {
                  _sections = _sections.copyWith(compliance: v ?? true);
                }),
              ),
              _SectionCheckbox(
                label: 'Health Trend',
                value: _sections.trend,
                onChanged: (v) => setState(() {
                  _sections = _sections.copyWith(trend: v ?? true);
                }),
              ),
            ],

            if (_exporting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                color: CodeOpsColors.primary,
                backgroundColor: CodeOpsColors.surfaceVariant,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _exporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _exporting ? null : _export,
          style: FilledButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
          ),
          child: Text(_exporting ? 'Exporting...' : 'Export'),
        ),
      ],
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);

    try {
      const exportService = ExportService();
      final jobName =
          widget.job.name ?? widget.job.mode.displayName;

      switch (_format) {
        case ExportFormat.markdown:
          final content = await exportService.exportAsMarkdown(
            job: widget.job,
            agentRuns: widget.agentRuns,
            findings: widget.findings,
            sections: _sections,
            summaryMd: widget.summaryMd,
          );
          await exportService.saveFile(
            suggestedName: '$jobName-report.md',
            data: utf8.encode(content),
            allowedExtensions: ['md'],
          );
          break;

        case ExportFormat.pdf:
          final pdfBytes = await exportService.exportAsPdf(
            job: widget.job,
            agentRuns: widget.agentRuns,
            findings: widget.findings,
            sections: _sections,
            summaryMd: widget.summaryMd,
          );
          await exportService.saveFile(
            suggestedName: '$jobName-report.pdf',
            data: pdfBytes,
            allowedExtensions: ['pdf'],
          );
          break;

        case ExportFormat.zip:
          final zipBytes = await exportService.exportAsZip(
            job: widget.job,
            agentRuns: widget.agentRuns,
            findings: widget.findings,
            sections: _sections,
            summaryMd: widget.summaryMd,
          );
          await exportService.saveFile(
            suggestedName: '$jobName-report.zip',
            data: zipBytes,
            allowedExtensions: ['zip'],
          );
          break;

        case ExportFormat.csv:
          final csv =
              exportService.exportFindingsAsCsv(widget.findings);
          await exportService.saveFile(
            suggestedName: '$jobName-findings.csv',
            data: utf8.encode(csv),
            allowedExtensions: ['csv'],
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, message: 'Export complete', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        showToast(context,
            message: 'Export failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatLabel(ExportFormat fmt) {
    return switch (fmt) {
      ExportFormat.markdown => 'Markdown',
      ExportFormat.pdf => 'PDF',
      ExportFormat.zip => 'ZIP',
      ExportFormat.csv => 'CSV',
    };
  }
}

class _SectionCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _SectionCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: CodeOpsColors.primary,
              side: const BorderSide(color: CodeOpsColors.border),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
