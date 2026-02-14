// Tests for the ApiException sealed class hierarchy.
//
// Verifies that each exception type has the correct message,
// status code, and toString behavior.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/services/cloud/api_exceptions.dart';

void main() {
  group('ApiException hierarchy', () {
    test('BadRequestException has statusCode 400', () {
      const e = BadRequestException('bad request');
      expect(e.statusCode, 400);
      expect(e.message, 'bad request');
      expect(e.errors, isNull);
    });

    test('BadRequestException with field errors', () {
      const e = BadRequestException(
        'validation failed',
        errors: {'email': 'invalid'},
      );
      expect(e.errors, {'email': 'invalid'});
    });

    test('UnauthorizedException has statusCode 401', () {
      const e = UnauthorizedException('unauthorized');
      expect(e.statusCode, 401);
      expect(e.message, 'unauthorized');
    });

    test('ForbiddenException has statusCode 403', () {
      const e = ForbiddenException('forbidden');
      expect(e.statusCode, 403);
      expect(e.message, 'forbidden');
    });

    test('NotFoundException has statusCode 404', () {
      const e = NotFoundException('not found');
      expect(e.statusCode, 404);
      expect(e.message, 'not found');
    });

    test('ConflictException has statusCode 409', () {
      const e = ConflictException('conflict');
      expect(e.statusCode, 409);
      expect(e.message, 'conflict');
    });

    test('ValidationException has statusCode 422', () {
      const e = ValidationException('invalid');
      expect(e.statusCode, 422);
      expect(e.message, 'invalid');
      expect(e.fieldErrors, isNull);
    });

    test('ValidationException with field errors', () {
      const e = ValidationException(
        'validation',
        fieldErrors: {'name': 'too short'},
      );
      expect(e.fieldErrors, {'name': 'too short'});
    });

    test('RateLimitException has statusCode 429', () {
      const e = RateLimitException('rate limited');
      expect(e.statusCode, 429);
      expect(e.message, 'rate limited');
      expect(e.retryAfterSeconds, isNull);
    });

    test('RateLimitException with retryAfterSeconds', () {
      const e = RateLimitException('slow down', retryAfterSeconds: 60);
      expect(e.retryAfterSeconds, 60);
    });

    test('ServerException has provided statusCode', () {
      const e = ServerException('internal error', statusCode: 500);
      expect(e.statusCode, 500);
      expect(e.message, 'internal error');
    });

    test('ServerException with 502 statusCode', () {
      const e = ServerException('bad gateway', statusCode: 502);
      expect(e.statusCode, 502);
    });

    test('NetworkException has null statusCode', () {
      const e = NetworkException('no network');
      expect(e.statusCode, isNull);
      expect(e.message, 'no network');
    });

    test('TimeoutException has null statusCode', () {
      const e = TimeoutException('timed out');
      expect(e.statusCode, isNull);
      expect(e.message, 'timed out');
    });

    test('toString includes runtimeType, statusCode, and message', () {
      const e = NotFoundException('resource missing');
      expect(e.toString(), contains('NotFoundException'));
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('resource missing'));
    });

    test('all types implement ApiException', () {
      const exceptions = <ApiException>[
        BadRequestException('test'),
        UnauthorizedException('test'),
        ForbiddenException('test'),
        NotFoundException('test'),
        ConflictException('test'),
        ValidationException('test'),
        RateLimitException('test'),
        ServerException('test', statusCode: 500),
        NetworkException('test'),
        TimeoutException('test'),
      ];

      expect(exceptions, hasLength(10));
      for (final e in exceptions) {
        expect(e, isA<ApiException>());
        expect(e, isA<Exception>());
      }
    });

    test('switch exhaustiveness on sealed class', () {
      const ApiException exception = NotFoundException('test');

      final result = switch (exception) {
        BadRequestException() => 'bad_request',
        UnauthorizedException() => 'unauthorized',
        ForbiddenException() => 'forbidden',
        NotFoundException() => 'not_found',
        ConflictException() => 'conflict',
        ValidationException() => 'validation',
        RateLimitException() => 'rate_limit',
        ServerException() => 'server',
        NetworkException() => 'network',
        TimeoutException() => 'timeout',
      };

      expect(result, 'not_found');
    });
  });
}
