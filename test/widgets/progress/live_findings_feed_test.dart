import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/orchestration/progress_aggregator.dart';
import 'package:codeops/widgets/progress/live_findings_feed.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 400, child: child),
        ),
      );

  group('LiveFindingsFeed', () {
    testWidgets('shows empty state with no findings', (tester) async {
      await tester.pumpWidget(wrap(
        const LiveFindingsFeed(findings: []),
      ));

      expect(find.text('No findings yet'), findsOneWidget);
    });

    testWidgets('renders finding titles', (tester) async {
      final findings = [
        LiveFinding(
          agentType: AgentType.security,
          severity: Severity.high,
          title: 'SQL injection detected',
          detectedAt: DateTime.now(),
        ),
        LiveFinding(
          agentType: AgentType.codeQuality,
          severity: Severity.medium,
          title: 'Complex method',
          detectedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(wrap(
        LiveFindingsFeed(findings: findings),
      ));

      expect(find.text('SQL injection detected'), findsOneWidget);
      expect(find.text('Complex method'), findsOneWidget);
    });

    testWidgets('shows severity badges', (tester) async {
      final findings = [
        LiveFinding(
          agentType: AgentType.security,
          severity: Severity.critical,
          title: 'Critical issue',
          detectedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(wrap(
        LiveFindingsFeed(findings: findings),
      ));

      expect(find.text('Critical'), findsOneWidget);
    });
  });
}
