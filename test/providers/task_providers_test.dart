// Tests for task providers.
//
// Verifies that integrationApiProvider, taskApiProvider are accessible
// and create proper instances. FutureProviders are verified as existing
// by checking their type without triggering execution.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/task_providers.dart';
import 'package:codeops/services/cloud/integration_api.dart';
import 'package:codeops/services/cloud/task_api.dart';

void main() {
  group('Task providers', () {
    test('integrationApiProvider creates IntegrationApi instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(integrationApiProvider);

      expect(api, isA<IntegrationApi>());
    });

    test('taskApiProvider creates TaskApi instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final api = container.read(taskApiProvider);

      expect(api, isA<TaskApi>());
    });

    test('jobTasksProvider is defined as a family provider', () {
      // Verify the provider exists and can be called with a parameter.
      // We do not read it from a container because it would trigger
      // an actual API call requiring WidgetsFlutterBinding.
      expect(jobTasksProvider, isNotNull);
      expect(jobTasksProvider('any-id'), isNotNull);
    });

    test('myTasksProvider is defined', () {
      expect(myTasksProvider, isNotNull);
    });

    test('taskProvider is defined as a family provider', () {
      expect(taskProvider, isNotNull);
      expect(taskProvider('any-id'), isNotNull);
    });
  });
}
