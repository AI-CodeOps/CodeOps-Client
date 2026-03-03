// Widget tests for CodeGenerationPage.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/pages/courier/code_generation_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildCodegenPage() {
  return const ProviderScope(
    child: MaterialApp(
      home: CodeGenerationPage(),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('CodeGenerationPage', () {
    testWidgets('renders page header and title', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildCodegenPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('codegen_page_header')), findsOneWidget);
      expect(find.text('Code Generation'), findsOneWidget);
    });

    testWidgets('shows language selector sidebar', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildCodegenPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('language_selector')), findsOneWidget);
      // Should show all 12 languages
      expect(find.byKey(const Key('lang_tile_curl')), findsOneWidget);
      expect(find.byKey(const Key('lang_tile_pythonRequests')), findsOneWidget);
      expect(find.byKey(const Key('lang_tile_kotlin')), findsOneWidget);
    });

    testWidgets('displays generated code', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildCodegenPage());
      await tester.pumpAndSettle();

      // Default language is cURL, so code panel should show curl output
      expect(find.byKey(const Key('code_display_panel')), findsOneWidget);
      expect(find.byKey(const Key('code_content')), findsOneWidget);
    });

    testWidgets('switches language on tile tap', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildCodegenPage());
      await tester.pumpAndSettle();

      // Tap Python
      await tester.tap(find.byKey(const Key('lang_tile_pythonRequests')));
      await tester.pumpAndSettle();

      // Code toolbar should now show Python label
      expect(find.text('Python (Requests)'), findsOneWidget);
    });
  });
}
