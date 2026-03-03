// Widget tests for auth preview section.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/auth_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildAuthTab({
  AuthType authType = AuthType.noAuth,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      authTypeProvider.overrideWith((ref) => authType),
      authApiKeyHeaderProvider.overrideWith((ref) => ''),
      authApiKeyValueProvider.overrideWith((ref) => ''),
      authApiKeyAddToProvider.overrideWith((ref) => 'header'),
      authBearerTokenProvider.overrideWith((ref) => ''),
      authBearerPrefixProvider.overrideWith((ref) => 'Bearer'),
      authBasicUsernameProvider.overrideWith((ref) => ''),
      authBasicPasswordProvider.overrideWith((ref) => ''),
      authOAuth2AuthUrlProvider.overrideWith((ref) => ''),
      authOAuth2TokenUrlProvider.overrideWith((ref) => ''),
      authOAuth2ClientIdProvider.overrideWith((ref) => ''),
      authOAuth2ClientSecretProvider.overrideWith((ref) => ''),
      authOAuth2ScopeProvider.overrideWith((ref) => ''),
      authOAuth2CallbackUrlProvider
          .overrideWith((ref) => 'https://localhost/callback'),
      authOAuth2AccessTokenProvider.overrideWith((ref) => ''),
      authOAuth2GrantTypeProvider.overrideWith((ref) => ''),
      authJwtAlgorithmProvider.overrideWith((ref) => 'HS256'),
      authJwtSecretProvider.overrideWith((ref) => ''),
      authJwtPayloadProvider.overrideWith((ref) => '{}'),
      authJwtGeneratedTokenProvider.overrideWith((ref) => ''),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: AuthTab(),
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
  group('AuthPreview', () {
    testWidgets('shows header preview for API Key', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildAuthTab(
        authType: AuthType.apiKey,
        overrides: [
          authApiKeyHeaderProvider.overrideWith((ref) => 'X-API-Key'),
          authApiKeyValueProvider.overrideWith((ref) => 'abc123'),
          authApiKeyAddToProvider.overrideWith((ref) => 'header'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_preview')), findsOneWidget);
      expect(find.textContaining('X-API-Key: abc123'), findsOneWidget);
    });

    testWidgets('shows query preview for API Key with query addTo',
        (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildAuthTab(
        authType: AuthType.apiKey,
        overrides: [
          authApiKeyHeaderProvider.overrideWith((ref) => 'api_key'),
          authApiKeyValueProvider.overrideWith((ref) => 'secret'),
          authApiKeyAddToProvider.overrideWith((ref) => 'query'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_preview')), findsOneWidget);
      expect(find.textContaining('?api_key=secret'), findsOneWidget);
    });

    testWidgets('shows Basic Auth base64 preview', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildAuthTab(
        authType: AuthType.basicAuth,
        overrides: [
          authBasicUsernameProvider.overrideWith((ref) => 'admin'),
          authBasicPasswordProvider.overrideWith((ref) => 'pass'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_preview')), findsOneWidget);
      expect(
          find.textContaining('Authorization: Basic'), findsAtLeastNWidgets(1));
    });
  });
}
