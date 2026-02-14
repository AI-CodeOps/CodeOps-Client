// Tests for ExportService.
//
// Verifies markdown export, CSV export, and ExportSections copyWith.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_run.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/models/finding.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/services/integration/export_service.dart';

void main() {
  late ExportService exportService;

  final testJob = QaJob(
    id: 'job-1',
    projectId: 'proj-1',
    projectName: 'Test Project',
    mode: JobMode.audit,
    status: JobStatus.completed,
    name: 'Security Audit',
    branch: 'main',
    overallResult: JobResult.warn,
    healthScore: 72,
    completedAt: DateTime.utc(2024, 6, 15, 14, 30),
  );

  final testAgentRuns = [
    const AgentRun(
      id: 'run-1',
      jobId: 'job-1',
      agentType: AgentType.security,
      status: AgentStatus.completed,
      result: AgentResult.warn,
      score: 72,
      findingsCount: 3,
    ),
    const AgentRun(
      id: 'run-2',
      jobId: 'job-1',
      agentType: AgentType.codeQuality,
      status: AgentStatus.completed,
      result: AgentResult.pass,
      score: 90,
      findingsCount: 1,
    ),
  ];

  final testFindings = [
    const Finding(
      id: 'f1',
      jobId: 'job-1',
      agentType: AgentType.security,
      severity: Severity.critical,
      title: 'SQL Injection',
      description: 'Raw SQL concatenation',
      filePath: 'src/db/queries.dart',
      lineNumber: 42,
      recommendation: 'Use prepared statements',
      status: FindingStatus.open,
    ),
    const Finding(
      id: 'f2',
      jobId: 'job-1',
      agentType: AgentType.security,
      severity: Severity.high,
      title: 'Hardcoded API Key',
      description: 'API key in source code',
      filePath: 'src/config/api.dart',
      lineNumber: 15,
      recommendation: 'Use environment variables',
      status: FindingStatus.open,
    ),
    const Finding(
      id: 'f3',
      jobId: 'job-1',
      agentType: AgentType.codeQuality,
      severity: Severity.medium,
      title: 'Unused Import',
      filePath: 'src/utils.dart',
      lineNumber: 3,
      status: FindingStatus.acknowledged,
    ),
  ];

  setUp(() {
    exportService = const ExportService();
  });

  group('ExportService', () {
    // ---------------------------------------------------------------------
    // exportAsMarkdown
    // ---------------------------------------------------------------------

    group('exportAsMarkdown', () {
      test('contains job name in title', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('# Job Report: Security Audit'));
      });

      test('contains project name', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('**Project:** Test Project'));
      });

      test('contains branch name', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('**Branch:** main'));
      });

      test('contains health score', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('**Health Score:** 72'));
      });

      test('contains overall result', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('Warning'));
      });

      test('includes findings table with all findings', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('## Findings (3)'));
        expect(markdown, contains('SQL Injection'));
        expect(markdown, contains('Hardcoded API Key'));
        expect(markdown, contains('Unused Import'));
      });

      test('includes findings table headers', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('| Severity | Agent | Title | File | Status |'));
      });

      test('includes agent results section', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('## Agent Results'));
        expect(markdown, contains('Security'));
        expect(markdown, contains('Code Quality'));
      });

      test('includes executive summary when provided', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
          summaryMd: 'This audit found several security concerns.',
        );

        expect(markdown, contains('## Executive Summary'));
        expect(
            markdown, contains('This audit found several security concerns.'));
      });

      test('omits executive summary when not provided', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, isNot(contains('## Executive Summary')));
      });

      test('omits executive summary when section disabled', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections(executiveSummary: false),
          summaryMd: 'This should not appear.',
        );

        expect(markdown, isNot(contains('## Executive Summary')));
        expect(markdown, isNot(contains('This should not appear.')));
      });

      test('omits findings section when disabled', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections(findings: false),
        );

        expect(markdown, isNot(contains('## Findings')));
      });

      test('omits agent reports section when disabled', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: testFindings,
          sections: const ExportSections(agentReports: false),
        );

        expect(markdown, isNot(contains('## Agent Results')));
      });

      test('handles empty findings list', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: testAgentRuns,
          findings: [],
          sections: const ExportSections.all(),
        );

        expect(markdown, isNot(contains('## Findings')));
      });

      test('handles empty agent runs list', () async {
        final markdown = await exportService.exportAsMarkdown(
          job: testJob,
          agentRuns: [],
          findings: testFindings,
          sections: const ExportSections.all(),
        );

        expect(markdown, isNot(contains('## Agent Results')));
      });

      test('falls back to job mode when name is null', () async {
        final jobNoName = QaJob(
          id: 'job-2',
          projectId: 'proj-1',
          mode: JobMode.audit,
          status: JobStatus.completed,
        );

        final markdown = await exportService.exportAsMarkdown(
          job: jobNoName,
          agentRuns: [],
          findings: [],
          sections: const ExportSections.all(),
        );

        expect(markdown, contains('# Job Report: Audit'));
      });
    });

    // ---------------------------------------------------------------------
    // exportFindingsAsCsv
    // ---------------------------------------------------------------------

    group('exportFindingsAsCsv', () {
      test('contains CSV header row', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains(
          'ID,Severity,Agent,Title,File,Line,Status,Description,Recommendation',
        ));
      });

      test('contains data rows for each finding', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains('f1'));
        expect(csv, contains('f2'));
        expect(csv, contains('f3'));
      });

      test('includes severity display names', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains('Critical'));
        expect(csv, contains('High'));
        expect(csv, contains('Medium'));
      });

      test('includes agent type display names', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains('Security'));
        expect(csv, contains('Code Quality'));
      });

      test('includes finding titles', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains('SQL Injection'));
        expect(csv, contains('Hardcoded API Key'));
        expect(csv, contains('Unused Import'));
      });

      test('includes file paths', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains('src/db/queries.dart'));
        expect(csv, contains('src/config/api.dart'));
        expect(csv, contains('src/utils.dart'));
      });

      test('includes line numbers', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains('42'));
        expect(csv, contains('15'));
        expect(csv, contains('3'));
      });

      test('includes status display names', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains('Open'));
        expect(csv, contains('Acknowledged'));
      });

      test('includes descriptions and recommendations', () {
        final csv = exportService.exportFindingsAsCsv(testFindings);

        expect(csv, contains('Raw SQL concatenation'));
        expect(csv, contains('Use prepared statements'));
      });

      test('handles empty findings list', () {
        final csv = exportService.exportFindingsAsCsv([]);

        // Should still have the header row
        expect(csv, contains('ID,Severity'));
        // Should be only the header line
        final lines =
            csv.trim().split('\n').where((l) => l.isNotEmpty).toList();
        expect(lines, hasLength(1));
      });

      test('escapes values containing commas', () {
        final findingWithComma = const Finding(
          id: 'f-comma',
          jobId: 'job-1',
          agentType: AgentType.security,
          severity: Severity.high,
          title: 'Injection, XSS',
          status: FindingStatus.open,
        );

        final csv = exportService.exportFindingsAsCsv([findingWithComma]);

        // Title with comma should be quoted
        expect(csv, contains('"Injection, XSS"'));
      });

      test('escapes values containing double quotes', () {
        final findingWithQuotes = const Finding(
          id: 'f-quote',
          jobId: 'job-1',
          agentType: AgentType.security,
          severity: Severity.high,
          title: 'Uses "eval" function',
          status: FindingStatus.open,
        );

        final csv = exportService.exportFindingsAsCsv([findingWithQuotes]);

        // Quotes should be escaped
        expect(csv, contains('""eval""'));
      });
    });

    // ---------------------------------------------------------------------
    // ExportSections
    // ---------------------------------------------------------------------

    group('ExportSections', () {
      test('default constructor enables all sections', () {
        const sections = ExportSections();

        expect(sections.executiveSummary, true);
        expect(sections.agentReports, true);
        expect(sections.findings, true);
        expect(sections.compliance, true);
        expect(sections.trend, true);
      });

      test('all() constructor enables all sections', () {
        const sections = ExportSections.all();

        expect(sections.executiveSummary, true);
        expect(sections.agentReports, true);
        expect(sections.findings, true);
        expect(sections.compliance, true);
        expect(sections.trend, true);
      });

      test('copyWith modifies specified fields only', () {
        const original = ExportSections();
        final modified = original.copyWith(
          executiveSummary: false,
          findings: false,
        );

        expect(modified.executiveSummary, false);
        expect(modified.findings, false);
        expect(modified.agentReports, true);
        expect(modified.compliance, true);
        expect(modified.trend, true);
      });

      test('copyWith preserves all fields when none specified', () {
        const original = ExportSections(
          executiveSummary: false,
          agentReports: false,
          findings: false,
          compliance: false,
          trend: false,
        );
        final copy = original.copyWith();

        expect(copy.executiveSummary, false);
        expect(copy.agentReports, false);
        expect(copy.findings, false);
        expect(copy.compliance, false);
        expect(copy.trend, false);
      });

      test('copyWith can enable individual sections', () {
        const allDisabled = ExportSections(
          executiveSummary: false,
          agentReports: false,
          findings: false,
          compliance: false,
          trend: false,
        );

        final withFindings = allDisabled.copyWith(findings: true);

        expect(withFindings.findings, true);
        expect(withFindings.executiveSummary, false);
        expect(withFindings.agentReports, false);
        expect(withFindings.compliance, false);
        expect(withFindings.trend, false);
      });

      test('constructor allows selective section enabling', () {
        const sections = ExportSections(
          executiveSummary: true,
          agentReports: false,
          findings: true,
          compliance: false,
          trend: false,
        );

        expect(sections.executiveSummary, true);
        expect(sections.agentReports, false);
        expect(sections.findings, true);
        expect(sections.compliance, false);
        expect(sections.trend, false);
      });
    });

    // ---------------------------------------------------------------------
    // ExportService instantiation
    // ---------------------------------------------------------------------

    group('ExportService instantiation', () {
      test('can be created as a const instance', () {
        const service = ExportService();
        expect(service, isA<ExportService>());
      });
    });
  });
}
