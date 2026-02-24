// Widget tests for VaultSealStatus (CVF-007).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_seal_status.dart';

void main() {
  Widget createWidget(SealStatusResponse status) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: VaultSealStatus(sealStatus: status),
        ),
      ),
    );
  }

  group('VaultSealStatus', () {
    testWidgets('unsealed shows lock_open icon and green text', (tester) async {
      final status = SealStatusResponse(
        status: SealStatus.unsealed,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 3,
        autoUnsealEnabled: false,
      );

      await tester.pumpWidget(createWidget(status));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.text('Vault is Unsealed'), findsOneWidget);
      expect(find.text('Vault is operational. All services available.'),
          findsOneWidget);
    });

    testWidgets('sealed shows lock icon and red text', (tester) async {
      final status = SealStatusResponse(
        status: SealStatus.sealed,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 0,
        autoUnsealEnabled: false,
      );

      await tester.pumpWidget(createWidget(status));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('Vault is Sealed'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('unsealing shows hourglass and progress', (tester) async {
      final status = SealStatusResponse(
        status: SealStatus.unsealing,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 1,
        autoUnsealEnabled: false,
      );

      await tester.pumpWidget(createWidget(status));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.text('Unsealing in Progress'), findsOneWidget);
      expect(find.text('1 of 3 shares entered.'), findsOneWidget);
      expect(find.text('1 of 3 shares provided'), findsOneWidget);
    });
  });
}
