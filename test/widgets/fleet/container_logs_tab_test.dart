// Widget tests for ContainerLogsTab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/widgets/fleet/container_logs_tab.dart';

void main() {
  final logs = [
    FleetContainerLog(
      id: 'l1',
      stream: 'stdout',
      content: 'Server started on port 5432',
      timestamp: DateTime(2026, 2, 27, 10, 0, 1),
      containerId: 'c1',
    ),
    FleetContainerLog(
      id: 'l2',
      stream: 'stderr',
      content: 'WARNING: connection refused',
      timestamp: DateTime(2026, 2, 27, 10, 0, 2),
      containerId: 'c1',
    ),
    FleetContainerLog(
      id: 'l3',
      stream: 'stdout',
      content: 'Database ready',
      timestamp: DateTime(2026, 2, 27, 10, 0, 3),
      containerId: 'c1',
    ),
  ];

  void useWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget wrap({
    List<FleetContainerLog>? data,
    ValueChanged<int>? onTailChanged,
    VoidCallback? onRefresh,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ContainerLogsTab(
          logs: data ?? logs,
          onTailChanged: onTailChanged ?? (_) {},
          onRefresh: onRefresh ?? () {},
        ),
      ),
    );
  }

  group('ContainerLogsTab', () {
    testWidgets('renders log entries', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Server started on port 5432'), findsOneWidget);
      expect(find.text('WARNING: connection refused'), findsOneWidget);
      expect(find.text('Database ready'), findsOneWidget);
    });

    testWidgets('renders timestamps', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('10:00:01.000'), findsOneWidget);
      expect(find.text('10:00:02.000'), findsOneWidget);
    });

    testWidgets('shows empty state when no logs', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap(data: []));

      expect(find.text('No logs available'), findsOneWidget);
    });

    testWidgets('renders tail dropdown', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Tail:'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders refresh button', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onRefresh when refresh tapped', (tester) async {
      useWideViewport(tester);
      var called = false;
      await tester.pumpWidget(wrap(onRefresh: () => called = true));

      await tester.tap(find.byIcon(Icons.refresh));
      expect(called, isTrue);
    });

    testWidgets('renders auto-scroll toggle', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.byIcon(Icons.vertical_align_bottom), findsOneWidget);
    });

    testWidgets('search filters log entries', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      // Type search query
      await tester.enterText(find.byType(TextField), 'WARNING');
      await tester.pumpAndSettle();

      // Only the matching log should be visible
      expect(find.text('WARNING: connection refused'), findsOneWidget);
      expect(find.text('Server started on port 5432'), findsNothing);
      expect(find.text('Database ready'), findsNothing);
    });
  });
}
