// Widget tests for EncryptionPlayground.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/widgets/vault/encryption_playground.dart';

void main() {
  final testKey = TransitKeyResponse(
    id: 'k1',
    teamId: 't1',
    name: 'test-key',
    currentVersion: 2,
    minDecryptionVersion: 1,
    algorithm: 'AES-256-GCM',
    isDeletable: true,
    isExportable: false,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final testPage = PageResponse<TransitKeyResponse>(
    content: [testKey],
    page: 0,
    size: 20,
    totalElements: 1,
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
      ],
      child: const MaterialApp(
        home: Scaffold(body: EncryptionPlayground()),
      ),
    );
  }

  group('EncryptionPlayground', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Encryption Playground'), findsOneWidget);
    });

    testWidgets('shows key selector with key name', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Transit Key'), findsOneWidget);
    });

    testWidgets('shows four operation tabs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Encrypt'), findsWidgets);
      expect(find.text('Decrypt'), findsWidgets);
      expect(find.text('Rewrap'), findsWidgets);
      expect(find.text('Data Key'), findsWidgets);
    });

    testWidgets('shows encrypt input on Encrypt tab', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Plaintext (Base64-encoded)'),
        findsOneWidget,
      );
      expect(
        find.text('Enter plaintext to encrypt...'),
        findsOneWidget,
      );
    });

    testWidgets('shows no keys message when empty', (tester) async {
      await tester.pumpWidget(createWidget(
        page: PageResponse<TransitKeyResponse>.empty(),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('No transit keys available. Create a key first.'),
        findsOneWidget,
      );
    });

    testWidgets('Data Key tab shows generate button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Data Key tab
      await tester.tap(find.text('Data Key'));
      await tester.pumpAndSettle();

      expect(find.text('Generate Data Key'), findsWidgets);
    });
  });
}
