// Tests for ApiClient.
//
// Verifies auth header injection, 401 refresh flow,
// and error mapping to typed ApiException subclasses.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/services/auth/secure_storage.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/api_exceptions.dart';

class MockSecureStorage extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorage mockStorage;
  late ApiClient apiClient;

  setUp(() {
    mockStorage = MockSecureStorage();
    apiClient = ApiClient(secureStorage: mockStorage);
  });

  group('ApiClient', () {
    test('has correct baseUrl', () {
      expect(apiClient.dio.options.baseUrl, contains('/api/v1'));
    });

    test('has JSON content headers', () {
      expect(apiClient.dio.options.headers['Content-Type'], 'application/json');
      expect(apiClient.dio.options.headers['Accept'], 'application/json');
    });

    test('has reasonable timeout values', () {
      expect(apiClient.dio.options.connectTimeout, const Duration(seconds: 15));
      expect(apiClient.dio.options.receiveTimeout, const Duration(seconds: 30));
      expect(apiClient.dio.options.sendTimeout, const Duration(seconds: 15));
    });

    test('has interceptors configured', () {
      // Auth, refresh, error, and optionally log interceptor
      expect(apiClient.dio.interceptors.length, greaterThanOrEqualTo(3));
    });

    group('error mapping', () {
      test('maps 400 to BadRequestException', () async {
        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'token');

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 400,
          data: {'message': 'Bad request'},
        );

        try {
          await apiClient.get('/test');
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.error, isA<BadRequestException>());
          expect((e.error as BadRequestException).message, 'Bad request');
        }
      });

      test('maps 404 to NotFoundException', () async {
        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'token');

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 404,
          data: {'message': 'Not found'},
        );

        try {
          await apiClient.get('/test');
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.error, isA<NotFoundException>());
        }
      });

      test('maps 409 to ConflictException', () async {
        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'token');

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 409,
          data: {'message': 'Duplicate'},
        );

        try {
          await apiClient.get('/test');
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ConflictException>());
        }
      });

      test('maps 422 to ValidationException', () async {
        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'token');

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 422,
          data: {'message': 'Invalid input'},
        );

        try {
          await apiClient.get('/test');
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ValidationException>());
        }
      });

      test('maps 429 to RateLimitException', () async {
        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'token');

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 429,
          data: {'message': 'Too many requests'},
        );

        try {
          await apiClient.get('/test');
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.error, isA<RateLimitException>());
        }
      });

      test('maps 500 to ServerException', () async {
        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'token');

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 500,
          data: {'message': 'Internal error'},
        );

        try {
          await apiClient.get('/test');
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ServerException>());
        }
      });

      test('maps 403 to ForbiddenException', () async {
        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'token');

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 403,
          data: {'message': 'Access denied'},
        );

        try {
          await apiClient.get('/test');
          fail('Should have thrown');
        } on DioException catch (e) {
          expect(e.error, isA<ForbiddenException>());
        }
      });
    });

    group('auth header injection', () {
      test('attaches Bearer token for non-public paths', () async {
        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'my-jwt');

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 200,
          data: {'ok': true},
          onRequest: (options) {
            expect(options.headers['Authorization'], 'Bearer my-jwt');
          },
        );

        await apiClient.get('/users/me');
      });

      test('skips auth header for /auth/login', () async {
        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 200,
          data: {'token': 'test'},
          onRequest: (options) {
            expect(options.headers.containsKey('Authorization'), false);
          },
        );

        await apiClient.post('/auth/login', data: {});
      });
    });

    group('onAuthFailure callback', () {
      test('is called when refresh fails on 401', () async {
        var authFailureCalled = false;
        apiClient.onAuthFailure = () => authFailureCalled = true;

        when(() => mockStorage.getAuthToken())
            .thenAnswer((_) async => 'expired');
        when(() => mockStorage.getRefreshToken())
            .thenAnswer((_) async => null);

        apiClient.dio.httpClientAdapter = _MockAdapter(
          statusCode: 401,
          data: {'message': 'Token expired'},
        );

        try {
          await apiClient.get('/users/me');
        } on DioException {
          // Expected
        }

        expect(authFailureCalled, true);
      });
    });
  });
}

/// Minimal HttpClientAdapter that returns a canned response.
class _MockAdapter implements HttpClientAdapter {
  final int statusCode;
  final dynamic data;
  final void Function(RequestOptions)? onRequest;

  _MockAdapter({
    required this.statusCode,
    required this.data,
    this.onRequest,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest?.call(options);

    if (statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: data,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    // Return a successful response by encoding data
    final responseStr =
        data is String ? data : data.toString();
    return ResponseBody.fromString(responseStr, statusCode);
  }

  @override
  void close({bool force = false}) {}
}
