// Tests for ScribeLanguagePicker (CS-010).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/scribe/scribe_language_picker.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('ScribeLanguagePicker', () {
    testWidgets('displays search field', (tester) async {
      await tester.pumpWidget(wrap(
        ScribeLanguagePicker(
          currentLanguage: 'dart',
          onSelect: (_) {},
          onClose: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Search languages...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays languages visible at top of list', (tester) async {
      await tester.pumpWidget(wrap(
        ScribeLanguagePicker(
          currentLanguage: 'dart',
          onSelect: (_) {},
          onClose: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Alphabetically sorted: Bash, C, C++, C#, CMake, CSS, Dart visible.
      expect(find.text('Bash'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
    });

    testWidgets('highlights current language with check icon',
        (tester) async {
      await tester.pumpWidget(wrap(
        ScribeLanguagePicker(
          currentLanguage: 'dart',
          onSelect: (_) {},
          onClose: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('filters languages by search query', (tester) async {
      await tester.pumpWidget(wrap(
        ScribeLanguagePicker(
          currentLanguage: 'dart',
          onSelect: (_) {},
          onClose: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'java',
      );
      await tester.pumpAndSettle();

      expect(find.text('Java'), findsOneWidget);
      expect(find.text('JavaScript'), findsOneWidget);
      // Other non-matching languages should not appear.
      expect(find.text('Python'), findsNothing);
    });

    testWidgets('shows no results for unmatched query', (tester) async {
      await tester.pumpWidget(wrap(
        ScribeLanguagePicker(
          currentLanguage: 'dart',
          onSelect: (_) {},
          onClose: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No matching languages'), findsOneWidget);
    });

    testWidgets('fires onSelect when language tapped', (tester) async {
      String? selected;
      await tester.pumpWidget(wrap(
        ScribeLanguagePicker(
          currentLanguage: 'dart',
          onSelect: (lang) => selected = lang,
          onClose: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Tap 'Bash' which is visible at the top of the alphabetical list.
      await tester.tap(find.text('Bash'));
      expect(selected, 'bash');
    });
  });
}
