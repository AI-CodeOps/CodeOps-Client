/// Vault-specific enum types.
///
/// Mirrors the Java enum definitions in CodeOps-Vault exactly.
/// Each enum provides JSON serialization (SCREAMING_SNAKE_CASE),
/// deserialization, a human-readable [displayName], and a
/// companion [JsonConverter] for use with json_serializable.
library;

import 'package:json_annotation/json_annotation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SecretType
// ─────────────────────────────────────────────────────────────────────────────

/// The storage type of a secret.
enum SecretType {
  /// A statically stored secret value.
  static_,

  /// A dynamically generated secret (e.g., database credentials).
  dynamic_,

  /// A reference to a secret stored in an external system.
  reference;

  /// Serializes this value to its JSON (SCREAMING_SNAKE_CASE) representation.
  String toJson() => switch (this) {
        SecretType.static_ => 'STATIC',
        SecretType.dynamic_ => 'DYNAMIC',
        SecretType.reference => 'REFERENCE',
      };

  /// Deserializes a JSON string to a [SecretType] value.
  static SecretType fromJson(String json) => switch (json) {
        'STATIC' => SecretType.static_,
        'DYNAMIC' => SecretType.dynamic_,
        'REFERENCE' => SecretType.reference,
        _ => throw ArgumentError('Unknown SecretType: $json'),
      };

  /// Human-readable display name.
  String get displayName => switch (this) {
        SecretType.static_ => 'Static',
        SecretType.dynamic_ => 'Dynamic',
        SecretType.reference => 'Reference',
      };
}

/// JSON converter for [SecretType].
class SecretTypeConverter extends JsonConverter<SecretType, String> {
  /// Creates a const [SecretTypeConverter].
  const SecretTypeConverter();

  @override
  SecretType fromJson(String json) => SecretType.fromJson(json);

