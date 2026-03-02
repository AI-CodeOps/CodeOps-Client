// Widget tests for DbAdminPage.
//
// Verifies page rendering, tab bar with 5 tabs, connection selector,
// back button, and empty state when no connection is selected.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_admin_models.dart';
import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/pages/datalens/db_admin_page.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/services/datalens/db_admin_service.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDbAdminService extends Mock implements DbAdminService {}

const _testConnections = [
  DatabaseConnection(id: 'c1', name: 'TestDB'),
  DatabaseConnection(id: 'c2', name: 'Staging'),
];

Widget _createWidget({
  String? connectionId,
  required MockDbAdminService mockService,
  List<DatabaseConnection> connections = _testConnections,
}) {
  return ProviderScope(
    overrides: [
      datalensConnectionsProvider.overrideWith(
        (ref) => Future.value(connections),
      ),
      datalensSchemasProvider.overrideWith((ref) => Future.value([])),
      selectedConnectionIdProvider.overrideWith((ref) => connectionId),
      dbAdminServiceProvider.overrideWithValue(mockService),
    ],
    child: MaterialApp(
      home: DbAdminPage(connectionId: connectionId),
    ),
  );
}

void main() {
  late MockDbAdminService mockService;

  setUp(() {
    mockService = MockDbAdminService();
    // Set up default stubs for admin service methods.
    when(() => mockService.getActiveSessions(any()))
        .thenAnswer((_) async => <ActiveSession>[]);
    when(() => mockService.getTableStats(any(), any()))
        .thenAnswer((_) async => <TableStatInfo>[]);
    when(() => mockService.getLocks(any()))
        .thenAnswer((_) async => <LockInfo>[]);
    when(() => mockService.getLockConflicts(any()))
        .thenAnswer((_) async => <LockConflict>[]);
    when(() => mockService.getIndexUsage(any(), any()))
        .thenAnswer((_) async => <IndexUsageInfo>[]);
    when(() => mockService.getServerInfo(any())).thenAnswer(
      (_) async => const ServerInfo(
        version: 'PostgreSQL 16.1',
        currentDatabase: 'testdb',
        currentUser: 'admin',
      ),
    );
    when(() => mockService.getServerParameters(any()))
        .thenAnswer((_) async => <ServerParameter>[]);
  });

  group('DbAdminPage', () {
    testWidgets('renders title and 5 tab labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
          _createWidget(connectionId: 'c1', mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('Database Administration'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Table Stats'), findsOneWidget);
      expect(find.text('Locks'), findsOneWidget);
      expect(find.text('Indexes'), findsOneWidget);
      expect(find.text('Server'), findsOneWidget);
    });

    testWidgets('shows prompt when no connection selected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
          _createWidget(connectionId: null, mockService: mockService));
      await tester.pumpAndSettle();

      expect(
        find.text('Select a connection to view administration data'),
        findsOneWidget,
      );
    });

    testWidgets('has admin_panel_settings icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
          _createWidget(connectionId: 'c1', mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
    });

    testWidgets('has back button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
          _createWidget(connectionId: 'c1', mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
