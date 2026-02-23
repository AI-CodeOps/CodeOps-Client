// Tests for WorkstationCard widget.
//
// Verifies name, default star indicator, service count, startup sequence,
// health summary, Start All button, and onTap callback.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/workstation_card.dart';

const _entry1 = WorkstationServiceEntry(
  serviceId: 'svc-1',
  name: 'Auth Service',
  slug: 'auth-service',
  serviceType: ServiceType.springBootApi,
  status: ServiceStatus.active,
  healthStatus: HealthStatus.up,
  startupPosition: 1,
);

const _entry2 = WorkstationServiceEntry(
  serviceId: 'svc-2',
  name: 'API Gateway',
  slug: 'api-gateway',
  serviceType: ServiceType.springBootApi,
  status: ServiceStatus.active,
  healthStatus: HealthStatus.degraded,
  startupPosition: 2,
);

const _profile = WorkstationProfileResponse(
  id: 'wp-1',
  teamId: 'team-1',
  name: 'Dev Workstation',
  isDefault: true,
  services: [_entry1, _entry2],
  startupOrder: ['svc-1', 'svc-2'],
);

const _profileNoDefault = WorkstationProfileResponse(
  id: 'wp-2',
  teamId: 'team-1',
  name: 'Staging Profile',
  isDefault: false,
  services: [_entry1],
  startupOrder: ['svc-1'],
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildCard({
  WorkstationProfileResponse profile = _profile,
  VoidCallback? onTap,
  VoidCallback? onStartAll,
}) {
  return MaterialApp(
    home: Scaffold(
      body: WorkstationCard(
        profile: profile,
        onTap: onTap,
        onStartAll: onStartAll,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkstationCard', () {
    testWidgets('renders profile name', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Dev Workstation'), findsOneWidget);
    });

    testWidgets('renders default star indicator', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Default profile'), findsOneWidget);
    });

    testWidgets('hides star when not default', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard(profile: _profileNoDefault));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('renders service count', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('2 services'), findsOneWidget);
    });

    testWidgets('renders startup sequence', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.textContaining('Auth Service'), findsOneWidget);
    });

    testWidgets('renders health summary with degraded', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('1 degraded'), findsOneWidget);
    });

    testWidgets('Start All button fires callback', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var startPressed = false;
      await tester.pumpWidget(_buildCard(
        onStartAll: () => startPressed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start All'));
      expect(startPressed, isTrue);
    });

    testWidgets('onTap callback fires', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tapped = false;
      await tester.pumpWidget(_buildCard(
        onTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dev Workstation'));
      expect(tapped, isTrue);
    });
  });
}
