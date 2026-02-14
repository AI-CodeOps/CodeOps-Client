/// A scrollable feed of live findings detected during job execution.
///
/// Auto-scrolls to the bottom as new findings arrive. Each finding
/// shows a severity badge, agent icon, title, and timestamp.
library;

import 'package:flutter/material.dart';

import '../../services/orchestration/progress_aggregator.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import 'agent_card.dart';

/// Displays a scrollable list of live findings during job execution.
class LiveFindingsFeed extends StatefulWidget {
  /// The list of live findings to display.
  final List<LiveFinding> findings;

  /// Creates a [LiveFindingsFeed].
  const LiveFindingsFeed({super.key, required this.findings});

  @override
  State<LiveFindingsFeed> createState() => _LiveFindingsFeedState();
}

class _LiveFindingsFeedState extends State<LiveFindingsFeed> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(LiveFindingsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.findings.length > oldWidget.findings.length) {
      // Auto-scroll to bottom on new findings.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
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
    final visible = widget.findings.length >
            AppConstants.maxVisibleLiveFindings
        ? widget.findings.sublist(
            widget.findings.length - AppConstants.maxVisibleLiveFindings)
        : widget.findings;

    if (visible.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'No findings yet',
          style: TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: visible.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: CodeOpsColors.divider),
      itemBuilder: (context, index) {
        final finding = visible[index];
        return _FindingTile(finding: finding);
      },
    );
  }
}

class _FindingTile extends StatelessWidget {
  final LiveFinding finding;

  const _FindingTile({required this.finding});

  @override
  Widget build(BuildContext context) {
    final severityColor =
        CodeOpsColors.severityColors[finding.severity] ?? CodeOpsColors.warning;
    final meta = AgentTypeMetadata.all[finding.agentType];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity badge
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: severityColor,
            ),
          ),
          const SizedBox(width: 8),

          // Agent icon
          if (meta != null) ...[
            Icon(meta.icon, size: 14, color: CodeOpsColors.textTertiary),
            const SizedBox(width: 6),
          ],

          // Finding title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.title,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        finding.severity.displayName,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatTimeAgo(finding.detectedAt),
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
