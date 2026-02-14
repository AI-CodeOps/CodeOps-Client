// Widget tests for RecentActivity.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/qa_job.dart';
import 'package:codeops/providers/job_providers.dart';
import 'package:codeops/widgets/dashboard/recent_activity.dart';

void main() {
  Widget createWidget({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(body: SizedBox(height: 400, child: RecentActivity())),
      ),
    );
  }

  group('RecentActivity', () {
    testWidgets('shows empty state when no jobs', (tester) async {
      await tester.pumpWidget(createWidget(overrides: [
        myJobsProvider.overrideWith((ref) => Future.value(<JobSummary>[])),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('No recent activity'), findsOneWidget);
    });

    testWidgets('renders job items', (tester) async {
      final jobs = [
        JobSummary(
          id: '1',
          mode: JobMode.audit,
          status: JobStatus.completed,
          name: 'Security Audit',
          projectName: 'Project Alpha',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        JobSummary(
          id: '2',
          mode: JobMode.dependency,
          status: JobStatus.running,
          name: 'Dep Scan',
          projectName: 'Project Beta',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      await tester.pumpWidget(createWidget(overrides: [
        myJobsProvider.overrideWith((ref) => Future.value(jobs)),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Security Audit'), findsOneWidget);
      expect(find.text('Dep Scan'), findsOneWidget);
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Project Beta'), findsOneWidget);
    });

    testWidgets('shows Recent Activity header', (tester) async {
      await tester.pumpWidget(createWidget(overrides: [
        myJobsProvider.overrideWith((ref) => Future.value(<JobSummary>[])),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
    });
  });
}
