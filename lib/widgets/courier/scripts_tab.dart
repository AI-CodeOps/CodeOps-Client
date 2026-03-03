/// Scripts tab for the Courier request builder.
///
/// Provides two sub-tabs for Pre-request and Post-response scripts with
/// appropriate snippet libraries. Scripts use the `courier.*` DSL.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/courier_ui_providers.dart';
import '../../theme/colors.dart';
import 'script_console.dart';
import 'script_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Snippet libraries
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-request script snippets.
const _preRequestSnippets = <ScriptSnippet>[
  ScriptSnippet(
    label: 'Set environment variable',
    code: 'courier.environment.set("key", "value");',
  ),
  ScriptSnippet(
    label: 'Get environment variable',
    code: 'const val = courier.environment.get("key");',
  ),
  ScriptSnippet(
    label: 'Set global variable',
    code: 'courier.globals.set("key", "value");',
  ),
  ScriptSnippet(
    label: 'Set request header',
    code: 'courier.request.addHeader("key", "value");',
  ),
  ScriptSnippet(
    label: 'Set request URL',
    code: 'courier.request.url = "https://...";',
  ),
  ScriptSnippet(
    label: 'Generate UUID',
    code: 'const uuid = courier.uuid();',
  ),
  ScriptSnippet(
    label: 'Generate timestamp',
    code: 'const ts = courier.timestamp();',
  ),
  ScriptSnippet(
    label: 'Log to console',
    code: 'console.log("message");',
  ),
];

/// Post-response script snippets.
const _postResponseSnippets = <ScriptSnippet>[
  ScriptSnippet(
    label: 'Get response body',
    code: 'const body = courier.response.json();',
  ),
  ScriptSnippet(
    label: 'Get response header',
    code: 'const val = courier.response.header("Content-Type");',
  ),
  ScriptSnippet(
    label: 'Get status code',
    code: 'const code = courier.response.statusCode;',
  ),
  ScriptSnippet(
    label: 'Get response time',
    code: 'const time = courier.response.responseTime;',
  ),
  ScriptSnippet(
    label: 'Set env var from response',
    code: 'courier.environment.set("token", courier.response.json().access_token);',
  ),
  ScriptSnippet(
    label: 'Log to console',
    code: 'console.log("message");',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// ScriptsTab
// ─────────────────────────────────────────────────────────────────────────────

/// The Scripts tab with Pre-request and Post-response sub-tabs.
///
/// Each sub-tab shows a [ScriptEditor] with the appropriate snippet library
/// and a [ScriptConsole] output panel at the bottom.
class ScriptsTab extends StatefulWidget {
  /// Creates a [ScriptsTab].
  const ScriptsTab({super.key});

  @override
  State<ScriptsTab> createState() => _ScriptsTabState();
}

class _ScriptsTabState extends State<ScriptsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('scripts_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sub-tab bar.
        Container(
          color: CodeOpsColors.surface,
          child: TabBar(
            key: const Key('scripts_sub_tab_bar'),
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: CodeOpsColors.primary,
            unselectedLabelColor: CodeOpsColors.textSecondary,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            indicatorColor: CodeOpsColors.primary,
            indicatorWeight: 2,
            tabs: const [
              Tab(
                key: Key('pre_request_tab'),
                text: 'Pre-request',
                height: 32,
              ),
              Tab(
                key: Key('post_response_tab'),
                text: 'Post-response',
                height: 32,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Tab content.
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _PreRequestEditor(),
              _PostResponseEditor(),
            ],
          ),
        ),
        // Console output.
        const SizedBox(
          height: 150,
          child: ScriptConsole(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PreRequestEditor
// ─────────────────────────────────────────────────────────────────────────────

class _PreRequestEditor extends ConsumerWidget {
  const _PreRequestEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(scriptPreRequestProvider);

    return ScriptEditor(
      key: const Key('pre_request_editor'),
      content: content,
      snippets: _preRequestSnippets,
      placeholder: '// Pre-request script runs before sending the request.\n'
          '// Use snippets on the right to get started.',
      onChanged: (v) =>
          ref.read(scriptPreRequestProvider.notifier).state = v,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PostResponseEditor
// ─────────────────────────────────────────────────────────────────────────────

class _PostResponseEditor extends ConsumerWidget {
  const _PostResponseEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(scriptPostResponseProvider);

    return ScriptEditor(
      key: const Key('post_response_editor'),
      content: content,
      snippets: _postResponseSnippets,
      placeholder: '// Post-response script runs after the response is received.\n'
          '// Use snippets on the right to get started.',
      onChanged: (v) =>
          ref.read(scriptPostResponseProvider.notifier).state = v,
    );
  }
}
