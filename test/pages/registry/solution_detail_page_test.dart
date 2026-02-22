// Tests for SolutionDetailPage.
//
// Verifies loading, error, header rendering, health summary,
// member list, action buttons, and dialogs.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/pages/registry/solution_detail_page.dart';
import 'package:codeops/providers/registry_providers.dart';

const _testDetail = SolutionDetailResponse(
  id: 'sol-1',
  teamId: 'team-1',
  name: 'CodeOps Platform',
  slug: 'codeops-platform',
  description: 'Core infrastructure services',
  category: SolutionCategory.platform,
  status: SolutionStatus.active,
  repositoryUrl: 'https://github.com/org/codeops',
  documentationUrl: 'https://docs.codeops.io',
  members: [
    SolutionMemberResponse(
      id: 'mem-1',
      solutionId: 'sol-1',
      serviceId: 'svc-1',
      serviceName: 'CodeOps Server',
      serviceSlug: 'codeops-server',
      serviceType: ServiceType.springBootApi,
      serviceStatus: ServiceStatus.active,
      serviceHealthStatus: HealthStatus.up,
      role: SolutionMemberRole.core,
      displayOrder: 1,
    ),
    SolutionMemberResponse(
      id: 'mem-2',
      solutionId: 'sol-1',
      serviceId: 'svc-2',
      serviceName: 'Auth Service',
      serviceSlug: 'auth-service',
      serviceType: ServiceType.springBootApi,
      serviceStatus: ServiceStatus.active,
      serviceHealthStatus: HealthStatus.degraded,
      role: SolutionMemberRole.supporting,
      displayOrder: 2,
    ),
  ],
);

const _testHealth = SolutionHealthResponse(
  solutionId: 'sol-1',
  solutionName: 'CodeOps Platform',
  totalServices: 2,
  servicesUp: 1,
  servicesDown: 0,
  servicesDegraded: 1,
  servicesUnknown: 0,
  aggregatedHealth: HealthStatus.degraded,
  serviceHealths: [],
);

const _emptyDetail = SolutionDetailResponse(
  id: 'sol-2',
  teamId: 'team-1',
  name: 'Empty Solution',
  slug: 'empty-solution',
  category: SolutionCategory.other,
  status: SolutionStatus.inDevelopment,
  members: [],
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildPage({
  String solutionId = 'sol-1',
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: SolutionDetailPage(solutionId: solutionId)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SolutionDetailPage', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) => Completer<SolutionDetailResponse>().future,
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Solution Detail'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) => throw Exception('Not found'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Solution'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders solution header', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) async => _testDetail,
            ),
            registrySolutionHealthProvider('sol-1').overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CodeOps Platform'), findsOneWidget);
      expect(find.text('codeops-platform'), findsOneWidget);
      expect(find.text('Core infrastructure services'), findsOneWidget);
      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders health summary', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) async => _testDetail,
            ),
            registrySolutionHealthProvider('sol-1').overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Health Summary'), findsOneWidget);
      expect(find.text('Total: 2'), findsOneWidget);
      expect(find.text('Up: 1'), findsOneWidget);
      expect(find.text('Degraded: 1'), findsOneWidget);
    });

    testWidgets('renders member list with names', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) async => _testDetail,
            ),
            registrySolutionHealthProvider('sol-1').overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Members (2)'), findsOneWidget);
      expect(find.text('CodeOps Server'), findsOneWidget);
      expect(find.text('Auth Service'), findsOneWidget);
    });

    testWidgets('renders empty members state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          solutionId: 'sol-2',
          overrides: [
            registrySolutionFullDetailProvider('sol-2').overrideWith(
              (ref) async => _emptyDetail,
            ),
            registrySolutionHealthProvider('sol-2').overrideWith(
              (ref) => Completer<SolutionHealthResponse>().future,
            ),
          ],
        ),
      );
      // Use pump() because health provider never resolves (loading spinner)
      await tester.pump();
      await tester.pump();

      expect(find.text('Members (0)'), findsOneWidget);
      expect(find.text('No members yet'), findsOneWidget);
    });

    testWidgets('renders action buttons', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) async => _testDetail,
            ),
            registrySolutionHealthProvider('sol-1').overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Add Member'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) async => _testDetail,
            ),
            registrySolutionHealthProvider('sol-1').overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Solution'), findsOneWidget);
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
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) async => _testDetail,
            ),
            registrySolutionHealthProvider('sol-1').overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Solution'), findsNothing);
    });

    testWidgets('back button exists', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) async => _testDetail,
            ),
            registrySolutionHealthProvider('sol-1').overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byTooltip('Back to solutions'), findsOneWidget);
    });

    testWidgets('renders URLs when present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionFullDetailProvider('sol-1').overrideWith(
              (ref) async => _testDetail,
            ),
            registrySolutionHealthProvider('sol-1').overrideWith(
              (ref) async => _testHealth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('https://github.com/org/codeops'), findsOneWidget);
      expect(find.text('https://docs.codeops.io'), findsOneWidget);
    });
  });
}
