// Widget tests for VaultAuditDetailRow (CVF-008).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_models.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_audit_detail_row.dart';

void main() {
  final successEntry = AuditEntryResponse(
    id: 1,
    teamId: 't1',
    userId: 'user-abc-123',
    operation: 'WRITE',
    path: '/services/app/db-password',
    resourceType: 'Secret',
    resourceId: 'res-001',
    success: true,
    ipAddress: '10.0.0.1',
    correlationId: 'corr-xyz-789',
    createdAt: DateTime(2026, 2, 20, 10, 30),
  );

  final failureEntry = AuditEntryResponse(
    id: 2,
    teamId: 't1',
    userId: 'user-def-456',
    operation: 'DELETE',
    path: '/services/app/api-key',
    resourceType: 'Secret',
    resourceId: 'res-002',
    success: false,
    errorMessage: 'Permission denied: insufficient privileges',
    ipAddress: '10.0.0.2',
    createdAt: DateTime(2026, 2, 20, 11, 0),
  );

  Widget createWidget(AuditEntryResponse entry) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SingleChildScrollView(child: VaultAuditDetailRow(entry: entry)),
      ),
    );
  }

  group('VaultAuditDetailRow', () {
    testWidgets('shows operation badge', (tester) async {
      await tester.pumpWidget(createWidget(successEntry));
      expect(find.text('WRITE'), findsOneWidget);
    });

    testWidgets('shows Success status for successful entry', (tester) async {
      await tester.pumpWidget(createWidget(successEntry));
      expect(find.text('Success'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows Failed status for failed entry', (tester) async {
      await tester.pumpWidget(createWidget(failureEntry));
      expect(find.text('Failed'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows all detail fields', (tester) async {
      await tester.pumpWidget(createWidget(successEntry));

      expect(find.text('Path'), findsOneWidget);
      expect(find.text('/services/app/db-password'), findsOneWidget);
      expect(find.text('Resource Type'), findsOneWidget);
      expect(find.text('Secret'), findsOneWidget);
      expect(find.text('Resource ID'), findsOneWidget);
      expect(find.text('res-001'), findsOneWidget);
      expect(find.text('User ID'), findsOneWidget);
      expect(find.text('user-abc-123'), findsOneWidget);
      expect(find.text('IP Address'), findsOneWidget);
      expect(find.text('10.0.0.1'), findsOneWidget);
      expect(find.text('Correlation ID'), findsOneWidget);
      expect(find.text('corr-xyz-789'), findsOneWidget);
    });

    testWidgets('shows error message for failed entry', (tester) async {
      await tester.pumpWidget(createWidget(failureEntry));

      expect(find.text('Error'), findsOneWidget);
      expect(
        find.text('Permission denied: insufficient privileges'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('does not show error section for successful entry',
        (tester) async {
      await tester.pumpWidget(createWidget(successEntry));

      expect(find.text('Error'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('shows copy buttons for fields', (tester) async {
      await tester.pumpWidget(createWidget(successEntry));

      // Each non-null field gets a copy button
      expect(find.byIcon(Icons.copy), findsWidgets);
    });
  });
}
