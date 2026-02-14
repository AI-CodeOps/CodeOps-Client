// Tests for ReportParser markdown-to-structured-data parsing.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/services/agent/report_parser.dart';
import 'package:codeops/models/enums.dart';

/// A complete, well-formed markdown report used as the baseline fixture.
const _validReport = '''
# Security Agent Report

**Project:** Test Project
**Date:** 2024-01-15
**Agent:** Security
**Overall:** WARN
**Score:** 72

## Executive Summary

This project has some security concerns that need to be addressed.

## Findings

### [CRITICAL] SQL Injection Vulnerability

**File:** src/db/queries.dart
**Line:** 42
**Description:** Raw SQL string concatenation detected.
**Recommendation:** Use prepared statements.
**Effort:** S
**Evidence:** `String query = "SELECT * FROM users WHERE id = " + userId;`
**Ref:** CWE-89

### [HIGH] Hardcoded API Key

**File:** src/config/api.dart
**Line:** 15
**Description:** API key stored in source code.
**Recommendation:** Use environment variables or a secrets manager.
**Effort:** M
**Ref:** CWE-798

### [MEDIUM] Missing CSRF Token

**Description:** CSRF protection is not implemented.
**Recommendation:** Add CSRF middleware.
**Effort:** M
**Ref:** CWE-352

### [LOW] Debug Logging Enabled

**File:** src/main.dart
**Line:** 8
**Description:** Verbose debug logging left enabled.
**Recommendation:** Disable debug logging for production.
**Effort:** S
**Ref:** CWE-489

## Metrics

| Metric | Value |
|--------|-------|
| Files Reviewed | 42 |
| Total Findings | 4 |
| Critical | 1 |
| High | 1 |
| Medium | 1 |
| Low | 1 |
| Score | 72 |

## End
''';

