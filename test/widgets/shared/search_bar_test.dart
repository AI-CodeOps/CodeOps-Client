// Widget tests for CodeOpsSearchBar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/shared/search_bar.dart';

void main() {
  Widget wrap({required ValueChanged<String> onChanged}) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CodeOpsSearchBar(
            onChanged: onChanged,
            debounceDuration: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }

  group('CodeOpsSearchBar', () {
    testWidgets('renders placeholder text', (tester) async {
      await tester.pumpWidget(wrap(onChanged: (_) {}));

      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('fires onChanged after debounce', (tester) async {
      String? result;
      await tester.pumpWidget(wrap(onChanged: (v) => result = v));

      await tester.enterText(find.byType(TextField), 'hello');
      // Before debounce
      expect(result, isNull);

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 150));
      expect(result, 'hello');
    });

    testWidgets('shows clear button when text entered', (tester) async {
      await tester.pumpWidget(wrap(onChanged: (_) {}));

      // Initially no clear button
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('clear button clears text and fires empty callback',
        (tester) async {
      String? result;
      await tester.pumpWidget(wrap(onChanged: (v) => result = v));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(result, '');
    });
  });
}
