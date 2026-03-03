// Unit tests for auth application in HttpExecutionService.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/services/courier/http_execution_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Builds auth headers that would be applied before sending a request.
///
/// This mirrors the auth application logic that will be integrated into
/// [HttpExecutionService.execute] in a future execution-phase task.
Map<String, String> applyAuth({
  required AuthType authType,
  String apiKeyHeader = '',
  String apiKeyValue = '',
  String apiKeyAddTo = 'header',
  String bearerToken = '',
  String bearerPrefix = 'Bearer',
  String basicUsername = '',
  String basicPassword = '',
  String oauth2AccessToken = '',
  String jwtToken = '',
}) {
  final headers = <String, String>{};

  switch (authType) {
    case AuthType.noAuth:
      break;

    case AuthType.apiKey:
      if (apiKeyAddTo == 'header' && apiKeyHeader.isNotEmpty) {
        headers[apiKeyHeader] = apiKeyValue;
      }
      // Query params would be applied to the URL, not headers.

    case AuthType.bearerToken:
      if (bearerToken.isNotEmpty) {
        headers['Authorization'] = '$bearerPrefix $bearerToken';
      }

    case AuthType.basicAuth:
      if (basicUsername.isNotEmpty || basicPassword.isNotEmpty) {
        final encoded =
            base64Encode(utf8.encode('$basicUsername:$basicPassword'));
        headers['Authorization'] = 'Basic $encoded';
      }

    case AuthType.oauth2AuthorizationCode:
    case AuthType.oauth2ClientCredentials:
    case AuthType.oauth2Implicit:
    case AuthType.oauth2Password:
      if (oauth2AccessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $oauth2AccessToken';
      }

    case AuthType.jwtBearer:
      if (jwtToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwtToken';
      }

    case AuthType.inheritFromParent:
      // Resolution deferred to execution time via parent chain traversal.
      break;
  }

  return headers;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Auth application logic', () {
    test('noAuth produces no headers', () {
      final headers = applyAuth(authType: AuthType.noAuth);
      expect(headers, isEmpty);
    });

    test('API Key adds to header', () {
      final headers = applyAuth(
        authType: AuthType.apiKey,
        apiKeyHeader: 'X-API-Key',
        apiKeyValue: 'secret123',
        apiKeyAddTo: 'header',
      );
      expect(headers['X-API-Key'], 'secret123');
    });

    test('API Key with query addTo does not add header', () {
      final headers = applyAuth(
        authType: AuthType.apiKey,
        apiKeyHeader: 'api_key',
        apiKeyValue: 'secret',
        apiKeyAddTo: 'query',
      );
      expect(headers, isEmpty);
    });

    test('Bearer Token sets Authorization header', () {
      final headers = applyAuth(
        authType: AuthType.bearerToken,
        bearerToken: 'my-token',
        bearerPrefix: 'Bearer',
      );
      expect(headers['Authorization'], 'Bearer my-token');
    });

    test('Basic Auth sets base64-encoded Authorization header', () {
      final headers = applyAuth(
        authType: AuthType.basicAuth,
        basicUsername: 'user',
        basicPassword: 'pass',
      );
      final expected =
          'Basic ${base64Encode(utf8.encode('user:pass'))}';
      expect(headers['Authorization'], expected);
    });

    test('OAuth2 sets Bearer token header', () {
      final headers = applyAuth(
        authType: AuthType.oauth2ClientCredentials,
        oauth2AccessToken: 'oauth-access-token',
      );
      expect(headers['Authorization'], 'Bearer oauth-access-token');
    });

    test('JWT Bearer sets Authorization header', () {
      final headers = applyAuth(
        authType: AuthType.jwtBearer,
        jwtToken: 'eyJhbGciOiJIUzI1NiJ9.test.sig',
      );
      expect(headers['Authorization'],
          'Bearer eyJhbGciOiJIUzI1NiJ9.test.sig');
    });

    test('inheritFromParent produces no headers (deferred)', () {
      final headers = applyAuth(authType: AuthType.inheritFromParent);
      expect(headers, isEmpty);
    });

    test('HttpExecutionRequest accepts auth headers', () {
      // Verify that auth headers can be passed through to the execution
      // request and are preserved.
      const request = HttpExecutionRequest(
        method: CourierHttpMethod.get,
        url: 'https://api.example.com/data',
        headers: {'Authorization': 'Bearer test-token'},
      );
      expect(request.headers['Authorization'], 'Bearer test-token');
    });
  });
}
