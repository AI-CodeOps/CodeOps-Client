/// Code generation page for the Courier module.
///
/// Two-pane layout: left sidebar lists 12 target languages with icons,
/// right pane shows generated code with copy/save/wrap controls. Generates
/// code client-side from the active request's configuration using
/// [CodeGenerationService].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/courier_enums.dart';
import '../../providers/courier_ui_providers.dart';
import '../../services/courier/code_generation_service.dart';
import '../../theme/colors.dart';
import '../../widgets/courier/batch_codegen_dialog.dart';
import '../../widgets/courier/code_display_panel.dart';

/// Language metadata for the sidebar list.
class _LangEntry {
  final CodeLanguage language;
  final String label;
  final String sublabel;
  final IconData icon;

  const _LangEntry(this.language, this.label, this.sublabel, this.icon);
}

const _languages = [
  _LangEntry(CodeLanguage.curl, 'cURL', 'Command Line', Icons.terminal),
  _LangEntry(CodeLanguage.pythonRequests, 'Python', 'Requests', Icons.code),
  _LangEntry(CodeLanguage.javascriptFetch, 'JavaScript', 'Fetch API', Icons.javascript),
  _LangEntry(CodeLanguage.javascriptAxios, 'JavaScript', 'Axios', Icons.javascript),
  _LangEntry(CodeLanguage.javaHttpClient, 'Java', 'HttpClient', Icons.coffee),
  _LangEntry(CodeLanguage.javaOkhttp, 'Java', 'OkHttp', Icons.coffee),
  _LangEntry(CodeLanguage.csharpHttpClient, 'C#', 'HttpClient', Icons.data_object),
  _LangEntry(CodeLanguage.go, 'Go', 'net/http', Icons.code),
  _LangEntry(CodeLanguage.ruby, 'Ruby', 'Net::HTTP', Icons.diamond),
  _LangEntry(CodeLanguage.php, 'PHP', 'cURL', Icons.php),
  _LangEntry(CodeLanguage.swift, 'Swift', 'URLSession', Icons.apple),
  _LangEntry(CodeLanguage.kotlin, 'Kotlin', 'OkHttp', Icons.android),
];

/// Full-page code generation tool shown at `/courier/codegen`.
///
/// Reads the current request's method, URL, headers, params, body, auth, and
/// settings from Riverpod providers and generates code client-side via
/// [CodeGenerationService].
class CodeGenerationPage extends ConsumerStatefulWidget {
  /// Creates a [CodeGenerationPage].
  const CodeGenerationPage({super.key});

  @override
  ConsumerState<CodeGenerationPage> createState() => _CodeGenerationPageState();
}

class _CodeGenerationPageState extends ConsumerState<CodeGenerationPage> {
  CodeLanguage _selected = CodeLanguage.curl;
  bool _showResolved = false;
  String _generatedCode = '';

  @override
  void initState() {
    super.initState();
    // Generate initial code after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _generateCode());
  }

  void _generateCode() {
    final editState = ref.read(activeRequestStateProvider);
    final params = ref.read(requestParamsProvider);
    final headers = ref.read(requestHeadersProvider);
    final bodyType = ref.read(bodyTypeProvider);
    final rawContent = ref.read(bodyRawContentProvider);
    final formData = ref.read(bodyFormDataProvider);
    final graphqlQuery = ref.read(bodyGraphqlQueryProvider);
    final graphqlVars = ref.read(bodyGraphqlVariablesProvider);
    final binaryFile = ref.read(bodyBinaryFileNameProvider);
    final authType = ref.read(authTypeProvider);

    // Build maps from KeyValuePair lists.
    final headerMap = <String, String>{};
    for (final kv in headers) {
      if (kv.enabled && kv.key.isNotEmpty) {
        headerMap[kv.key] = kv.value;
      }
    }

    final paramMap = <String, String>{};
    for (final kv in params) {
      if (kv.enabled && kv.key.isNotEmpty) {
        paramMap[kv.key] = kv.value;
      }
    }

    final formDataMap = <String, String>{};
    for (final kv in formData) {
      if (kv.enabled && kv.key.isNotEmpty) {
        formDataMap[kv.key] = kv.value;
      }
    }

    // Build auth data.
    final auth = CodegenAuth(
      type: authType,
      bearerToken: ref.read(authBearerTokenProvider),
      bearerPrefix: ref.read(authBearerPrefixProvider),
      basicUsername: ref.read(authBasicUsernameProvider),
      basicPassword: ref.read(authBasicPasswordProvider),
      apiKeyHeader: ref.read(authApiKeyHeaderProvider),
      apiKeyValue: ref.read(authApiKeyValueProvider),
      apiKeyAddTo: ref.read(authApiKeyAddToProvider),
    );

    final body = CodegenBody(
      type: bodyType,
      rawContent: rawContent,
      formData: formDataMap,
      graphqlQuery: graphqlQuery,
      graphqlVariables: graphqlVars,
      binaryFileName: binaryFile,
    );

    final settings = CodegenSettings(
      sslVerify: editState.settings.sslVerify,
      timeoutMs: editState.settings.timeoutMs,
      followRedirects: editState.settings.followRedirects,
    );

    const svc = CodeGenerationService();
    final code = svc.generate(
      language: _selected,
      method: editState.method.toJson(),
      url: editState.url,
      headers: headerMap,
      queryParams: paramMap,
      body: body,
      auth: auth,
      settings: settings,
    );

    setState(() => _generatedCode = code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CodeOpsColors.background,
      body: Column(
        children: [
          // ── Page header ────────────────────────────────────────
          Container(
            key: const Key('codegen_page_header'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: CodeOpsColors.surface,
              border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  key: const Key('codegen_back_button'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  color: CodeOpsColors.textSecondary,
                  onPressed: () => context.go('/courier'),
                  tooltip: 'Back to Courier',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.code, color: CodeOpsColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Code Generation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  key: const Key('batch_codegen_button'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const BatchCodegenDialog(),
                    );
                  },
                  icon: const Icon(Icons.playlist_play, size: 16),
                  label: const Text('Batch Generate', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: CodeOpsColors.surfaceVariant,
                    foregroundColor: CodeOpsColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),

          // ── Body: sidebar + code panel ─────────────────────────
          Expanded(
            child: Row(
              children: [
                // Language sidebar
                Container(
                  key: const Key('language_selector'),
                  width: 200,
                  decoration: const BoxDecoration(
                    color: CodeOpsColors.surface,
                    border: Border(
                      right: BorderSide(color: CodeOpsColors.border),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _languages.length,
                    itemBuilder: (_, i) {
                      final lang = _languages[i];
                      final isSelected = lang.language == _selected;
                      return _LanguageTile(
                        key: Key('lang_tile_${lang.language.name}'),
                        entry: lang,
                        selected: isSelected,
                        onTap: () {
                          setState(() => _selected = lang.language);
                          _generateCode();
                        },
                      );
                    },
                  ),
                ),

                // Code display
                Expanded(
                  child: CodeDisplayPanel(
                    code: _generatedCode,
                    language: _selected,
                    showResolved: _showResolved,
                    onVariablesToggled: (v) {
                      setState(() => _showResolved = v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language tile widget
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final _LangEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? CodeOpsColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? CodeOpsColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              entry.icon,
              size: 18,
              color: selected ? CodeOpsColors.primary : CodeOpsColors.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected
                          ? CodeOpsColors.textPrimary
                          : CodeOpsColors.textSecondary,
                    ),
                  ),
                  Text(
                    entry.sublabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
