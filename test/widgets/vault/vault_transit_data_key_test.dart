// Widget tests for VaultTransitDataKey (CVF-006).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/vault_transit_data_key.dart';

void main() {
  Widget createWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(
            height: 600,
            child: VaultTransitDataKey(keyName: 'my-aes-key'),
          ),
        ),
      ),
    );
  }

  group('VaultTransitDataKey', () {
    testWidgets('shows Generate Data Encryption Key title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Generate Data Encryption Key'),
        findsOneWidget,
      );
    });

    testWidgets('shows Generate Data Key button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ElevatedButton, 'Generate Data Key'),
        findsOneWidget,
      );
    });

    testWidgets('shows envelope encryption description', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('envelope encryption'),
        findsOneWidget,
      );
    });
  });
}
