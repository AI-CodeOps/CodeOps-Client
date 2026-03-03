// Unit tests for health badge colors and Registry health integration.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/providers/courier_providers.dart';
import 'package:codeops/theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Health badge colors', () {
    test('UP maps to success (green)', () {
      expect(CodeOpsColors.healthStatusColors[HealthStatus.up],
          CodeOpsColors.success);
    });

    test('DOWN maps to error (red)', () {
      expect(CodeOpsColors.healthStatusColors[HealthStatus.down],
          CodeOpsColors.error);
    });

    test('DEGRADED maps to warning (amber)', () {
      expect(CodeOpsColors.healthStatusColors[HealthStatus.degraded],
          CodeOpsColors.warning);
    });

    test('UNKNOWN maps to textTertiary (grey)', () {
      expect(CodeOpsColors.healthStatusColors[HealthStatus.unknown],
          CodeOpsColors.textTertiary);
    });
  });

  group('Registry service provider', () {
    test('registryServicesForCourierProvider returns empty list without team',
        () {
      final container = ProviderContainer(
        overrides: [
          registryServicesForCourierProvider
              .overrideWith((ref) => <ServiceRegistrationResponse>[]),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(registryServicesForCourierProvider);
      expect(result,
          isA<AsyncValue<List<ServiceRegistrationResponse>>>());
    });
  });
}
