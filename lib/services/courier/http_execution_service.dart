/// HTTP execution service for Courier.
///
/// Fires HTTP requests directly from the Flutter desktop client using Dio.
/// Captures status code, response headers, body, duration, redirects, and
/// errors without routing through the CodeOps-Server proxy.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../models/courier_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HttpExecutionRequest
// ─────────────────────────────────────────────────────────────────────────────

/// All inputs needed to fire a single HTTP request.
class HttpExecutionRequest {
  /// HTTP method.
  final CourierHttpMethod method;

  /// Fully resolved URL (all `{{variables}}` already substituted).
  final String url;

  /// Request headers.
  final Map<String, String> headers;

  /// Raw request body (null for GET / HEAD / OPTIONS).
  final String? body;

  /// Content-Type override; applied if not already present in [headers].
  final String? contentType;

  /// Whether to follow 3xx redirect responses automatically.
  final bool followRedirects;

  /// Request timeout in milliseconds (connect + receive).
  final int timeoutMs;

  /// Whether to verify SSL/TLS certificates.
  ///
  /// Set to `false` to accept self-signed certificates during development.
  final bool sslVerify;

  /// Optional HTTP proxy URL (e.g. `http://proxy.local:8080`).
  final String? proxyUrl;

  /// Creates an [HttpExecutionRequest].
  const HttpExecutionRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
    this.contentType,
    this.followRedirects = true,
    this.timeoutMs = 30000,
    this.sslVerify = true,
    this.proxyUrl,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// RedirectInfo
// ─────────────────────────────────────────────────────────────────────────────

/// A single redirect hop captured during an HTTP execution.
class RedirectInfo {
  /// HTTP status code of the redirect response (301, 302, 307, 308, …).
  final int statusCode;

  /// Redirect target URL from the `Location` header.
  final String location;

  /// Creates a [RedirectInfo].
  const RedirectInfo({required this.statusCode, required this.location});
}

// ─────────────────────────────────────────────────────────────────────────────
// HttpExecutionResult
// ─────────────────────────────────────────────────────────────────────────────

/// The outcome of a completed (or failed / cancelled) HTTP execution.
class HttpExecutionResult {
  /// HTTP response status code, or null on connection failure.
  final int? statusCode;

  /// HTTP reason phrase (e.g. `"OK"`, `"Not Found"`).
  final String? statusText;

  /// Flattened response headers (multiple values joined by `", "`).
  final Map<String, String> responseHeaders;

  /// Response body as a UTF-8 string.
  final String? body;

  /// Total round-trip duration in milliseconds (from send to body complete).
  final int durationMs;

  /// Approximate response body size in bytes.
  final int responseSize;

  /// Redirect hops followed before the final response, in order.
  final List<RedirectInfo> redirects;

  /// Human-readable error message, or null on success.
  final String? error;

  /// Whether this result represents a successful response (no error, has status).
  bool get isSuccess => error == null && statusCode != null;

