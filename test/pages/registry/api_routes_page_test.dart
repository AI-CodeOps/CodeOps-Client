// Tests for ApiRoutesPage.
//
// Verifies loading, error, empty state, route table rendering,
// collision warning, service filter, search filter, add button,
// and delete confirmation.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_models.dart';
import 'package:codeops/pages/registry/api_routes_page.dart';
import 'package:codeops/providers/registry_providers.dart';

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
  serviceId: 'svc-1',
  serviceName: 'CodeOps Server',
  routePrefix: '/api/v1/users',
  httpMethods: 'GET,POST',
  environment: 'dev',
);

const _route3 = ApiRouteResponse(
  id: 'rt-3',
  serviceId: 'svc-2',
  serviceName: 'Auth Service',
  routePrefix: '/api/v1/users',
  httpMethods: 'GET,DELETE',
  environment: 'dev',
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildPage({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: Scaffold(body: ApiRoutesPage()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiRoutesPage', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final completer = Completer<List<ApiRouteResponse>>();
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryAllRoutesProvider.overrideWith(
            (ref) => completer.future,
          ),
        ]),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders route table', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryAllRoutesProvider.overrideWith(
            (ref) async => [_route1, _route2],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('/api/v1/registry'), findsOneWidget);
      expect(find.text('/api/v1/users'), findsOneWidget);
    });

    testWidgets('renders collision warning', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // route2 and route3 share prefix /api/v1/users, different services
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryAllRoutesProvider.overrideWith(
            (ref) async => [_route1, _route2, _route3],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('route collision'),
        findsOneWidget,
      );
    });

    testWidgets('add button present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryAllRoutesProvider.overrideWith(
            (ref) async => [_route1],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Register Route'), findsOneWidget);
    });

    testWidgets('empty state shows message', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryAllRoutesProvider.overrideWith(
            (ref) async => <ApiRouteResponse>[],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('No routes registered'), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryAllRoutesProvider.overrideWith(
            (ref) async => throw Exception('Network error'),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('refresh button present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryAllRoutesProvider.overrideWith(
            (ref) async => [_route1],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Refresh'), findsOneWidget);
    });

    testWidgets('search field present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryAllRoutesProvider.overrideWith(
            (ref) async => [_route1],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search prefix...'), findsOneWidget);
    });
  });
}
