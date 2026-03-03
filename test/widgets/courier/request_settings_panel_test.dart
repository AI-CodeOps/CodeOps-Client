// Widget tests for RequestSettingsPanel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/request_settings_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildPanel({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: Scaffold(body: RequestSettingsPanel()),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RequestSettingsPanel', () {
    testWidgets('renders follow redirects toggle', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('follow_redirects_toggle')), findsOneWidget);
    });

    testWidgets('renders SSL certificate verification toggle', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ssl_verify_toggle')), findsOneWidget);
    });

    testWidgets('renders timeout input field', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timeout_field')), findsOneWidget);
    });

    testWidgets('renders proxy URL input field', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('proxy_url_field')), findsOneWidget);
    });

    testWidgets('toggling follow redirects updates activeRequestStateProvider',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RequestSettingsPanel)),
      );

      // Default is true.
      expect(
        container.read(activeRequestStateProvider).settings.followRedirects,
        isTrue,
      );

      // Tap the toggle to disable follow redirects.
      await tester.tap(find.byKey(const Key('follow_redirects_toggle')));
      await tester.pump();

      expect(
        container.read(activeRequestStateProvider).settings.followRedirects,
        isFalse,
      );
    });

    testWidgets('toggling SSL verify updates activeRequestStateProvider',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildPanel());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RequestSettingsPanel)),
      );

      expect(
        container.read(activeRequestStateProvider).settings.sslVerify,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('ssl_verify_toggle')));
      await tester.pump();

      expect(
        container.read(activeRequestStateProvider).settings.sslVerify,
        isFalse,
      );
    });
  });
}
