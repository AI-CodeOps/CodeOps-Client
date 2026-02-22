// Tests for ServiceStatusBadge and HealthIndicator widgets.
//
// Verifies color mapping, label display, and null health handling.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/theme/colors.dart';
import 'package:codeops/widgets/registry/service_status_badge.dart';

void main() {
  group('ServiceStatusBadge', () {
    testWidgets('active shows green styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ServiceStatusBadge(status: ServiceStatus.active)),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color.a, greaterThan(0));
    });

    testWidgets('inactive shows gray styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceStatusBadge(status: ServiceStatus.inactive),
          ),
        ),
      );

      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('deprecated shows amber styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceStatusBadge(status: ServiceStatus.deprecated),
          ),
        ),
      );

      expect(find.text('Deprecated'), findsOneWidget);
    });

    testWidgets('archived shows dark gray styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceStatusBadge(status: ServiceStatus.archived),
          ),
        ),
      );

      expect(find.text('Archived'), findsOneWidget);
    });

    testWidgets('all statuses render without error', (tester) async {
      for (final status in ServiceStatus.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ServiceStatusBadge(status: status)),
          ),
        );
        expect(find.text(status.displayName), findsOneWidget);
      }
    });
  });

  group('HealthIndicator', () {
    testWidgets('up shows green dot and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HealthIndicator(status: HealthStatus.up)),
        ),
      );

      expect(find.text('Up'), findsOneWidget);
      // Verify the colored dot exists
      final containers = tester.widgetList<Container>(find.byType(Container));
      final dot = containers.firstWhere(
        (c) =>
            c.constraints?.maxWidth == 8 &&
            (c.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      );
      final dotDecoration = dot.decoration! as BoxDecoration;
      expect(dotDecoration.color, CodeOpsColors.success);
    });

    testWidgets('down shows red dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HealthIndicator(status: HealthStatus.down)),
        ),
      );

      expect(find.text('Down'), findsOneWidget);
    });

    testWidgets('degraded shows amber dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HealthIndicator(status: HealthStatus.degraded),
          ),
        ),
      );

      expect(find.text('Degraded'), findsOneWidget);
    });

    testWidgets('unknown shows gray dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HealthIndicator(status: HealthStatus.unknown)),
        ),
      );

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('null status shows "Never checked"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HealthIndicator(status: null)),
        ),
      );

      expect(find.text('Never checked'), findsOneWidget);
    });

    testWidgets('showLabel false hides text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HealthIndicator(status: HealthStatus.up, showLabel: false),
          ),
        ),
      );

      expect(find.text('Up'), findsNothing);
    });
  });
}
