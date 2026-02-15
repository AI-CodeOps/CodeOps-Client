// Tests for DependencyScanner.
//
// Verifies health score computation, severity/status grouping,
// actionable vulnerability filtering, and markdown report generation.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/dependency_scan.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/services/analysis/dependency_scanner.dart';

void main() {
  // -------------------------------------------------------------------------
  // Shared test fixtures
  // -------------------------------------------------------------------------
  final baseScan = DependencyScan(
    id: 'scan-1',
    projectId: 'proj-1',
    jobId: 'job-1',
    manifestFile: 'pubspec.yaml',
    totalDependencies: 50,
    outdatedCount: 10,
    vulnerableCount: 5,
    createdAt: DateTime.parse('2024-06-01T10:00:00.000Z'),
  );

  DependencyVulnerability makeVuln({
    String id = 'vuln-1',
    Severity severity = Severity.high,
    VulnerabilityStatus status = VulnerabilityStatus.open,
    String dependencyName = 'lodash',
    String? currentVersion = '4.17.20',
    String? fixedVersion = '4.17.21',
    String? cveId = 'CVE-2021-23337',
  }) {
    return DependencyVulnerability(
      id: id,
      scanId: 'scan-1',
      dependencyName: dependencyName,
      currentVersion: currentVersion,
      fixedVersion: fixedVersion,
      cveId: cveId,
      severity: severity,
      description: 'Test vulnerability',
      status: status,
    );
  }

  group('DependencyScanner', () {
    // -----------------------------------------------------------------------
    // computeDepHealthScore
    // -----------------------------------------------------------------------
    group('computeDepHealthScore', () {
      test('returns 100 for zero vulnerabilities', () {
        final score = DependencyScanner.computeDepHealthScore(baseScan, []);
        expect(score, 100);
      });

      test('deducts 25 per CRITICAL vulnerability', () {
        // 4 CRITICAL => 100 - 4*25 = 0
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.critical),
          makeVuln(id: 'v2', severity: Severity.critical),
          makeVuln(id: 'v3', severity: Severity.critical),
          makeVuln(id: 'v4', severity: Severity.critical),
        ];
        expect(DependencyScanner.computeDepHealthScore(baseScan, vulns), 0);
      });

      test('deducts 10 per HIGH vulnerability', () {
        // 2 HIGH => 100 - 2*10 = 80
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.high),
          makeVuln(id: 'v2', severity: Severity.high),
        ];
        expect(DependencyScanner.computeDepHealthScore(baseScan, vulns), 80);
      });

      test('deducts 3 per MEDIUM vulnerability', () {
        // 3 MEDIUM => 100 - 3*3 = 91
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.medium),
          makeVuln(id: 'v2', severity: Severity.medium),
          makeVuln(id: 'v3', severity: Severity.medium),
        ];
        expect(DependencyScanner.computeDepHealthScore(baseScan, vulns), 91);
      });

      test('deducts 1 per LOW vulnerability', () {
        // 5 LOW => 100 - 5*1 = 95
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.low),
          makeVuln(id: 'v2', severity: Severity.low),
          makeVuln(id: 'v3', severity: Severity.low),
          makeVuln(id: 'v4', severity: Severity.low),
          makeVuln(id: 'v5', severity: Severity.low),
        ];
        expect(DependencyScanner.computeDepHealthScore(baseScan, vulns), 95);
      });

      test('mixed severities: 2 HIGH + 3 MEDIUM => 71', () {
        // 100 - (2*10) - (3*3) = 100 - 20 - 9 = 71
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.high),
          makeVuln(id: 'v2', severity: Severity.high),
          makeVuln(id: 'v3', severity: Severity.medium),
          makeVuln(id: 'v4', severity: Severity.medium),
          makeVuln(id: 'v5', severity: Severity.medium),
        ];
        expect(DependencyScanner.computeDepHealthScore(baseScan, vulns), 71);
      });

      test('skips RESOLVED vulnerabilities', () {
        // 1 HIGH (counted) + 1 HIGH (resolved, skipped) => 100 - 10 = 90
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.high, status: VulnerabilityStatus.open),
          makeVuln(id: 'v2', severity: Severity.high, status: VulnerabilityStatus.resolved),
        ];
        expect(DependencyScanner.computeDepHealthScore(baseScan, vulns), 90);
      });

      test('counts OPEN, UPDATING, and SUPPRESSED but not RESOLVED', () {
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.high, status: VulnerabilityStatus.open),
          makeVuln(id: 'v2', severity: Severity.high, status: VulnerabilityStatus.updating),
          makeVuln(id: 'v3', severity: Severity.high, status: VulnerabilityStatus.suppressed),
          makeVuln(id: 'v4', severity: Severity.high, status: VulnerabilityStatus.resolved),
        ];
        // 3 counted HIGH => 100 - 30 = 70
        expect(DependencyScanner.computeDepHealthScore(baseScan, vulns), 70);
      });

      test('clamps to 0 when deductions exceed 100', () {
        // 5 CRITICAL => 100 - 125 => clamped to 0
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.critical),
          makeVuln(id: 'v2', severity: Severity.critical),
          makeVuln(id: 'v3', severity: Severity.critical),
          makeVuln(id: 'v4', severity: Severity.critical),
          makeVuln(id: 'v5', severity: Severity.critical),
        ];
        expect(DependencyScanner.computeDepHealthScore(baseScan, vulns), 0);
      });
    });

    // -----------------------------------------------------------------------
    // groupBySeverity
    // -----------------------------------------------------------------------
    group('groupBySeverity', () {
      test('returns empty lists for all 4 severity levels when no vulns', () {
        final groups = DependencyScanner.groupBySeverity([]);

        expect(groups.length, 4);
        expect(groups[Severity.critical], isEmpty);
        expect(groups[Severity.high], isEmpty);
        expect(groups[Severity.medium], isEmpty);
        expect(groups[Severity.low], isEmpty);
      });

      test('groups vulnerabilities into correct severity buckets', () {
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.critical),
          makeVuln(id: 'v2', severity: Severity.high),
          makeVuln(id: 'v3', severity: Severity.high),
          makeVuln(id: 'v4', severity: Severity.medium),
          makeVuln(id: 'v5', severity: Severity.medium),
          makeVuln(id: 'v6', severity: Severity.medium),
          makeVuln(id: 'v7', severity: Severity.low),
        ];

        final groups = DependencyScanner.groupBySeverity(vulns);

        expect(groups[Severity.critical], hasLength(1));
        expect(groups[Severity.high], hasLength(2));
        expect(groups[Severity.medium], hasLength(3));
        expect(groups[Severity.low], hasLength(1));
      });

      test('preserves vulnerability objects in groups', () {
        final vuln = makeVuln(
          id: 'v-special',
          severity: Severity.critical,
          dependencyName: 'special-package',
        );

        final groups = DependencyScanner.groupBySeverity([vuln]);

        expect(groups[Severity.critical]!.first.id, 'v-special');
        expect(groups[Severity.critical]!.first.dependencyName, 'special-package');
      });
    });

    // -----------------------------------------------------------------------
    // groupByStatus
    // -----------------------------------------------------------------------
    group('groupByStatus', () {
      test('returns empty lists for all 4 status values when no vulns', () {
        final groups = DependencyScanner.groupByStatus([]);

        expect(groups.length, 4);
        expect(groups[VulnerabilityStatus.open], isEmpty);
        expect(groups[VulnerabilityStatus.updating], isEmpty);
        expect(groups[VulnerabilityStatus.suppressed], isEmpty);
        expect(groups[VulnerabilityStatus.resolved], isEmpty);
      });

      test('groups vulnerabilities into correct status buckets', () {
        final vulns = [
          makeVuln(id: 'v1', status: VulnerabilityStatus.open),
          makeVuln(id: 'v2', status: VulnerabilityStatus.open),
          makeVuln(id: 'v3', status: VulnerabilityStatus.updating),
          makeVuln(id: 'v4', status: VulnerabilityStatus.suppressed),
          makeVuln(id: 'v5', status: VulnerabilityStatus.resolved),
          makeVuln(id: 'v6', status: VulnerabilityStatus.resolved),
        ];

        final groups = DependencyScanner.groupByStatus(vulns);

        expect(groups[VulnerabilityStatus.open], hasLength(2));
        expect(groups[VulnerabilityStatus.updating], hasLength(1));
        expect(groups[VulnerabilityStatus.suppressed], hasLength(1));
        expect(groups[VulnerabilityStatus.resolved], hasLength(2));
      });
    });

    // -----------------------------------------------------------------------
    // getActionableVulns
    // -----------------------------------------------------------------------
    group('getActionableVulns', () {
      test('returns empty list when no vulns', () {
        expect(DependencyScanner.getActionableVulns([]), isEmpty);
      });

      test('returns only OPEN vulns with fixedVersion available', () {
        final vulns = [
          // Actionable: OPEN + fixedVersion
          makeVuln(
            id: 'v1',
            status: VulnerabilityStatus.open,
            fixedVersion: '2.0.0',
          ),
          // Not actionable: RESOLVED
          makeVuln(
            id: 'v2',
            status: VulnerabilityStatus.resolved,
            fixedVersion: '2.0.0',
          ),
          // Not actionable: OPEN but no fixedVersion
          makeVuln(
            id: 'v3',
            status: VulnerabilityStatus.open,
            fixedVersion: null,
          ),
          // Not actionable: UPDATING
          makeVuln(
            id: 'v4',
            status: VulnerabilityStatus.updating,
            fixedVersion: '2.0.0',
          ),
          // Not actionable: OPEN but empty fixedVersion
          makeVuln(
            id: 'v5',
            status: VulnerabilityStatus.open,
            fixedVersion: '',
          ),
          // Actionable: OPEN + fixedVersion
          makeVuln(
            id: 'v6',
            status: VulnerabilityStatus.open,
            fixedVersion: '3.0.0',
          ),
        ];

        final actionable = DependencyScanner.getActionableVulns(vulns);

        expect(actionable, hasLength(2));
        expect(actionable[0].id, 'v1');
        expect(actionable[1].id, 'v6');
      });

      test('excludes SUPPRESSED vulns even with fixedVersion', () {
        final vulns = [
          makeVuln(
            id: 'v1',
            status: VulnerabilityStatus.suppressed,
            fixedVersion: '2.0.0',
          ),
        ];

        expect(DependencyScanner.getActionableVulns(vulns), isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // formatDepReport
    // -----------------------------------------------------------------------
    group('formatDepReport', () {
      test('generates valid markdown with required headers', () {
        final report = DependencyScanner.formatDepReport(baseScan, []);

        expect(report, contains('# Dependency Health Report'));
        expect(report, contains('## Scan Overview'));
        expect(report, contains('## Vulnerability Summary'));
      });

      test('contains scan overview fields', () {
        final report = DependencyScanner.formatDepReport(baseScan, []);

        expect(report, contains('**Scan ID:** scan-1'));
        expect(report, contains('**Project ID:** proj-1'));
        expect(report, contains('**Manifest:** pubspec.yaml'));
        expect(report, contains('**Total Dependencies:** 50'));
        expect(report, contains('**Outdated:** 10'));
        expect(report, contains('**Vulnerable:** 5'));
      });

      test('contains health score', () {
        final report = DependencyScanner.formatDepReport(baseScan, []);
        expect(report, contains('**Health Score:** 100/100'));
      });

      test('shows reduced health score with vulnerabilities', () {
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.high),
        ];

        final report = DependencyScanner.formatDepReport(baseScan, vulns);
        expect(report, contains('**Health Score:** 90/100'));
      });

      test('contains severity breakdown', () {
        final vulns = [
          makeVuln(id: 'v1', severity: Severity.critical),
          makeVuln(id: 'v2', severity: Severity.high),
          makeVuln(id: 'v3', severity: Severity.high),
        ];

        final report = DependencyScanner.formatDepReport(baseScan, vulns);

        expect(report, contains('**Critical:** 1'));
        expect(report, contains('**High:** 2'));
        expect(report, contains('**Medium:** 0'));
        expect(report, contains('**Low:** 0'));
      });

      test('contains recommended updates table for actionable vulns', () {
        final vulns = [
          makeVuln(
            id: 'v1',
            severity: Severity.high,
            dependencyName: 'lodash',
            currentVersion: '4.17.20',
            fixedVersion: '4.17.21',
            cveId: 'CVE-2021-23337',
            status: VulnerabilityStatus.open,
          ),
        ];

        final report = DependencyScanner.formatDepReport(baseScan, vulns);

        expect(report, contains('## Recommended Updates'));
        expect(report, contains('| Dependency | Current | Fixed | Severity | CVE |'));
        expect(report, contains('lodash'));
        expect(report, contains('4.17.20'));
        expect(report, contains('4.17.21'));
        expect(report, contains('CVE-2021-23337'));
      });

      test('omits recommended updates when no actionable vulns', () {
        // All resolved — no actionable
        final vulns = [
          makeVuln(id: 'v1', status: VulnerabilityStatus.resolved),
        ];

        final report = DependencyScanner.formatDepReport(baseScan, vulns);

        expect(report, isNot(contains('## Recommended Updates')));
      });

      test('omits manifest line when manifestFile is null', () {
        final scanNoManifest = DependencyScan(
          id: 'scan-2',
          projectId: 'proj-1',
        );

        final report = DependencyScanner.formatDepReport(scanNoManifest, []);

        expect(report, isNot(contains('**Manifest:**')));
      });

      test('shows scan date when createdAt is present', () {
        final report = DependencyScanner.formatDepReport(baseScan, []);
        expect(report, contains('**Scanned:**'));
      });
    });
  });
}
