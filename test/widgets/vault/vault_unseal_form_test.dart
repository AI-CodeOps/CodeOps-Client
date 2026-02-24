// Widget tests for VaultUnsealForm (CVF-007).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_unseal_form.dart';

void main() {
  Widget createWidget(SealStatusResponse status) {
    return ProviderScope(
      overrides: [
        sealStatusProvider.overrideWith(
          (ref) => Future.value(status),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: VaultUnsealForm(sealStatus: status),
          ),
        ),
      ),
    );
  }

  group('VaultUnsealForm', () {
    testWidgets('shows Unseal Progress title and input', (tester) async {
      final status = SealStatusResponse(
        status: SealStatus.sealed,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 0,
        autoUnsealEnabled: false,
      );

      await tester.pumpWidget(createWidget(status));
      await tester.pumpAndSettle();

      expect(find.text('Unseal Progress'), findsOneWidget);
      expect(find.text('Key Share'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('shows progress bar with share count', (tester) async {
      final status = SealStatusResponse(
        status: SealStatus.unsealing,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 2,
        autoUnsealEnabled: false,
      );

      await tester.pumpWidget(createWidget(status));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 shares provided'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success message when unsealed', (tester) async {
      final sealed = SealStatusResponse(
        status: SealStatus.sealed,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 0,
        autoUnsealEnabled: false,
      );

      final unsealed = SealStatusResponse(
        status: SealStatus.unsealed,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 3,
        autoUnsealEnabled: false,
      );

      // Start with sealed
      final key = GlobalKey();
      Widget buildWidget(SealStatusResponse s) {
        return ProviderScope(
          overrides: [
            sealStatusProvider.overrideWith((ref) => Future.value(s)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: VaultUnsealForm(key: key, sealStatus: s),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWidget(sealed));
      await tester.pumpAndSettle();
      expect(find.text('Unseal Progress'), findsOneWidget);

      // Transition to unsealed
      await tester.pumpWidget(buildWidget(unsealed));
      await tester.pumpAndSettle();

      expect(find.text('Vault successfully unsealed!'), findsOneWidget);
    });
  });
}
