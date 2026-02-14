/// Parses standardized markdown reports produced by QA agents into
/// structured data models.
///
/// The parser is tolerant of minor formatting variations typical of
/// AI-generated output — optional whitespace, missing fields, and
/// inconsistent casing are handled gracefully.
library;

import '../../models/enums.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// A fully parsed agent report.
class ParsedReport {
  /// Metadata extracted from the report header.
  final ReportMetadata metadata;

  /// Executive summary paragraph, if present.
  final String? executiveSummary;

  /// Individual findings parsed from the `## Findings` section.
  final List<ParsedFinding> findings;

  /// Aggregate metrics parsed from the `## Metrics` table.
  final ReportMetrics? metrics;

  /// The original unmodified markdown source.
  final String rawMarkdown;

  /// Creates a [ParsedReport].
  const ParsedReport({
    required this.metadata,
    this.executiveSummary,
    required this.findings,
    this.metrics,
    required this.rawMarkdown,
  });
}

/// Header-level metadata extracted from labeled fields at the top of the
/// report.
class ReportMetadata {
  /// Name of the project that was analyzed.
  final String? projectName;

  /// Date the report was generated (typically `YYYY-MM-DD`).
  final String? date;

  /// Agent type that produced the report (e.g. `"Security"`).
  final String? agentType;

  /// Overall result: `"PASS"`, `"WARN"`, or `"FAIL"`.
  final String? overallResult;

  /// Numeric quality score (0-100).
  final int? score;

  /// Creates a [ReportMetadata].
  const ReportMetadata({
    this.projectName,
    this.date,
    this.agentType,
    this.overallResult,
    this.score,
  });
}

/// A single finding extracted from a `### [SEVERITY] Title` block.
class ParsedFinding {
  /// Severity level of the finding.
  final Severity severity;

  /// Human-readable title.
  final String title;

  /// Source file path where the issue was found.
  final String? filePath;

  /// Line number within [filePath].
  final int? lineNumber;

  /// Detailed description of the issue.
  final String? description;

  /// Actionable recommendation to resolve the issue.
  final String? recommendation;

  /// Estimated effort to address the finding.
  final Effort? effortEstimate;

  /// Code snippet or log output demonstrating the issue.
  final String? evidence;

  /// The agent type that produced this finding.
  ///
  /// Set externally by the orchestrator after parsing, since the parser
  /// itself does not know which agent produced the report.
  final AgentType? agentType;

  /// Technical debt category for this finding.
  final DebtCategory? debtCategory;

  /// Creates a [ParsedFinding].
  const ParsedFinding({
    required this.severity,
    required this.title,
    this.filePath,
    this.lineNumber,
    this.description,
    this.recommendation,
    this.effortEstimate,
    this.evidence,
    this.agentType,
    this.debtCategory,
  });

  /// Returns a copy of this finding with [agentType] set.
  ParsedFinding withAgentType(AgentType type) => ParsedFinding(
        severity: severity,
        title: title,
        filePath: filePath,
        lineNumber: lineNumber,
        description: description,
        recommendation: recommendation,
        effortEstimate: effortEstimate,
        evidence: evidence,
        agentType: type,
        debtCategory: debtCategory,
      );
}

/// Aggregate metrics parsed from the `## Metrics` table.
class ReportMetrics {
  /// Number of files the agent reviewed.
  final int? filesReviewed;

  /// Total number of findings.
  final int? totalFindings;

  /// Count of critical-severity findings.
  final int? critical;

  /// Count of high-severity findings.
  final int? high;

  /// Count of medium-severity findings.
  final int? medium;

  /// Count of low-severity findings.
  final int? low;

  /// Numeric quality score (0-100).
  final int? score;

  /// Creates a [ReportMetrics].
  const ReportMetrics({
    this.filesReviewed,
    this.totalFindings,
    this.critical,
    this.high,
    this.medium,
    this.low,
    this.score,
  });
}

// ---------------------------------------------------------------------------
// ReportParser
// ---------------------------------------------------------------------------

