// Tests for User model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/user.dart';

void main() {
  group('User', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'abc-123',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'avatarUrl': 'https://example.com/avatar.png',
        'isActive': true,
        'lastLoginAt': '2025-01-15T10:30:00.000Z',
        'createdAt': '2025-01-01T00:00:00.000Z',
      };
      final user = User.fromJson(json);
      expect(user.id, 'abc-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.isActive, true);
      expect(user.lastLoginAt, isNotNull);
      expect(user.createdAt, isNotNull);
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 'abc-123',
        'email': 'test@example.com',
        'displayName': 'Test User',
      };
      final user = User.fromJson(json);
      expect(user.avatarUrl, isNull);
      expect(user.isActive, isNull);
      expect(user.lastLoginAt, isNull);
      expect(user.createdAt, isNull);
    });

    test('toJson round-trip', () {
      final user = User(
        id: 'abc-123',
        email: 'test@example.com',
        displayName: 'Test User',
        isActive: true,
      );
      final json = user.toJson();
      final restored = User.fromJson(json);
      expect(restored.id, user.id);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
      expect(restored.isActive, user.isActive);
    });
  });
}
