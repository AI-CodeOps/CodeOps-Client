/// Vera consolidation engine for multi-agent QA reports.
///
/// Collects findings from all agent [ParsedReport]s, deduplicates them,
/// computes a weighted health score, determines the overall job result,
/// and generates a Markdown executive summary. The name "Vera" is the
/// CodeOps consolidation persona that synthesizes agent outputs into a
/// single unified report.
library;

import 'dart:math' as math;

import '../../models/enums.dart';
import '../../utils/constants.dart';
import '../agent/persona_manager.dart';
import '../agent/report_parser.dart';
import 'agent_dispatcher.dart';

// ---------------------------------------------------------------------------
// VeraReport
// ---------------------------------------------------------------------------

/// The consolidated output of a Vera analysis across all agent reports.
class VeraReport {
  /// Weighted health score (0-100) across all agents.
  final int healthScore;

  /// Overall job result derived from the highest-severity finding.
  final JobResult overallResult;

  /// Markdown executive summary suitable for display and server upload.
  final String executiveSummaryMd;

  /// Findings after cross-agent deduplication, sorted by severity.
  final List<ParsedFinding> deduplicatedFindings;

  /// Total number of deduplicated findings.
  final int totalFindings;

  /// Count of findings with [Severity.critical].
  final int criticalCount;

  /// Count of findings with [Severity.high].
  final int highCount;

  /// Count of findings with [Severity.medium].
  final int mediumCount;

  /// Count of findings with [Severity.low].
  final int lowCount;

  /// Per-agent scores keyed by [AgentType].
  final Map<AgentType, int> agentScores;

  /// Creates a [VeraReport].
  const VeraReport({
    required this.healthScore,
    required this.overallResult,
    required this.executiveSummaryMd,
    required this.deduplicatedFindings,
    required this.totalFindings,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.agentScores,
  });
}

// ---------------------------------------------------------------------------
// VeraManager
// ---------------------------------------------------------------------------

/// Consolidates multi-agent QA results into a single [VeraReport].
///
/// Depends on [PersonaManager] for prompt context, [AgentDispatcher] for
/// potential follow-up dispatches, and [ReportParser] for structural access
/// to parsed agent outputs.
class VeraManager {
  final PersonaManager _personaManager;
  final AgentDispatcher _agentDispatcher;
  final ReportParser _reportParser;

  /// Creates a [VeraManager].
  VeraManager({
    required PersonaManager personaManager,
    required AgentDispatcher agentDispatcher,
    required ReportParser reportParser,
  })  : _personaManager = personaManager,
        _agentDispatcher = agentDispatcher,
        _reportParser = reportParser;

  /// Consolidates all agent reports into a single [VeraReport].
  ///
  /// Collects findings from every [ParsedReport], deduplicates them,
  /// calculates the weighted health score, determines the overall result,
  /// and generates a Markdown executive summary.
  ///
  /// [jobId] is the UUID of the job being consolidated.
  /// [projectName] is the human-readable project name for the summary.
  /// [agentReports] maps each agent type to its parsed report.
  /// [mode] is the job mode for summary context.
  Future<VeraReport> consolidate({
    required String jobId,
    required String projectName,
    required Map<AgentType, ParsedReport> agentReports,
    required JobMode mode,
  }) async {
    // Collect all findings across agents.
    final allFindings = <ParsedFinding>[];
    for (final report in agentReports.values) {
      allFindings.addAll(report.findings);
    }

    // Deduplicate.
    final deduplicated = deduplicateFindings(allFindings);

    // Severity counts.
    final criticalCount =
        deduplicated.where((f) => f.severity == Severity.critical).length;
    final highCount =
        deduplicated.where((f) => f.severity == Severity.high).length;
    final mediumCount =
        deduplicated.where((f) => f.severity == Severity.medium).length;
    final lowCount =
        deduplicated.where((f) => f.severity == Severity.low).length;

    // Per-agent scores.
    final agentScores = <AgentType, int>{};
    for (final entry in agentReports.entries) {
      agentScores[entry.key] = entry.value.metrics?.score ?? 0;
    }

    // Weighted health score.
    final healthScore = calculateHealthScore(agentReports);

    // Overall result.
    final overallResult = determineOverallResult(deduplicated);

    // Executive summary.
    final summaryMd = await generateExecutiveSummary(
      projectName: projectName,
      mode: mode,
      healthScore: healthScore,
      overallResult: overallResult,
      totalFindings: deduplicated.length,
      criticalCount: criticalCount,
      highCount: highCount,
      mediumCount: mediumCount,
      lowCount: lowCount,
      agentScores: agentScores,
    );

    return VeraReport(
      healthScore: healthScore,
      overallResult: overallResult,
      executiveSummaryMd: summaryMd,
      deduplicatedFindings: deduplicated,
      totalFindings: deduplicated.length,
      criticalCount: criticalCount,
      highCount: highCount,
      mediumCount: mediumCount,
      lowCount: lowCount,
      agentScores: agentScores,
    );
  }

