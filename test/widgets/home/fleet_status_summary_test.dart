// Widget tests for FleetStatusSummary.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/providers/fleet_providers.dart' hide selectedTeamIdProvider;
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/widgets/home/fleet_status_summary.dart';

void main() {
  Widget createWidget({
    String? teamId = 'team-1',
    FleetHealthSummary? summary,
  }) {
    final defaultSummary = summary ??
        const FleetHealthSummary(
          totalContainers: 8,
          runningContainers: 5,
          stoppedContainers: 2,
          unhealthyContainers: 1,
          totalCpuPercent: 42.5,
          totalMemoryBytes: 3221225472, // 3GB
        );

    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => teamId),
        if (teamId != null)
          fleetHealthSummaryProvider(teamId).overrideWith(
            (ref) => Future.value(defaultSummary),
          ),
      ],
      child: const MaterialApp(home: Scaffold(body: FleetStatusSummary())),
    );
  }

  group('FleetStatusSummary', () {
    testWidgets('renders Fleet Status title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Fleet Status'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('shows container counts', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget); // running
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // stopped
      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('1'), findsAtLeastNWidgets(1)); // unhealthy
      expect(find.text('Unhealthy'), findsOneWidget);
    });

    testWidgets('shows CPU and memory gauges', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('42.5%'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('3.0GB'), findsOneWidget);
    });

    testWidgets('shows unhealthy alert when containers unhealthy',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('1 unhealthy container'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('shows no team selected when teamId is null', (tester) async {
      await tester.pumpWidget(createWidget(teamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('hides unhealthy alert when all healthy', (tester) async {
      await tester.pumpWidget(createWidget(
        summary: const FleetHealthSummary(
          totalContainers: 5,
          runningContainers: 5,
          stoppedContainers: 0,
          unhealthyContainers: 0,
          totalCpuPercent: 20.0,
          totalMemoryBytes: 1073741824,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });
}
