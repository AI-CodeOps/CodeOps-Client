// Tests for ServiceTypeIcon widget.
//
// Verifies icon mapping, tooltip display, and rendering for all types.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/widgets/registry/service_type_icon.dart';

void main() {
  group('ServiceTypeIcon', () {
    testWidgets('springBootApi shows api icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceTypeIcon(type: ServiceType.springBootApi),
          ),
        ),
      );

      expect(find.byIcon(Icons.api), findsOneWidget);
    });

    testWidgets('flutterDesktop shows desktop_windows icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceTypeIcon(type: ServiceType.flutterDesktop),
          ),
        ),
      );

      expect(find.byIcon(Icons.desktop_windows), findsOneWidget);
    });

    testWidgets('gateway shows router icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceTypeIcon(type: ServiceType.gateway),
          ),
        ),
      );

      expect(find.byIcon(Icons.router), findsOneWidget);
    });

    testWidgets('mcpServer shows smart_toy icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceTypeIcon(type: ServiceType.mcpServer),
          ),
        ),
      );

      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('allTypes render without error', (tester) async {
      for (final type in ServiceType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ServiceTypeIcon(type: type)),
          ),
        );

        // Each type should render an Icon widget
        expect(find.byType(Icon), findsOneWidget);

        // Should have a Tooltip with the display name
        expect(find.byType(Tooltip), findsOneWidget);
        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, type.displayName);
      }
    });

    testWidgets('custom size is applied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceTypeIcon(type: ServiceType.springBootApi, size: 32),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 32);
    });
  });
}
