// Widget tests for NotificationToast and showToast.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/shared/notification_toast.dart';
import 'package:codeops/theme/colors.dart';

void main() {
  group('NotificationToast', () {
    testWidgets('renders message and icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NotificationToast(
            message: 'Success!',
            icon: Icons.check_circle_outline,
            color: CodeOpsColors.success,
          ),
        ),
      ));

      expect(find.text('Success!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  group('showToast', () {
    testWidgets('shows snackbar with message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showToast(
                context,
                message: 'Test toast',
                type: ToastType.success,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Test toast'), findsOneWidget);
    });

    testWidgets('success toast has check icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showToast(
                context,
                message: 'Saved',
                type: ToastType.success,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('error toast has error icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showToast(
                context,
                message: 'Failed',
                type: ToastType.error,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
