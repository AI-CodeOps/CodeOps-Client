// Tests for ComplianceItem model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/compliance_item.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('ComplianceItem', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'ci-1',
        'jobId': 'j-1',
        'requirement': 'All endpoints must have auth',
        'specId': 'spec-1',
        'specName': 'OpenAPI Spec',
        'status': 'MET',
        'evidence': 'JWT filter applied to all routes',
        'agentType': 'API_CONTRACT',
        'notes': 'Verified manually',
        'createdAt': '2025-01-15T00:00:00.000Z',
      };
      final item = ComplianceItem.fromJson(json);
      expect(item.status, ComplianceStatus.met);
      expect(item.agentType, AgentType.apiContract);
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 'ci-2',
        'jobId': 'j-1',
        'requirement': 'Has rate limiting',
        'status': 'MISSING',
      };
      final item = ComplianceItem.fromJson(json);
      expect(item.agentType, isNull);
      expect(item.status, ComplianceStatus.missing);
    });

    test('toJson round-trip', () {
      final item = ComplianceItem(
        id: 'ci1',
        jobId: 'j1',
        requirement: 'Test req',
        status: ComplianceStatus.partial,
        agentType: AgentType.security,
      );
      final json = item.toJson();
      expect(json['status'], 'PARTIAL');
      expect(json['agentType'], 'SECURITY');
    });
  });
}
