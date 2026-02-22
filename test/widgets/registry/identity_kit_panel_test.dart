// Tests for IdentityKitPanel and its sub-cards.
//
// Verifies port list, dependency, route, infra resource, and
// environment config card rendering with populated and empty data.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/identity_kit_panel.dart';

final _fullIdentity = ServiceIdentityResponse.fromJson(const {
  'service': {
    'id': 'svc-1',
    'teamId': 'team-1',
    'name': 'Test Service',
    'slug': 'test-service',
    'serviceType': 'SPRING_BOOT_API',
    'status': 'ACTIVE',
  },
  'ports': [
    {
      'id': 'port-1',
      'serviceId': 'svc-1',
      'environment': 'local',
      'portType': 'HTTP_API',
      'portNumber': 8080,
      'protocol': 'TCP',
      'description': 'Main HTTP port',
    },
    {
      'id': 'port-2',
      'serviceId': 'svc-1',
      'environment': 'local',
      'portType': 'DEBUG',
      'portNumber': 5005,
    },
  ],
  'upstreamDependencies': [
    {
      'id': 'dep-1',
      'sourceServiceId': 'svc-1',
      'sourceServiceName': 'Test Service',
      'targetServiceId': 'svc-2',
      'targetServiceName': 'Auth Service',
      'dependencyType': 'HTTP_REST',
      'isRequired': true,
    },
  ],
  'downstreamDependencies': [
    {
      'id': 'dep-2',
      'sourceServiceId': 'svc-3',
      'sourceServiceName': 'Frontend App',
      'targetServiceId': 'svc-1',
      'targetServiceName': 'Test Service',
      'dependencyType': 'HTTP_REST',
      'isRequired': false,
    },
  ],
  'routes': [
    {
      'id': 'route-1',
      'serviceId': 'svc-1',
      'routePrefix': '/api/v1/users',
      'httpMethods': 'GET,POST,PUT',
      'environment': 'local',
      'description': 'User management',
    },
  ],
  'infraResources': [
    {
      'id': 'infra-1',
      'teamId': 'team-1',
      'serviceId': 'svc-1',
      'resourceType': 'S3_BUCKET',
      'resourceName': 'test-uploads',
      'environment': 'dev',
      'region': 'us-east-1',
    },
  ],
  'environmentConfigs': [
    {
      'id': 'cfg-1',
      'serviceId': 'svc-1',
      'environment': 'dev',
      'configKey': 'DATABASE_URL',
      'configValue': 'jdbc:postgresql://localhost:5432/testdb',
      'configSource': 'MANUAL',
    },
    {
      'id': 'cfg-2',
      'serviceId': 'svc-1',
      'environment': 'prod',
      'configKey': 'API_KEY',
      'configValue': 'sk-abc123...',
    },
  ],
});

final _emptyIdentity = ServiceIdentityResponse.fromJson(const {
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

Widget _buildPanel(ServiceIdentityResponse identity) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: IdentityKitPanel(identity: identity),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdentityKitPanel', () {
    testWidgets('renders all five card headers', (tester) async {
      await tester.pumpWidget(_buildPanel(_fullIdentity));
      await tester.pumpAndSettle();

      expect(find.text('Port Allocations'), findsOneWidget);
      expect(find.text('Dependencies'), findsOneWidget);
      expect(find.text('API Routes'), findsOneWidget);
      expect(find.text('Infrastructure Resources'), findsOneWidget);
      expect(find.text('Environment Configs'), findsOneWidget);
    });

    testWidgets('shows port data', (tester) async {
      await tester.pumpWidget(_buildPanel(_fullIdentity));
      await tester.pumpAndSettle();

      // Port count badge
      expect(find.text('2'), findsAtLeastNWidgets(1));
      // Port numbers
      expect(find.text('8080'), findsOneWidget);
      expect(find.text('5005'), findsOneWidget);
      // Description
      expect(find.text('Main HTTP port'), findsOneWidget);
    });

    testWidgets('shows upstream and downstream dependencies', (tester) async {
      await tester.pumpWidget(_buildPanel(_fullIdentity));
      await tester.pumpAndSettle();

      // Upstream section
      expect(find.textContaining('Depends on'), findsOneWidget);
      expect(find.text('Auth Service'), findsOneWidget);

      // Downstream section
      expect(find.textContaining('Depended on by'), findsOneWidget);
      expect(find.text('Frontend App'), findsOneWidget);

      // Dependency type and required label
      expect(find.textContaining('HTTP REST'), findsAtLeastNWidgets(1));
      expect(find.textContaining('required'), findsAtLeastNWidgets(1));
      expect(find.textContaining('optional'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows route data with HTTP method badges', (tester) async {
      await tester.pumpWidget(_buildPanel(_fullIdentity));
      await tester.pumpAndSettle();

      // Route prefix
      expect(find.text('/api/v1/users'), findsOneWidget);
      // HTTP methods
      expect(find.text('GET'), findsOneWidget);
      expect(find.text('POST'), findsOneWidget);
      expect(find.text('PUT'), findsOneWidget);
      // Description
      expect(find.text('User management'), findsOneWidget);
    });

    testWidgets('shows infra resource data', (tester) async {
      await tester.pumpWidget(_buildPanel(_fullIdentity));
      await tester.pumpAndSettle();

      expect(find.text('test-uploads'), findsOneWidget);
      expect(find.text('S3 Bucket'), findsOneWidget);
      expect(find.text('us-east-1'), findsOneWidget);
    });

    testWidgets('shows environment config data', (tester) async {
      await tester.pumpWidget(_buildPanel(_fullIdentity));
      await tester.pumpAndSettle();

      expect(find.text('DATABASE_URL'), findsOneWidget);
      expect(find.text('API_KEY'), findsOneWidget);
      // Environment badges
      expect(find.text('dev'), findsAtLeastNWidgets(1));
      expect(find.text('prod'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty states for all cards', (tester) async {
      await tester.pumpWidget(_buildPanel(_emptyIdentity));
      await tester.pumpAndSettle();

      expect(find.text('No ports allocated'), findsOneWidget);
      expect(find.text('No dependencies'), findsOneWidget);
      expect(find.text('No routes registered'), findsOneWidget);
      expect(find.text('No infrastructure resources'), findsOneWidget);
      expect(find.text('No environment configs'), findsOneWidget);
    });

    testWidgets('env config row expands on tap', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildPanel(_fullIdentity));
      await tester.pumpAndSettle();

      // Scroll to make the env config card visible
      await tester.ensureVisible(find.text('DATABASE_URL'));
      await tester.pumpAndSettle();

      // Tap to expand
      await tester.tap(find.text('DATABASE_URL'));
      await tester.pumpAndSettle();

      // Expanded shows SelectableText with full value
      expect(find.byType(SelectableText), findsAtLeastNWidgets(1));
    });
  });
}
