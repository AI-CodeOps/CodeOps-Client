// Tests for AuthService.
//
// Verifies login, register, logout, tryAutoLogin, and changePassword
// flows with mocked ApiClient and SecureStorageService.
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/database/database.dart' hide User;
import 'package:codeops/services/auth/auth_service.dart';
import 'package:codeops/services/auth/secure_storage.dart';
import 'package:codeops/services/cloud/api_client.dart';

class MockApiClient extends Mock implements ApiClient {
  @override
  VoidCallback? onAuthFailure;
}

class MockSecureStorage extends Mock implements SecureStorageService {}

class MockDatabase extends Mock implements CodeOpsDatabase {}

void main() {
  late MockApiClient mockApiClient;
  late MockSecureStorage mockSecureStorage;
  late MockDatabase mockDatabase;
  late AuthService authService;

  final loginResponse = {
    'token': 'access-token',
    'refreshToken': 'refresh-token',
    'user': {
      'id': 'user-123',
      'email': 'test@example.com',
      'displayName': 'Test User',
    },
  };

  setUp(() {
    mockApiClient = MockApiClient();
    mockSecureStorage = MockSecureStorage();
    mockDatabase = MockDatabase();

    authService = AuthService(
      apiClient: mockApiClient,
      secureStorage: mockSecureStorage,
      database: mockDatabase,
    );
  });

  tearDown(() {
    authService.dispose();
  });

  group('AuthService', () {
    test('initial state is unknown', () {
      expect(authService.currentState, AuthState.unknown);
      expect(authService.currentUser, isNull);
    });

    group('login', () {
      test('stores tokens and emits authenticated', () async {
        when(() => mockApiClient.post<Map<String, dynamic>>(
              '/auth/login',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: loginResponse,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        when(() => mockSecureStorage.setAuthToken('access-token'))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.setRefreshToken('refresh-token'))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.setCurrentUserId('user-123'))
            .thenAnswer((_) async {});

        final user = await authService.login('test@example.com', 'password');

        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
        expect(authService.currentState, AuthState.authenticated);
        expect(authService.currentUser, isNotNull);
        verify(() => mockSecureStorage.setAuthToken('access-token')).called(1);
        verify(() => mockSecureStorage.setRefreshToken('refresh-token'))
            .called(1);
      });

      test('emits authenticated to stream', () async {
        when(() => mockApiClient.post<Map<String, dynamic>>(
              '/auth/login',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: loginResponse,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        when(() => mockSecureStorage.setAuthToken(any()))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.setRefreshToken(any()))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.setCurrentUserId(any()))
            .thenAnswer((_) async {});

        expectLater(
          authService.authStateStream,
          emitsInOrder([AuthState.authenticated]),
        );

        await authService.login('test@example.com', 'password');
      });
    });

    group('register', () {
      test('stores tokens and emits authenticated', () async {
        when(() => mockApiClient.post<Map<String, dynamic>>(
              '/auth/register',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: loginResponse,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        when(() => mockSecureStorage.setAuthToken(any()))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.setRefreshToken(any()))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.setCurrentUserId(any()))
            .thenAnswer((_) async {});

        final user = await authService.register(
          'test@example.com',
          'password',
          'Test User',
        );

        expect(user.email, 'test@example.com');
        expect(authService.currentState, AuthState.authenticated);
      });
    });

    group('logout', () {
      test('clears storage, wipes database, and emits unauthenticated',
          () async {
        when(() => mockSecureStorage.clearAll()).thenAnswer((_) async {});
        when(() => mockDatabase.clearAllTables()).thenAnswer((_) async {});

        await authService.logout();

        expect(authService.currentState, AuthState.unauthenticated);
        expect(authService.currentUser, isNull);
        verify(() => mockSecureStorage.clearAll()).called(1);
        verify(() => mockDatabase.clearAllTables()).called(1);
      });
    });

    group('tryAutoLogin', () {
      test('emits unauthenticated when no token stored', () async {
        when(() => mockSecureStorage.getAuthToken())
            .thenAnswer((_) async => null);

        await authService.tryAutoLogin();

        expect(authService.currentState, AuthState.unauthenticated);
      });

      test('emits authenticated when token is valid', () async {
        when(() => mockSecureStorage.getAuthToken())
            .thenAnswer((_) async => 'valid-token');
        when(() => mockApiClient.get<Map<String, dynamic>>('/users/me'))
            .thenAnswer((_) async => Response(
                  data: {
                    'id': 'user-123',
                    'email': 'test@example.com',
                    'displayName': 'Test User',
                  },
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        await authService.tryAutoLogin();

        expect(authService.currentState, AuthState.authenticated);
        expect(authService.currentUser?.email, 'test@example.com');
      });

      test('emits unauthenticated when token is expired', () async {
        when(() => mockSecureStorage.getAuthToken())
            .thenAnswer((_) async => 'expired-token');
        when(() => mockSecureStorage.clearAll()).thenAnswer((_) async {});
        when(() => mockApiClient.get<Map<String, dynamic>>('/users/me'))
            .thenThrow(DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          error: const UnauthorizedException('expired'),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
          ),
        ));

        await authService.tryAutoLogin();

        expect(authService.currentState, AuthState.unauthenticated);
      });
    });

    group('changePassword', () {
      test('sends correct request body', () async {
        when(() => mockApiClient.post(
              '/auth/change-password',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await authService.changePassword('old-pass', 'new-pass');

        verify(() => mockApiClient.post(
              '/auth/change-password',
              data: {
                'currentPassword': 'old-pass',
                'newPassword': 'new-pass',
              },
            )).called(1);
      });
    });

    group('refreshToken', () {
      test('emits unauthenticated when no refresh token', () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => null);

        await authService.refreshToken();

        expect(authService.currentState, AuthState.unauthenticated);
      });

      test('stores new tokens on success', () async {
        when(() => mockSecureStorage.getRefreshToken())
            .thenAnswer((_) async => 'old-refresh');
        when(() => mockApiClient.post<Map<String, dynamic>>(
              '/auth/refresh',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: loginResponse,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));
        when(() => mockSecureStorage.setAuthToken(any()))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.setRefreshToken(any()))
            .thenAnswer((_) async {});
        when(() => mockSecureStorage.setCurrentUserId(any()))
            .thenAnswer((_) async {});

        await authService.refreshToken();

        verify(() => mockSecureStorage.setAuthToken('access-token')).called(1);
        verify(() => mockSecureStorage.setRefreshToken('refresh-token'))
            .called(1);
      });
    });
  });
}

// Needed for Mocktail to match UnauthorizedException
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);
}
