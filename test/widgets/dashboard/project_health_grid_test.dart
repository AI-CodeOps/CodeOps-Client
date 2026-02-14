// Widget tests for ProjectHealthGrid.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/project.dart';
import 'package:codeops/providers/project_providers.dart';
import 'package:codeops/widgets/dashboard/project_health_grid.dart';

void main() {
  Widget createWidget({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 400, child: ProjectHealthGrid()),
        ),
      ),
    );
  }

  group('ProjectHealthGrid', () {
    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(createWidget(overrides: []));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no projects', (tester) async {
      await tester.pumpWidget(createWidget(overrides: [
        teamProjectsProvider.overrideWith((ref) => Future.value(<Project>[])),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('No projects yet'), findsOneWidget);
    });

    testWidgets('renders project cards with health scores', (tester) async {
      final projects = [
        Project(id: '1', teamId: 't1', name: 'Alpha', healthScore: 92),
        Project(id: '2', teamId: 't1', name: 'Beta', healthScore: 65),
        Project(id: '3', teamId: 't1', name: 'Gamma', healthScore: 45),
      ];

      await tester.pumpWidget(createWidget(overrides: [
        teamProjectsProvider.overrideWith((ref) => Future.value(projects)),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('92'), findsOneWidget);
      expect(find.text('65'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
    });
  });
}
