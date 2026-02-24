// Widget tests for VaultAuditTable (updated for CVF-008).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/widgets/vault/vault_audit_table.dart';

void main() {
  final testEntries = [
    AuditEntryResponse(
      id: 1,
      teamId: 't1',
      userId: 'user-abc-123',
      operation: 'READ',
      path: '/services/my-app/db-password',
      resourceType: 'Secret',
      resourceId: 'secret-1',
      success: true,
      correlationId: 'corr-abc-123',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AuditEntryResponse(
      id: 2,
      teamId: 't1',
      userId: 'user-def-456',
      operation: 'DELETE',
      path: '/policies/admin',
      resourceType: 'Policy',
      resourceId: 'policy-1',
      success: false,
      errorMessage: 'Forbidden: insufficient permissions',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final testPage = PageResponse<AuditEntryResponse>(
    content: testEntries,
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    PageResponse<AuditEntryResponse>? page,
    bool error = false,
  }) {
    return ProviderScope(
      overrides: [
        vaultAuditLogProvider.overrideWith((ref) {
          if (error) return Future.error(Exception('Connection failed'));
          return Future.value(page ?? testPage);
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VaultAuditTable(),
          ),
        ),
      ),
    );
  }

  group('VaultAuditTable', () {
    testWidgets('renders column headers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Operation'), findsOneWidget);
      expect(find.text('Path'), findsOneWidget);
      expect(find.text('Resource'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
    });

    testWidgets('shows operation badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('READ'), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('shows success and failure icons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows resource types', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Secret'), findsOneWidget);
      expect(find.text('Policy'), findsOneWidget);
    });

    testWidgets('shows entry count and pagination', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2 entries'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      final emptyPage = PageResponse<AuditEntryResponse>(
        content: [],
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
        isLast: true,
      );

      await tester.pumpWidget(createWidget(page: emptyPage));
      await tester.pumpAndSettle();

      expect(find.text('No audit entries found.'), findsOneWidget);
    });

    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(createWidget(error: true));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load audit log'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
