// Tests for AnthropicApiService.
//
// Verifies model fetching, API key testing, response parsing,
// and error mapping to typed ApiException subclasses.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/services/cloud/anthropic_api_service.dart';
import 'package:codeops/services/cloud/api_exceptions.dart';
import 'package:codeops/utils/constants.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {
  @override
  BaseOptions options = BaseOptions(
    baseUrl: AppConstants.anthropicApiBaseUrl,
    headers: <String, dynamic>{
      'anthropic-version': AppConstants.anthropicApiVersion,
      'content-type': 'application/json',
    },
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  );
}

void main() {
  late MockDio mockDio;
  late AnthropicApiService service;

  setUp(() {
    mockDio = MockDio();
    service = AnthropicApiService(dio: mockDio);
  });

  group('AnthropicApiService', () {
    group('validateAndFetchModels', () {
      test('parses models from API response', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => Response(
                  data: {
                    'data': [
                      {
                        'id': 'claude-sonnet-4-20250514',
                        'display_name': 'Claude Sonnet 4',
                        'type': 'model',
                        'context_window': 200000,
                        'max_output_tokens': 16384,
                        'created_at': '2025-05-14T00:00:00Z',
                      },
                      {
                        'id': 'claude-opus-4-20250514',
                        'display_name': 'Claude Opus 4',
                        'type': 'model',
                        'context_window': 200000,
                        'max_output_tokens': 32768,
                        'created_at': '2025-05-14T00:00:00Z',
                      },
                    ],
                  },
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/v1/models'),
                ));

        final models = await service.validateAndFetchModels('sk-test-key');

        expect(models, hasLength(2));
        expect(models[0].id, 'claude-sonnet-4-20250514');
        expect(models[0].displayName, 'Claude Sonnet 4');
        expect(models[0].contextWindow, 200000);
        expect(models[0].maxOutputTokens, 16384);
        expect(models[1].id, 'claude-opus-4-20250514');
      });

      test('filters out non-model entries', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => Response(
                  data: {
                    'data': [
                      {
                        'id': 'claude-sonnet-4-20250514',
                        'display_name': 'Claude Sonnet 4',
                        'type': 'model',
                      },
                      {
                        'id': 'some-other-thing',
                        'type': 'not_a_model',
                      },
                    ],
                  },
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/v1/models'),
                ));

        final models = await service.validateAndFetchModels('sk-test-key');

        expect(models, hasLength(1));
        expect(models[0].id, 'claude-sonnet-4-20250514');
      });

      test('sets x-api-key header', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => Response(
                  data: {'data': <dynamic>[]},
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/v1/models'),
                ));

        await service.validateAndFetchModels('sk-my-key');

        expect(mockDio.options.headers['x-api-key'], 'sk-my-key');
      });

      test('throws UnauthorizedException on 401', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            data: {'error': {'message': 'Invalid key'}},
            requestOptions: RequestOptions(path: '/v1/models'),
          ),
          requestOptions: RequestOptions(path: '/v1/models'),
        ));

        expect(
          () => service.validateAndFetchModels('bad-key'),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('throws TimeoutException on connection timeout', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/v1/models'),
          message: 'Connection timeout',
        ));

        expect(
          () => service.validateAndFetchModels('sk-key'),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('throws NetworkException on connection error', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/v1/models'),
          message: 'Network error',
        ));

        expect(
          () => service.validateAndFetchModels('sk-key'),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('testApiKey', () {
      test('returns true on 200 response', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenAnswer((_) async => Response(
                  data: {'data': <dynamic>[]},
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/v1/models'),
                ));

        final result = await service.testApiKey('sk-valid-key');

        expect(result, isTrue);
      });

      test('returns false on DioException', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/v1/models'),
          ),
          requestOptions: RequestOptions(path: '/v1/models'),
        ));

        final result = await service.testApiKey('sk-bad-key');

        expect(result, isFalse);
      });

      test('returns false on unexpected error', () async {
        when(() => mockDio.get<Map<String, dynamic>>(any()))
            .thenThrow(Exception('unexpected'));

        final result = await service.testApiKey('sk-key');

        expect(result, isFalse);
      });
    });
  });
}
