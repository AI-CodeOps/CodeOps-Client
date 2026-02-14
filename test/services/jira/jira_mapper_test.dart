// Tests for JiraMapper — converts between Jira API models and CodeOps models.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/jira_models.dart';
import 'package:codeops/models/remediation_task.dart';
import 'package:codeops/models/enums.dart';
import 'package:codeops/services/jira/jira_mapper.dart';
import 'package:codeops/theme/colors.dart';

void main() {
  // ---------------------------------------------------------------------------
  // adfToMarkdown
  // ---------------------------------------------------------------------------
  group('JiraMapper.adfToMarkdown', () {
    test('returns empty string for null input', () {
      expect(JiraMapper.adfToMarkdown(null), '');
    });

    test('returns empty string for empty string input', () {
      expect(JiraMapper.adfToMarkdown(''), '');
    });

    test('returns input as-is for non-JSON strings', () {
      expect(JiraMapper.adfToMarkdown('just plain text'), 'just plain text');
    });

    test('returns input as-is for invalid JSON', () {
      expect(JiraMapper.adfToMarkdown('{not valid json'), '{not valid json');
    });

    test('converts paragraph node to text', () {
      final adf = jsonEncode({
        'version': 1,
        'type': 'doc',
        'content': [
          {
            'type': 'paragraph',
            'content': [
              {'type': 'text', 'text': 'Hello world'},
            ],
          },
        ],
      });
      final result = JiraMapper.adfToMarkdown(adf);
      expect(result, contains('Hello world'));
    });

    test('converts heading node to markdown heading', () {
      final adf = jsonEncode({
        'version': 1,
        'type': 'doc',
        'content': [
          {
            'type': 'heading',
            'attrs': {'level': 2},
            'content': [
              {'type': 'text', 'text': 'My Heading'},
            ],
          },
        ],
      });
      final result = JiraMapper.adfToMarkdown(adf);
      expect(result, contains('## My Heading'));
    });

    test('converts level 1 heading', () {
      final adf = jsonEncode({
        'version': 1,
        'type': 'doc',
        'content': [
          {
            'type': 'heading',
            'attrs': {'level': 1},
            'content': [
              {'type': 'text', 'text': 'Title'},
            ],
          },
        ],
      });
      final result = JiraMapper.adfToMarkdown(adf);
      expect(result, contains('# Title'));
    });

    test('converts codeBlock node to fenced code block', () {
      final adf = jsonEncode({
        'version': 1,
        'type': 'doc',
        'content': [
          {
            'type': 'codeBlock',
            'content': [
              {'type': 'text', 'text': 'print("hello")'},
            ],
          },
        ],
      });
      final result = JiraMapper.adfToMarkdown(adf);
      expect(result, contains('```'));
      expect(result, contains('print("hello")'));
    });

    test('converts bulletList node to markdown bullet list', () {
      final adf = jsonEncode({
        'version': 1,
        'type': 'doc',
        'content': [
          {
            'type': 'bulletList',
            'content': [
              {
                'type': 'listItem',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'Item one'},
                    ],
                  },
                ],
              },
              {
                'type': 'listItem',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'Item two'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      });
      final result = JiraMapper.adfToMarkdown(adf);
      expect(result, contains('- '));
    });

    test('converts orderedList node to numbered list', () {
      final adf = jsonEncode({
        'version': 1,
        'type': 'doc',
        'content': [
          {
            'type': 'orderedList',
            'content': [
              {
                'type': 'listItem',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'First'},
                    ],
                  },
                ],
              },
              {
                'type': 'listItem',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'Second'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      });
      final result = JiraMapper.adfToMarkdown(adf);
      expect(result, contains('1.'));
      expect(result, contains('2.'));
    });

    test('returns empty string for doc with null content', () {
      final adf = jsonEncode({
        'version': 1,
        'type': 'doc',
      });
      final result = JiraMapper.adfToMarkdown(adf);
      expect(result, '');
    });

    test('returns input as-is for non-Map JSON (e.g. array)', () {
      final adf = jsonEncode([1, 2, 3]);
      final result = JiraMapper.adfToMarkdown(adf);
      expect(result, adf);
    });
  });

  // ---------------------------------------------------------------------------
  // markdownToAdf
  // ---------------------------------------------------------------------------
  group('JiraMapper.markdownToAdf', () {
    test('converts plain paragraph to ADF', () {
      final result = JiraMapper.markdownToAdf('Hello world');
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      expect(parsed['version'], 1);
      expect(parsed['type'], 'doc');
      final content = parsed['content'] as List;
      expect(content.length, 1);
      expect(content[0]['type'], 'paragraph');
      expect(content[0]['content'][0]['text'], 'Hello world');
    });

    test('converts # heading to ADF heading level 1', () {
      final result = JiraMapper.markdownToAdf('# Title');
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      final content = parsed['content'] as List;
      expect(content[0]['type'], 'heading');
      expect(content[0]['attrs']['level'], 1);
      expect(content[0]['content'][0]['text'], 'Title');
    });

    test('converts ## heading to ADF heading level 2', () {
      final result = JiraMapper.markdownToAdf('## Subtitle');
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      final content = parsed['content'] as List;
      expect(content[0]['type'], 'heading');
      expect(content[0]['attrs']['level'], 2);
    });

    test('converts ### heading to ADF heading level 3', () {
      final result = JiraMapper.markdownToAdf('### Section');
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      final content = parsed['content'] as List;
      expect(content[0]['type'], 'heading');
      expect(content[0]['attrs']['level'], 3);
    });

    test('converts code block to ADF codeBlock', () {
      final result = JiraMapper.markdownToAdf('```\ncode here\n```');
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      final content = parsed['content'] as List;
      expect(content[0]['type'], 'codeBlock');
    });

    test('handles multiple paragraphs separated by blank lines', () {
      final result = JiraMapper.markdownToAdf('Para one\n\nPara two');
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      final content = parsed['content'] as List;
      expect(content.length, 2);
      expect(content[0]['type'], 'paragraph');
      expect(content[1]['type'], 'paragraph');
    });

    test('empty content wraps input as single paragraph', () {
      // A string with only whitespace paragraphs -> falls through to default.
      final result = JiraMapper.markdownToAdf('  ');
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      final content = parsed['content'] as List;
      expect(content.isNotEmpty, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // mapStatusColor
  // ---------------------------------------------------------------------------
  group('JiraMapper.mapStatusColor', () {
    test('returns textTertiary for null category', () {
      expect(
        JiraMapper.mapStatusColor(null),
        CodeOpsColors.textTertiary,
      );
    });

    test('returns textSecondary for "new" category', () {
      const category = JiraStatusCategory(id: 2, key: 'new', name: 'To Do');
      expect(JiraMapper.mapStatusColor(category), CodeOpsColors.textSecondary);
    });

    test('returns primary for "indeterminate" category', () {
      const category =
          JiraStatusCategory(id: 4, key: 'indeterminate', name: 'In Progress');
      expect(JiraMapper.mapStatusColor(category), CodeOpsColors.primary);
    });

    test('returns success for "done" category', () {
      const category = JiraStatusCategory(id: 3, key: 'done', name: 'Done');
      expect(JiraMapper.mapStatusColor(category), CodeOpsColors.success);
    });

    test('returns textTertiary for unknown category key', () {
      const category =
          JiraStatusCategory(id: 99, key: 'unknown', name: 'Custom');
      expect(JiraMapper.mapStatusColor(category), CodeOpsColors.textTertiary);
    });
  });

  // ---------------------------------------------------------------------------
  // mapStatusColorFromKey
  // ---------------------------------------------------------------------------
  group('JiraMapper.mapStatusColorFromKey', () {
    test('returns textSecondary for "new"', () {
      expect(
        JiraMapper.mapStatusColorFromKey('new'),
        CodeOpsColors.textSecondary,
      );
    });

    test('returns primary for "indeterminate"', () {
      expect(
        JiraMapper.mapStatusColorFromKey('indeterminate'),
        CodeOpsColors.primary,
      );
    });

    test('returns success for "done"', () {
      expect(
        JiraMapper.mapStatusColorFromKey('done'),
        CodeOpsColors.success,
      );
    });

    test('returns textTertiary for null', () {
      expect(
        JiraMapper.mapStatusColorFromKey(null),
        CodeOpsColors.textTertiary,
      );
    });

    test('returns textTertiary for unknown key', () {
      expect(
        JiraMapper.mapStatusColorFromKey('custom'),
        CodeOpsColors.textTertiary,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // mapPriority
  // ---------------------------------------------------------------------------
  group('JiraMapper.mapPriority', () {
    test('maps "Highest" to critical color and double arrow up icon', () {
      final p = JiraMapper.mapPriority('Highest');
      expect(p.name, 'Highest');
      expect(p.color, CodeOpsColors.critical);
      expect(p.icon, Icons.keyboard_double_arrow_up);
    });

    test('maps "High" to error color and arrow up icon', () {
      final p = JiraMapper.mapPriority('High');
      expect(p.name, 'High');
      expect(p.color, CodeOpsColors.error);
      expect(p.icon, Icons.keyboard_arrow_up);
    });

    test('maps "Medium" to warning color and drag handle icon', () {
      final p = JiraMapper.mapPriority('Medium');
      expect(p.name, 'Medium');
      expect(p.color, CodeOpsColors.warning);
      expect(p.icon, Icons.drag_handle);
    });

    test('maps "Low" to secondary color and arrow down icon', () {
      final p = JiraMapper.mapPriority('Low');
      expect(p.name, 'Low');
      expect(p.color, CodeOpsColors.secondary);
      expect(p.icon, Icons.keyboard_arrow_down);
    });

    test('maps "Lowest" to textTertiary color and double arrow down icon', () {
      final p = JiraMapper.mapPriority('Lowest');
      expect(p.name, 'Lowest');
      expect(p.color, CodeOpsColors.textTertiary);
      expect(p.icon, Icons.keyboard_double_arrow_down);
    });

    test('maps null to "None" with textTertiary color', () {
      final p = JiraMapper.mapPriority(null);
      expect(p.name, 'None');
      expect(p.color, CodeOpsColors.textTertiary);
      expect(p.icon, Icons.drag_handle);
    });

    test('maps unknown priority to textTertiary with original name', () {
      final p = JiraMapper.mapPriority('Custom Level');
      expect(p.name, 'Custom Level');
      expect(p.color, CodeOpsColors.textTertiary);
      expect(p.icon, Icons.drag_handle);
    });

    test('is case-insensitive', () {
      final p = JiraMapper.mapPriority('highest');
      expect(p.name, 'Highest');
      expect(p.color, CodeOpsColors.critical);
    });
  });

  // ---------------------------------------------------------------------------
  // toDisplayModel
  // ---------------------------------------------------------------------------
  group('JiraMapper.toDisplayModel', () {
    test('extracts correct fields from JiraIssue', () {
      const issue = JiraIssue(
        id: '100',
        key: 'PAY-456',
        self: 'https://jira.example.com/rest/api/3/issue/100',
        fields: JiraIssueFields(
          summary: 'Payment timeout',
          issuetype: JiraIssueType(id: '1', name: 'Bug', subtask: false),
          status: JiraStatus(
            id: '1',
            name: 'In Progress',
            statusCategory: JiraStatusCategory(
              id: 4,
              key: 'indeterminate',
              name: 'In Progress',
            ),
          ),
          priority: JiraPriority(id: '2', name: 'High'),
          assignee: JiraUser(
            accountId: 'u1',
            displayName: 'Alice',
            avatarUrls: JiraAvatarUrls(x24: 'https://avatar/24.png'),
          ),
          comment: JiraCommentPage(total: 5, maxResults: 50, comments: []),
          attachment: [
            JiraAttachment(
              id: 'att-1',
              filename: 'screen.png',
              content: 'https://dl',
            ),
          ],
          issuelinks: [
            JiraIssueLink(
              id: 'link-1',
              type: JiraIssueLinkType(
                name: 'Blocks',
                inward: 'is blocked by',
                outward: 'blocks',
              ),
            ),
          ],
          created: '2025-01-15T10:00:00Z',
          updated: '2025-01-15T12:00:00Z',
        ),
      );

      final display = JiraMapper.toDisplayModel(issue);
      expect(display.key, 'PAY-456');
      expect(display.summary, 'Payment timeout');
      expect(display.statusName, 'In Progress');
      expect(display.statusCategoryKey, 'indeterminate');
      expect(display.priorityName, 'High');
      expect(display.assigneeName, 'Alice');
      expect(display.assigneeAvatarUrl, 'https://avatar/24.png');
      expect(display.issuetypeName, 'Bug');
      expect(display.commentCount, 5);
      expect(display.attachmentCount, 1);
      expect(display.linkCount, 1);
      expect(display.created, isNotNull);
      expect(display.updated, isNotNull);
    });

    test('handles issue with null optional fields', () {
      const issue = JiraIssue(
        id: '200',
        key: 'X-1',
        self: 'https://jira.example.com/rest/api/3/issue/200',
        fields: JiraIssueFields(
          summary: 'Minimal issue',
          issuetype: JiraIssueType(id: '1', name: 'Task', subtask: false),
          status: JiraStatus(id: '1', name: 'Open'),
        ),
      );

      final display = JiraMapper.toDisplayModel(issue);
      expect(display.key, 'X-1');
      expect(display.statusCategoryKey, isNull);
      expect(display.priorityName, isNull);
      expect(display.assigneeName, isNull);
      expect(display.commentCount, 0);
      expect(display.attachmentCount, 0);
      expect(display.linkCount, 0);
      expect(display.created, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // toInvestigationFields
  // ---------------------------------------------------------------------------
  group('JiraMapper.toInvestigationFields', () {
    test('produces expected map from issue and comments', () {
      const issue = JiraIssue(
        id: '100',
        key: 'PAY-456',
        self: 'https://jira.example.com/rest/api/3/issue/100',
        fields: JiraIssueFields(
          summary: 'Payment timeout',
          description: 'Detailed description of the bug',
          issuetype: JiraIssueType(id: '1', name: 'Bug', subtask: false),
          status: JiraStatus(id: '1', name: 'Open'),
          attachment: [
            JiraAttachment(
              id: 'att-1',
              filename: 'log.txt',
              content: 'https://dl/log.txt',
            ),
          ],
          issuelinks: [
            JiraIssueLink(
              id: 'link-1',
              type: JiraIssueLinkType(
                name: 'Relates',
                inward: 'relates to',
                outward: 'relates to',
              ),
            ),
          ],
        ),
      );

      final comments = [
        const JiraComment(id: 'c-1', body: 'Comment body'),
      ];

      final fields = JiraMapper.toInvestigationFields(
        jobId: 'job-123',
        issue: issue,
        comments: comments,
        additionalContext: 'Extra info',
      );

      expect(fields['jobId'], 'job-123');
      expect(fields['jiraKey'], 'PAY-456');
      expect(fields['jiraSummary'], 'Payment timeout');
      expect(fields['jiraDescription'], 'Detailed description of the bug');
      expect(fields['jiraCommentsJson'], isNotNull);
      expect(fields['jiraAttachmentsJson'], isNotNull);
      expect(fields['jiraLinkedIssues'], isNotNull);
      expect(fields['additionalContext'], 'Extra info');
    });

    test('omits additionalContext when null', () {
      const issue = JiraIssue(
        id: '200',
        key: 'X-1',
        self: 'https://x',
        fields: JiraIssueFields(
          summary: 'Test',
          issuetype: JiraIssueType(id: '1', name: 'Task', subtask: false),
          status: JiraStatus(id: '1', name: 'Open'),
        ),
      );

      final fields = JiraMapper.toInvestigationFields(
        jobId: 'job-456',
        issue: issue,
        comments: [],
      );

      expect(fields.containsKey('additionalContext'), isFalse);
      expect(fields['jiraAttachmentsJson'], isNull);
      expect(fields['jiraLinkedIssues'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // taskToJiraIssue
  // ---------------------------------------------------------------------------
  group('JiraMapper.taskToJiraIssue', () {
    test('produces correct CreateJiraIssueRequest from task', () {
      const task = RemediationTask(
        id: 'rt-1',
        jobId: 'j-1',
        taskNumber: 1,
        title: 'Fix SQL injection in UserDao',
        description: 'Use parameterized queries instead of string concat.',
        promptMd: '**Step 1:** Replace string concat with ?.',
        status: TaskStatus.pending,
        priority: Priority.p0,
      );

      final request = JiraMapper.taskToJiraIssue(
        task: task,
        projectKey: 'PAY',
        issueTypeName: 'Bug',
        labels: ['security', 'codeops'],
        componentName: 'Backend',
        assigneeAccountId: 'u1',
        sprintId: '42',
      );

      expect(request.projectKey, 'PAY');
      expect(request.issueTypeName, 'Bug');
      expect(request.summary, 'Fix SQL injection in UserDao');
      expect(request.description, contains('Use parameterized queries'));
      expect(request.description, contains('Remediation Prompt'));
      expect(request.labels, ['security', 'codeops']);
      expect(request.componentName, 'Backend');
      expect(request.assigneeAccountId, 'u1');
      expect(request.sprintId, '42');
    });

    test('handles task with null description and promptMd', () {
      const task = RemediationTask(
        id: 'rt-2',
        jobId: 'j-1',
        taskNumber: 2,
        title: 'Update docs',
        status: TaskStatus.pending,
      );

      final request = JiraMapper.taskToJiraIssue(
        task: task,
        projectKey: 'PAY',
        issueTypeName: 'Task',
      );

      expect(request.summary, 'Update docs');
      // When both description and promptMd are null, description should be null.
      expect(request.description, isNull);
      expect(request.labels, isNull);
      expect(request.componentName, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // tasksToJiraIssues
  // ---------------------------------------------------------------------------
  group('JiraMapper.tasksToJiraIssues', () {
    test('converts multiple tasks to list of requests', () {
      const tasks = [
        RemediationTask(
          id: 'rt-1',
          jobId: 'j-1',
          taskNumber: 1,
          title: 'Task one',
          status: TaskStatus.pending,
        ),
        RemediationTask(
          id: 'rt-2',
          jobId: 'j-1',
          taskNumber: 2,
          title: 'Task two',
          description: 'Has description',
          status: TaskStatus.assigned,
        ),
      ];

      final requests = JiraMapper.tasksToJiraIssues(
        tasks: tasks,
        projectKey: 'PAY',
        issueTypeName: 'Task',
        labels: ['codeops'],
      );

      expect(requests.length, 2);
      expect(requests[0].summary, 'Task one');
      expect(requests[0].projectKey, 'PAY');
      expect(requests[0].labels, ['codeops']);
      expect(requests[1].summary, 'Task two');
      expect(requests[1].description, contains('Has description'));
    });

    test('returns empty list for empty tasks', () {
      final requests = JiraMapper.tasksToJiraIssues(
        tasks: [],
        projectKey: 'PAY',
        issueTypeName: 'Bug',
      );
      expect(requests, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraPriorityDisplay
  // ---------------------------------------------------------------------------
  group('JiraPriorityDisplay', () {
    test('constructor stores all fields', () {
      const display = JiraPriorityDisplay(
        name: 'High',
        color: CodeOpsColors.error,
        icon: Icons.keyboard_arrow_up,
      );
      expect(display.name, 'High');
      expect(display.color, CodeOpsColors.error);
      expect(display.icon, Icons.keyboard_arrow_up);
    });
  });
}
