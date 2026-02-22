// Tests for ServiceDetailPage.
//
// Verifies loading, error, data states, header metadata,
// action buttons, clone dialog, delete dialog, and health check.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_models.dart';
import 'package:codeops/pages/registry/service_detail_page.dart';
import 'package:codeops/providers/registry_providers.dart';

final _testIdentity = ServiceIdentityResponse.fromJson(const {
  'service': {
    'id': 'svc-1',
    'teamId': 'team-1',
    'name': 'CodeOps Server',
    'slug': 'codeops-server',
    'serviceType': 'SPRING_BOOT_API',
    'status': 'ACTIVE',
    'description': 'Main backend service',
    'techStack': 'Java 25 / Spring Boot',
    'repoUrl': 'https://github.com/org/codeops-server',
    'healthCheckUrl': 'http://localhost:8090/actuator/health',
    'lastHealthStatus': 'UP',
    'portCount': 2,
    'dependencyCount': 3,
    'solutionCount': 1,
    'createdAt': '2026-01-15T10:00:00.000Z',
    'updatedAt': '2026-02-20T15:30:00.000Z',
  },
  'ports': [
    {
      'id': 'port-1',
      'serviceId': 'svc-1',
      'environment': 'local',
      'portType': 'HTTP_API',
      'portNumber': 8090,
      'protocol': 'TCP',
    },
  ],
  'upstreamDependencies': [
    {
      'id': 'dep-1',
      'sourceServiceId': 'svc-1',
      'sourceServiceName': 'CodeOps Server',
      'targetServiceId': 'svc-2',
      'targetServiceName': 'Auth Service',
      'dependencyType': 'HTTP_REST',
      'isRequired': true,
    },
  ],
  'downstreamDependencies': [],
  'routes': [
    {
      'id': 'route-1',
      'serviceId': 'svc-1',
      'routePrefix': '/api/v1/services',
      'httpMethods': 'GET,POST',
      'environment': 'local',
    },
  ],
  'infraResources': [
    {
      'id': 'infra-1',
      'teamId': 'team-1',
      'serviceId': 'svc-1',
      'resourceType': 'RDS_INSTANCE',
      'resourceName': 'codeops-db',
      'environment': 'local',
      'region': 'us-east-1',
    },
  ],
  'environmentConfigs': [
    {
      'id': 'cfg-1',
      'serviceId': 'svc-1',
      'environment': 'dev',
      'configKey': 'DB_HOST',
      'configValue': 'localhost:5432',
    },
  ],
});

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildPage({
  String serviceId = 'svc-1',
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: ServiceDetailPage(serviceId: serviceId)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServiceDetailPage', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) => Completer<ServiceIdentityResponse>().future,
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Service Detail'), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) => throw Exception('Network error'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders service header with metadata', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Service name appears in header bar and header card
      expect(find.text('CodeOps Server'), findsNWidgets(2));
      // Slug
      expect(find.text('codeops-server'), findsOneWidget);
      // Status badge
      expect(find.text('Active'), findsOneWidget);
      // Description
      expect(find.text('Main backend service'), findsOneWidget);
      // Tech stack
      expect(find.text('Java 25 / Spring Boot'), findsOneWidget);
      // Service type
      expect(find.text('Spring Boot API'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders count chips', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ports'), findsOneWidget);
      expect(find.text('Dependencies'), findsAtLeastNWidgets(1));
      expect(find.text('Solutions'), findsOneWidget);
    });

    testWidgets('renders action buttons', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clone'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Check Health'), findsOneWidget);
    });

    testWidgets('renders identity kit cards', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Port Allocations'), findsOneWidget);
      expect(find.text('API Routes'), findsOneWidget);
      expect(find.text('Infrastructure Resources'), findsOneWidget);
      expect(find.text('Environment Configs'), findsOneWidget);
    });

    testWidgets('clone dialog opens with name pre-filled', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clone'));
      await tester.pumpAndSettle();

      expect(find.text('Clone Service'), findsOneWidget);
      expect(find.text('New Service Name'), findsOneWidget);
      expect(find.text('New Slug (optional)'), findsOneWidget);
      // Pre-filled name
      expect(find.text('CodeOps Server (Copy)'), findsOneWidget);
      // Dialog buttons
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('clone dialog can be cancelled', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clone'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Clone Service'), findsNothing);
    });

    testWidgets('delete dialog opens with confirmation message',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Service'), findsOneWidget);
      expect(find.textContaining('CodeOps Server'), findsAtLeastNWidgets(1));
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('delete dialog can be cancelled', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Delete Service'), findsNothing);
    });

    testWidgets('back button exists with tooltip', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServiceIdentityProvider('svc-1').overrideWith(
              (ref) async => _testIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byTooltip('Back to services'), findsOneWidget);
    });

    testWidgets('renders with empty identity kit lists', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final emptyIdentity = ServiceIdentityResponse.fromJson(const {
        'service': {
          'id': 'svc-empty',
          'teamId': 'team-1',
          'name': 'Empty Service',
          'slug': 'empty-service',
          'serviceType': 'OTHER',
          'status': 'INACTIVE',
        },
        'ports': [],
        'upstreamDependencies': [],
        'downstreamDependencies': [],
        'routes': [],
        'infraResources': [],
        'environmentConfigs': [],
      });

      await tester.pumpWidget(
        _buildPage(
          serviceId: 'svc-empty',
          overrides: [
            registryServiceIdentityProvider('svc-empty').overrideWith(
              (ref) async => emptyIdentity,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Empty Service'), findsNWidgets(2));
      expect(find.text('No ports allocated'), findsOneWidget);
      expect(find.text('No dependencies'), findsOneWidget);
      expect(find.text('No routes registered'), findsOneWidget);
      expect(find.text('No infrastructure resources'), findsOneWidget);
      expect(find.text('No environment configs'), findsOneWidget);
    });
  });
}
