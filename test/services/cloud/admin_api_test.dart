// Tests for AdminApi.
//
// Verifies user management, system settings, audit logs, usage stats,
// and error handling for admin endpoints.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/services/cloud/admin_api.dart';
import 'package:codeops/services/cloud/api_client.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late AdminApi adminApi;

  final userJson = {
    'id': 'user-1',
    'email': 'alice@test.com',
    'displayName': 'Alice',
    'isActive': true,
    'lastLoginAt': '2024-01-01T00:00:00.000Z',
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  final userPageJson = {
    'content': [userJson],
    'page': 0,
    'size': 20,
    'totalElements': 1,
    'totalPages': 1,
    'isLast': true,
  };

  final settingJson = {
    'key': 'max_team_members',
    'value': '50',
    'updatedBy': 'admin-1',
    'updatedAt': '2024-01-01T00:00:00.000Z',
  };

  final auditJson = {
    'id': 1,
    'userId': 'user-1',
    'userName': 'Alice',
    'action': 'LOGIN',
    'entityType': 'USER',
    'entityId': 'user-1',
    'details': 'User logged in',
    'ipAddress': '127.0.0.1',
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  final auditPageJson = {
    'content': [auditJson],
    'page': 0,
    'size': 20,
    'totalElements': 1,
    'totalPages': 1,
    'isLast': true,
  };

  setUp(() {
    mockClient = MockApiClient();
    adminApi = AdminApi(mockClient);
  });

  group('AdminApi', () {
    test('getAllUsers returns paginated users', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/admin/users',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
                data: userPageJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final page = await adminApi.getAllUsers();

      expect(page.content, hasLength(1));
      expect(page.content.first.email, 'alice@test.com');
      expect(page.totalElements, 1);
      verify(() => mockClient.get<Map<String, dynamic>>(
            '/admin/users',
            queryParameters: {'page': 0, 'size': 20},
          )).called(1);
    });

    test('getUserById fetches user by ID', () async {
      when(() =>
              mockClient.get<Map<String, dynamic>>('/admin/users/user-1'))
          .thenAnswer((_) async => Response(
                data: userJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final user = await adminApi.getUserById('user-1');

      expect(user.id, 'user-1');
      expect(user.displayName, 'Alice');
    });

    test('updateUserStatus sends isActive in body', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/admin/users/user-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {...userJson, 'isActive': false},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final user =
          await adminApi.updateUserStatus('user-1', isActive: false);

      expect(user.id, 'user-1');
      verify(() => mockClient.put<Map<String, dynamic>>(
            '/admin/users/user-1',
            data: {'isActive': false},
          )).called(1);
    });

    test('getAllSettings returns list of settings', () async {
      when(() => mockClient.get<List<dynamic>>('/admin/settings'))
          .thenAnswer((_) async => Response(
                data: [settingJson],
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final settings = await adminApi.getAllSettings();

      expect(settings, hasLength(1));
      expect(settings.first.key, 'max_team_members');
      expect(settings.first.value, '50');
    });

    test('getSetting fetches by key', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/admin/settings/max_team_members',
          )).thenAnswer((_) async => Response(
                data: settingJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final setting = await adminApi.getSetting('max_team_members');

      expect(setting.key, 'max_team_members');
      expect(setting.value, '50');
    });

    test('updateSetting sends key and value in body', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/admin/settings',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {...settingJson, 'value': '100'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final setting = await adminApi.updateSetting(
        key: 'max_team_members',
        value: '100',
      );

      expect(setting.key, 'max_team_members');
      verify(() => mockClient.put<Map<String, dynamic>>(
            '/admin/settings',
            data: {'key': 'max_team_members', 'value': '100'},
          )).called(1);
    });

    test('getUsageStats returns raw map', () async {
      final usageJson = {
        'totalUsers': 10,
        'activeUsers': 8,
        'totalTeams': 3,
      };

      when(() => mockClient.get<Map<String, dynamic>>('/admin/usage'))
          .thenAnswer((_) async => Response(
                data: usageJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final stats = await adminApi.getUsageStats();

      expect(stats['totalUsers'], 10);
      expect(stats['activeUsers'], 8);
    });

    test('getTeamAuditLog returns paginated audit entries', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/admin/audit-log/team/team-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
                data: auditPageJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final page = await adminApi.getTeamAuditLog('team-1');

      expect(page.content, hasLength(1));
      expect(page.content.first.action, 'LOGIN');
      expect(page.content.first.userName, 'Alice');
      verify(() => mockClient.get<Map<String, dynamic>>(
            '/admin/audit-log/team/team-1',
            queryParameters: {'page': 0, 'size': 20},
          )).called(1);
    });

    test('getUserAuditLog returns paginated audit entries', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/admin/audit-log/user/user-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
                data: auditPageJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final page = await adminApi.getUserAuditLog('user-1');

      expect(page.content, hasLength(1));
      expect(page.content.first.userId, 'user-1');
      expect(page.content.first.ipAddress, '127.0.0.1');
      verify(() => mockClient.get<Map<String, dynamic>>(
            '/admin/audit-log/user/user-1',
            queryParameters: {'page': 0, 'size': 20},
          )).called(1);
    });

    test('getAllUsers throws on DioException', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/admin/users',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ));

      expect(
        () => adminApi.getAllUsers(),
        throwsA(isA<DioException>()),
      );
    });

    test('getTeamAuditLog throws on DioException', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/admin/audit-log/team/team-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 403,
            ),
            type: DioExceptionType.badResponse,
          ));

      expect(
        () => adminApi.getTeamAuditLog('team-1'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