  @override
  String toJson(SecretType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// SealStatus
// ─────────────────────────────────────────────────────────────────────────────

/// The seal state of the Vault.
enum SealStatus {
  /// Vault is sealed — all operations blocked.
  sealed,

  /// Vault is unsealed — operations allowed.
  unsealed,

  /// Vault is in the process of being unsealed (shares submitted).
  unsealing;

  /// Serializes this value to its JSON (SCREAMING_SNAKE_CASE) representation.
  String toJson() => switch (this) {
        SealStatus.sealed => 'SEALED',
        SealStatus.unsealed => 'UNSEALED',
        SealStatus.unsealing => 'UNSEALING',
      };

  /// Deserializes a JSON string to a [SealStatus] value.
  static SealStatus fromJson(String json) => switch (json) {
        'SEALED' => SealStatus.sealed,
        'UNSEALED' => SealStatus.unsealed,
        'UNSEALING' => SealStatus.unsealing,
        _ => throw ArgumentError('Unknown SealStatus: $json'),
      };

  /// Human-readable display name.
  String get displayName => switch (this) {
        SealStatus.sealed => 'Sealed',
        SealStatus.unsealed => 'Unsealed',
        SealStatus.unsealing => 'Unsealing',
      };
}

/// JSON converter for [SealStatus].
class SealStatusConverter extends JsonConverter<SealStatus, String> {
  /// Creates a const [SealStatusConverter].
  const SealStatusConverter();

  @override
  SealStatus fromJson(String json) => SealStatus.fromJson(json);

  @override
  String toJson(SealStatus object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// PolicyPermission
// ─────────────────────────────────────────────────────────────────────────────

/// Permission type for access policies.
enum PolicyPermission {
  /// Read secret values.
  read,

  /// Create or update secrets.
  write,

  /// Delete secrets.
  delete,

  /// List secrets and paths.
  list,

  /// Rotate secrets.
  rotate;

  /// Serializes this value to its JSON (SCREAMING_SNAKE_CASE) representation.
  String toJson() => switch (this) {
        PolicyPermission.read => 'READ',
        PolicyPermission.write => 'WRITE',
        PolicyPermission.delete => 'DELETE',
        PolicyPermission.list => 'LIST',
        PolicyPermission.rotate => 'ROTATE',
      };

  /// Deserializes a JSON string to a [PolicyPermission] value.
  static PolicyPermission fromJson(String json) => switch (json) {
        'READ' => PolicyPermission.read,
        'WRITE' => PolicyPermission.write,
        'DELETE' => PolicyPermission.delete,
        'LIST' => PolicyPermission.list,
        'ROTATE' => PolicyPermission.rotate,
        _ => throw ArgumentError('Unknown PolicyPermission: $json'),
      };

  /// Human-readable display name.
  String get displayName => switch (this) {
        PolicyPermission.read => 'Read',
        PolicyPermission.write => 'Write',
        PolicyPermission.delete => 'Delete',
        PolicyPermission.list => 'List',
        PolicyPermission.rotate => 'Rotate',
      };
}

/// JSON converter for [PolicyPermission].
class PolicyPermissionConverter
    extends JsonConverter<PolicyPermission, String> {
  /// Creates a const [PolicyPermissionConverter].
  const PolicyPermissionConverter();

  @override
  PolicyPermission fromJson(String json) => PolicyPermission.fromJson(json);

  @override
  String toJson(PolicyPermission object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// BindingType
// ─────────────────────────────────────────────────────────────────────────────

/// The type of entity a policy is bound to.
enum BindingType {
  /// Bound to a specific user.
  user,

  /// Bound to an entire team.
  team,

  /// Bound to a service account.
  service;

  /// Serializes this value to its JSON (SCREAMING_SNAKE_CASE) representation.
  String toJson() => switch (this) {
        BindingType.user => 'USER',
        BindingType.team => 'TEAM',
        BindingType.service => 'SERVICE',
      };

  /// Deserializes a JSON string to a [BindingType] value.
  static BindingType fromJson(String json) => switch (json) {
        'USER' => BindingType.user,
        'TEAM' => BindingType.team,
        'SERVICE' => BindingType.service,
        _ => throw ArgumentError('Unknown BindingType: $json'),
      };

  /// Human-readable display name.
  String get displayName => switch (this) {
        BindingType.user => 'User',
        BindingType.team => 'Team',
        BindingType.service => 'Service',
      };
}

/// JSON converter for [BindingType].
class BindingTypeConverter extends JsonConverter<BindingType, String> {
  /// Creates a const [BindingTypeConverter].
  const BindingTypeConverter();

  @override
  BindingType fromJson(String json) => BindingType.fromJson(json);

  @override
  String toJson(BindingType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// RotationStrategy
// ─────────────────────────────────────────────────────────────────────────────

/// Strategy for automatic secret rotation.
enum RotationStrategy {
  /// Generate a new random value.
  randomGenerate,

  /// Fetch a new value from an external API.
  externalApi,

  /// Run a custom script to generate a new value.
  customScript;

  /// Serializes this value to its JSON (SCREAMING_SNAKE_CASE) representation.
  String toJson() => switch (this) {
        RotationStrategy.randomGenerate => 'RANDOM_GENERATE',
        RotationStrategy.externalApi => 'EXTERNAL_API',
        RotationStrategy.customScript => 'CUSTOM_SCRIPT',
      };

  /// Deserializes a JSON string to a [RotationStrategy] value.
  static RotationStrategy fromJson(String json) => switch (json) {
        'RANDOM_GENERATE' => RotationStrategy.randomGenerate,
        'EXTERNAL_API' => RotationStrategy.externalApi,
        'CUSTOM_SCRIPT' => RotationStrategy.customScript,
        _ => throw ArgumentError('Unknown RotationStrategy: $json'),
      };

  /// Human-readable display name.
  String get displayName => switch (this) {
        RotationStrategy.randomGenerate => 'Random Generate',
        RotationStrategy.externalApi => 'External API',
        RotationStrategy.customScript => 'Custom Script',
      };
}

/// JSON converter for [RotationStrategy].
class RotationStrategyConverter
    extends JsonConverter<RotationStrategy, String> {
  /// Creates a const [RotationStrategyConverter].
  const RotationStrategyConverter();

  @override
  RotationStrategy fromJson(String json) => RotationStrategy.fromJson(json);

  @override
  String toJson(RotationStrategy object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// LeaseStatus
// ─────────────────────────────────────────────────────────────────────────────

/// Lifecycle status of a dynamic secret lease.
enum LeaseStatus {
  /// Lease is currently active and credentials are valid.
  active,

  /// Lease has expired (TTL elapsed).
  expired,

  /// Lease was explicitly revoked.
  revoked;

  /// Serializes this value to its JSON (SCREAMING_SNAKE_CASE) representation.
  String toJson() => switch (this) {
        LeaseStatus.active => 'ACTIVE',
        LeaseStatus.expired => 'EXPIRED',
        LeaseStatus.revoked => 'REVOKED',
      };

  /// Deserializes a JSON string to a [LeaseStatus] value.
  static LeaseStatus fromJson(String json) => switch (json) {
        'ACTIVE' => LeaseStatus.active,
        'EXPIRED' => LeaseStatus.expired,
        'REVOKED' => LeaseStatus.revoked,
        _ => throw ArgumentError('Unknown LeaseStatus: $json'),
      };

  /// Human-readable display name.
  String get displayName => switch (this) {
        LeaseStatus.active => 'Active',
        LeaseStatus.expired => 'Expired',
        LeaseStatus.revoked => 'Revoked',
      };
}

/// JSON converter for [LeaseStatus].
class LeaseStatusConverter extends JsonConverter<LeaseStatus, String> {
  /// Creates a const [LeaseStatusConverter].
  const LeaseStatusConverter();

  @override
  LeaseStatus fromJson(String json) => LeaseStatus.fromJson(json);

  @override
  String toJson(LeaseStatus object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// Label maps
// ─────────────────────────────────────────────────────────────────────────────

/// Display labels for [SecretType] values.
const secretTypeLabels = {
  SecretType.static_: 'Static',
  SecretType.dynamic_: 'Dynamic',
  SecretType.reference: 'Reference',
};

/// Display labels for [SealStatus] values.
const sealStatusLabels = {
  SealStatus.sealed: 'Sealed',
  SealStatus.unsealed: 'Unsealed',
  SealStatus.unsealing: 'Unsealing',
};

/// Display labels for [PolicyPermission] values.
const policyPermissionLabels = {
  PolicyPermission.read: 'Read',
  PolicyPermission.write: 'Write',
  PolicyPermission.delete: 'Delete',
  PolicyPermission.list: 'List',
  PolicyPermission.rotate: 'Rotate',
};

/// Display labels for [BindingType] values.
const bindingTypeLabels = {
  BindingType.user: 'User',
  BindingType.team: 'Team',
  BindingType.service: 'Service',
};

/// Display labels for [RotationStrategy] values.
const rotationStrategyLabels = {
  RotationStrategy.randomGenerate: 'Random Generate',
  RotationStrategy.externalApi: 'External API',
  RotationStrategy.customScript: 'Custom Script',
};

/// Display labels for [LeaseStatus] values.
const leaseStatusLabels = {
  LeaseStatus.active: 'Active',
  LeaseStatus.expired: 'Expired',
  LeaseStatus.revoked: 'Revoked',
};
