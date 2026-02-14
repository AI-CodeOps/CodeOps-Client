/// Centralized HTTP client for all CodeOps-Server API communication.
///
/// Wraps [Dio] with three interceptors:
/// 1. **Auth interceptor** — attaches `Authorization: Bearer <token>` to every request
/// 2. **Refresh interceptor** — on 401, attempts token refresh once, then retries
/// 3. **Error interceptor** — maps HTTP errors to typed [ApiException]s
///
/// All cloud API services depend on this single [ApiClient] instance.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../utils/constants.dart';
import '../auth/secure_storage.dart';
import 'api_exceptions.dart';

/// Centralized HTTP client for all CodeOps-Server API communication.
///
/// Wraps [Dio] with interceptors for JWT auth, token refresh, error handling,
/// and request logging.
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  /// Whether a token refresh is currently in progress.
  bool _isRefreshing = false;

  /// Callback invoked when token refresh fails (triggers logout).
  VoidCallback? onAuthFailure;

  /// Paths that do not require an Authorization header.
  static const _publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/health',
  ];

  /// Creates an [ApiClient] configured with the given [secureStorage].
  ApiClient({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.apiBaseUrl}${AppConstants.apiPrefix}',
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
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (msg) => debugPrint('[API] $msg'),
        ),
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

  /// Sends a multipart file upload POST to [path].
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    String fieldName = 'file',
  }) =>
      _dio.post<T>(
        path,
        data: FormData.fromMap({
          fieldName: MultipartFile.fromFileSync(filePath),
        }),
      );

  /// Downloads a file from [path] to [savePath].
  Future<Response> downloadFile(String path, String savePath) =>
      _dio.download(path, savePath);

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

  /// On 401, attempts a single token refresh and retries the original request.
  InterceptorsWrapper _refreshInterceptor() => InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          // Don't attempt refresh for auth endpoints
          final path = error.requestOptions.path;
          if (_publicPaths.any((p) => path.contains(p))) {
            return handler.next(error);
          }

          // Prevent concurrent refresh attempts
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

            // Attempt token refresh using a fresh Dio instance to avoid
            // interceptor loops.
            final refreshDio = Dio(BaseOptions(
              baseUrl: _dio.options.baseUrl,
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

            // Retry the original request with the new token
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await _dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          } on DioException {
            // Refresh failed — trigger logout
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

  /// Converts a [DioException] to a typed [ApiException].
  ApiException _mapError(DioException error) {
    // Handle connection and timeout errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(
          'Request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          'Unable to connect to the server. Check your network connection.',
        );
      default:
        break;
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Parse server error response: { "status": 400, "error": "...", "message": "..." }
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
