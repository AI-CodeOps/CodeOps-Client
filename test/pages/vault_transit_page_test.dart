// Widget tests for VaultTransitPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/pages/vault_transit_page.dart';
import 'package:codeops/providers/vault_providers.dart';

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
  }) {
    return ProviderScope(
      overrides: [
        vaultTransitKeysProvider.overrideWith(
          (ref) => Future.value(page ?? testPage),
        ),
        vaultTransitKeyDetailProvider.overrideWith(
          (ref, id) => Future.value(testKey),
        ),
        vaultTransitStatsProvider.overrideWith(
          (ref) => Future.value(<String, int>{'total': 2}),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: VaultTransitPage())),
    );
  }

  group('VaultTransitPage', () {
    testWidgets('shows Transit header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Transit'), findsOneWidget);
    });

    testWidgets('shows two tabs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Keys'), findsOneWidget);
      expect(find.text('Encryption Playground'), findsWidgets);
    });

    testWidgets('shows New Key button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Key'), findsOneWidget);
    });

    testWidgets('shows Active Only filter chip', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active Only'), findsOneWidget);
    });

    testWidgets('shows key list items', (tester) async {
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

    testWidgets('shows pagination info', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2 keys'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
    });

    testWidgets('shows empty state when no keys', (tester) async {
      await tester.pumpWidget(createWidget(
        page: PageResponse<TransitKeyResponse>.empty(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No transit keys found'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      final widget = ProviderScope(
        overrides: [
          vaultTransitKeysProvider.overrideWith(
            (ref) =>
                Completer<PageResponse<TransitKeyResponse>>().future,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: VaultTransitPage())),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.text('Loading transit keys...'), findsOneWidget);
    });
  });
}
