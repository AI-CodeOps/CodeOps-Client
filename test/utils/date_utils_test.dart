// Tests for date and time formatting utilities.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/utils/date_utils.dart';

void main() {
  group('formatDateTime', () {
    test('returns em dash for null', () {
      expect(formatDateTime(null), '\u2014');
    });

    test('formats a date with time', () {
      final dt = DateTime(2025, 1, 15, 14, 30);
      final result = formatDateTime(dt);
      expect(result, contains('Jan'));
      expect(result, contains('15'));
      expect(result, contains('2025'));
    });
  });

  group('formatDate', () {
    test('returns em dash for null', () {
      expect(formatDate(null), '\u2014');
    });

    test('formats date without time', () {
      final dt = DateTime(2025, 3, 5);
      final result = formatDate(dt);
      expect(result, contains('Mar'));
      expect(result, contains('5'));
      expect(result, contains('2025'));
    });
  });

  group('formatTimeAgo', () {
    test('returns em dash for null', () {
      expect(formatTimeAgo(null), '\u2014');
    });

    test('returns just now for recent times', () {
      final now = DateTime.now();
      expect(formatTimeAgo(now), 'just now');
    });

    test('returns minutes ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 5));
      expect(formatTimeAgo(dt), '5m ago');
    });

    test('returns hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 2));
      expect(formatTimeAgo(dt), '2h ago');
    });

    test('returns yesterday', () {
      final dt = DateTime.now().subtract(const Duration(days: 1));
      expect(formatTimeAgo(dt), 'yesterday');
    });

    test('returns days ago for 2-6 days', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      expect(formatTimeAgo(dt), '3d ago');
    });

    test('returns month day for older dates', () {
      final dt = DateTime.now().subtract(const Duration(days: 30));
      final result = formatTimeAgo(dt);
      expect(result, isNot(contains('ago')));
    });
  });

  group('formatDuration', () {
    test('formats hours minutes seconds', () {
      expect(formatDuration(const Duration(hours: 1, minutes: 23, seconds: 45)),
          '1h 23m 45s');
    });

    test('formats minutes seconds only', () {
      expect(formatDuration(const Duration(minutes: 23, seconds: 12)),
          '23m 12s');
    });

    test('formats seconds only', () {
      expect(formatDuration(const Duration(seconds: 45)), '45s');
    });

    test('formats zero', () {
      expect(formatDuration(Duration.zero), '0s');
    });
  });
}
