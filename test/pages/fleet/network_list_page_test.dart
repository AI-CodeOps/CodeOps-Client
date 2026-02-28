// Widget tests for NetworkListPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/pages/fleet/network_list_page.dart';
import 'package:codeops/providers/fleet_providers.dart'
    hide selectedTeamIdProvider;
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final networks = [
    FleetDockerNetwork(
      id: 'net-1',
      name: 'codeops-net',
      driver: 'bridge',
      subnet: '172.18.0.0/16',
      gateway: '172.18.0.1',
      connectedContainers: ['container-1', 'container-2'],
    ),
    FleetDockerNetwork(
      id: 'net-2',
      name: 'monitoring',
      driver: 'overlay',
      subnet: '10.0.0.0/24',
      gateway: '10.0.0.1',
      connectedContainers: [],
    ),
  ];

  void useWideViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget createWidget({
    String? selectedTeamId = teamId,
    List<FleetDockerNetwork>? networkList,
    bool loading = false,
    bool error = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        fleetNetworksProvider.overrideWith(
          (ref, tid) {
            if (loading) {
              return Completer<List<FleetDockerNetwork>>().future;
            }
            if (error) {
              return Future<List<FleetDockerNetwork>>.error('Server error');
            }
            return Future.value(networkList ?? networks);
          },
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: NetworkListPage()),
      ),
    );
  }

  group('NetworkListPage', () {
    testWidgets('renders page title', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Docker Networks'), findsOneWidget);
    });

    testWidgets('renders network count', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('(2)'), findsOneWidget);
    });

    testWidgets('renders network names in table', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('codeops-net'), findsOneWidget);
      expect(find.text('monitoring'), findsOneWidget);
    });

    testWidgets('renders drivers in table', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('bridge'), findsOneWidget);
      expect(find.text('overlay'), findsOneWidget);
    });

    testWidgets('renders subnets in table', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('172.18.0.0/16'), findsOneWidget);
      expect(find.text('10.0.0.0/24'), findsOneWidget);
    });

    testWidgets('renders gateways in table', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('172.18.0.1'), findsOneWidget);
      expect(find.text('10.0.0.1'), findsOneWidget);
    });

    testWidgets('renders connected container counts', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('2'), findsAtLeastNWidgets(1));
      expect(find.text('0'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Create Network button', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Network'), findsOneWidget);
    });

    testWidgets('renders connect and remove buttons per row',
        (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.link), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('renders table headers', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
      expect(find.text('Subnet'), findsOneWidget);
      expect(find.text('Gateway'), findsOneWidget);
      expect(find.text('Containers'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(createWidget(loading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      await tester.pumpWidget(createWidget(error: true));
      await tester.pumpAndSettle();

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders no team selected state', (tester) async {
      await tester.pumpWidget(createWidget(selectedTeamId: null));
      await tester.pumpAndSettle();

      expect(find.text('No team selected'), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget(networkList: []));
      await tester.pumpAndSettle();

      expect(find.text('No Docker networks found'), findsOneWidget);
    });
  });
}
