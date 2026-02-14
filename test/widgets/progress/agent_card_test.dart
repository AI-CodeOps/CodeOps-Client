import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/orchestration/progress_aggregator.dart';
import 'package:codeops/widgets/progress/agent_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AgentCard', () {
    testWidgets('shows agent name and phase', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          status: AgentProgressStatus(
            agentType: AgentType.security,
            phase: AgentPhase.running,
            elapsed: Duration(minutes: 2),
          ),
        ),
      ));

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('shows elapsed time', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          status: AgentProgressStatus(
            agentType: AgentType.codeQuality,
            phase: AgentPhase.completed,
            elapsed: Duration(minutes: 5, seconds: 30),
          ),
        ),
      ));

      expect(find.text('Code Quality'), findsOneWidget);
      expect(find.textContaining('5m'), findsOneWidget);
    });

    testWidgets('shows findings count when available', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          status: AgentProgressStatus(
            agentType: AgentType.testCoverage,
            phase: AgentPhase.completed,
            elapsed: Duration(minutes: 3),
            findingsCount: 7,
          ),
        ),
      ));

      expect(find.text('7 findings'), findsOneWidget);
    });

    testWidgets('hides findings count when null', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          status: AgentProgressStatus(
            agentType: AgentType.security,
            phase: AgentPhase.running,
            elapsed: Duration.zero,
          ),
        ),
      ));

      expect(find.textContaining('findings'), findsNothing);
    });

    testWidgets('shows last output line when running', (tester) async {
      await tester.pumpWidget(wrap(
        const AgentCard(
          status: AgentProgressStatus(
            agentType: AgentType.security,
            phase: AgentPhase.running,
            elapsed: Duration(minutes: 1),
            lastOutputLine: 'Scanning files...',
          ),
        ),
      ));

      expect(find.text('Scanning files...'), findsOneWidget);
    });
  });

  group('AgentTypeMetadata', () {
    test('has metadata for every AgentType', () {
      for (final agentType in AgentType.values) {
        expect(AgentTypeMetadata.all.containsKey(agentType), isTrue,
            reason: '$agentType should have metadata');
      }
    });

    test('all entries have non-empty fields', () {
      for (final entry in AgentTypeMetadata.all.entries) {
        expect(entry.value.displayName, isNotEmpty,
            reason: '${entry.key} displayName');
        expect(entry.value.description, isNotEmpty,
            reason: '${entry.key} description');
      }
    });
  });
}
