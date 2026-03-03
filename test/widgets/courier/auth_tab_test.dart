// Widget tests for AuthTab.
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
  group('AuthTab', () {
    testWidgets('renders auth type selector', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildAuthTab());
      await tester.pumpAndSettle();

      expect(find.byType(AuthTab), findsOneWidget);
      expect(find.byKey(const Key('auth_type_selector')), findsOneWidget);
      expect(find.byKey(const Key('auth_type_dropdown')), findsOneWidget);
    });

    testWidgets('shows no auth message by default', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildAuthTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no_auth_message')), findsOneWidget);
      expect(
          find.text('This request does not use any authorization.'),
          findsOneWidget);
    });

    testWidgets('shows API Key form', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildAuthTab(authType: AuthType.apiKey));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('api_key_form')), findsOneWidget);
      expect(find.byKey(const Key('api_key_header_field')), findsOneWidget);
      expect(find.byKey(const Key('api_key_value_field')), findsOneWidget);
      expect(
          find.byKey(const Key('api_key_add_to_dropdown')), findsOneWidget);
    });

    testWidgets('shows Bearer Token form', (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildAuthTab(authType: AuthType.bearerToken));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bearer_token_form')), findsOneWidget);
      expect(find.byKey(const Key('bearer_token_field')), findsOneWidget);
      expect(find.byKey(const Key('bearer_prefix_field')), findsOneWidget);
    });

    testWidgets('shows Basic Auth form with preview', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildAuthTab(
        authType: AuthType.basicAuth,
        overrides: [
          authBasicUsernameProvider.overrideWith((ref) => 'user'),
          authBasicPasswordProvider.overrideWith((ref) => 'pass'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('basic_auth_form')), findsOneWidget);
      expect(find.byKey(const Key('basic_username_field')), findsOneWidget);
      expect(find.byKey(const Key('basic_password_field')), findsOneWidget);
      expect(find.byKey(const Key('basic_auth_preview')), findsOneWidget);
    });

    testWidgets('shows OAuth2 Authorization Code form', (tester) async {
      setSize(tester);
      await tester.pumpWidget(
          buildAuthTab(authType: AuthType.oauth2AuthorizationCode));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('oauth2_auth_code_form')), findsOneWidget);
      expect(
          find.byKey(const Key('oauth2_auth_url_field')), findsOneWidget);
      expect(
          find.byKey(const Key('oauth2_token_url_field')), findsOneWidget);
      expect(
          find.byKey(const Key('oauth2_get_token_button')), findsOneWidget);
    });

    testWidgets('shows OAuth2 Client Credentials form', (tester) async {
      setSize(tester);
      await tester.pumpWidget(
          buildAuthTab(authType: AuthType.oauth2ClientCredentials));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('oauth2_client_cred_form')), findsOneWidget);
      expect(find.byKey(const Key('oauth2_cc_token_url_field')),
          findsOneWidget);
    });

    testWidgets('shows OAuth2 Implicit form', (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildAuthTab(authType: AuthType.oauth2Implicit));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('oauth2_implicit_form')), findsOneWidget);
      expect(find.byKey(const Key('oauth2_imp_auth_url_field')),
          findsOneWidget);
    });

    testWidgets('shows OAuth2 Password form', (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildAuthTab(authType: AuthType.oauth2Password));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('oauth2_password_form')), findsOneWidget);
      expect(find.byKey(const Key('oauth2_pw_token_url_field')),
          findsOneWidget);
      expect(find.byKey(const Key('oauth2_pw_username_field')),
          findsOneWidget);
    });

    testWidgets('shows JWT Bearer form', (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildAuthTab(authType: AuthType.jwtBearer));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('jwt_bearer_form')), findsOneWidget);
      expect(
          find.byKey(const Key('jwt_algorithm_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('jwt_secret_field')), findsOneWidget);
      expect(find.byKey(const Key('jwt_payload_field')), findsOneWidget);
      expect(find.byKey(const Key('jwt_generate_button')), findsOneWidget);
    });

    testWidgets('shows Inherit from Parent message', (tester) async {
      setSize(tester);
      await tester.pumpWidget(
          buildAuthTab(authType: AuthType.inheritFromParent));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('inherit_auth_message')), findsOneWidget);
      expect(
        find.text(
            'This request inherits auth from its parent folder or collection.'),
        findsOneWidget,
      );
    });

    testWidgets('shows auth preview for bearer token', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildAuthTab(
        authType: AuthType.bearerToken,
        overrides: [
          authBearerTokenProvider.overrideWith((ref) => 'my-secret-token'),
          authBearerPrefixProvider.overrideWith((ref) => 'Bearer'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_preview')), findsOneWidget);
      expect(find.textContaining('Authorization: Bearer'), findsWidgets);
    });
  });
}
