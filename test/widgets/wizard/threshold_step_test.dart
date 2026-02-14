import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/wizard_providers.dart';
import 'package:codeops/widgets/wizard/threshold_step.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 800, child: child),
        ),
      );

  group('ThresholdStep', () {
    testWidgets('shows title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ThresholdStep(
          config: const JobConfig(),
          onConfigChanged: (_) {},
        ),
      ));

      expect(find.text('Configuration'), findsOneWidget);
    });

    testWidgets('shows subtitle', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ThresholdStep(
          config: const JobConfig(),
          onConfigChanged: (_) {},
        ),
      ));

      expect(find.text('Fine-tune agent behavior and thresholds.'),
          findsOneWidget);
    });

    testWidgets('shows slider labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ThresholdStep(
          config: const JobConfig(),
          onConfigChanged: (_) {},
        ),
      ));

      expect(find.text('Concurrent Agents'), findsOneWidget);
      expect(find.text('Agent Timeout (minutes)'), findsOneWidget);
      expect(find.text('Max Turns'), findsOneWidget);
    });

    testWidgets('shows Claude Model dropdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ThresholdStep(
          config: const JobConfig(),
          onConfigChanged: (_) {},
        ),
      ));

      expect(find.text('Claude Model'), findsOneWidget);
    });

    testWidgets('shows threshold section', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ThresholdStep(
          config: const JobConfig(),
          onConfigChanged: (_) {},
        ),
      ));

      expect(find.text('Health Score Thresholds'), findsOneWidget);
      expect(find.text('Pass threshold:'), findsOneWidget);
      expect(find.text('Warn threshold:'), findsOneWidget);
    });

    testWidgets('shows additional context field', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ThresholdStep(
          config: const JobConfig(),
          onConfigChanged: (_) {},
        ),
      ));

      expect(find.text('Additional Context'), findsOneWidget);
    });

    testWidgets('shows 3 Slider widgets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ThresholdStep(
          config: const JobConfig(),
          onConfigChanged: (_) {},
        ),
      ));

      expect(find.byType(Slider), findsNWidgets(3));
    });
  });
}
