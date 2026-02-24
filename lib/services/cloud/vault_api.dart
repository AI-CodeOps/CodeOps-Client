/// API service for all CodeOps-Vault endpoints.
///
/// Covers secrets, access policies, rotation, transit encryption,
/// dynamic secret leases, seal/unseal lifecycle, and audit log queries.
/// All 67 endpoints from CodeOps-Vault-OpenAPI.yaml are represented here.
library;

import '../../models/health_snapshot.dart';
import '../../models/vault_enums.dart';
import '../../models/vault_models.dart';
import 'vault_api_client.dart';

/// API service for CodeOps-Vault endpoints.
///
/// Provides typed methods for every Vault endpoint, organized by
/// controller: Secrets, Policies, Rotation, Transit, Dynamic Secrets,
/// Seal, and Audit.
class VaultApi {
  final VaultApiClient _client;

  /// Creates a [VaultApi] backed by the given Vault [client].
  VaultApi(this._client);

  // ═══════════════════════════════════════════════════════════════════════════
  // Secrets (19 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new secret.
  Future<SecretResponse> createSecret({
    required String path,
    required String name,
    required String value,
    required SecretType secretType,
    String? description,
    String? referenceArn,
    int? maxVersions,
    int? retentionDays,
    DateTime? expiresAt,
    Map<String, String>? metadata,
  }) async {
    final body = <String, dynamic>{
      'path': path,
      'name': name,
      'value': value,
      'secretType': secretType.toJson(),
    };
    if (description != null) body['description'] = description;
    if (referenceArn != null) body['referenceArn'] = referenceArn;
    if (maxVersions != null) body['maxVersions'] = maxVersions;
    if (retentionDays != null) body['retentionDays'] = retentionDays;
    if (expiresAt != null) {
      body['expiresAt'] = expiresAt.toUtc().toIso8601String();
    }
    if (metadata != null) body['metadata'] = metadata;

    final response = await _client.post<Map<String, dynamic>>(
      '/secrets',
      data: body,
    );
    return SecretResponse.fromJson(response.data!);
  }

