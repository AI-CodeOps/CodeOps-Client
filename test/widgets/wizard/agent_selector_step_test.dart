import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/widgets/wizard/agent_selector_step.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 800, child: child),
        ),
      );

  group('AgentSelectorStep', () {
    testWidgets('shows title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        AgentSelectorStep(
          selectedAgents: AgentType.values.toSet(),
          onToggle: (_) {},
          onSelectAll: () {},
          onSelectNone: () {},
        ),
      ));

      expect(find.text('Select Agents'), findsOneWidget);
    });

    testWidgets('shows agent count', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        AgentSelectorStep(
          selectedAgents: {AgentType.security, AgentType.codeQuality},
          onToggle: (_) {},
          onSelectAll: () {},
          onSelectNone: () {},
        ),
      ));

      expect(find.textContaining('2 of 12'), findsOneWidget);
    });

    testWidgets('shows All and None quick-select chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        AgentSelectorStep(
          selectedAgents: AgentType.values.toSet(),
          onToggle: (_) {},
          onSelectAll: () {},
          onSelectNone: () {},
        ),
      ));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('shows Recommended chip when callback provided', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        AgentSelectorStep(
          selectedAgents: AgentType.values.toSet(),
          onToggle: (_) {},
          onSelectAll: () {},
          onSelectNone: () {},
          onSelectRecommended: () {},
        ),
      ));

      expect(find.text('Recommended'), findsOneWidget);
    });

    testWidgets('shows all 12 agent names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        AgentSelectorStep(
          selectedAgents: AgentType.values.toSet(),
          onToggle: (_) {},
          onSelectAll: () {},
          onSelectNone: () {},
        ),
      ));

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Code Quality'), findsOneWidget);
      expect(find.text('Architecture'), findsOneWidget);
    });

    testWidgets('fires onToggle when agent tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      AgentType? toggled;
      await tester.pumpWidget(wrap(
        AgentSelectorStep(
          selectedAgents: AgentType.values.toSet(),
          onToggle: (a) => toggled = a,
          onSelectAll: () {},
          onSelectNone: () {},
        ),
      ));

      await tester.tap(find.text('Security'));
      expect(toggled, AgentType.security);
    });
  });
}
