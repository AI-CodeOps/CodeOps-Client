// Widget tests for ResponseCookiesTab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/courier/response_cookies_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildCookiesTab({Map<String, String> headers = const {}}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 900,
        height: 600,
        child: ResponseCookiesTab(headers: headers),
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
  group('ResponseCookiesTab', () {
    testWidgets('shows empty message when no cookies', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildCookiesTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cookies_empty')), findsOneWidget);
    });

    testWidgets('parses Set-Cookie headers', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildCookiesTab(headers: {
        'set-cookie': 'session_id=abc123; Path=/; HttpOnly; Secure',
      }));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('response_cookies_tab')), findsOneWidget);
      expect(find.text('session_id'), findsOneWidget);
      expect(find.text('abc123'), findsOneWidget);
    });

    testWidgets('displays cookie count', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildCookiesTab(headers: {
        'set-cookie': 'a=1; Path=/',
      }));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cookie_count')), findsOneWidget);
      expect(find.text('1 cookie'), findsOneWidget);
    });

    testWidgets('displays cookie attributes', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildCookiesTab(headers: {
        'set-cookie':
            'token=xyz; Domain=.example.com; Path=/api; Secure; HttpOnly; SameSite=Strict',
      }));
      await tester.pumpAndSettle();

      expect(find.text('token'), findsOneWidget);
      expect(find.text('.example.com'), findsOneWidget);
      expect(find.text('/api'), findsOneWidget);
      expect(find.text('Strict'), findsOneWidget);
    });
  });
}
