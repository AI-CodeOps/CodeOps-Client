/// Dialog for testing a persona against code using the Claude Code CLI.
///
/// Streams output from a `claude` subprocess and displays results
/// with elapsed time tracking.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Shows the persona test runner dialog.
Future<void> showPersonaTestRunner(
  BuildContext context, {
  required String personaName,
  required String personaContent,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PersonaTestRunner(
      personaName: personaName,
      personaContent: personaContent,
    ),
  );
}

/// A dialog that runs a persona against code via the Claude Code CLI.
class PersonaTestRunner extends ConsumerStatefulWidget {
  /// The persona name for display.
  final String personaName;

  /// The persona markdown content.
  final String personaContent;

  /// Creates a [PersonaTestRunner].
  const PersonaTestRunner({
    super.key,
    required this.personaName,
    required this.personaContent,
  });

  @override
  ConsumerState<PersonaTestRunner> createState() => _PersonaTestRunnerState();
}

class _PersonaTestRunnerState extends ConsumerState<PersonaTestRunner> {
  final _codeController = TextEditingController();
  final _scrollController = ScrollController();
  String _language = 'java';
  int _maxTurns = AppConstants.defaultMaxTurns;
  String _model = AppConstants.defaultClaudeModel;
  String _output = '';
  bool _running = false;
  Process? _process;
  Timer? _timer;
  int _elapsedSeconds = 0;

  static const _languages = [
    'java',
    'kotlin',
    'dart',
    'python',
    'javascript',
    'typescript',
    'go',
    'rust',
    'swift',
    'ruby',
  ];

  @override
  void dispose() {
    _process?.kill();
    _timer?.cancel();
    _codeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runTest() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _running = true;
      _output = '';
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });

    final prompt = '''
Review the following ${_language.toUpperCase()} code using this persona:

---PERSONA---
${widget.personaContent}
---END PERSONA---

---CODE---
$code
---END CODE---

Provide your analysis following the persona's output format.
''';

    try {
      _process = await Process.start(
        'claude',
        ['--print', '--output-format', 'text', '-p', prompt],
        environment: {'CLAUDE_MODEL': _model},
      );

      _process!.stdout.transform(const SystemEncoding().decoder).listen(
        (data) {
          if (mounted) {
            setState(() => _output += data);
            _scrollToBottom();
          }
        },
      );

      _process!.stderr.transform(const SystemEncoding().decoder).listen(
        (data) {
          if (mounted) {
            setState(() => _output += '[stderr] $data');
          }
        },
      );

      final exitCode = await _process!.exitCode.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _process?.kill();
          return -1;
        },
      );

      if (mounted) {
        setState(() {
          if (exitCode == -1) {
            _output += '\n\n[Timed out after 5 minutes]';
          }
          _running = false;
        });
        _timer?.cancel();
      }
    } on ProcessException {
      if (mounted) {
        setState(() {
          _output =
              'Error: Claude Code CLI not found.\n\n'
              'Install it with: npm install -g @anthropic-ai/claude-code';
          _running = false;
        });
        _timer?.cancel();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _output = 'Error: $e';
          _running = false;
        });
        _timer?.cancel();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyOutput() {
    Clipboard.setData(ClipboardData(text: _output));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Output copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatElapsed() {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Row(
        children: [
          const Icon(Icons.science, size: 20, color: CodeOpsColors.primary),
          const SizedBox(width: 8),
          Text('Test: ${widget.personaName}'),
        ],
      ),
      content: SizedBox(
        width: 700,
        height: 550,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Config row.
            Row(
              children: [
                // Language.
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _language,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      isDense: true,
                    ),
                    dropdownColor: CodeOpsColors.surfaceVariant,
                    items: _languages
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: _running
                        ? null
                        : (v) => setState(() => _language = v ?? 'java'),
                  ),
                ),
                const SizedBox(width: 12),
                // Model.
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: _model,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      isDense: true,
                    ),
                    onChanged: (v) => _model = v,
                    enabled: !_running,
                  ),
                ),
                const SizedBox(width: 12),
                // Max turns.
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: '$_maxTurns',
                    decoration: const InputDecoration(
                      labelText: 'Max Turns',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _maxTurns = int.tryParse(v) ?? _maxTurns,
                    enabled: !_running,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Code input.
            const Text(
              'Code Sample',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 150,
              child: TextField(
                controller: _codeController,
                maxLines: null,
                expands: true,
                enabled: !_running,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: CodeOpsColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste your code here...',
                  filled: true,
                  fillColor: CodeOpsColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Output header.
            Row(
              children: [
                const Text(
                  'Output',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_running || _elapsedSeconds > 0)
                  Text(
                    _formatElapsed(),
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                if (_output.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'Copy output',
                    onPressed: _copyOutput,
                    color: CodeOpsColors.textTertiary,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Output panel.
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CodeOpsColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CodeOpsColors.border),
                ),
                child: _output.isEmpty && !_running
                    ? const Center(
                        child: Text(
                          'Run a test to see output here',
                          style: TextStyle(
                            color: CodeOpsColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        child: SelectableText(
                          _output.isEmpty ? 'Running...' : _output,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: CodeOpsColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _process?.kill();
            _timer?.cancel();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Close',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        FilledButton.icon(
          onPressed: _running ? null : _runTest,
          icon: _running
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow, size: 18),
          label: Text(_running ? 'Running...' : 'Run Test'),
        ),
      ],
    );
  }
}
