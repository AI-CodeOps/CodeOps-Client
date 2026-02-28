// Widget tests for ImageListPage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/fleet_models.dart';
import 'package:codeops/pages/fleet/image_list_page.dart';
import 'package:codeops/providers/fleet_providers.dart'
    hide selectedTeamIdProvider;
import 'package:codeops/providers/team_providers.dart'
    show selectedTeamIdProvider;

void main() {
  const teamId = 'team-1';

  final images = [
    FleetDockerImage(
      id: 'sha256:abc123',
      repoTags: ['postgres:16', 'postgres:latest'],
      sizeBytes: 419430400, // ~400 MB
      created: DateTime(2026, 2, 27, 9, 0),
    ),
    FleetDockerImage(
      id: 'sha256:def456',
      repoTags: ['redis:7-alpine'],
      sizeBytes: 31457280, // ~30 MB
      created: DateTime(2026, 2, 27, 10, 0),
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
    List<FleetDockerImage>? imageList,
    bool loading = false,
    bool error = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTeamIdProvider.overrideWith((ref) => selectedTeamId),
        fleetImagesProvider.overrideWith(
          (ref, tid) {
            if (loading) {
              return Completer<List<FleetDockerImage>>().future;
            }
            if (error) {
              return Future<List<FleetDockerImage>>.error('Server error');
            }
            return Future.value(imageList ?? images);
          },
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ImageListPage()),
      ),
    );
  }

  group('ImageListPage', () {
    testWidgets('renders page title', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Docker Images'), findsOneWidget);
    });

    testWidgets('renders image count', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('(2)'), findsOneWidget);
    });

    testWidgets('renders repo tags in table', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('postgres:16, postgres:latest'), findsOneWidget);
      expect(find.text('redis:7-alpine'), findsOneWidget);
    });

    testWidgets('renders formatted file sizes', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('400.0 MB'), findsOneWidget);
      expect(find.text('30.0 MB'), findsOneWidget);
    });

    testWidgets('renders Pull Image button', (tester) async {
      useWideViewport(tester);
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pull Image'), findsOneWidget);
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

      expect(find.text('Repository Tags'), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);
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
      await tester.pumpWidget(createWidget(imageList: []));
      await tester.pumpAndSettle();

      expect(find.text('No Docker images found'), findsOneWidget);
    });
  });
}
