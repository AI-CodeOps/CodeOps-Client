// Widget tests for TeamOverview.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/providers/health_providers.dart';
import 'package:codeops/widgets/dashboard/team_overview.dart';

void main() {
  Widget createWidget({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(body: TeamOverview()),
      ),
    );
  }

  group('TeamOverview', () {
    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(createWidget(overrides: []));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders metrics values', (tester) async {
      final metrics = TeamMetrics(
        teamId: 't1',
        totalProjects: 5,
        totalJobs: 42,
        totalFindings: 18,
        averageHealthScore: 85.0,
        projectsBelowThreshold: 1,
        openCriticalFindings: 3,
      );

      await tester.pumpWidget(createWidget(overrides: [
        teamMetricsProvider.overrideWith((ref) => Future.value(metrics)),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows dash for null metrics', (tester) async {
      final metrics = TeamMetrics(teamId: 't1');

      await tester.pumpWidget(createWidget(overrides: [
        teamMetricsProvider.overrideWith((ref) => Future.value(metrics)),
      ]));
      await tester.pumpAndSettle();

      // All values should be dash (—)
      expect(find.text('\u2014'), findsNWidgets(6));
    });

    testWidgets('renders stat labels', (tester) async {
      final metrics = TeamMetrics(teamId: 't1');

      await tester.pumpWidget(createWidget(overrides: [
        teamMetricsProvider.overrideWith((ref) => Future.value(metrics)),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Total Jobs'), findsOneWidget);
      expect(find.text('Findings'), findsOneWidget);
      expect(find.text('Avg Health'), findsOneWidget);
      expect(find.text('Below Threshold'), findsOneWidget);
      expect(find.text('Open Critical'), findsOneWidget);
    });
  });
}
