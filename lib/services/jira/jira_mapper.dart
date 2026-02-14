/// Converts between Jira Cloud API models and CodeOps internal models.
///
/// Handles the mapping of Jira issue data to CodeOps bug investigation models,
/// and converts CodeOps remediation tasks to Jira issue creation requests.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/jira_models.dart';
import '../../models/remediation_task.dart';
import '../../theme/colors.dart';

/// Converts between Jira Cloud API models and CodeOps internal models.
class JiraMapper {
  JiraMapper._();

  /// Converts a Jira issue to fields needed for creating a bug investigation
  /// on the CodeOps server.
  ///
  /// Returns a map of fields matching [CreateBugInvestigationRequest].
  static Map<String, dynamic> toInvestigationFields({
    required String jobId,
    required JiraIssue issue,
    required List<JiraComment> comments,
    String? additionalContext,
  }) {
    return {
      'jobId': jobId,
      'jiraKey': issue.key,
      'jiraSummary': issue.fields.summary,
      'jiraDescription': issue.fields.description,
      'jiraCommentsJson': jsonEncode(
        comments.map((c) => c.toJson()).toList(),
      ),
      'jiraAttachmentsJson': issue.fields.attachment != null
          ? jsonEncode(
              issue.fields.attachment!.map((a) => a.toJson()).toList(),
            )
          : null,
      'jiraLinkedIssues': issue.fields.issuelinks != null
          ? jsonEncode(
              issue.fields.issuelinks!.map((l) => l.toJson()).toList(),
            )
          : null,
      if (additionalContext != null) 'additionalContext': additionalContext,
    };
  }

  /// Converts a remediation task to a Jira issue creation request.
  static CreateJiraIssueRequest taskToJiraIssue({
    required RemediationTask task,
    required String projectKey,
    required String issueTypeName,
    List<String>? labels,
    String? componentName,
    String? assigneeAccountId,
    String? sprintId,
  }) {
    final description = StringBuffer();
    if (task.description != null) {
      description.writeln(task.description);
    }
    if (task.promptMd != null) {
      description.writeln('\n---\n');
      description.writeln('**Remediation Prompt:**');
      description.writeln(task.promptMd);
    }

    return CreateJiraIssueRequest(
      projectKey: projectKey,
      issueTypeName: issueTypeName,
      summary: task.title,
      description: description.isNotEmpty ? description.toString() : null,
      assigneeAccountId: assigneeAccountId,
      labels: labels,
      componentName: componentName,
      sprintId: sprintId,
    );
  }

  /// Converts multiple tasks to bulk Jira issue creation requests.
  static List<CreateJiraIssueRequest> tasksToJiraIssues({
    required List<RemediationTask> tasks,
    required String projectKey,
    required String issueTypeName,
    List<String>? labels,
    String? componentName,
  }) {
    return tasks
        .map((task) => taskToJiraIssue(
              task: task,
              projectKey: projectKey,
              issueTypeName: issueTypeName,
              labels: labels,
              componentName: componentName,
            ))
        .toList();
  }

  /// Converts a [JiraIssue] to a simplified [JiraIssueDisplayModel].
  static JiraIssueDisplayModel toDisplayModel(JiraIssue issue) {
    final fields = issue.fields;
    return JiraIssueDisplayModel(
      key: issue.key,
      summary: fields.summary,
      statusName: fields.status.name,
      statusCategoryKey: fields.status.statusCategory?.key,
      priorityName: fields.priority?.name,
      priorityIconUrl: fields.priority?.iconUrl,
      assigneeName: fields.assignee?.displayName,
      assigneeAvatarUrl: fields.assignee?.avatarUrls?.x24,
      issuetypeName: fields.issuetype.name,
      issuetypeIconUrl: fields.issuetype.iconUrl,
      commentCount: fields.comment?.total ?? 0,
      attachmentCount: fields.attachment?.length ?? 0,
      linkCount: fields.issuelinks?.length ?? 0,
      created: fields.created != null
          ? DateTime.tryParse(fields.created!)
          : null,
      updated: fields.updated != null
          ? DateTime.tryParse(fields.updated!)
          : null,
    );
  }

  /// Converts ADF (Atlassian Document Format) JSON to plain text / markdown.
  ///
  /// Handles the common ADF node types: paragraph, heading, codeBlock,
  /// bulletList, orderedList, text, hardBreak.
  static String adfToMarkdown(String? adfJson) {
    if (adfJson == null || adfJson.isEmpty) return '';

    try {
      final dynamic parsed = jsonDecode(adfJson);
      if (parsed is! Map<String, dynamic>) return adfJson;
      final content = parsed['content'] as List<dynamic>?;
      if (content == null) return '';
      return _processAdfNodes(content);
    } catch (_) {
      // If it's not valid ADF JSON, return as-is (may be plain text).
      return adfJson;
    }
  }

