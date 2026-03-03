// Widget tests for RequestBuilder.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/request_builder.dart';
import 'package:codeops/widgets/courier/request_settings_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildBuilder({
  List<Override> overrides = const [],
  String? activeTabId,
  String activeUrl = 'http://localhost/',
}) {
  final tab = activeTabId == null
      ? null
      : RequestTab(
          id: activeTabId,
          name: 'Test',
          method: CourierHttpMethod.get,
          url: activeUrl,
        );

  return ProviderScope(
    overrides: [
      if (tab != null) ...[
        openRequestTabsProvider.overrideWith((ref) => [tab]),
        activeRequestTabProvider.overrideWith((ref) => activeTabId),
        activeRequestStateProvider.overrideWith(
          (ref) => RequestEditNotifier()
            ..load(RequestEditState(
              method: tab.method,
              url: tab.url,
            )),
        ),
      ],
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(body: RequestBuilder()),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RequestBuilder', () {
    testWidgets('renders without error', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBuilder());
      await tester.pumpAndSettle();

      expect(find.byType(RequestBuilder), findsOneWidget);
    });

    testWidgets('shows empty hint when no active tab', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBuilder());
      await tester.pumpAndSettle();

      expect(find.text('No request open'), findsOneWidget);
    });

    testWidgets('shows method dropdown when tab is active', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBuilder(activeTabId: 'tab-1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('method_dropdown')), findsOneWidget);
    });

    testWidgets('shows URL field when tab is active', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBuilder(activeTabId: 'tab-1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('url_field')), findsOneWidget);
    });

    testWidgets('shows send button when tab is active', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBuilder(activeTabId: 'tab-1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('send_button')), findsOneWidget);
    });

    testWidgets('shows all 7 request sub-tabs', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBuilder(activeTabId: 'tab-1'));
      await tester.pumpAndSettle();

      expect(find.text('Params'), findsOneWidget);
      expect(find.text('Headers'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Scripts'), findsOneWidget);
      expect(find.text('Tests'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Settings tab shows RequestSettingsPanel', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBuilder(activeTabId: 'tab-1'));
      await tester.pumpAndSettle();

      // Tap the Settings tab.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(RequestSettingsPanel), findsOneWidget);
    });

    testWidgets('shows cancel button when execution is running', (tester) async {
      setSize(tester);

      // Pre-set execution state to "running" to simulate an in-flight request.
      await tester.pumpWidget(buildBuilder(
        activeTabId: 'tab-1',
        overrides: [
          executionStateProvider.overrideWith(
            (ref) => ExecutionNotifier()..setRunning(),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // In "running" state: cancel button visible, send button absent.
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('send_button')), findsNothing);
    });
  });
}

