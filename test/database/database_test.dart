// Tests for CodeOpsDatabase creation and basic operations.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/database/database.dart';

void main() {
  group('CodeOpsDatabase', () {
    late CodeOpsDatabase db;

    setUp(() {
      db = CodeOpsDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('can be instantiated with in-memory database', () {
      expect(db, isNotNull);
    });

    test('schema version is 4', () {
      expect(db.schemaVersion, 4);
    });

    test('clearAllTables does not throw', () async {
      await expectLater(db.clearAllTables(), completes);
    });

    test('has all 17 tables', () {
      expect(db.allTables.length, 17);
    });

    test('can insert and query a user', () async {
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'test-id',
            email: 'test@test.com',
            displayName: 'Test',
          ));
      final users = await db.select(db.users).get();
      expect(users.length, 1);
      expect(users.first.email, 'test@test.com');
    });

    test('clearAllTables removes all data', () async {
      await db.into(db.users).insert(UsersCompanion.insert(
            id: 'test-id',
            email: 'test@test.com',
            displayName: 'Test',
          ));
      await db.clearAllTables();
      final users = await db.select(db.users).get();
      expect(users, isEmpty);
    });
  });
}
