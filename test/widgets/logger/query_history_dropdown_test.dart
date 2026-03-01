// Widget tests for QueryHistoryDropdown.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/query_history_dropdown.dart';

void main() {
  final history = [
    QueryHistoryResponse(
      id: 'qh-1',
      queryJson: '{"level":"ERROR"}',
      queryDsl: 'level:ERROR',
      resultCount: 42,
      executionTimeMs: 120,
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 1, 15, 10, 30),
    ),
    QueryHistoryResponse(
      id: 'qh-2',
      queryJson: '{"serviceName":"auth","query":"failed"}',
      resultCount: 7,
      executionTimeMs: 85,
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 1, 15, 9, 45),
    ),
  ];

  Widget createWidget({
    List<QueryHistoryResponse>? historyList,
    ValueChanged<QueryHistoryResponse>? onReExecute,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: QueryHistoryDropdown(
            history: historyList ?? history,
            onReExecute: onReExecute ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('QueryHistoryDropdown', () {
    testWidgets('renders button with count', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('History (2)'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsAtLeastNWidgets(1));
    });

    testWidgets('shows history items in popup', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open the dropdown.
      await tester.tap(find.text('History (2)'));
      await tester.pumpAndSettle();

      // First entry has DSL text.
      expect(find.text('level:ERROR'), findsOneWidget);
      expect(find.text('42 results'), findsOneWidget);
      expect(find.text('120ms'), findsOneWidget);

      // Second entry uses queryJson summary.
      expect(find.text('7 results'), findsOneWidget);
      expect(find.text('85ms'), findsOneWidget);
    });

    testWidgets('calls onReExecute when item selected', (tester) async {
      QueryHistoryResponse? selected;
      await tester.pumpWidget(createWidget(
        onReExecute: (h) => selected = h,
      ));
      await tester.pumpAndSettle();

      // Open and select.
      await tester.tap(find.text('History (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('level:ERROR'));
      await tester.pumpAndSettle();

      expect(selected?.id, 'qh-1');
    });
  });
}
