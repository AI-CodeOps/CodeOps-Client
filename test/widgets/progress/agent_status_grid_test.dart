import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/agent_progress.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/providers/wizard_providers.dart';
import 'package:codeops/widgets/progress/agent_card.dart';
import 'package:codeops/widgets/progress/agent_status_grid.dart';
import 'package:codeops/widgets/progress/vera_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 1200, height: 800, child: child),
        ),
      );

  group('AgentStatusGrid', () {
    testWidgets('renders one AgentCard per agent', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const agents = [
        AgentProgress(
          agentRunId: 'r1',
          agentType: AgentType.security,
          status: AgentStatus.running,
          elapsed: Duration(minutes: 1),
        ),
        AgentProgress(
          agentRunId: 'r2',
          agentType: AgentType.codeQuality,
          status: AgentStatus.pending,
        ),
        AgentProgress(
          agentRunId: 'r3',
          agentType: AgentType.buildHealth,
          status: AgentStatus.completed,
          elapsed: Duration(minutes: 5),
        ),
      ];

      await tester.pumpWidget(wrap(
        const AgentStatusGrid(
          agents: agents,
          phase: JobExecutionPhase.running,
        ),
      ));

      expect(find.byType(AgentCard), findsNWidgets(3));
    });

    testWidgets('renders empty grid with no agents', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        const AgentStatusGrid(
          agents: [],
          phase: JobExecutionPhase.running,
        ),
      ));

      expect(find.byType(AgentCard), findsNothing);
    });

    testWidgets('shows VeraCard during consolidation phase', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const agents = [
        AgentProgress(
          agentRunId: 'r1',
          agentType: AgentType.security,
          status: AgentStatus.completed,
        ),
      ];

      await tester.pumpWidget(wrap(
        const AgentStatusGrid(
          agents: agents,
          phase: JobExecutionPhase.consolidating,
        ),
      ));

      expect(find.byType(VeraCard), findsOneWidget);
    });

    testWidgets('hides VeraCard during running phase', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const agents = [
        AgentProgress(
          agentRunId: 'r1',
          agentType: AgentType.security,
          status: AgentStatus.running,
        ),
      ];

      await tester.pumpWidget(wrap(
        const AgentStatusGrid(
          agents: agents,
          phase: JobExecutionPhase.running,
        ),
      ));

      expect(find.byType(VeraCard), findsNothing);
    });
  });
}
