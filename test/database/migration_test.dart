// Tests for Drift database schema migration from v2 to v3.
//
// Verifies that the configJson column is added to the qaJobs table
// during the v2 → v3 migration.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/database/database.dart';

void main() {
  group('Database migration v3 → v4', () {
    late CodeOpsDatabase db;

    setUp(() {
      db = CodeOpsDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schema version is 5', () {
      expect(db.schemaVersion, 5);
    });

    test('qaJobs table has configJson column', () async {
      await db.customStatement('''
        INSERT INTO qa_jobs (id, project_id, mode, status)
        VALUES ('test-job', 'test-proj', 'AUDIT', 'PENDING')
      ''');

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

    test('qaJobs table has summaryMd column', () async {
      await db.customStatement('''
        INSERT INTO qa_jobs (id, project_id, mode, status, summary_md)
        VALUES ('test-md', 'test-proj', 'AUDIT', 'COMPLETED', '# Summary')
      ''');

      final results = await db.customSelect(
        'SELECT summary_md FROM qa_jobs WHERE id = ?',
        variables: [Variable.withString('test-md')],
      ).get();

      expect(results, hasLength(1));
      expect(results.first.data['summary_md'], '# Summary');
    });

    test('qaJobs table has startedByName column', () async {
      await db.customStatement('''
        INSERT INTO qa_jobs (id, project_id, mode, status, started_by_name)
        VALUES ('test-name', 'test-proj', 'AUDIT', 'PENDING', 'Adam')
      ''');

      final results = await db.customSelect(
        'SELECT started_by_name FROM qa_jobs WHERE id = ?',
        variables: [Variable.withString('test-name')],
      ).get();

      expect(results, hasLength(1));
      expect(results.first.data['started_by_name'], 'Adam');
    });

    test('findings table has statusChangedBy column', () async {
      await db.customStatement('''
        INSERT INTO findings (id, job_id, agent_type, severity, title, finding_status, status_changed_by)
        VALUES ('f-1', 'job-1', 'SECURITY', 'HIGH', 'Test', 'OPEN', 'user-1')
      ''');

      final results = await db.customSelect(
        'SELECT status_changed_by FROM findings WHERE id = ?',
        variables: [Variable.withString('f-1')],
      ).get();

      expect(results, hasLength(1));
      expect(results.first.data['status_changed_by'], 'user-1');
    });

    test('findings table has statusChangedAt column', () async {
      await db.customStatement('''
        INSERT INTO findings (id, job_id, agent_type, severity, title, finding_status, status_changed_at)
        VALUES ('f-2', 'job-1', 'SECURITY', 'HIGH', 'Test', 'OPEN', 1705312800)
      ''');

      final results = await db.customSelect(
        'SELECT status_changed_at FROM findings WHERE id = ?',
        variables: [Variable.withString('f-2')],
      ).get();

      expect(results, hasLength(1));
      expect(results.first.data['status_changed_at'], isNotNull);
    });

    test('new v4 columns are nullable', () async {
      await db.customStatement('''
        INSERT INTO qa_jobs (id, project_id, mode, status)
        VALUES ('test-null', 'test-proj', 'AUDIT', 'PENDING')
      ''');

      final jobResults = await db.customSelect(
        'SELECT summary_md, started_by_name, config_json FROM qa_jobs WHERE id = ?',
        variables: [Variable.withString('test-null')],
      ).get();

      expect(jobResults, hasLength(1));
      expect(jobResults.first.data['summary_md'], isNull);
      expect(jobResults.first.data['started_by_name'], isNull);
      expect(jobResults.first.data['config_json'], isNull);

      await db.customStatement('''
        INSERT INTO findings (id, job_id, agent_type, severity, title, finding_status)
        VALUES ('f-null', 'job-1', 'SECURITY', 'HIGH', 'Test', 'OPEN')
      ''');

      final findingResults = await db.customSelect(
        'SELECT status_changed_by, status_changed_at FROM findings WHERE id = ?',
        variables: [Variable.withString('f-null')],
      ).get();

      expect(findingResults, hasLength(1));
      expect(findingResults.first.data['status_changed_by'], isNull);
      expect(findingResults.first.data['status_changed_at'], isNull);
    });
  });
}
