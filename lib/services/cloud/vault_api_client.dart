/// Centralized HTTP client for all CodeOps-Vault API communication.
///
/// Wraps [Dio] with four interceptors mirroring [ApiClient]:
/// 1. **Auth interceptor** — attaches `Authorization: Bearer <token>`
/// 2. **Refresh interceptor** — on 401, refreshes via CodeOps-Server
/// 3. **Error interceptor** — maps HTTP errors to typed [ApiException]s
/// 4. **Logging interceptor** — logs requests/responses with correlation IDs
///
/// All Vault API services depend on this single [VaultApiClient] instance.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../utils/constants.dart';
import '../auth/secure_storage.dart';
import '../logging/log_service.dart';
import 'api_exceptions.dart';

/// Centralized HTTP client for CodeOps-Vault API communication.
///
/// Uses the same JWT tokens as [ApiClient] (issued by CodeOps-Server)
/// but targets the Vault service at [AppConstants.vaultApiBaseUrl].
class VaultApiClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;
  static const _uuid = Uuid();

  /// Whether a token refresh is currently in progress.
  bool _isRefreshing = false;

  /// Callback invoked when token refresh fails (triggers logout).
  VoidCallback? onAuthFailure;

  /// Paths that do not require an Authorization header.
  static const _publicPaths = [
    '/seal/status',
  ];

  /// Creates a [VaultApiClient] configured with the given [secureStorage].
  VaultApiClient({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(BaseOptions(
      baseUrl:
          '${AppConstants.vaultApiBaseUrl}${AppConstants.vaultApiPrefix}',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      _authInterceptor(),
      _refreshInterceptor(),
      _errorInterceptor(),
      _loggingInterceptor(),
    ]);
  }

  /// Exposes the underlying [Dio] instance for advanced usage.
  @visibleForTesting
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Public HTTP methods
  // ---------------------------------------------------------------------------

  /// Sends a GET request to [path] with optional [queryParameters].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  /// Sends a POST request to [path] with optional [data] body.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters);

  /// Sends a PUT request to [path] with optional [data] body.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.put<T>(path, data: data, queryParameters: queryParameters);

  /// Sends a DELETE request to [path] with optional [queryParameters].
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.delete<T>(path, queryParameters: queryParameters);

  // ---------------------------------------------------------------------------
  // Interceptors
  // ---------------------------------------------------------------------------

  /// Attaches the JWT access token to every request except public paths.
  InterceptorsWrapper _authInterceptor() => InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isPublic = _publicPaths.any(
            (p) => options.path.contains(p),
          );
          if (!isPublic) {
            final token = await _secureStorage.getAuthToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      );

  /// On 401, attempts a single token refresh via CodeOps-Server and retries.
  InterceptorsWrapper _refreshInterceptor() => InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final path = error.requestOptions.path;
          if (_publicPaths.any((p) => path.contains(p))) {
            return handler.next(error);
          }

          if (_isRefreshing) {
            return handler.next(error);
          }

          _isRefreshing = true;
          try {
            final refreshToken = await _secureStorage.getRefreshToken();
            if (refreshToken == null) {
              onAuthFailure?.call();
              return handler.next(error);
            }

            // Refresh via CodeOps-Server (not Vault).
            final refreshDio = Dio(BaseOptions(
              baseUrl:
                  '${AppConstants.apiBaseUrl}${AppConstants.apiPrefix}',
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ));

            final response = await refreshDio.post<Map<String, dynamic>>(
              '/auth/refresh',
              data: {'refreshToken': refreshToken},
            );

            final data = response.data!;
            final newToken = data['token'] as String;
            final newRefreshToken = data['refreshToken'] as String;

            await _secureStorage.setAuthToken(newToken);
            await _secureStorage.setRefreshToken(newRefreshToken);

            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await _dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          } on DioException {
            onAuthFailure?.call();
            return handler.next(error);
          } finally {
            _isRefreshing = false;
          }
        },
      );

  /// Maps [DioException]s to typed [ApiException]s.
  InterceptorsWrapper _errorInterceptor() => InterceptorsWrapper(
        onError: (error, handler) {
          final exception = _mapError(error);
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: exception,
            ),
          );
        },
      );

  /// Logs requests, responses, and errors with correlation IDs.
  InterceptorsWrapper _loggingInterceptor() {
    const tag = 'VaultApiClient';
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final correlationId = _uuid.v4().substring(0, 8);
        options.extra['correlationId'] = correlationId;
        options.extra['requestStart'] = DateTime.now().millisecondsSinceEpoch;
        options.headers['X-Correlation-ID'] = correlationId;
        log.d(tag,
            '\u2192 ${options.method} ${options.uri} (correlationId=$correlationId)');
        handler.next(options);
      },
      onResponse: (response, handler) {
        final correlationId =
            response.requestOptions.extra['correlationId'] ?? '?';
        final startMs =
            response.requestOptions.extra['requestStart'] as int? ?? 0;
        final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
        log.d(tag,
            '\u2190 ${response.statusCode} ${response.requestOptions.method} '
            '${response.requestOptions.uri} (${elapsed}ms) '
            '(correlationId=$correlationId)');
        handler.next(response);
      },
      onError: (error, handler) {
        final correlationId =
            error.requestOptions.extra['correlationId'] ?? '?';
        final status = error.response?.statusCode ?? 0;
        log.e(tag,
            '\u2717 $status ${error.requestOptions.method} '
            '${error.requestOptions.uri} (correlationId=$correlationId)',
            error.error);
        handler.next(error);
      },
    );
  }

  /// Converts a [DioException] to a typed [ApiException].
  ApiException _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(
          'Request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Unable to connect to the Vault server. Check your network connection.',
        );
      default:
        break;
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'An unexpected error occurred';
    if (data is Map<String, dynamic>) {
      message = (data['message'] as String?) ??
          (data['error'] as String?) ??
          message;
    }

    return switch (statusCode) {
      400 => BadRequestException(message),
      401 => UnauthorizedException(message),
      403 => ForbiddenException(message),
      404 => NotFoundException(message),
      409 => ConflictException(message),
      422 => ValidationException(message),
      429 => RateLimitException(
          message,
          retryAfterSeconds: _parseRetryAfter(error.response),
        ),
      _ when statusCode != null && statusCode >= 500 =>
        ServerException(message, statusCode: statusCode),
      _ => ServerException(message, statusCode: statusCode ?? 0),
    };
  }

  /// Parses the `Retry-After` header from a 429 response.
  int? _parseRetryAfter(Response? response) {
    final header = response?.headers.value('retry-after');
    if (header == null) return null;
    return int.tryParse(header);
  }
}
