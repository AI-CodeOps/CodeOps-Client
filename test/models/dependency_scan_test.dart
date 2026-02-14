// Tests for DependencyScan and DependencyVulnerability model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/dependency_scan.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('DependencyScan', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'ds-1',
        'projectId': 'p-1',
        'jobId': 'j-1',
        'manifestFile': 'pom.xml',
        'totalDependencies': 45,
        'outdatedCount': 12,
        'vulnerableCount': 3,
        'createdAt': '2025-01-15T00:00:00.000Z',
      };
      final scan = DependencyScan.fromJson(json);
      expect(scan.totalDependencies, 45);
      expect(scan.vulnerableCount, 3);
    });

    test('toJson round-trip', () {
      final scan = DependencyScan(id: 'ds1', projectId: 'p1');
      final restored = DependencyScan.fromJson(scan.toJson());
      expect(restored.id, 'ds1');
    });
  });

  group('DependencyVulnerability', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'dv-1',
        'scanId': 'ds-1',
        'dependencyName': 'log4j-core',
        'currentVersion': '2.14.1',
        'fixedVersion': '2.17.1',
        'cveId': 'CVE-2021-44228',
        'severity': 'CRITICAL',
        'description': 'Log4Shell RCE vulnerability',
        'status': 'OPEN',
        'createdAt': '2025-01-15T00:00:00.000Z',
      };
      final vuln = DependencyVulnerability.fromJson(json);
      expect(vuln.severity, Severity.critical);
      expect(vuln.status, VulnerabilityStatus.open);
      expect(vuln.cveId, 'CVE-2021-44228');
    });

    test('toJson round-trip preserves enums', () {
      final vuln = DependencyVulnerability(
        id: 'v1',
        scanId: 's1',
        dependencyName: 'spring-web',
        severity: Severity.high,
        status: VulnerabilityStatus.updating,
      );
      final json = vuln.toJson();
      expect(json['severity'], 'HIGH');
      expect(json['status'], 'UPDATING');
    });
  });
}
