// Unit tests for OpenApiImportService.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/models/openapi_spec.dart';
import 'package:codeops/services/courier/openapi_import_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

final _spec = OpenApiSpec(
  title: 'User Service',
  version: '1.0.0',
  description: 'Manages users',
  tags: [
    const OpenApiTag(name: 'Auth', description: 'Authentication endpoints'),
    const OpenApiTag(name: 'Users', description: 'User management'),
  ],
  endpoints: [
    const OpenApiEndpoint(
      path: '/api/v1/auth/login',
      method: 'POST',
      summary: 'Login',
      tags: ['Auth'],
      requestBody: OpenApiRequestBody(
        required: true,
        content: {
          'application/json': OpenApiMediaType(
            schema: OpenApiSchema(
              type: 'object',
              properties: {
                'email': OpenApiSchema(type: 'string', format: null),
                'password': OpenApiSchema(type: 'string', format: null),
              },
            ),
          ),
        },
      ),
    ),
    const OpenApiEndpoint(
      path: '/api/v1/auth/register',
      method: 'POST',
      summary: 'Register',
      tags: ['Auth'],
    ),
    const OpenApiEndpoint(
      path: '/api/v1/users',
      method: 'GET',
      summary: 'List users',
      tags: ['Users'],
      parameters: [
        OpenApiParameter(name: 'page', location: 'query'),
        OpenApiParameter(name: 'size', location: 'query'),
      ],
    ),
    const OpenApiEndpoint(
      path: '/api/v1/users/{userId}',
      method: 'GET',
      summary: 'Get user by ID',
      tags: ['Users'],
      parameters: [
        OpenApiParameter(
            name: 'userId', location: 'path', required: true,
            schema: OpenApiSchema(type: 'string', format: 'uuid')),
      ],
    ),
    const OpenApiEndpoint(
      path: '/api/v1/users/{userId}',
      method: 'PUT',
      summary: 'Update user',
      tags: ['Users'],
      parameters: [
        OpenApiParameter(name: 'userId', location: 'path', required: true),
      ],
    ),
    const OpenApiEndpoint(
      path: '/api/v1/health',
      method: 'GET',
      summary: 'Health check',
      tags: [],
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('OpenApiImportService', () {
    const service = OpenApiImportService();

    test('uses spec title as collection name', () {
      final result = service.importSpec(_spec);
      expect(result.collectionName, 'User Service');
    });

    test('groups endpoints by tag into folders', () {
      final result = service.importSpec(_spec);
      expect(result.folders.length, 2);
      expect(result.folders[0].name, 'Auth');
      expect(result.folders[1].name, 'Users');
    });

    test('Auth folder has 2 requests', () {
      final result = service.importSpec(_spec);
      final auth = result.folders.firstWhere((f) => f.name == 'Auth');
      expect(auth.requests.length, 2);
      expect(auth.requests[0].name, 'Login');
      expect(auth.requests[1].name, 'Register');
    });

    test('Users folder has 3 requests', () {
      final result = service.importSpec(_spec);
      final users = result.folders.firstWhere((f) => f.name == 'Users');
      expect(users.requests.length, 3);
    });

    test('untagged endpoints go to ungroupedRequests', () {
      final result = service.importSpec(_spec);
      expect(result.ungroupedRequests.length, 1);
      expect(result.ungroupedRequests[0].name, 'Health check');
    });

    test('extracts query parameters', () {
      final result = service.importSpec(_spec);
      final users = result.folders.firstWhere((f) => f.name == 'Users');
      final listUsers = users.requests.firstWhere((r) => r.name == 'List users');
      expect(listUsers.queryParams.containsKey('page'), isTrue);
      expect(listUsers.queryParams.containsKey('size'), isTrue);
    });

    test('extracts path parameters', () {
      final result = service.importSpec(_spec);
      final users = result.folders.firstWhere((f) => f.name == 'Users');
      final getUser =
          users.requests.firstWhere((r) => r.name == 'Get user by ID');
      expect(getUser.pathParams.containsKey('userId'), isTrue);
    });

    test('generates request body from schema', () {
      final result = service.importSpec(_spec);
      final auth = result.folders.firstWhere((f) => f.name == 'Auth');
      final login = auth.requests.firstWhere((r) => r.name == 'Login');
      expect(login.requestBody, isNotNull);
      expect(login.requestBody!, contains('email'));
      expect(login.requestBody!, contains('password'));
    });

    test('maps HTTP methods correctly', () {
      final result = service.importSpec(_spec);
      final auth = result.folders.firstWhere((f) => f.name == 'Auth');
      expect(auth.requests[0].method, CourierHttpMethod.post);

      final users = result.folders.firstWhere((f) => f.name == 'Users');
      final getReq = users.requests.firstWhere((r) => r.name == 'List users');
      expect(getReq.method, CourierHttpMethod.get);

      final putReq =
          users.requests.firstWhere((r) => r.name == 'Update user');
      expect(putReq.method, CourierHttpMethod.put);
    });

    test('totalRequests counts all requests', () {
      final result = service.importSpec(_spec);
      expect(result.totalRequests, 6);
    });

    test('handles empty spec', () {
      final emptySpec = OpenApiSpec(title: 'Empty', version: '0.0.0');
      final result = service.importSpec(emptySpec);
      expect(result.collectionName, 'Empty');
      expect(result.folders, isEmpty);
      expect(result.ungroupedRequests, isEmpty);
      expect(result.totalRequests, 0);
    });
  });
}
