// Tests for TechDebtTracker.
//
// Verifies debt score computation, category/status breakdowns,
// resolution rate, priority matrix sorting, and markdown report generation.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/tech_debt_item.dart';
import 'package:codeops/services/analysis/tech_debt_tracker.dart';

void main() {
  // -------------------------------------------------------------------------
  // Shared test fixtures
  // -------------------------------------------------------------------------
  TechDebtItem makeItem({
    String id = 'debt-1',
    DebtCategory category = DebtCategory.code,
    Effort? effortEstimate,
    BusinessImpact? businessImpact,
    DebtStatus status = DebtStatus.identified,
    String title = 'Test debt item',
  }) {
    return TechDebtItem(
      id: id,
      projectId: 'proj-1',
      category: category,
      title: title,
      status: status,
      effortEstimate: effortEstimate,
      businessImpact: businessImpact,
    );
  }

  group('TechDebtTracker', () {
    // -----------------------------------------------------------------------
    // computeDebtScore
    // -----------------------------------------------------------------------
    group('computeDebtScore', () {
      test('returns 0 for empty list', () {
        expect(TechDebtTracker.computeDebtScore([]), 0);
      });

      test('skips RESOLVED items', () {
        final items = [
          makeItem(status: DebtStatus.resolved, category: DebtCategory.architecture),
          makeItem(status: DebtStatus.resolved, category: DebtCategory.code),
        ];
        expect(TechDebtTracker.computeDebtScore(items), 0);
      });

      test('uses default effort=S(1) and impact=LOW(1) when null', () {
        // CODE category weight = 3, effort default = 1, impact default = 1
        // Score = 3 * 1 * 1 = 3
        final items = [makeItem(category: DebtCategory.code)];
        expect(TechDebtTracker.computeDebtScore(items), 3);
      });

      test('applies category weight for ARCHITECTURE (5)', () {
        // ARCHITECTURE=5, S=1, LOW=1 => 5
        final items = [makeItem(category: DebtCategory.architecture)];
        expect(TechDebtTracker.computeDebtScore(items), 5);
      });

      test('applies category weight for DOCUMENTATION (2)', () {
        // DOCUMENTATION=2, S=1, LOW=1 => 2
        final items = [makeItem(category: DebtCategory.documentation)];
        expect(TechDebtTracker.computeDebtScore(items), 2);
      });

      test('applies category weight for DEPENDENCY (4)', () {
        // DEPENDENCY=4, S=1, LOW=1 => 4
        final items = [makeItem(category: DebtCategory.dependency)];
        expect(TechDebtTracker.computeDebtScore(items), 4);
      });

      test('applies category weight for TEST (3)', () {
        // TEST=3, S=1, LOW=1 => 3
        final items = [makeItem(category: DebtCategory.test)];
        expect(TechDebtTracker.computeDebtScore(items), 3);
      });

      test('applies effort multipliers correctly', () {
        // CODE=3, M=2, LOW=1 => 6
        final itemM = makeItem(
          category: DebtCategory.code,
          effortEstimate: Effort.m,
        );
        expect(TechDebtTracker.computeDebtScore([itemM]), 6);

        // CODE=3, L=4, LOW=1 => 12
        final itemL = makeItem(
          category: DebtCategory.code,
          effortEstimate: Effort.l,
        );
        expect(TechDebtTracker.computeDebtScore([itemL]), 12);

        // CODE=3, XL=8, LOW=1 => 24
        final itemXL = makeItem(
          category: DebtCategory.code,
          effortEstimate: Effort.xl,
        );
        expect(TechDebtTracker.computeDebtScore([itemXL]), 24);
      });

      test('applies impact multipliers correctly', () {
        // CODE=3, S=1, MEDIUM=2 => 6
        final itemMed = makeItem(
          category: DebtCategory.code,
          businessImpact: BusinessImpact.medium,
        );
        expect(TechDebtTracker.computeDebtScore([itemMed]), 6);

        // CODE=3, S=1, HIGH=4 => 12
        final itemHigh = makeItem(
          category: DebtCategory.code,
          businessImpact: BusinessImpact.high,
        );
        expect(TechDebtTracker.computeDebtScore([itemHigh]), 12);

        // CODE=3, S=1, CRITICAL=8 => 24
        final itemCrit = makeItem(
          category: DebtCategory.code,
          businessImpact: BusinessImpact.critical,
        );
        expect(TechDebtTracker.computeDebtScore([itemCrit]), 24);
      });

      test('combines category, effort, and impact multipliers', () {
        // ARCHITECTURE=5, XL=8, CRITICAL=8 => 5*8*8 = 320
        final item = makeItem(
          category: DebtCategory.architecture,
          effortEstimate: Effort.xl,
          businessImpact: BusinessImpact.critical,
        );
        expect(TechDebtTracker.computeDebtScore([item]), 320);
      });

      test('sums scores for multiple non-resolved items', () {
        final items = [
          // ARCHITECTURE=5, S=1, LOW=1 => 5
          makeItem(id: 'd1', category: DebtCategory.architecture),
          // CODE=3, M=2, MEDIUM=2 => 12
          makeItem(
            id: 'd2',
            category: DebtCategory.code,
            effortEstimate: Effort.m,
            businessImpact: BusinessImpact.medium,
          ),
          // RESOLVED — skipped
          makeItem(id: 'd3', status: DebtStatus.resolved),
          // DOCUMENTATION=2, S=1, LOW=1 => 2
          makeItem(id: 'd4', category: DebtCategory.documentation),
        ];
        // Total: 5 + 12 + 0 + 2 = 19
        expect(TechDebtTracker.computeDebtScore(items), 19);
      });
    });

    // -----------------------------------------------------------------------
    // computeDebtByCategory
    // -----------------------------------------------------------------------
    group('computeDebtByCategory', () {
      test('returns zero counts for empty list', () {
        final counts = TechDebtTracker.computeDebtByCategory([]);
        for (final cat in DebtCategory.values) {
          expect(counts[cat], 0);
        }
      });

      test('counts items per category correctly', () {
        final items = [
          makeItem(id: 'd1', category: DebtCategory.architecture),
          makeItem(id: 'd2', category: DebtCategory.code),
          makeItem(id: 'd3', category: DebtCategory.code),
          makeItem(id: 'd4', category: DebtCategory.test),
          makeItem(id: 'd5', category: DebtCategory.dependency),
          makeItem(id: 'd6', category: DebtCategory.dependency),
          makeItem(id: 'd7', category: DebtCategory.dependency),
          makeItem(id: 'd8', category: DebtCategory.documentation),
        ];

        final counts = TechDebtTracker.computeDebtByCategory(items);

        expect(counts[DebtCategory.architecture], 1);
        expect(counts[DebtCategory.code], 2);
        expect(counts[DebtCategory.test], 1);
        expect(counts[DebtCategory.dependency], 3);
        expect(counts[DebtCategory.documentation], 1);
      });

      test('includes resolved items in category counts', () {
        final items = [
          makeItem(
            id: 'd1',
            category: DebtCategory.code,
            status: DebtStatus.resolved,
          ),
          makeItem(id: 'd2', category: DebtCategory.code),
        ];

        final counts = TechDebtTracker.computeDebtByCategory(items);
        expect(counts[DebtCategory.code], 2);
      });
    });

    // -----------------------------------------------------------------------
    // computeDebtByStatus
    // -----------------------------------------------------------------------
    group('computeDebtByStatus', () {
      test('returns zero counts for empty list', () {
        final counts = TechDebtTracker.computeDebtByStatus([]);
        for (final status in DebtStatus.values) {
          expect(counts[status], 0);
        }
      });

      test('counts items per status correctly', () {
        final items = [
          makeItem(id: 'd1', status: DebtStatus.identified),
          makeItem(id: 'd2', status: DebtStatus.identified),
          makeItem(id: 'd3', status: DebtStatus.planned),
          makeItem(id: 'd4', status: DebtStatus.inProgress),
          makeItem(id: 'd5', status: DebtStatus.resolved),
          makeItem(id: 'd6', status: DebtStatus.resolved),
          makeItem(id: 'd7', status: DebtStatus.resolved),
        ];

        final counts = TechDebtTracker.computeDebtByStatus(items);

        expect(counts[DebtStatus.identified], 2);
        expect(counts[DebtStatus.planned], 1);
        expect(counts[DebtStatus.inProgress], 1);
        expect(counts[DebtStatus.resolved], 3);
      });
    });

    // -----------------------------------------------------------------------
    // computeResolutionRate
    // -----------------------------------------------------------------------
    group('computeResolutionRate', () {
      test('returns 0.0 for empty list', () {
        expect(TechDebtTracker.computeResolutionRate([]), 0.0);
      });

      test('returns 100.0 when all items are resolved', () {
        final items = [
          makeItem(id: 'd1', status: DebtStatus.resolved),
          makeItem(id: 'd2', status: DebtStatus.resolved),
          makeItem(id: 'd3', status: DebtStatus.resolved),
        ];
        expect(TechDebtTracker.computeResolutionRate(items), 100.0);
      });

      test('returns 0.0 when no items are resolved', () {
        final items = [
          makeItem(id: 'd1', status: DebtStatus.identified),
          makeItem(id: 'd2', status: DebtStatus.planned),
          makeItem(id: 'd3', status: DebtStatus.inProgress),
        ];
        expect(TechDebtTracker.computeResolutionRate(items), 0.0);
      });

      test('returns correct percentage for mixed statuses', () {
        final items = [
          makeItem(id: 'd1', status: DebtStatus.identified),
          makeItem(id: 'd2', status: DebtStatus.resolved),
          makeItem(id: 'd3', status: DebtStatus.planned),
          makeItem(id: 'd4', status: DebtStatus.resolved),
        ];
        // 2 resolved out of 4 = 50.0%
        expect(TechDebtTracker.computeResolutionRate(items), 50.0);
      });

      test('handles single resolved item', () {
        final items = [makeItem(status: DebtStatus.resolved)];
        expect(TechDebtTracker.computeResolutionRate(items), 100.0);
      });

      test('handles single non-resolved item', () {
        final items = [makeItem(status: DebtStatus.identified)];
        expect(TechDebtTracker.computeResolutionRate(items), 0.0);
      });
    });

    // -----------------------------------------------------------------------
    // computePriorityMatrix
    // -----------------------------------------------------------------------
    group('computePriorityMatrix', () {
      test('returns empty list for empty input', () {
        expect(TechDebtTracker.computePriorityMatrix([]), isEmpty);
      });

      test('sorts high impact before low impact', () {
        final items = [
          makeItem(
            id: 'low-impact',
            title: 'Low impact',
            businessImpact: BusinessImpact.low,
          ),
          makeItem(
            id: 'critical-impact',
            title: 'Critical impact',
            businessImpact: BusinessImpact.critical,
          ),
          makeItem(
            id: 'high-impact',
            title: 'High impact',
            businessImpact: BusinessImpact.high,
          ),
        ];

        final sorted = TechDebtTracker.computePriorityMatrix(items);

        expect(sorted[0].title, 'Critical impact');
        expect(sorted[1].title, 'High impact');
        expect(sorted[2].title, 'Low impact');
      });

      test('sorts low effort before high effort when impact is equal', () {
        final items = [
          makeItem(
            id: 'xl-effort',
            title: 'XL effort',
            businessImpact: BusinessImpact.high,
            effortEstimate: Effort.xl,
          ),
          makeItem(
            id: 's-effort',
            title: 'S effort',
            businessImpact: BusinessImpact.high,
            effortEstimate: Effort.s,
          ),
          makeItem(
            id: 'm-effort',
            title: 'M effort',
            businessImpact: BusinessImpact.high,
            effortEstimate: Effort.m,
          ),
        ];

        final sorted = TechDebtTracker.computePriorityMatrix(items);

        expect(sorted[0].title, 'S effort');
        expect(sorted[1].title, 'M effort');
        expect(sorted[2].title, 'XL effort');
      });

      test('high impact + low effort comes first (priority order)', () {
        final items = [
          makeItem(
            id: 'low-priority',
            title: 'Low impact + XL effort',
            businessImpact: BusinessImpact.low,
            effortEstimate: Effort.xl,
          ),
          makeItem(
            id: 'high-priority',
            title: 'Critical impact + S effort',
            businessImpact: BusinessImpact.critical,
            effortEstimate: Effort.s,
          ),
          makeItem(
            id: 'mid-priority',
            title: 'High impact + M effort',
            businessImpact: BusinessImpact.high,
            effortEstimate: Effort.m,
          ),
        ];

        final sorted = TechDebtTracker.computePriorityMatrix(items);

        expect(sorted[0].title, 'Critical impact + S effort');
        expect(sorted[1].title, 'High impact + M effort');
        expect(sorted[2].title, 'Low impact + XL effort');
      });

      test('does not modify the original list', () {
        final items = [
          makeItem(
            id: 'd1',
            title: 'Second',
            businessImpact: BusinessImpact.low,
          ),
          makeItem(
            id: 'd2',
            title: 'First',
            businessImpact: BusinessImpact.critical,
          ),
        ];

        TechDebtTracker.computePriorityMatrix(items);

        // Original list unchanged
        expect(items[0].title, 'Second');
        expect(items[1].title, 'First');
      });

      test('defaults null impact to LOW and null effort to S', () {
        final items = [
          makeItem(id: 'd1', title: 'No impact/effort'),
          makeItem(
            id: 'd2',
            title: 'Explicit low/s',
            businessImpact: BusinessImpact.low,
            effortEstimate: Effort.s,
          ),
        ];

        final sorted = TechDebtTracker.computePriorityMatrix(items);

        // Both should have equivalent sort values, order is stable
        expect(sorted, hasLength(2));
      });
    });

    // -----------------------------------------------------------------------
    // formatDebtReport
    // -----------------------------------------------------------------------
    group('formatDebtReport', () {
      test('generates valid markdown with required headers', () {
        final items = [
          makeItem(
            id: 'd1',
            category: DebtCategory.architecture,
            businessImpact: BusinessImpact.critical,
            effortEstimate: Effort.s,
            title: 'Monolith coupling',
          ),
          makeItem(
            id: 'd2',
            category: DebtCategory.code,
            status: DebtStatus.resolved,
            title: 'Dead code cleanup',
          ),
        ];

        final report = TechDebtTracker.formatDebtReport(items, {'totalItems': 2});

        expect(report, contains('# Tech Debt Report'));
        expect(report, contains('## Summary'));
        expect(report, contains('## Status Breakdown'));
        expect(report, contains('## Category Breakdown'));
        expect(report, contains('## Priority Items'));
        expect(report, contains('## Server Summary Data'));
      });

      test('contains correct total items count', () {
        final items = [
          makeItem(id: 'd1'),
          makeItem(id: 'd2'),
          makeItem(id: 'd3'),
        ];

        final report = TechDebtTracker.formatDebtReport(items, {});

        expect(report, contains('**Total Items:** 3'));
      });

      test('contains debt score', () {
        final items = [
          // CODE=3, S=1, LOW=1 => 3
          makeItem(id: 'd1', category: DebtCategory.code),
        ];

        final report = TechDebtTracker.formatDebtReport(items, {});

        expect(report, contains('**Debt Score:** 3'));
      });

      test('contains resolution rate', () {
        final items = [
          makeItem(id: 'd1', status: DebtStatus.resolved),
          makeItem(id: 'd2', status: DebtStatus.identified),
        ];

        final report = TechDebtTracker.formatDebtReport(items, {});

        expect(report, contains('**Resolution Rate:** 50.0%'));
      });

      test('contains priority items table with pipe-separated columns', () {
        final items = [
          makeItem(
            id: 'd1',
            title: 'Test item',
            category: DebtCategory.architecture,
            businessImpact: BusinessImpact.high,
            effortEstimate: Effort.m,
          ),
        ];

        final report = TechDebtTracker.formatDebtReport(items, {});

        expect(report, contains('| Title | Category | Impact | Effort |'));
        expect(report, contains('|-------|----------|--------|--------|'));
        expect(report, contains('Test item'));
        expect(report, contains('Architecture'));
        expect(report, contains('High'));
        expect(report, contains('Medium'));
      });

      test('includes server summary data when provided', () {
        final report = TechDebtTracker.formatDebtReport(
          [],
          {'totalItems': 42, 'debtScore': 128},
        );

        expect(report, contains('**totalItems:** 42'));
        expect(report, contains('**debtScore:** 128'));
      });

      test('omits server summary section when summary is empty', () {
        final report = TechDebtTracker.formatDebtReport([], {});

        expect(report, isNot(contains('## Server Summary Data')));
      });
    });
  });
}
