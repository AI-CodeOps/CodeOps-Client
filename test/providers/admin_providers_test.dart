// Tests for admin providers.
//
// Verifies provider creation, default state values, and async provider types.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/admin_providers.dart';
import 'package:codeops/services/cloud/admin_api.dart';

void main() {
  group('Admin providers', () {
    // -----------------------------------------------------------------------
    // API provider
    // -----------------------------------------------------------------------

    test('adminApiProvider creates instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(adminApiProvider);

      expect(api, isA<AdminApi>());
    });

    // -----------------------------------------------------------------------
    // UI state providers
    // -----------------------------------------------------------------------

    test('adminTabIndexProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(adminTabIndexProvider);

      expect(value, 0);
    });

    test('adminTabIndexProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminTabIndexProvider.notifier).state = 2;

      expect(container.read(adminTabIndexProvider), 2);
    });

    test('adminUserSearchProvider defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(adminUserSearchProvider);

      expect(value, '');
    });

    test('adminUserSearchProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminUserSearchProvider.notifier).state = 'alice';

      expect(container.read(adminUserSearchProvider), 'alice');
    });

    test('adminUserPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(adminUserPageProvider);

      expect(value, 0);
    });

    test('adminUserPageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminUserPageProvider.notifier).state = 3;

      expect(container.read(adminUserPageProvider), 3);
    });

    test('auditLogPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(auditLogPageProvider);

      expect(value, 0);
    });

    test('auditLogPageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(auditLogPageProvider.notifier).state = 5;

      expect(container.read(auditLogPageProvider), 5);
    });

    test('auditLogActionFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(auditLogActionFilterProvider);

      expect(value, isNull);
    });

    test('auditLogActionFilterProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(auditLogActionFilterProvider.notifier).state = 'LOGIN';

      expect(container.read(auditLogActionFilterProvider), 'LOGIN');
    });

    // -----------------------------------------------------------------------
    // FutureProviders
    // -----------------------------------------------------------------------

    test('adminUsersProvider exists', () {
      // Verifies the provider is properly defined without triggering the
      // API layer which requires WidgetsFlutterBinding / SecureStorage.
      expect(adminUsersProvider, isNotNull);
    });

    test('systemSettingsProvider exists', () {
      expect(systemSettingsProvider, isNotNull);
    });

    test('usageStatsProvider exists', () {
      expect(usageStatsProvider, isNotNull);
    });

    test('teamAuditLogProvider is a FutureProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Returns PageResponse.empty() immediately when no team is selected.
      final asyncValue = container.read(teamAuditLogProvider);

      expect(asyncValue, isA<AsyncValue>());
    });
  });
}
