// Widget tests for VaultTransitKeyDialog (CVF-006).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_transit_key_dialog.dart';

void main() {
  final existingKey = TransitKeyResponse(
    id: 'k1',
    teamId: 't1',
    name: 'my-aes-key',
    description: 'Primary key',
    currentVersion: 3,
    minDecryptionVersion: 1,
    algorithm: 'AES-256-GCM',
    isDeletable: true,
    isExportable: false,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createWidget({TransitKeyResponse? key}) {
    return ProviderScope(
      overrides: [
        vaultTransitKeysProvider.overrideWith(
          (ref) => Future.value(PageResponse<TransitKeyResponse>.empty()),
        ),
        vaultTransitStatsProvider.overrideWith(
          (ref) => Future.value(<String, int>{}),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ProviderScope(
                  parent: ProviderScope.containerOf(context),
                  child: VaultTransitKeyDialog(existingKey: key),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('VaultTransitKeyDialog — create mode', () {
    testWidgets('shows Create Transit Key title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create Transit Key'), findsOneWidget);
    });

    testWidgets('shows name, description, and algorithm fields',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Algorithm'), findsOneWidget);
    });

    testWidgets('shows Deletable and Exportable checkboxes',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Deletable'), findsOneWidget);
      expect(find.text('Exportable'), findsOneWidget);
    });

    testWidgets('shows Create and Cancel buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel closes dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Create Transit Key'), findsNothing);
    });
  });

  group('VaultTransitKeyDialog — edit mode', () {
    testWidgets('shows Edit Transit Key title', (tester) async {
      await tester.pumpWidget(createWidget(key: existingKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transit Key'), findsOneWidget);
    });

    testWidgets('shows Min Decryption Version field', (tester) async {
      await tester.pumpWidget(createWidget(key: existingKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Min Decryption Version'), findsOneWidget);
    });

    testWidgets('shows Active checkbox in edit mode', (tester) async {
      await tester.pumpWidget(createWidget(key: existingKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows Save button in edit mode', (tester) async {
      await tester.pumpWidget(createWidget(key: existingKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });
  });
}
