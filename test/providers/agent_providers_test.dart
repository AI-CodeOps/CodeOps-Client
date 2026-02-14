import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/providers/agent_providers.dart';
import 'package:codeops/services/orchestration/agent_dispatcher.dart';
import 'package:codeops/utils/constants.dart';

void main() {
  group('selectedAgentTypesProvider', () {
    test('defaults to all agent types', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selected = container.read(selectedAgentTypesProvider);
      expect(selected, equals(AgentType.values.toSet()));
    });

    test('contains every AgentType enum value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selected = container.read(selectedAgentTypesProvider);
      for (final agentType in AgentType.values) {
        expect(selected.contains(agentType), isTrue,
            reason: '$agentType should be selected by default');
      }
    });

    test('has the correct count matching AgentType.values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selected = container.read(selectedAgentTypesProvider);
      expect(selected.length, equals(AgentType.values.length));
    });
  });

  group('agentDispatchConfigProvider', () {
    test('has correct defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(agentDispatchConfigProvider);
      expect(config.maxConcurrent, AppConstants.defaultMaxConcurrentAgents);
      expect(config.agentTimeout,
          const Duration(minutes: AppConstants.defaultAgentTimeoutMinutes));
      expect(config.claudeModel, AppConstants.defaultClaudeModelForDispatch);
      expect(config.maxTurns, AppConstants.defaultMaxTurns);
    });

    test('setMaxConcurrent updates config', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(agentDispatchConfigProvider.notifier).setMaxConcurrent(5);

      final config = container.read(agentDispatchConfigProvider);
      expect(config.maxConcurrent, 5);
      // Other fields remain unchanged.
      expect(config.agentTimeout,
          const Duration(minutes: AppConstants.defaultAgentTimeoutMinutes));
      expect(config.claudeModel, AppConstants.defaultClaudeModelForDispatch);
      expect(config.maxTurns, AppConstants.defaultMaxTurns);
    });

    test('setAgentTimeout updates config', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(agentDispatchConfigProvider.notifier)
          .setAgentTimeout(const Duration(minutes: 30));

      final config = container.read(agentDispatchConfigProvider);
      expect(config.agentTimeout, const Duration(minutes: 30));
      // Other fields remain unchanged.
      expect(config.maxConcurrent, AppConstants.defaultMaxConcurrentAgents);
      expect(config.claudeModel, AppConstants.defaultClaudeModelForDispatch);
      expect(config.maxTurns, AppConstants.defaultMaxTurns);
    });

    test('setClaudeModel updates config', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(agentDispatchConfigProvider.notifier)
          .setClaudeModel('claude-opus-4-20250514');

      final config = container.read(agentDispatchConfigProvider);
      expect(config.claudeModel, 'claude-opus-4-20250514');
      // Other fields remain unchanged.
      expect(config.maxConcurrent, AppConstants.defaultMaxConcurrentAgents);
      expect(config.agentTimeout,
          const Duration(minutes: AppConstants.defaultAgentTimeoutMinutes));
      expect(config.maxTurns, AppConstants.defaultMaxTurns);
    });

    test('setMaxTurns updates config', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(agentDispatchConfigProvider.notifier).setMaxTurns(25);

      final config = container.read(agentDispatchConfigProvider);
      expect(config.maxTurns, 25);
      // Other fields remain unchanged.
      expect(config.maxConcurrent, AppConstants.defaultMaxConcurrentAgents);
      expect(config.agentTimeout,
          const Duration(minutes: AppConstants.defaultAgentTimeoutMinutes));
      expect(config.claudeModel, AppConstants.defaultClaudeModelForDispatch);
    });

    test('multiple sequential updates accumulate correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(agentDispatchConfigProvider.notifier);
      notifier.setMaxConcurrent(8);
      notifier.setAgentTimeout(const Duration(minutes: 45));
      notifier.setClaudeModel('claude-opus-4-20250514');
      notifier.setMaxTurns(10);

      final config = container.read(agentDispatchConfigProvider);
      expect(config.maxConcurrent, 8);
      expect(config.agentTimeout, const Duration(minutes: 45));
      expect(config.claudeModel, 'claude-opus-4-20250514');
      expect(config.maxTurns, 10);
    });
  });

  group('AgentDispatchConfig', () {
    test('default constructor values match AppConstants', () {
      const config = AgentDispatchConfig();
      expect(config.maxConcurrent, AppConstants.defaultMaxConcurrentAgents);
      expect(config.agentTimeout,
          const Duration(minutes: AppConstants.defaultAgentTimeoutMinutes));
      expect(config.claudeModel, AppConstants.defaultClaudeModelForDispatch);
      expect(config.maxTurns, AppConstants.defaultMaxTurns);
    });

    test('accepts custom values via constructor', () {
      const config = AgentDispatchConfig(
        maxConcurrent: 10,
        agentTimeout: Duration(minutes: 60),
        claudeModel: 'custom-model',
        maxTurns: 99,
      );
      expect(config.maxConcurrent, 10);
      expect(config.agentTimeout, const Duration(minutes: 60));
      expect(config.claudeModel, 'custom-model');
      expect(config.maxTurns, 99);
    });
  });
}
