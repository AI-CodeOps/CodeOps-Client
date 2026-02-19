// Tests for all 6 Vault enums.
//
// Verifies toJson(), fromJson() round-trips, displayName, converter,
// label map, and invalid input handling for every enum value.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/vault_enums.dart';

void main() {
  group('SecretType', () {
    test('toJson returns correct server strings', () {
      expect(SecretType.static_.toJson(), 'STATIC');
      expect(SecretType.dynamic_.toJson(), 'DYNAMIC');
      expect(SecretType.reference.toJson(), 'REFERENCE');
    });

    test('fromJson round-trips all values', () {
      for (final v in SecretType.values) {
        expect(SecretType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(SecretType.static_.displayName, 'Static');
      expect(SecretType.dynamic_.displayName, 'Dynamic');
      expect(SecretType.reference.displayName, 'Reference');
    });

    test('fromJson throws on invalid input', () {
      expect(() => SecretType.fromJson('INVALID'), throwsArgumentError);
    });

    test('converter round-trips', () {
      const converter = SecretTypeConverter();
      for (final v in SecretType.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });

    test('label map covers all values', () {
      for (final v in SecretType.values) {
        expect(secretTypeLabels.containsKey(v), isTrue);
      }
    });
  });

  group('SealStatus', () {
    test('toJson returns correct server strings', () {
      expect(SealStatus.sealed.toJson(), 'SEALED');
      expect(SealStatus.unsealed.toJson(), 'UNSEALED');
      expect(SealStatus.unsealing.toJson(), 'UNSEALING');
    });

    test('fromJson round-trips all values', () {
      for (final v in SealStatus.values) {
        expect(SealStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(SealStatus.sealed.displayName, 'Sealed');
      expect(SealStatus.unsealed.displayName, 'Unsealed');
      expect(SealStatus.unsealing.displayName, 'Unsealing');
    });

    test('fromJson throws on invalid input', () {
      expect(() => SealStatus.fromJson('INVALID'), throwsArgumentError);
    });

    test('converter round-trips', () {
      const converter = SealStatusConverter();
      for (final v in SealStatus.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });

    test('label map covers all values', () {
      for (final v in SealStatus.values) {
        expect(sealStatusLabels.containsKey(v), isTrue);
      }
    });
  });

  group('PolicyPermission', () {
    test('toJson returns correct server strings', () {
      expect(PolicyPermission.read.toJson(), 'READ');
      expect(PolicyPermission.write.toJson(), 'WRITE');
      expect(PolicyPermission.delete.toJson(), 'DELETE');
      expect(PolicyPermission.list.toJson(), 'LIST');
      expect(PolicyPermission.rotate.toJson(), 'ROTATE');
    });

    test('fromJson round-trips all values', () {
      for (final v in PolicyPermission.values) {
        expect(PolicyPermission.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(PolicyPermission.read.displayName, 'Read');
      expect(PolicyPermission.write.displayName, 'Write');
      expect(PolicyPermission.delete.displayName, 'Delete');
      expect(PolicyPermission.list.displayName, 'List');
      expect(PolicyPermission.rotate.displayName, 'Rotate');
    });

    test('fromJson throws on invalid input', () {
      expect(
        () => PolicyPermission.fromJson('INVALID'),
        throwsArgumentError,
      );
    });

    test('converter round-trips', () {
      const converter = PolicyPermissionConverter();
      for (final v in PolicyPermission.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });

    test('label map covers all values', () {
      for (final v in PolicyPermission.values) {
        expect(policyPermissionLabels.containsKey(v), isTrue);
      }
    });
  });

  group('BindingType', () {
    test('toJson returns correct server strings', () {
      expect(BindingType.user.toJson(), 'USER');
      expect(BindingType.team.toJson(), 'TEAM');
      expect(BindingType.service.toJson(), 'SERVICE');
    });

    test('fromJson round-trips all values', () {
      for (final v in BindingType.values) {
        expect(BindingType.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(BindingType.user.displayName, 'User');
      expect(BindingType.team.displayName, 'Team');
      expect(BindingType.service.displayName, 'Service');
    });

    test('fromJson throws on invalid input', () {
      expect(() => BindingType.fromJson('INVALID'), throwsArgumentError);
    });

    test('converter round-trips', () {
      const converter = BindingTypeConverter();
      for (final v in BindingType.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });

    test('label map covers all values', () {
      for (final v in BindingType.values) {
        expect(bindingTypeLabels.containsKey(v), isTrue);
      }
    });
  });

  group('RotationStrategy', () {
    test('toJson returns correct server strings', () {
      expect(RotationStrategy.randomGenerate.toJson(), 'RANDOM_GENERATE');
      expect(RotationStrategy.externalApi.toJson(), 'EXTERNAL_API');
      expect(RotationStrategy.customScript.toJson(), 'CUSTOM_SCRIPT');
    });

    test('fromJson round-trips all values', () {
      for (final v in RotationStrategy.values) {
        expect(RotationStrategy.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(RotationStrategy.randomGenerate.displayName, 'Random Generate');
      expect(RotationStrategy.externalApi.displayName, 'External API');
      expect(RotationStrategy.customScript.displayName, 'Custom Script');
    });

    test('fromJson throws on invalid input', () {
      expect(
        () => RotationStrategy.fromJson('INVALID'),
        throwsArgumentError,
      );
    });

    test('converter round-trips', () {
      const converter = RotationStrategyConverter();
      for (final v in RotationStrategy.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });

    test('label map covers all values', () {
      for (final v in RotationStrategy.values) {
        expect(rotationStrategyLabels.containsKey(v), isTrue);
      }
    });
  });

  group('LeaseStatus', () {
    test('toJson returns correct server strings', () {
      expect(LeaseStatus.active.toJson(), 'ACTIVE');
      expect(LeaseStatus.expired.toJson(), 'EXPIRED');
      expect(LeaseStatus.revoked.toJson(), 'REVOKED');
    });

    test('fromJson round-trips all values', () {
      for (final v in LeaseStatus.values) {
        expect(LeaseStatus.fromJson(v.toJson()), v);
      }
    });

    test('displayName returns human label', () {
      expect(LeaseStatus.active.displayName, 'Active');
      expect(LeaseStatus.expired.displayName, 'Expired');
      expect(LeaseStatus.revoked.displayName, 'Revoked');
    });

    test('fromJson throws on invalid input', () {
      expect(() => LeaseStatus.fromJson('INVALID'), throwsArgumentError);
    });

    test('converter round-trips', () {
      const converter = LeaseStatusConverter();
      for (final v in LeaseStatus.values) {
        expect(converter.fromJson(converter.toJson(v)), v);
      }
    });

    test('label map covers all values', () {
      for (final v in LeaseStatus.values) {
        expect(leaseStatusLabels.containsKey(v), isTrue);
      }
    });
  });
}
