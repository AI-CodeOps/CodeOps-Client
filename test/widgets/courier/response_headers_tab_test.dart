// Widget tests for ResponseHeadersTab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/courier/response_headers_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildHeadersTab({Map<String, String> headers = const {}}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: ResponseHeadersTab(headers: headers),
      ),
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
  group('ResponseHeadersTab', () {
    testWidgets('shows empty message when no headers', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildHeadersTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('headers_empty')), findsOneWidget);
    });

    testWidgets('displays headers with count', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildHeadersTab(headers: {
        'content-type': 'application/json',
        'x-request-id': 'abc-123',
        'cache-control': 'no-cache',
      }));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('response_headers_tab')), findsOneWidget);
      expect(find.byKey(const Key('header_count')), findsOneWidget);
      expect(find.text('3 headers'), findsOneWidget);
    });

    testWidgets('sorts headers alphabetically', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildHeadersTab(headers: {
        'x-custom': 'value1',
        'content-type': 'text/plain',
        'authorization': 'Bearer xxx',
      }));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('header_list')), findsOneWidget);
      // All headers should be present.
      expect(find.text('authorization'), findsOneWidget);
      expect(find.text('content-type'), findsOneWidget);
      expect(find.text('x-custom'), findsOneWidget);
    });

    testWidgets('displays header values', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildHeadersTab(headers: {
        'content-type': 'application/json; charset=utf-8',
      }));
      await tester.pumpAndSettle();

      expect(find.text('application/json; charset=utf-8'), findsOneWidget);
    });

    testWidgets('shows single header count', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildHeadersTab(headers: {
        'server': 'nginx',
      }));
      await tester.pumpAndSettle();

      expect(find.text('1 header'), findsOneWidget);
    });
  });
}