  /// Converts markdown text to ADF JSON for posting to Jira.
  static String markdownToAdf(String markdown) {
    final paragraphs = markdown.split('\n\n');
    final content = <Map<String, dynamic>>[];

    for (final para in paragraphs) {
      final trimmed = para.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('```')) {
        final code = trimmed
            .replaceFirst(RegExp(r'^```\w*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
        content.add({
          'type': 'codeBlock',
          'content': [
            {'type': 'text', 'text': code},
          ],
        });
      } else if (trimmed.startsWith('### ')) {
        content.add(_adfHeading(3, trimmed.substring(4)));
      } else if (trimmed.startsWith('## ')) {
        content.add(_adfHeading(2, trimmed.substring(3)));
      } else if (trimmed.startsWith('# ')) {
        content.add(_adfHeading(1, trimmed.substring(2)));
      } else {
        content.add({
          'type': 'paragraph',
          'content': [
            {'type': 'text', 'text': trimmed},
          ],
        });
      }
    }

    if (content.isEmpty) {
      content.add({
        'type': 'paragraph',
        'content': [
          {'type': 'text', 'text': markdown},
        ],
      });
    }

    return jsonEncode({
      'version': 1,
      'type': 'doc',
      'content': content,
    });
  }

  /// Maps Jira status category to a display color.
  static Color mapStatusColor(JiraStatusCategory? category) {
    if (category == null) return CodeOpsColors.textTertiary;
    return switch (category.key) {
      'new' => CodeOpsColors.textSecondary,
      'indeterminate' => CodeOpsColors.primary,
      'done' => CodeOpsColors.success,
      _ => CodeOpsColors.textTertiary,
    };
  }

  /// Maps a status category key string to a display color.
  static Color mapStatusColorFromKey(String? categoryKey) {
    return switch (categoryKey) {
      'new' => CodeOpsColors.textSecondary,
      'indeterminate' => CodeOpsColors.primary,
      'done' => CodeOpsColors.success,
      _ => CodeOpsColors.textTertiary,
    };
  }

  /// Maps Jira priority name to display properties.
  static JiraPriorityDisplay mapPriority(String? priorityName) {
    return switch (priorityName?.toLowerCase()) {
      'highest' => const JiraPriorityDisplay(
          name: 'Highest',
          color: CodeOpsColors.critical,
          icon: Icons.keyboard_double_arrow_up,
        ),
      'high' => const JiraPriorityDisplay(
          name: 'High',
          color: CodeOpsColors.error,
          icon: Icons.keyboard_arrow_up,
        ),
      'medium' => const JiraPriorityDisplay(
          name: 'Medium',
          color: CodeOpsColors.warning,
          icon: Icons.drag_handle,
        ),
      'low' => const JiraPriorityDisplay(
          name: 'Low',
          color: CodeOpsColors.secondary,
          icon: Icons.keyboard_arrow_down,
        ),
      'lowest' => const JiraPriorityDisplay(
          name: 'Lowest',
          color: CodeOpsColors.textTertiary,
          icon: Icons.keyboard_double_arrow_down,
        ),
      _ => JiraPriorityDisplay(
          name: priorityName ?? 'None',
          color: CodeOpsColors.textTertiary,
          icon: Icons.drag_handle,
        ),
    };
  }

  // ---------------------------------------------------------------------------
  // Private ADF helpers
  // ---------------------------------------------------------------------------

  static String _processAdfNodes(List<dynamic> nodes) {
    final buffer = StringBuffer();
    for (final node in nodes) {
      if (node is! Map<String, dynamic>) continue;
      final type = node['type'] as String?;
      switch (type) {
        case 'paragraph':
          buffer.writeln(_extractText(node));
          buffer.writeln();
        case 'heading':
          final level = (node['attrs'] as Map?)?['level'] as int? ?? 1;
          final prefix = '#' * level;
          buffer.writeln('$prefix ${_extractText(node)}');
          buffer.writeln();
        case 'codeBlock':
          buffer.writeln('```');
          buffer.writeln(_extractText(node));
          buffer.writeln('```');
          buffer.writeln();
        case 'bulletList':
          final items = node['content'] as List<dynamic>? ?? [];
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              buffer.writeln('- ${_extractText(item)}');
            }
          }
          buffer.writeln();
        case 'orderedList':
          final items = node['content'] as List<dynamic>? ?? [];
          for (var i = 0; i < items.length; i++) {
            final item = items[i];
            if (item is Map<String, dynamic>) {
              buffer.writeln('${i + 1}. ${_extractText(item)}');
            }
          }
          buffer.writeln();
        case 'blockquote':
          final lines = _extractText(node).split('\n');
          for (final line in lines) {
            buffer.writeln('> $line');
          }
          buffer.writeln();
        case 'rule':
          buffer.writeln('---');
          buffer.writeln();
      }
    }
    return buffer.toString().trimRight();
  }

  static String _extractText(Map<String, dynamic> node) {
    final content = node['content'] as List<dynamic>?;
    if (content == null) return '';
    final buffer = StringBuffer();
    for (final child in content) {
      if (child is! Map<String, dynamic>) continue;
      final type = child['type'] as String?;
      if (type == 'text') {
        buffer.write(child['text'] as String? ?? '');
      } else if (type == 'hardBreak') {
        buffer.writeln();
      } else if (type == 'listItem' || type == 'paragraph') {
        buffer.write(_extractText(child));
      }
    }
    return buffer.toString();
  }

  static Map<String, dynamic> _adfHeading(int level, String text) => {
        'type': 'heading',
        'attrs': {'level': level},
        'content': [
          {'type': 'text', 'text': text},
        ],
      };
}

/// Display properties for a Jira priority.
class JiraPriorityDisplay {
  /// Display name.
  final String name;

  /// Color for badges and icons.
  final Color color;

  /// Material icon.
  final IconData icon;

  /// Creates a [JiraPriorityDisplay].
  const JiraPriorityDisplay({
    required this.name,
    required this.color,
    required this.icon,
  });
}
