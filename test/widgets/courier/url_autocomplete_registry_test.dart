// Widget tests for URL autocomplete from Registry.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/request_builder.dart';

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
  ),
];

final _ports = [
  PortAllocationResponse(
    id: 'p1',
    serviceId: 's1',
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

Widget buildRequestBuilder() {
  return ProviderScope(
    overrides: [
      openRequestTabsProvider.overrideWith((ref) => [
            RequestTab(
              id: 'tab-1',
              requestId: null,
              name: 'New Request',
              method: CourierHttpMethod.get,
              url: '',
              isNew: true,
            ),
          ]),
      activeRequestTabProvider.overrideWith((ref) => 'tab-1'),
      registryServicesForCourierProvider
          .overrideWith((ref) => _services),
      servicePortsForCourierProvider('s1')
          .overrideWith((ref) => _ports),
      serviceApiRoutesProvider('s1').overrideWith((ref) => _routes),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 600,
          child: RequestBuilder(),
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
  group('URL autocomplete from Registry', () {
    testWidgets('URL field exists', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildRequestBuilder());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('url_field')), findsOneWidget);
    });

    testWidgets('shows suggestions when typing http prefix', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildRequestBuilder());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('url_field')), 'http');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('url_suggestions')), findsOneWidget);
    });

    testWidgets('hides suggestions for non-http text', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildRequestBuilder());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('url_field')), 'foo');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('url_suggestions')), findsNothing);
    });
  });
}
