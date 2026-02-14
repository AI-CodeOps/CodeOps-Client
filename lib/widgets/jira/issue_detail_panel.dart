/// Full detail side-panel for a single Jira issue.
///
/// Displays the issue header (key, summary, status, priority), a metadata grid,
/// rendered description (ADF -> markdown), comments, attachments, linked issues,
/// and action buttons for investigation and opening in Jira.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/jira_models.dart';
import '../../providers/jira_providers.dart';
import '../../services/jira/jira_mapper.dart';
import '../../theme/colors.dart';

/// Full detail view of a single Jira issue shown in a side panel.
///
/// Fetches the issue and its comments via [jiraIssueProvider] and
/// [jiraCommentsProvider] keyed by [issueKey]. Provides callbacks for
/// investigating the bug and closing the panel.
class IssueDetailPanel extends ConsumerWidget {
  /// The Jira issue key to display (e.g. 'PAY-456').
  final String issueKey;

  /// Called when the user taps the "Investigate This Bug" button.
  final ValueChanged<JiraIssue>? onInvestigate;

  /// Called when the user taps the close button.
  final VoidCallback? onClose;

  /// Creates an [IssueDetailPanel].
  const IssueDetailPanel({
    super.key,
    required this.issueKey,
    this.onInvestigate,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issueAsync = ref.watch(jiraIssueProvider(issueKey));
    final commentsAsync = ref.watch(jiraCommentsProvider(issueKey));

    return Container(
      width: 560,
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(
          left: BorderSide(color: CodeOpsColors.border, width: 1),
        ),
      ),
      child: issueAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CodeOpsColors.primary),
        ),
        error: (error, _) => _buildErrorState(error.toString()),
        data: (issue) {
          if (issue == null) {
            return _buildErrorState('Issue $issueKey not found.');
          }
          return _IssueDetailContent(
            issue: issue,
            comments: commentsAsync.valueOrNull ?? [],
            commentsLoading: commentsAsync.isLoading,
            onInvestigate: onInvestigate,
            onClose: onClose,
          );
        },
      ),
    );
  }

  /// Builds an error state widget with the given [message].
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: CodeOpsColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal stateless widget that renders the issue detail content.
class _IssueDetailContent extends StatelessWidget {
  final JiraIssue issue;
  final List<JiraComment> comments;
  final bool commentsLoading;
  final ValueChanged<JiraIssue>? onInvestigate;
  final VoidCallback? onClose;

