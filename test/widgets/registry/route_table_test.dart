// Tests for RouteTable widget.
//
// Verifies column rendering, collision indicator, HTTP methods,
// gateway service display, and service name tap navigation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/route_table.dart';

const _route1 = ApiRouteResponse(
  id: 'rt-1',
  serviceId: 'svc-1',
  serviceName: 'CodeOps Server',
  routePrefix: '/api/v1/registry',
  httpMethods: 'GET,POST,PUT,DELETE',
  environment: 'dev',
  description: 'Registry endpoints',
);

const _route2 = ApiRouteResponse(
  id: 'rt-2',
  serviceId: 'svc-2',
  serviceName: 'Auth Service',
  gatewayServiceId: 'svc-gw',
  gatewayServiceName: 'Gateway',
  routePrefix: '/api/v1/users',
  httpMethods: 'GET,POST',
  environment: 'dev',
);

const _route3 = ApiRouteResponse(
  id: 'rt-3',
  serviceId: 'svc-3',
  serviceName: 'Vault',
  routePrefix: '/api/v1/vault',
  environment: 'dev',
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildTable({
  List<ApiRouteResponse> routes = const [_route1, _route2, _route3],
  Set<String>? collisionPrefixes,
  String sortField = 'prefix',
  bool sortAscending = true,
  void Function(String)? onSort,
  ValueChanged<ApiRouteResponse>? onDelete,
  void Function(String)? onServiceTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: RouteTable(
          routes: routes,
          collisionPrefixes: collisionPrefixes,
          sortField: sortField,
          sortAscending: sortAscending,
          onSort: onSort ?? (_) {},
          onDelete: onDelete,
          onServiceTap: onServiceTap,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RouteTable', () {
    testWidgets('renders all columns', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildTable());
      await tester.pumpAndSettle();

      expect(find.text('Prefix'), findsOneWidget);
      expect(find.text('Methods'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Gateway'), findsWidgets); // header + data cell
      expect(find.text('Env'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('renders collision indicator', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildTable(
        collisionPrefixes: {'/api/v1/users'},
      ));
      await tester.pumpAndSettle();

      // Warning icon for collision
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('renders HTTP methods', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildTable());
      await tester.pumpAndSettle();

      expect(find.text('GET,POST,PUT,DELETE'), findsOneWidget);
      expect(find.text('GET,POST'), findsOneWidget);
      // Route 3 has no methods — shows *
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('renders gateway service', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildTable());
      await tester.pumpAndSettle();

      expect(find.text('Gateway'), findsWidgets);
    });

    testWidgets('service name clickable', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? tappedServiceId;
      await tester.pumpWidget(_buildTable(
        onServiceTap: (id) => tappedServiceId = id,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CodeOps Server'));
      expect(tappedServiceId, 'svc-1');
    });
  });
}
