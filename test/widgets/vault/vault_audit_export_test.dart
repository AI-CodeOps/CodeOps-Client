// Widget tests for VaultAuditExport (CVF-008).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_models.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_audit_export.dart';

void main() {
  final testEntries = [
    AuditEntryResponse(
      id: 1,
      operation: 'WRITE',
      path: '/services/app/db-password',
      resourceType: 'Secret',
      success: true,
      createdAt: DateTime(2026, 2, 20, 10, 30),
    ),
    AuditEntryResponse(
      id: 2,
      operation: 'DELETE',
      path: '/services/app/api-key',
      success: false,
      errorMessage: 'Permission denied',
      createdAt: DateTime(2026, 2, 20, 11, 0),
    ),
  ];

  Widget createApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('VaultAuditExport dialog', () {
    testWidgets('shows entry count', (tester) async {
      await tester.pumpWidget(createApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                VaultAuditExport.showExportDialog(context, testEntries),
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Export Audit Log'), findsOneWidget);
      expect(find.text('2 entries will be exported.'), findsOneWidget);
    });

    testWidgets('shows CSV and JSON buttons', (tester) async {
      await tester.pumpWidget(createApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                VaultAuditExport.showExportDialog(context, testEntries),
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.byIcon(Icons.data_object), findsOneWidget);
    });

    testWidgets('shows Cancel button', (tester) async {
      await tester.pumpWidget(createApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                VaultAuditExport.showExportDialog(context, testEntries),
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel closes dialog', (tester) async {
      await tester.pumpWidget(createApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                VaultAuditExport.showExportDialog(context, testEntries),
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Export Audit Log'), findsNothing);
    });
  });
}
