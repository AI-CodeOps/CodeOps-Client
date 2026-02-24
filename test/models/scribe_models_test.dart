// Tests for ScribeTab and ScribeSettings models.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/scribe_models.dart';

void main() {
  group('ScribeTab', () {
    test('untitled creates tab with correct title pattern', () {
      final tab = ScribeTab.untitled(3);
      expect(tab.title, 'Untitled-3');
      expect(tab.content, isEmpty);
      expect(tab.language, 'plaintext');
      expect(tab.isDirty, isFalse);
      expect(tab.cursorLine, 0);
      expect(tab.cursorColumn, 0);
      expect(tab.scrollOffset, 0.0);
      expect(tab.filePath, isNull);
      expect(tab.id, isNotEmpty);
    });

    test('untitled generates unique IDs', () {
      final a = ScribeTab.untitled(1);
      final b = ScribeTab.untitled(2);
      expect(a.id, isNot(equals(b.id)));
    });

    test('fromFile detects language from file extension', () {
      final tab = ScribeTab.fromFile(
        filePath: '/home/user/main.dart',
        content: 'void main() {}',
      );
      expect(tab.title, 'main.dart');
      expect(tab.language, 'dart');
      expect(tab.content, 'void main() {}');
      expect(tab.filePath, '/home/user/main.dart');
      expect(tab.isDirty, isFalse);
    });

    test('fromFile detects SQL language', () {
      final tab = ScribeTab.fromFile(
        filePath: 'schema.sql',
        content: 'SELECT 1;',
      );
      expect(tab.language, 'sql');
      expect(tab.title, 'schema.sql');
    });

    test('fromFile handles file with no directory', () {
      final tab = ScribeTab.fromFile(
        filePath: 'readme.md',
        content: '# Hello',
      );
      expect(tab.title, 'readme.md');
      expect(tab.language, 'markdown');
    });

    test('copyWith preserves unchanged fields', () {
      final tab = ScribeTab.untitled(1);
      final copy = tab.copyWith(content: 'new content');
      expect(copy.id, tab.id);
      expect(copy.title, tab.title);
      expect(copy.content, 'new content');
      expect(copy.language, tab.language);
      expect(copy.isDirty, tab.isDirty);
      expect(copy.cursorLine, tab.cursorLine);
      expect(copy.cursorColumn, tab.cursorColumn);
      expect(copy.scrollOffset, tab.scrollOffset);
      expect(copy.createdAt, tab.createdAt);
    });

    test('copyWith replaces specified fields', () {
      final tab = ScribeTab.untitled(1);
      final copy = tab.copyWith(
        isDirty: true,
        cursorLine: 10,
        cursorColumn: 5,
        language: 'dart',
      );
      expect(copy.isDirty, isTrue);
      expect(copy.cursorLine, 10);
      expect(copy.cursorColumn, 5);
      expect(copy.language, 'dart');
    });

    test('isDirty defaults to false for new tabs', () {
      final tab = ScribeTab.untitled(1);
      expect(tab.isDirty, isFalse);
    });

    test('toJson produces valid map', () {
      final tab = ScribeTab.untitled(1);
      final json = tab.toJson();
      expect(json['id'], tab.id);
      expect(json['title'], 'Untitled-1');
      expect(json['content'], '');
      expect(json['language'], 'plaintext');
      expect(json['isDirty'], false);
      expect(json['cursorLine'], 0);
      expect(json['cursorColumn'], 0);
      expect(json['scrollOffset'], 0.0);
      expect(json['filePath'], isNull);
      expect(json['createdAt'], isNotNull);
      expect(json['lastModifiedAt'], isNotNull);
    });

    test('fromJson reconstructs tab correctly', () {
      final now = DateTime(2026, 2, 17, 12, 0, 0);
      final json = {
        'id': 'test-id',
        'title': 'main.dart',
        'filePath': '/src/main.dart',
        'content': 'void main() {}',
        'language': 'dart',
        'isDirty': true,
        'cursorLine': 5,
        'cursorColumn': 10,
        'scrollOffset': 42.5,
        'createdAt': now.toIso8601String(),
        'lastModifiedAt': now.toIso8601String(),
      };
      final tab = ScribeTab.fromJson(json);
      expect(tab.id, 'test-id');
      expect(tab.title, 'main.dart');
      expect(tab.filePath, '/src/main.dart');
      expect(tab.content, 'void main() {}');
      expect(tab.language, 'dart');
      expect(tab.isDirty, isTrue);
      expect(tab.cursorLine, 5);
      expect(tab.cursorColumn, 10);
      expect(tab.scrollOffset, 42.5);
      expect(tab.createdAt, now);
      expect(tab.lastModifiedAt, now);
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      final original = ScribeTab.fromFile(
        filePath: '/home/user/app.ts',
        content: 'const x = 1;',
      ).copyWith(isDirty: true, cursorLine: 3, cursorColumn: 7);

      final json = original.toJson();
      final restored = ScribeTab.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.filePath, original.filePath);
      expect(restored.content, original.content);
      expect(restored.language, original.language);
      expect(restored.isDirty, original.isDirty);
      expect(restored.cursorLine, original.cursorLine);
      expect(restored.cursorColumn, original.cursorColumn);
      expect(restored.scrollOffset, original.scrollOffset);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'id': 'test',
        'title': 'file.txt',
        'createdAt': DateTime.now().toIso8601String(),
        'lastModifiedAt': DateTime.now().toIso8601String(),
      };
      final tab = ScribeTab.fromJson(json);
      expect(tab.content, '');
      expect(tab.language, 'plaintext');
      expect(tab.isDirty, false);
      expect(tab.cursorLine, 0);
      expect(tab.cursorColumn, 0);
      expect(tab.scrollOffset, 0.0);
      expect(tab.filePath, isNull);
    });

    test('equality is based on id', () {
      final now = DateTime.now();
      final a = ScribeTab(
        id: 'same-id',
        title: 'A',
        createdAt: now,
        lastModifiedAt: now,
      );
      final b = ScribeTab(
        id: 'same-id',
        title: 'B',
        createdAt: now,
        lastModifiedAt: now,
      );
      expect(a, equals(b));
    });

    test('inequality when different id', () {
      final now = DateTime.now();
      final a = ScribeTab(
        id: 'id-1',
        title: 'A',
        createdAt: now,
        lastModifiedAt: now,
      );
      final b = ScribeTab(
        id: 'id-2',
        title: 'A',
        createdAt: now,
        lastModifiedAt: now,
      );
      expect(a, isNot(equals(b)));
    });

    test('default encoding is utf-8', () {
      final tab = ScribeTab.untitled(1);
      expect(tab.encoding, 'utf-8');
    });

    test('default lineEnding is lf', () {
      final tab = ScribeTab.untitled(1);
      expect(tab.lineEnding, 'lf');
    });

    test('copyWith preserves encoding and lineEnding', () {
      final now = DateTime.now();
      final tab = ScribeTab(
        id: 'test',
        title: 'test.txt',
        encoding: 'ascii',
        lineEnding: 'crlf',
        createdAt: now,
        lastModifiedAt: now,
      );
      final copy = tab.copyWith(title: 'renamed.txt');
      expect(copy.encoding, 'ascii');
      expect(copy.lineEnding, 'crlf');
    });

    test('copyWith can override encoding', () {
      final tab = ScribeTab.untitled(1);
      final copy = tab.copyWith(encoding: 'iso-8859-1');
      expect(copy.encoding, 'iso-8859-1');
    });

    test('copyWith can override lineEnding', () {
      final tab = ScribeTab.untitled(1);
      final copy = tab.copyWith(lineEnding: 'crlf');
      expect(copy.lineEnding, 'crlf');
    });

    test('toJson includes encoding and lineEnding', () {
      final tab = ScribeTab.untitled(1);
      final json = tab.toJson();
      expect(json['encoding'], 'utf-8');
      expect(json['lineEnding'], 'lf');
    });

    test('fromJson parses encoding and lineEnding', () {
      final json = {
        'id': 'test',
        'title': 'test.txt',
        'encoding': 'ascii',
        'lineEnding': 'crlf',
        'createdAt': '2026-02-23T00:00:00.000',
        'lastModifiedAt': '2026-02-23T00:00:00.000',
      };
      final tab = ScribeTab.fromJson(json);
      expect(tab.encoding, 'ascii');
      expect(tab.lineEnding, 'crlf');
    });

    test('fromJson defaults missing encoding to utf-8', () {
      final json = {
        'id': 'test',
        'title': 'test.txt',
        'createdAt': '2026-02-23T00:00:00.000',
        'lastModifiedAt': '2026-02-23T00:00:00.000',
      };
      final tab = ScribeTab.fromJson(json);
      expect(tab.encoding, 'utf-8');
    });

    test('fromJson defaults missing lineEnding to lf', () {
      final json = {
        'id': 'test',
        'title': 'test.txt',
        'createdAt': '2026-02-23T00:00:00.000',
        'lastModifiedAt': '2026-02-23T00:00:00.000',
      };
      final tab = ScribeTab.fromJson(json);
      expect(tab.lineEnding, 'lf');
    });

    test('fromFile auto-detects LF line endings', () {
      final tab = ScribeTab.fromFile(
        filePath: '/test/hello.dart',
        content: 'line1\nline2\nline3',
      );
      expect(tab.lineEnding, 'lf');
    });

    test('fromFile auto-detects CRLF line endings', () {
      final tab = ScribeTab.fromFile(
        filePath: '/test/hello.dart',
        content: 'line1\r\nline2\r\nline3',
      );
      expect(tab.lineEnding, 'crlf');
    });
  });

  group('ScribeSettings', () {
    test('default constructor has correct defaults', () {
      const settings = ScribeSettings();
      expect(settings.fontSize, 14.0);
      expect(settings.tabSize, 2);
      expect(settings.insertSpaces, isTrue);
      expect(settings.wordWrap, isFalse);
      expect(settings.showLineNumbers, isTrue);
      expect(settings.showMinimap, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const settings = ScribeSettings();
      final copy = settings.copyWith(fontSize: 18.0);
      expect(copy.fontSize, 18.0);
      expect(copy.tabSize, 2);
      expect(copy.insertSpaces, isTrue);
      expect(copy.wordWrap, isFalse);
      expect(copy.showLineNumbers, isTrue);
      expect(copy.showMinimap, isFalse);
    });

    test('copyWith replaces all fields', () {
      const settings = ScribeSettings();
      final copy = settings.copyWith(
        fontSize: 20.0,
        tabSize: 4,
        insertSpaces: false,
        wordWrap: true,
        showLineNumbers: false,
        showMinimap: true,
      );
      expect(copy.fontSize, 20.0);
      expect(copy.tabSize, 4);
      expect(copy.insertSpaces, isFalse);
      expect(copy.wordWrap, isTrue);
      expect(copy.showLineNumbers, isFalse);
      expect(copy.showMinimap, isTrue);
    });

    test('toJson produces valid map', () {
      const settings = ScribeSettings(fontSize: 16.0, tabSize: 4);
      final json = settings.toJson();
      expect(json['fontSize'], 16.0);
      expect(json['tabSize'], 4);
      expect(json['insertSpaces'], true);
      expect(json['wordWrap'], false);
      expect(json['showLineNumbers'], true);
      expect(json['showMinimap'], false);
    });

    test('fromJson reconstructs settings correctly', () {
      final json = {
        'fontSize': 18.0,
        'tabSize': 8,
        'insertSpaces': false,
        'wordWrap': true,
        'showLineNumbers': false,
        'showMinimap': true,
      };
      final settings = ScribeSettings.fromJson(json);
      expect(settings.fontSize, 18.0);
      expect(settings.tabSize, 8);
      expect(settings.insertSpaces, isFalse);
      expect(settings.wordWrap, isTrue);
      expect(settings.showLineNumbers, isFalse);
      expect(settings.showMinimap, isTrue);
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      const original = ScribeSettings(
        fontSize: 16.0,
        tabSize: 4,
        insertSpaces: false,
        wordWrap: true,
        showLineNumbers: false,
        showMinimap: true,
      );
      final json = original.toJson();
      final restored = ScribeSettings.fromJson(json);
      expect(restored.fontSize, original.fontSize);
      expect(restored.tabSize, original.tabSize);
      expect(restored.insertSpaces, original.insertSpaces);
      expect(restored.wordWrap, original.wordWrap);
      expect(restored.showLineNumbers, original.showLineNumbers);
      expect(restored.showMinimap, original.showMinimap);
    });

    test('fromJson handles missing fields with defaults', () {
      final settings = ScribeSettings.fromJson({});
      expect(settings.fontSize, 14.0);
      expect(settings.tabSize, 2);
      expect(settings.insertSpaces, isTrue);
      expect(settings.wordWrap, isFalse);
      expect(settings.showLineNumbers, isTrue);
      expect(settings.showMinimap, isFalse);
    });

    test('toJsonString produces valid JSON string', () {
      const settings = ScribeSettings(fontSize: 16.0);
      final jsonStr = settings.toJsonString();
      expect(jsonStr, contains('"fontSize":16.0'));
    });

    test('fromJsonString parses valid JSON string', () {
      const settings = ScribeSettings(fontSize: 20.0, tabSize: 8);
      final jsonStr = settings.toJsonString();
      final restored = ScribeSettings.fromJsonString(jsonStr);
      expect(restored.fontSize, 20.0);
      expect(restored.tabSize, 8);
    });
  });
}
