/// Exec tab for the container detail page.
///
/// Provides a basic terminal-like interface for executing commands
/// inside a running container. Includes a command input field and
/// a scrollable output area displaying command results.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// A command-output pair for display in the exec history.
class ExecEntry {
  /// The command that was executed.
  final String command;

  /// The output returned from the container.
  final String output;

  /// Whether this entry represents an error.
  final bool isError;

  /// Creates an [ExecEntry].
  const ExecEntry({
    required this.command,
    required this.output,
    this.isError = false,
  });
}

/// Terminal-like interface for executing commands in a container.
class ContainerExecTab extends StatefulWidget {
  /// Callback to execute a command, returning the output string.
  final Future<String> Function(String command) onExec;

  /// Whether the container is currently running.
  final bool isRunning;

  /// Creates a [ContainerExecTab].
  const ContainerExecTab({
    super.key,
    required this.onExec,
    required this.isRunning,
  });

  @override
  State<ContainerExecTab> createState() => _ContainerExecTabState();
}

class _ContainerExecTabState extends State<ContainerExecTab> {
  final _commandController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ExecEntry> _history = [];
  bool _executing = false;

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Executes the current command.
  Future<void> _executeCommand() async {
    final cmd = _commandController.text.trim();
    if (cmd.isEmpty) return;

    _commandController.clear();
    setState(() => _executing = true);

    try {
      final output = await widget.onExec(cmd);
      setState(() {
        _history.add(ExecEntry(command: cmd, output: output));
        _executing = false;
      });
    } catch (e) {
      setState(() {
        _history.add(
            ExecEntry(command: cmd, output: e.toString(), isError: true));
        _executing = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRunning) {
      return const Center(
        child: Text(
          'Container is not running',
          style: TextStyle(color: CodeOpsColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        // Output area
        Expanded(
          child: Container(
            color: CodeOpsColors.background,
            child: _history.isEmpty
                ? const Center(
                    child: Text(
                      'Enter a command below to execute in the container',
                      style: TextStyle(color: CodeOpsColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _history.length,
                    itemBuilder: (_, i) => _buildEntry(_history[i]),
                  ),
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        // Command input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: CodeOpsColors.surface,
          child: Row(
            children: [
              Text(
                '\$',
                style: CodeOpsTypography.code
                    .copyWith(color: CodeOpsColors.success),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _commandController,
                  style: CodeOpsTypography.code,
                  enabled: !_executing,
                  decoration: const InputDecoration(
                    hintText: 'Enter command...',
                    hintStyle: TextStyle(
                        color: CodeOpsColors.textTertiary, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _executeCommand(),
                ),
              ),
              if (_executing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  color: CodeOpsColors.primary,
                  onPressed: _executeCommand,
                  tooltip: 'Execute',
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Renders a single exec history entry.
  Widget _buildEntry(ExecEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Command line
          Row(
            children: [
              Text(
                '\$ ',
                style: CodeOpsTypography.code
                    .copyWith(color: CodeOpsColors.success),
              ),
              Expanded(
                child: Text(
                  entry.command,
                  style: CodeOpsTypography.code
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Output
          Text(
            entry.output,
            style: CodeOpsTypography.code.copyWith(
              color: entry.isError
                  ? CodeOpsColors.error
                  : CodeOpsColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
