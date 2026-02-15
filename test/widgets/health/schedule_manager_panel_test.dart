// Widget tests for ScheduleManagerPanel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/providers/health_providers.dart';
import 'package:codeops/widgets/health/schedule_manager_panel.dart';

void main() {
  const testSchedule = HealthSchedule(
    id: 'sched-1',
    projectId: 'proj-1',
    scheduleType: ScheduleType.daily,
    cronExpression: '0 0 * * *',
    isActive: true,
  );

  Widget createWidget({
    List<HealthSchedule>? schedules,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        healthSchedulesProvider.overrideWith(
          (ref, arg) => Future.value(schedules ?? [testSchedule]),
        ),
        ...overrides,
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScheduleManagerPanel(projectId: 'proj-1'),
          ),
        ),
      ),
    );
  }

  group('ScheduleManagerPanel', () {
    testWidgets('renders Health Schedules heading', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Health Schedules'), findsOneWidget);
    });

    testWidgets('shows New Schedule button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Schedule'), findsOneWidget);
    });

    testWidgets('shows schedule rows when data exists', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('0 0 * * *'), findsOneWidget);
    });

    testWidgets('shows empty message when no schedules', (tester) async {
      await tester.pumpWidget(createWidget(schedules: []));
      await tester.pumpAndSettle();

      expect(find.text('No schedules configured.'), findsOneWidget);
    });
  });
}
