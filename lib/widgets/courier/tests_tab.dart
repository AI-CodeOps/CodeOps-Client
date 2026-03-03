/// Tests tab for the Courier request builder.
///
/// Provides a script editor with assertion-focused snippets for writing
/// `courier.test()` / `courier.expect()` post-response test assertions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/courier_ui_providers.dart';
import '../../theme/colors.dart';
import 'script_console.dart';
import 'script_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test assertion snippets
// ─────────────────────────────────────────────────────────────────────────────

/// Assertion-focused snippets for the Tests tab.
const _testSnippets = <ScriptSnippet>[
  ScriptSnippet(
    label: 'Status code is 200',
    code: 'courier.test("Status is 200", () => {\n'
        '  courier.expect(courier.response.statusCode).toBe(200);\n'
        '});',
  ),
  ScriptSnippet(
    label: 'Response time < 500ms',
    code: 'courier.test("Response time < 500ms", () => {\n'
        '  courier.expect(courier.response.responseTime).toBeLessThan(500);\n'
        '});',
  ),
  ScriptSnippet(
    label: 'Body contains property',
    code: 'courier.test("Body contains user", () => {\n'
        '  const body = courier.response.json();\n'
        '  courier.expect(body).toHaveProperty("user");\n'
        '});',
  ),
  ScriptSnippet(
    label: 'Content-Type is JSON',
    code: 'courier.test("Content-Type is JSON", () => {\n'
        '  courier.expect(courier.response.header("Content-Type"))'
        '.toContain("application/json");\n'
        '});',
  ),
  ScriptSnippet(
    label: 'Array length check',
    code: 'courier.test("Returns 10 items", () => {\n'
        '  const body = courier.response.json();\n'
        '  courier.expect(body.items.length).toBe(10);\n'
        '});',
  ),
  ScriptSnippet(
    label: 'Schema validation',
    code: 'courier.test("Schema is valid", () => {\n'
        '  const body = courier.response.json();\n'
        '  courier.expect(body).toMatchSchema({"id": "string", "name": "string"});\n'
        '});',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// TestsTab
// ─────────────────────────────────────────────────────────────────────────────

/// The Tests tab for writing post-response assertion scripts.
///
/// Shows a [ScriptEditor] with assertion-focused snippets and a
/// [ScriptConsole] output panel at the bottom.
class TestsTab extends ConsumerWidget {
  /// Creates a [TestsTab].
  const TestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(scriptTestsProvider);

    return Column(
      key: const Key('tests_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: CodeOpsColors.surface,
          child: const Row(
            children: [
              Icon(Icons.science_outlined,
                  size: 14, color: CodeOpsColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Test Assertions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Write courier.test() assertions to validate responses',
                style: TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Editor.
        Expanded(
          child: ScriptEditor(
            key: const Key('tests_editor'),
            content: content,
            snippets: _testSnippets,
            placeholder:
                '// Write test assertions that run after each response.\n'
                '// Click snippets on the right to insert common patterns.',
            onChanged: (v) =>
                ref.read(scriptTestsProvider.notifier).state = v,
          ),
        ),
        // Console.
        const SizedBox(
          height: 150,
          child: ScriptConsole(),
        ),
      ],
    );
  }
}
