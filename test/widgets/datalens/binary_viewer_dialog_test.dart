// Widget tests for BinaryViewerDialog.
//
// Verifies dialog rendering, hex dump display, title bar, size info,
// toolbar buttons, and footer.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/datalens/binary_viewer_dialog.dart';

Widget _createWidget({
  Uint8List? data,
  String columnName = 'avatar',
  ValueChanged<Uint8List>? onUpload,
}) {
  final bytes = data ?? Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]);

  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => BinaryViewerDialog(
              data: bytes,
              columnName: columnName,
              onUpload: onUpload,
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

void main() {
  group('BinaryViewerDialog', () {
    testWidgets('renders dialog with column name and BINARY badge',
        (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('avatar'), findsOneWidget);
      expect(find.text('BINARY'), findsOneWidget);
    });

    testWidgets('shows size info in toolbar', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('5 bytes'), findsOneWidget);
    });

    testWidgets('shows hex dump rows', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should show the offset "00000000" for the first row.
      expect(find.textContaining('00000000'), findsOneWidget);
      // Should show "Hello" in ASCII column.
      expect(find.textContaining('Hello'), findsOneWidget);
    });

    testWidgets('shows Copy Hex button', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Copy Hex'), findsOneWidget);
    });

    testWidgets('shows Close button', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('shows Upload button when onUpload provided', (tester) async {
      await tester.pumpWidget(_createWidget(onUpload: (_) {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('hides Upload button when onUpload null', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Upload'), findsNothing);
    });

    testWidgets('shows footer with byte and row counts', (tester) async {
      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('5 bytes'), findsWidgets);
      expect(find.textContaining('1 rows'), findsOneWidget);
    });
  });
}