/// Parses standardized markdown reports into [ParsedReport] instances.
///
/// The parser uses regex-based extraction and is intentionally tolerant of
/// AI-generated formatting variations: extra whitespace, inconsistent casing,
/// missing optional fields, and minor structural deviations are all handled.
class ReportParser {
  /// Creates a [ReportParser].
  const ReportParser();

  /// Parses a complete markdown report into a [ParsedReport].
  ///
  /// [markdown] is the raw report content as produced by a QA agent.
  /// Returns a fully populated [ParsedReport]; missing sections will have
  /// `null` or empty values rather than throwing.
  ParsedReport parseReport(String markdown) {
    return ParsedReport(
      metadata: parseMetadata(markdown),
      executiveSummary: parseExecutiveSummary(markdown),
      findings: parseFindings(markdown),
      metrics: parseMetrics(markdown),
      rawMarkdown: markdown,
    );
  }

  /// Extracts all findings from the `## Findings` section of [markdown].
  ///
  /// Each finding begins with a `### [SEVERITY] Title` heading and extends
  /// until the next level-2 or level-3 heading.
  List<ParsedFinding> parseFindings(String markdown) {
    // Match `### [SEVERITY] Title` headers, tolerating leading whitespace.
    final headingPattern = RegExp(
      r'###\s*\[(CRITICAL|HIGH|MEDIUM|LOW)\]\s*(.+)',
      caseSensitive: false,
    );

    final findings = <ParsedFinding>[];
    final matches = headingPattern.allMatches(markdown).toList();

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final severityStr = match.group(1)!.toUpperCase();
      final title = match.group(2)!.trim();

      // Extract the block between this heading and the next heading of equal
      // or higher level (## or ###).
      final blockStart = match.end;
      final blockEnd = (i + 1 < matches.length)
          ? matches[i + 1].start
          : _nextSectionStart(markdown, blockStart);
      final block = markdown.substring(blockStart, blockEnd);

      findings.add(ParsedFinding(
        severity: _parseSeverity(severityStr),
        title: title,
        filePath: _extractField(block, 'File'),
        lineNumber: _extractIntField(block, 'Line'),
        description: _extractField(block, 'Description'),
        recommendation: _extractField(block, 'Recommendation'),
        effortEstimate: _extractEffort(block),
        evidence: _extractField(block, 'Evidence'),
      ));
    }

