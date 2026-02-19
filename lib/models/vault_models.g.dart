// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretResponse _$SecretResponseFromJson(Map<String, dynamic> json) =>
    SecretResponse(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      secretType:
          const SecretTypeConverter().fromJson(json['secretType'] as String),
      currentVersion: (json['currentVersion'] as num).toInt(),
      maxVersions: (json['maxVersions'] as num?)?.toInt(),
      retentionDays: (json['retentionDays'] as num?)?.toInt(),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] == null
          ? null
          : DateTime.parse(json['lastAccessedAt'] as String),
      lastRotatedAt: json['lastRotatedAt'] == null
          ? null
          : DateTime.parse(json['lastRotatedAt'] as String),
      ownerUserId: json['ownerUserId'] as String?,
      referenceArn: json['referenceArn'] as String?,
      isActive: json['isActive'] as bool,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SecretResponseToJson(SecretResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'path': instance.path,
      'name': instance.name,
      'description': instance.description,
      'secretType': const SecretTypeConverter().toJson(instance.secretType),
      'currentVersion': instance.currentVersion,
      'maxVersions': instance.maxVersions,
      'retentionDays': instance.retentionDays,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'lastAccessedAt': instance.lastAccessedAt?.toIso8601String(),
      'lastRotatedAt': instance.lastRotatedAt?.toIso8601String(),
      'ownerUserId': instance.ownerUserId,
      'referenceArn': instance.referenceArn,
      'isActive': instance.isActive,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

SecretValueResponse _$SecretValueResponseFromJson(Map<String, dynamic> json) =>
    SecretValueResponse(
      secretId: json['secretId'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      versionNumber: (json['versionNumber'] as num).toInt(),
      value: json['value'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SecretValueResponseToJson(
        SecretValueResponse instance) =>
    <String, dynamic>{
      'secretId': instance.secretId,
      'path': instance.path,
      'name': instance.name,
      'versionNumber': instance.versionNumber,
      'value': instance.value,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

SecretVersionResponse _$SecretVersionResponseFromJson(
        Map<String, dynamic> json) =>
    SecretVersionResponse(
      id: json['id'] as String,
      secretId: json['secretId'] as String,
      versionNumber: (json['versionNumber'] as num).toInt(),
      encryptionKeyId: json['encryptionKeyId'] as String?,
      changeDescription: json['changeDescription'] as String?,
      createdByUserId: json['createdByUserId'] as String?,
      isDestroyed: json['isDestroyed'] as bool,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SecretVersionResponseToJson(
        SecretVersionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'secretId': instance.secretId,
      'versionNumber': instance.versionNumber,
      'encryptionKeyId': instance.encryptionKeyId,
      'changeDescription': instance.changeDescription,
      'createdByUserId': instance.createdByUserId,
      'isDestroyed': instance.isDestroyed,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

AccessPolicyResponse _$AccessPolicyResponseFromJson(
        Map<String, dynamic> json) =>
    AccessPolicyResponse(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      pathPattern: json['pathPattern'] as String,
      permissions: const _PolicyPermissionListConverter()
          .fromJson(json['permissions'] as List),
      isDenyPolicy: json['isDenyPolicy'] as bool,
      isActive: json['isActive'] as bool,
      createdByUserId: json['createdByUserId'] as String?,
      bindingCount: (json['bindingCount'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AccessPolicyResponseToJson(
        AccessPolicyResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'name': instance.name,
      'description': instance.description,
      'pathPattern': instance.pathPattern,
      'permissions':
          const _PolicyPermissionListConverter().toJson(instance.permissions),
      'isDenyPolicy': instance.isDenyPolicy,
      'isActive': instance.isActive,
      'createdByUserId': instance.createdByUserId,
      'bindingCount': instance.bindingCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

PolicyBindingResponse _$PolicyBindingResponseFromJson(
        Map<String, dynamic> json) =>
    PolicyBindingResponse(
      id: json['id'] as String,
      policyId: json['policyId'] as String,
      policyName: json['policyName'] as String?,
      bindingType:
          const BindingTypeConverter().fromJson(json['bindingType'] as String),
      bindingTargetId: json['bindingTargetId'] as String,
      createdByUserId: json['createdByUserId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PolicyBindingResponseToJson(
        PolicyBindingResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'policyId': instance.policyId,
      'policyName': instance.policyName,
      'bindingType': const BindingTypeConverter().toJson(instance.bindingType),
      'bindingTargetId': instance.bindingTargetId,
      'createdByUserId': instance.createdByUserId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

AccessDecision _$AccessDecisionFromJson(Map<String, dynamic> json) =>
    AccessDecision(
      allowed: json['allowed'] as bool,
      reason: json['reason'] as String?,
      decidingPolicyId: json['decidingPolicyId'] as String?,
      decidingPolicyName: json['decidingPolicyName'] as String?,
    );

Map<String, dynamic> _$AccessDecisionToJson(AccessDecision instance) =>
    <String, dynamic>{
      'allowed': instance.allowed,
      'reason': instance.reason,
      'decidingPolicyId': instance.decidingPolicyId,
      'decidingPolicyName': instance.decidingPolicyName,
    };

RotationPolicyResponse _$RotationPolicyResponseFromJson(
        Map<String, dynamic> json) =>
    RotationPolicyResponse(
      id: json['id'] as String,
      secretId: json['secretId'] as String,
      secretPath: json['secretPath'] as String?,
      strategy: const RotationStrategyConverter()
          .fromJson(json['strategy'] as String),
      rotationIntervalHours: (json['rotationIntervalHours'] as num).toInt(),
      randomLength: (json['randomLength'] as num?)?.toInt(),
      randomCharset: json['randomCharset'] as String?,
      externalApiUrl: json['externalApiUrl'] as String?,
      isActive: json['isActive'] as bool,
      failureCount: (json['failureCount'] as num).toInt(),
      maxFailures: (json['maxFailures'] as num?)?.toInt(),
      lastRotatedAt: json['lastRotatedAt'] == null
          ? null
          : DateTime.parse(json['lastRotatedAt'] as String),
      nextRotationAt: json['nextRotationAt'] == null
          ? null
          : DateTime.parse(json['nextRotationAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RotationPolicyResponseToJson(
        RotationPolicyResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'secretId': instance.secretId,
      'secretPath': instance.secretPath,
      'strategy': const RotationStrategyConverter().toJson(instance.strategy),
      'rotationIntervalHours': instance.rotationIntervalHours,
      'randomLength': instance.randomLength,
      'randomCharset': instance.randomCharset,
      'externalApiUrl': instance.externalApiUrl,
      'isActive': instance.isActive,
      'failureCount': instance.failureCount,
      'maxFailures': instance.maxFailures,
      'lastRotatedAt': instance.lastRotatedAt?.toIso8601String(),
      'nextRotationAt': instance.nextRotationAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

RotationHistoryResponse _$RotationHistoryResponseFromJson(
        Map<String, dynamic> json) =>
    RotationHistoryResponse(
      id: json['id'] as String,
      secretId: json['secretId'] as String,
      secretPath: json['secretPath'] as String?,
      strategy: const RotationStrategyConverter()
          .fromJson(json['strategy'] as String),
      previousVersion: (json['previousVersion'] as num?)?.toInt(),
      newVersion: (json['newVersion'] as num?)?.toInt(),
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      triggeredByUserId: json['triggeredByUserId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$RotationHistoryResponseToJson(
        RotationHistoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'secretId': instance.secretId,
      'secretPath': instance.secretPath,
      'strategy': const RotationStrategyConverter().toJson(instance.strategy),
      'previousVersion': instance.previousVersion,
      'newVersion': instance.newVersion,
      'success': instance.success,
      'errorMessage': instance.errorMessage,
      'durationMs': instance.durationMs,
      'triggeredByUserId': instance.triggeredByUserId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

TransitKeyResponse _$TransitKeyResponseFromJson(Map<String, dynamic> json) =>
    TransitKeyResponse(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      currentVersion: (json['currentVersion'] as num).toInt(),
      minDecryptionVersion: (json['minDecryptionVersion'] as num).toInt(),
      algorithm: json['algorithm'] as String,
      isDeletable: json['isDeletable'] as bool,
      isExportable: json['isExportable'] as bool,
      isActive: json['isActive'] as bool,
      createdByUserId: json['createdByUserId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TransitKeyResponseToJson(TransitKeyResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'name': instance.name,
      'description': instance.description,
      'currentVersion': instance.currentVersion,
      'minDecryptionVersion': instance.minDecryptionVersion,
      'algorithm': instance.algorithm,
      'isDeletable': instance.isDeletable,
      'isExportable': instance.isExportable,
      'isActive': instance.isActive,
      'createdByUserId': instance.createdByUserId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

TransitEncryptResponse _$TransitEncryptResponseFromJson(
        Map<String, dynamic> json) =>
    TransitEncryptResponse(
      keyName: json['keyName'] as String,
      keyVersion: (json['keyVersion'] as num).toInt(),
      ciphertext: json['ciphertext'] as String,
    );

Map<String, dynamic> _$TransitEncryptResponseToJson(
        TransitEncryptResponse instance) =>
    <String, dynamic>{
      'keyName': instance.keyName,
      'keyVersion': instance.keyVersion,
      'ciphertext': instance.ciphertext,
    };

TransitDecryptResponse _$TransitDecryptResponseFromJson(
        Map<String, dynamic> json) =>
    TransitDecryptResponse(
      keyName: json['keyName'] as String,
      plaintext: json['plaintext'] as String,
    );

Map<String, dynamic> _$TransitDecryptResponseToJson(
        TransitDecryptResponse instance) =>
    <String, dynamic>{
      'keyName': instance.keyName,
      'plaintext': instance.plaintext,
    };

DynamicLeaseResponse _$DynamicLeaseResponseFromJson(
        Map<String, dynamic> json) =>
    DynamicLeaseResponse(
      id: json['id'] as String,
      leaseId: json['leaseId'] as String,
      secretId: json['secretId'] as String,
      secretPath: json['secretPath'] as String?,
      backendType: json['backendType'] as String?,
      status: const LeaseStatusConverter().fromJson(json['status'] as String),
      ttlSeconds: (json['ttlSeconds'] as num).toInt(),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      revokedAt: json['revokedAt'] == null
          ? null
          : DateTime.parse(json['revokedAt'] as String),
      requestedByUserId: json['requestedByUserId'] as String?,
      connectionDetails: json['connectionDetails'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DynamicLeaseResponseToJson(
        DynamicLeaseResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'leaseId': instance.leaseId,
      'secretId': instance.secretId,
      'secretPath': instance.secretPath,
      'backendType': instance.backendType,
      'status': const LeaseStatusConverter().toJson(instance.status),
      'ttlSeconds': instance.ttlSeconds,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'revokedAt': instance.revokedAt?.toIso8601String(),
      'requestedByUserId': instance.requestedByUserId,
      'connectionDetails': instance.connectionDetails,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

SealStatusResponse _$SealStatusResponseFromJson(Map<String, dynamic> json) =>
    SealStatusResponse(
      status: const SealStatusConverter().fromJson(json['status'] as String),
      totalShares: (json['totalShares'] as num).toInt(),
      threshold: (json['threshold'] as num).toInt(),
      sharesProvided: (json['sharesProvided'] as num).toInt(),
      autoUnsealEnabled: json['autoUnsealEnabled'] as bool,
      sealedAt: json['sealedAt'] == null
          ? null
          : DateTime.parse(json['sealedAt'] as String),
      unsealedAt: json['unsealedAt'] == null
          ? null
          : DateTime.parse(json['unsealedAt'] as String),
    );

Map<String, dynamic> _$SealStatusResponseToJson(SealStatusResponse instance) =>
    <String, dynamic>{
      'status': const SealStatusConverter().toJson(instance.status),
      'totalShares': instance.totalShares,
      'threshold': instance.threshold,
      'sharesProvided': instance.sharesProvided,
      'autoUnsealEnabled': instance.autoUnsealEnabled,
      'sealedAt': instance.sealedAt?.toIso8601String(),
      'unsealedAt': instance.unsealedAt?.toIso8601String(),
    };

AuditEntryResponse _$AuditEntryResponseFromJson(Map<String, dynamic> json) =>
    AuditEntryResponse(
      id: (json['id'] as num).toInt(),
      teamId: json['teamId'] as String?,
      userId: json['userId'] as String?,
      operation: json['operation'] as String,
      path: json['path'] as String?,
      resourceType: json['resourceType'] as String?,
      resourceId: json['resourceId'] as String?,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      ipAddress: json['ipAddress'] as String?,
      correlationId: json['correlationId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AuditEntryResponseToJson(AuditEntryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'userId': instance.userId,
      'operation': instance.operation,
      'path': instance.path,
      'resourceType': instance.resourceType,
      'resourceId': instance.resourceId,
      'success': instance.success,
      'errorMessage': instance.errorMessage,
      'ipAddress': instance.ipAddress,
      'correlationId': instance.correlationId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
