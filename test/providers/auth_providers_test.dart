// Tests for auth providers.
//
// Verifies provider creation and auth state stream emission.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/services/auth/auth_service.dart';
import 'package:codeops/services/auth/secure_storage.dart';
import 'package:codeops/services/cloud/api_client.dart';

void main() {
  group('Auth providers', () {
    test('secureStorageProvider creates instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final storage = container.read(secureStorageProvider);

      expect(storage, isA<SecureStorageService>());
    });

    test('apiClientProvider creates instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(apiClientProvider);

      expect(client, isA<ApiClient>());
    });

    test('authServiceProvider creates instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(authServiceProvider);

      expect(service, isA<AuthService>());
    });

    test('currentUserProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final user = container.read(currentUserProvider);

      expect(user, isNull);
    });

    test('authStateProvider creates a stream provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final asyncState = container.read(authStateProvider);

      // Initially loading since stream hasn't emitted yet
      expect(asyncState, isA<AsyncValue<AuthState>>());
    });
  });
}
