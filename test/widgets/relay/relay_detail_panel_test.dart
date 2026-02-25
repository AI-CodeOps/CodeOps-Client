/// Tests for [RelayDetailPanel] — right thread/detail panel.
///
/// Verifies header rendering, close button callback, and
/// placeholder content display.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/relay/relay_detail_panel.dart';

Widget _createPanel({VoidCallback? onClose}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 340,
          child: RelayDetailPanel(onClose: onClose ?? () {}),
        ),
      ),
    ),
  );
}

void main() {
  group('RelayDetailPanel', () {
    testWidgets('renders header with Thread title', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Thread'), findsOneWidget);
    });

    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button calls onClose callback', (tester) async {
      bool closed = false;
      await tester.pumpWidget(_createPanel(onClose: () => closed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('renders placeholder content', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Thread content will appear here'), findsOneWidget);
    });
  });
}
