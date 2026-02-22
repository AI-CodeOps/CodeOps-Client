// Tests for SolutionListPage.
//
// Verifies loading, error, empty, and data states, header elements,
// status/category filters, search, card rendering, and create button.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/pages/registry/solution_list_page.dart';
import 'package:codeops/providers/registry_providers.dart';

final _testPage = PageResponse<SolutionResponse>(
  content: const [
    SolutionResponse(
      id: 'sol-1',
      teamId: 'team-1',
      name: 'CodeOps Platform',
      slug: 'codeops-platform',
      description: 'Core infrastructure',
      category: SolutionCategory.platform,
      status: SolutionStatus.active,
      memberCount: 6,
    ),
    SolutionResponse(
      id: 'sol-2',
      teamId: 'team-1',
      name: 'Elaro Platform',
      slug: 'elaro-platform',
      description: 'AI development platform',
      category: SolutionCategory.application,
      status: SolutionStatus.active,
      memberCount: 4,
    ),
  ],
  totalElements: 2,
  totalPages: 1,
  page: 0,
  size: 20,
  isLast: true,
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildPage({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: Scaffold(body: SolutionListPage()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SolutionListPage', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionsProvider.overrideWith(
              (ref) => Completer<PageResponse<SolutionResponse>>().future,
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
            registrySolutionsProvider.overrideWith(
              (ref) => throw Exception('Network error'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to Load Solutions'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionsProvider.overrideWith(
              (ref) async => PageResponse<SolutionResponse>.empty(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No solutions yet'), findsOneWidget);
      expect(find.text('Create a solution to group related services.'),
          findsOneWidget);
    });

    testWidgets('renders solution cards', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionsProvider.overrideWith(
              (ref) async => _testPage,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CodeOps Platform'), findsOneWidget);
      expect(find.text('Elaro Platform'), findsOneWidget);
      expect(find.text('6 services'), findsOneWidget);
      expect(find.text('4 services'), findsOneWidget);
    });

    testWidgets('renders header with title and create button', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionsProvider.overrideWith(
              (ref) async => _testPage,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Solutions'), findsOneWidget);
      expect(find.text('Create Solution'), findsOneWidget);
    });

    testWidgets('renders filter dropdowns and search', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionsProvider.overrideWith(
              (ref) async => _testPage,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('search filters solutions by name', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionsProvider.overrideWith(
              (ref) async => _testPage,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Both solutions visible
      expect(find.text('CodeOps Platform'), findsOneWidget);
      expect(find.text('Elaro Platform'), findsOneWidget);

      // Type search text
      await tester.enterText(
        find.byType(TextField).last,
        'Elaro',
      );
      await tester.pumpAndSettle();

      // Only Elaro visible
      expect(find.text('CodeOps Platform'), findsNothing);
      expect(find.text('Elaro Platform'), findsOneWidget);
    });

    testWidgets('renders category badges', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _buildPage(
          overrides: [
            registrySolutionsProvider.overrideWith(
              (ref) async => _testPage,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Application'), findsOneWidget);
    });
  });
}
