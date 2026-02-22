// Tests for MemberList widget.
//
// Verifies member rendering, role badges, health indicators,
// drag handles, and remove button callbacks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/member_list.dart';

const _testMembers = [
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
  SolutionMemberResponse(
    id: 'mem-3',
    solutionId: 'sol-1',
    serviceId: 'svc-3',
    serviceName: 'PostgreSQL',
    serviceSlug: 'postgresql',
    serviceType: ServiceType.databaseService,
    serviceStatus: ServiceStatus.active,
    serviceHealthStatus: HealthStatus.up,
    role: SolutionMemberRole.infrastructure,
    displayOrder: 3,
  ),
];

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildMemberList({
  List<SolutionMemberResponse> members = _testMembers,
  void Function(List<String>)? onReorder,
  void Function(String)? onRemove,
  void Function(String)? onMemberTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: MemberList(
          solutionId: 'sol-1',
          members: members,
          onReorder: onReorder ?? (_) {},
          onRemove: onRemove ?? (_) {},
          onMemberTap: onMemberTap,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MemberList', () {
    testWidgets('renders all members', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildMemberList());
      await tester.pumpAndSettle();

      expect(find.text('CodeOps Server'), findsOneWidget);
      expect(find.text('Auth Service'), findsOneWidget);
      expect(find.text('PostgreSQL'), findsOneWidget);
    });

    testWidgets('renders role badges', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildMemberList());
      await tester.pumpAndSettle();

      expect(find.text('Core'), findsOneWidget);
      expect(find.text('Supporting'), findsOneWidget);
      expect(find.text('Infrastructure'), findsOneWidget);
    });

    testWidgets('renders drag handles', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildMemberList());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(3));
    });

    testWidgets('renders order numbers', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildMemberList());
      await tester.pumpAndSettle();

      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);
    });

    testWidgets('remove button calls onRemove', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? removedId;
      await tester.pumpWidget(_buildMemberList(
        onRemove: (id) => removedId = id,
      ));
      await tester.pumpAndSettle();

      // Find the remove buttons (close icons)
      final removeButtons = find.byTooltip('Remove member');
      expect(removeButtons, findsNWidgets(3));

      // Tap the first remove button
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      expect(removedId, 'svc-1');
    });

    testWidgets('renders empty state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildMemberList(members: []));
      await tester.pumpAndSettle();

      expect(find.text('No members yet'), findsOneWidget);
      expect(find.text('Add services to this solution.'), findsOneWidget);
    });
  });
}
