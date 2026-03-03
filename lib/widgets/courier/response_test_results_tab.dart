/// Response test results tab for Courier.
///
/// Displays test assertion results from script execution (CCF-007).
/// Shows pass/fail status, summary bar, and error details for failures.
library;

import 'package:flutter/material.dart';

import '../../services/courier/script_engine.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ResponseTestResultsTab
// ─────────────────────────────────────────────────────────────────────────────

/// Displays test results from `courier.test()` assertions.
///
/// Shows a summary bar with pass/fail counts and a list of individual test
/// results. Failed tests expand to show assertion error details.
class ResponseTestResultsTab extends StatelessWidget {
  /// Test results from script execution.
  final List<TestResult> results;

  /// Creates a [ResponseTestResultsTab].
  const ResponseTestResultsTab({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No test results',
          key: Key('test_results_empty'),
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    final passed = results.where((r) => r.passed).length;
    final failed = results.length - passed;

    return Column(
      key: const Key('response_test_results_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary bar.
        _SummaryBar(
          total: results.length,
          passed: passed,
          failed: failed,
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Results list.
        Expanded(
          child: ListView.separated(
            key: const Key('test_results_list'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, thickness: 1, color: CodeOpsColors.border),
            itemBuilder: (_, i) => _TestResultRow(result: results[i]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SummaryBar
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int total;
  final int passed;
  final int failed;

  const _SummaryBar({
    required this.total,
    required this.passed,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    final allPassed = failed == 0;

    return Container(
      key: const Key('test_summary_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: allPassed
          ? CodeOpsColors.success.withAlpha(20)
          : CodeOpsColors.error.withAlpha(20),
      child: Row(
        children: [
          Icon(
            allPassed ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: allPassed ? CodeOpsColors.success : CodeOpsColors.error,
          ),
          const SizedBox(width: 8),
          Text(
            '$passed/$total tests passed',
            key: const Key('test_summary_text'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: allPassed ? CodeOpsColors.success : CodeOpsColors.error,
            ),
          ),
          if (failed > 0) ...[
            const SizedBox(width: 12),
            Text(
              '$failed failed',
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TestResultRow
// ─────────────────────────────────────────────────────────────────────────────

class _TestResultRow extends StatelessWidget {
  final TestResult result;

  const _TestResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.passed
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: 14,
                color: result.passed
                    ? CodeOpsColors.success
                    : CodeOpsColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: result.passed
                        ? CodeOpsColors.textPrimary
                        : CodeOpsColors.error,
                  ),
                ),
              ),
              Text(
                result.passed ? 'PASS' : 'FAIL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: result.passed
                      ? CodeOpsColors.success
                      : CodeOpsColors.error,
                ),
              ),
            ],
          ),
          if (!result.passed && result.errorMessage != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CodeOpsColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CodeOpsColors.error.withAlpha(50)),
              ),
              child: Text(
                result.errorMessage!,
                key: const Key('test_error_detail'),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: CodeOpsColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
