/// Riverpod providers for the Vault module.
///
/// Manages state, exposes API data, handles filtering/sorting, and
/// provides the reactive layer between [VaultApi] and the UI pages.
/// Follows the same patterns as [team_providers.dart] and
/// [finding_providers.dart]: [Provider] for singletons,
/// [FutureProvider] for async data, [FutureProvider.family] for
/// parameterized queries, [StateProvider] for UI state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/vault_enums.dart';
import '../models/vault_models.dart';
import '../services/cloud/vault_api.dart';
import '../services/cloud/vault_api_client.dart';
import 'auth_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core Singleton Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [VaultApiClient] singleton, configured for port 8097.
final vaultApiClientProvider = Provider<VaultApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return VaultApiClient(secureStorage: secureStorage);
});

/// Provides the [VaultApi] singleton for all Vault API calls.
final vaultApiProvider = Provider<VaultApi>((ref) {
  final client = ref.watch(vaultApiClientProvider);
  return VaultApi(client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Seal Status
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the current Vault seal status (auto-refreshes when invalidated).
final sealStatusProvider = FutureProvider<SealStatusResponse>((ref) {
  final api = ref.watch(vaultApiProvider);
  return api.getSealStatus();
});

// ─────────────────────────────────────────────────────────────────────────────
// Secrets — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a paginated secret list with filters.
final vaultSecretsProvider =
    FutureProvider<PageResponse<SecretResponse>>((ref) {
  final api = ref.watch(vaultApiProvider);
  final type = ref.watch(vaultSecretTypeFilterProvider);
  final pathPrefix = ref.watch(vaultSecretPathFilterProvider);
  final activeOnly = ref.watch(vaultSecretActiveOnlyProvider);
  final page = ref.watch(vaultSecretPageProvider);
  final sortBy = ref.watch(vaultSecretSortByProvider);
  final sortDir = ref.watch(vaultSecretSortDirProvider);
  return api.listSecrets(
    type: type,
    pathPrefix: pathPrefix.isEmpty ? null : pathPrefix,
    activeOnly: activeOnly,
    page: page,
    size: 20,
    sortBy: sortBy,
    sortDir: sortDir,
  );
});

/// Searches secrets by name. Returns empty page for queries under 2 chars.
final vaultSecretSearchProvider =
    FutureProvider.family<PageResponse<SecretResponse>, String>((ref, query) {
  if (query.length < 2) return PageResponse.empty();
  final api = ref.watch(vaultApiProvider);
  return api.searchSecrets(query);
});

/// Fetches a single secret's metadata by ID.
final vaultSecretDetailProvider =
    FutureProvider.family<SecretResponse, String>((ref, id) {
  final api = ref.watch(vaultApiProvider);
  return api.getSecret(id);
});

/// Fetches the decrypted value for a secret (current version).
final vaultSecretValueProvider =
    FutureProvider.family<SecretValueResponse, String>((ref, id) {
  final api = ref.watch(vaultApiProvider);
  return api.readSecretValue(id);
});

/// Fetches paginated versions for a secret.
final vaultSecretVersionsProvider =
    FutureProvider.family<PageResponse<SecretVersionResponse>, String>(
        (ref, secretId) {
  final api = ref.watch(vaultApiProvider);
  return api.listVersions(secretId);
});

/// Fetches metadata key-value pairs for a secret.
final vaultSecretMetadataProvider =
    FutureProvider.family<Map<String, String>, String>((ref, secretId) {
  final api = ref.watch(vaultApiProvider);
  return api.getMetadata(secretId);
});

/// Fetches secret paths under a prefix (directory browser).
final vaultSecretPathsProvider =
    FutureProvider.family<List<String>, String>((ref, prefix) {
  final api = ref.watch(vaultApiProvider);
  return api.listPaths(prefix: prefix);
});

/// Fetches secret statistics (counts by type).
final vaultSecretStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final api = ref.watch(vaultApiProvider);
  return api.getSecretStats();
});

/// Fetches secrets expiring within 72 hours.
final vaultExpiringSecretsProvider =
    FutureProvider<List<SecretResponse>>((ref) {
  final api = ref.watch(vaultApiProvider);
  return api.getExpiringSecrets(withinHours: 72);
});

// ─────────────────────────────────────────────────────────────────────────────
// Secrets — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Currently selected secret type filter (null = all types).
final vaultSecretTypeFilterProvider =
    StateProvider<SecretType?>((ref) => null);

/// Current path prefix filter for secrets.
final vaultSecretPathFilterProvider = StateProvider<String>((ref) => '');

/// Whether to show only active secrets.
final vaultSecretActiveOnlyProvider = StateProvider<bool>((ref) => true);

/// Current page index for the secrets list.
final vaultSecretPageProvider = StateProvider<int>((ref) => 0);

/// Sort field for the secrets list.
final vaultSecretSortByProvider = StateProvider<String>((ref) => 'createdAt');

/// Sort direction for the secrets list.
final vaultSecretSortDirProvider = StateProvider<String>((ref) => 'desc');

/// Current search query for secrets.
final vaultSecretSearchQueryProvider = StateProvider<String>((ref) => '');

/// ID of the currently selected secret.
final selectedVaultSecretIdProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Policies — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a paginated policy list with filters and sorting.
final vaultPoliciesProvider =
    FutureProvider<PageResponse<AccessPolicyResponse>>((ref) {
  final api = ref.watch(vaultApiProvider);
  final activeOnly = ref.watch(vaultPolicyActiveOnlyProvider);
  final page = ref.watch(vaultPolicyPageProvider);
  final sortBy = ref.watch(vaultPolicySortByProvider);
  final sortDir = ref.watch(vaultPolicySortDirProvider);
  return api.listPolicies(
    activeOnly: activeOnly,
    page: page,
    sortBy: sortBy,
    sortDir: sortDir,
  );
});

/// Fetches a single policy by ID.
final vaultPolicyDetailProvider =
    FutureProvider.family<AccessPolicyResponse, String>((ref, id) {
  final api = ref.watch(vaultApiProvider);
  return api.getPolicy(id);
});

/// Fetches bindings for a policy.
final vaultPolicyBindingsProvider =
    FutureProvider.family<List<PolicyBindingResponse>, String>(
        (ref, policyId) {
  final api = ref.watch(vaultApiProvider);
  return api.listBindingsForPolicy(policyId);
});

/// Fetches policy statistics.
final vaultPolicyStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final api = ref.watch(vaultApiProvider);
  return api.getPolicyStats();
});

