// Tests for the enhanced ScribeStatusBar (CS-010).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/scribe/scribe_status_bar.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  ScribeStatusBar createStatusBar({
    int cursorLine = 0,
    int cursorColumn = 0,
    String language = 'dart',
    int selectedChars = 0,
    int selectedLines = 0,
    bool insertSpaces = true,
    int tabSize = 2,
    String encoding = 'utf-8',
    String lineEnding = 'lf',
    String content = '',
    ValueChanged<String>? onLanguageChanged,
    ValueChanged<bool>? onInsertSpacesChanged,
    ValueChanged<int>? onTabSizeChanged,
    ValueChanged<String>? onEncodingChanged,
    ValueChanged<String>? onLineEndingChanged,
  }) {
    return ScribeStatusBar(
      cursorLine: cursorLine,
      cursorColumn: cursorColumn,
      language: language,
      onLanguageChanged: onLanguageChanged ?? (_) {},
      selectedChars: selectedChars,
      selectedLines: selectedLines,
      insertSpaces: insertSpaces,
      tabSize: tabSize,
      onInsertSpacesChanged: onInsertSpacesChanged ?? (_) {},
      onTabSizeChanged: onTabSizeChanged ?? (_) {},
      encoding: encoding,
      onEncodingChanged: onEncodingChanged ?? (_) {},
      lineEnding: lineEnding,
      onLineEndingChanged: onLineEndingChanged ?? (_) {},
      content: content,
    );
  }

  group('ScribeStatusBar', () {
    testWidgets('displays language name', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar(language: 'dart')));
      await tester.pumpAndSettle();

      expect(find.text('Dart'), findsOneWidget);
    });

    testWidgets('displays cursor position as 1-based', (tester) async {
      await tester
          .pumpWidget(wrap(createStatusBar(cursorLine: 5, cursorColumn: 10)));
      await tester.pumpAndSettle();

      expect(find.text('Ln 6, Col 11'), findsOneWidget);
    });

    testWidgets('hides selection info when no selection', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar(selectedChars: 0)));
      await tester.pumpAndSettle();

      expect(find.textContaining('selected'), findsNothing);
      expect(find.textContaining('chars'), findsNothing);
    });

    testWidgets('shows single-line selection info', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar(
        selectedChars: 15,
        selectedLines: 1,
      )));
      await tester.pumpAndSettle();

      expect(find.text('15 selected'), findsOneWidget);
    });

    testWidgets('shows multi-line selection info', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar(
        selectedChars: 42,
        selectedLines: 3,
      )));
      await tester.pumpAndSettle();

      expect(find.text('42 chars (3 lines)'), findsOneWidget);
    });

    testWidgets('displays spaces indentation indicator', (tester) async {
      await tester.pumpWidget(
          wrap(createStatusBar(insertSpaces: true, tabSize: 4)));
      await tester.pumpAndSettle();

      expect(find.text('Spaces: 4'), findsOneWidget);
    });

    testWidgets('displays tabs indentation indicator', (tester) async {
      await tester.pumpWidget(
          wrap(createStatusBar(insertSpaces: false, tabSize: 4)));
      await tester.pumpAndSettle();

      expect(find.text('Tabs: 4'), findsOneWidget);
    });

    testWidgets('displays encoding in uppercase', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar(encoding: 'utf-8')));
      await tester.pumpAndSettle();

      expect(find.text('UTF-8'), findsOneWidget);
    });

    testWidgets('displays LF line ending', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar(lineEnding: 'lf')));
      await tester.pumpAndSettle();

      expect(find.text('LF'), findsOneWidget);
    });

    testWidgets('displays CRLF line ending', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar(lineEnding: 'crlf')));
      await tester.pumpAndSettle();

      expect(find.text('CRLF'), findsOneWidget);
    });

    testWidgets('displays file size in bytes', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar(content: 'Hello')));
      await tester.pumpAndSettle();

      expect(find.text('5 B'), findsOneWidget);
    });

    testWidgets('displays file size in KB', (tester) async {
      final content = 'A' * 2048;
      await tester.pumpWidget(wrap(createStatusBar(content: content)));
      await tester.pumpAndSettle();

      expect(find.text('2.0 KB'), findsOneWidget);
    });

    testWidgets('displays file size in MB', (tester) async {
      final content = 'A' * 1048576;
      await tester.pumpWidget(wrap(createStatusBar(content: content)));
      await tester.pumpAndSettle();

      expect(find.text('1.0 MB'), findsOneWidget);
    });

    testWidgets('language button shows tooltip', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar()));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Tooltip && w.message == 'Select language mode',
        ),
        findsOneWidget,
      );
    });

    testWidgets('indentation button opens popup on tap', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spaces: 2'));
      await tester.pumpAndSettle();

      expect(find.text('Indent Using Spaces'), findsOneWidget);
      expect(find.text('Indent Using Tabs'), findsOneWidget);
      expect(find.text('Tab Size: 2'), findsOneWidget);
      expect(find.text('Tab Size: 4'), findsOneWidget);
      expect(find.text('Tab Size: 8'), findsOneWidget);
    });

    testWidgets('encoding button opens popup on tap', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('UTF-8'));
      await tester.pumpAndSettle();

      expect(find.text('ASCII'), findsOneWidget);
      expect(find.text('ISO-8859-1'), findsOneWidget);
      expect(find.text('UTF-16'), findsOneWidget);
    });

    testWidgets('line ending button opens popup on tap', (tester) async {
      await tester.pumpWidget(wrap(createStatusBar()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('LF'));
      await tester.pumpAndSettle();

      expect(find.text('LF (Unix/macOS)'), findsOneWidget);
      expect(find.text('CRLF (Windows)'), findsOneWidget);
    });

    testWidgets('encoding popup fires onEncodingChanged', (tester) async {
      String? newEncoding;
      await tester.pumpWidget(wrap(createStatusBar(
        onEncodingChanged: (enc) => newEncoding = enc,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('UTF-8'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ASCII'));
      await tester.pumpAndSettle();

      expect(newEncoding, 'ascii');
    });

    testWidgets('line ending popup fires onLineEndingChanged', (tester) async {
      String? newLineEnding;
      await tester.pumpWidget(wrap(createStatusBar(
        onLineEndingChanged: (le) => newLineEnding = le,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('LF'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CRLF (Windows)'));
      await tester.pumpAndSettle();

      expect(newLineEnding, 'crlf');
    });

    testWidgets('indentation popup fires onTabSizeChanged', (tester) async {
      int? newTabSize;
      await tester.pumpWidget(wrap(createStatusBar(
        onTabSizeChanged: (size) => newTabSize = size,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spaces: 2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tab Size: 4'));
      await tester.pumpAndSettle();

      expect(newTabSize, 4);
    });

    testWidgets('indentation popup fires onInsertSpacesChanged',
        (tester) async {
      bool? useSpaces;
      await tester.pumpWidget(wrap(createStatusBar(
        onInsertSpacesChanged: (val) => useSpaces = val,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spaces: 2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Indent Using Tabs'));
      await tester.pumpAndSettle();

      expect(useSpaces, false);
    });

    testWidgets('cursor at 0,0 displays as Ln 1, Col 1', (tester) async {
      await tester
          .pumpWidget(wrap(createStatusBar(cursorLine: 0, cursorColumn: 0)));
      await tester.pumpAndSettle();

      expect(find.text('Ln 1, Col 1'), findsOneWidget);
    });
  });
}
