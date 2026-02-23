// Tests for StartupOrderDisplay widget.
//
// Verifies ordered display, empty state, no-order warning,
// numbered steps, service tap callback, and health indicators.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/startup_order_display.dart';

const _entry1 = WorkstationServiceEntry(
  serviceId: 'svc-1',
  name: 'Database',
  slug: 'database',
  serviceType: ServiceType.databaseService,
  status: ServiceStatus.active,
  healthStatus: HealthStatus.up,
  startupPosition: 1,
);

const _entry2 = WorkstationServiceEntry(
  serviceId: 'svc-2',
  name: 'API Server',
  slug: 'api-server',
  serviceType: ServiceType.springBootApi,
  status: ServiceStatus.active,
  healthStatus: HealthStatus.up,
  startupPosition: 2,
);

const _entry3 = WorkstationServiceEntry(
  serviceId: 'svc-3',
  name: 'Frontend',
  slug: 'frontend',
  serviceType: ServiceType.reactSpa,
  status: ServiceStatus.active,
  healthStatus: HealthStatus.down,
  startupPosition: 3,
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildDisplay({
  List<WorkstationServiceEntry> services = const [],
  List<String> startupOrder = const [],
  ValueChanged<String>? onServiceTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: StartupOrderDisplay(
          services: services,
          startupOrder: startupOrder,
          onServiceTap: onServiceTap,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StartupOrderDisplay', () {
    testWidgets('renders empty state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildDisplay());
      await tester.pumpAndSettle();

      expect(find.text('No services in this profile'), findsOneWidget);
    });

    testWidgets('renders warning when no startup order', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildDisplay(
        services: [_entry1, _entry2],
        startupOrder: [],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No dependency-based ordering'), findsOneWidget);
    });

    testWidgets('renders ordered service names', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildDisplay(
        services: [_entry1, _entry2, _entry3],
        startupOrder: ['svc-1', 'svc-2', 'svc-3'],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Database'), findsOneWidget);
      expect(find.text('API Server'), findsOneWidget);
      expect(find.text('Frontend'), findsOneWidget);
    });

    testWidgets('renders numbered steps', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildDisplay(
        services: [_entry1, _entry2],
        startupOrder: ['svc-1', 'svc-2'],
      ));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('service tap callback fires', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? tappedId;
      await tester.pumpWidget(_buildDisplay(
        services: [_entry1],
        startupOrder: ['svc-1'],
        onServiceTap: (id) => tappedId = id,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Database'));
      expect(tappedId, 'svc-1');
    });

    testWidgets('renders health status labels', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildDisplay(
        services: [_entry1, _entry3],
        startupOrder: ['svc-1', 'svc-3'],
      ));
      await tester.pumpAndSettle();

      expect(find.text(HealthStatus.up.displayName), findsOneWidget);
      expect(find.text(HealthStatus.down.displayName), findsOneWidget);
    });
  });
}
