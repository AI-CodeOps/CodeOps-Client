// Tests for report providers.
//
// Verifies that agentReportMarkdownProvider and projectTrendProvider exist
// and are properly defined. These providers depend on the API layer with
// WidgetsFlutterBinding, so we verify existence without triggering execution.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/report_providers.dart';

void main() {
  group('Report providers', () {
    test('agentReportMarkdownProvider exists and is a family provider', () {
      expect(agentReportMarkdownProvider, isNotNull);
      expect(agentReportMarkdownProvider('some-s3-key'), isNotNull);
    });

    test('projectTrendProvider exists and is a family provider', () {
      expect(projectTrendProvider, isNotNull);
      expect(
        projectTrendProvider((projectId: 'p1', days: 30)),
        isNotNull,
      );
    });
  });
}
