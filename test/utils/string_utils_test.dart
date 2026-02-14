// Tests for string manipulation utilities.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/utils/string_utils.dart';

void main() {
  group('truncate', () {
    test('returns original if under max', () {
      expect(truncate('hello', 10), 'hello');
    });

    test('returns original if exactly max', () {
      expect(truncate('hello', 5), 'hello');
    });

    test('truncates with ellipsis if over max', () {
      expect(truncate('hello world', 5), 'hello...');
    });
  });

  group('pluralize', () {
    test('uses singular for count 1', () {
      expect(pluralize(1, 'finding'), '1 finding');
    });

    test('uses default plural for count 0', () {
      expect(pluralize(0, 'finding'), '0 findings');
    });

    test('uses default plural for count > 1', () {
      expect(pluralize(3, 'finding'), '3 findings');
    });

    test('uses custom plural form', () {
      expect(pluralize(2, 'vulnerability', 'vulnerabilities'),
          '2 vulnerabilities');
    });
  });

  group('camelToTitle', () {
    test('converts camelCase to Title Case', () {
      expect(camelToTitle('codeQuality'), 'Code Quality');
    });

    test('handles single word', () {
      expect(camelToTitle('security'), 'Security');
    });

    test('returns empty for empty string', () {
      expect(camelToTitle(''), '');
    });
  });

  group('snakeToTitle', () {
    test('converts SCREAMING_SNAKE to Title Case', () {
      expect(snakeToTitle('CODE_QUALITY'), 'Code Quality');
    });

    test('handles single word', () {
      expect(snakeToTitle('SECURITY'), 'Security');
    });

    test('returns empty for empty string', () {
      expect(snakeToTitle(''), '');
    });
  });

  group('isValidEmail', () {
    test('returns true for valid emails', () {
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('user.name+tag@domain.co'), isTrue);
    });

    test('returns false for invalid emails', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('not-an-email'), isFalse);
      expect(isValidEmail('@domain.com'), isFalse);
      expect(isValidEmail('user@'), isFalse);
      expect(isValidEmail('user@.com'), isFalse);
    });
  });
}
