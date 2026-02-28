// Widget tests for ContainerListTable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_enums.dart';
import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/widgets/fleet/container_list_table.dart';

void main() {
  final containers = [
    FleetContainerInstance(
      id: 'c1',
      containerName: 'postgres-a1b2',
      imageName: 'postgres',
      imageTag: '16',
      status: ContainerStatus.running,
      cpuPercent: 12.0,
      memoryBytes: 256 * 1024 * 1024,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    FleetContainerInstance(
      id: 'c2',
      containerName: 'redis-c3d4',
      imageName: 'redis',
      imageTag: '7',
      status: ContainerStatus.stopped,
      startedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  /// Sets a wide viewport to avoid overflow in the desktop-oriented table.
  void useWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget wrap({
    List<FleetContainerInstance>? data,
    ContainerSortColumn sortColumn = ContainerSortColumn.name,
    bool sortAscending = true,
    Set<String>? selectedIds,
    ValueChanged<ContainerSortColumn>? onSort,
    ValueChanged<bool>? onSelectAll,
    void Function(String, bool)? onSelectRow,
    ValueChanged<FleetContainerInstance>? onRowTap,
    ValueChanged<FleetContainerInstance>? onStop,
    ValueChanged<FleetContainerInstance>? onStart,
    ValueChanged<FleetContainerInstance>? onRestart,
    ValueChanged<FleetContainerInstance>? onRemove,
    ValueChanged<FleetContainerInstance>? onViewLogs,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ContainerListTable(
            containers: data ?? containers,
            sortColumn: sortColumn,
            sortAscending: sortAscending,
            onSort: onSort ?? (_) {},
            selectedIds: selectedIds ?? {},
            onSelectAll: onSelectAll ?? (_) {},
            onSelectRow: onSelectRow ?? (_, __) {},
            onRowTap: onRowTap ?? (_) {},
            onStop: onStop ?? (_) {},
            onStart: onStart ?? (_) {},
            onRestart: onRestart ?? (_) {},
            onRemove: onRemove ?? (_) {},
            onViewLogs: onViewLogs ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('ContainerListTable', () {
    testWidgets('renders column headers', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });

    testWidgets('renders container names', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('postgres-a1b2'), findsOneWidget);
      expect(find.text('redis-c3d4'), findsOneWidget);
    });

    testWidgets('renders image:tag format', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('postgres:16'), findsOneWidget);
      expect(find.text('redis:7'), findsOneWidget);
    });

    testWidgets('renders status badges', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('renders CPU percentage', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.text('12.0%'), findsOneWidget);
    });

    testWidgets('renders checkboxes for each row plus header', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      // 2 container rows + 1 header = 3 checkboxes
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('select-all checkbox is checked when all selected',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap(selectedIds: {'c1', 'c2'}));

      final headerCheckbox =
          tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(headerCheckbox.value, isTrue);
    });

    testWidgets('select-all checkbox is unchecked when none selected',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap(selectedIds: {}));

      final headerCheckbox =
          tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(headerCheckbox.value, isFalse);
    });

    testWidgets('shows sort indicator on active column', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(
          wrap(sortColumn: ContainerSortColumn.name, sortAscending: true));

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('shows descending sort indicator', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(
          wrap(sortColumn: ContainerSortColumn.cpu, sortAscending: false));

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('calls onSort when column header tapped', (tester) async {
      useWideViewport(tester);
      ContainerSortColumn? sorted;
      await tester.pumpWidget(wrap(onSort: (c) => sorted = c));

      await tester.tap(find.text('CPU'));
      expect(sorted, ContainerSortColumn.cpu);
    });

    testWidgets('shows Stop icon for running container', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('shows Start icon for stopped container', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(wrap());

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('calls onRowTap when row is tapped', (tester) async {
      useWideViewport(tester);
      FleetContainerInstance? tapped;
      await tester.pumpWidget(wrap(onRowTap: (c) => tapped = c));

      await tester.tap(find.text('postgres-a1b2'));
      expect(tapped?.id, 'c1');
    });
  });
}
