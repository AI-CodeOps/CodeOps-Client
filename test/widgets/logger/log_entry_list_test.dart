// Widget tests for LogEntryList.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/log_entry_list.dart';

void main() {
  final entries = [
    LogEntryResponse(
      id: 'log-1',
      sourceId: 's1',
      sourceName: 'api-service',
      level: LogLevel.error,
      message: 'NullPointerException in UserService',
      timestamp: DateTime.utc(2026, 1, 1, 12, 30, 15),
      serviceName: 'api-service',
      teamId: 'team-1',
    ),
    LogEntryResponse(
      id: 'log-2',
      sourceId: 's1',
      sourceName: 'api-service',
      level: LogLevel.info,
      message: 'Server started on port 8090',
      timestamp: DateTime.utc(2026, 1, 1, 12, 30, 10),
      serviceName: 'api-service',
      teamId: 'team-1',
    ),
    LogEntryResponse(
      id: 'log-3',
      sourceId: 's2',
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

  final middlePage = PageResponse<LogEntryResponse>(
    content: entries,
    page: 1,
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
    PageResponse<LogEntryResponse> logs, {
    bool autoScroll = false,
    VoidCallback? onLoadMore,
    VoidCallback? onLoadPrevious,
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
                child: LogEntryList(
                  logs: logs,
                  autoScroll: autoScroll,
                  onLoadMore: onLoadMore,
                  onLoadPrevious: onLoadPrevious,
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

  group('LogEntryList', () {
    testWidgets('renders log entries with messages', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      expect(find.text('NullPointerException in UserService'), findsOneWidget);
      expect(find.text('Server started on port 8090'), findsOneWidget);
      expect(find.text('Queue backlog exceeded threshold'), findsOneWidget);
    });

    testWidgets('shows service names in rows', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      expect(find.text('api-service'), findsAtLeastNWidgets(2));
      expect(find.text('worker-service'), findsOneWidget);
    });

    testWidgets('shows level labels', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('INFO'), findsOneWidget);
      expect(find.text('WARN'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when no entries', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(emptyPage));
      await tester.pumpAndSettle();

      expect(find.text('No log entries found'), findsOneWidget);
      expect(find.text('0 entries'), findsOneWidget);
    });

    testWidgets('shows status bar with entry count', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing 1'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
    });

    testWidgets('shows Load More button when not last page', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var loadMoreCalled = false;
      await tester.pumpWidget(createWidget(
        firstPage,
        onLoadMore: () => loadMoreCalled = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Load More'), findsOneWidget);
      expect(find.text('Previous'), findsNothing);

      await tester.tap(find.text('Load More'));
      expect(loadMoreCalled, isTrue);
    });

    testWidgets('shows Previous and Load More on middle page', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(
        middlePage,
        onLoadMore: () {},
        onLoadPrevious: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Load More'), findsOneWidget);
      expect(find.text('Page 2 of 3'), findsOneWidget);
    });

    testWidgets('expands entry detail on tap', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      // Tap the first log entry row.
      await tester.tap(find.text('NullPointerException in UserService').first);
      await tester.pumpAndSettle();

      // Detail panel should appear — the LogEntryDetail renders the copy button.
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.text('Source: '), findsOneWidget);
    });

    testWidgets('collapses entry detail on second tap', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(singlePage));
      await tester.pumpAndSettle();

      // Expand.
      await tester.tap(find.text('NullPointerException in UserService').first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.copy), findsOneWidget);

      // Collapse.
      await tester.tap(find.text('NullPointerException in UserService').first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.copy), findsNothing);
    });
  });
}
