// Widget tests for TableStatsPanel.
//
// Verifies rendering, sortable columns, dead-tuple highlighting, VACUUM
// badges, and empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_admin_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/services/datalens/db_admin_service.dart';
import 'package:codeops/widgets/datalens/admin/table_stats_panel.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDbAdminService extends Mock implements DbAdminService {}

Widget _createWidget({required MockDbAdminService mockService}) {
  return ProviderScope(
    overrides: [
      dbAdminServiceProvider.overrideWithValue(mockService),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: TableStatsPanel(connectionId: 'conn-1', schema: 'public'),
      ),
    ),
  );
}

void main() {
  late MockDbAdminService mockService;

  setUp(() {
    mockService = MockDbAdminService();
  });

  group('TableStatsPanel', () {
    testWidgets('renders toolbar with table count and refresh', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getTableStats('conn-1', 'public'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('0 tables'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows empty state when no stats', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getTableStats('conn-1', 'public'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('No table statistics available'), findsOneWidget);
    });

    testWidgets('renders DataTable with stats', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getTableStats('conn-1', 'public'))
          .thenAnswer((_) async => [
                const TableStatInfo(
                  schema: 'public',
                  tableName: 'users',
                  liveRows: 5000,
                  deadRows: 10,
                  seqScans: 100,
                  seqTuplesRead: 50000,
                  idxScans: 400,
                  idxTuplesFetched: 2000,
                  inserts: 300,
                  updates: 100,
                  deletes: 50,
                  tableSize: '2 MB',
                ),
              ]);

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('Table'), findsOneWidget);
      expect(find.text('Live Rows'), findsOneWidget);
      expect(find.text('Dead Rows'), findsOneWidget);
      expect(find.text('users'), findsOneWidget);
      expect(find.text('2 MB'), findsOneWidget);
    });

    testWidgets('shows VACUUM badge for high dead ratio', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getTableStats('conn-1', 'public'))
          .thenAnswer((_) async => [
                const TableStatInfo(
                  schema: 'public',
                  tableName: 'dirty_table',
                  liveRows: 100,
                  deadRows: 50,
                  seqScans: 10,
                  seqTuplesRead: 500,
                  idxScans: 5,
                  idxTuplesFetched: 20,
                  inserts: 100,
                  updates: 0,
                  deletes: 0,
                ),
              ]);

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('VACUUM'), findsOneWidget);
    });

    testWidgets('shows table count in toolbar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getTableStats('conn-1', 'public'))
          .thenAnswer((_) async => [
                const TableStatInfo(
                  schema: 'public', tableName: 'a', liveRows: 1, deadRows: 0,
                  seqScans: 0, seqTuplesRead: 0, idxScans: 0,
                  idxTuplesFetched: 0, inserts: 0, updates: 0, deletes: 0,
                ),
                const TableStatInfo(
                  schema: 'public', tableName: 'b', liveRows: 2, deadRows: 0,
                  seqScans: 0, seqTuplesRead: 0, idxScans: 0,
                  idxTuplesFetched: 0, inserts: 0, updates: 0, deletes: 0,
                ),
              ]);

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('2 tables'), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getTableStats('conn-1', 'public'))
          .thenThrow(Exception('Query failed'));

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.textContaining('Query failed'), findsOneWidget);
    });
  });
}
