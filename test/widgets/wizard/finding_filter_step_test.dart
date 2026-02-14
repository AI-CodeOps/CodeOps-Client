import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/finding.dart';
import 'package:codeops/widgets/wizard/finding_filter_step.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 800, child: child),
        ),
      );

  final sampleFindings = [
    const Finding(
      id: 'f1',
      jobId: 'j1',
      agentType: AgentType.security,
      severity: Severity.critical,
      title: 'SQL injection vulnerability',
      filePath: 'src/db/query.dart',
      status: FindingStatus.open,
    ),
    const Finding(
      id: 'f2',
      jobId: 'j1',
      agentType: AgentType.codeQuality,
      severity: Severity.medium,
      title: 'Complex method detected',
      filePath: 'src/service.dart',
      status: FindingStatus.open,
    ),
    const Finding(
      id: 'f3',
      jobId: 'j1',
      agentType: AgentType.security,
      severity: Severity.high,
      title: 'Hardcoded credentials',
      filePath: 'src/config.dart',
      status: FindingStatus.open,
    ),
  ];

  group('FindingFilterStep', () {
    testWidgets('shows title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        FindingFilterStep(
          findings: sampleFindings,
          selectedIds: const {},
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('Select Findings'), findsOneWidget);
    });

    testWidgets('shows selection count', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        FindingFilterStep(
          findings: sampleFindings,
          selectedIds: const {'f1', 'f2'},
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('2 of 3 findings selected.'), findsOneWidget);
    });

    testWidgets('shows finding titles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        FindingFilterStep(
          findings: sampleFindings,
          selectedIds: const {},
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('SQL injection vulnerability'), findsOneWidget);
      expect(find.text('Complex method detected'), findsOneWidget);
      expect(find.text('Hardcoded credentials'), findsOneWidget);
    });

    testWidgets('shows quick action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        FindingFilterStep(
          findings: sampleFindings,
          selectedIds: const {},
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('Select visible'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets('shows empty message when no findings match', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        FindingFilterStep(
          findings: const [],
          selectedIds: const {},
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.text('No findings match filters'), findsOneWidget);
    });

    testWidgets('fires onSelectionChanged when Clear all tapped',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Set<String>? newSelection;
      await tester.pumpWidget(wrap(
        FindingFilterStep(
          findings: sampleFindings,
          selectedIds: const {'f1', 'f2'},
          onSelectionChanged: (s) => newSelection = s,
        ),
      ));

      await tester.tap(find.text('Clear all'));
      expect(newSelection, isEmpty);
    });

    testWidgets('shows checkboxes for each finding', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        FindingFilterStep(
          findings: sampleFindings,
          selectedIds: const {},
          onSelectionChanged: (_) {},
        ),
      ));

      expect(find.byType(Checkbox), findsNWidgets(3));
    });
  });
}
