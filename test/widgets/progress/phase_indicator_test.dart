import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/wizard_providers.dart';
import 'package:codeops/widgets/progress/phase_indicator.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('PhaseIndicator', () {
    testWidgets('renders all 6 phase labels', (tester) async {
      await tester.pumpWidget(wrap(
        const PhaseIndicator(currentPhase: JobExecutionPhase.running),
      ));
      // Use pump() instead of pumpAndSettle() because PhaseIndicator
      // has a repeating pulse animation.
      await tester.pump();

      expect(find.text('Creating'), findsOneWidget);
      expect(find.text('Dispatching'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Consolidating'), findsOneWidget);
      expect(find.text('Syncing'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('renders for creating phase', (tester) async {
      await tester.pumpWidget(wrap(
        const PhaseIndicator(currentPhase: JobExecutionPhase.creating),
      ));
      await tester.pump();

      expect(find.text('Creating'), findsOneWidget);
    });

    testWidgets('renders for complete phase', (tester) async {
      await tester.pumpWidget(wrap(
        const PhaseIndicator(currentPhase: JobExecutionPhase.complete),
      ));
      await tester.pump();

      // Should show check icons for completed steps
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('renders for failed phase', (tester) async {
      await tester.pumpWidget(wrap(
        const PhaseIndicator(currentPhase: JobExecutionPhase.failed),
      ));
      await tester.pump();

      expect(find.text('Creating'), findsOneWidget);
    });
  });
}
