/// Service for managing agent definitions, attached files, and cached
/// Anthropic model metadata.
///
/// Provides CRUD operations for agents and files, model caching backed
/// by Drift, and idempotent seeding of built-in agent definitions.
library;

import 'dart:io' show File;

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

import '../../database/database.dart';
import '../../models/anthropic_model_info.dart';
import '../auth/secure_storage.dart';
import '../cloud/anthropic_api_service.dart';
import '../logging/log_service.dart';

const _uuid = Uuid();

/// Manages local agent configuration, Anthropic model caching, and
/// attached file storage.
class AgentConfigService {
  final CodeOpsDatabase _db;
  final AnthropicApiService _anthropicApi;
  final SecureStorageService _secureStorage;

  /// Creates an [AgentConfigService].
  AgentConfigService({
    required CodeOpsDatabase db,
    required AnthropicApiService anthropicApi,
    required SecureStorageService secureStorage,
  })  : _db = db,
        _anthropicApi = anthropicApi,
        _secureStorage = secureStorage;

  // ---------------------------------------------------------------------------
  // Model caching
  // ---------------------------------------------------------------------------

  /// Returns all cached Anthropic models from the local database.
  Future<List<AnthropicModelInfo>> getCachedModels() async {
    final rows = await _db.select(_db.anthropicModels).get();
    return rows.map(AnthropicModelInfo.fromDb).toList();
  }

  /// Replaces the entire model cache with [models].
  Future<void> cacheModels(List<AnthropicModelInfo> models) async {
    await _db.transaction(() async {
      await _db.delete(_db.anthropicModels).go();
      for (final model in models) {
        await _db.into(_db.anthropicModels).insert(
              model.toDbCompanion(),
              mode: InsertMode.replace,
            );
      }
    });
    log.i('AgentConfigService', 'Cached ${models.length} models');
  }

  /// Refreshes the model cache from the Anthropic API.
  ///
  /// Reads the API key from secure storage, fetches models, and caches
  /// them locally. Returns the fetched models, or an empty list if
  /// no API key is configured.
  Future<List<AnthropicModelInfo>> refreshModels() async {
    final apiKey = await _secureStorage.getAnthropicApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      log.w('AgentConfigService', 'No API key configured, skipping refresh');
      return [];
    }

