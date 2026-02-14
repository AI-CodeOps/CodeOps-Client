// Tests for Finding model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/finding.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('Finding', () {
    test('fromJson with all enum fields', () {
      final json = {
        'id': 'f-1',
        'jobId': 'j-1',
        'agentType': 'SECURITY',
        'severity': 'CRITICAL',
        'title': 'SQL Injection',
        'description': 'Found SQL injection in login',
        'filePath': 'src/auth/login.java',
        'lineNumber': 42,
        'recommendation': 'Use parameterized queries',
        'evidence': 'String concatenation in query',
        'effortEstimate': 'M',
        'debtCategory': 'CODE',
        'status': 'OPEN',
        'createdAt': '2025-01-15T00:00:00.000Z',
      };
      final finding = Finding.fromJson(json);
      expect(finding.agentType, AgentType.security);
      expect(finding.severity, Severity.critical);
      expect(finding.effortEstimate, Effort.m);
      expect(finding.debtCategory, DebtCategory.code);
      expect(finding.status, FindingStatus.open);
      expect(finding.lineNumber, 42);
    });

    test('fromJson with null optional enums', () {
      final json = {
        'id': 'f-2',
        'jobId': 'j-1',
        'agentType': 'CODE_QUALITY',
        'severity': 'LOW',
        'title': 'Unused import',
        'status': 'FIXED',
      };
      final finding = Finding.fromJson(json);
      expect(finding.effortEstimate, isNull);
      expect(finding.debtCategory, isNull);
      expect(finding.status, FindingStatus.fixed);
    });

    test('toJson round-trip preserves all enums', () {
      final finding = Finding(
        id: 'f1',
        jobId: 'j1',
        agentType: AgentType.documentation,
        severity: Severity.medium,
        title: 'Missing docs',
        status: FindingStatus.acknowledged,
        effortEstimate: Effort.s,
        debtCategory: DebtCategory.documentation,
      );
      final json = finding.toJson();
      expect(json['agentType'], 'DOCUMENTATION');
      expect(json['severity'], 'MEDIUM');
      expect(json['effortEstimate'], 'S');
      expect(json['debtCategory'], 'DOCUMENTATION');
      expect(json['status'], 'ACKNOWLEDGED');
    });
  });
}