// ─────────────────────────────────────────────────────────────────────────────
// Policies — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Whether to show only active policies.
final vaultPolicyActiveOnlyProvider = StateProvider<bool>((ref) => true);

/// Current page index for the policies list.
final vaultPolicyPageProvider = StateProvider<int>((ref) => 0);

/// Sort field for the policies list.
final vaultPolicySortByProvider = StateProvider<String>((ref) => 'createdAt');

/// Sort direction for the policies list.
final vaultPolicySortDirProvider = StateProvider<String>((ref) => 'desc');

/// ID of the currently selected policy.
final selectedVaultPolicyIdProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Rotation — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the rotation policy for a secret.
final vaultRotationPolicyProvider =
    FutureProvider.family<RotationPolicyResponse, String>((ref, secretId) {
  final api = ref.watch(vaultApiProvider);
  return api.getRotationPolicy(secretId);
});

/// Fetches paginated rotation history for a secret.
final vaultRotationHistoryProvider =
    FutureProvider.family<PageResponse<RotationHistoryResponse>, String>(
        (ref, secretId) {
  final api = ref.watch(vaultApiProvider);
  return api.getRotationHistory(secretId);
});

/// Fetches rotation statistics for a secret.
final vaultRotationStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, secretId) {
  final api = ref.watch(vaultApiProvider);
  return api.getRotationStats(secretId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Transit — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a paginated list of transit keys.
final vaultTransitKeysProvider =
    FutureProvider<PageResponse<TransitKeyResponse>>((ref) {
  final api = ref.watch(vaultApiProvider);
  final activeOnly = ref.watch(vaultTransitActiveOnlyProvider);
  final page = ref.watch(vaultTransitPageProvider);
  return api.listTransitKeys(activeOnly: activeOnly, page: page);
});

/// Fetches a single transit key by ID.
final vaultTransitKeyDetailProvider =
    FutureProvider.family<TransitKeyResponse, String>((ref, id) {
  final api = ref.watch(vaultApiProvider);
  return api.getTransitKeyById(id);
});

/// Fetches transit key statistics.
final vaultTransitStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final api = ref.watch(vaultApiProvider);
  return api.getTransitKeyStats();
});

