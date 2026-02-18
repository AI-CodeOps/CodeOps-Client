// Tests for ScribeTheme and ScribeThemeData.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/scribe/scribe_theme.dart';

void main() {
  group('ScribeTheme', () {
    group('dark', () {
      test('returns non-null ScribeThemeData with all fields set', () {
        final theme = ScribeTheme.dark();
        expect(theme.background, isNotNull);
        expect(theme.gutterBackground, isNotNull);
        expect(theme.gutterText, isNotNull);
        expect(theme.lineHighlight, isNotNull);
        expect(theme.selection, isNotNull);
        expect(theme.cursor, isNotNull);
        expect(theme.matchingBracket, isNotNull);
        expect(theme.fontFamily, isNotNull);
        expect(theme.defaultFontSize, isNotNull);
        expect(theme.keyword, isNotNull);
        expect(theme.string, isNotNull);
        expect(theme.number, isNotNull);
        expect(theme.comment, isNotNull);
        expect(theme.type, isNotNull);
        expect(theme.function, isNotNull);
        expect(theme.variable, isNotNull);
        expect(theme.operator, isNotNull);
        expect(theme.annotation, isNotNull);
        expect(theme.constant, isNotNull);
        expect(theme.tag, isNotNull);
        expect(theme.attribute, isNotNull);
      });

      test('uses JetBrains Mono font family', () {
        final theme = ScribeTheme.dark();
        expect(theme.fontFamily, 'JetBrains Mono');
      });

      test('background matches #1A1B2E', () {
        final theme = ScribeTheme.dark();
        expect(theme.background, const Color(0xFF1A1B2E));
      });

      test('cursor color is #00D9FF (secondary)', () {
        final theme = ScribeTheme.dark();
        expect(theme.cursor, const Color(0xFF00D9FF));
      });

      test('default font size is 14.0', () {
        final theme = ScribeTheme.dark();
        expect(theme.defaultFontSize, 14.0);
      });

      test('all syntax colors are non-null and distinct from background', () {
        final theme = ScribeTheme.dark();
        final syntaxColors = [
          theme.keyword,
          theme.string,
          theme.number,
          theme.comment,
          theme.type,
          theme.function,
          theme.variable,
          theme.operator,
          theme.annotation,
          theme.constant,
          theme.tag,
          theme.attribute,
        ];
        for (final color in syntaxColors) {
          expect(color, isNot(equals(theme.background)));
        }
      });

      test('keyword color matches Material Palenight purple', () {
        final theme = ScribeTheme.dark();
        expect(theme.keyword, const Color(0xFFC792EA));
      });

      test('string color matches Material Palenight green', () {
        final theme = ScribeTheme.dark();
        expect(theme.string, const Color(0xFFC3E88D));
      });

      test('comment color is muted gray-blue', () {
        final theme = ScribeTheme.dark();
        expect(theme.comment, const Color(0xFF546E7A));
      });
    });

    group('light', () {
      test('returns non-null ScribeThemeData with all fields set', () {
        final theme = ScribeTheme.light();
        expect(theme.background, isNotNull);
        expect(theme.gutterBackground, isNotNull);
        expect(theme.gutterText, isNotNull);
        expect(theme.lineHighlight, isNotNull);
        expect(theme.selection, isNotNull);
        expect(theme.cursor, isNotNull);
        expect(theme.matchingBracket, isNotNull);
        expect(theme.fontFamily, isNotNull);
        expect(theme.defaultFontSize, isNotNull);
        expect(theme.keyword, isNotNull);
        expect(theme.string, isNotNull);
        expect(theme.number, isNotNull);
        expect(theme.comment, isNotNull);
        expect(theme.type, isNotNull);
        expect(theme.function, isNotNull);
        expect(theme.variable, isNotNull);
        expect(theme.operator, isNotNull);
        expect(theme.annotation, isNotNull);
        expect(theme.constant, isNotNull);
        expect(theme.tag, isNotNull);
        expect(theme.attribute, isNotNull);
      });

      test('uses JetBrains Mono font family', () {
        final theme = ScribeTheme.light();
        expect(theme.fontFamily, 'JetBrains Mono');
      });

      test('default font size is 14.0', () {
        final theme = ScribeTheme.light();
        expect(theme.defaultFontSize, 14.0);
      });
    });

    group('dark vs light', () {
      test('return different background colors', () {
        final dark = ScribeTheme.dark();
        final light = ScribeTheme.light();
        expect(dark.background, isNot(equals(light.background)));
      });

      test('return different cursor colors', () {
        final dark = ScribeTheme.dark();
        final light = ScribeTheme.light();
        expect(dark.cursor, isNot(equals(light.cursor)));
      });

      test('return different gutter backgrounds', () {
        final dark = ScribeTheme.dark();
        final light = ScribeTheme.light();
        expect(
          dark.gutterBackground,
          isNot(equals(light.gutterBackground)),
        );
      });
    });

    group('toHighlightThemeMap', () {
      test('returns a non-empty map', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, isNotEmpty);
      });

      test('contains root key with background color', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('root'));
        expect(map['root']!.backgroundColor, theme.background);
      });

      test('contains keyword entry', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('keyword'));
        expect(map['keyword']!.color, theme.keyword);
      });

      test('contains string entry', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('string'));
        expect(map['string']!.color, theme.string);
      });

      test('contains comment entry with italic style', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('comment'));
        expect(map['comment']!.color, theme.comment);
        expect(map['comment']!.fontStyle, FontStyle.italic);
      });

      test('contains number entry', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('number'));
        expect(map['number']!.color, theme.number);
      });

      test('contains type entry', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('type'));
        expect(map['type']!.color, theme.type);
      });

      test('contains title entry for functions', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('title'));
        expect(map['title']!.color, theme.function);
      });

      test('contains meta entry for annotations', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('meta'));
        expect(map['meta']!.color, theme.annotation);
      });

      test('contains name entry for tags', () {
        final theme = ScribeTheme.dark();
        final map = theme.toHighlightThemeMap();
        expect(map, contains('name'));
        expect(map['name']!.color, theme.tag);
      });

      test('light theme also produces valid map', () {
        final theme = ScribeTheme.light();
        final map = theme.toHighlightThemeMap();
        expect(map, isNotEmpty);
        expect(map, contains('root'));
        expect(map, contains('keyword'));
        expect(map, contains('string'));
      });
    });
  });
}