    final models = await _anthropicApi.fetchModels(apiKey);
    await cacheModels(models);
    return models;
  }

  // ---------------------------------------------------------------------------
  // Agent CRUD
  // ---------------------------------------------------------------------------

  /// Returns all agent definitions ordered by [sortOrder].
  Future<List<AgentDefinition>> getAllAgents() async {
    return (_db.select(_db.agentDefinitions)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
          ]))
        .get();
  }

  /// Returns a single agent definition by [id], or `null` if not found.
  Future<AgentDefinition?> getAgent(String id) async {
    return (_db.select(_db.agentDefinitions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Creates a new custom agent definition.
  ///
  /// Returns the created [AgentDefinition].
  Future<AgentDefinition> createAgent({
    required String name,
    String? description,
    String? agentType,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Get next sort order.
    final agents = await getAllAgents();
    final maxSort = agents.isEmpty
        ? 0
        : agents.map((a) => a.sortOrder).reduce((a, b) => a > b ? a : b);

    final companion = AgentDefinitionsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      agentType: Value(agentType),
      isBuiltIn: const Value(false),
      isQaManager: const Value(false),
      isEnabled: const Value(true),
      temperature: const Value(0.0),
      maxRetries: const Value(1),
      maxTurns: const Value(50),
      sortOrder: Value(maxSort + 1),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _db.into(_db.agentDefinitions).insert(companion);
    log.i('AgentConfigService', 'Created agent: $name (id=$id)');
    return (await getAgent(id))!;
  }

  /// Updates an existing agent definition.
  ///
  /// Only non-null fields are updated. Stamps [updatedAt] automatically.
  Future<void> updateAgent(
    String id, {
    String? name,
    String? description,
    String? agentType,
    bool? isEnabled,
    String? modelId,
    double? temperature,
    int? maxRetries,
    int? timeoutMinutes,
    int? maxTurns,
    String? systemPromptOverride,
  }) async {
    final companion = AgentDefinitionsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      agentType: agentType != null ? Value(agentType) : const Value.absent(),
      isEnabled: isEnabled != null ? Value(isEnabled) : const Value.absent(),
      modelId: modelId != null ? Value(modelId) : const Value.absent(),
      temperature:
          temperature != null ? Value(temperature) : const Value.absent(),
      maxRetries:
          maxRetries != null ? Value(maxRetries) : const Value.absent(),
      timeoutMinutes: timeoutMinutes != null
          ? Value(timeoutMinutes)
          : const Value.absent(),
      maxTurns: maxTurns != null ? Value(maxTurns) : const Value.absent(),
      systemPromptOverride: systemPromptOverride != null
          ? Value(systemPromptOverride)
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await (_db.update(_db.agentDefinitions)
          ..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Deletes a custom agent and its attached files.
  ///
  /// Throws [StateError] if the agent is built-in.
  Future<void> deleteAgent(String id) async {
    final agent = await getAgent(id);
    if (agent == null) return;
    if (agent.isBuiltIn) {
      throw StateError('Cannot delete built-in agent: ${agent.name}');
    }

    await _db.transaction(() async {
      await (_db.delete(_db.agentFiles)
            ..where((t) => t.agentDefinitionId.equals(id)))
          .go();
      await (_db.delete(_db.agentDefinitions)
            ..where((t) => t.id.equals(id)))
          .go();
    });
    log.i('AgentConfigService', 'Deleted agent: ${agent.name} (id=$id)');
  }

  /// Reorders agents by updating [sortOrder] based on [orderedIds] position.
  Future<void> reorderAgents(List<String> orderedIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.agentDefinitions)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(AgentDefinitionsCompanion(sortOrder: Value(i)));
      }
    });
  }

  // ---------------------------------------------------------------------------
  // File management
  // ---------------------------------------------------------------------------

  /// Returns all files for a given agent, ordered by [sortOrder].
  Future<List<AgentFile>> getAgentFiles(String agentDefinitionId) async {
    return (_db.select(_db.agentFiles)
          ..where((t) => t.agentDefinitionId.equals(agentDefinitionId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Adds a file to an agent definition.
  ///
  /// Returns the created [AgentFile].
  Future<AgentFile> addFile(
    String agentDefinitionId, {
    required String fileName,
    required String fileType,
    String? contentMd,
    String? filePath,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Get next sort order for this agent's files.
    final files = await getAgentFiles(agentDefinitionId);
    final maxSort = files.isEmpty
        ? 0
        : files.map((f) => f.sortOrder).reduce((a, b) => a > b ? a : b);

    final companion = AgentFilesCompanion(
      id: Value(id),
      agentDefinitionId: Value(agentDefinitionId),
      fileName: Value(fileName),
      fileType: Value(fileType),
      contentMd: Value(contentMd),
      filePath: Value(filePath),
      sortOrder: Value(maxSort + 1),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _db.into(_db.agentFiles).insert(companion);
    return (_db.select(_db.agentFiles)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  /// Updates an existing file's metadata or content.
  Future<void> updateFile(
    String fileId, {
    String? fileName,
    String? contentMd,
    String? fileType,
  }) async {
    final companion = AgentFilesCompanion(
      fileName: fileName != null ? Value(fileName) : const Value.absent(),
      contentMd: contentMd != null ? Value(contentMd) : const Value.absent(),
      fileType: fileType != null ? Value(fileType) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await (_db.update(_db.agentFiles)..where((t) => t.id.equals(fileId)))
        .write(companion);
  }

  /// Deletes a file by [fileId].
  Future<void> deleteFile(String fileId) async {
    await (_db.delete(_db.agentFiles)..where((t) => t.id.equals(fileId))).go();
  }

  /// Opens a file picker to import a `.md` file from disk.
  ///
  /// Returns the created [AgentFile], or `null` if the user cancelled.
  Future<AgentFile?> importFileFromDisk(String agentDefinitionId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt', 'markdown'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return null;

    final content = await File(path).readAsString();

    return addFile(
      agentDefinitionId,
      fileName: file.name,
      fileType: 'context',
      contentMd: content,
      filePath: path,
    );
  }

  // ---------------------------------------------------------------------------
  // Seed built-in agents
  // ---------------------------------------------------------------------------

  /// Seeds the 17 built-in agent definitions if the table is empty.
  ///
  /// Idempotent: does nothing if agents already exist.
  Future<void> seedBuiltInAgents() async {
    final existing = await getAllAgents();
    if (existing.isNotEmpty) {
      log.d('AgentConfigService', 'Agents already seeded (${existing.length})');
      return;
    }

    log.i('AgentConfigService', 'Seeding built-in agents');
    final now = DateTime.now();

    final agentSpecs = _builtInAgentSpecs;
    await _db.transaction(() async {
      for (var i = 0; i < agentSpecs.length; i++) {
        final spec = agentSpecs[i];
        final agentId = _uuid.v4();

        await _db.into(_db.agentDefinitions).insert(
              AgentDefinitionsCompanion(
                id: Value(agentId),
                name: Value(spec.name),
                agentType: Value(spec.agentType),
                isQaManager: Value(spec.isQaManager),
                isBuiltIn: const Value(true),
                isEnabled: const Value(true),
                temperature: const Value(0.0),
                maxRetries: const Value(1),
                maxTurns: const Value(50),
                description: Value(spec.description),
                sortOrder: Value(i),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        // Seed persona file for each agent.
        if (spec.personaAsset != null) {
          try {
            final content = await rootBundle.loadString(spec.personaAsset!);
            await _db.into(_db.agentFiles).insert(
                  AgentFilesCompanion(
                    id: Value(_uuid.v4()),
                    agentDefinitionId: Value(agentId),
                    fileName: Value('${spec.name} Persona'),
                    fileType: const Value('persona'),
                    contentMd: Value(content),
                    sortOrder: const Value(0),
                    createdAt: Value(now),
                    updatedAt: Value(now),
                  ),
                );
          } catch (e) {
            log.w('AgentConfigService',
                'Failed to load persona asset: ${spec.personaAsset}', e);
          }
        }
      }
    });

    log.i('AgentConfigService', 'Seeded ${agentSpecs.length} built-in agents');
  }
}

// ---------------------------------------------------------------------------
// Built-in agent specifications
// ---------------------------------------------------------------------------

class _BuiltInAgentSpec {
  final String name;
  final String? agentType;
  final bool isQaManager;
  final String description;
  final String? personaAsset;

  const _BuiltInAgentSpec({
    required this.name,
    this.agentType,
    this.isQaManager = false,
    required this.description,
    this.personaAsset,
  });
}

/// The 17 built-in agents: Vera (QA Manager) + 12 standard + 4 adversarial.
final List<_BuiltInAgentSpec> _builtInAgentSpecs = [
  const _BuiltInAgentSpec(
    name: 'Vera',
    agentType: null,
    isQaManager: true,
    description: 'QA Manager — orchestrates analysis and consolidates reports',
    personaAsset: 'assets/personas/vera-manager.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Security Agent',
    agentType: 'SECURITY',
    description: 'Identifies vulnerabilities, injection risks, and auth issues',
    personaAsset: 'assets/personas/agent-security.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Code Quality Agent',
    agentType: 'CODE_QUALITY',
    description: 'Reviews code structure, naming, complexity, and best practices',
    personaAsset: 'assets/personas/agent-code-quality.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Build Health Agent',
    agentType: 'BUILD_HEALTH',
    description: 'Validates build configuration, dependencies, and CI/CD setup',
    personaAsset: 'assets/personas/agent-build-health.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Completeness Agent',
    agentType: 'COMPLETENESS',
    description: 'Checks for missing features, TODOs, and incomplete implementations',
    personaAsset: 'assets/personas/agent-completeness.md',
  ),
  const _BuiltInAgentSpec(
    name: 'API Contract Agent',
    agentType: 'API_CONTRACT',
    description: 'Validates API endpoints against OpenAPI specs and contracts',
    personaAsset: 'assets/personas/agent-api-contract.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Test Coverage Agent',
    agentType: 'TEST_COVERAGE',
    description: 'Analyzes test completeness, quality, and coverage gaps',
    personaAsset: 'assets/personas/agent-test-coverage.md',
  ),
  const _BuiltInAgentSpec(
    name: 'UI/UX Agent',
    agentType: 'UI_UX',
    description: 'Reviews user interface quality, accessibility, and UX patterns',
    personaAsset: 'assets/personas/agent-ui-ux.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Documentation Agent',
    agentType: 'DOCUMENTATION',
    description: 'Evaluates code documentation, README quality, and API docs',
    personaAsset: 'assets/personas/agent-documentation.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Database Agent',
    agentType: 'DATABASE',
    description: 'Reviews schema design, queries, migrations, and data integrity',
    personaAsset: 'assets/personas/agent-database.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Performance Agent',
    agentType: 'PERFORMANCE',
    description: 'Identifies performance bottlenecks, memory leaks, and N+1 queries',
    personaAsset: 'assets/personas/agent-performance.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Dependency Agent',
    agentType: 'DEPENDENCY',
    description: 'Scans for outdated, vulnerable, or unnecessary dependencies',
    personaAsset: 'assets/personas/agent-dependency.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Architecture Agent',
    agentType: 'ARCHITECTURE',
    description: 'Evaluates system architecture, design patterns, and modularity',
    personaAsset: 'assets/personas/agent-architecture.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Chaos Monkey Agent',
    agentType: 'CHAOS_MONKEY',
    description: 'Mutation testing to verify test suite catches real bugs',
    personaAsset: 'assets/personas/agent-chaos-monkey.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Hostile User Agent',
    agentType: 'HOSTILE_USER',
    description: 'Adversarial UX and API abuse testing',
    personaAsset: 'assets/personas/agent-hostile-user.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Compliance Auditor Agent',
    agentType: 'COMPLIANCE_AUDITOR',
    description: 'Regulatory compliance and data traceability auditing',
    personaAsset: 'assets/personas/agent-compliance-auditor.md',
  ),
  const _BuiltInAgentSpec(
    name: 'Load Saboteur Agent',
    agentType: 'LOAD_SABOTEUR',
    description: 'Adversarial performance and resilience testing',
    personaAsset: 'assets/personas/agent-load-saboteur.md',
  ),
];
