// Tests for Jira provider helper functions and token key builder.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/providers/jira_providers.dart';
import 'package:codeops/services/auth/secure_storage.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  // ---------------------------------------------------------------------------
  // jiraTokenKey
  // ---------------------------------------------------------------------------
  group('jiraTokenKey', () {
    test('builds correct key string for a connection ID', () {
      expect(jiraTokenKey('conn-123'), 'jira_api_token_conn-123');
    });

    test('builds correct key for UUID-style ID', () {
      const uuid = '11111111-1111-1111-1111-111111111111';
      expect(jiraTokenKey(uuid), 'jira_api_token_$uuid');
    });

    test('builds correct key for empty string', () {
      expect(jiraTokenKey(''), 'jira_api_token_');
    });
  });

  // ---------------------------------------------------------------------------
  // saveJiraApiToken
  // ---------------------------------------------------------------------------
  group('saveJiraApiToken', () {
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    test('delegates to secure storage with correct key and value', () async {
      when(() => mockStorage.write(any(), any()))
          .thenAnswer((_) async {});

      await saveJiraApiToken(mockStorage, 'conn-123', 'my-api-token');

      verify(() => mockStorage.write(
            'jira_api_token_conn-123',
            'my-api-token',
          )).called(1);
    });

    test('uses jiraTokenKey to build the storage key', () async {
      when(() => mockStorage.write(any(), any()))
          .thenAnswer((_) async {});

      const connectionId = 'abc-def';
      await saveJiraApiToken(mockStorage, connectionId, 'token-value');

      verify(() => mockStorage.write(
            jiraTokenKey(connectionId),
            'token-value',
          )).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteJiraApiToken
  // ---------------------------------------------------------------------------
  group('deleteJiraApiToken', () {
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    test('delegates to secure storage with correct key', () async {
      when(() => mockStorage.delete(any()))
          .thenAnswer((_) async {});

      await deleteJiraApiToken(mockStorage, 'conn-456');

      verify(() => mockStorage.delete('jira_api_token_conn-456')).called(1);
    });

    test('uses jiraTokenKey to build the storage key', () async {
      when(() => mockStorage.delete(any()))
          .thenAnswer((_) async {});

      const connectionId = 'xyz-789';
      await deleteJiraApiToken(mockStorage, connectionId);

      verify(() => mockStorage.delete(jiraTokenKey(connectionId))).called(1);
    });
  });
}
