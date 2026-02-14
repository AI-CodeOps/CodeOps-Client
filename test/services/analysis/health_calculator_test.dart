// Tests for HealthCalculator.
//
// Verifies composite score calculation, result determination,
// finding-based score deductions, and agent weight multipliers.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_run.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/services/analysis/health_calculator.dart';
import 'package:codeops/utils/constants.dart';

void main() {
  late HealthCalculator calculator;

  setUp(() {
    calculator = const HealthCalculator();
  });

  group('HealthCalculator', () {
    // ---------------------------------------------------------------------
    // calculateCompositeScore
    // ---------------------------------------------------------------------

    group('calculateCompositeScore', () {
      test('returns zero score and fail for empty list', () {
        final result = calculator.calculateCompositeScore([]);

        expect(result.score, 0);
        expect(result.result, AgentResult.fail);
        expect(result.agentScores, isEmpty);
      });

      test('returns zero score and fail when no runs are completed', () {
        final runs = [
          const AgentRun(
            id: 'r1',
            jobId: 'j1',
            agentType: AgentType.security,
            status: AgentStatus.running,
            score: 85,
          ),
          const AgentRun(
            id: 'r2',
            jobId: 'j1',
            agentType: AgentType.codeQuality,
            status: AgentStatus.pending,
            score: 90,
          ),
        ];

        final result = calculator.calculateCompositeScore(runs);

        expect(result.score, 0);
        expect(result.result, AgentResult.fail);
        expect(result.agentScores, isEmpty);
      });

      test('returns zero score when completed runs have null scores', () {
        final runs = [
          const AgentRun(
            id: 'r1',
            jobId: 'j1',
            agentType: AgentType.security,
            status: AgentStatus.completed,
          ),
        ];

        final result = calculator.calculateCompositeScore(runs);

        expect(result.score, 0);
        expect(result.result, AgentResult.fail);
        expect(result.agentScores, isEmpty);
      });

      test('calculates score for a single completed agent', () {
        final runs = [
          const AgentRun(
            id: 'r1',
            jobId: 'j1',
            agentType: AgentType.security,
            status: AgentStatus.completed,
            score: 85,
          ),
        ];

        final result = calculator.calculateCompositeScore(runs);

        expect(result.score, 85);
        expect(result.result, AgentResult.pass);
        expect(result.agentScores[AgentType.security], 85.0);
      });

      test('calculates weighted average for multiple agents', () {
        final runs = [
          const AgentRun(
            id: 'r1',
            jobId: 'j1',
            agentType: AgentType.security,
            status: AgentStatus.completed,
            score: 80,
          ),
          const AgentRun(
            id: 'r2',
            jobId: 'j1',
            agentType: AgentType.codeQuality,
            status: AgentStatus.completed,
            score: 90,
          ),
        ];

        final result = calculator.calculateCompositeScore(runs);

        // security weight = 1.5, codeQuality weight = 1.0
        // weighted = (80 * 1.5 + 90 * 1.0) / (1.5 + 1.0) = 210 / 2.5 = 84
        expect(result.score, 84);
        expect(result.result, AgentResult.pass);
        expect(result.agentScores[AgentType.security], 80.0);
        expect(result.agentScores[AgentType.codeQuality], 90.0);
      });

      test('applies higher weight for architecture agent', () {
        final runs = [
          const AgentRun(
            id: 'r1',
            jobId: 'j1',
            agentType: AgentType.architecture,
            status: AgentStatus.completed,
            score: 70,
          ),
          const AgentRun(
            id: 'r2',
            jobId: 'j1',
            agentType: AgentType.documentation,
            status: AgentStatus.completed,
            score: 90,
          ),
        ];

        final result = calculator.calculateCompositeScore(runs);

        // architecture weight = 1.5, documentation weight = 1.0
        // weighted = (70 * 1.5 + 90 * 1.0) / (1.5 + 1.0) = 195 / 2.5 = 78
        expect(result.score, 78);
        expect(result.result, AgentResult.warn);
      });

      test('ignores non-completed runs in calculation', () {
        final runs = [
          const AgentRun(
            id: 'r1',
            jobId: 'j1',
            agentType: AgentType.security,
            status: AgentStatus.completed,
            score: 90,
          ),
          const AgentRun(
            id: 'r2',
            jobId: 'j1',
            agentType: AgentType.codeQuality,
            status: AgentStatus.failed,
            score: 20,
          ),
        ];

        final result = calculator.calculateCompositeScore(runs);

        expect(result.score, 90);
        expect(result.agentScores, hasLength(1));
        expect(result.agentScores[AgentType.security], 90.0);
      });

      test('clamps score to 0-100 range', () {
        final runs = [
          const AgentRun(
            id: 'r1',
            jobId: 'j1',
            agentType: AgentType.security,
            status: AgentStatus.completed,
            score: 100,
          ),
        ];

        final result = calculator.calculateCompositeScore(runs);

        expect(result.score, lessThanOrEqualTo(100));
        expect(result.score, greaterThanOrEqualTo(0));
      });
    });

    // ---------------------------------------------------------------------
    // determineResult
    // ---------------------------------------------------------------------

    group('determineResult', () {
      test('returns pass for score at green threshold', () {
        final result = calculator
            .determineResult(AppConstants.healthScoreGreenThreshold);

        expect(result, AgentResult.pass);
      });

      test('returns pass for score above green threshold', () {
        final result = calculator
            .determineResult(AppConstants.healthScoreGreenThreshold + 5);

        expect(result, AgentResult.pass);
      });

      test('returns warn for score at yellow threshold', () {
        final result = calculator
            .determineResult(AppConstants.healthScoreYellowThreshold);

        expect(result, AgentResult.warn);
      });

      test('returns warn for score between yellow and green thresholds', () {
        final result = calculator
            .determineResult(AppConstants.healthScoreGreenThreshold - 1);

        expect(result, AgentResult.warn);
      });

      test('returns fail for score below yellow threshold', () {
        final result = calculator
            .determineResult(AppConstants.healthScoreYellowThreshold - 1);

        expect(result, AgentResult.fail);
      });

      test('returns fail for zero score', () {
        final result = calculator.determineResult(0);

        expect(result, AgentResult.fail);
      });

      test('returns pass for perfect score', () {
        final result = calculator.determineResult(100);

        expect(result, AgentResult.pass);
      });
    });

    // ---------------------------------------------------------------------
    // calculateFindingBasedScore
    // ---------------------------------------------------------------------

    group('calculateFindingBasedScore', () {
      test('returns 100 with no findings', () {
        final score = calculator.calculateFindingBasedScore();

        expect(score, 100);
      });

      test('deducts correct amount for critical findings', () {
        final score = calculator.calculateFindingBasedScore(criticalCount: 2);

        final expected =
            (100 - 2 * AppConstants.criticalScoreReduction).round().clamp(0, 100);
        expect(score, expected);
      });

      test('deducts correct amount for high findings', () {
        final score = calculator.calculateFindingBasedScore(highCount: 3);

        final expected =
            (100 - 3 * AppConstants.highScoreReduction).round().clamp(0, 100);
        expect(score, expected);
      });

      test('deducts correct amount for medium findings', () {
        final score = calculator.calculateFindingBasedScore(mediumCount: 4);

        final expected =
            (100 - 4 * AppConstants.mediumScoreReduction).round().clamp(0, 100);
        expect(score, expected);
      });

      test('deducts zero for low findings (low reduction is 0)', () {
        final score = calculator.calculateFindingBasedScore(lowCount: 10);

        expect(score, 100);
      });

      test('accumulates deductions from all severities', () {
        final score = calculator.calculateFindingBasedScore(
          criticalCount: 1,
          highCount: 2,
          mediumCount: 4,
          lowCount: 5,
        );

        final expectedDeduction =
            (1 * AppConstants.criticalScoreReduction) +
            (2 * AppConstants.highScoreReduction) +
            (4 * AppConstants.mediumScoreReduction) +
            (5 * AppConstants.lowScoreReduction);
        final expected = (100 - expectedDeduction).round().clamp(0, 100);
        expect(score, expected);
      });

      test('clamps score to zero when deductions exceed 100', () {
        final score = calculator.calculateFindingBasedScore(criticalCount: 100);

        expect(score, 0);
      });
    });

    // ---------------------------------------------------------------------
    // getAgentWeight
    // ---------------------------------------------------------------------

    group('getAgentWeight', () {
      test('returns 1.5 for security agent', () {
        final weight = calculator.getAgentWeight(AgentType.security);

        expect(weight, AppConstants.securityAgentWeight);
        expect(weight, 1.5);
      });

      test('returns 1.5 for architecture agent', () {
        final weight = calculator.getAgentWeight(AgentType.architecture);

        expect(weight, AppConstants.architectureAgentWeight);
        expect(weight, 1.5);
      });

      test('returns 1.0 for code quality agent', () {
        final weight = calculator.getAgentWeight(AgentType.codeQuality);

        expect(weight, AppConstants.defaultAgentWeight);
        expect(weight, 1.0);
      });

      test('returns 1.0 for documentation agent', () {
        final weight = calculator.getAgentWeight(AgentType.documentation);

        expect(weight, AppConstants.defaultAgentWeight);
        expect(weight, 1.0);
      });

      test('returns 1.0 for all non-security/architecture agents', () {
        final defaultWeightAgents = [
          AgentType.codeQuality,
          AgentType.buildHealth,
          AgentType.completeness,
          AgentType.apiContract,
          AgentType.testCoverage,
          AgentType.uiUx,
          AgentType.documentation,
          AgentType.database,
          AgentType.performance,
          AgentType.dependency,
        ];

        for (final agentType in defaultWeightAgents) {
          expect(
            calculator.getAgentWeight(agentType),
            AppConstants.defaultAgentWeight,
            reason: '${agentType.name} should have default weight',
          );
        }
      });
    });

    // ---------------------------------------------------------------------
    // HealthResult
    // ---------------------------------------------------------------------

    group('HealthResult', () {
      test('can be constructed with required fields', () {
        const result = HealthResult(
          score: 85,
          result: AgentResult.pass,
          agentScores: {AgentType.security: 85.0},
        );

        expect(result.score, 85);
        expect(result.result, AgentResult.pass);
        expect(result.agentScores, hasLength(1));
      });
    });

    // ---------------------------------------------------------------------
    // const instantiation
    // ---------------------------------------------------------------------

    group('HealthCalculator instantiation', () {
      test('can be created as a const instance', () {
        const c = HealthCalculator();
        expect(c, isA<HealthCalculator>());
      });
    });
  });
}
