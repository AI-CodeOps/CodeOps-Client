// Widget tests for VaultTransitDecrypt (CVF-006).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_transit_decrypt.dart';

void main() {
  Widget createWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(
            height: 600,
            child: VaultTransitDecrypt(keyName: 'my-aes-key'),
          ),
        ),
      ),
    );
  }

  group('VaultTransitDecrypt', () {
    testWidgets('shows Ciphertext label', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ciphertext'), findsOneWidget);
    });

    testWidgets('shows Decrypt button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ElevatedButton, 'Decrypt'),
        findsOneWidget,
      );
    });

    testWidgets('shows text input field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
