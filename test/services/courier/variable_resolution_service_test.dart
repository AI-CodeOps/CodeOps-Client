// Unit tests for VariableResolutionService.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/services/courier/variable_resolution_service.dart';

void main() {
  late VariableResolutionService service;

  setUp(() => service = VariableResolutionService());

  group('VariableResolutionService.resolve', () {
    test('resolves a token from the environment map', () {
      final result = service.resolve(
        'https://{{host}}/api',
        environment: {'host': 'example.com'},
      );
      expect(result, 'https://example.com/api');
    });

    test('resolves a token from globals', () {
      final result = service.resolve(
        '{{base}}/users',
        globals: {'base': 'http://api.dev'},
      );
      expect(result, 'http://api.dev/users');
    });

    test('local overrides environment which overrides collection which overrides globals', () {
      final result = service.resolve(
        '{{token}}',
        globals: {'token': 'g'},
        collection: {'token': 'c'},
        environment: {'token': 'e'},
        local: {'token': 'l'},
      );
      expect(result, 'l');
    });

    test('environment beats collection', () {
      final result = service.resolve(
        '{{key}}',
        collection: {'key': 'collection-val'},
        environment: {'key': 'env-val'},
      );
      expect(result, 'env-val');
    });

    test('collection beats globals', () {
      final result = service.resolve(
        '{{key}}',
        globals: {'key': 'global-val'},
        collection: {'key': 'col-val'},
      );
      expect(result, 'col-val');
    });

    test('unresolved token is left unchanged', () {
      final result = service.resolve('{{unknown}}');
      expect(result, '{{unknown}}');
    });

    test('resolves multiple tokens in a single string', () {
      final result = service.resolve(
        '{{scheme}}://{{host}}:{{port}}/api',
        environment: {
          'scheme': 'https',
          'host': 'api.example.com',
          'port': '443',
        },
      );
      expect(result, 'https://api.example.com:443/api');
    });

    test('returns input unchanged when no tokens present', () {
      const input = 'https://example.com/api/v1';
      expect(service.resolve(input), input);
    });

    test('resolves tokens with whitespace inside braces', () {
      final result = service.resolve(
        '{{ host }}',
        environment: {'host': 'example.com'},
      );
      expect(result, 'example.com');
    });
  });

  group('VariableResolutionService.extractTokens', () {
    test('returns empty list when no tokens present', () {
      expect(service.extractTokens('no variables here'), isEmpty);
    });

    test('returns one token with correct name and resolution', () {
      final tokens = service.extractTokens(
        'Bearer {{token}}',
        environment: {'token': 'abc123'},
      );
      expect(tokens, hasLength(1));
      expect(tokens.first.name, 'token');
      expect(tokens.first.isResolved, isTrue);
      expect(tokens.first.resolvedValue, 'abc123');
    });

    test('marks unresolved tokens correctly', () {
      final tokens = service.extractTokens('{{missing}}');
      expect(tokens.first.isResolved, isFalse);
      expect(tokens.first.resolvedValue, isNull);
    });

    test('returns tokens in order with correct positions', () {
      const input = '{{a}} and {{b}}';
      final tokens = service.extractTokens(input,
          environment: {'a': 'alpha', 'b': 'beta'});
      expect(tokens, hasLength(2));
      expect(tokens[0].name, 'a');
      expect(tokens[1].name, 'b');
      expect(tokens[0].start, 0);
      expect(tokens[0].end, 5); // '{{a}}'.length = 5
    });
  });

  group('VariableResolutionService.hasVariables', () {
    test('returns true when string contains a token', () {
      expect(service.hasVariables('{{host}}/path'), isTrue);
    });

    test('returns false when string has no tokens', () {
      expect(service.hasVariables('https://example.com'), isFalse);
    });

    test('returns false for empty string', () {
      expect(service.hasVariables(''), isFalse);
    });
  });
}
