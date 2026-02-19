/// Vault response model classes.
///
/// Maps to the response DTOs defined in CodeOps-Vault-OpenAPI.yaml.
/// All 14 response models use [JsonSerializable] with generated
/// `fromJson` / `toJson` methods via build_runner.
library;

import 'package:json_annotation/json_annotation.dart';

import 'vault_enums.dart';

part 'vault_models.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Secret responses
// ─────────────────────────────────────────────────────────────────────────────

/// Metadata for a stored secret (never includes the secret value).
@JsonSerializable()
class SecretResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the owning team.
  final String teamId;

  /// Hierarchical path (e.g., "/services/my-app/db-password").
  final String path;

  /// Human-readable name.
  final String name;

  /// Optional description.
  final String? description;

  /// Storage type of the secret.
  @SecretTypeConverter()
  final SecretType secretType;

  /// Current version number.
  final int currentVersion;

  /// Maximum number of versions to retain (null = unlimited).
  final int? maxVersions;

  /// Days to retain old versions (null = forever).
  final int? retentionDays;

  /// Optional expiration timestamp.
  final DateTime? expiresAt;

  /// Timestamp of the last read access.
  final DateTime? lastAccessedAt;

  /// Timestamp of the last rotation.
  final DateTime? lastRotatedAt;

  /// UUID of the user who owns this secret.
  final String? ownerUserId;

  /// External store ARN/URL for REFERENCE type secrets.
  final String? referenceArn;

  /// Whether the secret is active (false = soft-deleted).
  final bool isActive;

  /// Key-value metadata pairs.
  final Map<String, String>? metadata;

  /// Timestamp when the secret was created.
  final DateTime? createdAt;

  /// Timestamp when the secret was last updated.
  final DateTime? updatedAt;

  /// Creates a [SecretResponse] instance.
  const SecretResponse({
    required this.id,
    required this.teamId,
    required this.path,
    required this.name,
    this.description,
    required this.secretType,
    required this.currentVersion,
    this.maxVersions,
    this.retentionDays,
    this.expiresAt,
    this.lastAccessedAt,
    this.lastRotatedAt,
    this.ownerUserId,
    this.referenceArn,
    required this.isActive,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [SecretResponse] from a JSON map.
  factory SecretResponse.fromJson(Map<String, dynamic> json) =>
      _$SecretResponseFromJson(json);

  /// Serializes this [SecretResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$SecretResponseToJson(this);
}

/// Decrypted secret value for a specific version.
@JsonSerializable()
class SecretValueResponse {
  /// UUID of the secret.
  final String secretId;

  /// Hierarchical path.
  final String path;

  /// Human-readable name.
  final String name;

  /// Version number of the returned value.
  final int versionNumber;

  /// The decrypted secret value.
  final String value;

  /// Timestamp when this version was created.
  final DateTime? createdAt;

  /// Creates a [SecretValueResponse] instance.
  const SecretValueResponse({
    required this.secretId,
    required this.path,
    required this.name,
    required this.versionNumber,
    required this.value,
    this.createdAt,
  });

  /// Deserializes a [SecretValueResponse] from a JSON map.
  factory SecretValueResponse.fromJson(Map<String, dynamic> json) =>
      _$SecretValueResponseFromJson(json);

  /// Serializes this [SecretValueResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$SecretValueResponseToJson(this);
}

/// Metadata for a single secret version.
@JsonSerializable()
class SecretVersionResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent secret.
  final String secretId;

  /// Version number.
  final int versionNumber;

  /// Identifier of the encryption key used.
  final String? encryptionKeyId;

  /// Description of what changed in this version.
  final String? changeDescription;

  /// UUID of the user who created this version.
  final String? createdByUserId;

  /// Whether this version has been destroyed (value zeroed).
  final bool isDestroyed;

  /// Timestamp when this version was created.
  final DateTime? createdAt;

  /// Creates a [SecretVersionResponse] instance.
  const SecretVersionResponse({
    required this.id,
    required this.secretId,
    required this.versionNumber,
    this.encryptionKeyId,
    this.changeDescription,
    this.createdByUserId,
    required this.isDestroyed,
    this.createdAt,
  });

  /// Deserializes a [SecretVersionResponse] from a JSON map.
  factory SecretVersionResponse.fromJson(Map<String, dynamic> json) =>
      _$SecretVersionResponseFromJson(json);

  /// Serializes this [SecretVersionResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$SecretVersionResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Policy responses
// ─────────────────────────────────────────────────────────────────────────────

/// An access policy governing path-based secret permissions.
@JsonSerializable()
class AccessPolicyResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the owning team.
  final String teamId;

  /// Policy name (unique within team).
  final String name;

  /// Optional description.
  final String? description;

  /// Glob pattern matching secret paths.
  final String pathPattern;

  /// Permissions granted (or denied) by this policy.
  @_PolicyPermissionListConverter()
  final List<PolicyPermission> permissions;

  /// Whether this policy denies the listed permissions.
  final bool isDenyPolicy;

  /// Whether this policy is currently active.
  final bool isActive;

  /// UUID of the user who created this policy.
  final String? createdByUserId;

  /// Number of bindings associated with this policy.
  final int bindingCount;

  /// Timestamp when the policy was created.
  final DateTime? createdAt;

  /// Timestamp when the policy was last updated.
  final DateTime? updatedAt;

  /// Creates an [AccessPolicyResponse] instance.
  const AccessPolicyResponse({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    required this.pathPattern,
    required this.permissions,
    required this.isDenyPolicy,
    required this.isActive,
    this.createdByUserId,
    required this.bindingCount,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes an [AccessPolicyResponse] from a JSON map.
  factory AccessPolicyResponse.fromJson(Map<String, dynamic> json) =>
      _$AccessPolicyResponseFromJson(json);

  /// Serializes this [AccessPolicyResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AccessPolicyResponseToJson(this);
}

/// A binding between a policy and a target (user, team, or service).
@JsonSerializable()
class PolicyBindingResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the bound policy.
  final String policyId;

  /// Name of the bound policy.
  final String? policyName;

  /// Type of entity the policy is bound to.
  @BindingTypeConverter()
  final BindingType bindingType;

  /// UUID of the target entity.
  final String bindingTargetId;

  /// UUID of the user who created this binding.
  final String? createdByUserId;

  /// Timestamp when the binding was created.
  final DateTime? createdAt;

  /// Creates a [PolicyBindingResponse] instance.
  const PolicyBindingResponse({
    required this.id,
    required this.policyId,
    this.policyName,
    required this.bindingType,
    required this.bindingTargetId,
    this.createdByUserId,
    this.createdAt,
  });

  /// Deserializes a [PolicyBindingResponse] from a JSON map.
  factory PolicyBindingResponse.fromJson(Map<String, dynamic> json) =>
      _$PolicyBindingResponseFromJson(json);

  /// Serializes this [PolicyBindingResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$PolicyBindingResponseToJson(this);
}

/// Result of an access evaluation request.
@JsonSerializable()
class AccessDecision {
  /// Whether access is allowed.
  final bool allowed;

  /// Human-readable reason for the decision.
  final String? reason;

  /// UUID of the policy that decided (if any).
  final String? decidingPolicyId;

  /// Name of the deciding policy (if any).
  final String? decidingPolicyName;

  /// Creates an [AccessDecision] instance.
  const AccessDecision({
    required this.allowed,
    this.reason,
    this.decidingPolicyId,
    this.decidingPolicyName,
  });

  /// Deserializes an [AccessDecision] from a JSON map.
  factory AccessDecision.fromJson(Map<String, dynamic> json) =>
      _$AccessDecisionFromJson(json);

  /// Serializes this [AccessDecision] to a JSON map.
  Map<String, dynamic> toJson() => _$AccessDecisionToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rotation responses
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration for automatic secret rotation.
@JsonSerializable()
class RotationPolicyResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the target secret.
  final String secretId;

  /// Path of the target secret.
  final String? secretPath;

  /// Rotation strategy.
  @RotationStrategyConverter()
  final RotationStrategy strategy;

  /// Hours between automatic rotations.
  final int rotationIntervalHours;

  /// Length of randomly generated values (RANDOM_GENERATE only).
  final int? randomLength;

  /// Character set for random generation (RANDOM_GENERATE only).
  final String? randomCharset;

  /// URL for external API rotation (EXTERNAL_API only).
  final String? externalApiUrl;

  /// Whether the rotation policy is active.
  final bool isActive;

  /// Number of consecutive failures since last success.
  final int failureCount;

  /// Maximum failures before automatic deactivation.
  final int? maxFailures;

  /// Timestamp of the last successful rotation.
  final DateTime? lastRotatedAt;

  /// Scheduled time for the next rotation.
  final DateTime? nextRotationAt;

  /// Timestamp when the policy was created.
  final DateTime? createdAt;

  /// Timestamp when the policy was last updated.
  final DateTime? updatedAt;

  /// Creates a [RotationPolicyResponse] instance.
  const RotationPolicyResponse({
    required this.id,
    required this.secretId,
    this.secretPath,
    required this.strategy,
    required this.rotationIntervalHours,
    this.randomLength,
    this.randomCharset,
    this.externalApiUrl,
    required this.isActive,
    required this.failureCount,
    this.maxFailures,
    this.lastRotatedAt,
    this.nextRotationAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [RotationPolicyResponse] from a JSON map.
  factory RotationPolicyResponse.fromJson(Map<String, dynamic> json) =>
      _$RotationPolicyResponseFromJson(json);

  /// Serializes this [RotationPolicyResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$RotationPolicyResponseToJson(this);
}

/// A single entry in a secret's rotation history.
@JsonSerializable()
class RotationHistoryResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the rotated secret.
  final String secretId;

  /// Path of the rotated secret.
  final String? secretPath;

  /// Strategy used for this rotation.
  @RotationStrategyConverter()
  final RotationStrategy strategy;

  /// Version number before rotation.
  final int? previousVersion;

  /// Version number after rotation (null on failure).
  final int? newVersion;

  /// Whether the rotation succeeded.
  final bool success;

  /// Error message if rotation failed.
  final String? errorMessage;

  /// Duration of the rotation operation in milliseconds.
  final int? durationMs;

  /// UUID of the user who triggered rotation (null if automatic).
  final String? triggeredByUserId;

  /// Timestamp when the rotation was performed.
  final DateTime? createdAt;

  /// Creates a [RotationHistoryResponse] instance.
  const RotationHistoryResponse({
    required this.id,
    required this.secretId,
    this.secretPath,
    required this.strategy,
    this.previousVersion,
    this.newVersion,
    required this.success,
    this.errorMessage,
    this.durationMs,
    this.triggeredByUserId,
    this.createdAt,
  });

  /// Deserializes a [RotationHistoryResponse] from a JSON map.
  factory RotationHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$RotationHistoryResponseFromJson(json);

  /// Serializes this [RotationHistoryResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$RotationHistoryResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Transit responses
// ─────────────────────────────────────────────────────────────────────────────

/// Metadata for a named transit encryption key.
@JsonSerializable()
class TransitKeyResponse {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the owning team.
  final String teamId;

  /// Unique key name within the team.
  final String name;

  /// Optional description.
  final String? description;

  /// Current key version number.
  final int currentVersion;

  /// Minimum key version allowed for decryption.
  final int minDecryptionVersion;

  /// Encryption algorithm (e.g., "AES-256-GCM").
  final String algorithm;

  /// Whether this key can be deleted.
  final bool isDeletable;

  /// Whether key material can be exported.
  final bool isExportable;

  /// Whether this key is active.
  final bool isActive;

  /// UUID of the user who created this key.
  final String? createdByUserId;

  /// Timestamp when the key was created.
  final DateTime? createdAt;

  /// Timestamp when the key was last updated.
  final DateTime? updatedAt;

  /// Creates a [TransitKeyResponse] instance.
  const TransitKeyResponse({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    required this.currentVersion,
    required this.minDecryptionVersion,
    required this.algorithm,
    required this.isDeletable,
    required this.isExportable,
    required this.isActive,
    this.createdByUserId,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [TransitKeyResponse] from a JSON map.
  factory TransitKeyResponse.fromJson(Map<String, dynamic> json) =>
      _$TransitKeyResponseFromJson(json);

  /// Serializes this [TransitKeyResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$TransitKeyResponseToJson(this);
}

/// Result of a transit encryption operation.
@JsonSerializable()
class TransitEncryptResponse {
  /// Name of the key used.
  final String keyName;

  /// Key version used for encryption.
  final int keyVersion;

  /// The encrypted ciphertext.
  final String ciphertext;

  /// Creates a [TransitEncryptResponse] instance.
  const TransitEncryptResponse({
    required this.keyName,
    required this.keyVersion,
    required this.ciphertext,
  });

  /// Deserializes a [TransitEncryptResponse] from a JSON map.
  factory TransitEncryptResponse.fromJson(Map<String, dynamic> json) =>
      _$TransitEncryptResponseFromJson(json);

  /// Serializes this [TransitEncryptResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$TransitEncryptResponseToJson(this);
}

/// Result of a transit decryption operation.
@JsonSerializable()
class TransitDecryptResponse {
  /// Name of the key used.
  final String keyName;

  /// The decrypted plaintext (Base64-encoded).
  final String plaintext;

  /// Creates a [TransitDecryptResponse] instance.
  const TransitDecryptResponse({
    required this.keyName,
    required this.plaintext,
  });

  /// Deserializes a [TransitDecryptResponse] from a JSON map.
  factory TransitDecryptResponse.fromJson(Map<String, dynamic> json) =>
      _$TransitDecryptResponseFromJson(json);

  /// Serializes this [TransitDecryptResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$TransitDecryptResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic Secrets responses
// ─────────────────────────────────────────────────────────────────────────────

/// A dynamic secret lease with temporary credentials.
@JsonSerializable()
class DynamicLeaseResponse {
  /// Unique identifier (UUID).
  final String id;

  /// Unique lease identifier string.
  final String leaseId;

  /// UUID of the parent dynamic secret.
  final String secretId;

  /// Path of the parent dynamic secret.
  final String? secretPath;

  /// Backend type (e.g., "postgresql").
  final String? backendType;

  /// Lifecycle status of the lease.
  @LeaseStatusConverter()
  final LeaseStatus status;

  /// Lease duration in seconds.
  final int ttlSeconds;

  /// Timestamp when the lease expires.
  final DateTime? expiresAt;

  /// Timestamp when the lease was revoked (if revoked).
  final DateTime? revokedAt;

  /// UUID of the user who requested this lease.
  final String? requestedByUserId;

  /// Connection details (only included on creation).
  final Map<String, dynamic>? connectionDetails;

  /// Timestamp when the lease was created.
  final DateTime? createdAt;

  /// Creates a [DynamicLeaseResponse] instance.
  const DynamicLeaseResponse({
    required this.id,
    required this.leaseId,
    required this.secretId,
    this.secretPath,
    this.backendType,
    required this.status,
    required this.ttlSeconds,
    this.expiresAt,
    this.revokedAt,
    this.requestedByUserId,
    this.connectionDetails,
    this.createdAt,
  });

  /// Deserializes a [DynamicLeaseResponse] from a JSON map.
  factory DynamicLeaseResponse.fromJson(Map<String, dynamic> json) =>
      _$DynamicLeaseResponseFromJson(json);

  /// Serializes this [DynamicLeaseResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$DynamicLeaseResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Seal responses
// ─────────────────────────────────────────────────────────────────────────────

/// Current seal status of the Vault.
@JsonSerializable()
class SealStatusResponse {
  /// Current seal state.
  @SealStatusConverter()
  final SealStatus status;

  /// Total number of Shamir key shares.
  final int totalShares;

  /// Number of shares required to unseal.
  final int threshold;

  /// Number of shares submitted so far.
  final int sharesProvided;

  /// Whether auto-unseal is enabled.
  final bool autoUnsealEnabled;

  /// Timestamp when the vault was last sealed.
  final DateTime? sealedAt;

  /// Timestamp when the vault was last unsealed.
  final DateTime? unsealedAt;

  /// Creates a [SealStatusResponse] instance.
  const SealStatusResponse({
    required this.status,
    required this.totalShares,
    required this.threshold,
    required this.sharesProvided,
    required this.autoUnsealEnabled,
    this.sealedAt,
    this.unsealedAt,
  });

  /// Deserializes a [SealStatusResponse] from a JSON map.
  factory SealStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$SealStatusResponseFromJson(json);

  /// Serializes this [SealStatusResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$SealStatusResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Audit responses
// ─────────────────────────────────────────────────────────────────────────────

/// A single entry in the Vault audit log.
@JsonSerializable()
class AuditEntryResponse {
  /// Unique identifier (auto-increment).
  final int id;

  /// UUID of the team context.
  final String? teamId;

  /// UUID of the user who performed the action.
  final String? userId;

  /// Operation name (e.g., "WRITE", "READ", "DELETE").
  final String operation;

  /// Secret path involved.
  final String? path;

  /// Type of resource affected.
  final String? resourceType;

  /// UUID of the affected resource.
  final String? resourceId;

  /// Whether the operation succeeded.
  final bool success;

  /// Error message if the operation failed.
  final String? errorMessage;

  /// IP address of the requester.
  final String? ipAddress;

  /// Correlation ID for request tracing.
  final String? correlationId;

  /// Timestamp when the entry was recorded.
  final DateTime? createdAt;

  /// Creates an [AuditEntryResponse] instance.
  const AuditEntryResponse({
    required this.id,
    this.teamId,
    this.userId,
    required this.operation,
    this.path,
    this.resourceType,
    this.resourceId,
    required this.success,
    this.errorMessage,
    this.ipAddress,
    this.correlationId,
    this.createdAt,
  });

  /// Deserializes an [AuditEntryResponse] from a JSON map.
  factory AuditEntryResponse.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryResponseFromJson(json);

  /// Serializes this [AuditEntryResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$AuditEntryResponseToJson(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal converters
// ─────────────────────────────────────────────────────────────────────────────

/// Converts a JSON list of permission strings to [List<PolicyPermission>].
class _PolicyPermissionListConverter
    extends JsonConverter<List<PolicyPermission>, List<dynamic>> {
  const _PolicyPermissionListConverter();

  @override
  List<PolicyPermission> fromJson(List<dynamic> json) =>
      json.map((e) => PolicyPermission.fromJson(e as String)).toList();

  @override
  List<dynamic> toJson(List<PolicyPermission> object) =>
      object.map((e) => e.toJson()).toList();
}
