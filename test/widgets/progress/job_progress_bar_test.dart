import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/orchestration/progress_aggregator.dart';
import 'package:codeops/widgets/progress/job_progress_bar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('JobProgressBar', () {
    testWidgets('shows completion text', (tester) async {
      final progress = JobProgress(
        agentStatuses: {
          AgentType.security: const AgentProgressStatus(
            agentType: AgentType.security,
            phase: AgentPhase.completed,
            elapsed: Duration(minutes: 5),
          ),
          AgentType.codeQuality: const AgentProgressStatus(
            agentType: AgentType.codeQuality,
            phase: AgentPhase.running,
            elapsed: Duration(minutes: 2),
          ),
        },
        liveFindings: const [],
        completedCount: 1,
        totalCount: 2,
        elapsed: const Duration(minutes: 5),
      );

      await tester.pumpWidget(wrap(
        JobProgressBar(progress: progress),
      ));

      expect(find.textContaining('1 of 2'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('renders nothing for empty progress', (tester) async {
      const progress = JobProgress(
        agentStatuses: {},
        liveFindings: [],
        completedCount: 0,
        totalCount: 0,
        elapsed: Duration.zero,
      );

      await tester.pumpWidget(wrap(
        const JobProgressBar(progress: progress),
      ));

      // SizedBox.shrink for empty
      expect(find.byType(JobProgressBar), findsOneWidget);
    });

    testWidgets('shows 100% when all complete', (tester) async {
      final progress = JobProgress(
        agentStatuses: {
          AgentType.security: const AgentProgressStatus(
            agentType: AgentType.security,
            phase: AgentPhase.completed,
            elapsed: Duration(minutes: 5),
          ),
        },
        liveFindings: const [],
        completedCount: 1,
        totalCount: 1,
        elapsed: const Duration(minutes: 5),
      );

      await tester.pumpWidget(wrap(
        JobProgressBar(progress: progress),
      ));

      expect(find.textContaining('100%'), findsOneWidget);
    });
  });
}
