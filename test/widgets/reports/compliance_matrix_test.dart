// Tests for ComplianceMatrix.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/compliance_item.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/widgets/reports/compliance_matrix.dart';

void main() {
  final testItems = <ComplianceItem>[
    const ComplianceItem(
      id: 'c1',
      jobId: 'j1',
      requirement: 'Must have auth',
      status: ComplianceStatus.met,
    ),
    const ComplianceItem(
      id: 'c2',
      jobId: 'j1',
      requirement: 'Must encrypt data at rest',
      status: ComplianceStatus.missing,
    ),
    const ComplianceItem(
      id: 'c3',
      jobId: 'j1',
      requirement: 'Must log access events',
      status: ComplianceStatus.partial,
    ),
  ];

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 800,
          child: child,
        ),
      ),
    );
  }

  group('ComplianceMatrix', () {
    testWidgets('renders compliance item requirements', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ComplianceMatrix(items: testItems),
      ));
      await tester.pump();

      expect(find.text('Must have auth'), findsOneWidget);
      expect(find.text('Must encrypt data at rest'), findsOneWidget);
      expect(find.text('Must log access events'), findsOneWidget);
    });

    testWidgets('renders filter chips with status counts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ComplianceMatrix(items: testItems),
      ));
      await tester.pump();

      // "All" chip with total count.
      expect(find.text('All (3)'), findsOneWidget);
      // Status-specific chips.
      expect(find.text('Met (1)'), findsOneWidget);
      expect(find.text('Missing (1)'), findsOneWidget);
      expect(find.text('Partial (1)'), findsOneWidget);
    });

    testWidgets('renders status badges', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ComplianceMatrix(items: testItems),
      ));
      await tester.pump();

      // Status badges render displayName text.
      expect(find.text('Met'), findsAtLeast(1));
      expect(find.text('Missing'), findsAtLeast(1));
      expect(find.text('Partial'), findsAtLeast(1));
    });

    testWidgets('renders data table column headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        ComplianceMatrix(items: testItems),
      ));
      await tester.pump();

      expect(find.text('Requirement'), findsOneWidget);
      expect(find.text('Spec'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Agent'), findsOneWidget);
    });

    testWidgets('renders empty table with no items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        const ComplianceMatrix(items: []),
      ));
      await tester.pump();

      // "All" chip shows 0.
      expect(find.text('All (0)'), findsOneWidget);
    });
  });
}
