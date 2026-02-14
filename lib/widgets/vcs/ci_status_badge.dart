/// Compact CI status badge widget.
///
/// Displays green/yellow/red/grey icon + text based on workflow run status.
/// Click opens the workflow URL in a browser.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/vcs_models.dart';
import '../../theme/colors.dart';

/// A compact badge showing CI workflow status.
class CiStatusBadge extends StatelessWidget {
  /// The workflow run to display.
  final WorkflowRun run;

  /// Creates a [CiStatusBadge].
  const CiStatusBadge({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${run.name ?? 'CI'}: ${run.conclusion ?? run.status}',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: run.htmlUrl != null
            ? () => launchUrl(Uri.parse(run.htmlUrl!))
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon, size: 14, color: _statusColor),
              const SizedBox(width: 4),
              Text(
                _statusText,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    if (run.conclusion == 'success') return CodeOpsColors.success;
    if (run.conclusion == 'failure') return CodeOpsColors.error;
    if (run.status == 'in_progress' || run.status == 'queued') {
      return CodeOpsColors.warning;
    }
    return CodeOpsColors.textTertiary;
  }

  IconData get _statusIcon {
    if (run.conclusion == 'success') return Icons.check_circle;
    if (run.conclusion == 'failure') return Icons.cancel;
    if (run.status == 'in_progress') return Icons.pending;
    if (run.status == 'queued') return Icons.schedule;
    return Icons.help_outline;
  }

  String get _statusText {
    if (run.conclusion != null) return run.conclusion!;
    return run.status;
  }
}
