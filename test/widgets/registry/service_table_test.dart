// Tests for ServiceTable widget.
//
// Verifies column rendering, service data display, sort callbacks,
// and row tap navigation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/service_table.dart';

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  final testService = ServiceRegistrationResponse.fromJson(const {
    'id': 'svc-1',
    'teamId': 'team-1',
    'name': 'CodeOps Server',
    'slug': 'codeops-server',
    'serviceType': 'SPRING_BOOT_API',
    'status': 'ACTIVE',
    'lastHealthStatus': 'UP',
    'lastHealthCheckAt': '2026-02-22T10:00:00.000Z',
    'dependencyCount': 5,
  });

  final testService2 = ServiceRegistrationResponse.fromJson(const {
    'id': 'svc-2',
    'teamId': 'team-1',
    'name': 'CodeOps Client',
    'slug': 'codeops-client',
    'serviceType': 'FLUTTER_DESKTOP',
    'status': 'ACTIVE',
  });

  Widget buildTable({
    List<ServiceRegistrationResponse>? services,
    String sortField = 'name',
    bool sortAscending = true,
    void Function(String)? onSort,
    void Function(ServiceRegistrationResponse)? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ServiceTable(
            services: services ?? [testService, testService2],
            sortField: sortField,
            sortAscending: sortAscending,
            onSort: onSort ?? (_) {},
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('ServiceTable', () {
    testWidgets('renders all column headers', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTable());

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Deps'), findsOneWidget);
      expect(find.text('Last Check'), findsOneWidget);
    });

    testWidgets('renders service name with slug', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTable());

      expect(find.text('CodeOps Server'), findsOneWidget);
      expect(find.text('codeops-server'), findsOneWidget);
    });

    testWidgets('renders service type label', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTable());

      expect(find.text('Spring Boot API'), findsOneWidget);
      expect(find.text('Flutter Desktop'), findsOneWidget);
    });

    testWidgets('renders status badge', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTable());

      // Both services are ACTIVE
      expect(find.text('Active'), findsNWidgets(2));
    });

    testWidgets('renders health indicator', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTable());

      expect(find.text('Up'), findsOneWidget);
      expect(find.text('Never checked'), findsOneWidget);
    });

    testWidgets('renders dependency count', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTable());

      expect(find.text('5'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('sort callback fires on column tap', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? sortedField;
      await tester.pumpWidget(buildTable(onSort: (f) => sortedField = f));

      await tester.tap(find.text('Name'));
      await tester.pump();

      expect(sortedField, 'name');
    });

    testWidgets('row tap callback fires', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ServiceRegistrationResponse? tappedService;
      await tester.pumpWidget(
        buildTable(onTap: (s) => tappedService = s),
      );

      await tester.tap(find.text('CodeOps Server'));
      await tester.pump();

      expect(tappedService?.id, 'svc-1');
    });
  });
}
