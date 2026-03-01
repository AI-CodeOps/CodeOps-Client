// Widget tests for DataBrowserToolbar.
//
// Verifies toolbar rendering: pagination display, page size dropdown,
// refresh button, filter toggle, export button, and row count display.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/datalens/data_browser_toolbar.dart';

Widget _createWidget({
  int currentPage = 0,
  int totalRows = 2340,
  int pageSize = 100,
  bool filterVisible = false,
  String? sortColumn,
  bool sortAscending = true,
  VoidCallback? onPrevious,
  VoidCallback? onNext,
}) {
  return MaterialApp(
    home: Scaffold(
      body: DataBrowserToolbar(
        currentPage: currentPage,
        totalRows: totalRows,
        pageSize: pageSize,
        filterVisible: filterVisible,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
        onPrevious: onPrevious,
        onNext: onNext,
        onPageSizeChanged: (_) {},
        onRefresh: () {},
        onFilterToggle: () {},
        onExport: () {},
      ),
    ),
  );
}

void main() {
  group('DataBrowserToolbar', () {
    testWidgets('shows pagination', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Page 1 of 24'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows page size dropdown', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Rows:'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows export button', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('shows row count', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2,340 rows'), findsOneWidget);
    });
  });
}
