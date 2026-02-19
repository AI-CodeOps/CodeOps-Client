// Widget tests for SecretDetailPanel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/widgets/vault/secret_detail_panel.dart';

void main() {
  final testSecret = SecretResponse(
    id: 's1',
    teamId: 't1',
    path: '/services/app/db-password',
    name: 'db-password',
    description: 'Production DB password',
    secretType: SecretType.static_,
    currentVersion: 3,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 2, 1),
    expiresAt: DateTime.now().add(const Duration(hours: 48)),
  );

  final testVersions = PageResponse<SecretVersionResponse>(
    content: [
      SecretVersionResponse(
        id: 'v1',
        secretId: 's1',
        versionNumber: 3,
        isDestroyed: false,
        changeDescription: 'Rotated password',
        createdAt: DateTime(2026, 2, 1),
      ),
      SecretVersionResponse(
        id: 'v2',
        secretId: 's1',
        versionNumber: 2,
        isDestroyed: true,
        createdAt: DateTime(2026, 1, 15),
      ),
    ],
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  Widget createWidget({
    SecretResponse? secret,
    VoidCallback? onClose,
    Map<String, String> metadata = const {'env': 'prod', 'team': 'backend'},
    PageResponse<SecretVersionResponse>? versions,
  }) {
    return ProviderScope(
      overrides: [
        vaultSecretVersionsProvider.overrideWith(
          (ref, id) => Future.value(versions ?? testVersions),
        ),
        vaultSecretMetadataProvider.overrideWith(
          (ref, id) => Future.value(metadata),
        ),
        // Override mutation providers to avoid real API calls
        vaultSecretsProvider.overrideWith(
          (ref) => Future.value(PageResponse<SecretResponse>.empty()),
        ),
        vaultSecretDetailProvider.overrideWith(
          (ref, id) => Future.value(secret ?? testSecret),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SecretDetailPanel(
            secret: secret ?? testSecret,
            onClose: onClose,
          ),
        ),
      ),
    );
  }

  group('SecretDetailPanel', () {
    testWidgets('shows secret name in header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('db-password'), findsWidgets);
    });

    testWidgets('shows secret path', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('/services/app/db-password'), findsWidgets);
    });

    testWidgets('shows action buttons', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Soft Delete'), findsOneWidget);
      expect(find.text('Permanent Delete'), findsOneWidget);
    });

    testWidgets('shows four tabs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Versions'), findsOneWidget);
      expect(find.text('Metadata'), findsOneWidget);
    });

    testWidgets('Info tab shows secret fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Info tab is shown by default
      expect(find.text('Path'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('v3'), findsWidgets);
    });

    testWidgets('Value tab shows reveal button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Value tab
      await tester.tap(find.text('Value'));
      await tester.pumpAndSettle();

      expect(find.text('Reveal Secret'), findsOneWidget);
      expect(find.text('Secret value is hidden'), findsOneWidget);
    });

    testWidgets('Versions tab shows version list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Versions tab
      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      expect(find.text('v3'), findsWidgets);
      expect(find.text('Rotated password'), findsOneWidget);
      expect(find.text('Destroyed'), findsOneWidget);
    });

    testWidgets('Metadata tab shows key-value pairs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Metadata tab
      await tester.tap(find.text('Metadata'));
      await tester.pumpAndSettle();

      expect(find.text('env'), findsOneWidget);
      expect(find.text('prod'), findsOneWidget);
      expect(find.text('team'), findsOneWidget);
      expect(find.text('backend'), findsOneWidget);
    });

    testWidgets('shows close button when onClose provided', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        createWidget(onClose: () => closed = true),
      );
      await tester.pumpAndSettle();

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      expect(closed, isTrue);
    });
  });
}
