// Widget tests for LogFilterBar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/providers/logger_providers.dart';
import 'package:codeops/widgets/logger/log_filter_bar.dart';

void main() {
  final sources = [
    LogSourceResponse(
      id: 's1',
      name: 'api-service',
      isActive: true,
      teamId: 'team-1',
      logCount: 1000,
    ),
    LogSourceResponse(
      id: 's2',
      name: 'worker-service',
      isActive: true,
      teamId: 'team-1',
      logCount: 500,
    ),
  ];

  Widget createWidget({
    List<LogSourceResponse>? sourceList,
    bool isPaused = false,
    VoidCallback? onTogglePause,
    LogLevel? initialLevel,
    String? initialService,
    String initialSearch = '',
  }) {
    return ProviderScope(
      overrides: [
        loggerLogLevelFilterProvider.overrideWith((ref) => initialLevel),
        loggerLogServiceFilterProvider.overrideWith((ref) => initialService),
        loggerLogSearchProvider.overrideWith((ref) => initialSearch),
        loggerLogStartTimeProvider.overrideWith((ref) => null),
        loggerLogEndTimeProvider.overrideWith((ref) => null),
        loggerLogPageProvider.overrideWith((ref) => 0),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LogFilterBar(
            sources: sourceList ?? sources,
            isPaused: isPaused,
            onTogglePause: onTogglePause ?? () {},
          ),
        ),
      ),
    );
  }

  group('LogFilterBar', () {
    testWidgets('renders source dropdown with source names', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // The dropdown should show "All Sources" by default.
      expect(find.text('All Sources'), findsOneWidget);
    });

    testWidgets('renders level dropdown', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('All Levels'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders pause button', (tester) async {
      await tester.pumpWidget(createWidget(isPaused: false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('renders resume button when paused', (tester) async {
      await tester.pumpWidget(createWidget(isPaused: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byTooltip('Resume'), findsOneWidget);
    });

    testWidgets('calls onTogglePause when button tapped', (tester) async {
      var toggled = false;
      await tester.pumpWidget(createWidget(
        isPaused: false,
        onTogglePause: () => toggled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pause'));
      expect(toggled, isTrue);
    });
  });
}
