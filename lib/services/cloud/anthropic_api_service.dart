/// Anthropic API client for model discovery and API key validation.
///
/// Uses its own [Dio] instance targeting `https://api.anthropic.com`,
/// separate from the app's [ApiClient] which targets the CodeOps server.
/// Follows the [GitHubProvider] pattern for error mapping.
library;

import 'package:dio/dio.dart';

import '../../models/anthropic_model_info.dart';
import '../../utils/constants.dart';
import '../logging/log_service.dart';
import 'api_exceptions.dart';

/// Client for the Anthropic REST API.
///
/// Provides model listing and API key validation. Never logs API key values.
class AnthropicApiService {
  final Dio _dio;

  /// Creates an [AnthropicApiService] with an optional custom [Dio] instance.
  AnthropicApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.anthropicApiBaseUrl,
              headers: {
                'anthropic-version': AppConstants.anthropicApiVersion,
                'content-type': 'application/json',
              },
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// Validates the API key and fetches available models.
  ///
  /// Sets the `x-api-key` header, calls `GET /v1/models`, and returns
  /// parsed [AnthropicModelInfo] entries. Throws [ApiException] subtypes
  /// on failure.
  Future<List<AnthropicModelInfo>> validateAndFetchModels(
    String apiKey,
  ) async {
    _dio.options.headers['x-api-key'] = apiKey;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/models');
      return _parseModelsResponse(response.data);
    } on DioException catch (e) {
      _mapDioException(e);
    }
  }

  /// Fetches models using a previously stored API key.
  ///
  /// Identical to [validateAndFetchModels] but named for clarity when
  /// the key is known-good.
  Future<List<AnthropicModelInfo>> fetchModels(String apiKey) async {
    return validateAndFetchModels(apiKey);
  }

  /// Tests whether the given API key is valid.
  ///
  /// Returns `true` if the key authenticates successfully (HTTP 200),
  /// `false` otherwise. Does not throw.
  Future<bool> testApiKey(String apiKey) async {
    _dio.options.headers['x-api-key'] = apiKey;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/models');
      return response.statusCode == 200;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Parses the `/v1/models` response into model info objects.
  List<AnthropicModelInfo> _parseModelsResponse(Map<String, dynamic>? data) {
    if (data == null) return [];

    final rawList = data['data'] as List<dynamic>? ?? [];
    final models = <AnthropicModelInfo>[];

    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final type = item['type'] as String?;
        if (type == 'model') {
          models.add(AnthropicModelInfo.fromApiJson(item));
        }
      }
    }

    log.i('AnthropicApiService',
        'Fetched ${models.length} models from Anthropic API');
    return models;
  }

  /// Maps [DioException] to typed [ApiException] subtypes.
  Never _mapDioException(DioException e) {
    log.e('AnthropicApiService', 'API error: ${e.type}', e);

    final statusCode = e.response?.statusCode;
    final message = _extractErrorMessage(e);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw TimeoutException(message);
      case DioExceptionType.connectionError:
        throw NetworkException(message);
      default:
        break;
    }

    switch (statusCode) {
      case 400:
        throw BadRequestException(message);
      case 401:
        throw const UnauthorizedException('Invalid Anthropic API key');
      case 403:
        throw const ForbiddenException('API key lacks required permissions');
      case 404:
        throw const NotFoundException('Anthropic API endpoint not found');
      case 429:
        throw RateLimitException(message);
      default:
        if (statusCode != null && statusCode >= 500) {
          throw ServerException(message, statusCode: statusCode);
        }
        throw NetworkException(message);
    }
  }

  /// Extracts a human-readable error message from a [DioException].
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String? ?? e.message ?? 'Unknown error';
      }
    }
    return e.message ?? 'Network error';
  }
}
