// Tests for vault providers.
//
// Verifies singleton provider creation, FutureProvider types,
// StateProvider defaults, and state updates for all Vault providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/services/cloud/vault_api.dart';
import 'package:codeops/services/cloud/vault_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────────────────────
  // Core singleton providers
  // ─────────────────────────────────────────────────────────────────────────

  group('Core providers', () {
    test('vaultApiClientProvider creates VaultApiClient', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(vaultApiClientProvider);

      expect(client, isA<VaultApiClient>());
    });

    test('vaultApiProvider creates VaultApi', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(vaultApiProvider);

      expect(api, isA<VaultApi>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FutureProvider types
  // ─────────────────────────────────────────────────────────────────────────

  group('FutureProvider types', () {
    test('sealStatusProvider is a FutureProvider', () {
      expect(sealStatusProvider, isA<FutureProvider<SealStatusResponse>>());
    });

    test('vaultSecretsProvider is a FutureProvider', () {
      expect(
        vaultSecretsProvider,
        isA<FutureProvider<PageResponse<SecretResponse>>>(),
      );
    });

    test('vaultPoliciesProvider is a FutureProvider', () {
      expect(
        vaultPoliciesProvider,
        isA<FutureProvider<PageResponse<AccessPolicyResponse>>>(),
      );
    });

    test('vaultTransitKeysProvider is a FutureProvider', () {
      expect(
        vaultTransitKeysProvider,
        isA<FutureProvider<PageResponse<TransitKeyResponse>>>(),
      );
    });

    test('vaultAuditLogProvider is a FutureProvider', () {
      expect(
        vaultAuditLogProvider,
        isA<FutureProvider<PageResponse<AuditEntryResponse>>>(),
      );
    });

    test('vaultSecretStatsProvider is a FutureProvider', () {
      expect(
        vaultSecretStatsProvider,
        isA<FutureProvider<Map<String, int>>>(),
      );
    });

    test('vaultActiveLeaseCountProvider is a FutureProvider', () {
      expect(vaultActiveLeaseCountProvider, isA<FutureProvider<int>>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Secret UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Secret UI state', () {
    test('vaultSecretTypeFilterProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultSecretTypeFilterProvider), isNull);
    });

    test('vaultSecretPathFilterProvider defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultSecretPathFilterProvider), '');
    });

    test('vaultSecretActiveOnlyProvider defaults to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultSecretActiveOnlyProvider), true);
    });

    test('vaultSecretPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultSecretPageProvider), 0);
    });

    test('vaultSecretSortByProvider defaults to createdAt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultSecretSortByProvider), 'createdAt');
    });

    test('vaultSecretSortDirProvider defaults to desc', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultSecretSortDirProvider), 'desc');
    });

    test('vaultSecretSearchQueryProvider defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultSecretSearchQueryProvider), '');
    });

    test('selectedVaultSecretIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedVaultSecretIdProvider), isNull);
    });

    test('selectedVaultSecretIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedVaultSecretIdProvider.notifier).state =
          'secret-123';

      expect(container.read(selectedVaultSecretIdProvider), 'secret-123');
    });

    test('vaultSecretPageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultSecretPageProvider.notifier).state = 5;

      expect(container.read(vaultSecretPageProvider), 5);
    });

    test('vaultSecretPathFilterProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultSecretPathFilterProvider.notifier).state =
          '/services/app';

      expect(container.read(vaultSecretPathFilterProvider), '/services/app');
    });

    test('vaultSecretPathFilterProvider reset to empty clears filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultSecretPathFilterProvider.notifier).state =
          '/services';
      container.read(vaultSecretPathFilterProvider.notifier).state = '';

      expect(container.read(vaultSecretPathFilterProvider), '');
    });

    test('vaultSecretTypeFilterProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultSecretTypeFilterProvider.notifier).state =
          SecretType.dynamic_;

      expect(
        container.read(vaultSecretTypeFilterProvider),
        SecretType.dynamic_,
      );
    });

    test('vaultSecretSearchQueryProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultSecretSearchQueryProvider.notifier).state = 'db';

      expect(container.read(vaultSecretSearchQueryProvider), 'db');
    });

    test('vaultSecretSortByProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultSecretSortByProvider.notifier).state = 'name';

      expect(container.read(vaultSecretSortByProvider), 'name');
    });

    test('vaultSecretSortDirProvider can be toggled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultSecretSortDirProvider.notifier).state = 'asc';

      expect(container.read(vaultSecretSortDirProvider), 'asc');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Policy UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Policy UI state', () {
    test('vaultPolicyActiveOnlyProvider defaults to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultPolicyActiveOnlyProvider), true);
    });

    test('vaultPolicyPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultPolicyPageProvider), 0);
    });

    test('selectedVaultPolicyIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedVaultPolicyIdProvider), isNull);
    });

    test('selectedVaultPolicyIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedVaultPolicyIdProvider.notifier).state =
          'policy-456';

      expect(container.read(selectedVaultPolicyIdProvider), 'policy-456');
    });

    test('vaultPolicySortByProvider defaults to createdAt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultPolicySortByProvider), 'createdAt');
    });

    test('vaultPolicySortDirProvider defaults to desc', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultPolicySortDirProvider), 'desc');
    });

    test('vaultPolicySortByProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultPolicySortByProvider.notifier).state = 'name';

      expect(container.read(vaultPolicySortByProvider), 'name');
    });

    test('vaultPolicySortDirProvider can be toggled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultPolicySortDirProvider.notifier).state = 'asc';

      expect(container.read(vaultPolicySortDirProvider), 'asc');
    });

    test('vaultPolicyActiveOnlyProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultPolicyActiveOnlyProvider.notifier).state = false;

      expect(container.read(vaultPolicyActiveOnlyProvider), false);
    });

    test('vaultPolicyPageProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultPolicyPageProvider.notifier).state = 3;

      expect(container.read(vaultPolicyPageProvider), 3);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Transit UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Transit UI state', () {
    test('vaultTransitActiveOnlyProvider defaults to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultTransitActiveOnlyProvider), true);
    });

    test('vaultTransitPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultTransitPageProvider), 0);
    });

    test('selectedVaultTransitKeyIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedVaultTransitKeyIdProvider), isNull);
    });

    test('selectedVaultTransitKeyIdProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedVaultTransitKeyIdProvider.notifier).state =
          'key-789';

      expect(container.read(selectedVaultTransitKeyIdProvider), 'key-789');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Audit UI state defaults and updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Audit UI state', () {
    test('vaultAuditOperationFilterProvider defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultAuditOperationFilterProvider), '');
    });

    test('vaultAuditResourceTypeFilterProvider defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultAuditResourceTypeFilterProvider), '');
    });

    test('vaultAuditSuccessOnlyProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultAuditSuccessOnlyProvider), isNull);
    });

    test('vaultAuditPageProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultAuditPageProvider), 0);
    });

    test('vaultAuditOperationFilterProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultAuditOperationFilterProvider.notifier).state =
          'WRITE';

      expect(container.read(vaultAuditOperationFilterProvider), 'WRITE');
    });

    test('vaultAuditSuccessOnlyProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultAuditSuccessOnlyProvider.notifier).state = true;

      expect(container.read(vaultAuditSuccessOnlyProvider), true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation state
  // ─────────────────────────────────────────────────────────────────────────

  group('Navigation state', () {
    test('vaultActiveTabProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(vaultActiveTabProvider), 0);
    });

    test('vaultActiveTabProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(vaultActiveTabProvider.notifier).state = 3;

      expect(container.read(vaultActiveTabProvider), 3);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Secret Detail Page — Provider types (CVF-003)
  // ─────────────────────────────────────────────────────────────────────────

  group('Secret detail providers (CVF-003)', () {
    test('vaultSecretVersionValueProvider is a FutureProvider.family', () {
      expect(
        vaultSecretVersionValueProvider,
        isA<
            FutureProviderFamily<SecretValueResponse,
                ({String secretId, int version})>>(),
      );
    });

    test('vaultSecretDetailProvider is a FutureProvider.family', () {
      expect(
        vaultSecretDetailProvider,
        isA<FutureProviderFamily<SecretResponse, String>>(),
      );
    });

    test('vaultSecretVersionsProvider is a FutureProvider.family', () {
      expect(
        vaultSecretVersionsProvider,
        isA<
            FutureProviderFamily<PageResponse<SecretVersionResponse>,
                String>>(),
      );
    });

    test('vaultSecretMetadataProvider is a FutureProvider.family', () {
      expect(
        vaultSecretMetadataProvider,
        isA<FutureProviderFamily<Map<String, String>, String>>(),
      );
    });
  });
}
