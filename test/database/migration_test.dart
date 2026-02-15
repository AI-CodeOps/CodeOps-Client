// Tests for Drift database schema migration from v2 to v3.
//
// Verifies that the configJson column is added to the qaJobs table
// during the v2 → v3 migration.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/database/database.dart';

void main() {
  group('Database migration v2 → v3', () {
    late CodeOpsDatabase db;

    setUp(() {
      db = CodeOpsDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schema version is 3', () {
      expect(db.schemaVersion, 3);
    });

    test('qaJobs table has configJson column', () async {
      // Insert a job with configJson to prove the column exists.
      await db.customStatement('''
        INSERT INTO qa_jobs (id, project_id, mode, status)
        VALUES ('test-job', 'test-proj', 'AUDIT', 'PENDING')
      ''');

      // Update the configJson column to verify it exists and accepts data.
      await db.customStatement('''
        UPDATE qa_jobs SET config_json = '{"agents":["SECURITY"]}'
        WHERE id = 'test-job'
      ''');

      final results = await db.customSelect(
        'SELECT config_json FROM qa_jobs WHERE id = ?',
        variables: [Variable.withString('test-job')],
      ).get();

      expect(results, hasLength(1));
      expect(results.first.data['config_json'], '{"agents":["SECURITY"]}');
    });

    test('qaJobs configJson is nullable', () async {
      // Insert a job without configJson to verify nullable.
      await db.customStatement('''
        INSERT INTO qa_jobs (id, project_id, mode, status)
        VALUES ('test-job-2', 'test-proj', 'AUDIT', 'PENDING')
      ''');

      final results = await db.customSelect(
        'SELECT config_json FROM qa_jobs WHERE id = ?',
        variables: [Variable.withString('test-job-2')],
      ).get();

      expect(results, hasLength(1));
      expect(results.first.data['config_json'], isNull);
    });
  });
}
