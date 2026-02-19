// Widget tests for SharesDisplay.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/vault/shares_display.dart';

void main() {
  final testShares = [
    'AaGVsbG8gd29ybGQ=',
    'Bc2VjcmV0IGtleQ==',
    'CnNoYXJlIHRocmVl',
  ];

  Widget createWidget({List<String>? shares}) {
    return MaterialApp(
      home: Scaffold(
        body: SharesDisplay(
          shares: shares ?? testShares,
          totalShares: 5,
          threshold: 3,
          onDismiss: () {},
        ),
      ),
    );
  }

  group('SharesDisplay', () {
    testWidgets('shows correct number of shares', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Share 1'), findsOneWidget);
      expect(find.text('Share 2'), findsOneWidget);
      expect(find.text('Share 3'), findsOneWidget);
    });

    testWidgets('shows share values', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('AaGVsbG8gd29ybGQ='), findsOneWidget);
      expect(find.text('Bc2VjcmV0IGtleQ=='), findsOneWidget);
      expect(find.text('CnNoYXJlIHRocmVl'), findsOneWidget);
    });

    testWidgets('shows warning text', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(
        find.textContaining('will NOT be shown again'),
        findsOneWidget,
      );
    });

    testWidgets('shows share info', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(
        find.textContaining('Total Shares: 5'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Threshold: 3'),
        findsOneWidget,
      );
    });

    testWidgets('shows Copy All button', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Copy All'), findsOneWidget);
    });

    testWidgets('shows Dismiss button', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('shows individual copy buttons', (tester) async {
      await tester.pumpWidget(createWidget());

      // 3 individual copy buttons + 1 Copy All button icon
      expect(find.byIcon(Icons.copy), findsNWidgets(3));
    });
  });
}
