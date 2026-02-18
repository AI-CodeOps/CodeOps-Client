// Tests for ScribeLanguage utility.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/scribe/scribe_language.dart';

void main() {
  group('ScribeLanguage', () {
    group('fromFileName', () {
      test('maps .dart extension to dart', () {
        expect(ScribeLanguage.fromFileName('main.dart'), 'dart');
      });

      test('maps .java extension to java', () {
        expect(ScribeLanguage.fromFileName('App.java'), 'java');
      });

      test('maps .js extension to javascript', () {
        expect(ScribeLanguage.fromFileName('index.js'), 'javascript');
      });

      test('maps .mjs extension to javascript', () {
        expect(ScribeLanguage.fromFileName('module.mjs'), 'javascript');
      });

      test('maps .cjs extension to javascript', () {
        expect(ScribeLanguage.fromFileName('config.cjs'), 'javascript');
      });

      test('maps .ts extension to typescript', () {
        expect(ScribeLanguage.fromFileName('app.ts'), 'typescript');
      });

      test('maps .tsx extension to typescript', () {
        expect(ScribeLanguage.fromFileName('component.tsx'), 'typescript');
      });

      test('maps .py extension to python', () {
        expect(ScribeLanguage.fromFileName('script.py'), 'python');
      });

      test('maps .rb extension to ruby', () {
        expect(ScribeLanguage.fromFileName('app.rb'), 'ruby');
      });

      test('maps .rs extension to rust', () {
        expect(ScribeLanguage.fromFileName('main.rs'), 'rust');
      });

      test('maps .go extension to go', () {
        expect(ScribeLanguage.fromFileName('main.go'), 'go');
      });

      test('maps .swift extension to swift', () {
        expect(ScribeLanguage.fromFileName('ViewController.swift'), 'swift');
      });

      test('maps .kt extension to kotlin', () {
        expect(ScribeLanguage.fromFileName('Main.kt'), 'kotlin');
      });

      test('maps .c extension to c', () {
        expect(ScribeLanguage.fromFileName('main.c'), 'c');
      });

      test('maps .cpp extension to cpp', () {
        expect(ScribeLanguage.fromFileName('main.cpp'), 'cpp');
      });

      test('maps .cs extension to csharp', () {
        expect(ScribeLanguage.fromFileName('Program.cs'), 'csharp');
      });

      test('maps .css extension to css', () {
        expect(ScribeLanguage.fromFileName('styles.css'), 'css');
      });

      test('maps .html extension to html', () {
        expect(ScribeLanguage.fromFileName('index.html'), 'html');
      });

      test('maps .xml extension to xml', () {
        expect(ScribeLanguage.fromFileName('config.xml'), 'xml');
      });

      test('maps .json extension to json', () {
        expect(ScribeLanguage.fromFileName('data.json'), 'json');
      });

      test('maps .yaml extension to yaml', () {
        expect(ScribeLanguage.fromFileName('config.yaml'), 'yaml');
      });

      test('maps .yml extension to yaml', () {
        expect(ScribeLanguage.fromFileName('docker-compose.yml'), 'yaml');
      });

      test('maps .md extension to markdown', () {
        expect(ScribeLanguage.fromFileName('README.md'), 'markdown');
      });

      test('maps .sql extension to sql', () {
        expect(ScribeLanguage.fromFileName('schema.sql'), 'sql');
      });

      test('maps .sh extension to bash', () {
        expect(ScribeLanguage.fromFileName('deploy.sh'), 'bash');
      });

      test('maps .php extension to php', () {
        expect(ScribeLanguage.fromFileName('index.php'), 'php');
      });

      test('maps .lua extension to lua', () {
        expect(ScribeLanguage.fromFileName('config.lua'), 'lua');
      });

      test('maps .m extension to objectivec', () {
        expect(ScribeLanguage.fromFileName('AppDelegate.m'), 'objectivec');
      });

      test('maps .pl extension to perl', () {
        expect(ScribeLanguage.fromFileName('script.pl'), 'perl');
      });

      test('maps .graphql extension to graphql', () {
        expect(ScribeLanguage.fromFileName('schema.graphql'), 'graphql');
      });

      test('maps .groovy extension to groovy', () {
        expect(ScribeLanguage.fromFileName('build.groovy'), 'groovy');
      });

      test('maps .scala extension to scala', () {
        expect(ScribeLanguage.fromFileName('Main.scala'), 'scala');
      });

      test('maps .toml extension to toml', () {
        expect(ScribeLanguage.fromFileName('Cargo.toml'), 'toml');
      });

      test('maps .dockerfile extension to dockerfile', () {
        expect(ScribeLanguage.fromFileName('app.dockerfile'), 'dockerfile');
      });

      test('returns plaintext for unknown extension', () {
        expect(ScribeLanguage.fromFileName('data.xyz'), 'plaintext');
        expect(ScribeLanguage.fromFileName('file.unknown'), 'plaintext');
      });

      test('handles Dockerfile (no extension)', () {
        expect(ScribeLanguage.fromFileName('Dockerfile'), 'dockerfile');
      });

      test('handles Makefile (no extension)', () {
        expect(ScribeLanguage.fromFileName('Makefile'), 'makefile');
      });

      test('handles files with no extension that are not special', () {
        expect(ScribeLanguage.fromFileName('NOTES'), 'plaintext');
      });

      test('is case-insensitive for extensions', () {
        expect(ScribeLanguage.fromFileName('Main.DART'), 'dart');
        expect(ScribeLanguage.fromFileName('App.Java'), 'java');
        expect(ScribeLanguage.fromFileName('style.CSS'), 'css');
      });

      test('is case-insensitive for special file names', () {
        expect(ScribeLanguage.fromFileName('dockerfile'), 'dockerfile');
        expect(ScribeLanguage.fromFileName('DOCKERFILE'), 'dockerfile');
        expect(ScribeLanguage.fromFileName('makefile'), 'makefile');
        expect(ScribeLanguage.fromFileName('MAKEFILE'), 'makefile');
      });

      test('handles paths with directories', () {
        expect(ScribeLanguage.fromFileName('src/main/App.java'), 'java');
        expect(
          ScribeLanguage.fromFileName('lib/widgets/editor.dart'),
          'dart',
        );
        expect(
          ScribeLanguage.fromFileName('config/docker/Dockerfile'),
          'dockerfile',
        );
      });
    });

    group('supportedLanguages', () {
      test('returns a sorted list', () {
        final languages = ScribeLanguage.supportedLanguages;
        final sorted = List<String>.from(languages)..sort();
        expect(languages, sorted);
      });

      test('contains at least 30 entries', () {
        expect(ScribeLanguage.supportedLanguages.length, greaterThanOrEqualTo(30));
      });

      test('contains key languages', () {
        final languages = ScribeLanguage.supportedLanguages;
        expect(languages, contains('dart'));
        expect(languages, contains('java'));
        expect(languages, contains('javascript'));
        expect(languages, contains('python'));
        expect(languages, contains('sql'));
        expect(languages, contains('yaml'));
        expect(languages, contains('json'));
        expect(languages, contains('typescript'));
        expect(languages, contains('rust'));
        expect(languages, contains('go'));
      });
    });

    group('displayName', () {
      test('returns human-readable names for all languages', () {
        for (final lang in ScribeLanguage.supportedLanguages) {
          final name = ScribeLanguage.displayName(lang);
          expect(name, isNotEmpty, reason: 'displayName for $lang');
        }
      });

      test('returns correct names for common languages', () {
        expect(ScribeLanguage.displayName('javascript'), 'JavaScript');
        expect(ScribeLanguage.displayName('typescript'), 'TypeScript');
        expect(ScribeLanguage.displayName('csharp'), 'C#');
        expect(ScribeLanguage.displayName('cpp'), 'C++');
        expect(ScribeLanguage.displayName('sql'), 'SQL');
        expect(ScribeLanguage.displayName('html'), 'HTML');
        expect(ScribeLanguage.displayName('css'), 'CSS');
        expect(ScribeLanguage.displayName('json'), 'JSON');
        expect(ScribeLanguage.displayName('yaml'), 'YAML');
        expect(ScribeLanguage.displayName('xml'), 'XML');
        expect(ScribeLanguage.displayName('dart'), 'Dart');
        expect(ScribeLanguage.displayName('python'), 'Python');
        expect(ScribeLanguage.displayName('plaintext'), 'Plain Text');
        expect(ScribeLanguage.displayName('objectivec'), 'Objective-C');
        expect(ScribeLanguage.displayName('graphql'), 'GraphQL');
      });

      test('returns identifier for unknown language', () {
        expect(ScribeLanguage.displayName('fakeLang'), 'fakeLang');
      });
    });

    group('extensions', () {
      test('returns non-empty list for most supported languages', () {
        final languagesWithExtensions = ScribeLanguage.supportedLanguages
            .where((lang) =>
                lang != 'cmake' && lang != 'makefile')
            .toList();

        for (final lang in languagesWithExtensions) {
          final exts = ScribeLanguage.extensions(lang);
          expect(
            exts,
            isNotEmpty,
            reason: 'extensions for $lang should be non-empty',
          );
        }
      });

      test('returns correct extensions for dart', () {
        expect(ScribeLanguage.extensions('dart'), ['.dart']);
      });

      test('returns correct extensions for javascript', () {
        final exts = ScribeLanguage.extensions('javascript');
        expect(exts, contains('.js'));
        expect(exts, contains('.mjs'));
        expect(exts, contains('.cjs'));
      });

      test('returns correct extensions for typescript', () {
        final exts = ScribeLanguage.extensions('typescript');
        expect(exts, contains('.ts'));
        expect(exts, contains('.tsx'));
      });

      test('returns empty list for unknown language', () {
        expect(ScribeLanguage.extensions('fakeLang'), isEmpty);
      });
    });

    group('highlightModeKeys', () {
      test('maps html to xml', () {
        expect(ScribeLanguage.highlightModeKeys['html'], 'xml');
      });

      test('maps toml to ini', () {
        expect(ScribeLanguage.highlightModeKeys['toml'], 'ini');
      });

      test('maps shell to shell', () {
        expect(ScribeLanguage.highlightModeKeys['shell'], 'shell');
      });

      test('maps dart to dart', () {
        expect(ScribeLanguage.highlightModeKeys['dart'], 'dart');
      });

      test('has an entry for every supported language', () {
        for (final lang in ScribeLanguage.supportedLanguages) {
          expect(
            ScribeLanguage.highlightModeKeys,
            contains(lang),
            reason: 'highlightModeKeys should contain $lang',
          );
        }
      });
    });
  });
}
