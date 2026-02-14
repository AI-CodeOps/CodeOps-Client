// Tests for SecureStorageService.
//
// Verifies that all getters/setters correctly delegate to
// FlutterSecureStorage, and that clearAll removes all data.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:codeops/services/auth/secure_storage.dart';
import 'package:codeops/utils/constants.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  group('SecureStorageService', () {
    test('getAuthToken reads correct key', () async {
      when(() => mockStorage.read(key: AppConstants.keyAuthToken))
          .thenAnswer((_) async => 'test-token');

      final result = await service.getAuthToken();

      expect(result, 'test-token');
      verify(() => mockStorage.read(key: AppConstants.keyAuthToken)).called(1);
    });

    test('setAuthToken writes correct key and value', () async {
      when(() => mockStorage.write(
            key: AppConstants.keyAuthToken,
            value: 'new-token',
          )).thenAnswer((_) async {});

      await service.setAuthToken('new-token');

      verify(() => mockStorage.write(
            key: AppConstants.keyAuthToken,
            value: 'new-token',
          )).called(1);
    });

    test('getRefreshToken reads correct key', () async {
      when(() => mockStorage.read(key: AppConstants.keyRefreshToken))
          .thenAnswer((_) async => 'refresh-token');

      final result = await service.getRefreshToken();

      expect(result, 'refresh-token');
    });

    test('setRefreshToken writes correct key and value', () async {
      when(() => mockStorage.write(
            key: AppConstants.keyRefreshToken,
            value: 'new-refresh',
          )).thenAnswer((_) async {});

      await service.setRefreshToken('new-refresh');

      verify(() => mockStorage.write(
            key: AppConstants.keyRefreshToken,
            value: 'new-refresh',
          )).called(1);
    });

    test('getCurrentUserId reads correct key', () async {
      when(() => mockStorage.read(key: AppConstants.keyCurrentUserId))
          .thenAnswer((_) async => 'user-123');

      final result = await service.getCurrentUserId();

      expect(result, 'user-123');
    });

    test('setCurrentUserId writes correct key and value', () async {
      when(() => mockStorage.write(
            key: AppConstants.keyCurrentUserId,
            value: 'user-123',
          )).thenAnswer((_) async {});

      await service.setCurrentUserId('user-123');

      verify(() => mockStorage.write(
            key: AppConstants.keyCurrentUserId,
            value: 'user-123',
          )).called(1);
    });

    test('getSelectedTeamId reads correct key', () async {
      when(() => mockStorage.read(key: AppConstants.keySelectedTeamId))
          .thenAnswer((_) async => 'team-456');

      final result = await service.getSelectedTeamId();

      expect(result, 'team-456');
    });

    test('setSelectedTeamId writes correct key and value', () async {
      when(() => mockStorage.write(
            key: AppConstants.keySelectedTeamId,
            value: 'team-456',
          )).thenAnswer((_) async {});

      await service.setSelectedTeamId('team-456');

      verify(() => mockStorage.write(
            key: AppConstants.keySelectedTeamId,
            value: 'team-456',
          )).called(1);
    });

    test('returns null for unset keys', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      expect(await service.getAuthToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getCurrentUserId(), isNull);
      expect(await service.getSelectedTeamId(), isNull);
    });

    test('read delegates to storage', () async {
      when(() => mockStorage.read(key: 'custom-key'))
          .thenAnswer((_) async => 'custom-value');

      final result = await service.read('custom-key');

      expect(result, 'custom-value');
    });

    test('write delegates to storage', () async {
      when(() => mockStorage.write(key: 'custom-key', value: 'custom-value'))
          .thenAnswer((_) async {});

      await service.write('custom-key', 'custom-value');

      verify(() => mockStorage.write(key: 'custom-key', value: 'custom-value'))
          .called(1);
    });

    test('delete delegates to storage', () async {
      when(() => mockStorage.delete(key: 'custom-key'))
          .thenAnswer((_) async {});

      await service.delete('custom-key');

      verify(() => mockStorage.delete(key: 'custom-key')).called(1);
    });

    test('clearAll deletes all stored data', () async {
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

      await service.clearAll();

      verify(() => mockStorage.deleteAll()).called(1);
    });

    test('round-trip: set then get returns same value', () async {
      when(() => mockStorage.write(
            key: AppConstants.keyAuthToken,
            value: 'round-trip-token',
          )).thenAnswer((_) async {});
      when(() => mockStorage.read(key: AppConstants.keyAuthToken))
          .thenAnswer((_) async => 'round-trip-token');

      await service.setAuthToken('round-trip-token');
      final result = await service.getAuthToken();

      expect(result, 'round-trip-token');
    });
  });
}
