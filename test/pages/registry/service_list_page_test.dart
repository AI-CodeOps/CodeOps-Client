// Tests for ServiceListPage.
//
// Verifies loading, error, empty, and data states,
// summary cards, filter behavior, and pagination.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/pages/registry/service_list_page.dart';
import 'package:codeops/providers/registry_providers.dart';

/// Creates a page response with test services.
PageResponse<ServiceRegistrationResponse> _mockPage(
    List<ServiceRegistrationResponse> content) {
  return PageResponse(
    content: content,
    page: 0,
    size: 20,
    totalElements: content.length,
    totalPages: 1,
    isLast: true,
  );
}

final _testServices = [
  ServiceRegistrationResponse.fromJson(const {
    'id': 'svc-1',
    'teamId': 'team-1',
    'name': 'CodeOps Server',
    'slug': 'codeops-server',
    'serviceType': 'SPRING_BOOT_API',
    'status': 'ACTIVE',
    'lastHealthStatus': 'UP',
    'lastHealthCheckAt': '2026-02-22T10:00:00.000Z',
    'dependencyCount': 5,
  }),
  ServiceRegistrationResponse.fromJson(const {
    'id': 'svc-2',
    'teamId': 'team-1',
    'name': 'CodeOps Client',
    'slug': 'codeops-client',
    'serviceType': 'FLUTTER_DESKTOP',
    'status': 'ACTIVE',
    'lastHealthStatus': 'DEGRADED',
  }),
  ServiceRegistrationResponse.fromJson(const {
    'id': 'svc-3',
    'teamId': 'team-1',
    'name': 'Logger Service',
    'slug': 'logger-service',
    'serviceType': 'SPRING_BOOT_API',
    'status': 'INACTIVE',
    'lastHealthStatus': 'DOWN',
  }),
];

final _testHealth = TeamHealthSummaryResponse.fromJson(const {
  'teamId': 'team-1',
  'totalServices': 3,
  'activeServices': 2,
  'servicesUp': 1,
  'servicesDown': 1,
  'servicesDegraded': 1,
  'servicesUnknown': 0,
  'servicesNeverChecked': 0,
  'overallHealth': 'DEGRADED',
});

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
      home: Scaffold(body: ServiceListPage()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServiceListPage', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServicesProvider.overrideWith(
              (ref) => Completer<PageResponse<ServiceRegistrationResponse>>()
                  .future,
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServicesProvider.overrideWith(
              (ref) => throw Exception('Network error'),
            ),
            registryTeamHealthSummaryProvider.overrideWith(
              (ref) async => null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders empty state when no services', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServicesProvider.overrideWith(
              (ref) async => _mockPage([]),
            ),
            registryTeamHealthSummaryProvider.overrideWith(
              (ref) async => null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No services registered'), findsOneWidget);
      expect(find.text('Register Service'), findsOneWidget);
    });

    testWidgets('renders service table with data', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServicesProvider.overrideWith(
              (ref) async => _mockPage(_testServices),
            ),
            registryTeamHealthSummaryProvider.overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CodeOps Server'), findsOneWidget);
      expect(find.text('CodeOps Client'), findsOneWidget);
      expect(find.text('Logger Service'), findsOneWidget);
    });

    testWidgets('renders summary cards with health data', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServicesProvider.overrideWith(
              (ref) async => _mockPage(_testServices),
            ),
            registryTeamHealthSummaryProvider.overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('Unhealthy'), findsOneWidget);
      // "Degraded" appears in summary card AND as health indicator for svc-2
      expect(find.text('Degraded'), findsNWidgets(2));
      // Values
      expect(find.text('3'), findsOneWidget); // total
      // healthy=1, unhealthy=1, degraded=1 (+ pagination page "1" button)
      expect(find.text('1'), findsAtLeastNWidgets(3));
    });

    testWidgets('status filter filters services', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(overrides: [
        registryServicesProvider.overrideWith(
          (ref) async => _mockPage(_testServices),
        ),
        registryTeamHealthSummaryProvider.overrideWith(
          (ref) async => null,
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ServiceListPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 3 services visible
      expect(find.text('CodeOps Server'), findsOneWidget);
      expect(find.text('Logger Service'), findsOneWidget);

      // Apply INACTIVE filter
      container.read(registryServiceStatusFilterProvider.notifier).state =
          ServiceStatus.inactive;
      await tester.pumpAndSettle();

      // Only inactive service remains
      expect(find.text('Logger Service'), findsOneWidget);
      expect(find.text('CodeOps Server'), findsNothing);
    });

    testWidgets('type filter filters services', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(overrides: [
        registryServicesProvider.overrideWith(
          (ref) async => _mockPage(_testServices),
        ),
        registryTeamHealthSummaryProvider.overrideWith(
          (ref) async => null,
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ServiceListPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Apply FLUTTER_DESKTOP filter
      container.read(registryServiceTypeFilterProvider.notifier).state =
          ServiceType.flutterDesktop;
      await tester.pumpAndSettle();

      expect(find.text('CodeOps Client'), findsOneWidget);
      expect(find.text('CodeOps Server'), findsNothing);
    });

    testWidgets('health filter filters services', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(overrides: [
        registryServicesProvider.overrideWith(
          (ref) async => _mockPage(_testServices),
        ),
        registryTeamHealthSummaryProvider.overrideWith(
          (ref) async => null,
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ServiceListPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Apply DOWN health filter
      container.read(registryServiceHealthFilterProvider.notifier).state =
          HealthStatus.down;
      await tester.pumpAndSettle();

      expect(find.text('Logger Service'), findsOneWidget);
      expect(find.text('CodeOps Server'), findsNothing);
    });

    testWidgets('pagination shows correct page info', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Create 15 services
      final manyServices = List.generate(
        15,
        (i) => ServiceRegistrationResponse.fromJson({
          'id': 'svc-$i',
          'teamId': 'team-1',
          'name': 'Service $i',
          'slug': 'service-$i',
          'serviceType': 'SPRING_BOOT_API',
          'status': 'ACTIVE',
        }),
      );

      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServicesProvider.overrideWith(
              (ref) async => _mockPage(manyServices),
            ),
            registryTeamHealthSummaryProvider.overrideWith(
              (ref) async => null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Default page size is 10, so first 10 of 15
      expect(find.textContaining('of 15 services'), findsOneWidget);
    });

    testWidgets('renders header and register button', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registryServicesProvider.overrideWith(
              (ref) async => _mockPage(_testServices),
            ),
            registryTeamHealthSummaryProvider.overrideWith(
              (ref) async => null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service Registry'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });
  });
}