void main() {
  late ReportParser parser;

  setUp(() {
    parser = const ReportParser();
  });

  // -----------------------------------------------------------------------
  // Full report parsing
  // -----------------------------------------------------------------------

  group('parseReport', () {
    test('parses a complete valid report with all sections', () {
      final report = parser.parseReport(_validReport);

      // Metadata
      expect(report.metadata.projectName, 'Test Project');
      expect(report.metadata.date, '2024-01-15');
      expect(report.metadata.agentType, 'Security');
      expect(report.metadata.overallResult, 'WARN');
      expect(report.metadata.score, 72);

      // Executive summary
      expect(report.executiveSummary, isNotNull);
      expect(
        report.executiveSummary,
        contains('security concerns'),
      );

      // Findings
      expect(report.findings, hasLength(4));

      // Metrics
      expect(report.metrics, isNotNull);
      expect(report.metrics!.filesReviewed, 42);
      expect(report.metrics!.totalFindings, 4);

      // Raw markdown preserved
      expect(report.rawMarkdown, _validReport);
    });
  });

  // -----------------------------------------------------------------------
  // Metadata
  // -----------------------------------------------------------------------

  group('parseMetadata', () {
    test('extracts all metadata fields', () {
      final metadata = parser.parseMetadata(_validReport);

      expect(metadata.projectName, 'Test Project');
      expect(metadata.date, '2024-01-15');
      expect(metadata.agentType, 'Security');
      expect(metadata.overallResult, 'WARN');
      expect(metadata.score, 72);
    });

    test('returns null fields when metadata is missing', () {
      const markdown = '# Report\n\nSome content without metadata fields.\n';
      final metadata = parser.parseMetadata(markdown);

      expect(metadata.projectName, isNull);
      expect(metadata.date, isNull);
      expect(metadata.agentType, isNull);
      expect(metadata.overallResult, isNull);
      expect(metadata.score, isNull);
    });

    test('handles partial metadata (only some fields present)', () {
      const markdown = '''
# Report

**Project:** My App
**Score:** 95
''';
      final metadata = parser.parseMetadata(markdown);

      expect(metadata.projectName, 'My App');
      expect(metadata.score, 95);
      expect(metadata.date, isNull);
      expect(metadata.agentType, isNull);
      expect(metadata.overallResult, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // Executive Summary
  // -----------------------------------------------------------------------

  group('parseExecutiveSummary', () {
    test('extracts the executive summary paragraph', () {
      final summary = parser.parseExecutiveSummary(_validReport);

      expect(summary, isNotNull);
      expect(
        summary,
        'This project has some security concerns that need to be addressed.',
      );
    });

    test('returns null when executive summary section is absent', () {
      const markdown = '''
# Report

**Project:** Test

## Findings

### [LOW] Minor issue

**Description:** Something small.
''';
      final summary = parser.parseExecutiveSummary(markdown);
      expect(summary, isNull);
    });

    test('returns null when executive summary section is empty', () {
      const markdown = '''
# Report

## Executive Summary

## Findings
''';
      final summary = parser.parseExecutiveSummary(markdown);
      expect(summary, isNull);
    });

    test('handles multi-line executive summary', () {
      const markdown = '''
# Report

## Executive Summary

First paragraph of the summary.

Second paragraph with more detail.

## Findings
''';
      final summary = parser.parseExecutiveSummary(markdown);

      expect(summary, isNotNull);
      expect(summary, contains('First paragraph'));
      expect(summary, contains('Second paragraph'));
    });
  });

  // -----------------------------------------------------------------------
  // Findings — severity levels
  // -----------------------------------------------------------------------

  group('parseFindings - severity levels', () {
    test('parses CRITICAL severity', () {
      final findings = parser.parseFindings(_validReport);
      final critical =
          findings.where((f) => f.severity == Severity.critical).toList();

      expect(critical, hasLength(1));
      expect(critical.first.title, 'SQL Injection Vulnerability');
    });

    test('parses HIGH severity', () {
      final findings = parser.parseFindings(_validReport);
      final high =
          findings.where((f) => f.severity == Severity.high).toList();

      expect(high, hasLength(1));
      expect(high.first.title, 'Hardcoded API Key');
    });

    test('parses MEDIUM severity', () {
      final findings = parser.parseFindings(_validReport);
      final medium =
          findings.where((f) => f.severity == Severity.medium).toList();

      expect(medium, hasLength(1));
      expect(medium.first.title, 'Missing CSRF Token');
    });

    test('parses LOW severity', () {
      final findings = parser.parseFindings(_validReport);
      final low =
          findings.where((f) => f.severity == Severity.low).toList();

      expect(low, hasLength(1));
      expect(low.first.title, 'Debug Logging Enabled');
    });

    test('handles case-insensitive severity tags', () {
      const markdown = '''
## Findings

### [critical] Lowercase Tag

**Description:** Test case insensitivity.

### [High] Mixed Case Tag

**Description:** Another test.

### [MEDIUM] Uppercase Tag

**Description:** Standard casing.

### [low] All Lowercase

**Description:** Last test.
''';
      final findings = parser.parseFindings(markdown);

      expect(findings, hasLength(4));
      expect(findings[0].severity, Severity.critical);
      expect(findings[0].title, 'Lowercase Tag');
      expect(findings[1].severity, Severity.high);
      expect(findings[1].title, 'Mixed Case Tag');
      expect(findings[2].severity, Severity.medium);
      expect(findings[3].severity, Severity.low);
    });
  });

  // -----------------------------------------------------------------------
  // Findings — field extraction
  // -----------------------------------------------------------------------

  group('parseFindings - field extraction', () {
    test('extracts all fields from a fully populated finding', () {
      final findings = parser.parseFindings(_validReport);
      final critical = findings.first;

      expect(critical.severity, Severity.critical);
      expect(critical.title, 'SQL Injection Vulnerability');
      expect(critical.filePath, 'src/db/queries.dart');
      expect(critical.lineNumber, 42);
      expect(critical.description, 'Raw SQL string concatenation detected.');
      expect(critical.recommendation, 'Use prepared statements.');
      expect(critical.effortEstimate, Effort.s);
      expect(critical.evidence, isNotNull);
      expect(critical.evidence,
          contains('SELECT * FROM users WHERE id ='));
    });

    test('handles finding with missing optional fields (no file/line)', () {
      final findings = parser.parseFindings(_validReport);
      // The MEDIUM finding has no File or Line fields
      final medium =
          findings.firstWhere((f) => f.severity == Severity.medium);

      expect(medium.title, 'Missing CSRF Token');
      expect(medium.filePath, isNull);
      expect(medium.lineNumber, isNull);
      expect(medium.description, 'CSRF protection is not implemented.');
      expect(medium.recommendation, 'Add CSRF middleware.');
    });

    test('handles finding with no evidence field', () {
      final findings = parser.parseFindings(_validReport);
      // The HIGH finding has no Evidence field
      final high = findings.firstWhere((f) => f.severity == Severity.high);

      expect(high.evidence, isNull);
      expect(high.filePath, 'src/config/api.dart');
      expect(high.lineNumber, 15);
    });

    test('agentType and debtCategory default to null from parser', () {
      final findings = parser.parseFindings(_validReport);

      for (final finding in findings) {
        expect(finding.agentType, isNull);
        expect(finding.debtCategory, isNull);
      }
    });
  });

  // -----------------------------------------------------------------------
  // Findings — multiple findings
  // -----------------------------------------------------------------------

  group('parseFindings - multiple findings', () {
    test('parses all four findings from the valid report', () {
      final findings = parser.parseFindings(_validReport);
      expect(findings, hasLength(4));
    });

    test('preserves finding order as they appear in the markdown', () {
      final findings = parser.parseFindings(_validReport);

      expect(findings[0].severity, Severity.critical);
      expect(findings[1].severity, Severity.high);
      expect(findings[2].severity, Severity.medium);
      expect(findings[3].severity, Severity.low);
    });

    test('parses a single finding correctly', () {
      const markdown = '''
## Findings

### [HIGH] Sole Finding

**Description:** The only finding in this report.
**Effort:** L
**Ref:** -

## End
''';
      final findings = parser.parseFindings(markdown);

      expect(findings, hasLength(1));
      expect(findings.first.title, 'Sole Finding');
      expect(findings.first.severity, Severity.high);
      expect(findings.first.effortEstimate, Effort.l);
    });
  });

  // -----------------------------------------------------------------------
  // Effort estimate parsing
  // -----------------------------------------------------------------------

  group('parseFindings - effort estimates', () {
    test('parses effort S', () {
      final findings = parser.parseFindings(_validReport);
      final critical = findings.first;
      expect(critical.effortEstimate, Effort.s);
    });

    test('parses effort M', () {
      final findings = parser.parseFindings(_validReport);
      final high = findings.firstWhere((f) => f.severity == Severity.high);
      expect(high.effortEstimate, Effort.m);
    });

    test('parses effort L', () {
      const markdown = '''
### [HIGH] Large Effort Finding

**Description:** Something big.
**Effort:** L
**Ref:** -

## End
''';
      final findings = parser.parseFindings(markdown);
      expect(findings.first.effortEstimate, Effort.l);
    });

    test('parses effort XL', () {
      const markdown = '''
### [HIGH] Extra Large Effort Finding

**Description:** Something huge.
**Effort:** XL
**Ref:** -

## End
''';
      final findings = parser.parseFindings(markdown);
      expect(findings.first.effortEstimate, Effort.xl);
    });

    test('returns null effort when field is missing', () {
      const markdown = '''
### [LOW] No Effort Specified

**Description:** Missing effort field.
''';
      final findings = parser.parseFindings(markdown);
      expect(findings.first.effortEstimate, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // Evidence extraction
  // -----------------------------------------------------------------------

  group('parseFindings - evidence extraction', () {
    test('extracts inline code evidence', () {
      final findings = parser.parseFindings(_validReport);
      final critical = findings.first;

      expect(critical.evidence, isNotNull);
      expect(
        critical.evidence,
        contains('SELECT * FROM users WHERE id ='),
      );
    });

    test('handles finding with no evidence', () {
      const markdown = '''
### [MEDIUM] No Evidence Finding

**Description:** No code sample provided.
**Recommendation:** Add tests.
''';
      final findings = parser.parseFindings(markdown);
      expect(findings.first.evidence, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // Metrics
  // -----------------------------------------------------------------------

  group('parseMetrics', () {
    test('extracts all metric values from the table', () {
      final metrics = parser.parseMetrics(_validReport);

      expect(metrics, isNotNull);
      expect(metrics!.filesReviewed, 42);
      expect(metrics.totalFindings, 4);
      expect(metrics.critical, 1);
      expect(metrics.high, 1);
      expect(metrics.medium, 1);
      expect(metrics.low, 1);
      expect(metrics.score, 72);
    });

    test('returns null when metrics section is absent', () {
      const markdown = '''
# Report

**Project:** Test

## Findings

### [LOW] Minor

**Description:** Small issue.
''';
      final metrics = parser.parseMetrics(markdown);
      expect(metrics, isNull);
    });

    test('handles partial metrics table (some rows missing)', () {
      const markdown = '''
## Metrics

| Metric | Value |
|--------|-------|
| Files Reviewed | 10 |
| Score | 88 |

## End
''';
      final metrics = parser.parseMetrics(markdown);

      expect(metrics, isNotNull);
      expect(metrics!.filesReviewed, 10);
      expect(metrics.score, 88);
      expect(metrics.totalFindings, isNull);
      expect(metrics.critical, isNull);
      expect(metrics.high, isNull);
      expect(metrics.medium, isNull);
      expect(metrics.low, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // Edge cases — empty and malformed input
  // -----------------------------------------------------------------------

  group('edge cases', () {
    test('handles empty string input', () {
      final report = parser.parseReport('');

      expect(report.metadata.projectName, isNull);
      expect(report.metadata.date, isNull);
      expect(report.metadata.agentType, isNull);
      expect(report.metadata.overallResult, isNull);
      expect(report.metadata.score, isNull);
      expect(report.executiveSummary, isNull);
      expect(report.findings, isEmpty);
      expect(report.metrics, isNull);
      expect(report.rawMarkdown, '');
    });

    test('handles markdown with no recognized sections', () {
      const markdown = '''
# Random Document

This is just some random markdown that does not follow the report format.

## Some Section

Unrelated content here.
''';
      final report = parser.parseReport(markdown);

      expect(report.metadata.projectName, isNull);
      expect(report.executiveSummary, isNull);
      expect(report.findings, isEmpty);
      expect(report.metrics, isNull);
    });

    test('handles report with only metadata (no findings, no metrics)', () {
      const markdown = '''
# Report

**Project:** Minimal Project
**Date:** 2024-06-01
**Agent:** Code Quality
**Overall:** PASS
**Score:** 100
''';
      final report = parser.parseReport(markdown);

      expect(report.metadata.projectName, 'Minimal Project');
      expect(report.metadata.date, '2024-06-01');
      expect(report.metadata.agentType, 'Code Quality');
      expect(report.metadata.overallResult, 'PASS');
      expect(report.metadata.score, 100);
      expect(report.executiveSummary, isNull);
      expect(report.findings, isEmpty);
      expect(report.metrics, isNull);
    });

    test('handles report with findings but no metrics', () {
      const markdown = '''
# Report

**Project:** Partial

## Findings

### [HIGH] Only Finding

**Description:** The one and only.
''';
      final report = parser.parseReport(markdown);

      expect(report.findings, hasLength(1));
      expect(report.metrics, isNull);
    });

    test('handles report with metrics but no findings', () {
      const markdown = '''
# Report

**Project:** Clean Project
**Score:** 100

## Metrics

| Metric | Value |
|--------|-------|
| Files Reviewed | 50 |
| Total Findings | 0 |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
| Score | 100 |

## End
''';
      final report = parser.parseReport(markdown);

      expect(report.findings, isEmpty);
      expect(report.metrics, isNotNull);
      expect(report.metrics!.totalFindings, 0);
      expect(report.metrics!.score, 100);
    });

    test('handles whitespace-only input', () {
      const markdown = '   \n\n  \t\n  ';
      final report = parser.parseReport(markdown);

      expect(report.findings, isEmpty);
      expect(report.metrics, isNull);
      expect(report.executiveSummary, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // ParsedFinding.withAgentType
  // -----------------------------------------------------------------------

  group('ParsedFinding.withAgentType', () {
    test('returns a copy with the specified agent type', () {
      final original = parser.parseFindings(_validReport).first;
      expect(original.agentType, isNull);

      final updated = original.withAgentType(AgentType.security);

      expect(updated.agentType, AgentType.security);
      // All other fields should remain unchanged
      expect(updated.severity, original.severity);
      expect(updated.title, original.title);
      expect(updated.filePath, original.filePath);
      expect(updated.lineNumber, original.lineNumber);
      expect(updated.description, original.description);
      expect(updated.recommendation, original.recommendation);
      expect(updated.effortEstimate, original.effortEstimate);
      expect(updated.evidence, original.evidence);
      expect(updated.debtCategory, original.debtCategory);
    });
  });

  // -----------------------------------------------------------------------
  // const instantiation
  // -----------------------------------------------------------------------

  group('ReportParser instantiation', () {
    test('can be created as a const instance', () {
      const p = ReportParser();
      expect(p, isA<ReportParser>());
    });
  });
}
