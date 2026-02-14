// Tests for VeraManager.
//
// Verifies consolidation, health score calculation, finding deduplication,
// overall result determination, and executive summary generation.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/agent/persona_manager.dart';
import 'package:codeops/services/agent/report_parser.dart';
import 'package:codeops/services/orchestration/agent_dispatcher.dart';
import 'package:codeops/services/orchestration/vera_manager.dart';

class MockPersonaManager extends Mock implements PersonaManager {}

class MockAgentDispatcher extends Mock implements AgentDispatcher {}

class MockReportParser extends Mock implements ReportParser {}

void main() {
  late MockPersonaManager mockPersonaManager;
  late MockAgentDispatcher mockAgentDispatcher;
  late MockReportParser mockReportParser;
  late VeraManager veraManager;

  setUp(() {
    mockPersonaManager = MockPersonaManager();
    mockAgentDispatcher = MockAgentDispatcher();
    mockReportParser = MockReportParser();
    veraManager = VeraManager(
      personaManager: mockPersonaManager,
      agentDispatcher: mockAgentDispatcher,
      reportParser: mockReportParser,
    );
  });

  // ---------------------------------------------------------------------------
  // Helper factories
  // ---------------------------------------------------------------------------

  ParsedFinding makeFinding({
    Severity severity = Severity.medium,
    String title = 'Test finding',
    String? filePath,
    int? lineNumber,
    String? description,
    AgentType? agentType,
  }) {
    return ParsedFinding(
      severity: severity,
      title: title,
      filePath: filePath,
      lineNumber: lineNumber,
      description: description,
      agentType: agentType,
    );
  }

  ParsedReport makeReport({
    List<ParsedFinding>? findings,
    int? score,
    String? projectName,
  }) {
    return ParsedReport(
      metadata: ReportMetadata(
        projectName: projectName ?? 'Test Project',
        score: score,
      ),
      findings: findings ?? [],
      metrics: score != null ? ReportMetrics(score: score) : null,
      rawMarkdown: '# Test Report',
    );
  }

  // ---------------------------------------------------------------------------
  // consolidate
  // ---------------------------------------------------------------------------

  group('consolidate', () {
    test('returns correct VeraReport with all fields', () async {
      final criticalFinding = makeFinding(
        severity: Severity.critical,
        title: 'SQL Injection',
        filePath: 'lib/db.dart',
        lineNumber: 42,
      );
      final highFinding = makeFinding(
        severity: Severity.high,
        title: 'Missing auth check',
        filePath: 'lib/auth.dart',
        lineNumber: 10,
      );
      final mediumFinding = makeFinding(
        severity: Severity.medium,
        title: 'Unused import',
        filePath: 'lib/utils.dart',
        lineNumber: 1,
      );
      final lowFinding = makeFinding(
        severity: Severity.low,
        title: 'TODO comment',
        filePath: 'lib/main.dart',
        lineNumber: 99,
      );

      final securityReport = makeReport(
        findings: [criticalFinding, highFinding],
        score: 40,
      );
      final codeQualityReport = makeReport(
        findings: [mediumFinding, lowFinding],
        score: 85,
      );

      final agentReports = <AgentType, ParsedReport>{
        AgentType.security: securityReport,
        AgentType.codeQuality: codeQualityReport,
      };

      final result = await veraManager.consolidate(
        jobId: 'job-123',
        projectName: 'My Project',
        agentReports: agentReports,
        mode: JobMode.audit,
      );

      expect(result, isA<VeraReport>());
      expect(result.criticalCount, 1);
      expect(result.highCount, 1);
      expect(result.mediumCount, 1);
      expect(result.lowCount, 1);
      expect(result.totalFindings, 4);
      expect(result.overallResult, JobResult.fail);
      expect(result.deduplicatedFindings, hasLength(4));
      expect(result.agentScores[AgentType.security], 40);
      expect(result.agentScores[AgentType.codeQuality], 85);
      expect(result.executiveSummaryMd, isNotEmpty);
      expect(result.healthScore, inInclusiveRange(0, 100));
    });
  });

  // ---------------------------------------------------------------------------
  // calculateHealthScore
  // ---------------------------------------------------------------------------

  group('calculateHealthScore', () {
    test('empty reports returns 100', () {
      final score =
          veraManager.calculateHealthScore(<AgentType, ParsedReport>{});

      expect(score, 100);
    });

    test('single agent score', () {
      final reports = <AgentType, ParsedReport>{
        AgentType.codeQuality: makeReport(score: 75),
      };

      final score = veraManager.calculateHealthScore(reports);

      expect(score, 75);
    });

    test('weighted scoring gives security 1.5x weight', () {
      // security score = 60, weight = 1.5
      // codeQuality score = 80, weight = 1.0
      // weighted average = (60 * 1.5 + 80 * 1.0) / (1.5 + 1.0)
      //                  = (90 + 80) / 2.5
      //                  = 170 / 2.5
      //                  = 68
      final reports = <AgentType, ParsedReport>{
        AgentType.security: makeReport(score: 60),
        AgentType.codeQuality: makeReport(score: 80),
      };

      final score = veraManager.calculateHealthScore(reports);

      expect(score, 68);
    });

    test('weighted scoring gives architecture 1.5x weight', () {
      // architecture score = 60, weight = 1.5
      // codeQuality score = 80, weight = 1.0
      // weighted average = (60 * 1.5 + 80 * 1.0) / (1.5 + 1.0) = 68
      final reports = <AgentType, ParsedReport>{
        AgentType.architecture: makeReport(score: 60),
        AgentType.codeQuality: makeReport(score: 80),
      };

      final score = veraManager.calculateHealthScore(reports);

      expect(score, 68);
    });

    test('handles null metrics gracefully by treating score as 0', () {
      // A report with no metrics means score defaults to 0.
      final reports = <AgentType, ParsedReport>{
        AgentType.codeQuality: ParsedReport(
          metadata: const ReportMetadata(),
          findings: [],
          metrics: null,
          rawMarkdown: '# Empty',
        ),
      };

      final score = veraManager.calculateHealthScore(reports);

      expect(score, 0);
    });

    test('multiple weighted agents produces correct average', () {
      // security = 80, weight 1.5 => 120
      // architecture = 60, weight 1.5 => 90
      // codeQuality = 90, weight 1.0 => 90
      // total weight = 4.0
      // average = 300 / 4.0 = 75
      final reports = <AgentType, ParsedReport>{
        AgentType.security: makeReport(score: 80),
        AgentType.architecture: makeReport(score: 60),
        AgentType.codeQuality: makeReport(score: 90),
      };

      final score = veraManager.calculateHealthScore(reports);

      expect(score, 75);
    });

    test('clamps score to 0-100 range', () {
      // Even with unusual inputs the result stays in bounds.
      final reports = <AgentType, ParsedReport>{
        AgentType.codeQuality: makeReport(score: 100),
      };

      final score = veraManager.calculateHealthScore(reports);

      expect(score, inInclusiveRange(0, 100));
    });
  });

  // ---------------------------------------------------------------------------
  // deduplicateFindings
  // ---------------------------------------------------------------------------

  group('deduplicateFindings', () {
    test('no duplicates keeps all findings', () {
      final findings = [
        makeFinding(
          severity: Severity.high,
          title: 'SQL Injection',
          filePath: 'lib/db.dart',
          lineNumber: 10,
        ),
        makeFinding(
          severity: Severity.medium,
          title: 'Unused import',
          filePath: 'lib/utils.dart',
          lineNumber: 1,
        ),
        makeFinding(
          severity: Severity.low,
          title: 'TODO comment',
          filePath: 'lib/main.dart',
          lineNumber: 50,
        ),
      ];

      final result = veraManager.deduplicateFindings(findings);

      expect(result, hasLength(3));
    });

    test('removes duplicates with same file, nearby line, similar title', () {
      final findings = [
        makeFinding(
          severity: Severity.high,
          title: 'SQL Injection vulnerability',
          filePath: 'lib/db.dart',
          lineNumber: 10,
        ),
        makeFinding(
          severity: Severity.medium,
          title: 'SQL Injection vulnerability',
          filePath: 'lib/db.dart',
          lineNumber: 12, // Within ±5 lines.
        ),
      ];

      final result = veraManager.deduplicateFindings(findings);

      expect(result, hasLength(1));
    });

    test('keeps higher severity when deduplicating', () {
      final findings = [
        makeFinding(
          severity: Severity.medium,
          title: 'Hardcoded secret',
          filePath: 'lib/config.dart',
          lineNumber: 20,
        ),
        makeFinding(
          severity: Severity.critical,
          title: 'Hardcoded secret',
          filePath: 'lib/config.dart',
          lineNumber: 22,
        ),
      ];

      final result = veraManager.deduplicateFindings(findings);

      expect(result, hasLength(1));
      expect(result.first.severity, Severity.critical);
    });

    test('different files are not considered duplicates', () {
      final findings = [
        makeFinding(
          severity: Severity.high,
          title: 'SQL Injection vulnerability',
          filePath: 'lib/db.dart',
          lineNumber: 10,
        ),
        makeFinding(
          severity: Severity.high,
          title: 'SQL Injection vulnerability',
          filePath: 'lib/other_db.dart',
          lineNumber: 10,
        ),
      ];

      final result = veraManager.deduplicateFindings(findings);

      expect(result, hasLength(2));
    });

    test('null filePath findings are not considered duplicates of each other',
        () {
      final findings = [
        makeFinding(
          severity: Severity.high,
          title: 'Missing HTTPS enforcement',
          filePath: null,
          lineNumber: null,
        ),
        makeFinding(
          severity: Severity.high,
          title: 'Missing HTTPS enforcement',
          filePath: null,
          lineNumber: null,
        ),
      ];

      final result = veraManager.deduplicateFindings(findings);

      expect(result, hasLength(2));
    });

    test('empty list returns empty', () {
      final result = veraManager.deduplicateFindings([]);

      expect(result, isEmpty);
    });

    test('result is sorted by severity descending', () {
      final findings = [
        makeFinding(severity: Severity.low, title: 'A', filePath: 'a.dart'),
        makeFinding(
            severity: Severity.critical, title: 'B', filePath: 'b.dart'),
        makeFinding(severity: Severity.medium, title: 'C', filePath: 'c.dart'),
        makeFinding(severity: Severity.high, title: 'D', filePath: 'd.dart'),
      ];

      final result = veraManager.deduplicateFindings(findings);

      expect(result[0].severity, Severity.critical);
      expect(result[1].severity, Severity.high);
      expect(result[2].severity, Severity.medium);
      expect(result[3].severity, Severity.low);
    });

    test('lines outside threshold are not duplicates', () {
      final findings = [
        makeFinding(
          severity: Severity.high,
          title: 'SQL Injection vulnerability',
          filePath: 'lib/db.dart',
          lineNumber: 10,
        ),
        makeFinding(
          severity: Severity.high,
          title: 'SQL Injection vulnerability',
          filePath: 'lib/db.dart',
          lineNumber: 20, // 10 lines apart, exceeds ±5 threshold.
        ),
      ];

      final result = veraManager.deduplicateFindings(findings);

      expect(result, hasLength(2));
    });

    test('dissimilar titles in same file and line are not duplicates', () {
      final findings = [
        makeFinding(
          severity: Severity.high,
          title: 'SQL Injection vulnerability',
          filePath: 'lib/db.dart',
          lineNumber: 10,
        ),
        makeFinding(
          severity: Severity.high,
          title: 'Missing error handling',
          filePath: 'lib/db.dart',
          lineNumber: 10,
        ),
      ];

      final result = veraManager.deduplicateFindings(findings);

      expect(result, hasLength(2));
    });
  });

  // ---------------------------------------------------------------------------
  // determineOverallResult
  // ---------------------------------------------------------------------------

  group('determineOverallResult', () {
    test('critical finding produces fail', () {
      final findings = [
        makeFinding(severity: Severity.critical, title: 'Critical issue'),
        makeFinding(severity: Severity.low, title: 'Minor issue'),
      ];

      final result = veraManager.determineOverallResult(findings);

      expect(result, JobResult.fail);
    });

    test('high finding without critical produces warn', () {
      final findings = [
        makeFinding(severity: Severity.high, title: 'High issue'),
        makeFinding(severity: Severity.medium, title: 'Medium issue'),
      ];

      final result = veraManager.determineOverallResult(findings);

      expect(result, JobResult.warn);
    });

    test('medium and low only produces pass', () {
      final findings = [
        makeFinding(severity: Severity.medium, title: 'Medium issue'),
        makeFinding(severity: Severity.low, title: 'Low issue'),
      ];

      final result = veraManager.determineOverallResult(findings);

      expect(result, JobResult.pass);
    });

    test('empty findings produces pass', () {
      final result = veraManager.determineOverallResult([]);

      expect(result, JobResult.pass);
    });

    test('only low findings produces pass', () {
      final findings = [
        makeFinding(severity: Severity.low, title: 'Low issue 1'),
        makeFinding(severity: Severity.low, title: 'Low issue 2'),
      ];

      final result = veraManager.determineOverallResult(findings);

      expect(result, JobResult.pass);
    });

    test('critical takes precedence over high', () {
      final findings = [
        makeFinding(severity: Severity.high, title: 'High issue'),
        makeFinding(severity: Severity.critical, title: 'Critical issue'),
      ];

      final result = veraManager.determineOverallResult(findings);

      expect(result, JobResult.fail);
    });
  });

  // ---------------------------------------------------------------------------
  // generateExecutiveSummary
  // ---------------------------------------------------------------------------

  group('generateExecutiveSummary', () {
    test('contains project name, health score, findings table, and agent scores',
        () async {
      final summary = await veraManager.generateExecutiveSummary(
        projectName: 'Acme Widget',
        mode: JobMode.audit,
        healthScore: 72,
        overallResult: JobResult.warn,
        totalFindings: 7,
        criticalCount: 1,
        highCount: 2,
        mediumCount: 3,
        lowCount: 1,
        agentScores: {
          AgentType.security: 55,
          AgentType.codeQuality: 88,
        },
      );

      // Project name.
      expect(summary, contains('Acme Widget'));

      // Health score.
      expect(summary, contains('72 / 100'));

      // Severity breakdown table.
      expect(summary, contains('| Critical | 1 |'));
      expect(summary, contains('| High | 2 |'));
      expect(summary, contains('| Medium | 3 |'));
      expect(summary, contains('| Low | 1 |'));
      expect(summary, contains('| **Total** | **7** |'));

      // Agent scores table.
      expect(summary, contains('| Security | 55 |'));
      expect(summary, contains('| Code Quality | 88 |'));

      // Overall result section.
      expect(summary, contains('Warning'));

      // Mode.
      expect(summary, contains('Audit'));
    });

    test('pass result includes pass interpretation', () async {
      final summary = await veraManager.generateExecutiveSummary(
        projectName: 'Good Project',
        mode: JobMode.audit,
        healthScore: 95,
        overallResult: JobResult.pass,
        totalFindings: 2,
        criticalCount: 0,
        highCount: 0,
        mediumCount: 1,
        lowCount: 1,
        agentScores: {},
      );

      expect(summary, contains('meets quality thresholds'));
    });

    test('fail result includes fail interpretation', () async {
      final summary = await veraManager.generateExecutiveSummary(
        projectName: 'Risky Project',
        mode: JobMode.compliance,
        healthScore: 30,
        overallResult: JobResult.fail,
        totalFindings: 10,
        criticalCount: 3,
        highCount: 4,
        mediumCount: 2,
        lowCount: 1,
        agentScores: {AgentType.security: 20},
      );

      expect(summary, contains('Critical issues were found'));
      expect(summary, contains('immediate attention'));
    });

    test('warn result includes warn interpretation', () async {
      final summary = await veraManager.generateExecutiveSummary(
        projectName: 'Caution Project',
        mode: JobMode.techDebt,
        healthScore: 65,
        overallResult: JobResult.warn,
        totalFindings: 5,
        criticalCount: 0,
        highCount: 2,
        mediumCount: 2,
        lowCount: 1,
        agentScores: {},
      );

      expect(summary, contains('High-severity issues were detected'));
      expect(summary, contains('prioritize remediation'));
    });

    test('empty agent scores omits agent scores section', () async {
      final summary = await veraManager.generateExecutiveSummary(
        projectName: 'Solo Project',
        mode: JobMode.audit,
        healthScore: 100,
        overallResult: JobResult.pass,
        totalFindings: 0,
        criticalCount: 0,
        highCount: 0,
        mediumCount: 0,
        lowCount: 0,
        agentScores: {},
      );

      expect(summary, isNot(contains('## Agent Scores')));
    });

    test('includes Vera attribution footer', () async {
      final summary = await veraManager.generateExecutiveSummary(
        projectName: 'Footer Test',
        mode: JobMode.audit,
        healthScore: 80,
        overallResult: JobResult.pass,
        totalFindings: 0,
        criticalCount: 0,
        highCount: 0,
        mediumCount: 0,
        lowCount: 0,
        agentScores: {},
      );

      expect(summary, contains('Vera consolidation engine'));
    });

    test('uses mode displayName in header', () async {
      final summary = await veraManager.generateExecutiveSummary(
        projectName: 'Mode Test',
        mode: JobMode.healthMonitor,
        healthScore: 90,
        overallResult: JobResult.pass,
        totalFindings: 0,
        criticalCount: 0,
        highCount: 0,
        mediumCount: 0,
        lowCount: 0,
        agentScores: {},
      );

      expect(summary, contains('Health Monitor'));
    });
  });
}
