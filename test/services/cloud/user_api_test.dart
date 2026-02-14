// Tests for UserApi.
//
// Verifies that each method sends the correct request and
// deserializes responses into typed User objects.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/user_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late UserApi userApi;

  final userJson = {
    'id': 'user-1',
    'email': 'test@example.com',
    'displayName': 'Test User',
    'avatarUrl': null,
    'isActive': true,
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    userApi = UserApi(mockClient);
  });

  group('UserApi', () {
    test('getCurrentUser parses response correctly', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/users/me'))
          .thenAnswer((_) async => Response(
                data: userJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final user = await userApi.getCurrentUser();

      expect(user.id, 'user-1');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
    });

    test('getUserById fetches correct path', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/users/user-1'))
          .thenAnswer((_) async => Response(
                data: userJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final user = await userApi.getUserById('user-1');

      expect(user.id, 'user-1');
    });

    test('updateUser sends correct body', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/users/user-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {...userJson, 'displayName': 'Updated Name'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final user = await userApi.updateUser(
        'user-1',
        displayName: 'Updated Name',
      );

      expect(user.displayName, 'Updated Name');
      verify(() => mockClient.put<Map<String, dynamic>>(
            '/users/user-1',
            data: {'displayName': 'Updated Name'},
          )).called(1);
    });

    test('searchUsers returns list', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/users/search',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: [userJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final users = await userApi.searchUsers('test');

      expect(users, hasLength(1));
      expect(users.first.email, 'test@example.com');
    });

    test('deactivateUser calls correct endpoint', () async {
      when(() => mockClient.put('/users/user-1/deactivate'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await userApi.deactivateUser('user-1');

      verify(() => mockClient.put('/users/user-1/deactivate')).called(1);
    });

    test('activateUser calls correct endpoint', () async {
      when(() => mockClient.put('/users/user-1/activate'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      await userApi.activateUser('user-1');

      verify(() => mockClient.put('/users/user-1/activate')).called(1);
    });
  });
}
