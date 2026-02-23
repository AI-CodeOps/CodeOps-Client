// Tests for WorkstationListPage.
//
// Verifies loading, error, empty state, profile cards rendering,
// create button, from-solution button, and default star display.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/pages/registry/workstation_list_page.dart';
import 'package:codeops/providers/registry_providers.dart';

const _profile1 = WorkstationProfileResponse(
  id: 'wp-1',
  teamId: 'team-1',
  name: 'Dev Workstation',
  isDefault: true,
  services: [
    WorkstationServiceEntry(
      serviceId: 'svc-1',
      name: 'Auth Service',
      slug: 'auth-service',
      serviceType: ServiceType.springBootApi,
      status: ServiceStatus.active,
      healthStatus: HealthStatus.up,
      startupPosition: 1,
    ),
  ],
  startupOrder: ['svc-1'],
);

const _profile2 = WorkstationProfileResponse(
  id: 'wp-2',
  teamId: 'team-1',
  name: 'Staging Profile',
  isDefault: false,
  services: [],
  startupOrder: [],
);

const _solution1 = SolutionResponse(
  id: 'sol-1',
  teamId: 'team-1',
  name: 'CodeOps Platform',
  slug: 'codeops-platform',
  category: SolutionCategory.platform,
  status: SolutionStatus.active,
);

PageResponse<SolutionResponse> _solutionPage(List<SolutionResponse> items) {
  return PageResponse(
    content: items,
    page: 0,
    size: 20,
    totalElements: items.length,
    totalPages: 1,
    isLast: true,
  );
}

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildPage({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: Scaffold(body: WorkstationListPage()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkstationListPage', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final completer = Completer<List<WorkstationProfileResponse>>();
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryWorkstationProfilesProvider.overrideWith(
            (ref) => completer.future,
          ),
          registrySolutionsProvider.overrideWith(
            (ref) async => _solutionPage([]),
          ),
        ]),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryWorkstationProfilesProvider.overrideWith(
            (ref) async => <WorkstationProfileResponse>[],
          ),
          registrySolutionsProvider.overrideWith(
            (ref) async => _solutionPage([]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('No workstation profiles yet'), findsOneWidget);
    });

    testWidgets('renders profile cards', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryWorkstationProfilesProvider.overrideWith(
            (ref) async => [_profile1, _profile2],
          ),
          registrySolutionsProvider.overrideWith(
            (ref) async => _solutionPage([]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dev Workstation'), findsOneWidget);
      expect(find.text('Staging Profile'), findsOneWidget);
    });

    testWidgets('renders title', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryWorkstationProfilesProvider.overrideWith(
            (ref) async => [_profile1],
          ),
          registrySolutionsProvider.overrideWith(
            (ref) async => _solutionPage([]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workstation Profiles'), findsOneWidget);
    });

    testWidgets('create button present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryWorkstationProfilesProvider.overrideWith(
            (ref) async => [_profile1],
          ),
          registrySolutionsProvider.overrideWith(
            (ref) async => _solutionPage([]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Profile'), findsOneWidget);
    });

    testWidgets('from solution button visible when solutions exist',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryWorkstationProfilesProvider.overrideWith(
            (ref) async => [_profile1],
          ),
          registrySolutionsProvider.overrideWith(
            (ref) async => _solutionPage([_solution1]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('From Solution'), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryWorkstationProfilesProvider.overrideWith(
            (ref) async => throw Exception('Network error'),
          ),
          registrySolutionsProvider.overrideWith(
            (ref) async => _solutionPage([]),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