  const _IssueDetailContent({
    required this.issue,
    required this.comments,
    required this.commentsLoading,
    this.onInvestigate,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final fields = issue.fields;
    final statusColor = JiraMapper.mapStatusColor(fields.status.statusCategory);
    final priorityDisplay = JiraMapper.mapPriority(fields.priority?.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(fields, statusColor, priorityDisplay),
        const Divider(color: CodeOpsColors.border, height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMetadataGrid(fields),
              const SizedBox(height: 20),
              _buildDescriptionSection(fields),
              const SizedBox(height: 20),
              _buildCommentsSection(),
              if (fields.attachment != null && fields.attachment!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildAttachmentsSection(fields.attachment!),
              ],
              if (fields.issuelinks != null &&
                  fields.issuelinks!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildLinkedIssuesSection(fields.issuelinks!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the panel header with issue key, summary, badges, and action buttons.
  Widget _buildHeader(
    JiraIssueFields fields,
    Color statusColor,
    JiraPriorityDisplay priorityDisplay,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: CodeOpsColors.surfaceVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      issue.key,
                      style: const TextStyle(
                        color: CodeOpsColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(
                      label: fields.status.name,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    _PriorityBadge(display: priorityDisplay),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: CodeOpsColors.textSecondary, size: 20),
                onPressed: onClose,
                tooltip: 'Close panel',
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fields.summary,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onInvestigate != null)
                _ActionButton(
                  label: 'Investigate This Bug',
                  icon: Icons.bug_report_outlined,
                  color: CodeOpsColors.primary,
                  onPressed: () => onInvestigate!(issue),
                ),
              if (onInvestigate != null) const SizedBox(width: 8),
              _ActionButton(
                label: 'Open in Jira',
                icon: Icons.open_in_new,
                color: CodeOpsColors.secondary,
                onPressed: () => _openInJira(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the metadata grid showing type, assignee, reporter, dates, etc.
  Widget _buildMetadataGrid(JiraIssueFields fields) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Details'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _MetadataRow(
                label: 'Type',
                value: fields.issuetype.name,
                icon: Icons.category_outlined,
              ),
              _MetadataRow(
                label: 'Assignee',
                value: fields.assignee?.displayName ?? 'Unassigned',
                icon: Icons.person_outline,
              ),
              _MetadataRow(
                label: 'Reporter',
                value: fields.reporter?.displayName ?? 'Unknown',
                icon: Icons.person_2_outlined,
              ),
              _MetadataRow(
                label: 'Created',
                value: fields.created != null
                    ? dateFormat
                        .format(DateTime.parse(fields.created!).toLocal())
                    : 'N/A',
                icon: Icons.calendar_today_outlined,
              ),
              _MetadataRow(
                label: 'Updated',
                value: fields.updated != null
                    ? dateFormat
                        .format(DateTime.parse(fields.updated!).toLocal())
                    : 'N/A',
                icon: Icons.update_outlined,
              ),
              _MetadataRow(
                label: 'Sprint',
                value: fields.sprint?.name ?? 'None',
                icon: Icons.directions_run_outlined,
              ),
              _MetadataRow(
                label: 'Labels',
                value: fields.labels != null && fields.labels!.isNotEmpty
                    ? fields.labels!.join(', ')
                    : 'None',
                icon: Icons.label_outline,
              ),
              _MetadataRow(
                label: 'Components',
                value:
                    fields.components != null && fields.components!.isNotEmpty
                        ? fields.components!.map((c) => c.name).join(', ')
                        : 'None',
                icon: Icons.extension_outlined,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the description section, converting ADF to markdown.
  Widget _buildDescriptionSection(JiraIssueFields fields) {
    final markdown = JiraMapper.adfToMarkdown(fields.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Description'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: markdown.isNotEmpty
              ? MarkdownBody(
                  data: markdown,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    h1: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    h2: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    h3: const TextStyle(
                      color: CodeOpsColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    code: TextStyle(
                      color: CodeOpsColors.secondary,
                      backgroundColor:
                          CodeOpsColors.background.withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: CodeOpsColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    blockquoteDecoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: CodeOpsColors.primary,
                          width: 3,
                        ),
                      ),
                    ),
                    listBullet: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                )
              : const Text(
                  'No description provided.',
                  style: TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  /// Builds the comments section with loading state.
  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Comments',
          trailing: Text(
            '${comments.length}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (commentsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
          )
        else if (comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CodeOpsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No comments.',
              style: TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...comments.map(_buildCommentTile),
      ],
    );
  }

  /// Builds a single comment tile.
  Widget _buildCommentTile(JiraComment comment) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    final bodyMarkdown = JiraMapper.adfToMarkdown(comment.body);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_circle,
                color: CodeOpsColors.textTertiary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                comment.author?.displayName ?? 'Unknown',
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (comment.created != null)
                Text(
                  dateFormat
                      .format(DateTime.parse(comment.created!).toLocal()),
                  style: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bodyMarkdown.isNotEmpty ? bodyMarkdown : '(empty)',
            style: const TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the attachments section.
  Widget _buildAttachmentsSection(List<JiraAttachment> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Attachments',
          trailing: Text(
            '${attachments.length}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...attachments.map(_buildAttachmentTile),
      ],
    );
  }

  /// Builds a single attachment tile with filename and size.
  Widget _buildAttachmentTile(JiraAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.attach_file,
            color: CodeOpsColors.textTertiary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachment.filename,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (attachment.size != null)
            Text(
              _formatFileSize(attachment.size!),
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the linked issues section.
  Widget _buildLinkedIssuesSection(List<JiraIssueLink> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Linked Issues',
          trailing: Text(
            '${links.length}',
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...links.map(_buildIssueLinkTile),
      ],
    );
  }

  /// Builds a single linked issue tile.
  Widget _buildIssueLinkTile(JiraIssueLink link) {
    final linkedIssue = link.outwardIssue ?? link.inwardIssue;
    final direction =
        link.outwardIssue != null ? link.type.outward : link.type.inward;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.link,
            color: CodeOpsColors.textTertiary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            direction,
            style: const TextStyle(
              color: CodeOpsColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          if (linkedIssue != null) ...[
            Text(
              linkedIssue.key,
              style: const TextStyle(
                color: CodeOpsColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                linkedIssue.fields.summary,
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Expanded(
              child: Text(
                'Unknown issue',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the issue in Jira via the browser.
  Future<void> _openInJira() async {
    final baseUrl = issue.self;
    // Derive browse URL from REST API self URL.
    // self = https://company.atlassian.net/rest/api/3/issue/12345
    // browse = https://company.atlassian.net/browse/PAY-456
    final uri = Uri.parse(baseUrl);
    final browseUrl = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: '/browse/${issue.key}',
    );
    if (await canLaunchUrl(browseUrl)) {
      await launchUrl(browseUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Formats a byte count into a human-readable string.
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// A section header label with optional trailing widget.
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

/// A row in the metadata grid.
class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _MetadataRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CodeOpsColors.textTertiary, size: 15),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A colored status badge.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A priority badge with icon and color.
class _PriorityBadge extends StatelessWidget {
  final JiraPriorityDisplay display;

  const _PriorityBadge({required this.display});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: display.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(display.icon, color: display.color, size: 13),
          const SizedBox(width: 3),
          Text(
            display.name,
            style: TextStyle(
              color: display.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A styled action button used in the header area.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
