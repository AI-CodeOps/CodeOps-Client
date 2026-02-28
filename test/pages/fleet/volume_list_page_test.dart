// Widget tests for VolumeListPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/pages/fleet/volume_list_page.dart';
import 'package:codeops/providers/fleet_providers.dart'
    hide selectedTeamIdProvider;
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final volumes = [
    FleetDockerVolume(
      name: 'pg-data',
      driver: 'local',
      mountpoint: '/var/lib/docker/volumes/pg-data/_data',
      labels: {'app': 'codeops'},
      createdAt: DateTime(2026, 2, 27, 9, 0),
    ),
    FleetDockerVolume(
      name: 'redis-data',
      driver: 'local',
      mountpoint: '/var/lib/docker/volumes/redis-data/_data',
      labels: {},
      createdAt: DateTime(2026, 2, 27, 10, 0),
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
    List<FleetDockerVolume>? volumeList,
    bool loading = false,
    bool error = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        fleetVolumesProvider.overrideWith(
          (ref, tid) {
            if (loading) {
              return Completer<List<FleetDockerVolume>>().future;
            }
            if (error) {
              return Future<List<FleetDockerVolume>>.error('Server error');
            }
            return Future.value(volumeList ?? volumes);
          },
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: VolumeListPage()),
      ),
    );
  }

  group('VolumeListPage', () {
    testWidgets('renders page title', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Docker Volumes'), findsOneWidget);
    });

    testWidgets('renders volume count', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('(2)'), findsOneWidget);
    });

    testWidgets('renders volume names in table', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('pg-data'), findsOneWidget);
      expect(find.text('redis-data'), findsOneWidget);
    });

    testWidgets('renders driver in table', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Both volumes use "local" driver — appears twice
      expect(find.text('local'), findsNWidgets(2));
    });

    testWidgets('renders Create Volume button', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Volume'), findsOneWidget);
    });

    testWidgets('renders Prune button', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Prune'), findsOneWidget);
    });

    testWidgets('renders remove buttons per row', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('renders table headers', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
      expect(find.text('Mountpoint'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
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
      await tester.pumpWidget(createWidget(volumeList: []));
      await tester.pumpAndSettle();

      expect(find.text('No Docker volumes found'), findsOneWidget);
    });
  });
}
