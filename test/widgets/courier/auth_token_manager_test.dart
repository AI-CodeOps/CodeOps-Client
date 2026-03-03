// Widget tests for AuthTokenManager.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/courier/auth_token_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildTokenManager({
  OAuthToken? token,
  ValueChanged<String>? onUseToken,
  VoidCallback? onDelete,
  VoidCallback? onRefresh,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: AuthTokenManager(
          token: token,
          onUseToken: onUseToken,
          onDelete: onDelete,
          onRefresh: onRefresh,
        ),
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
  group('AuthTokenManager', () {
    testWidgets('shows nothing when token is null', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildTokenManager());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('token_manager')), findsNothing);
    });

    testWidgets('displays token with metadata', (tester) async {
      setSize(tester);
      final token = OAuthToken(
        accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature',
        tokenType: 'Bearer',
        scope: 'read write',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await tester.pumpWidget(buildTokenManager(token: token));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('token_manager')), findsOneWidget);
      expect(find.byKey(const Key('token_display')), findsOneWidget);
      expect(find.text('Type: Bearer'), findsOneWidget);
      expect(find.text('Scope: read write'), findsOneWidget);
    });

    testWidgets('shows delete button and calls onDelete', (tester) async {
      setSize(tester);
      var deleted = false;
      final token = OAuthToken(
        accessToken: 'test-token-value',
      );
      await tester.pumpWidget(buildTokenManager(
        token: token,
        onDelete: () => deleted = true,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('token_delete_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('token_delete_button')));
      await tester.pumpAndSettle();

      expect(deleted, true);
    });

    testWidgets('shows refresh button when refresh token available',
        (tester) async {
      setSize(tester);
      final token = OAuthToken(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );
      await tester.pumpWidget(buildTokenManager(token: token));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('token_refresh_button')), findsOneWidget);
    });

    testWidgets('OAuthToken.isExpired returns true for past expiry',
        (_) async {
      final token = OAuthToken(
        accessToken: 'test',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(token.isExpired, true);
    });

    testWidgets('OAuthToken.truncatedToken truncates long tokens',
        (_) async {
      final token = OAuthToken(
        accessToken: 'abcdefghij1234567890klmnopqrst',
      );
      expect(token.truncatedToken, contains('...'));
    });
  });
}
