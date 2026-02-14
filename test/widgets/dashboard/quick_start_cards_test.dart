// Widget tests for QuickStartCards.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/widgets/dashboard/quick_start_cards.dart';

void main() {
  group('QuickStartCards', () {
    testWidgets('renders 4 cards with correct titles', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: QuickStartCards(),
        ),
      ));

      expect(find.text('Run Audit'), findsOneWidget);
      expect(find.text('Investigate Bug'), findsOneWidget);
      expect(find.text('Compliance Check'), findsOneWidget);
      expect(find.text('Scan Dependencies'), findsOneWidget);
    });

    testWidgets('renders correct icons', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: QuickStartCards(),
        ),
      ));

      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });
}
