// Widget tests for SearchResultsTable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/search_results_table.dart';

void main() {
  final entries = [
    LogEntryResponse(
      id: 'log-1',
      sourceId: 'source-12345678',
      sourceName: 'api-service',
      level: LogLevel.error,
      message: 'NullPointerException in UserService',
      timestamp: DateTime.utc(2026, 1, 1, 12, 30, 15),
      serviceName: 'api-service',
      loggerName: 'com.codeops.UserService',
      correlationId: 'corr-abc-12345',
      teamId: 'team-1',
    ),
    LogEntryResponse(
      id: 'log-2',
      sourceId: 'source-12345678',
      sourceName: 'api-service',
      level: LogLevel.info,
      message: 'Server started on port 8090',
      timestamp: DateTime.utc(2026, 1, 1, 12, 30, 10),
      serviceName: 'api-service',
      teamId: 'team-1',
    ),
    LogEntryResponse(
      id: 'log-3',
      sourceId: 'source-87654321',
      sourceName: 'worker-service',
      level: LogLevel.warn,
      message: 'Queue backlog exceeded threshold',
      timestamp: DateTime.utc(2026, 1, 1, 12, 29, 55),
      serviceName: 'worker-service',
      teamId: 'team-1',
    ),
  ];

  final singlePage = PageResponse<LogEntryResponse>(
    content: entries,
    page: 0,
    size: 20,
    totalElements: 3,
    totalPages: 1,
    isLast: true,
  );

  final firstPage = PageResponse<LogEntryResponse>(
    content: entries,
    page: 0,
    size: 3,
    totalElements: 9,
    totalPages: 3,
    isLast: false,
  );

  final emptyPage = PageResponse<LogEntryResponse>(
    content: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
    isLast: true,
  );

  Widget createWidget(
    PageResponse<LogEntryResponse> results, {
    String? sortColumn,
    bool sortAscending = true,
    ValueChanged<String>? onSort,
    VoidCallback? onNextPage,
    VoidCallback? onPreviousPage,
  }) {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 800,
                child: SearchResultsTable(
                  results: results,
                  sortColumn: sortColumn,
                  sortAscending: sortAscending,
                  onSort: onSort,
                  onNextPage: onNextPage,
                  onPreviousPage: onPreviousPage,
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/logger/traces/:correlationId',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('Trace Page'))),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('SearchResultsTable', () {
    testWidgets('renders column headers', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      expect(find.text('Timestamp'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Logger'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('Correlation'), findsOneWidget);
    });

    testWidgets('shows results header with match count', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      expect(find.text('Results (3 matches)'), findsOneWidget);
    });

    testWidgets('renders log entry messages', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      expect(find.text('NullPointerException in UserService'), findsOneWidget);
      expect(find.text('Server started on port 8090'), findsOneWidget);
      expect(find.text('Queue backlog exceeded threshold'), findsOneWidget);
    });

    testWidgets('expands detail on row click', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      // Tap the first row.
      await tester.tap(find.text('NullPointerException in UserService'));
      await tester.pumpAndSettle();

      // Detail should show copy button.
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows pagination with Next button', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var nextCalled = false;
      await tester.pumpWidget(createWidget(
        firstPage,
        onNextPage: () => nextCalled = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Page 1 of 3'), findsOneWidget);

      await tester.tap(find.text('Next'));
      expect(nextCalled, isTrue);
    });

    testWidgets('shows empty state when no results', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(emptyPage));
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Results (0 matches)'), findsOneWidget);
    });
  });
}
