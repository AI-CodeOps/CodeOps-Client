// Widget tests for LoadingOverlay.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/shared/loading_overlay.dart';

void main() {
  group('LoadingOverlay', () {
    testWidgets('renders spinner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Stack(children: [LoadingOverlay()])),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(children: [LoadingOverlay(message: 'Loading...')]),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('hides message when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Stack(children: [LoadingOverlay()])),
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('absorbs pointer events', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Stack(children: [LoadingOverlay()])),
      );

      // Find the AbsorbPointer that is absorbing (ours)
      final absorbers = tester.widgetList<AbsorbPointer>(
        find.byType(AbsorbPointer),
      );
      final hasAbsorbing = absorbers.any((a) => a.absorbing);
      expect(hasAbsorbing, isTrue);
    });
  });
}
