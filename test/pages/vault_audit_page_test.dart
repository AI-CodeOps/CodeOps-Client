// Widget tests for VaultAuditPage (CVF-008).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/pages/vault_audit_page.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';

void main() {
  final testEntry1 = AuditEntryResponse(
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

  final testEntry2 = AuditEntryResponse(
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

  final testPage = PageResponse<AuditEntryResponse>(
    content: [testEntry1, testEntry2],
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  final testStats = <String, int>{
    'totalEntries': 100,
    'failedEntries': 5,
    'readOperations': 60,
    'writeOperations': 30,
    'deleteOperations': 10,
  };

  Widget createWidget({
    PageResponse<AuditEntryResponse>? page,
    Map<String, int>? stats,
    bool error = false,
  }) {
    return ProviderScope(
      overrides: [
        vaultAuditLogProvider.overrideWith((ref) {
          if (error) return Future.error(Exception('Connection refused'));
          return Future.value(page ?? testPage);
        }),
        vaultAuditStatsProvider.overrideWith(
          (ref) => Future.value(stats ?? testStats),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: VaultAuditPage()),
      ),
    );
  }

  group('VaultAuditPage — header', () {
    testWidgets('shows Audit Log title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Audit Log'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows export button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Export'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('shows receipt_long icon', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    });
  });

  group('VaultAuditPage — stats', () {
    testWidgets('shows stat chips from AuditStatsPanel', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Reads'), findsOneWidget);
      expect(find.text('Writes'), findsOneWidget);
      expect(find.text('Deletes'), findsOneWidget);
    });
  });

  group('VaultAuditPage — filters', () {
    testWidgets('shows filter bar with Apply and Clear', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('shows quick range chips', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('1h'), findsOneWidget);
      expect(find.text('6h'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
      expect(find.text('7d'), findsOneWidget);
      expect(find.text('30d'), findsOneWidget);
    });

    testWidgets('shows time range pickers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
    });
  });

  group('VaultAuditPage — table', () {
    testWidgets('shows table column headers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Operation'), findsWidgets);
      expect(find.text('Path'), findsWidgets);
      expect(find.text('Resource'), findsWidgets);
      expect(find.text('Status'), findsWidgets);
      expect(find.text('User'), findsWidgets);
      expect(find.text('Correlation'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
    });

    testWidgets('shows operation badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('WRITE'), findsOneWidget);
      expect(find.text('DELETE'), findsWidgets);
    });

    testWidgets('shows success and failure icons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows pagination info', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2 entries'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      await tester.pumpWidget(createWidget(
        page: PageResponse<AuditEntryResponse>.empty(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No audit entries found.'), findsOneWidget);
    });

    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(createWidget(error: true));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load audit log'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultAuditLogProvider.overrideWith(
            (ref) => Completer<PageResponse<AuditEntryResponse>>().future,
          ),
          vaultAuditStatsProvider.overrideWith(
            (ref) => Future.value(testStats),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: VaultAuditPage()),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
