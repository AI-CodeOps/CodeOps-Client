import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/project.dart';
import 'package:codeops/providers/agent_providers.dart';
import 'package:codeops/providers/wizard_providers.dart';
import 'package:codeops/services/platform/claude_code_detector.dart';
import 'package:codeops/widgets/wizard/review_step.dart';

void main() {
  Widget createWidget({
    Project? project,
    String? branch,
    Set<AgentType> selectedAgents = const {},
    JobConfig config = const JobConfig(),
    Widget? additionalInfo,
    ClaudeCodeStatus claudeStatus = ClaudeCodeStatus.available,
  }) {
    return ProviderScope(
      overrides: [
        claudeCodeStatusProvider
            .overrideWith((ref) => Future.value(claudeStatus)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: ReviewStep(
              project: project,
              branch: branch,
              selectedAgents: selectedAgents,
              config: config,
              additionalInfo: additionalInfo,
            ),
          ),
        ),
      ),
    );
  }

  group('ReviewStep', () {
    testWidgets('shows title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Review & Launch'), findsOneWidget);
    });

    testWidgets('shows source card with project and branch', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(
        project: const Project(
          id: 'p1',
          teamId: 't1',
          name: 'Frontend App',
          techStack: 'React',
        ),
        branch: 'main',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Frontend App'), findsOneWidget);
      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('shows agents card with count', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(
        selectedAgents: {AgentType.security, AgentType.codeQuality},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('2 of 16'), findsOneWidget);
    });

    testWidgets('shows configuration card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(
        config: const JobConfig(maxConcurrentAgents: 4),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Configuration'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // concurrent agents value
    });

    testWidgets('shows estimated time', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(
        selectedAgents: {AgentType.security, AgentType.codeQuality},
        config: const JobConfig(
          maxConcurrentAgents: 2,
          agentTimeoutMinutes: 15,
        ),
      ));
      await tester.pumpAndSettle();

      // 2 agents / 2 concurrent = 1 batch, 15/3 = 5 min
      expect(find.textContaining('Estimated time'), findsOneWidget);
    });

    testWidgets('shows Claude Code available status', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(
        claudeStatus: ClaudeCodeStatus.available,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Claude Code CLI detected'), findsOneWidget);
    });

    testWidgets('shows Claude Code not installed warning', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget(
        claudeStatus: ClaudeCodeStatus.notInstalled,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please install it'), findsOneWidget);
    });
  });
}
