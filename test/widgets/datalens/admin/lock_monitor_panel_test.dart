// Widget tests for LockMonitorPanel.
//
// Verifies rendering, sub-tabs (All Locks, Blocking), auto-refresh toggle,
// blocking badge, and empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_admin_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/services/datalens/database_connection_service.dart';
import 'package:codeops/services/datalens/db_admin_service.dart';
import 'package:codeops/widgets/datalens/admin/lock_monitor_panel.dart';

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
        body: LockMonitorPanel(connectionId: 'conn-1'),
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

  group('LockMonitorPanel', () {
    testWidgets('renders with two sub-tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getLocks('conn-1'))
          .thenAnswer((_) async => []);
      when(() => mockService.getLockConflicts('conn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('All Locks (0)'), findsOneWidget);
      expect(find.text('Blocking (0)'), findsOneWidget);
    });

    testWidgets('shows auto-refresh and refresh button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getLocks('conn-1'))
          .thenAnswer((_) async => []);
      when(() => mockService.getLockConflicts('conn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('Auto-refresh'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows empty state for all locks tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getLocks('conn-1'))
          .thenAnswer((_) async => []);
      when(() => mockService.getLockConflicts('conn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('No locks held'), findsOneWidget);
    });

    testWidgets('shows blocking badge when conflicts exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getLocks('conn-1'))
          .thenAnswer((_) async => []);
      when(() => mockService.getLockConflicts('conn-1'))
          .thenAnswer((_) async => [
                const LockConflict(
                  blockedPid: 200,
                  blockingPid: 100,
                  lockMode: 'AccessExclusiveLock',
                ),
              ]);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('1 blocking'), findsOneWidget);
    });

    testWidgets('renders lock rows with data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getLocks('conn-1'))
          .thenAnswer((_) async => [
                const LockInfo(
                  pid: 100,
                  lockMode: 'AccessShareLock',
                  lockType: 'relation',
                  relation: 'users',
                  granted: true,
                  username: 'admin',
                ),
              ]);
      when(() => mockService.getLockConflicts('conn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
          _createWidget(mockService: mockService, mockConnService: mockConnService));
      await tester.pumpAndSettle();

      expect(find.text('PID'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('users'), findsOneWidget);
    });
  });
}
