// Unit tests for HttpExecutionService.
//
// Uses a custom HttpClientAdapter to simulate HTTP responses without making
// real network calls. The [HttpExecutionService.withFactory] constructor
// injects a pre-configured Dio for each test.
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/services/courier/http_execution_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock HTTP adapters
// ─────────────────────────────────────────────────────────────────────────────

/// Immediately returns a pre-configured [ResponseBody].
class _StaticAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;

  _StaticAdapter({
    this.statusCode = 200,
    this.body = '',
    this.headers = const {},
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    return ResponseBody.fromString(body, statusCode, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

/// Waits for [cancelFuture] to fire, then completes — simulating a hanging
/// request that is cancelled by the caller.
class _HangingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    // Wait until cancel fires (or indefinitely in tests that don't cancel).
    if (cancelFuture != null) {
      await cancelFuture.catchError((_) {});
    } else {
      await Completer<void>().future;
    }
    // Return a dummy response; Dio will intercept cancel before this matters.
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}

/// Always throws a [DioException] of the given [type].
class _ErrorAdapter implements HttpClientAdapter {
  final DioExceptionType type;
  final String? message;

  _ErrorAdapter(this.type, {this.message});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) {
    throw DioException(
      requestOptions: options,
      type: type,
      message: message,
    );
  }

  @override
  void close({bool force = false}) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

HttpExecutionService _serviceWith(HttpClientAdapter adapter) {
  return HttpExecutionService.withFactory((request, redirects) {
    final dio = Dio(BaseOptions(validateStatus: (_) => true));
    dio.httpClientAdapter = adapter;
    return dio;
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('HttpExecutionService', () {
    test('GET request returns correct status code', () async {
      final service = _serviceWith(_StaticAdapter(statusCode: 200, body: '{}'));
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/api',
        ),
      );

      expect(result.statusCode, 200);
      expect(result.error, isNull);
      expect(result.isSuccess, isTrue);
    });

    test('POST request returns 201 with body', () async {
      final service = _serviceWith(
        _StaticAdapter(statusCode: 201, body: '{"id":"abc"}'),
      );
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.post,
          url: 'http://localhost/api/items',
          body: '{"name":"test"}',
          contentType: 'application/json',
        ),
      );

      expect(result.statusCode, 201);
      expect(result.body, '{"id":"abc"}');
      expect(result.isSuccess, isTrue);
    });

    test('response body is captured', () async {
      final service = _serviceWith(
        _StaticAdapter(statusCode: 200, body: 'Hello World'),
      );
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/hello',
        ),
      );

      expect(result.body, 'Hello World');
    });

    test('response size matches body length', () async {
      const body = 'twelve chars';
      final service = _serviceWith(
        _StaticAdapter(statusCode: 200, body: body),
      );
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/',
        ),
      );

      expect(result.responseSize, body.length);
    });

    test('duration is measured and positive', () async {
      final service = _serviceWith(_StaticAdapter(statusCode: 200));
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/',
        ),
      );

      expect(result.durationMs, greaterThanOrEqualTo(0));
    });

    test('response headers are captured', () async {
      final service = _serviceWith(_StaticAdapter(
        statusCode: 200,
        headers: {
          'x-request-id': ['abc-123'],
          'content-type': ['application/json'],
        },
      ));
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/',
        ),
      );

      expect(result.responseHeaders['x-request-id'], 'abc-123');
      expect(result.responseHeaders['content-type'], 'application/json');
    });

    test('4xx response is captured without error', () async {
      final service = _serviceWith(_StaticAdapter(statusCode: 404, body: 'Not Found'));
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/missing',
        ),
      );

      expect(result.statusCode, 404);
      expect(result.error, isNull);
      expect(result.isSuccess, isTrue);
    });

    test('connection timeout sets error', () async {
      final service = _serviceWith(
        _ErrorAdapter(DioExceptionType.connectionTimeout),
      );
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/',
          timeoutMs: 1,
        ),
      );

      expect(result.error, 'Connection timed out');
      expect(result.isSuccess, isFalse);
    });

    test('connection error sets descriptive error message', () async {
      final service = _serviceWith(
        _ErrorAdapter(
          DioExceptionType.connectionError,
          message: 'Connection refused',
        ),
      );
      final result = await service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/',
        ),
      );

      expect(result.error, contains('Connection error'));
      expect(result.isSuccess, isFalse);
    });

    test('cancel() sets error to "Request cancelled"', () async {
      final service = _serviceWith(_HangingAdapter());

      final future = service.execute(
        const HttpExecutionRequest(
          method: CourierHttpMethod.get,
          url: 'http://localhost/',
        ),
      );

      // Allow the execute call to start.
      await Future<void>.delayed(Duration.zero);
      service.cancel();

      final result = await future;
      expect(result.error, 'Request cancelled');
      expect(result.isSuccess, isFalse);
    });
  });
}
