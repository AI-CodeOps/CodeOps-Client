// Widget tests for ActiveSessionsPanel.
//
// Verifies rendering, state filter dropdown, auto-refresh toggle, session
// count display, and empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_admin_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/db_admin_service.dart';
import 'package:codeops/widgets/datalens/admin/active_sessions_panel.dart';

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
        body: ActiveSessionsPanel(connectionId: 'conn-1'),
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

  group('ActiveSessionsPanel', () {
    testWidgets('renders toolbar with filter and auto-refresh', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getActiveSessions('conn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('State:'), findsOneWidget);
      expect(find.text('Auto-refresh'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows session count', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getActiveSessions('conn-1'))
          .thenAnswer((_) async => [
                const ActiveSession(pid: 1, state: 'active', query: 'SELECT 1'),
                const ActiveSession(pid: 2, state: 'idle', query: ''),
              ]);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('2 sessions'), findsOneWidget);
    });

    testWidgets('shows empty state when no sessions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getActiveSessions('conn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('No active sessions'), findsOneWidget);
    });

    testWidgets('renders DataTable with sessions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getActiveSessions('conn-1'))
          .thenAnswer((_) async => [
                const ActiveSession(
                  pid: 123,
                  database: 'mydb',
                  username: 'admin',
                  state: 'active',
                  waitDurationSec: 5.0,
                  query: 'SELECT 1',
                ),
              ]);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('PID'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
      expect(find.text('mydb'), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('shows cancel and terminate buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getActiveSessions('conn-1'))
          .thenAnswer((_) async => [
                const ActiveSession(pid: 123, state: 'active', query: 'SELECT 1'),
              ]);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.stop_circle), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getActiveSessions('conn-1'))
          .thenThrow(StateError('Connection lost'));

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.textContaining('Connection lost'), findsOneWidget);
    });
  });
}