    return findings;
  }

  /// Extracts metadata from labeled fields at the top of [markdown].
  ///
  /// Looks for `**Project:**`, `**Date:**`, `**Agent:**`, `**Overall:**`,
  /// and `**Score:**` fields.
  ReportMetadata parseMetadata(String markdown) {
    return ReportMetadata(
      projectName: _extractMetadataField(markdown, 'Project'),
      date: _extractMetadataField(markdown, 'Date'),
      agentType: _extractMetadataField(markdown, 'Agent'),
      overallResult: _extractMetadataField(markdown, 'Overall'),
      score: _extractMetadataIntField(markdown, 'Score'),
    );
  }

  /// Extracts the executive summary from the `## Executive Summary`
  /// section of [markdown].
  ///
  /// Returns `null` if the section is not found.
  String? parseExecutiveSummary(String markdown) {
    final pattern = RegExp(
      r'##\s*Executive\s+Summary\s*\n([\s\S]*?)(?=\n##\s|\Z)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(markdown);
    if (match == null) return null;
    final content = match.group(1)!.trim();
    return content.isNotEmpty ? content : null;
  }

  /// Extracts aggregate metrics from the `## Metrics` section of [markdown].
  ///
  /// The metrics section is expected to contain a markdown table with
  /// `| Metric | Value |` rows.
  ///
  /// Returns `null` if the section is not found.
  ReportMetrics? parseMetrics(String markdown) {
    final sectionPattern = RegExp(
      r'##\s*Metrics\s*\n([\s\S]*?)(?=\n##\s|\Z)',
      caseSensitive: false,
    );
    final sectionMatch = sectionPattern.firstMatch(markdown);
    if (sectionMatch == null) return null;

    final section = sectionMatch.group(1)!;

    return ReportMetrics(
      filesReviewed: _extractTableInt(section, 'Files Reviewed'),
      totalFindings: _extractTableInt(section, 'Total Findings'),
      critical: _extractTableInt(section, 'Critical'),
      high: _extractTableInt(section, 'High'),
      medium: _extractTableInt(section, 'Medium'),
      low: _extractTableInt(section, 'Low'),
      score: _extractTableInt(section, 'Score'),
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Returns the start index of the next level-2 section heading (`## `)
  /// after [fromIndex], or the end of [markdown] if none is found.
  int _nextSectionStart(String markdown, int fromIndex) {
    final pattern = RegExp(r'\n##\s');
    final match = pattern.firstMatch(markdown.substring(fromIndex));
    if (match == null) return markdown.length;
    return fromIndex + match.start;
  }

  /// Extracts a labeled field value from a finding block.
  ///
  /// Matches patterns like `**File:** some/path.dart` and
  /// `**Description:** Multi-word value that continues to end of line.`
  /// Also handles multi-line values that continue on the next line without
  /// a new bold field.
  String? _extractField(String block, String fieldName) {
    final pattern = RegExp(
      r'\*\*' + RegExp.escape(fieldName) + r':\*\*\s*([\s\S]*?)(?=\n\s*\*\*\w+:\*\*|\n\s*###|\n\s*##|\Z)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(block);
    if (match == null) return null;
    final value = match.group(1)!.trim();
    return value.isNotEmpty ? value : null;
  }

  /// Extracts an integer-valued labeled field from a finding block.
  int? _extractIntField(String block, String fieldName) {
    final raw = _extractField(block, fieldName);
    if (raw == null) return null;
    return int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
  }

  /// Extracts the `**Effort:**` field and parses it as an [Effort] enum.
  Effort? _extractEffort(String block) {
    final raw = _extractField(block, 'Effort');
    if (raw == null) return null;
    final normalized = raw.trim().toUpperCase();
    try {
      return Effort.fromJson(normalized);
    } catch (_) {
      // Handle descriptive labels: "Small" -> S, "Medium" -> M, etc.
      return switch (normalized) {
        'SMALL' => Effort.s,
        'MEDIUM' => Effort.m,
        'LARGE' => Effort.l,
        'EXTRA LARGE' || 'EXTRA-LARGE' || 'EXTRALARGE' => Effort.xl,
        _ => null,
      };
    }
  }

  /// Extracts a metadata field value from the report header.
  ///
  /// Matches `**FieldName:** value` at the beginning of lines.
  String? _extractMetadataField(String markdown, String fieldName) {
    final pattern = RegExp(
      r'\*\*' + RegExp.escape(fieldName) + r':\*\*\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(markdown);
    if (match == null) return null;
    final value = match.group(1)!.trim();
    return value.isNotEmpty ? value : null;
  }

  /// Extracts an integer metadata field value.
  int? _extractMetadataIntField(String markdown, String fieldName) {
    final raw = _extractMetadataField(markdown, fieldName);
    if (raw == null) return null;
    return int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
  }

  /// Extracts an integer value from a markdown table row.
  ///
  /// Matches rows like `| Files Reviewed | 42 |` with tolerance for
  /// extra whitespace and case differences.
  int? _extractTableInt(String tableSection, String metricName) {
    final pattern = RegExp(
      r'\|\s*' + RegExp.escape(metricName) + r'\s*\|\s*(\d+)\s*\|',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(tableSection);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Maps a severity string to the [Severity] enum.
  Severity _parseSeverity(String value) => switch (value.toUpperCase()) {
        'CRITICAL' => Severity.critical,
        'HIGH' => Severity.high,
        'MEDIUM' => Severity.medium,
        'LOW' => Severity.low,
        _ => Severity.medium,
      };
}
