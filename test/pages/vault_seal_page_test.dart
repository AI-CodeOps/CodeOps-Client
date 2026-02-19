// Widget tests for VaultSealPage.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/pages/vault_seal_page.dart';

void main() {
  final sealedStatus = SealStatusResponse(
    status: SealStatus.sealed,
    totalShares: 5,
    threshold: 3,
    sharesProvided: 0,
    autoUnsealEnabled: false,
    sealedAt: DateTime(2026, 2, 18, 14, 30),
  );

  final unsealedStatus = SealStatusResponse(
    status: SealStatus.unsealed,
    totalShares: 5,
    threshold: 3,
    sharesProvided: 3,
    autoUnsealEnabled: false,
    unsealedAt: DateTime(2026, 2, 18, 15, 0),
  );

  final unsealingStatus = SealStatusResponse(
    status: SealStatus.unsealing,
    totalShares: 5,
    threshold: 3,
    sharesProvided: 2,
    autoUnsealEnabled: false,
  );

  final testAuditPage = PageResponse<AuditEntryResponse>(
    content: [
      AuditEntryResponse(
        id: 1,
        operation: 'READ',
        path: '/srv/db-pass',
        resourceType: 'Secret',
        success: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ],
    page: 0,
    size: 20,
    totalElements: 1,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({SealStatusResponse? status, bool sealError = false}) {
    return ProviderScope(
      overrides: [
        sealStatusProvider.overrideWith((ref) {
          if (sealError) return Future.error(Exception('Connection refused'));
          return Future.value(status ?? unsealedStatus);
        }),
        vaultAuditLogProvider.overrideWith(
          (ref) => Future.value(testAuditPage),
        ),
        vaultAuditStatsProvider.overrideWith(
          (ref) => Future.value(<String, int>{
            'totalEntries': 100,
            'failedEntries': 5,
            'readOperations': 60,
            'writeOperations': 30,
            'deleteOperations': 10,
          }),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: VaultSealPage()),
      ),
    );
  }

  group('VaultSealPage', () {
    testWidgets('shows page title and tabs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Seal & Audit'), findsOneWidget);
      expect(find.text('Seal Status'), findsOneWidget);
      expect(find.text('Audit Log'), findsOneWidget);
    });

    testWidgets('sealed state shows lock icon and share input',
        (tester) async {
      await tester.pumpWidget(createWidget(status: sealedStatus));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.textContaining('Sealed'), findsWidgets);
      expect(find.text('Submit Share'), findsOneWidget);
      expect(find.text('Enter Key Share'), findsOneWidget);
    });

    testWidgets('unsealed state shows lock_open and seal button',
        (tester) async {
      await tester.pumpWidget(createWidget(status: unsealedStatus));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.text('Vault is operational'), findsOneWidget);
      expect(find.text('Seal Vault'), findsOneWidget);
    });

    testWidgets('unsealing state shows progress', (tester) async {
      await tester.pumpWidget(createWidget(status: unsealingStatus));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.text('2 of 3 shares provided'), findsOneWidget);
      expect(find.text('Submit Share'), findsOneWidget);
    });

    testWidgets('shows seal info section', (tester) async {
      await tester.pumpWidget(createWidget(status: sealedStatus));
      await tester.pumpAndSettle();

      expect(find.text('Seal Info'), findsOneWidget);
      expect(find.text('Total Shares'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(find.text('Threshold'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('shows generate shares button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Generate New Shares'), findsOneWidget);
    });

    testWidgets('seal confirmation requires typing SEAL', (tester) async {
      await tester.pumpWidget(createWidget(status: unsealedStatus));
      await tester.pumpAndSettle();

      // Tap Seal Vault button
      await tester.tap(find.text('Seal Vault'));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Type SEAL to confirm:'), findsOneWidget);

      // Seal button should be disabled
      final sealButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Seal'),
      );
      expect(sealButton.onPressed, isNull);

      // Type SEAL
      await tester.enterText(
        find.byType(TextField).last,
        'SEAL',
      );
      await tester.pumpAndSettle();

      // Seal button should be enabled
      final sealButtonAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Seal'),
      );
      expect(sealButtonAfter.onPressed, isNotNull);
    });

    testWidgets('shows error state with retry', (tester) async {
      await tester.pumpWidget(createWidget(sealError: true));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load seal status'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('audit tab renders table', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Audit Log tab
      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      // Should show audit table
      expect(find.text('READ'), findsOneWidget);
    });

    testWidgets('audit tab shows stats panel', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Audit Log tab
      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('95.0%'), findsOneWidget);
    });
  });
}
