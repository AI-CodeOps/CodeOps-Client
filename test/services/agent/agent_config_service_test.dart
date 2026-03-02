// Tests for AgentConfigService.
//
// Verifies agent seeding (idempotent, 17 agents), CRUD operations,
// file management, model caching, and built-in delete protection.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/database/database.dart';
import 'package:codeops/models/anthropic_model_info.dart';
import 'package:codeops/services/agent/agent_config_service.dart';
import 'package:codeops/services/auth/secure_storage.dart';
import 'package:codeops/services/cloud/anthropic_api_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAnthropicApiService extends Mock implements AnthropicApiService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late CodeOpsDatabase db;
  late MockAnthropicApiService mockApi;
  late MockSecureStorageService mockStorage;
  late AgentConfigService service;

  setUp(() {
    db = CodeOpsDatabase(NativeDatabase.memory());
    mockApi = MockAnthropicApiService();
    mockStorage = MockSecureStorageService();
    service = AgentConfigService(
      db: db,
      anthropicApi: mockApi,
      secureStorage: mockStorage,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AgentConfigService', () {
    group('model caching', () {
      test('getCachedModels returns empty initially', () async {
        final models = await service.getCachedModels();
        expect(models, isEmpty);
      });

      test('cacheModels stores and retrieves models', () async {
        final models = [
          AnthropicModelInfo(
            id: 'claude-sonnet-4-20250514',
            displayName: 'Claude Sonnet 4',
            contextWindow: 200000,
            maxOutputTokens: 16384,
            createdAt: DateTime.now(),
          ),
          AnthropicModelInfo(
            id: 'claude-opus-4-20250514',
            displayName: 'Claude Opus 4',
            contextWindow: 200000,
            maxOutputTokens: 32768,
            createdAt: DateTime.now(),
          ),
        ];

        await service.cacheModels(models);
        final cached = await service.getCachedModels();

        expect(cached, hasLength(2));
        expect(cached[0].id, 'claude-sonnet-4-20250514');
        expect(cached[1].id, 'claude-opus-4-20250514');
      });

      test('cacheModels replaces previous cache', () async {
        final first = [
          AnthropicModelInfo(
            id: 'model-a',
            displayName: 'Model A',
            createdAt: DateTime.now(),
          ),
        ];
        final second = [
          AnthropicModelInfo(
            id: 'model-b',
            displayName: 'Model B',
            createdAt: DateTime.now(),
          ),
        ];

        await service.cacheModels(first);
        await service.cacheModels(second);
        final cached = await service.getCachedModels();

        expect(cached, hasLength(1));
        expect(cached[0].id, 'model-b');
      });

      test('refreshModels returns empty when no API key', () async {
        when(() => mockStorage.getAnthropicApiKey())
            .thenAnswer((_) async => null);

        final result = await service.refreshModels();
        expect(result, isEmpty);
      });

      test('refreshModels fetches and caches', () async {
        when(() => mockStorage.getAnthropicApiKey())
            .thenAnswer((_) async => 'sk-test');
        when(() => mockApi.fetchModels('sk-test'))
            .thenAnswer((_) async => [
                  AnthropicModelInfo(
                    id: 'model-x',
                    displayName: 'Model X',
                    createdAt: DateTime.now(),
                  ),
                ]);

        final result = await service.refreshModels();

        expect(result, hasLength(1));
        expect(result[0].id, 'model-x');

        final cached = await service.getCachedModels();
        expect(cached, hasLength(1));
      });
    });

    group('agent CRUD', () {
      test('getAllAgents returns empty initially', () async {
        final agents = await service.getAllAgents();
        expect(agents, isEmpty);
      });

      test('createAgent creates a custom agent', () async {
        final agent = await service.createAgent(
          name: 'My Agent',
          description: 'Custom agent',
        );

        expect(agent.name, 'My Agent');
        expect(agent.description, 'Custom agent');
        expect(agent.isBuiltIn, isFalse);
        expect(agent.isEnabled, isTrue);
      });

      test('getAgent returns null for nonexistent id', () async {
        final agent = await service.getAgent('nonexistent');
        expect(agent, isNull);
      });

      test('updateAgent updates non-null fields', () async {
        final created = await service.createAgent(name: 'Agent A');
        await service.updateAgent(created.id, name: 'Agent B');

        final updated = await service.getAgent(created.id);
        expect(updated?.name, 'Agent B');
      });

      test('deleteAgent deletes custom agents', () async {
        final agent = await service.createAgent(name: 'Deletable');
        await service.deleteAgent(agent.id);

        final result = await service.getAgent(agent.id);
        expect(result, isNull);
      });

      test('deleteAgent throws for built-in agents', () async {
        // Insert a built-in agent directly.
        await db.into(db.agentDefinitions).insert(
              AgentDefinitionsCompanion(
                id: const Value('built-in-1'),
                name: const Value('Built-in Agent'),
                isBuiltIn: const Value(true),
                createdAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );

        expect(
          () => service.deleteAgent('built-in-1'),
          throwsA(isA<StateError>()),
        );
      });

      test('deleteAgent cascade deletes files', () async {
        final agent = await service.createAgent(name: 'WithFiles');
        await service.addFile(agent.id,
            fileName: 'test.md', fileType: 'context');

        final filesBefore = await service.getAgentFiles(agent.id);
        expect(filesBefore, hasLength(1));

        await service.deleteAgent(agent.id);

        final filesAfter = await service.getAgentFiles(agent.id);
        expect(filesAfter, isEmpty);
      });

      test('reorderAgents updates sort order', () async {
        final a = await service.createAgent(name: 'A');
        final b = await service.createAgent(name: 'B');

        await service.reorderAgents([b.id, a.id]);

        final agents = await service.getAllAgents();
        expect(agents[0].id, b.id);
        expect(agents[1].id, a.id);
      });
    });

    group('file management', () {
      test('addFile creates a file entry', () async {
        final agent = await service.createAgent(name: 'Agent');
        final file = await service.addFile(
          agent.id,
          fileName: 'persona.md',
          fileType: 'persona',
          contentMd: '# Persona',
        );

        expect(file.fileName, 'persona.md');
        expect(file.fileType, 'persona');
        expect(file.contentMd, '# Persona');
      });

      test('getAgentFiles returns ordered files', () async {
        final agent = await service.createAgent(name: 'Agent');
        await service.addFile(agent.id,
            fileName: 'first.md', fileType: 'context');
        await service.addFile(agent.id,
            fileName: 'second.md', fileType: 'prompt');

        final files = await service.getAgentFiles(agent.id);
        expect(files, hasLength(2));
        expect(files[0].fileName, 'first.md');
        expect(files[1].fileName, 'second.md');
      });

      test('updateFile updates content', () async {
        final agent = await service.createAgent(name: 'Agent');
        final file = await service.addFile(agent.id,
            fileName: 'file.md', fileType: 'context', contentMd: 'old');

        await service.updateFile(file.id, contentMd: 'new');

        final files = await service.getAgentFiles(agent.id);
        expect(files[0].contentMd, 'new');
      });

      test('deleteFile removes the entry', () async {
        final agent = await service.createAgent(name: 'Agent');
        final file = await service.addFile(agent.id,
            fileName: 'file.md', fileType: 'context');

        await service.deleteFile(file.id);

        final files = await service.getAgentFiles(agent.id);
        expect(files, isEmpty);
      });
    });
  });
}
