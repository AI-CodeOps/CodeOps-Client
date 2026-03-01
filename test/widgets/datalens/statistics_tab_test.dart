// Widget tests for StatisticsTab.
//
// Verifies statistics rendering: section headers, key-value rows,
// row counts, maintenance timestamps, scan counts, DML counts,
// null statistics state, and number formatting.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/statistics_tab.dart';

final _testStats = TableStatistics(
  liveRowCount: 15432,
  deadRowCount: 87,
  lastVacuum: DateTime(2026, 2, 15, 14, 30, 0),
  lastAutoVacuum: DateTime(2026, 2, 20, 3, 15, 0),
  lastAnalyze: DateTime(2026, 2, 15, 14, 30, 0),
  lastAutoAnalyze: DateTime(2026, 2, 20, 3, 15, 0),
  seqScans: 245,
  idxScans: 18903,
  insertCount: 1520,
  updateCount: 3891,
  deleteCount: 42,
);

Widget _createWidget({
  TableStatistics? stats,
  bool useNull = false,
}) {
  return ProviderScope(
    overrides: [
      datalensStatisticsProvider.overrideWith(
        (ref) => Future.value(useNull ? null : (stats ?? _testStats)),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: StatisticsTab()),
    ),
  );
}

void main() {
  group('StatisticsTab', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsTab), findsOneWidget);
    });

    testWidgets('shows section headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Row Counts'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('Scans'), findsOneWidget);
      expect(find.text('DML Operations'), findsOneWidget);
    });

    testWidgets('shows row count values', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Live Rows'), findsOneWidget);
      expect(find.text('15,432'), findsOneWidget);
      expect(find.text('Dead Rows'), findsOneWidget);
      expect(find.text('87'), findsOneWidget);
    });

    testWidgets('shows maintenance timestamps', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Last Vacuum'), findsOneWidget);
      expect(find.text('2026-02-15 14:30:00'), findsNWidgets(2));
    });

    testWidgets('shows scan counts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sequential Scans'), findsOneWidget);
      expect(find.text('245'), findsOneWidget);
      expect(find.text('Index Scans'), findsOneWidget);
      expect(find.text('18,903'), findsOneWidget);
    });

    testWidgets('shows DML counts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Inserts'), findsOneWidget);
      expect(find.text('1,520'), findsOneWidget);
      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('3,891'), findsOneWidget);
      expect(find.text('Deletes'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows empty state when no statistics', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(useNull: true));
      await tester.pumpAndSettle();

      expect(find.text('No statistics available'), findsOneWidget);
    });
  });
}
