// Widget tests for VaultTransitPage (CVF-006).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/pages/vault_transit_page.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';

void main() {
  final testKey = TransitKeyResponse(
    id: 'k1',
    teamId: 't1',
    name: 'my-aes-key',
    description: 'Primary encryption key',
    currentVersion: 3,
    minDecryptionVersion: 1,
    algorithm: 'AES-256-GCM',
    isDeletable: true,
    isExportable: false,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final testKey2 = TransitKeyResponse(
    id: 'k2',
    teamId: 't1',
    name: 'backup-key',
    currentVersion: 1,
    minDecryptionVersion: 1,
    algorithm: 'AES-256-GCM',
    isDeletable: false,
    isExportable: true,
    isActive: false,
    createdAt: DateTime(2026, 1, 15),
  );

  final testPage = PageResponse<TransitKeyResponse>(
    content: [testKey, testKey2],
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    PageResponse<TransitKeyResponse>? page,
    String? selectedKeyId,
  }) {
    return ProviderScope(
      overrides: [
        vaultTransitKeysProvider.overrideWith(
          (ref) => Future.value(page ?? testPage),
        ),
        vaultTransitStatsProvider.overrideWith(
          (ref) => Future.value(<String, int>{
            'total': 2,
            'active': 1,
            'totalVersions': 4,
          }),
        ),
        if (selectedKeyId != null)
          selectedVaultTransitKeyIdProvider
              .overrideWith((ref) => selectedKeyId),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: VaultTransitPage()),
      ),
    );
  }

  group('VaultTransitPage — header', () {
    testWidgets('shows Transit title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Transit'), findsOneWidget);
    });

    testWidgets('shows stats chips', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Keys'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Versions'), findsOneWidget);
    });
  });

  group('VaultTransitPage — key list', () {
    testWidgets('shows key names', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('my-aes-key'), findsOneWidget);
      expect(find.text('backup-key'), findsOneWidget);
    });

    testWidgets('shows algorithm labels', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('AES-256-GCM'), findsWidgets);
    });

    testWidgets('shows version badges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('v3'), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
    });

    testWidgets('shows New Key button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Key'), findsOneWidget);
    });

    testWidgets('shows Active Only filter', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active Only'), findsOneWidget);
    });

    testWidgets('shows pagination', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2 keys'), findsOneWidget);
    });

    testWidgets('shows empty state when no keys', (tester) async {
      await tester.pumpWidget(createWidget(
        page: PageResponse<TransitKeyResponse>.empty(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No transit keys'), findsOneWidget);
    });
  });

  group('VaultTransitPage — operations panel', () {
    testWidgets('shows select key prompt when none selected', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select a key to begin'), findsOneWidget);
    });

    testWidgets('shows operation tabs when key selected', (tester) async {
      await tester.pumpWidget(createWidget(selectedKeyId: 'k1'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Encrypt'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Decrypt'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Rewrap'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Data Key'), findsOneWidget);
    });

    testWidgets('shows key info bar when key selected', (tester) async {
      await tester.pumpWidget(createWidget(selectedKeyId: 'k1'));
      await tester.pumpAndSettle();

      // Key name appears in both the list and the info bar
      expect(find.text('my-aes-key'), findsWidgets);
      expect(find.text('Rotate'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('hides Delete button when key not deletable',
        (tester) async {
      await tester.pumpWidget(createWidget(selectedKeyId: 'k2'));
      await tester.pumpAndSettle();

      expect(find.text('Rotate'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      // backup-key isDeletable=false, so no Delete button
      // Note: only 2 action buttons should be present (Rotate + Edit)
      expect(
        find.widgetWithText(OutlinedButton, 'Delete'),
        findsNothing,
      );
    });

    testWidgets('shows encrypt input on Encrypt tab', (tester) async {
      await tester.pumpWidget(createWidget(selectedKeyId: 'k1'));
      await tester.pumpAndSettle();

      expect(find.text('Plaintext'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Encrypt'),
        findsOneWidget,
      );
    });
  });

  group('VaultTransitPage — loading', () {
    testWidgets('shows loading indicator', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultTransitKeysProvider.overrideWith(
            (ref) =>
                Completer<PageResponse<TransitKeyResponse>>().future,
          ),
          vaultTransitStatsProvider.overrideWith(
            (ref) => Completer<Map<String, int>>().future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: VaultTransitPage()),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
