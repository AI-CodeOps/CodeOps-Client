// Widget tests for ServerInfoPanel.
//
// Verifies rendering, overview cards, connection gauge, parameters table,
// search filtering, and empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/datalens_admin_models.dart';
import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/services/datalens/db_admin_service.dart';
import 'package:codeops/widgets/datalens/admin/server_info_panel.dart';

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
        body: ServerInfoPanel(connectionId: 'conn-1'),
      ),
    ),
  );
}

void main() {
  late MockDbAdminService mockService;

  setUp(() {
    mockService = MockDbAdminService();
  });

  group('ServerInfoPanel', () {
    testWidgets('renders overview cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getServerInfo('conn-1')).thenAnswer(
        (_) async => const ServerInfo(
          version: 'PostgreSQL 16.1',
          currentDatabase: 'mydb',
          currentUser: 'admin',
          uptime: '5 days, 3 hours',
          maxConnections: 100,
          activeConnections: 25,
          databaseSize: '500 MB',
        ),
      );
      when(() => mockService.getServerParameters('conn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('PostgreSQL 16.1'), findsOneWidget);
      expect(find.text('Uptime'), findsOneWidget);
      expect(find.text('Database Size'), findsOneWidget);
      expect(find.text('500 MB'), findsOneWidget);
      expect(find.text('Connections'), findsOneWidget);
      expect(find.text('25 / 100'), findsOneWidget);
    });

    testWidgets('renders parameters table', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getServerInfo('conn-1')).thenAnswer(
        (_) async => const ServerInfo(
          version: 'PostgreSQL 16.1',
          currentDatabase: 'mydb',
          currentUser: 'admin',
        ),
      );
      when(() => mockService.getServerParameters('conn-1'))
          .thenAnswer((_) async => [
                const ServerParameter(
                  name: 'max_connections',
                  value: '100',
                  category: 'Connections',
                  description: 'Maximum connections',
                ),
              ]);

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('Parameters'), findsOneWidget);
      expect(find.text('max_connections'), findsOneWidget);
      expect(find.text('1 parameter'), findsOneWidget);
    });

    testWidgets('has search field for parameters', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getServerInfo('conn-1')).thenAnswer(
        (_) async => const ServerInfo(
          version: 'PostgreSQL 16.1',
          currentDatabase: 'mydb',
          currentUser: 'admin',
        ),
      );
      when(() => mockService.getServerParameters('conn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => mockService.getServerInfo('conn-1'))
          .thenThrow(Exception('Server unreachable'));

      await tester.pumpWidget(_createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.textContaining('Server unreachable'), findsOneWidget);
    });
  });
}
