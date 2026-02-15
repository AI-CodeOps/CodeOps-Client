// Tests for health providers.
//
// Verifies provider creation, default state values, and async provider types.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/health_providers.dart';
import 'package:codeops/services/cloud/metrics_api.dart';
import 'package:codeops/services/cloud/health_monitor_api.dart';

void main() {
  group('Health providers', () {
    // -----------------------------------------------------------------------
    // API providers
    // -----------------------------------------------------------------------

    test('metricsApiProvider creates instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(metricsApiProvider);

      expect(api, isA<MetricsApi>());
    });

    test('healthMonitorApiProvider creates instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(healthMonitorApiProvider);

      expect(api, isA<HealthMonitorApi>());
    });

    // -----------------------------------------------------------------------
    // UI state providers
    // -----------------------------------------------------------------------

    test('selectedHealthProjectProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(selectedHealthProjectProvider);

      expect(value, isNull);
    });

    test('selectedHealthProjectProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedHealthProjectProvider.notifier).state =
          'project-abc';

      expect(container.read(selectedHealthProjectProvider), 'project-abc');
    });

    test('healthTrendRangeProvider defaults to 30', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(healthTrendRangeProvider);

      expect(value, 30);
    });

    test('healthTrendRangeProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(healthTrendRangeProvider.notifier).state = 90;

      expect(container.read(healthTrendRangeProvider), 90);
    });

    // -----------------------------------------------------------------------
    // FutureProviders
    // -----------------------------------------------------------------------

    test('teamMetricsProvider is a FutureProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Returns null immediately when no team is selected.
      final asyncValue = container.read(teamMetricsProvider);

      expect(asyncValue, isA<AsyncValue>());
    });

    test('projectMetricsProvider exists and is a family provider', () {
      // Verifies the provider is properly defined without triggering the
      // API layer which requires WidgetsFlutterBinding.
      expect(projectMetricsProvider, isNotNull);
      expect(projectMetricsProvider('proj-1'), isNotNull);
    });

    test('healthHistoryProvider exists and is a family provider', () {
      expect(healthHistoryProvider, isNotNull);
      expect(healthHistoryProvider('proj-1'), isNotNull);
    });

    test('healthSchedulesProvider exists and is a family provider', () {
      expect(healthSchedulesProvider, isNotNull);
      expect(healthSchedulesProvider('proj-1'), isNotNull);
    });

    test('latestSnapshotProvider exists and is a family provider', () {
      expect(latestSnapshotProvider, isNotNull);
      expect(latestSnapshotProvider('proj-1'), isNotNull);
    });

    test('healthTrendProvider exists and is a family provider', () {
      expect(healthTrendProvider, isNotNull);
      expect(healthTrendProvider('proj-1'), isNotNull);
    });

    // -----------------------------------------------------------------------
    // Derived providers
    // -----------------------------------------------------------------------

    test('healthScoreDeltaProvider returns null when no metrics', () {
      final container = ProviderContainer(
        overrides: [
          projectMetricsProvider('proj-1')
              .overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      final delta = container.read(healthScoreDeltaProvider('proj-1'));

      expect(delta, isNull);
    });
  });
}
