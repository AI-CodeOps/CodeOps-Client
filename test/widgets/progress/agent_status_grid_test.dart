import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/orchestration/progress_aggregator.dart';
import 'package:codeops/widgets/progress/agent_card.dart';
import 'package:codeops/widgets/progress/agent_status_grid.dart';

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

      final progress = JobProgress(
        agentStatuses: {
          AgentType.security: const AgentProgressStatus(
            agentType: AgentType.security,
            phase: AgentPhase.running,
            elapsed: Duration(minutes: 1),
          ),
          AgentType.codeQuality: const AgentProgressStatus(
            agentType: AgentType.codeQuality,
            phase: AgentPhase.queued,
            elapsed: Duration.zero,
          ),
          AgentType.buildHealth: const AgentProgressStatus(
            agentType: AgentType.buildHealth,
            phase: AgentPhase.completed,
            elapsed: Duration(minutes: 5),
          ),
        },
        liveFindings: const [],
        completedCount: 1,
        totalCount: 3,
        elapsed: const Duration(minutes: 5),
      );

      await tester.pumpWidget(wrap(
        AgentStatusGrid(progress: progress),
      ));

      expect(find.byType(AgentCard), findsNWidgets(3));
    });

    testWidgets('renders empty grid with no agents', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const progress = JobProgress(
        agentStatuses: {},
        liveFindings: [],
        completedCount: 0,
        totalCount: 0,
        elapsed: Duration.zero,
      );

      await tester.pumpWidget(wrap(
        const AgentStatusGrid(progress: progress),
      ));

      expect(find.byType(AgentCard), findsNothing);
    });
  });
}
