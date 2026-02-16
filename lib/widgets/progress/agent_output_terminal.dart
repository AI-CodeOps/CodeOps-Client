/// Mini terminal widget displaying the last N lines of agent output.
///
/// Used inside expanded [AgentCard]s to show raw Claude Code output
/// in a monospace, dark terminal-style container.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Displays raw output lines in a terminal-style container.
///
/// Shows the most recent lines from agent stdout. Auto-scrolls
/// to the bottom when new lines arrive.
class AgentOutputTerminal extends StatefulWidget {
  /// The output lines to display.
  final List<String> lines;

  /// Maximum height of the terminal container.
  final double maxHeight;

  /// Creates an [AgentOutputTerminal].
  const AgentOutputTerminal({
    super.key,
    required this.lines,
    this.maxHeight = 160,
  });

  @override
  State<AgentOutputTerminal> createState() => _AgentOutputTerminalState();
}

class _AgentOutputTerminalState extends State<AgentOutputTerminal> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(AgentOutputTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length > oldWidget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CodeOpsColors.border.withValues(alpha: 0.5)),
      ),
      child: widget.lines.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Waiting for output...',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: widget.lines.length,
              itemBuilder: (context, index) {
                return Text(
                  widget.lines[index],
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
    );
  }
}
