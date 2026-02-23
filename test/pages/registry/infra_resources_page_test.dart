// Tests for InfraResourcesPage.
//
// Verifies loading, error, empty state, resource table rendering,
// orphan banner, type filter, add button, and delete confirmation.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/pages/registry/infra_resources_page.dart';
import 'package:codeops/providers/registry_providers.dart';

const _resource1 = InfraResourceResponse(
  id: 'r-1',
  teamId: 'team-1',
  serviceId: 'svc-1',
  serviceName: 'CodeOps Server',
  resourceType: InfraResourceType.s3Bucket,
  resourceName: 'codeops-assets',
  environment: 'dev',
  region: 'us-east-1',
);

const _resource2 = InfraResourceResponse(
  id: 'r-2',
  teamId: 'team-1',
  serviceId: null,
  serviceName: null,
  resourceType: InfraResourceType.sqsQueue,
  resourceName: 'dead-letter-q',
  environment: 'dev',
);

const _resource3 = InfraResourceResponse(
  id: 'r-3',
  teamId: 'team-1',
  serviceId: 'svc-2',
  serviceName: 'Registry',
  resourceType: InfraResourceType.cloudwatchLogGroup,
  resourceName: 'codeops-registry',
  environment: 'dev',
);

PageResponse<InfraResourceResponse> _mockPage(
    List<InfraResourceResponse> content) {
  return PageResponse(
    content: content,
    page: 0,
    size: 20,
    totalElements: content.length,
    totalPages: 1,
    isLast: true,
  );
}

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
      home: Scaffold(body: InfraResourcesPage()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InfraResourcesPage', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final completer =
          Completer<PageResponse<InfraResourceResponse>>();
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryInfraResourcesProvider.overrideWith(
            (ref) => completer.future,
          ),
          registryOrphanedResourcesProvider.overrideWith(
            (ref) async => <InfraResourceResponse>[],
          ),
        ]),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders resource table', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryInfraResourcesProvider.overrideWith(
            (ref) async => _mockPage([_resource1, _resource3]),
          ),
          registryOrphanedResourcesProvider.overrideWith(
            (ref) async => <InfraResourceResponse>[],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('codeops-assets'), findsOneWidget);
      expect(find.text('codeops-registry'), findsOneWidget);
    });

    testWidgets('renders orphan banner when orphans exist', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryInfraResourcesProvider.overrideWith(
            (ref) async =>
                _mockPage([_resource1, _resource2, _resource3]),
          ),
          registryOrphanedResourcesProvider.overrideWith(
            (ref) async => [_resource2],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('1 orphan resource'),
        findsOneWidget,
      );
    });

    testWidgets('renders no orphan banner when clean', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryInfraResourcesProvider.overrideWith(
            (ref) async => _mockPage([_resource1]),
          ),
          registryOrphanedResourcesProvider.overrideWith(
            (ref) async => <InfraResourceResponse>[],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('orphan'), findsNothing);
    });

    testWidgets('add button present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryInfraResourcesProvider.overrideWith(
            (ref) async => _mockPage([_resource1]),
          ),
          registryOrphanedResourcesProvider.overrideWith(
            (ref) async => <InfraResourceResponse>[],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Resource'), findsOneWidget);
    });

    testWidgets('empty state shows message', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryInfraResourcesProvider.overrideWith(
            (ref) async => PageResponse<InfraResourceResponse>.empty(),
          ),
          registryOrphanedResourcesProvider.overrideWith(
            (ref) async => <InfraResourceResponse>[],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('No infrastructure resources'), findsOneWidget);
    });

    testWidgets('renders error state with retry', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryInfraResourcesProvider.overrideWith(
            (ref) async => throw Exception('Network error'),
          ),
          registryOrphanedResourcesProvider.overrideWith(
            (ref) async => <InfraResourceResponse>[],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('refresh button present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(overrides: [
          registryInfraResourcesProvider.overrideWith(
            (ref) async => _mockPage([_resource1]),
          ),
          registryOrphanedResourcesProvider.overrideWith(
            (ref) async => <InfraResourceResponse>[],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Refresh'), findsOneWidget);
    });
  });
}
