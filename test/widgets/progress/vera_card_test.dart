import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/wizard_providers.dart';
import 'package:codeops/widgets/progress/vera_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('VeraCard', () {
    testWidgets('shows Vera label', (tester) async {
      await tester.pumpWidget(wrap(
        const VeraCard(phase: JobExecutionPhase.consolidating),
      ));

      expect(find.text('Vera'), findsOneWidget);
    });

    testWidgets('shows consolidating status text', (tester) async {
      await tester.pumpWidget(wrap(
        const VeraCard(phase: JobExecutionPhase.consolidating),
      ));

      expect(find.text('Consolidating findings...'), findsOneWidget);
    });

    testWidgets('shows syncing status text', (tester) async {
      await tester.pumpWidget(wrap(
        const VeraCard(phase: JobExecutionPhase.syncing),
      ));

      expect(find.text('Syncing results to server...'), findsOneWidget);
    });

    testWidgets('shows complete status text', (tester) async {
      await tester.pumpWidget(wrap(
        const VeraCard(phase: JobExecutionPhase.complete),
      ));

      expect(find.text('Analysis complete'), findsOneWidget);
    });

    testWidgets('shows spinner during consolidation', (tester) async {
      await tester.pumpWidget(wrap(
        const VeraCard(phase: JobExecutionPhase.consolidating),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows check icon when complete', (tester) async {
      await tester.pumpWidget(wrap(
        const VeraCard(phase: JobExecutionPhase.complete),
      ));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows waiting text during running phase', (tester) async {
      await tester.pumpWidget(wrap(
        const VeraCard(phase: JobExecutionPhase.running),
      ));

      expect(find.text('Waiting for agents to finish'), findsOneWidget);
    });
  });
}