// ─────────────────────────────────────────────────────────────────────────────
// Transit — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Whether to show only active transit keys.
final vaultTransitActiveOnlyProvider = StateProvider<bool>((ref) => true);

/// Current page index for the transit keys list.
final vaultTransitPageProvider = StateProvider<int>((ref) => 0);

/// ID of the currently selected transit key.
final selectedVaultTransitKeyIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Secrets — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated leases for a dynamic secret.
final vaultLeasesProvider =
    FutureProvider.family<PageResponse<DynamicLeaseResponse>, String>(
        (ref, secretId) {
  final api = ref.watch(vaultApiProvider);
  return api.listDynamicLeases(secretId);
});

/// Fetches lease statistics for a dynamic secret.
final vaultLeaseStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, secretId) {
  final api = ref.watch(vaultApiProvider);
  return api.getDynamicLeaseStats(secretId);
});

/// Fetches the total number of active leases across all secrets.
final vaultActiveLeaseCountProvider = FutureProvider<int>((ref) {
  final api = ref.watch(vaultApiProvider);
  return api.getActiveDynamicLeaseCount();
});

// ─────────────────────────────────────────────────────────────────────────────
// Audit — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a paginated audit log with filters.
final vaultAuditLogProvider =
    FutureProvider<PageResponse<AuditEntryResponse>>((ref) {
  final api = ref.watch(vaultApiProvider);
  final operation = ref.watch(vaultAuditOperationFilterProvider);
  final resourceType = ref.watch(vaultAuditResourceTypeFilterProvider);
  final successOnly = ref.watch(vaultAuditSuccessOnlyProvider);
  final page = ref.watch(vaultAuditPageProvider);
  return api.queryAuditLog(
    operation: operation.isEmpty ? null : operation,
    resourceType: resourceType.isEmpty ? null : resourceType,
    successOnly: successOnly,
    page: page,
  );
});

/// Fetches audit log statistics.
final vaultAuditStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final api = ref.watch(vaultApiProvider);
  return api.getAuditStats();
});

/// Fetches audit entries for a specific resource.
final vaultResourceAuditProvider = FutureProvider.family<
    PageResponse<AuditEntryResponse>,
    ({String type, String id})>((ref, params) {
  final api = ref.watch(vaultApiProvider);
  return api.getAuditForResource(params.type, params.id);
});

// ─────────────────────────────────────────────────────────────────────────────
// Audit — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current operation filter for audit log.
final vaultAuditOperationFilterProvider =
    StateProvider<String>((ref) => '');

/// Current resource type filter for audit log.
final vaultAuditResourceTypeFilterProvider =
    StateProvider<String>((ref) => '');

/// Success-only filter for audit log (null = show all).
final vaultAuditSuccessOnlyProvider = StateProvider<bool?>((ref) => null);

/// Current page index for the audit log.
final vaultAuditPageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Navigation State
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Secret Detail Page — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the decrypted value for a specific secret version.
final vaultSecretVersionValueProvider = FutureProvider.family<
    SecretValueResponse,
    ({String secretId, int version})>((ref, params) {
  final api = ref.watch(vaultApiProvider);
  return api.readSecretVersionValue(params.secretId, params.version);
});

// ─────────────────────────────────────────────────────────────────────────────
// Rotation — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Selected secret ID in the rotation dashboard.
final selectedRotationSecretIdProvider = StateProvider<String?>((ref) => null);

/// Current page index for rotation history in the rotation dashboard.
final vaultRotationHistoryPageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Navigation State
// ─────────────────────────────────────────────────────────────────────────────

/// Active vault tab index.
///
/// 0=Secrets, 1=Policies, 2=Transit, 3=Dynamic, 4=Rotation, 5=Seal, 6=Audit.
final vaultActiveTabProvider = StateProvider<int>((ref) => 0);
