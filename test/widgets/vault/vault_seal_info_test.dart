// Widget tests for VaultSealInfo (CVF-007).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_seal_info.dart';

void main() {
  Widget createWidget(SealStatusResponse status) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: VaultSealInfo(sealStatus: status),
        ),
      ),
    );
  }

  group('VaultSealInfo', () {
    testWidgets('shows Seal Information title', (tester) async {
      final status = SealStatusResponse(
        status: SealStatus.unsealed,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 3,
        autoUnsealEnabled: true,
      );

      await tester.pumpWidget(createWidget(status));
      await tester.pumpAndSettle();

      expect(find.text('Seal Information'), findsOneWidget);
    });

    testWidgets('shows configuration values', (tester) async {
      final status = SealStatusResponse(
        status: SealStatus.unsealed,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 3,
        autoUnsealEnabled: true,
        unsealedAt: DateTime(2026, 2, 23, 10, 30),
      );

      await tester.pumpWidget(createWidget(status));
      await tester.pumpAndSettle();

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Unsealed'), findsOneWidget);
      expect(find.text('Total Shares'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Threshold'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Auto-Unseal'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('Unsealed At'), findsOneWidget);
    });

    testWidgets('shows Disabled for auto-unseal when false', (tester) async {
      final status = SealStatusResponse(
        status: SealStatus.sealed,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 0,
        autoUnsealEnabled: false,
        sealedAt: DateTime(2026, 2, 23, 10, 0),
      );

      await tester.pumpWidget(createWidget(status));
      await tester.pumpAndSettle();

      expect(find.text('Disabled'), findsOneWidget);
      expect(find.text('Sealed At'), findsOneWidget);
    });
  });
}
