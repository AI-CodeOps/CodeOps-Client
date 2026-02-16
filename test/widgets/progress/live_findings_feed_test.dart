import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/orchestration/progress_aggregator.dart';
import 'package:codeops/widgets/progress/live_findings_feed.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SizedBox(width: 600, height: 600, child: child)),
      );

  final sampleFindings = [
    LiveFinding(
      agentType: AgentType.security,
      severity: Severity.critical,
      title: 'SQL Injection in login',
      detectedAt: DateTime.now(),
    ),
    LiveFinding(
      agentType: AgentType.codeQuality,
      severity: Severity.medium,
      title: 'Unused import statement',
      detectedAt: DateTime.now(),
    ),
  ];

  group('LiveFindingsFeed', () {
    testWidgets('shows empty message when no findings', (tester) async {
      await tester.pumpWidget(wrap(
        const LiveFindingsFeed(findings: []),
      ));

      expect(find.text('No findings yet'), findsOneWidget);
    });

    testWidgets('shows findings when not collapsed', (tester) async {
      await tester.pumpWidget(wrap(
        LiveFindingsFeed(findings: sampleFindings),
      ));

      expect(find.text('SQL Injection in login'), findsOneWidget);
      expect(find.text('Unused import statement'), findsOneWidget);
    });

    testWidgets('shows severity badges', (tester) async {
      await tester.pumpWidget(wrap(
        LiveFindingsFeed(findings: sampleFindings),
      ));

      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('collapse toggle hides findings', (tester) async {
      await tester.pumpWidget(wrap(
        LiveFindingsFeed(findings: sampleFindings),
      ));

      // Findings visible initially.
      expect(find.text('SQL Injection in login'), findsOneWidget);

      // Tap collapse toggle.
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      // Findings hidden.
      expect(find.text('SQL Injection in login'), findsNothing);
      expect(find.textContaining('Show findings'), findsOneWidget);
    });

    testWidgets('starts collapsed when initiallyCollapsed is true',
        (tester) async {
      await tester.pumpWidget(wrap(
        LiveFindingsFeed(
          findings: sampleFindings,
          initiallyCollapsed: true,
        ),
      ));

      // Findings not visible.
      expect(find.text('SQL Injection in login'), findsNothing);
      expect(find.textContaining('Show findings'), findsOneWidget);
    });

    testWidgets('expand from collapsed shows findings', (tester) async {
      await tester.pumpWidget(wrap(
        LiveFindingsFeed(
          findings: sampleFindings,
          initiallyCollapsed: true,
        ),
      ));

      // Tap expand.
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Findings now visible.
      expect(find.text('SQL Injection in login'), findsOneWidget);
    });
  });
}
