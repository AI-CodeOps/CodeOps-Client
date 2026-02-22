// Tests for ServiceFilterBar widget.
//
// Verifies search field, filter dropdowns, clear button, and provider updates.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/registry_providers.dart';
import 'package:codeops/widgets/registry/service_filter_bar.dart';

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  group('ServiceFilterBar', () {
    testWidgets('renders search field', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ServiceFilterBar()),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search services...'), findsOneWidget);
    });

    testWidgets('renders filter dropdowns', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ServiceFilterBar()),
          ),
        ),
      );

      // Status, Type, Health dropdowns (show "All X" when no filter selected)
      expect(find.text('All Status'), findsOneWidget);
      expect(find.text('All Type'), findsOneWidget);
      expect(find.text('All Health'), findsOneWidget);
    });

    testWidgets('search updates provider', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ServiceFilterBar()),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 350));

      expect(container.read(registryServiceSearchProvider), 'test');
    });

    testWidgets('clear button not visible when no filters active',
        (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ServiceFilterBar()),
          ),
        ),
      );

      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('clear button visible and resets filters', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set a filter to activate the clear button
      container.read(registryServiceSearchProvider.notifier).state = 'test';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ServiceFilterBar()),
          ),
        ),
      );

      expect(find.text('Clear'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(container.read(registryServiceSearchProvider), '');
      expect(container.read(registryServiceStatusFilterProvider), isNull);
      expect(container.read(registryServiceTypeFilterProvider), isNull);
      expect(container.read(registryServiceHealthFilterProvider), isNull);
    });
  });
}
