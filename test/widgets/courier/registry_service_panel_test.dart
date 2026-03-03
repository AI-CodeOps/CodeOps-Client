// Widget tests for RegistryServicePanel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/widgets/courier/registry_service_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

final _services = [
  ServiceRegistrationResponse(
    id: 's1',
    teamId: 't1',
    name: 'CodeOps Server',
    slug: 'codeops-server',
    serviceType: ServiceType.springBootApi,
    status: ServiceStatus.active,
    lastHealthStatus: HealthStatus.up,
    techStack: 'Spring Boot',
    lastHealthCheckAt: DateTime(2026, 3, 3, 14, 30),
  ),
  ServiceRegistrationResponse(
    id: 's2',
    teamId: 't1',
    name: 'CodeOps Analytics',
    slug: 'codeops-analytics',
    serviceType: ServiceType.springBootApi,
    status: ServiceStatus.active,
    lastHealthStatus: HealthStatus.down,
    techStack: 'Spring Boot',
  ),
];

final _ports = [
  PortAllocationResponse(
    id: 'p1',
    serviceId: 's1',
    serviceName: 'CodeOps Server',
    environment: 'dev',
    portType: PortType.httpApi,
    portNumber: 8090,
  ),
];

final _routes = [
  ApiRouteResponse(
    id: 'r1',
    serviceId: 's1',
    routePrefix: '/api/v1/auth',
    httpMethods: 'GET,POST',
  ),
];

Widget buildPanel({
  List<ServiceRegistrationResponse>? services,
}) {
  return ProviderScope(
    overrides: [
      registryServicesForCourierProvider
          .overrideWith((ref) => services ?? _services),
      servicePortsForCourierProvider('s1')
          .overrideWith((ref) => _ports),
      servicePortsForCourierProvider('s2')
          .overrideWith((ref) => <PortAllocationResponse>[]),
      serviceApiRoutesProvider('s1').overrideWith((ref) => _routes),
      serviceApiRoutesProvider('s2')
          .overrideWith((ref) => <ApiRouteResponse>[]),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 350,
          height: 700,
          child: RegistryServicePanel(),
        ),
      ),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RegistryServicePanel', () {
    testWidgets('renders panel with header', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('registry_service_panel')), findsOneWidget);
      expect(find.byKey(const Key('registry_panel_header')), findsOneWidget);
      expect(find.text('Registered Services'), findsOneWidget);
    });

    testWidgets('lists all services', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('services_list')), findsOneWidget);
      expect(find.text('CodeOps Server'), findsOneWidget);
      expect(find.text('CodeOps Analytics'), findsOneWidget);
    });

    testWidgets('shows health status badges', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.text('UP'), findsOneWidget);
      expect(find.text('DOWN'), findsOneWidget);
    });

    testWidgets('expands service to show detail', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      // Tap first service to expand
      await tester.tap(find.text('CodeOps Server'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('service_detail')), findsOneWidget);
      expect(
          find.byKey(const Key('import_openapi_button')), findsOneWidget);
      expect(find.byKey(const Key('quick_test_button')), findsOneWidget);
      expect(find.byKey(const Key('view_docs_button')), findsOneWidget);
    });

    testWidgets('shows route count in expanded detail', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      await tester.tap(find.text('CodeOps Server'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('route_count')), findsOneWidget);
      expect(find.text('1 API route'), findsOneWidget);
    });

    testWidgets('shows empty state when no services', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel(services: []));
      await tester.pumpAndSettle();

      expect(find.text('No services registered'), findsOneWidget);
    });
  });
}