  /// Creates an [HttpExecutionResult].
  const HttpExecutionResult({
    this.statusCode,
    this.statusText,
    this.responseHeaders = const {},
    this.body,
    required this.durationMs,
    this.responseSize = 0,
    this.redirects = const [],
    this.error,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HttpExecutionService
// ─────────────────────────────────────────────────────────────────────────────

/// Factory type for creating a Dio instance per execution.
///
/// Exposed so tests can inject a mock Dio without making real HTTP calls.
typedef DioFactory = Dio Function(
    HttpExecutionRequest request, List<RedirectInfo> redirects);

/// Executes HTTP requests directly from the Flutter desktop client.
///
/// Each call to [execute] uses a freshly configured [Dio] instance with the
/// settings from [HttpExecutionRequest]. Cancellation is supported via
/// [cancel], which aborts any in-progress execution.
class HttpExecutionService {
  final DioFactory? _dioFactory;
  CancelToken? _cancelToken;

  /// Creates a production [HttpExecutionService].
  ///
  /// A fresh Dio instance is constructed for each [execute] call using
  /// the settings from [HttpExecutionRequest].
  HttpExecutionService() : _dioFactory = null;

  /// Creates a testable [HttpExecutionService] with an injected [DioFactory].
  ///
  /// The factory receives the [HttpExecutionRequest] and the mutable
  /// [redirects] list so tests can inspect or simulate redirect behaviour.
  @visibleForTesting
  HttpExecutionService.withFactory(DioFactory factory)
      : _dioFactory = factory;

  /// Executes [request] and returns the [HttpExecutionResult].
  ///
  /// On connection errors, timeouts, or SSL failures, returns a result with
  /// [HttpExecutionResult.error] set. Never throws.
  Future<HttpExecutionResult> execute(HttpExecutionRequest request) async {
    _cancelToken = CancelToken();
    final redirects = <RedirectInfo>[];
    final stopwatch = Stopwatch()..start();

    try {
      final factory = _dioFactory;
      final dio = factory != null
          ? factory(request, redirects)
          : _buildDio(request, redirects);

      final effectiveHeaders = Map<String, String>.from(request.headers);
      if (request.contentType != null &&
          !effectiveHeaders.containsKey('Content-Type') &&
          !effectiveHeaders.containsKey('content-type')) {
        effectiveHeaders['Content-Type'] = request.contentType!;
      }

      final response = await dio.request<String>(
        request.url,
        data: request.body,
        options: Options(
          method: request.method.displayName,
          headers: effectiveHeaders,
          responseType: ResponseType.plain,
          sendTimeout: Duration(milliseconds: request.timeoutMs),
          receiveTimeout: Duration(milliseconds: request.timeoutMs),
          validateStatus: (_) => true,
          followRedirects: request.followRedirects,
          maxRedirects: 10,
        ),
        cancelToken: _cancelToken,
      );

      stopwatch.stop();

      // Capture redirects from Dio's redirect history (dart:io platforms).
      if (response.redirects.isNotEmpty && redirects.isEmpty) {
        for (final r in response.redirects) {
          redirects.add(RedirectInfo(
            statusCode: r.statusCode,
            location: r.location.toString(),
          ));
        }
      }

      final bodyStr = response.data ?? '';
      final headersMap = <String, String>{};
      response.headers.forEach((name, values) {
        headersMap[name] = values.join(', ');
      });

      return HttpExecutionResult(
        statusCode: response.statusCode,
        statusText: response.statusMessage,
        responseHeaders: headersMap,
        body: bodyStr,
        durationMs: stopwatch.elapsedMilliseconds,
        responseSize: bodyStr.length,
        redirects: List.unmodifiable(redirects),
      );
    } on DioException catch (e) {
      stopwatch.stop();
      if (CancelToken.isCancel(e)) {
        return HttpExecutionResult(
          durationMs: stopwatch.elapsedMilliseconds,
          error: 'Request cancelled',
        );
      }
      return HttpExecutionResult(
        durationMs: stopwatch.elapsedMilliseconds,
        error: _describeDioError(e),
      );
    } catch (e) {
      stopwatch.stop();
      return HttpExecutionResult(
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
    } finally {
      _cancelToken = null;
    }
  }

  /// Cancels any in-progress [execute] call.
  ///
  /// If no execution is running this is a no-op.
  void cancel() => _cancelToken?.cancel('User cancelled');

  // ── Private helpers ──────────────────────────────────────────────────────

  Dio _buildDio(HttpExecutionRequest request, List<RedirectInfo> redirects) {
    final dio = Dio(BaseOptions(
      connectTimeout: Duration(milliseconds: request.timeoutMs),
      receiveTimeout: Duration(milliseconds: request.timeoutMs),
      // Redirect following is handled at the Options level per-request.
    ));

    // SSL certificate verification bypass for development.
    if (!request.sslVerify) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    // Proxy configuration.
    if (request.proxyUrl != null && request.proxyUrl!.isNotEmpty) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.findProxy = (uri) => 'PROXY ${request.proxyUrl}';
        if (!request.sslVerify) {
          client.badCertificateCallback = (cert, host, port) => true;
        }
        return client;
      };
    }

    return dio;
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out';
      case DioExceptionType.sendTimeout:
        return 'Send timed out';
      case DioExceptionType.receiveTimeout:
        return 'Response timed out';
      case DioExceptionType.connectionError:
        return 'Connection error: ${e.message}';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.unknown:
        return e.message ?? 'Unknown error';
      default:
        return e.message ?? e.toString();
    }
  }
}
