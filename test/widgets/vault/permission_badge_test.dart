// Widget tests for PermissionBadge (CVF-004).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/theme/app_theme.dart';
import 'package:codeops/widgets/vault/permission_badge.dart';

void main() {
  Widget createWidget(PolicyPermission permission) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: PermissionBadge(permission: permission),
      ),
    );
  }

  group('PermissionBadge', () {
    testWidgets('shows READ label for read permission', (tester) async {
      await tester.pumpWidget(createWidget(PolicyPermission.read));

      expect(find.text('READ'), findsOneWidget);
    });

    testWidgets('shows WRITE label for write permission', (tester) async {
      await tester.pumpWidget(createWidget(PolicyPermission.write));

      expect(find.text('WRITE'), findsOneWidget);
    });

    testWidgets('shows DELETE label for delete permission', (tester) async {
      await tester.pumpWidget(createWidget(PolicyPermission.delete));

      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('shows LIST label for list permission', (tester) async {
      await tester.pumpWidget(createWidget(PolicyPermission.list));

      expect(find.text('LIST'), findsOneWidget);
    });

    testWidgets('shows ROTATE label for rotate permission', (tester) async {
      await tester.pumpWidget(createWidget(PolicyPermission.rotate));

      expect(find.text('ROTATE'), findsOneWidget);
    });

    testWidgets('renders as a Container with rounded border', (tester) async {
      await tester.pumpWidget(createWidget(PolicyPermission.read));

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('READ'),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(4));
    });
  });
}
