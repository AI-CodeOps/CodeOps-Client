// Widget tests for ContainerListToolbar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/fleet/container_list_toolbar.dart';

void main() {
  Widget wrap({
    ContainerStatusFilter filter = ContainerStatusFilter.all,
    ValueChanged<ContainerStatusFilter>? onFilterChanged,
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onRefresh,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ContainerListToolbar(
          filter: filter,
          onFilterChanged: onFilterChanged ?? (_) {},
          onSearchChanged: onSearchChanged ?? (_) {},
          onRefresh: onRefresh ?? () {},
        ),
      ),
    );
  }

  group('ContainerListToolbar', () {
    testWidgets('renders filter dropdown with All selected', (tester) async {
      await tester.pumpWidget(wrap());
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      await tester.pumpWidget(wrap());
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders refresh button', (tester) async {
      await tester.pumpWidget(wrap());
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onRefresh when refresh button tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(onRefresh: () => called = true));

      await tester.tap(find.byIcon(Icons.refresh));
      expect(called, isTrue);
    });

    testWidgets('dropdown shows all filter options', (tester) async {
      await tester.pumpWidget(wrap());

      // Tap the dropdown
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // All options should be visible in the dropdown menu
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('Unhealthy'), findsOneWidget);
    });

    testWidgets('calls onFilterChanged when filter selected', (tester) async {
      ContainerStatusFilter? selected;
      await tester.pumpWidget(
        wrap(onFilterChanged: (f) => selected = f),
      );

      // Open dropdown
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Select Running
      await tester.tap(find.text('Running').last);
      await tester.pumpAndSettle();

      expect(selected, ContainerStatusFilter.running);
    });

    testWidgets('shows Running label when filter is running', (tester) async {
      await tester.pumpWidget(wrap(filter: ContainerStatusFilter.running));
      expect(find.text('Running'), findsOneWidget);
    });
  });
}
