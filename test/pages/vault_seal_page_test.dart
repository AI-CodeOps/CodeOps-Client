// Widget tests for VaultSealPage (CVF-007).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/pages/vault_seal_page.dart';
import 'package:codeops/theme/app_theme.dart';

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
    autoUnsealEnabled: true,
    unsealedAt: DateTime(2026, 2, 18, 15, 0),
  );

  final unsealingStatus = SealStatusResponse(
    status: SealStatus.unsealing,
    totalShares: 5,
    threshold: 3,
    sharesProvided: 2,
    autoUnsealEnabled: false,
  );

  Widget createWidget({SealStatusResponse? status, bool sealError = false}) {
    return ProviderScope(
      overrides: [
        sealStatusProvider.overrideWith((ref) {
          if (sealError) return Future.error(Exception('Connection refused'));
          return Future.value(status ?? unsealedStatus);
        }),
        sealStatusPollingProvider.overrideWith((ref) {
          return const Stream<SealStatusResponse>.empty();
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: VaultSealPage()),
      ),
    );
  }

  group('VaultSealPage', () {
    testWidgets('shows Seal Management title when unsealed', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Seal Management'), findsOneWidget);
    });

    testWidgets('unsealed state shows lock_open icon and status text',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.text('Vault is Unsealed'), findsOneWidget);
    });

    testWidgets('unsealed state shows Seal Vault button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Seal Vault'), findsOneWidget);
    });

    testWidgets('unsealed state shows Generate Key Shares button',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Generate Key Shares'), findsOneWidget);
    });

    testWidgets('sealed state shows lock icon and sealed message',
        (tester) async {
      await tester.pumpWidget(createWidget(status: sealedStatus));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('Vault is Sealed'), findsOneWidget);
      expect(
        find.text('All vault operations are unavailable until unsealed.'),
        findsOneWidget,
      );
    });

    testWidgets('sealed state shows unseal form', (tester) async {
      await tester.pumpWidget(createWidget(status: sealedStatus));
      await tester.pumpAndSettle();

      expect(find.text('Unseal Progress'), findsOneWidget);
      expect(find.text('Key Share'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('sealed state hides Seal Vault and Generate buttons',
        (tester) async {
      await tester.pumpWidget(createWidget(status: sealedStatus));
      await tester.pumpAndSettle();

      expect(find.text('Seal Vault'), findsNothing);
      expect(find.text('Generate Key Shares'), findsNothing);
    });

    testWidgets('unsealing state shows progress bar and share count',
        (tester) async {
      await tester.pumpWidget(createWidget(status: unsealingStatus));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.text('Unsealing in Progress'), findsOneWidget);
      // Progress text appears in both status indicator and unseal form
      expect(find.text('2 of 3 shares provided'), findsWidgets);
    });

    testWidgets('shows seal info card with configuration', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Seal Information'), findsOneWidget);
      expect(find.text('Total Shares'), findsOneWidget);
      expect(find.text('Threshold'), findsOneWidget);
      expect(find.text('Auto-Unseal'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
    });

    testWidgets('seal dialog requires typing SEAL', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap Seal Vault button
      await tester.tap(find.text('Seal Vault'));
      await tester.pumpAndSettle();

      // Dialog appears with warning
      expect(find.text('Type SEAL to confirm:'), findsOneWidget);
      expect(
        find.textContaining('Unsealing requires 3 of 5 key shares'),
        findsOneWidget,
      );

      // Seal button should be disabled
      final sealButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Seal'),
      );
      expect(sealButton.onPressed, isNull);

      // Type SEAL
      await tester.enterText(find.byType(TextField).last, 'SEAL');
      await tester.pumpAndSettle();

      // Seal button should be enabled
      final sealButtonAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Seal'),
      );
      expect(sealButtonAfter.onPressed, isNotNull);
    });

    testWidgets('seal dialog cancel closes without action', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seal Vault'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed, page still shows unsealed
      expect(find.text('Type SEAL to confirm:'), findsNothing);
      expect(find.text('Vault is Unsealed'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(createWidget(sealError: true));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load seal status'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('loading state shows progress indicator', (tester) async {
      final widget = ProviderScope(
        overrides: [
          sealStatusProvider.overrideWith(
            (ref) => Completer<SealStatusResponse>().future,
          ),
          sealStatusPollingProvider.overrideWith((ref) {
            return const Stream<SealStatusResponse>.empty();
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: VaultSealPage()),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
