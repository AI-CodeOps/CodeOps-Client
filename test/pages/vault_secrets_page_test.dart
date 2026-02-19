// Widget tests for VaultSecretsPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/pages/vault_secrets_page.dart';
import 'package:codeops/providers/vault_providers.dart';

void main() {
  final testSecret = SecretResponse(
    id: 's1',
    teamId: 't1',
    path: '/services/app/db-password',
    name: 'db-password',
    secretType: SecretType.static_,
    currentVersion: 3,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    lastAccessedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  final testSecret2 = SecretResponse(
    id: 's2',
    teamId: 't1',
    path: '/services/app/api-key',
    name: 'api-key',
    secretType: SecretType.dynamic_,
    currentVersion: 1,
    isActive: true,
    expiresAt: DateTime.now().add(const Duration(hours: 12)),
  );

  final testPage = PageResponse<SecretResponse>(
    content: [testSecret, testSecret2],
    page: 0,
    size: 20,
    totalElements: 2,
    totalPages: 1,
    isLast: true,
  );

  final unsealedStatus = SealStatusResponse(
    status: SealStatus.unsealed,
    totalShares: 5,
    threshold: 3,
    sharesProvided: 3,
    autoUnsealEnabled: false,
  );

  final sealedStatus = SealStatusResponse(
    status: SealStatus.sealed,
    totalShares: 5,
    threshold: 3,
    sharesProvided: 0,
    autoUnsealEnabled: false,
  );

  Widget createWidget({
    PageResponse<SecretResponse>? page,
    SealStatusResponse? sealStatus,
  }) {
    return ProviderScope(
      overrides: [
        sealStatusProvider.overrideWith(
          (ref) => Future.value(sealStatus ?? unsealedStatus),
        ),
        vaultSecretsProvider.overrideWith(
          (ref) => Future.value(page ?? testPage),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: VaultSecretsPage())),
    );
  }

  group('VaultSecretsPage', () {
    testWidgets('shows Secrets header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Secrets'), findsOneWidget);
    });

    testWidgets('shows New Secret button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Secret'), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Static'), findsWidgets);
      expect(find.text('Dynamic'), findsWidgets);
      expect(find.text('Reference'), findsWidgets);
    });

    testWidgets('shows Active filter chip', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows secret list items', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('db-password'), findsOneWidget);
      expect(find.text('api-key'), findsOneWidget);
    });

    testWidgets('shows secret paths', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('/services/app/db-password'),
        findsOneWidget,
      );
    });

    testWidgets('shows version numbers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('v3'), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
    });

    testWidgets('shows pagination info', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2 secrets'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
    });

    testWidgets('shows empty state when no secrets', (tester) async {
      await tester.pumpWidget(createWidget(
        page: PageResponse<SecretResponse>.empty(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No secrets found'), findsOneWidget);
    });

    testWidgets('shows sealed banner when vault is sealed', (tester) async {
      await tester.pumpWidget(createWidget(sealStatus: sealedStatus));
      await tester.pumpAndSettle();

      expect(
        find.text('Vault is sealed — write operations are disabled'),
        findsOneWidget,
      );
    });

    testWidgets('does not show sealed banner when unsealed', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Vault is sealed — write operations are disabled'),
        findsNothing,
      );
    });

    testWidgets('shows loading state', (tester) async {
      final widget = ProviderScope(
        overrides: [
          sealStatusProvider.overrideWith(
            (ref) => Future.value(unsealedStatus),
          ),
          vaultSecretsProvider.overrideWith(
            (ref) => Completer<PageResponse<SecretResponse>>().future,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: VaultSecretsPage())),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.text('Loading secrets...'), findsOneWidget);
    });
  });
}
