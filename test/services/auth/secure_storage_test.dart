// Tests for SecureStorageService.
//
// Verifies that all getters/setters correctly store and retrieve values
// via SharedPreferences, and that clearAll preserves remember-me + API key.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:codeops/services/auth/secure_storage.dart';
import 'package:codeops/utils/constants.dart';

void main() {
  late SecureStorageService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = SecureStorageService(prefs: prefs);
  });

  group('SecureStorageService', () {
    test('getAuthToken reads correct key', () async {
      await service.setAuthToken('test-token');

      final result = await service.getAuthToken();

      expect(result, 'test-token');
    });

    test('setAuthToken writes correct key and value', () async {
      await service.setAuthToken('new-token');

      final result = await service.getAuthToken();

      expect(result, 'new-token');
    });

    test('getRefreshToken reads correct key', () async {
      await service.setRefreshToken('refresh-token');

      final result = await service.getRefreshToken();

      expect(result, 'refresh-token');
    });

    test('setRefreshToken writes correct key and value', () async {
      await service.setRefreshToken('new-refresh');

      final result = await service.getRefreshToken();

      expect(result, 'new-refresh');
    });

    test('getCurrentUserId reads correct key', () async {
      await service.setCurrentUserId('user-123');

      final result = await service.getCurrentUserId();

      expect(result, 'user-123');
    });

    test('setCurrentUserId writes correct key and value', () async {
      await service.setCurrentUserId('user-123');

      final result = await service.getCurrentUserId();

      expect(result, 'user-123');
    });

    test('getSelectedTeamId reads correct key', () async {
      await service.setSelectedTeamId('team-456');

      final result = await service.getSelectedTeamId();

      expect(result, 'team-456');
    });

    test('setSelectedTeamId writes correct key and value', () async {
      await service.setSelectedTeamId('team-456');

      final result = await service.getSelectedTeamId();

      expect(result, 'team-456');
    });

    test('returns null for unset keys', () async {
      expect(await service.getAuthToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getCurrentUserId(), isNull);
      expect(await service.getSelectedTeamId(), isNull);
    });

    test('read returns stored value', () async {
      await service.write('custom-key', 'custom-value');

      final result = await service.read('custom-key');

      expect(result, 'custom-value');
    });

    test('write stores value retrievable by read', () async {
      await service.write('custom-key', 'custom-value');

      final result = await service.read('custom-key');

      expect(result, 'custom-value');
    });

    test('delete removes key from storage', () async {
      await service.write('custom-key', 'custom-value');
      await service.delete('custom-key');

      final result = await service.read('custom-key');

      expect(result, isNull);
    });

    test('getAnthropicApiKey reads correct key', () async {
      await service.setAnthropicApiKey('sk-ant-test');

      final result = await service.getAnthropicApiKey();

      expect(result, 'sk-ant-test');
    });

    test('setAnthropicApiKey writes correct key and value', () async {
      await service.setAnthropicApiKey('sk-ant-test');

      final result = await service.getAnthropicApiKey();

      expect(result, 'sk-ant-test');
    });

    test('deleteAnthropicApiKey removes the key', () async {
      await service.setAnthropicApiKey('sk-ant-test');
      await service.deleteAnthropicApiKey();

      final result = await service.getAnthropicApiKey();

      expect(result, isNull);
    });

    test('clearAll deletes all stored data', () async {
      await service.setAuthToken('token');
      await service.setRefreshToken('refresh');
      await service.setCurrentUserId('user-123');

      await service.clearAll();

      expect(await service.getAuthToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getCurrentUserId(), isNull);
    });

    test('clearAll preserves remember-me credentials and API key', () async {
      // Set session data that should be cleared.
      await service.setAuthToken('token');
      await service.setRefreshToken('refresh');

      // Set remember-me data that should be preserved.
      await service.write(AppConstants.keyRememberMe, 'true');
      await service.write(AppConstants.keyRememberedEmail, 'user@example.com');
      await service.write(AppConstants.keyRememberedPassword, 'secret');

      // Set API key that should be preserved.
      await service.setAnthropicApiKey('sk-ant-test');

      await service.clearAll();

      // Session data cleared.
      expect(await service.getAuthToken(), isNull);
      expect(await service.getRefreshToken(), isNull);

      // Remember-me data preserved.
      expect(await service.read(AppConstants.keyRememberMe), 'true');
      expect(
          await service.read(AppConstants.keyRememberedEmail), 'user@example.com');
      expect(await service.read(AppConstants.keyRememberedPassword), 'secret');

      // API key preserved.
      expect(await service.getAnthropicApiKey(), 'sk-ant-test');
    });

    test('round-trip: set then get returns same value', () async {
      await service.setAuthToken('round-trip-token');

      final result = await service.getAuthToken();

      expect(result, 'round-trip-token');
    });
  });
}
