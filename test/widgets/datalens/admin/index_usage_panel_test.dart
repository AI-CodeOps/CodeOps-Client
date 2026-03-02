// Widget tests for IndexUsagePanel.
//
// Verifies rendering, unused filter toggle, unused badge, index count,
// and empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_admin_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/db_admin_service.dart';
import 'package:codeops/widgets/datalens/admin/index_usage_panel.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDbAdminService extends Mock implements DbAdminService {}

class MockDatabaseConnectionService extends Mock
    implements DatabaseConnectionService {}

Widget _createWidget({
  required MockDbAdminService mockService,
  required MockDatabaseConnectionService mockConnService,
}) {
  return ProviderScope(
    overrides: [
      dbAdminServiceProvider.overrideWithValue(mockService),
      datalensConnectionServiceProvider.overrideWithValue(mockConnService),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: IndexUsagePanel(connectionId: 'conn-1', schema: 'public'),
      ),
    ),
  );
}

void main() {
  late MockDbAdminService mockService;
  late MockDatabaseConnectionService mockConnService;

  setUp(() {
    mockService = MockDbAdminService();
    mockConnService = MockDatabaseConnectionService();
  });

  group('IndexUsagePanel', () {
    testWidgets('renders toolbar with index count and unused toggle',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getIndexUsage('conn-1', 'public'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('Unused only'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows empty state when no indexes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getIndexUsage('conn-1', 'public'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('No index data available'), findsOneWidget);
    });

    testWidgets('shows unused count badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getIndexUsage('conn-1', 'public'))
          .thenAnswer((_) async => [
                const IndexUsageInfo(
                  schema: 'public', tableName: 'users', indexName: 'users_pkey',
                  indexScans: 100, indexSize: '16 kB', indexSizeBytes: 16384,
                  indexTuplesRead: 500, indexTuplesFetched: 200,
                ),
                const IndexUsageInfo(
                  schema: 'public', tableName: 'users', indexName: 'users_old_idx',
                  indexScans: 0, indexSize: '8 kB', indexSizeBytes: 8192,
                  indexTuplesRead: 0, indexTuplesFetched: 0,
                ),
              ]);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('1 unused'), findsOneWidget);
      expect(find.text('2 indexes'), findsOneWidget);
    });

    testWidgets('renders DataTable with index data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getIndexUsage('conn-1', 'public'))
          .thenAnswer((_) async => [
                const IndexUsageInfo(
                  schema: 'public', tableName: 'users', indexName: 'users_pkey',
                  indexScans: 100, indexSize: '16 kB', indexSizeBytes: 16384,
                  indexTuplesRead: 500, indexTuplesFetched: 200,
                ),
              ]);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('Table'), findsOneWidget);
      expect(find.text('Index'), findsOneWidget);
      expect(find.text('Scans'), findsOneWidget);
      expect(find.text('users_pkey'), findsOneWidget);
    });
  });
}
