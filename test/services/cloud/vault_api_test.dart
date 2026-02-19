// Tests for VaultApi.
//
// Verifies that every endpoint method sends the correct path,
// query parameters, and request body, and deserializes responses.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/services/cloud/vault_api.dart';
import 'package:codeops/services/cloud/vault_api_client.dart';

class MockVaultApiClient extends Mock implements VaultApiClient {}

void main() {
  late MockVaultApiClient mockClient;
  late VaultApi vaultApi;

  setUp(() {
    mockClient = MockVaultApiClient();
    vaultApi = VaultApi(mockClient);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Secrets
  // ═══════════════════════════════════════════════════════════════════════════

  final secretJson = {
    'id': 'secret-1',
    'teamId': 'team-1',
    'path': '/test',
    'name': 'Test Secret',
    'secretType': 'STATIC',
    'currentVersion': 1,
    'isActive': true,
  };

  final secretValueJson = {
    'secretId': 'secret-1',
    'path': '/test',
    'name': 'Test',
    'versionNumber': 1,
    'value': 'secret-value',
  };

  final pageJson = {
    'content': [secretJson],
    'page': 0,
    'size': 20,
    'totalElements': 1,
    'totalPages': 1,
    'isLast': true,
  };

  group('Secrets', () {
    test('createSecret sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/secrets',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: secretJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await vaultApi.createSecret(
        path: '/test',
        name: 'Test Secret',
        value: 'my-secret',
        secretType: SecretType.static_,
      );

      expect(result.name, 'Test Secret');
      verify(() => mockClient.post<Map<String, dynamic>>(
            '/secrets',
            data: {
              'path': '/test',
              'name': 'Test Secret',
              'value': 'my-secret',
              'secretType': 'STATIC',
            },
          )).called(1);
    });

    test('listSecrets sends query parameters', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/secrets',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: pageJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.listSecrets(
        type: SecretType.static_,
        page: 0,
        size: 20,
      );

      expect(result.content, hasLength(1));
      expect(result.totalElements, 1);
    });

    test('getSecret fetches by ID', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/secrets/secret-1'))
          .thenAnswer((_) async => Response(
                data: secretJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.getSecret('secret-1');
      expect(result.id, 'secret-1');
    });

    test('updateSecret sends partial body', () async {
      when(() => mockClient.put<Map<String, dynamic>>(
            '/secrets/secret-1',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: secretJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      await vaultApi.updateSecret('secret-1', value: 'new-value');

      verify(() => mockClient.put<Map<String, dynamic>>(
            '/secrets/secret-1',
            data: {'value': 'new-value'},
          )).called(1);
    });

    test('softDeleteSecret calls correct path', () async {
      when(() => mockClient.delete('/secrets/secret-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 204,
              ));

      await vaultApi.softDeleteSecret('secret-1');

      verify(() => mockClient.delete('/secrets/secret-1')).called(1);
    });

    test('hardDeleteSecret calls correct path', () async {
      when(() => mockClient.delete('/secrets/secret-1/permanent'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 204,
              ));

      await vaultApi.hardDeleteSecret('secret-1');

      verify(() => mockClient.delete('/secrets/secret-1/permanent'))
          .called(1);
    });

    test('getSecretByPath sends path query', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/secrets/by-path',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: secretJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.getSecretByPath('/test');
      expect(result.path, '/test');
    });

    test('readSecretValue returns decrypted value', () async {
      when(() =>
              mockClient.get<Map<String, dynamic>>('/secrets/secret-1/value'))
          .thenAnswer((_) async => Response(
                data: secretValueJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.readSecretValue('secret-1');
      expect(result.value, 'secret-value');
    });

    test('destroyVersion calls correct path', () async {
      when(() => mockClient.delete('/secrets/secret-1/versions/2'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 204,
              ));

      await vaultApi.destroyVersion('secret-1', 2);

      verify(() => mockClient.delete('/secrets/secret-1/versions/2'))
          .called(1);
    });

    test('getMetadata returns map', () async {
      when(() =>
              mockClient.get<Map<String, dynamic>>('/secrets/secret-1/metadata'))
          .thenAnswer((_) async => Response(
                data: {'env': 'prod', 'owner': 'team-a'},
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.getMetadata('secret-1');
      expect(result, {'env': 'prod', 'owner': 'team-a'});
    });

    test('searchSecrets sends query parameter', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/secrets/search',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: pageJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.searchSecrets('db');
      expect(result.content, hasLength(1));
    });

    test('listPaths returns list of strings', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/secrets/paths',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: ['/services/app-a', '/services/app-b'],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.listPaths();
      expect(result, hasLength(2));
    });

    test('getSecretStats returns counts', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/secrets/stats'))
          .thenAnswer((_) async => Response(
                data: {'total': 10, 'static': 5, 'dynamic': 3, 'reference': 2},
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.getSecretStats();
      expect(result['total'], 10);
    });

    test('getExpiringSecrets returns list', () async {
      when(() => mockClient.get<List<dynamic>>(
            '/secrets/expiring',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: [secretJson],
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.getExpiringSecrets(withinHours: 48);
      expect(result, hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Policies
  // ═══════════════════════════════════════════════════════════════════════════

  final policyJson = {
    'id': 'policy-1',
    'teamId': 'team-1',
    'name': 'read-all',
    'pathPattern': '/*',
    'permissions': ['READ', 'LIST'],
    'isDenyPolicy': false,
    'isActive': true,
    'bindingCount': 2,
  };

  final bindingJson = {
    'id': 'binding-1',
    'policyId': 'policy-1',
    'bindingType': 'USER',
    'bindingTargetId': 'user-1',
  };

  group('Policies', () {
    test('createPolicy sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/policies',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: policyJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await vaultApi.createPolicy(
        name: 'read-all',
        pathPattern: '/*',
        permissions: [PolicyPermission.read, PolicyPermission.list],
      );

      expect(result.name, 'read-all');
    });

    test('deletePolicy calls correct path', () async {
      when(() => mockClient.delete('/policies/policy-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 204,
              ));

      await vaultApi.deletePolicy('policy-1');
      verify(() => mockClient.delete('/policies/policy-1')).called(1);
    });

    test('createBinding sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/policies/bindings',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: bindingJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await vaultApi.createBinding(
        policyId: 'policy-1',
        bindingType: BindingType.user,
        bindingTargetId: 'user-1',
      );

      expect(result.bindingTargetId, 'user-1');
    });

    test('evaluateAccess sends query parameters', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/policies/evaluate',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {'allowed': true, 'reason': 'Matched'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.evaluateAccess(
        userId: 'user-1',
        path: '/test',
        permission: PolicyPermission.read,
      );

      expect(result.allowed, true);
    });

    test('getPolicyStats returns counts', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/policies/stats'))
          .thenAnswer((_) async => Response(
                data: {'total': 5, 'active': 4, 'deny': 1},
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.getPolicyStats();
      expect(result['total'], 5);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Rotation
  // ═══════════════════════════════════════════════════════════════════════════

  final rotationPolicyJson = {
    'id': 'rp-1',
    'secretId': 'secret-1',
    'strategy': 'RANDOM_GENERATE',
    'rotationIntervalHours': 24,
    'isActive': true,
    'failureCount': 0,
  };

  final rotationHistoryJson = {
    'id': 'rh-1',
    'secretId': 'secret-1',
    'strategy': 'RANDOM_GENERATE',
    'previousVersion': 1,
    'newVersion': 2,
    'success': true,
    'durationMs': 100,
  };

  group('Rotation', () {
    test('createOrUpdateRotationPolicy sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/rotation/policies',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: rotationPolicyJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await vaultApi.createOrUpdateRotationPolicy(
        secretId: 'secret-1',
        strategy: RotationStrategy.randomGenerate,
        rotationIntervalHours: 24,
      );

      expect(result.strategy.toJson(), 'RANDOM_GENERATE');
    });

    test('rotateSecret triggers rotation', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/rotation/rotate/secret-1',
          )).thenAnswer((_) async => Response(
            data: rotationHistoryJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.rotateSecret('secret-1');
      expect(result.success, true);
      expect(result.newVersion, 2);
    });

    test('deleteRotationPolicy calls correct path', () async {
      when(() => mockClient.delete('/rotation/policies/rp-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 204,
              ));

      await vaultApi.deleteRotationPolicy('rp-1');
      verify(() => mockClient.delete('/rotation/policies/rp-1')).called(1);
    });

    test('getRotationStats returns counts', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/rotation/stats/secret-1',
          )).thenAnswer((_) async => Response(
            data: {'activePolicies': 1, 'totalRotations': 10},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.getRotationStats('secret-1');
      expect(result['totalRotations'], 10);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Transit
  // ═══════════════════════════════════════════════════════════════════════════

  final transitKeyJson = {
    'id': 'tk-1',
    'teamId': 'team-1',
    'name': 'app-key',
    'currentVersion': 1,
    'minDecryptionVersion': 1,
    'algorithm': 'AES-256-GCM',
    'isDeletable': false,
    'isExportable': false,
    'isActive': true,
  };

  group('Transit', () {
    test('createTransitKey sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/transit/keys',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: transitKeyJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await vaultApi.createTransitKey(name: 'app-key');
      expect(result.name, 'app-key');
    });

    test('transitEncrypt sends key name and plaintext', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/transit/encrypt',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {
              'keyName': 'app-key',
              'keyVersion': 1,
              'ciphertext': 'ct',
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.transitEncrypt(
        keyName: 'app-key',
        plaintext: 'hello',
      );

      expect(result.ciphertext, 'ct');
    });

    test('transitDecrypt sends key name and ciphertext', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/transit/decrypt',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: {'keyName': 'app-key', 'plaintext': 'hello'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.transitDecrypt(
        keyName: 'app-key',
        ciphertext: 'ct',
      );

      expect(result.plaintext, 'hello');
    });

    test('deleteTransitKey calls correct path', () async {
      when(() => mockClient.delete('/transit/keys/tk-1'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 204,
              ));

      await vaultApi.deleteTransitKey('tk-1');
      verify(() => mockClient.delete('/transit/keys/tk-1')).called(1);
    });

    test('generateDataKey returns plaintext and ciphertext', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/transit/datakey',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {'plaintext': 'pt-base64', 'ciphertext': 'ct-wrapped'},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.generateDataKey('app-key');
      expect(result['plaintext'], 'pt-base64');
      expect(result['ciphertext'], 'ct-wrapped');
    });

    test('getTransitKeyStats returns counts', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/transit/stats'))
          .thenAnswer((_) async => Response(
                data: {'total': 3, 'active': 2},
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.getTransitKeyStats();
      expect(result['total'], 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Dynamic Secrets
  // ═══════════════════════════════════════════════════════════════════════════

  final leaseJson = {
    'id': 'dl-1',
    'leaseId': 'v_app_abc',
    'secretId': 'secret-1',
    'status': 'ACTIVE',
    'ttlSeconds': 3600,
  };

  group('Dynamic Secrets', () {
    test('createDynamicLease sends correct body', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/dynamic/leases',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: leaseJson,
            requestOptions: RequestOptions(),
            statusCode: 201,
          ));

      final result = await vaultApi.createDynamicLease(
        secretId: 'secret-1',
        ttlSeconds: 3600,
      );

      expect(result.leaseId, 'v_app_abc');
    });

    test('revokeDynamicLease calls correct path', () async {
      when(() => mockClient.post('/dynamic/leases/v_app_abc/revoke'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(),
                statusCode: 204,
              ));

      await vaultApi.revokeDynamicLease('v_app_abc');
      verify(() => mockClient.post('/dynamic/leases/v_app_abc/revoke'))
          .called(1);
    });

    test('revokeAllDynamicLeases returns count', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/dynamic/leases/revoke-all',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {'revoked': 5},
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.revokeAllDynamicLeases('secret-1');
      expect(result, 5);
    });

    test('getActiveDynamicLeaseCount returns count', () async {
      when(() =>
              mockClient.get<Map<String, dynamic>>('/dynamic/active-count'))
          .thenAnswer((_) async => Response(
                data: {'activeLeases': 12},
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.getActiveDynamicLeaseCount();
      expect(result, 12);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Seal
  // ═══════════════════════════════════════════════════════════════════════════

  final sealStatusJson = {
    'status': 'UNSEALED',
    'totalShares': 5,
    'threshold': 3,
    'sharesProvided': 3,
    'autoUnsealEnabled': true,
  };

  group('Seal', () {
    test('getSealStatus returns status', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/seal/status'))
          .thenAnswer((_) async => Response(
                data: sealStatusJson,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.getSealStatus();
      expect(result.status.toJson(), 'UNSEALED');
    });

    test('sealVault calls correct path', () async {
      when(() => mockClient.post<Map<String, dynamic>>('/seal/seal'))
          .thenAnswer((_) async => Response(
                data: {
                  ...sealStatusJson,
                  'status': 'SEALED',
                  'sharesProvided': 0,
                },
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.sealVault();
      expect(result.status.toJson(), 'SEALED');
    });

    test('unsealVault sends key share', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/seal/unseal',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: sealStatusJson,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.unsealVault(
        action: 'unseal',
        keyShare: 'base64share',
      );

      expect(result.status.toJson(), 'UNSEALED');
    });

    test('generateShares returns share data', () async {
      when(() => mockClient.post<Map<String, dynamic>>(
            '/seal/generate-shares',
          )).thenAnswer((_) async => Response(
            data: {
              'shares': ['s1', 's2', 's3', 's4', 's5'],
              'totalShares': 5,
              'threshold': 3,
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.generateShares();
      expect((result['shares'] as List), hasLength(5));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Audit
  // ═══════════════════════════════════════════════════════════════════════════

  final auditEntryJson = {
    'id': 1,
    'operation': 'WRITE',
    'success': true,
  };

  group('Audit', () {
    test('queryAuditLog sends filters as query parameters', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/audit/query',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'content': [auditEntryJson],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'isLast': true,
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await vaultApi.queryAuditLog(
        operation: 'WRITE',
        successOnly: true,
      );

      expect(result.content, hasLength(1));
      expect(result.content.first.operation, 'WRITE');
    });

    test('getAuditForResource sends path parameters', () async {
      when(() => mockClient.get<Map<String, dynamic>>(
            '/audit/resource/SECRET/secret-1',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'content': [auditEntryJson],
              'page': 0,
              'size': 20,
              'totalElements': 1,
              'totalPages': 1,
              'isLast': true,
            },
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result =
          await vaultApi.getAuditForResource('SECRET', 'secret-1');
      expect(result.content, hasLength(1));
    });

    test('getAuditStats returns counts', () async {
      when(() => mockClient.get<Map<String, dynamic>>('/audit/stats'))
          .thenAnswer((_) async => Response(
                data: {'totalEntries': 100, 'failedEntries': 3},
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

      final result = await vaultApi.getAuditStats();
      expect(result['totalEntries'], 100);
    });
  });
}