  /// Lists secrets with optional filters and pagination.
  Future<PageResponse<SecretResponse>> listSecrets({
    SecretType? type,
    String? pathPrefix,
    bool? activeOnly,
    int page = 0,
    int size = 20,
    String? sortBy,
    String? sortDir,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (type != null) params['type'] = type.toJson();
    if (pathPrefix != null) params['pathPrefix'] = pathPrefix;
    if (activeOnly != null) params['activeOnly'] = activeOnly;
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortDir != null) params['sortDir'] = sortDir;

    final response = await _client.get<Map<String, dynamic>>(
      '/secrets',
      queryParameters: params,
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => SecretResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Gets secret metadata by [secretId].
  Future<SecretResponse> getSecret(String secretId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/$secretId',
    );
    return SecretResponse.fromJson(response.data!);
  }

  /// Updates a secret's metadata and/or creates a new version.
  Future<SecretResponse> updateSecret(
    String secretId, {
    String? value,
    String? changeDescription,
    String? description,
    int? maxVersions,
    int? retentionDays,
    DateTime? expiresAt,
    Map<String, String>? metadata,
  }) async {
    final body = <String, dynamic>{};
    if (value != null) body['value'] = value;
    if (changeDescription != null) {
      body['changeDescription'] = changeDescription;
    }
    if (description != null) body['description'] = description;
    if (maxVersions != null) body['maxVersions'] = maxVersions;
    if (retentionDays != null) body['retentionDays'] = retentionDays;
    if (expiresAt != null) {
      body['expiresAt'] = expiresAt.toUtc().toIso8601String();
    }
    if (metadata != null) body['metadata'] = metadata;

    final response = await _client.put<Map<String, dynamic>>(
      '/secrets/$secretId',
      data: body,
    );
    return SecretResponse.fromJson(response.data!);
  }

  /// Soft-deletes a secret (sets inactive).
  Future<void> softDeleteSecret(String secretId) async {
    await _client.delete('/secrets/$secretId');
  }

  /// Permanently deletes a secret and all its versions.
  Future<void> hardDeleteSecret(String secretId) async {
    await _client.delete('/secrets/$secretId/permanent');
  }

  /// Gets secret metadata by path.
  Future<SecretResponse> getSecretByPath(String path) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/by-path',
      queryParameters: {'path': path},
    );
    return SecretResponse.fromJson(response.data!);
  }

  /// Reads the decrypted value of the current version.
  Future<SecretValueResponse> readSecretValue(String secretId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/$secretId/value',
    );
    return SecretValueResponse.fromJson(response.data!);
  }

  /// Lists secret versions with pagination.
  Future<PageResponse<SecretVersionResponse>> listVersions(
    String secretId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/$secretId/versions',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => SecretVersionResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Gets version metadata for a specific version number.
  Future<SecretVersionResponse> getVersion(
    String secretId,
    int version,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/$secretId/versions/$version',
    );
    return SecretVersionResponse.fromJson(response.data!);
  }

  /// Destroys a secret version (irreversible).
  Future<void> destroyVersion(String secretId, int version) async {
    await _client.delete('/secrets/$secretId/versions/$version');
  }

  /// Reads the decrypted value of a specific version.
  Future<SecretValueResponse> readSecretVersionValue(
    String secretId,
    int version,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/$secretId/versions/$version/value',
    );
    return SecretValueResponse.fromJson(response.data!);
  }

  /// Gets the metadata key-value pairs for a secret.
  Future<Map<String, String>> getMetadata(String secretId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/$secretId/metadata',
    );
    return response.data!.map((k, v) => MapEntry(k, v as String));
  }

  /// Sets a single metadata key-value pair on a secret.
  Future<void> setMetadata(
    String secretId,
    String key,
    String value,
  ) async {
    await _client.put(
      '/secrets/$secretId/metadata/$key',
      data: value,
    );
  }

  /// Removes a metadata key from a secret.
  Future<void> removeMetadata(String secretId, String key) async {
    await _client.delete('/secrets/$secretId/metadata/$key');
  }

  /// Searches secrets by name with pagination.
  Future<PageResponse<SecretResponse>> searchSecrets(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/search',
      queryParameters: {'q': query, 'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => SecretResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Lists secret paths under a prefix.
  Future<List<String>> listPaths({String prefix = '/'}) async {
    final response = await _client.get<List<dynamic>>(
      '/secrets/paths',
      queryParameters: {'prefix': prefix},
    );
    return response.data!.cast<String>();
  }

  /// Gets secret statistics (counts by type).
  Future<Map<String, int>> getSecretStats() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/secrets/stats',
    );
    return response.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// Gets secrets expiring within [withinHours].
  Future<List<SecretResponse>> getExpiringSecrets({
    int withinHours = 24,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/secrets/expiring',
      queryParameters: {'withinHours': withinHours},
    );
    return response.data!
        .map((e) => SecretResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Policies (12 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates an access policy.
  Future<AccessPolicyResponse> createPolicy({
    required String name,
    required String pathPattern,
    required List<PolicyPermission> permissions,
    String? description,
    bool? isDenyPolicy,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'pathPattern': pathPattern,
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
    if (description != null) body['description'] = description;
    if (isDenyPolicy != null) body['isDenyPolicy'] = isDenyPolicy;

    final response = await _client.post<Map<String, dynamic>>(
      '/policies',
      data: body,
    );
    return AccessPolicyResponse.fromJson(response.data!);
  }

  /// Lists policies with optional filters, sorting, and pagination.
  Future<PageResponse<AccessPolicyResponse>> listPolicies({
    bool? activeOnly,
    int page = 0,
    int size = 20,
    String? sortBy,
    String? sortDir,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (activeOnly != null) params['activeOnly'] = activeOnly;
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortDir != null) params['sortDir'] = sortDir;

    final response = await _client.get<Map<String, dynamic>>(
      '/policies',
      queryParameters: params,
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          AccessPolicyResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Gets a policy by [policyId].
  Future<AccessPolicyResponse> getPolicy(String policyId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/policies/$policyId',
    );
    return AccessPolicyResponse.fromJson(response.data!);
  }

  /// Updates an access policy.
  Future<AccessPolicyResponse> updatePolicy(
    String policyId, {
    String? name,
    String? description,
    String? pathPattern,
    List<PolicyPermission>? permissions,
    bool? isDenyPolicy,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (pathPattern != null) body['pathPattern'] = pathPattern;
    if (permissions != null) {
      body['permissions'] = permissions.map((p) => p.toJson()).toList();
    }
    if (isDenyPolicy != null) body['isDenyPolicy'] = isDenyPolicy;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.put<Map<String, dynamic>>(
      '/policies/$policyId',
      data: body,
    );
    return AccessPolicyResponse.fromJson(response.data!);
  }

  /// Deletes a policy and all its bindings.
  Future<void> deletePolicy(String policyId) async {
    await _client.delete('/policies/$policyId');
  }

  /// Creates a policy binding.
  Future<PolicyBindingResponse> createBinding({
    required String policyId,
    required BindingType bindingType,
    required String bindingTargetId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/policies/bindings',
      data: {
        'policyId': policyId,
        'bindingType': bindingType.toJson(),
        'bindingTargetId': bindingTargetId,
      },
    );
    return PolicyBindingResponse.fromJson(response.data!);
  }

  /// Lists bindings for a policy.
  Future<List<PolicyBindingResponse>> listBindingsForPolicy(
    String policyId,
  ) async {
    final response = await _client.get<List<dynamic>>(
      '/policies/$policyId/bindings',
    );
    return response.data!
        .map((e) =>
            PolicyBindingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lists bindings for a target entity.
  Future<List<PolicyBindingResponse>> listBindingsForTarget({
    required BindingType type,
    required String targetId,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/policies/bindings/target',
      queryParameters: {
        'type': type.toJson(),
        'targetId': targetId,
      },
    );
    return response.data!
        .map((e) =>
            PolicyBindingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a binding.
  Future<void> deleteBinding(String bindingId) async {
    await _client.delete('/policies/bindings/$bindingId');
  }

  /// Evaluates access for a user on a path.
  Future<AccessDecision> evaluateAccess({
    required String userId,
    required String path,
    required PolicyPermission permission,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/policies/evaluate',
      queryParameters: {
        'userId': userId,
        'path': path,
        'permission': permission.toJson(),
      },
    );
    return AccessDecision.fromJson(response.data!);
  }

  /// Evaluates access for a service on a path.
  Future<AccessDecision> evaluateServiceAccess({
    required String serviceId,
    required String path,
    required PolicyPermission permission,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/policies/evaluate/service',
      queryParameters: {
        'serviceId': serviceId,
        'path': path,
        'permission': permission.toJson(),
      },
    );
    return AccessDecision.fromJson(response.data!);
  }

  /// Gets policy statistics.
  Future<Map<String, int>> getPolicyStats() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/policies/stats',
    );
    return response.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Rotation (8 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates or updates a rotation policy for a secret.
  Future<RotationPolicyResponse> createOrUpdateRotationPolicy({
    required String secretId,
    required RotationStrategy strategy,
    required int rotationIntervalHours,
    int? randomLength,
    String? randomCharset,
    String? externalApiUrl,
    String? externalApiHeaders,
    String? scriptCommand,
    int? maxFailures,
  }) async {
    final body = <String, dynamic>{
      'secretId': secretId,
      'strategy': strategy.toJson(),
      'rotationIntervalHours': rotationIntervalHours,
    };
    if (randomLength != null) body['randomLength'] = randomLength;
    if (randomCharset != null) body['randomCharset'] = randomCharset;
    if (externalApiUrl != null) body['externalApiUrl'] = externalApiUrl;
    if (externalApiHeaders != null) {
      body['externalApiHeaders'] = externalApiHeaders;
    }
    if (scriptCommand != null) body['scriptCommand'] = scriptCommand;
    if (maxFailures != null) body['maxFailures'] = maxFailures;

    final response = await _client.post<Map<String, dynamic>>(
      '/rotation/policies',
      data: body,
    );
    return RotationPolicyResponse.fromJson(response.data!);
  }

  /// Gets the rotation policy for a secret.
  Future<RotationPolicyResponse> getRotationPolicy(String secretId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/rotation/policies/$secretId',
    );
    return RotationPolicyResponse.fromJson(response.data!);
  }

  /// Updates a rotation policy.
  Future<RotationPolicyResponse> updateRotationPolicy(
    String policyId, {
    RotationStrategy? strategy,
    int? rotationIntervalHours,
    int? randomLength,
    String? randomCharset,
    String? externalApiUrl,
    String? externalApiHeaders,
    String? scriptCommand,
    int? maxFailures,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (strategy != null) body['strategy'] = strategy.toJson();
    if (rotationIntervalHours != null) {
      body['rotationIntervalHours'] = rotationIntervalHours;
    }
    if (randomLength != null) body['randomLength'] = randomLength;
    if (randomCharset != null) body['randomCharset'] = randomCharset;
    if (externalApiUrl != null) body['externalApiUrl'] = externalApiUrl;
    if (externalApiHeaders != null) {
      body['externalApiHeaders'] = externalApiHeaders;
    }
    if (scriptCommand != null) body['scriptCommand'] = scriptCommand;
    if (maxFailures != null) body['maxFailures'] = maxFailures;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.put<Map<String, dynamic>>(
      '/rotation/policies/$policyId',
      data: body,
    );
    return RotationPolicyResponse.fromJson(response.data!);
  }

  /// Deletes a rotation policy.
  Future<void> deleteRotationPolicy(String policyId) async {
    await _client.delete('/rotation/policies/$policyId');
  }

  /// Triggers manual rotation for a secret.
  Future<RotationHistoryResponse> rotateSecret(String secretId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/rotation/rotate/$secretId',
    );
    return RotationHistoryResponse.fromJson(response.data!);
  }

  /// Gets rotation history for a secret with pagination.
  Future<PageResponse<RotationHistoryResponse>> getRotationHistory(
    String secretId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/rotation/history/$secretId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          RotationHistoryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Gets the last successful rotation for a secret.
  Future<RotationHistoryResponse> getLastSuccessfulRotation(
    String secretId,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/rotation/history/$secretId/last',
    );
    return RotationHistoryResponse.fromJson(response.data!);
  }

  /// Gets rotation statistics for a secret.
  Future<Map<String, int>> getRotationStats(String secretId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/rotation/stats/$secretId',
    );
    return response.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Transit (12 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a named transit encryption key.
  Future<TransitKeyResponse> createTransitKey({
    required String name,
    String? description,
    String? algorithm,
    bool? isDeletable,
    bool? isExportable,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (algorithm != null) body['algorithm'] = algorithm;
    if (isDeletable != null) body['isDeletable'] = isDeletable;
    if (isExportable != null) body['isExportable'] = isExportable;

    final response = await _client.post<Map<String, dynamic>>(
      '/transit/keys',
      data: body,
    );
    return TransitKeyResponse.fromJson(response.data!);
  }

  /// Lists transit keys with optional filters and pagination.
  Future<PageResponse<TransitKeyResponse>> listTransitKeys({
    bool? activeOnly,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (activeOnly != null) params['activeOnly'] = activeOnly;

    final response = await _client.get<Map<String, dynamic>>(
      '/transit/keys',
      queryParameters: params,
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => TransitKeyResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Gets a transit key by [keyId].
  Future<TransitKeyResponse> getTransitKeyById(String keyId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/transit/keys/$keyId',
    );
    return TransitKeyResponse.fromJson(response.data!);
  }

  /// Updates transit key metadata.
  Future<TransitKeyResponse> updateTransitKey(
    String keyId, {
    String? description,
    int? minDecryptionVersion,
    bool? isDeletable,
    bool? isExportable,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (minDecryptionVersion != null) {
      body['minDecryptionVersion'] = minDecryptionVersion;
    }
    if (isDeletable != null) body['isDeletable'] = isDeletable;
    if (isExportable != null) body['isExportable'] = isExportable;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.put<Map<String, dynamic>>(
      '/transit/keys/$keyId',
      data: body,
    );
    return TransitKeyResponse.fromJson(response.data!);
  }

  /// Deletes a transit key (must be marked as deletable).
  Future<void> deleteTransitKey(String keyId) async {
    await _client.delete('/transit/keys/$keyId');
  }

  /// Gets a transit key by name.
  Future<TransitKeyResponse> getTransitKeyByName(String name) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/transit/keys/by-name',
      queryParameters: {'name': name},
    );
    return TransitKeyResponse.fromJson(response.data!);
  }

  /// Rotates a transit key (adds a new version).
  Future<TransitKeyResponse> rotateTransitKey(String keyId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/transit/keys/$keyId/rotate',
    );
    return TransitKeyResponse.fromJson(response.data!);
  }

  /// Encrypts data with a named transit key.
  Future<TransitEncryptResponse> transitEncrypt({
    required String keyName,
    required String plaintext,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/transit/encrypt',
      data: {'keyName': keyName, 'plaintext': plaintext},
    );
    return TransitEncryptResponse.fromJson(response.data!);
  }

  /// Decrypts data with a named transit key.
  Future<TransitDecryptResponse> transitDecrypt({
    required String keyName,
    required String ciphertext,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/transit/decrypt',
      data: {'keyName': keyName, 'ciphertext': ciphertext},
    );
    return TransitDecryptResponse.fromJson(response.data!);
  }

  /// Re-encrypts ciphertext with the current key version.
  Future<TransitEncryptResponse> transitRewrap({
    required String keyName,
    required String ciphertext,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/transit/rewrap',
      data: {'keyName': keyName, 'ciphertext': ciphertext},
    );
    return TransitEncryptResponse.fromJson(response.data!);
  }

  /// Generates a data encryption key wrapped with a named transit key.
  Future<Map<String, String>> generateDataKey(String keyName) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/transit/datakey',
      queryParameters: {'keyName': keyName},
    );
    return response.data!.map((k, v) => MapEntry(k, v as String));
  }

  /// Gets transit key statistics.
  Future<Map<String, int>> getTransitKeyStats() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/transit/stats',
    );
    return response.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dynamic Secrets (7 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new dynamic secret lease.
  Future<DynamicLeaseResponse> createDynamicLease({
    required String secretId,
    required int ttlSeconds,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/dynamic/leases',
      data: {'secretId': secretId, 'ttlSeconds': ttlSeconds},
    );
    return DynamicLeaseResponse.fromJson(response.data!);
  }

  /// Lists leases for a dynamic secret with pagination.
  Future<PageResponse<DynamicLeaseResponse>> listDynamicLeases(
    String secretId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/dynamic/leases',
      queryParameters: {'secretId': secretId, 'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          DynamicLeaseResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Gets a lease by [leaseId].
  Future<DynamicLeaseResponse> getDynamicLease(String leaseId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/dynamic/leases/$leaseId',
    );
    return DynamicLeaseResponse.fromJson(response.data!);
  }

  /// Revokes an active lease.
  Future<void> revokeDynamicLease(String leaseId) async {
    await _client.post('/dynamic/leases/$leaseId/revoke');
  }

  /// Revokes all active leases for a secret.
  Future<int> revokeAllDynamicLeases(String secretId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/dynamic/leases/revoke-all',
      queryParameters: {'secretId': secretId},
    );
    return response.data!['revoked'] as int;
  }

  /// Gets lease statistics for a dynamic secret.
  Future<Map<String, int>> getDynamicLeaseStats(String secretId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/dynamic/stats',
      queryParameters: {'secretId': secretId},
    );
    return response.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// Gets the total number of active leases across all secrets.
  Future<int> getActiveDynamicLeaseCount() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/dynamic/active-count',
    );
    return (response.data!['activeLeases'] as num).toInt();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Seal (5 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets the current seal status (public — no auth required).
  Future<SealStatusResponse> getSealStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/seal/status',
    );
    return SealStatusResponse.fromJson(response.data!);
  }

  /// Seals the Vault.
  Future<SealStatusResponse> sealVault() async {
    final response = await _client.post<Map<String, dynamic>>(
      '/seal/seal',
    );
    return SealStatusResponse.fromJson(response.data!);
  }

  /// Submits a key share to unseal the Vault.
  Future<SealStatusResponse> unsealVault({
    required String action,
    String? keyShare,
  }) async {
    final body = <String, dynamic>{'action': action};
    if (keyShare != null) body['keyShare'] = keyShare;

    final response = await _client.post<Map<String, dynamic>>(
      '/seal/unseal',
      data: body,
    );
    return SealStatusResponse.fromJson(response.data!);
  }

  /// Generates key shares for distribution.
  Future<Map<String, dynamic>> generateShares() async {
    final response = await _client.post<Map<String, dynamic>>(
      '/seal/generate-shares',
    );
    return response.data!;
  }

  /// Gets seal configuration info.
  Future<Map<String, dynamic>> getSealInfo() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/seal/info',
    );
    return response.data!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Audit (3 endpoints)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Queries the audit log with optional filters and pagination.
  Future<PageResponse<AuditEntryResponse>> queryAuditLog({
    String? userId,
    String? operation,
    String? path,
    String? resourceType,
    String? resourceId,
    bool? successOnly,
    DateTime? startTime,
    DateTime? endTime,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (userId != null) params['userId'] = userId;
    if (operation != null) params['operation'] = operation;
    if (path != null) params['path'] = path;
    if (resourceType != null) params['resourceType'] = resourceType;
    if (resourceId != null) params['resourceId'] = resourceId;
    if (successOnly != null) params['successOnly'] = successOnly;
    if (startTime != null) {
      params['startTime'] = startTime.toUtc().toIso8601String();
    }
    if (endTime != null) {
      params['endTime'] = endTime.toUtc().toIso8601String();
    }

    final response = await _client.get<Map<String, dynamic>>(
      '/audit/query',
      queryParameters: params,
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          AuditEntryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Gets audit entries for a specific resource.
  Future<PageResponse<AuditEntryResponse>> getAuditForResource(
    String resourceType,
    String resourceId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/audit/resource/$resourceType/$resourceId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) =>
          AuditEntryResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Gets audit log statistics.
  Future<Map<String, int>> getAuditStats() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/audit/stats',
    );
    return response.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
  }
}
