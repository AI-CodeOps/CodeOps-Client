// Widget tests for AnomalyBaselineDialog.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/logger/anomaly_baseline_dialog.dart';

void main() {
  Widget createWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AnomalyBaselineDialog(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('AnomalyBaselineDialog', () {
    testWidgets('renders create dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Create Baseline'), findsOneWidget);
    });

    testWidgets('shows service name field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Service Name'), findsOneWidget);
    });

    testWidgets('shows metric name field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Metric Name'), findsOneWidget);
    });

    testWidgets('shows sensitivity slider', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Sensitivity: '), findsOneWidget);
    });
  });
}