  /// Computes the weighted health score from per-agent report scores.
  ///
  /// Security and Architecture agents receive a weight of
  /// [AppConstants.securityAgentWeight] and
  /// [AppConstants.architectureAgentWeight] respectively. All other agents
  /// receive [AppConstants.defaultAgentWeight]. The result is a weighted
  /// average clamped to the 0-100 range.
  int calculateHealthScore(Map<AgentType, ParsedReport> reports) {
    if (reports.isEmpty) return 100;

    double weightedSum = 0;
    double totalWeight = 0;

    for (final entry in reports.entries) {
      final weight = _agentWeight(entry.key);
      final score = entry.value.metrics?.score ?? 0;
      weightedSum += score * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return 100;
    final raw = weightedSum / totalWeight;
    return raw.round().clamp(0, 100);
  }

  /// Removes duplicate findings across agents.
  ///
  /// Two findings are considered duplicates when all of the following hold:
  /// - They share the same [ParsedFinding.filePath] (both non-null).
  /// - Their line numbers are within +/- [AppConstants.deduplicationLineThreshold].
  /// - Their titles have a Levenshtein similarity ratio >=
  ///   [AppConstants.deduplicationTitleSimilarityThreshold].
  ///
  /// When duplicates are found, the finding with the higher severity is kept.
  /// The returned list is sorted by severity descending (critical first).
  List<ParsedFinding> deduplicateFindings(List<ParsedFinding> allFindings) {
    if (allFindings.isEmpty) return [];

    // Sort by severity descending so the higher-severity duplicate is encountered first.
    final sorted = List<ParsedFinding>.from(allFindings)
      ..sort((a, b) => _severityRank(b.severity) - _severityRank(a.severity));

    final kept = <ParsedFinding>[];

    for (final finding in sorted) {
      final isDuplicate = kept.any((existing) => _isDuplicate(existing, finding));
      if (!isDuplicate) {
        kept.add(finding);
      }
    }

    return kept;
  }

  /// Determines the overall job result from the consolidated findings.
  ///
  /// Returns [JobResult.fail] if any finding has [Severity.critical],
  /// [JobResult.warn] if any finding has [Severity.high], and
  /// [JobResult.pass] otherwise.
  JobResult determineOverallResult(List<ParsedFinding> findings) {
    if (findings.any((f) => f.severity == Severity.critical)) {
      return JobResult.fail;
    }
    if (findings.any((f) => f.severity == Severity.high)) {
      return JobResult.warn;
    }
    return JobResult.pass;
  }

  /// Generates a Markdown executive summary from consolidated metrics.
  ///
  /// The summary is assembled from a template and does not invoke Claude.
  /// It includes the health score, overall result, severity breakdown,
  /// and per-agent score table.
  Future<String> generateExecutiveSummary({
    required String projectName,
    required JobMode mode,
    required int healthScore,
    required JobResult overallResult,
    required int totalFindings,
    required int criticalCount,
    required int highCount,
    required int mediumCount,
    required int lowCount,
    required Map<AgentType, int> agentScores,
  }) async {
    final buffer = StringBuffer();

    buffer.writeln('# CodeOps ${mode.displayName} Report');
    buffer.writeln();
    buffer.writeln('**Project:** $projectName');
    buffer.writeln('**Mode:** ${mode.displayName}');
    buffer.writeln('**Health Score:** $healthScore / 100');
    buffer.writeln('**Overall Result:** ${overallResult.displayName}');
    buffer.writeln();

    // Severity breakdown.
    buffer.writeln('## Findings Summary');
    buffer.writeln();
    buffer.writeln('| Severity | Count |');
    buffer.writeln('|----------|-------|');
    buffer.writeln('| Critical | $criticalCount |');
    buffer.writeln('| High | $highCount |');
    buffer.writeln('| Medium | $mediumCount |');
    buffer.writeln('| Low | $lowCount |');
    buffer.writeln('| **Total** | **$totalFindings** |');
    buffer.writeln();

    // Per-agent scores.
    if (agentScores.isNotEmpty) {
      buffer.writeln('## Agent Scores');
      buffer.writeln();
      buffer.writeln('| Agent | Score |');
      buffer.writeln('|-------|-------|');
      for (final entry in agentScores.entries) {
        buffer.writeln('| ${entry.key.displayName} | ${entry.value} |');
      }
      buffer.writeln();
    }

    // Result interpretation.
    buffer.writeln('## Result');
    buffer.writeln();
    switch (overallResult) {
      case JobResult.pass:
        buffer.writeln(
          'No critical or high-severity issues were found. '
          'The project meets quality thresholds.',
        );
      case JobResult.warn:
        buffer.writeln(
          'High-severity issues were detected that should be addressed. '
          'Review the findings above and prioritize remediation.',
        );
      case JobResult.fail:
        buffer.writeln(
          'Critical issues were found that require immediate attention. '
          'These issues pose significant risk and should be resolved '
          'before proceeding.',
        );
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('*Generated by CodeOps Vera consolidation engine.*');

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the weight multiplier for a given [AgentType].
  double _agentWeight(AgentType agentType) => switch (agentType) {
        AgentType.security => AppConstants.securityAgentWeight,
        AgentType.architecture => AppConstants.architectureAgentWeight,
        _ => AppConstants.defaultAgentWeight,
      };

  /// Returns a numeric rank for severity ordering (higher = more severe).
  static int _severityRank(Severity severity) => switch (severity) {
        Severity.critical => 4,
        Severity.high => 3,
        Severity.medium => 2,
        Severity.low => 1,
      };

  /// Returns `true` if two findings are considered duplicates.
  bool _isDuplicate(ParsedFinding a, ParsedFinding b) {
    // Both must have a file path to be considered duplicates.
    if (a.filePath == null || b.filePath == null) return false;
    if (a.filePath != b.filePath) return false;

    // Line numbers must be within the deduplication threshold.
    if (a.lineNumber != null && b.lineNumber != null) {
      final lineDelta = (a.lineNumber! - b.lineNumber!).abs();
      if (lineDelta > AppConstants.deduplicationLineThreshold) return false;
    }

    // Title similarity must meet the threshold.
    final similarity = _levenshteinSimilarity(a.title, b.title);
    return similarity >= AppConstants.deduplicationTitleSimilarityThreshold;
  }

  /// Computes the Levenshtein similarity ratio between two strings.
  ///
  /// Returns a value between 0.0 (completely different) and 1.0 (identical).
  /// Uses the standard dynamic-programming Levenshtein distance algorithm
  /// and normalizes by the length of the longer string.
  double _levenshteinSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final aLower = a.toLowerCase();
    final bLower = b.toLowerCase();

    final aLen = aLower.length;
    final bLen = bLower.length;

    // Use two rows instead of a full matrix for space efficiency.
    var previousRow = List<int>.generate(bLen + 1, (i) => i);
    var currentRow = List<int>.filled(bLen + 1, 0);

    for (var i = 1; i <= aLen; i++) {
      currentRow[0] = i;
      for (var j = 1; j <= bLen; j++) {
        final cost = aLower[i - 1] == bLower[j - 1] ? 0 : 1;
        currentRow[j] = [
          previousRow[j] + 1, // Deletion.
          currentRow[j - 1] + 1, // Insertion.
          previousRow[j - 1] + cost, // Substitution.
        ].reduce(math.min);
      }
      // Swap rows.
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    final distance = previousRow[bLen];
    final maxLen = math.max(aLen, bLen);
    return 1.0 - (distance / maxLen);
  }
}
