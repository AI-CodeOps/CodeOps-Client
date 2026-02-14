// Tests for TechDebtItem model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/tech_debt_item.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('TechDebtItem', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'td-1',
        'projectId': 'p-1',
        'category': 'ARCHITECTURE',
        'title': 'Monolith needs splitting',
        'description': 'Service is too large',
        'filePath': 'src/main/App.java',
        'effortEstimate': 'XL',
        'businessImpact': 'HIGH',
        'status': 'IDENTIFIED',
        'firstDetectedJobId': 'j-1',
        'createdAt': '2025-01-01T00:00:00.000Z',
      };
      final item = TechDebtItem.fromJson(json);
      expect(item.category, DebtCategory.architecture);
      expect(item.effortEstimate, Effort.xl);
      expect(item.businessImpact, BusinessImpact.high);
      expect(item.status, DebtStatus.identified);
    });

    test('toJson round-trip', () {
      final item = TechDebtItem(
        id: 'td1',
        projectId: 'p1',
        category: DebtCategory.test,
        title: 'Low coverage',
        status: DebtStatus.planned,
        effortEstimate: Effort.l,
        businessImpact: BusinessImpact.medium,
      );
      final json = item.toJson();
      expect(json['category'], 'TEST');
      expect(json['effortEstimate'], 'L');
      expect(json['businessImpact'], 'MEDIUM');
      expect(json['status'], 'PLANNED');
    });
  });
}
