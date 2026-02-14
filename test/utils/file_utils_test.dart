// Tests for file utility functions.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/utils/file_utils.dart';

void main() {
  group('formatFileSize', () {
    test('formats bytes', () {
      expect(formatFileSize(500), '500 bytes');
    });

    test('formats kilobytes', () {
      expect(formatFileSize(1536), '1.5 KB');
    });

    test('formats megabytes', () {
      expect(formatFileSize(1258291), '1.2 MB');
    });

    test('formats gigabytes', () {
      expect(formatFileSize(1073741824), '1.0 GB');
    });

    test('formats zero', () {
      expect(formatFileSize(0), '0 bytes');
    });
  });

  group('getFileExtension', () {
    test('returns extension with dot', () {
      expect(getFileExtension('/foo/bar/MyFile.dart'), '.dart');
    });

    test('returns empty for no extension', () {
      expect(getFileExtension('Makefile'), '');
    });

    test('returns last extension for multiple dots', () {
      expect(getFileExtension('archive.tar.gz'), '.gz');
    });
  });

  group('getFileName', () {
    test('returns file name from path', () {
      expect(getFileName('/foo/bar/MyFile.dart'), 'MyFile.dart');
    });

    test('returns file name without directory', () {
      expect(getFileName('MyFile.dart'), 'MyFile.dart');
    });
  });
}
