// Widget tests for VaultAuditOperationBadge (CVF-008).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/theme/colors.dart';
import 'package:codeops/widgets/vault/vault_audit_operation_badge.dart';

void main() {
  Widget createWidget(String operation) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: VaultAuditOperationBadge(operation)),
    );
  }

  group('VaultAuditOperationBadge', () {
    testWidgets('displays the operation text', (tester) async {
      await tester.pumpWidget(createWidget('READ'));
      expect(find.text('READ'), findsOneWidget);
    });

    testWidgets('displays WRITE operation', (tester) async {
      await tester.pumpWidget(createWidget('WRITE'));
      expect(find.text('WRITE'), findsOneWidget);
    });

    testWidgets('displays DELETE operation', (tester) async {
      await tester.pumpWidget(createWidget('DELETE'));
      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('returns blue color for READ operations', (tester) async {
      final color = VaultAuditOperationBadge.operationColor('READ');
      expect(color, const Color(0xFF3B82F6));
    });

    testWidgets('returns success color for WRITE operations', (tester) async {
      final color = VaultAuditOperationBadge.operationColor('WRITE');
      expect(color, CodeOpsColors.success);
    });

    testWidgets('returns error color for DELETE operations', (tester) async {
      final color = VaultAuditOperationBadge.operationColor('DELETE');
      expect(color, CodeOpsColors.error);
    });

    testWidgets('returns warning color for SEAL operations', (tester) async {
      final color = VaultAuditOperationBadge.operationColor('SEAL');
      expect(color, CodeOpsColors.warning);
    });

    testWidgets('returns purple color for TRANSIT_ENCRYPT', (tester) async {
      final color = VaultAuditOperationBadge.operationColor('TRANSIT_ENCRYPT');
      expect(color, const Color(0xFFA855F7));
    });

    testWidgets('returns secondary color for ROTATE', (tester) async {
      final color = VaultAuditOperationBadge.operationColor('ROTATE');
      expect(color, CodeOpsColors.secondary);
    });
  });
}
