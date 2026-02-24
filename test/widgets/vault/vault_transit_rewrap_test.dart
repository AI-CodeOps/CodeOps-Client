// Widget tests for VaultTransitRewrap (CVF-006).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_transit_rewrap.dart';

void main() {
  Widget createWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(
            height: 600,
            child: VaultTransitRewrap(keyName: 'my-aes-key'),
          ),
        ),
      ),
    );
  }

  group('VaultTransitRewrap', () {
    testWidgets('shows Rewrap button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ElevatedButton, 'Rewrap'),
        findsOneWidget,
      );
    });

    testWidgets('shows help text about rewrap', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('re-encrypts data with the latest key version'),
        findsOneWidget,
      );
    });

    testWidgets('shows Ciphertext to Rewrap label', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ciphertext to Rewrap'), findsOneWidget);
    });
  });
}
