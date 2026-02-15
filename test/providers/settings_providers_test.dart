// Tests for settings providers.
//
// Verifies default values and state updates for all settings providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/settings_providers.dart';
import 'package:codeops/utils/constants.dart';

void main() {
  group('Settings providers', () {
    // -----------------------------------------------------------------------
    // Claude & agent settings
    // -----------------------------------------------------------------------

    test('claudeModelProvider defaults to AppConstants.defaultClaudeModel', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(claudeModelProvider);

      expect(value, AppConstants.defaultClaudeModel);
    });

    test('claudeModelProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(claudeModelProvider.notifier).state = 'claude-opus-4';

      expect(container.read(claudeModelProvider), 'claude-opus-4');
    });

    test(
        'maxConcurrentAgentsProvider defaults to '
        'AppConstants.defaultMaxConcurrentAgents', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(maxConcurrentAgentsProvider);

      expect(value, AppConstants.defaultMaxConcurrentAgents);
    });

    test('maxConcurrentAgentsProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(maxConcurrentAgentsProvider.notifier).state = 6;

      expect(container.read(maxConcurrentAgentsProvider), 6);
    });

    test(
        'agentTimeoutMinutesProvider defaults to '
        'AppConstants.defaultAgentTimeoutMinutes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(agentTimeoutMinutesProvider);

      expect(value, AppConstants.defaultAgentTimeoutMinutes);
    });

    test('agentTimeoutMinutesProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(agentTimeoutMinutesProvider.notifier).state = 30;

      expect(container.read(agentTimeoutMinutesProvider), 30);
    });

    // -----------------------------------------------------------------------
    // Connectivity & offline
    // -----------------------------------------------------------------------

    test('offlineModeProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(offlineModeProvider);

      expect(value, false);
    });

    test('offlineModeProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(offlineModeProvider.notifier).state = true;

      expect(container.read(offlineModeProvider), true);
    });

    test('connectivityProvider defaults to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(connectivityProvider);

      expect(value, true);
    });

    test('connectivityProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(connectivityProvider.notifier).state = false;

      expect(container.read(connectivityProvider), false);
    });

    // -----------------------------------------------------------------------
    // UI preferences
    // -----------------------------------------------------------------------

    test('sidebarCollapsedProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(sidebarCollapsedProvider);

      expect(value, false);
    });

    test('sidebarCollapsedProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sidebarCollapsedProvider.notifier).state = true;

      expect(container.read(sidebarCollapsedProvider), true);
    });

    test('settingsSectionProvider defaults to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(settingsSectionProvider);

      expect(value, 0);
    });

    test('settingsSectionProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsSectionProvider.notifier).state = 2;

      expect(container.read(settingsSectionProvider), 2);
    });

    test('fontDensityProvider defaults to 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(fontDensityProvider);

      expect(value, 1);
    });

    test('fontDensityProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fontDensityProvider.notifier).state = 2;

      expect(container.read(fontDensityProvider), 2);
    });

    test('compactModeProvider defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(compactModeProvider);

      expect(value, false);
    });

    test('compactModeProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(compactModeProvider.notifier).state = true;

      expect(container.read(compactModeProvider), true);
    });

    test('autoUpdateProvider defaults to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(autoUpdateProvider);

      expect(value, true);
    });

    test('autoUpdateProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(autoUpdateProvider.notifier).state = false;

      expect(container.read(autoUpdateProvider), false);
    });

    test('claudeCodePathProvider defaults to empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(claudeCodePathProvider);

      expect(value, '');
    });

    test('claudeCodePathProvider can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(claudeCodePathProvider.notifier).state =
          '/usr/local/bin/claude';

      expect(
        container.read(claudeCodePathProvider),
        '/usr/local/bin/claude',
      );
    });
  });
}
