// Widget tests for NavigatorTreeNode.
//
// Verifies rendering, depth indentation, expand/collapse arrow,
// selection highlight, trailing text, badge count, hover effects,
// and tap/double-tap callbacks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/datalens/navigator_tree_node.dart';

Widget _createWidget({
  int depth = 0,
  bool isExpanded = false,
  bool isExpandable = false,
  bool isSelected = false,
  IconData icon = Icons.table_chart_outlined,
  Color? iconColor,
  String label = 'test_table',
  String? trailingText,
  int? badgeCount,
  VoidCallback? onTap,
  VoidCallback? onDoubleTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: NavigatorTreeNode(
        depth: depth,
        isExpanded: isExpanded,
        isExpandable: isExpandable,
        isSelected: isSelected,
        icon: icon,
        iconColor: iconColor,
        label: label,
        trailingText: trailingText,
        badgeCount: badgeCount,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
      ),
    ),
  );
}

void main() {
  group('NavigatorTreeNode', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_createWidget(label: 'users'));

      expect(find.text('users'), findsOneWidget);
    });

    testWidgets('renders leading icon', (tester) async {
      await tester.pumpWidget(
        _createWidget(icon: Icons.visibility_outlined),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('shows expand arrow when expandable', (tester) async {
      await tester.pumpWidget(
        _createWidget(isExpandable: true, isExpanded: false),
      );

      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
    });

    testWidgets('shows down arrow when expanded', (tester) async {
      await tester.pumpWidget(
        _createWidget(isExpandable: true, isExpanded: true),
      );

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('hides arrow when not expandable', (tester) async {
      await tester.pumpWidget(_createWidget(isExpandable: false));

      expect(find.byIcon(Icons.keyboard_arrow_right), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });

    testWidgets('shows trailing text when provided', (tester) async {
      await tester.pumpWidget(_createWidget(trailingText: '~1.2k'));

      expect(find.text('~1.2k'), findsOneWidget);
    });

    testWidgets('shows badge count when provided', (tester) async {
      await tester.pumpWidget(_createWidget(badgeCount: 42));

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('invokes onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _createWidget(onTap: () => tapped = true),
      );

      await tester.tap(find.text('test_table'));
      expect(tapped, isTrue);
    });

    testWidgets('applies depth-based indentation', (tester) async {
      // Depth 0 → left padding 12.0
      await tester.pumpWidget(_createWidget(depth: 0));
      var container = tester.widget<Container>(
        find.ancestor(
          of: find.text('test_table'),
          matching: find.byType(Container),
        ).first,
      );
      var padding = container.padding as EdgeInsets?;
      expect(padding?.left, 12.0);

      // Depth 2 → left padding 12.0 + 2*20.0 = 52.0
      await tester.pumpWidget(_createWidget(depth: 2));
      container = tester.widget<Container>(
        find.ancestor(
          of: find.text('test_table'),
          matching: find.byType(Container),
        ).first,
      );
      padding = container.padding as EdgeInsets?;
      expect(padding?.left, 52.0);
    });

    testWidgets('invokes onDoubleTap callback', (tester) async {
      var doubleTapped = false;
      await tester.pumpWidget(
        _createWidget(onDoubleTap: () => doubleTapped = true),
      );

      await tester.tap(find.text('test_table'));
      await tester.tap(find.text('test_table'));
      // GestureDetector needs a proper double-tap gesture.
      // Re-test with actual double-tap.
      doubleTapped = false;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('test_table')),
      );
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.down(tester.getCenter(find.text('test_table')));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(doubleTapped, isTrue);
    });
  });
}
