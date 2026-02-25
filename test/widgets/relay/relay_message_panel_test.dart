/// Tests for [RelayMessagePanel] — center channel message panel.
///
/// Verifies channel header rendering, placeholder message area,
/// disabled composer, and channel name display.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/relay/relay_message_panel.dart';

Widget _createPanel({String channelId = 'ch-123'}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: RelayMessagePanel(channelId: channelId),
      ),
    ),
  );
}

void main() {
  group('RelayMessagePanel', () {
    testWidgets('renders channel header', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('# channel'), findsOneWidget);
    });

    testWidgets('renders placeholder message area', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('Messages will appear here'), findsOneWidget);
    });

    testWidgets('renders disabled composer', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('shows channel name in header', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.text('# channel'), findsOneWidget);
      expect(find.text('Channel topic will appear here'), findsOneWidget);
    });

    testWidgets('renders header action buttons', (tester) async {
      await tester.pumpWidget(_createPanel());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });
}
