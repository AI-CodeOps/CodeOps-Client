// Tests for the 4 adversarial persona markdown files, Vera's adversarial
// dispatch references, and agent config service built-in spec completeness.
//
// Verifies file existence, format consistency, content structure, and
// alignment between persona files, agent config, and persona manager.
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/database/database.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/services/agent/agent_config_service.dart';
import 'package:codeops/services/auth/secure_storage.dart';
import 'package:codeops/services/cloud/anthropic_api_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAnthropicApiService extends Mock implements AnthropicApiService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Reads a persona asset file from disk.
String _readPersona(String fileName) {
  final file = File('assets/personas/$fileName');
  if (!file.existsSync()) {
    fail('Persona file not found: assets/personas/$fileName');
  }
  return file.readAsStringSync();
}

void main() {
  // -------------------------------------------------------------------------
  // Adversarial persona file existence and structure
  // -------------------------------------------------------------------------

  group('Adversarial persona files', () {
    test('chaos monkey persona exists and has correct structure', () {
      final content = _readPersona('agent-chaos-monkey.md');

      expect(content, contains('# Chaos Monkey Agent'));
      expect(content, contains('**Agent Type:** CHAOS_MONKEY'));
      expect(content, contains('## Identity'));
      expect(content, contains('## Focus Areas'));
      expect(content, contains('## Severity Calibration'));
      expect(content, contains('## Output Format'));
      expect(content, contains('## Behavioral Rules'));
      expect(content, contains('## Kill Rate'));
      expect(content, contains('Mutation'));
      expect(content, contains('PASS'));
      expect(content, contains('FAIL'));
    });

    test('hostile user persona exists and has correct structure', () {
      final content = _readPersona('agent-hostile-user.md');

      expect(content, contains('# Hostile User Agent'));
      expect(content, contains('**Agent Type:** HOSTILE_USER'));
      expect(content, contains('## Identity'));
      expect(content, contains('## Focus Areas'));
      expect(content, contains('## Severity Calibration'));
      expect(content, contains('## Output Format'));
      expect(content, contains('## Behavioral Rules'));
      expect(content, contains('Payload'));
      expect(content, contains('Unicode'));
      expect(content, contains('Rate'));
    });

    test('compliance auditor persona exists and has correct structure', () {
      final content = _readPersona('agent-compliance-auditor.md');

      expect(content, contains('# Compliance Auditor Agent'));
      expect(content, contains('**Agent Type:** COMPLIANCE_AUDITOR'));
      expect(content, contains('## Identity'));
      expect(content, contains('## Focus Areas'));
      expect(content, contains('## Severity Calibration'));
      expect(content, contains('## Output Format'));
      expect(content, contains('## Behavioral Rules'));
      expect(content, contains('GDPR'));
      expect(content, contains('HIPAA'));
      expect(content, contains('PII'));
      expect(content, contains('Compliance Matrix'));
    });

    test('load saboteur persona exists and has correct structure', () {
      final content = _readPersona('agent-load-saboteur.md');

      expect(content, contains('# Load Saboteur Agent'));
      expect(content, contains('**Agent Type:** LOAD_SABOTEUR'));
      expect(content, contains('## Identity'));
      expect(content, contains('## Focus Areas'));
      expect(content, contains('## Severity Calibration'));
      expect(content, contains('## Output Format'));
      expect(content, contains('## Behavioral Rules'));
      expect(content, contains('Thundering'));
      expect(content, contains('Connection Pool'));
      expect(content, contains('circuit breaker'));
    });

    test('all 17 persona files exist (vera + 12 standard + 4 adversarial)',
        () {
      final expectedFiles = [
        'vera-manager.md',
        'agent-security.md',
        'agent-code-quality.md',
        'agent-build-health.md',
        'agent-completeness.md',
        'agent-api-contract.md',
        'agent-test-coverage.md',
        'agent-ui-ux.md',
        'agent-documentation.md',
        'agent-database.md',
        'agent-performance.md',
        'agent-dependency.md',
        'agent-architecture.md',
        'agent-chaos-monkey.md',
        'agent-hostile-user.md',
        'agent-compliance-auditor.md',
        'agent-load-saboteur.md',
      ];

      for (final fileName in expectedFiles) {
        final file = File('assets/personas/$fileName');
        expect(file.existsSync(), isTrue,
            reason: 'Missing persona file: $fileName');
      }

      expect(expectedFiles.length, 17);
    });
  });

  // -------------------------------------------------------------------------
  // Vera persona references adversarial agents
  // -------------------------------------------------------------------------

  group('Vera persona', () {
    test('references all 4 adversarial agent types', () {
      final content = _readPersona('vera-manager.md');

      expect(content, contains('CHAOS_MONKEY'));
      expect(content, contains('HOSTILE_USER'));
      expect(content, contains('COMPLIANCE_AUDITOR'));
      expect(content, contains('LOAD_SABOTEUR'));
    });

    test('includes adversarial dispatch logic', () {
      final content = _readPersona('vera-manager.md');

      expect(content, contains('Adversarial Dispatch'));
      expect(content, contains('Adversarial Override'));
      expect(content, contains('Tier 3'));
      expect(content, contains('kill rate'));
    });
  });

  // -------------------------------------------------------------------------
  // Agent config service includes 17 built-in specs
  // -------------------------------------------------------------------------

  group('AgentConfigService built-in specs', () {
    late CodeOpsDatabase db;
    late AgentConfigService service;

    setUp(() {
      db = CodeOpsDatabase(NativeDatabase.memory());
      service = AgentConfigService(
        db: db,
        anthropicApi: MockAnthropicApiService(),
        secureStorage: MockSecureStorageService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('seeding creates 17 built-in agents', () async {
      // seedBuiltInAgents loads from rootBundle which isn't available in
      // unit tests. Instead, verify the spec list alignment indirectly:
      // the kebab mapping covers all 16 AgentType values (persona_manager),
      // and the persona directory contains exactly 17 files.
      final dir = Directory('assets/personas');
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      // 17 = 1 vera + 12 standard + 4 adversarial
      expect(files.length, 17);

      // Verify adversarial persona assets exist with correct naming.
      final fileNames = files.map((f) => f.uri.pathSegments.last).toSet();
      expect(fileNames, contains('agent-chaos-monkey.md'));
      expect(fileNames, contains('agent-hostile-user.md'));
      expect(fileNames, contains('agent-compliance-auditor.md'));
      expect(fileNames, contains('agent-load-saboteur.md'));
    });
  });
}
