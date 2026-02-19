// Tests for all 14 Vault response model classes.
//
// Verifies fromJson with all fields, fromJson with null optionals,
// and toJson round-trip for each model.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // SecretResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('SecretResponse', () {
    final fullJson = {
      'id': 'secret-1',
      'teamId': 'team-1',
      'path': '/services/app/db-password',
      'name': 'DB Password',
      'description': 'Database password',
      'secretType': 'STATIC',
      'currentVersion': 3,
      'maxVersions': 10,
      'retentionDays': 90,
      'expiresAt': '2026-12-31T23:59:59.000Z',
      'lastAccessedAt': '2026-02-18T10:00:00.000Z',
      'lastRotatedAt': '2026-02-01T08:00:00.000Z',
      'ownerUserId': 'user-1',
      'referenceArn': null,
      'isActive': true,
      'metadata': {'env': 'production'},
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-02-18T10:00:00.000Z',
    };

    test('fromJson with all fields', () {
      final m = SecretResponse.fromJson(fullJson);
      expect(m.id, 'secret-1');
      expect(m.teamId, 'team-1');
      expect(m.path, '/services/app/db-password');
      expect(m.name, 'DB Password');
      expect(m.description, 'Database password');
      expect(m.secretType.toJson(), 'STATIC');
      expect(m.currentVersion, 3);
      expect(m.maxVersions, 10);
      expect(m.retentionDays, 90);
      expect(m.expiresAt, isNotNull);
      expect(m.isActive, true);
      expect(m.metadata, {'env': 'production'});
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 'secret-1',
        'teamId': 'team-1',
        'path': '/test',
        'name': 'Test',
        'secretType': 'DYNAMIC',
        'currentVersion': 1,
        'isActive': true,
      };
      final m = SecretResponse.fromJson(json);
      expect(m.description, isNull);
      expect(m.maxVersions, isNull);
      expect(m.retentionDays, isNull);
      expect(m.expiresAt, isNull);
      expect(m.metadata, isNull);
    });

    test('toJson round-trip', () {
      final m = SecretResponse.fromJson(fullJson);
      final json = m.toJson();
      final restored = SecretResponse.fromJson(json);
      expect(restored.id, m.id);
      expect(restored.name, m.name);
      expect(restored.secretType, m.secretType);
      expect(restored.currentVersion, m.currentVersion);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SecretValueResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('SecretValueResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'secretId': 'secret-1',
        'path': '/test',
        'name': 'Test',
        'versionNumber': 2,
        'value': 'super-secret-value',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };
      final m = SecretValueResponse.fromJson(json);
      expect(m.secretId, 'secret-1');
      expect(m.value, 'super-secret-value');
      expect(m.versionNumber, 2);
      expect(m.createdAt, isNotNull);
    });

    test('toJson round-trip', () {
      final m = SecretValueResponse(
        secretId: 'secret-1',
        path: '/test',
        name: 'Test',
        versionNumber: 1,
        value: 'value',
      );
      final restored = SecretValueResponse.fromJson(m.toJson());
      expect(restored.secretId, m.secretId);
      expect(restored.value, m.value);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SecretVersionResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('SecretVersionResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'ver-1',
        'secretId': 'secret-1',
        'versionNumber': 3,
        'encryptionKeyId': 'master-v1',
        'changeDescription': 'Rotated password',
        'createdByUserId': 'user-1',
        'isDestroyed': false,
        'createdAt': '2026-02-01T00:00:00.000Z',
      };
      final m = SecretVersionResponse.fromJson(json);
      expect(m.id, 'ver-1');
      expect(m.versionNumber, 3);
      expect(m.encryptionKeyId, 'master-v1');
      expect(m.isDestroyed, false);
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 'ver-1',
        'secretId': 'secret-1',
        'versionNumber': 1,
        'isDestroyed': false,
      };
      final m = SecretVersionResponse.fromJson(json);
      expect(m.encryptionKeyId, isNull);
      expect(m.changeDescription, isNull);
      expect(m.createdByUserId, isNull);
    });

    test('toJson round-trip', () {
      final m = SecretVersionResponse(
        id: 'ver-1',
        secretId: 'secret-1',
        versionNumber: 1,
        isDestroyed: false,
      );
      final restored = SecretVersionResponse.fromJson(m.toJson());
      expect(restored.versionNumber, 1);
      expect(restored.isDestroyed, false);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AccessPolicyResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('AccessPolicyResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'policy-1',
        'teamId': 'team-1',
        'name': 'read-all',
        'description': 'Read access to all secrets',
        'pathPattern': '/*',
        'permissions': ['READ', 'LIST'],
        'isDenyPolicy': false,
        'isActive': true,
        'createdByUserId': 'user-1',
        'bindingCount': 5,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-02-01T00:00:00.000Z',
      };
      final m = AccessPolicyResponse.fromJson(json);
      expect(m.name, 'read-all');
      expect(m.permissions, hasLength(2));
      expect(m.permissions.first.toJson(), 'READ');
      expect(m.isDenyPolicy, false);
      expect(m.bindingCount, 5);
    });

    test('toJson round-trip', () {
      final json = {
        'id': 'policy-1',
        'teamId': 'team-1',
        'name': 'admin',
        'pathPattern': '/admin/*',
        'permissions': ['READ', 'WRITE', 'DELETE'],
        'isDenyPolicy': false,
        'isActive': true,
        'bindingCount': 0,
      };
      final m = AccessPolicyResponse.fromJson(json);
      final restored = AccessPolicyResponse.fromJson(m.toJson());
      expect(restored.name, m.name);
      expect(restored.permissions, hasLength(3));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PolicyBindingResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('PolicyBindingResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'binding-1',
        'policyId': 'policy-1',
        'policyName': 'read-all',
        'bindingType': 'USER',
        'bindingTargetId': 'user-1',
        'createdByUserId': 'admin-1',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };
      final m = PolicyBindingResponse.fromJson(json);
      expect(m.policyName, 'read-all');
      expect(m.bindingType.toJson(), 'USER');
      expect(m.bindingTargetId, 'user-1');
    });

    test('toJson round-trip', () {
      final m = PolicyBindingResponse(
        id: 'binding-1',
        policyId: 'policy-1',
        bindingType: BindingType.team,
        bindingTargetId: 'team-1',
      );
      final restored = PolicyBindingResponse.fromJson(m.toJson());
      expect(restored.bindingType.toJson(), 'TEAM');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AccessDecision
  // ─────────────────────────────────────────────────────────────────────────

  group('AccessDecision', () {
    test('fromJson allowed decision', () {
      final json = {
        'allowed': true,
        'reason': 'Matched policy: read-all',
        'decidingPolicyId': 'policy-1',
        'decidingPolicyName': 'read-all',
      };
      final m = AccessDecision.fromJson(json);
      expect(m.allowed, true);
      expect(m.decidingPolicyName, 'read-all');
    });

    test('fromJson denied decision', () {
      final json = {
        'allowed': false,
        'reason': 'No matching policy found',
      };
      final m = AccessDecision.fromJson(json);
      expect(m.allowed, false);
      expect(m.decidingPolicyId, isNull);
    });

    test('toJson round-trip', () {
      final m = AccessDecision(allowed: true, reason: 'test');
      final restored = AccessDecision.fromJson(m.toJson());
      expect(restored.allowed, true);
      expect(restored.reason, 'test');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RotationPolicyResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('RotationPolicyResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'rp-1',
        'secretId': 'secret-1',
        'secretPath': '/test',
        'strategy': 'RANDOM_GENERATE',
        'rotationIntervalHours': 24,
        'randomLength': 32,
        'randomCharset': 'alphanumeric',
        'externalApiUrl': null,
        'isActive': true,
        'failureCount': 0,
        'maxFailures': 5,
        'lastRotatedAt': '2026-02-17T00:00:00.000Z',
        'nextRotationAt': '2026-02-18T00:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-02-17T00:00:00.000Z',
      };
      final m = RotationPolicyResponse.fromJson(json);
      expect(m.strategy.toJson(), 'RANDOM_GENERATE');
      expect(m.rotationIntervalHours, 24);
      expect(m.randomLength, 32);
      expect(m.failureCount, 0);
    });

    test('toJson round-trip', () {
      final m = RotationPolicyResponse(
        id: 'rp-1',
        secretId: 'secret-1',
        strategy: RotationStrategy.externalApi,
        rotationIntervalHours: 12,
        isActive: true,
        failureCount: 2,
      );
      final restored = RotationPolicyResponse.fromJson(m.toJson());
      expect(restored.strategy.toJson(), 'EXTERNAL_API');
      expect(restored.failureCount, 2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RotationHistoryResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('RotationHistoryResponse', () {
    test('fromJson successful rotation', () {
      final json = {
        'id': 'rh-1',
        'secretId': 'secret-1',
        'secretPath': '/test',
        'strategy': 'RANDOM_GENERATE',
        'previousVersion': 2,
        'newVersion': 3,
        'success': true,
        'durationMs': 150,
        'triggeredByUserId': 'user-1',
        'createdAt': '2026-02-18T00:00:00.000Z',
      };
      final m = RotationHistoryResponse.fromJson(json);
      expect(m.success, true);
      expect(m.newVersion, 3);
      expect(m.errorMessage, isNull);
    });

    test('fromJson failed rotation', () {
      final json = {
        'id': 'rh-2',
        'secretId': 'secret-1',
        'strategy': 'EXTERNAL_API',
        'previousVersion': 2,
        'success': false,
        'errorMessage': 'Connection refused',
        'durationMs': 5000,
        'createdAt': '2026-02-18T00:00:00.000Z',
      };
      final m = RotationHistoryResponse.fromJson(json);
      expect(m.success, false);
      expect(m.newVersion, isNull);
      expect(m.errorMessage, 'Connection refused');
    });

    test('toJson round-trip', () {
      final m = RotationHistoryResponse(
        id: 'rh-1',
        secretId: 'secret-1',
        strategy: RotationStrategy.randomGenerate,
        success: true,
      );
      final restored = RotationHistoryResponse.fromJson(m.toJson());
      expect(restored.success, true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TransitKeyResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('TransitKeyResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'tk-1',
        'teamId': 'team-1',
        'name': 'app-encryption-key',
        'description': 'Main app key',
        'currentVersion': 3,
        'minDecryptionVersion': 2,
        'algorithm': 'AES-256-GCM',
        'isDeletable': false,
        'isExportable': false,
        'isActive': true,
        'createdByUserId': 'user-1',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-02-18T00:00:00.000Z',
      };
      final m = TransitKeyResponse.fromJson(json);
      expect(m.name, 'app-encryption-key');
      expect(m.currentVersion, 3);
      expect(m.algorithm, 'AES-256-GCM');
      expect(m.isDeletable, false);
    });

    test('toJson round-trip', () {
      final m = TransitKeyResponse(
        id: 'tk-1',
        teamId: 'team-1',
        name: 'test-key',
        currentVersion: 1,
        minDecryptionVersion: 1,
        algorithm: 'AES-256-GCM',
        isDeletable: true,
        isExportable: false,
        isActive: true,
      );
      final restored = TransitKeyResponse.fromJson(m.toJson());
      expect(restored.name, 'test-key');
      expect(restored.isDeletable, true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TransitEncryptResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('TransitEncryptResponse', () {
    test('fromJson', () {
      final json = {
        'keyName': 'app-key',
        'keyVersion': 2,
        'ciphertext': 'encrypted-data-base64',
      };
      final m = TransitEncryptResponse.fromJson(json);
      expect(m.keyName, 'app-key');
      expect(m.keyVersion, 2);
      expect(m.ciphertext, 'encrypted-data-base64');
    });

    test('toJson round-trip', () {
      final m = TransitEncryptResponse(
        keyName: 'key',
        keyVersion: 1,
        ciphertext: 'ct',
      );
      final restored = TransitEncryptResponse.fromJson(m.toJson());
      expect(restored.ciphertext, 'ct');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // TransitDecryptResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('TransitDecryptResponse', () {
    test('fromJson', () {
      final json = {
        'keyName': 'app-key',
        'plaintext': 'decrypted-base64',
      };
      final m = TransitDecryptResponse.fromJson(json);
      expect(m.keyName, 'app-key');
      expect(m.plaintext, 'decrypted-base64');
    });

    test('toJson round-trip', () {
      final m = TransitDecryptResponse(keyName: 'key', plaintext: 'pt');
      final restored = TransitDecryptResponse.fromJson(m.toJson());
      expect(restored.plaintext, 'pt');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // DynamicLeaseResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('DynamicLeaseResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'dl-1',
        'leaseId': 'v_myapp_abc12345',
        'secretId': 'secret-1',
        'secretPath': '/dynamic/db',
        'backendType': 'postgresql',
        'status': 'ACTIVE',
        'ttlSeconds': 3600,
        'expiresAt': '2026-02-18T19:00:00.000Z',
        'revokedAt': null,
        'requestedByUserId': 'user-1',
        'connectionDetails': {
          'host': 'localhost',
          'port': 5432,
          'username': 'v_myapp_abc12345',
        },
        'createdAt': '2026-02-18T18:00:00.000Z',
      };
      final m = DynamicLeaseResponse.fromJson(json);
      expect(m.leaseId, 'v_myapp_abc12345');
      expect(m.status.toJson(), 'ACTIVE');
      expect(m.ttlSeconds, 3600);
      expect(m.connectionDetails, isNotNull);
      expect(m.connectionDetails!['host'], 'localhost');
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 'dl-1',
        'leaseId': 'v_myapp_abc',
        'secretId': 'secret-1',
        'status': 'EXPIRED',
        'ttlSeconds': 3600,
      };
      final m = DynamicLeaseResponse.fromJson(json);
      expect(m.connectionDetails, isNull);
      expect(m.revokedAt, isNull);
      expect(m.secretPath, isNull);
    });

    test('toJson round-trip', () {
      final m = DynamicLeaseResponse(
        id: 'dl-1',
        leaseId: 'lease-1',
        secretId: 'secret-1',
        status: LeaseStatus.revoked,
        ttlSeconds: 300,
      );
      final restored = DynamicLeaseResponse.fromJson(m.toJson());
      expect(restored.status.toJson(), 'REVOKED');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SealStatusResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('SealStatusResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'status': 'UNSEALED',
        'totalShares': 5,
        'threshold': 3,
        'sharesProvided': 3,
        'autoUnsealEnabled': true,
        'sealedAt': null,
        'unsealedAt': '2026-02-18T00:00:00.000Z',
      };
      final m = SealStatusResponse.fromJson(json);
      expect(m.status.toJson(), 'UNSEALED');
      expect(m.totalShares, 5);
      expect(m.threshold, 3);
      expect(m.autoUnsealEnabled, true);
    });

    test('fromJson sealed status', () {
      final json = {
        'status': 'SEALED',
        'totalShares': 5,
        'threshold': 3,
        'sharesProvided': 0,
        'autoUnsealEnabled': false,
        'sealedAt': '2026-02-18T00:00:00.000Z',
      };
      final m = SealStatusResponse.fromJson(json);
      expect(m.status.toJson(), 'SEALED');
      expect(m.sharesProvided, 0);
    });

    test('toJson round-trip', () {
      final m = SealStatusResponse(
        status: SealStatus.unsealing,
        totalShares: 5,
        threshold: 3,
        sharesProvided: 2,
        autoUnsealEnabled: false,
      );
      final restored = SealStatusResponse.fromJson(m.toJson());
      expect(restored.status.toJson(), 'UNSEALING');
      expect(restored.sharesProvided, 2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AuditEntryResponse
  // ─────────────────────────────────────────────────────────────────────────

  group('AuditEntryResponse', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 42,
        'teamId': 'team-1',
        'userId': 'user-1',
        'operation': 'WRITE',
        'path': '/secrets/db-password',
        'resourceType': 'SECRET',
        'resourceId': 'secret-1',
        'success': true,
        'errorMessage': null,
        'ipAddress': '127.0.0.1',
        'correlationId': 'abc12345',
        'createdAt': '2026-02-18T00:00:00.000Z',
      };
      final m = AuditEntryResponse.fromJson(json);
      expect(m.id, 42);
      expect(m.operation, 'WRITE');
      expect(m.success, true);
      expect(m.ipAddress, '127.0.0.1');
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 1,
        'operation': 'READ',
        'success': true,
      };
      final m = AuditEntryResponse.fromJson(json);
      expect(m.teamId, isNull);
      expect(m.userId, isNull);
      expect(m.path, isNull);
      expect(m.errorMessage, isNull);
    });

    test('toJson round-trip', () {
      final m = AuditEntryResponse(
        id: 1,
        operation: 'DELETE',
        success: false,
        errorMessage: 'Not found',
      );
      final restored = AuditEntryResponse.fromJson(m.toJson());
      expect(restored.operation, 'DELETE');
      expect(restored.success, false);
      expect(restored.errorMessage, 'Not found');
    });
  });
}
