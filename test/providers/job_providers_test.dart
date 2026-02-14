// Tests for job providers.
//
// Verifies activeJobIdProvider state management (default, set, clear).
// FutureProviders that depend on API clients are not tested here since they
// would require extensive mocking of the auth and API layers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/job_providers.dart';

void main() {
  group('Job providers', () {
    test('activeJobIdProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeJobIdProvider), isNull);
    });

    test('activeJobIdProvider can be set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activeJobIdProvider.notifier).state = 'job-123';
      expect(container.read(activeJobIdProvider), 'job-123');
    });

    test('activeJobIdProvider can be cleared', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activeJobIdProvider.notifier).state = 'job-123';
      container.read(activeJobIdProvider.notifier).state = null;
      expect(container.read(activeJobIdProvider), isNull);
    });
  });
}
