// Tests for agent config Riverpod providers.
//
// Verifies default values, provider dependencies, and state changes.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/agent_config_providers.dart';
import 'package:codeops/services/cloud/anthropic_api_service.dart';

void main() {
  group('Agent config providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('anthropicApiServiceProvider returns AnthropicApiService', () {
      final service = container.read(anthropicApiServiceProvider);
      expect(service, isA<AnthropicApiService>());
    });

    test('apiKeyValidatedProvider defaults to null', () {
      final validated = container.read(apiKeyValidatedProvider);
      expect(validated, isNull);
    });

    test('apiKeyValidatedProvider can be set to true', () {
      container.read(apiKeyValidatedProvider.notifier).state = true;
      expect(container.read(apiKeyValidatedProvider), isTrue);
    });

    test('apiKeyValidatedProvider can be set to false', () {
      container.read(apiKeyValidatedProvider.notifier).state = false;
      expect(container.read(apiKeyValidatedProvider), isFalse);
    });

    test('modelFetchFailedProvider defaults to false', () {
      final failed = container.read(modelFetchFailedProvider);
      expect(failed, isFalse);
    });

    test('modelFetchFailedProvider can be set to true', () {
      container.read(modelFetchFailedProvider.notifier).state = true;
      expect(container.read(modelFetchFailedProvider), isTrue);
    });

    test('selectedAgentIdProvider defaults to null', () {
      final id = container.read(selectedAgentIdProvider);
      expect(id, isNull);
    });

    test('selectedAgentIdProvider can be set', () {
      container.read(selectedAgentIdProvider.notifier).state = 'agent-123';
      expect(container.read(selectedAgentIdProvider), 'agent-123');
    });

    test('selectedAgentProvider returns null when no agent selected', () {
      final agent = container.read(selectedAgentProvider);
      expect(agent, isNull);
    });

    test('agentConfigTabProvider defaults to 0', () {
      final tab = container.read(agentConfigTabProvider);
      expect(tab, 0);
    });

    test('agentConfigTabProvider can be changed', () {
      container.read(agentConfigTabProvider.notifier).state = 2;
      expect(container.read(agentConfigTabProvider), 2);
    });

    test('agentSearchQueryProvider defaults to empty string', () {
      final query = container.read(agentSearchQueryProvider);
      expect(query, isEmpty);
    });

    test('agentSearchQueryProvider can be updated', () {
      container.read(agentSearchQueryProvider.notifier).state = 'security';
      expect(container.read(agentSearchQueryProvider), 'security');
    });
  });
}
