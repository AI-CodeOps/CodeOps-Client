import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/wizard/wizard_scaffold.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('WizardScaffold', () {
    final steps = [
      const WizardStepDef(
        title: 'Step 1',
        icon: Icons.looks_one,
        content: Text('Content 1'),
      ),
      const WizardStepDef(
        title: 'Step 2',
        icon: Icons.looks_two,
        content: Text('Content 2'),
        isValid: false,
      ),
      const WizardStepDef(
        title: 'Step 3',
        icon: Icons.looks_3,
        content: Text('Content 3'),
      ),
    ];

    testWidgets('shows title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        WizardScaffold(
          title: 'Test Wizard',
          steps: steps,
          currentStep: 0,
        ),
      ));

      expect(find.text('Test Wizard'), findsOneWidget);
    });

    testWidgets('shows step titles in sidebar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        WizardScaffold(
          title: 'Wizard',
          steps: steps,
          currentStep: 0,
        ),
      ));

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('Step 3'), findsOneWidget);
    });

    testWidgets('shows current step content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        WizardScaffold(
          title: 'Wizard',
          steps: steps,
          currentStep: 0,
        ),
      ));

      expect(find.text('Content 1'), findsOneWidget);
      expect(find.text('Content 2'), findsNothing);
    });

    testWidgets('hides Back button on first step', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        WizardScaffold(
          title: 'Wizard',
          steps: steps,
          currentStep: 0,
        ),
      ));

      expect(find.text('Back'), findsNothing);
    });

    testWidgets('shows Back button on non-first step', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        WizardScaffold(
          title: 'Wizard',
          steps: steps,
          currentStep: 1,
          onBack: () {},
        ),
      ));

      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('shows Launch button on last step', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        WizardScaffold(
          title: 'Wizard',
          steps: steps,
          currentStep: 2,
          launchLabel: 'Launch Audit',
          onLaunch: () {},
          onBack: () {},
        ),
      ));

      expect(find.text('Launch Audit'), findsOneWidget);
    });

    testWidgets('shows Cancel button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        WizardScaffold(
          title: 'Wizard',
          steps: steps,
          currentStep: 0,
          onCancel: () {},
        ),
      ));

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows Launching state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        WizardScaffold(
          title: 'Wizard',
          steps: steps,
          currentStep: 2,
          isLaunching: true,
          onLaunch: () {},
          onBack: () {},
        ),
      ));

      expect(find.text('Launching...'), findsOneWidget);
    });
  });

  group('WizardStepDef', () {
    test('isValid defaults to true', () {
      const step = WizardStepDef(
        title: 'Test',
        icon: Icons.check,
        content: Text('Content'),
      );
      expect(step.isValid, true);
    });
  });
}
