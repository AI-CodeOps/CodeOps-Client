/// Health score calculation service.
///
/// Computes composite health scores from agent runs using weighted
/// averages and finding-based deductions.
library;

import '../../models/agent_run.dart';
import '../../models/enums.dart';
import '../../utils/constants.dart';

/// Result of a health score calculation.
class HealthResult {
  /// Composite health score (0-100).
  final int score;

  /// Overall result derived from the score.
  final AgentResult result;

  /// Per-agent weighted scores.
  final Map<AgentType, double> agentScores;

  /// Creates a [HealthResult].
  const HealthResult({
    required this.score,
    required this.result,
    required this.agentScores,
  });
}

/// Calculates composite health scores from agent run data.
class HealthCalculator {
  /// Creates a [HealthCalculator].
  const HealthCalculator();

  /// Calculates a composite health score from agent runs.
  ///
  /// Uses a weighted average where Security and Architecture agents
  /// contribute 1.5x their weight compared to other agents.
  HealthResult calculateCompositeScore(List<AgentRun> agentRuns) {
    if (agentRuns.isEmpty) {
      return const HealthResult(
        score: 0,
        result: AgentResult.fail,
        agentScores: {},
      );
    }

    final completedRuns = agentRuns
        .where((r) => r.status == AgentStatus.completed && r.score != null)
        .toList();

    if (completedRuns.isEmpty) {
      return const HealthResult(
        score: 0,
        result: AgentResult.fail,
        agentScores: {},
      );
    }

    double totalWeightedScore = 0;
    double totalWeight = 0;
    final agentScores = <AgentType, double>{};

    for (final run in completedRuns) {
      final weight = getAgentWeight(run.agentType);
      final score = run.score!.toDouble();
      agentScores[run.agentType] = score;
      totalWeightedScore += score * weight;
      totalWeight += weight;
    }

    final compositeScore =
        totalWeight > 0 ? (totalWeightedScore / totalWeight).round() : 0;
    final clampedScore = compositeScore.clamp(0, 100);

    return HealthResult(
      score: clampedScore,
      result: determineResult(clampedScore),
      agentScores: agentScores,
    );
  }

  /// Determines the overall result from a health score.
  AgentResult determineResult(int score) {
    if (score >= AppConstants.healthScoreGreenThreshold) {
      return AgentResult.pass;
    } else if (score >= AppConstants.healthScoreYellowThreshold) {
      return AgentResult.warn;
    } else {
      return AgentResult.fail;
    }
  }

  /// Calculates a health score based on finding severity deductions.
  ///
  /// Starts at 100 and deducts points per severity level.
  int calculateFindingBasedScore({
    int criticalCount = 0,
    int highCount = 0,
    int mediumCount = 0,
    int lowCount = 0,
  }) {
    final deduction = (criticalCount * AppConstants.criticalScoreReduction) +
        (highCount * AppConstants.highScoreReduction) +
        (mediumCount * AppConstants.mediumScoreReduction) +
        (lowCount * AppConstants.lowScoreReduction);
    return (100 - deduction).round().clamp(0, 100);
  }

  /// Returns the weight multiplier for an agent type.
  double getAgentWeight(AgentType agentType) {
    return switch (agentType) {
      AgentType.security => AppConstants.securityAgentWeight,
      AgentType.architecture => AppConstants.architectureAgentWeight,
      _ => AppConstants.defaultAgentWeight,
    };
  }
}
