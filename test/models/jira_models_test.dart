// Tests for Jira model serialization (fromJson / toJson round-trips).
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/jira_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // JiraStatusCategory
  // ---------------------------------------------------------------------------
  group('JiraStatusCategory', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 2,
        'key': 'new',
        'name': 'To Do',
        'colorName': 'blue-gray',
      };
      final obj = JiraStatusCategory.fromJson(json);
      expect(obj.id, 2);
      expect(obj.key, 'new');
      expect(obj.name, 'To Do');
      expect(obj.colorName, 'blue-gray');

      final out = obj.toJson();
      expect(out['id'], 2);
      expect(out['key'], 'new');
      expect(out['name'], 'To Do');
      expect(out['colorName'], 'blue-gray');
    });

    test('fromJson with null colorName', () {
      final json = {'id': 3, 'key': 'done', 'name': 'Done'};
      final obj = JiraStatusCategory.fromJson(json);
      expect(obj.colorName, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraStatus
  // ---------------------------------------------------------------------------
  group('JiraStatus', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': '10001',
        'name': 'In Progress',
        'statusCategory': {
          'id': 4,
          'key': 'indeterminate',
          'name': 'In Progress',
        },
      };
      final obj = JiraStatus.fromJson(json);
      expect(obj.id, '10001');
      expect(obj.name, 'In Progress');
      expect(obj.statusCategory, isNotNull);
      expect(obj.statusCategory!.key, 'indeterminate');

      final out = obj.toJson();
      expect(out['id'], '10001');
      expect(out['statusCategory'], isA<Map<String, dynamic>>());
    });

    test('fromJson with null statusCategory', () {
      final json = {'id': '1', 'name': 'Open'};
      final obj = JiraStatus.fromJson(json);
      expect(obj.statusCategory, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraIssueType
  // ---------------------------------------------------------------------------
  group('JiraIssueType', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': '10002',
        'name': 'Bug',
        'subtask': false,
        'iconUrl': 'https://jira.example.com/icon.png',
      };
      final obj = JiraIssueType.fromJson(json);
      expect(obj.id, '10002');
      expect(obj.name, 'Bug');
      expect(obj.subtask, false);
      expect(obj.iconUrl, contains('icon.png'));

      final out = obj.toJson();
      expect(out['id'], '10002');
      expect(out['subtask'], false);
    });

    test('fromJson with null iconUrl', () {
      final json = {'id': '1', 'name': 'Task', 'subtask': true};
      final obj = JiraIssueType.fromJson(json);
      expect(obj.iconUrl, isNull);
      expect(obj.subtask, true);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraPriority
  // ---------------------------------------------------------------------------
  group('JiraPriority', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': '2',
        'name': 'High',
        'iconUrl': 'https://jira.example.com/high.png',
      };
      final obj = JiraPriority.fromJson(json);
      expect(obj.id, '2');
      expect(obj.name, 'High');
      expect(obj.iconUrl, contains('high.png'));

      final out = obj.toJson();
      expect(out['name'], 'High');
    });

    test('fromJson with null iconUrl', () {
      final json = {'id': '3', 'name': 'Medium'};
      final obj = JiraPriority.fromJson(json);
      expect(obj.iconUrl, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraAvatarUrls
  // ---------------------------------------------------------------------------
  group('JiraAvatarUrls', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        '48x48': 'https://avatar/48.png',
        '32x32': 'https://avatar/32.png',
        '24x24': 'https://avatar/24.png',
        '16x16': 'https://avatar/16.png',
      };
      final obj = JiraAvatarUrls.fromJson(json);
      expect(obj.x48, 'https://avatar/48.png');
      expect(obj.x32, 'https://avatar/32.png');
      expect(obj.x24, 'https://avatar/24.png');
      expect(obj.x16, 'https://avatar/16.png');

      final out = obj.toJson();
      expect(out['48x48'], 'https://avatar/48.png');
      expect(out['16x16'], 'https://avatar/16.png');
    });

    test('fromJson with all nulls', () {
      final obj = JiraAvatarUrls.fromJson({});
      expect(obj.x48, isNull);
      expect(obj.x32, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraUser
  // ---------------------------------------------------------------------------
  group('JiraUser', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'accountId': 'abc123',
        'displayName': 'Alice',
        'emailAddress': 'alice@test.com',
        'avatarUrls': {
          '48x48': 'https://avatar/48.png',
        },
        'active': true,
      };
      final obj = JiraUser.fromJson(json);
      expect(obj.accountId, 'abc123');
      expect(obj.displayName, 'Alice');
      expect(obj.emailAddress, 'alice@test.com');
      expect(obj.avatarUrls, isNotNull);
      expect(obj.active, true);

      final out = obj.toJson();
      expect(out['accountId'], 'abc123');
      expect(out['avatarUrls'], isA<Map<String, dynamic>>());
    });

    test('fromJson with minimal fields', () {
      final json = {'accountId': 'xyz'};
      final obj = JiraUser.fromJson(json);
      expect(obj.displayName, isNull);
      expect(obj.active, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraProject
  // ---------------------------------------------------------------------------
  group('JiraProject', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': '10000',
        'key': 'PAY',
        'name': 'Payments',
        'avatarUrls': {'48x48': 'https://avatar/project.png'},
      };
      final obj = JiraProject.fromJson(json);
      expect(obj.id, '10000');
      expect(obj.key, 'PAY');
      expect(obj.name, 'Payments');
      expect(obj.avatarUrl, 'https://avatar/project.png');

      final out = obj.toJson();
      expect(out['key'], 'PAY');
    });

    test('avatarUrl returns null when avatarUrlsMap is null', () {
      final json = {'id': '1', 'key': 'X', 'name': 'X'};
      final obj = JiraProject.fromJson(json);
      expect(obj.avatarUrl, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraComponent
  // ---------------------------------------------------------------------------
  group('JiraComponent', () {
    test('fromJson / toJson round-trip', () {
      final json = {'id': '100', 'name': 'Backend'};
      final obj = JiraComponent.fromJson(json);
      expect(obj.id, '100');
      expect(obj.name, 'Backend');

      final out = obj.toJson();
      expect(out['id'], '100');
      expect(out['name'], 'Backend');
    });
  });

  // ---------------------------------------------------------------------------
  // JiraSprint
  // ---------------------------------------------------------------------------
  group('JiraSprint', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 42,
        'name': 'Sprint 7',
        'state': 'active',
        'startDate': '2025-01-01T00:00:00Z',
        'endDate': '2025-01-14T00:00:00Z',
      };
      final obj = JiraSprint.fromJson(json);
      expect(obj.id, 42);
      expect(obj.name, 'Sprint 7');
      expect(obj.state, 'active');
      expect(obj.startDate, isNotNull);
      expect(obj.endDate, isNotNull);

      final out = obj.toJson();
      expect(out['id'], 42);
      expect(out['state'], 'active');
    });

    test('fromJson with null dates', () {
      final json = {'id': 1, 'name': 'Sprint 1', 'state': 'future'};
      final obj = JiraSprint.fromJson(json);
      expect(obj.startDate, isNull);
      expect(obj.endDate, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraComment
  // ---------------------------------------------------------------------------
  group('JiraComment', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 'c-1',
        'author': {'accountId': 'u1', 'displayName': 'Bob'},
        'body': 'plain text body',
        'created': '2025-01-15T10:00:00Z',
        'updated': '2025-01-15T11:00:00Z',
      };
      final obj = JiraComment.fromJson(json);
      expect(obj.id, 'c-1');
      expect(obj.author, isNotNull);
      expect(obj.author!.displayName, 'Bob');
      expect(obj.body, 'plain text body');
      expect(obj.created, isNotNull);

      final out = obj.toJson();
      expect(out['id'], 'c-1');
    });

    test('fromJson with null optionals', () {
      final json = {'id': 'c-2'};
      final obj = JiraComment.fromJson(json);
      expect(obj.author, isNull);
      expect(obj.body, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraCommentPage
  // ---------------------------------------------------------------------------
  group('JiraCommentPage', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'total': 2,
        'maxResults': 50,
        'comments': [
          {'id': 'c-1'},
          {'id': 'c-2'},
        ],
      };
      final obj = JiraCommentPage.fromJson(json);
      expect(obj.total, 2);
      expect(obj.maxResults, 50);
      expect(obj.comments.length, 2);

      final out = obj.toJson();
      expect(out['total'], 2);
      expect((out['comments'] as List).length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraAttachment
  // ---------------------------------------------------------------------------
  group('JiraAttachment', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 'att-1',
        'filename': 'screenshot.png',
        'mimeType': 'image/png',
        'size': 12345,
        'content': 'https://jira.example.com/download/att-1',
        'author': {'accountId': 'u1'},
        'created': '2025-01-15T10:00:00Z',
      };
      final obj = JiraAttachment.fromJson(json);
      expect(obj.id, 'att-1');
      expect(obj.filename, 'screenshot.png');
      expect(obj.mimeType, 'image/png');
      expect(obj.size, 12345);
      expect(obj.content, contains('download'));
      expect(obj.author, isNotNull);

      final out = obj.toJson();
      expect(out['filename'], 'screenshot.png');
    });

    test('fromJson with null optionals', () {
      final json = {
        'id': 'att-2',
        'filename': 'log.txt',
        'content': 'https://example.com/dl',
      };
      final obj = JiraAttachment.fromJson(json);
      expect(obj.mimeType, isNull);
      expect(obj.size, isNull);
      expect(obj.author, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraIssueLinkType
  // ---------------------------------------------------------------------------
  group('JiraIssueLinkType', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'name': 'Blocks',
        'inward': 'is blocked by',
        'outward': 'blocks',
      };
      final obj = JiraIssueLinkType.fromJson(json);
      expect(obj.name, 'Blocks');
      expect(obj.inward, 'is blocked by');
      expect(obj.outward, 'blocks');

      final out = obj.toJson();
      expect(out['name'], 'Blocks');
    });
  });

  // ---------------------------------------------------------------------------
  // JiraIssueLink
  // ---------------------------------------------------------------------------
  group('JiraIssueLink', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 'link-1',
        'type': {
          'name': 'Duplicate',
          'inward': 'is duplicated by',
          'outward': 'duplicates',
        },
        'outwardIssue': {
          'id': '100',
          'key': 'PAY-10',
          'self': 'https://jira.example.com/rest/api/3/issue/100',
          'fields': {
            'summary': 'Duplicate issue',
            'issuetype': {'id': '1', 'name': 'Bug', 'subtask': false},
            'status': {'id': '1', 'name': 'Open'},
          },
        },
      };
      final obj = JiraIssueLink.fromJson(json);
      expect(obj.id, 'link-1');
      expect(obj.type.name, 'Duplicate');
      expect(obj.outwardIssue, isNotNull);
      expect(obj.outwardIssue!.key, 'PAY-10');
      expect(obj.inwardIssue, isNull);

      final out = obj.toJson();
      expect(out['type'], isA<Map<String, dynamic>>());
    });
  });

  // ---------------------------------------------------------------------------
  // JiraIssueFields
  // ---------------------------------------------------------------------------
  group('JiraIssueFields', () {
    test('fromJson / toJson round-trip with full fields', () {
      final json = {
        'summary': 'Login page crash',
        'description': 'Some description text',
        'issuetype': {'id': '1', 'name': 'Bug', 'subtask': false},
        'status': {
          'id': '1',
          'name': 'Open',
          'statusCategory': {'id': 2, 'key': 'new', 'name': 'To Do'},
        },
        'priority': {'id': '2', 'name': 'High'},
        'assignee': {'accountId': 'u1', 'displayName': 'Alice'},
        'reporter': {'accountId': 'u2', 'displayName': 'Bob'},
        'project': {'id': '10000', 'key': 'PAY', 'name': 'Payments'},
        'created': '2025-01-15T10:00:00Z',
        'updated': '2025-01-15T12:00:00Z',
        'components': [
          {'id': '100', 'name': 'Backend'},
        ],
        'labels': ['critical', 'sprint-7'],
        'comment': {
          'total': 1,
          'maxResults': 50,
          'comments': [
            {'id': 'c-1'},
          ],
        },
      };
      final obj = JiraIssueFields.fromJson(json);
      expect(obj.summary, 'Login page crash');
      expect(obj.description, 'Some description text');
      expect(obj.issuetype.name, 'Bug');
      expect(obj.status.name, 'Open');
      expect(obj.priority!.name, 'High');
      expect(obj.assignee!.displayName, 'Alice');
      expect(obj.reporter!.displayName, 'Bob');
      expect(obj.project!.key, 'PAY');
      expect(obj.components!.length, 1);
      expect(obj.labels, ['critical', 'sprint-7']);
      expect(obj.comment!.total, 1);

      final out = obj.toJson();
      expect(out['summary'], 'Login page crash');
    });

    test('fromJson with null optionals', () {
      final json = {
        'summary': 'Minimal',
        'issuetype': {'id': '1', 'name': 'Task', 'subtask': false},
        'status': {'id': '1', 'name': 'Open'},
      };
      final obj = JiraIssueFields.fromJson(json);
      expect(obj.description, isNull);
      expect(obj.priority, isNull);
      expect(obj.assignee, isNull);
      expect(obj.sprint, isNull);
      expect(obj.parent, isNull);
      expect(obj.issuelinks, isNull);
      expect(obj.attachment, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraIssue
  // ---------------------------------------------------------------------------
  group('JiraIssue', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': '10001',
        'key': 'PAY-456',
        'self': 'https://jira.example.com/rest/api/3/issue/10001',
        'fields': {
          'summary': 'Payment timeout',
          'issuetype': {'id': '1', 'name': 'Bug', 'subtask': false},
          'status': {'id': '1', 'name': 'Open'},
        },
      };
      final obj = JiraIssue.fromJson(json);
      expect(obj.id, '10001');
      expect(obj.key, 'PAY-456');
      expect(obj.self, contains('10001'));
      expect(obj.fields.summary, 'Payment timeout');

      final out = obj.toJson();
      expect(out['key'], 'PAY-456');
      expect(out['fields'], isA<Map<String, dynamic>>());
    });
  });

  // ---------------------------------------------------------------------------
  // JiraSearchResult
  // ---------------------------------------------------------------------------
  group('JiraSearchResult', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'startAt': 0,
        'maxResults': 50,
        'total': 1,
        'issues': [
          {
            'id': '1',
            'key': 'PAY-1',
            'self': 'https://jira.example.com/rest/api/3/issue/1',
            'fields': {
              'summary': 'Issue one',
              'issuetype': {'id': '1', 'name': 'Task', 'subtask': false},
              'status': {'id': '1', 'name': 'Open'},
            },
          },
        ],
      };
      final obj = JiraSearchResult.fromJson(json);
      expect(obj.startAt, 0);
      expect(obj.maxResults, 50);
      expect(obj.total, 1);
      expect(obj.issues.length, 1);
      expect(obj.issues.first.key, 'PAY-1');

      final out = obj.toJson();
      expect(out['total'], 1);
      expect((out['issues'] as List).length, 1);
    });

    test('fromJson with empty issues', () {
      final json = {
        'startAt': 0,
        'maxResults': 50,
        'total': 0,
        'issues': <Map<String, dynamic>>[],
      };
      final obj = JiraSearchResult.fromJson(json);
      expect(obj.issues, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraTransition
  // ---------------------------------------------------------------------------
  group('JiraTransition', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': '21',
        'name': 'In Progress',
        'to': {
          'id': '3',
          'name': 'In Progress',
          'statusCategory': {
            'id': 4,
            'key': 'indeterminate',
            'name': 'In Progress',
          },
        },
      };
      final obj = JiraTransition.fromJson(json);
      expect(obj.id, '21');
      expect(obj.name, 'In Progress');
      expect(obj.to.name, 'In Progress');
      expect(obj.to.statusCategory!.key, 'indeterminate');

      final out = obj.toJson();
      expect(out['id'], '21');
      expect(out['to'], isA<Map<String, dynamic>>());
    });
  });

  // ---------------------------------------------------------------------------
  // CreateJiraIssueRequest
  // ---------------------------------------------------------------------------
  group('CreateJiraIssueRequest', () {
    test('fromJson / toJson round-trip with all fields', () {
      final json = {
        'projectKey': 'PAY',
        'issueTypeName': 'Bug',
        'summary': 'Login fails',
        'description': 'Detailed description',
        'assigneeAccountId': 'u1',
        'priorityName': 'High',
        'labels': ['urgent'],
        'componentName': 'Auth',
        'parentKey': 'PAY-100',
        'sprintId': '42',
      };
      final obj = CreateJiraIssueRequest.fromJson(json);
      expect(obj.projectKey, 'PAY');
      expect(obj.issueTypeName, 'Bug');
      expect(obj.summary, 'Login fails');
      expect(obj.description, 'Detailed description');
      expect(obj.assigneeAccountId, 'u1');
      expect(obj.priorityName, 'High');
      expect(obj.labels, ['urgent']);
      expect(obj.componentName, 'Auth');
      expect(obj.parentKey, 'PAY-100');
      expect(obj.sprintId, '42');

      final out = obj.toJson();
      expect(out['projectKey'], 'PAY');
    });

    test('fromJson with required fields only', () {
      final json = {
        'projectKey': 'X',
        'issueTypeName': 'Task',
        'summary': 'Do thing',
      };
      final obj = CreateJiraIssueRequest.fromJson(json);
      expect(obj.description, isNull);
      expect(obj.labels, isNull);
      expect(obj.sprintId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CreateJiraSubTaskRequest
  // ---------------------------------------------------------------------------
  group('CreateJiraSubTaskRequest', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'parentKey': 'PAY-456',
        'projectKey': 'PAY',
        'summary': 'Sub-task 1',
        'description': 'Details',
        'assigneeAccountId': 'u1',
        'priorityName': 'Low',
      };
      final obj = CreateJiraSubTaskRequest.fromJson(json);
      expect(obj.parentKey, 'PAY-456');
      expect(obj.projectKey, 'PAY');
      expect(obj.summary, 'Sub-task 1');
      expect(obj.description, 'Details');
      expect(obj.assigneeAccountId, 'u1');
      expect(obj.priorityName, 'Low');

      final out = obj.toJson();
      expect(out['parentKey'], 'PAY-456');
    });

    test('fromJson with required fields only', () {
      final json = {
        'parentKey': 'PAY-1',
        'projectKey': 'PAY',
        'summary': 'Minimal',
      };
      final obj = CreateJiraSubTaskRequest.fromJson(json);
      expect(obj.description, isNull);
      expect(obj.assigneeAccountId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // UpdateJiraIssueRequest
  // ---------------------------------------------------------------------------
  group('UpdateJiraIssueRequest', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'assigneeAccountId': 'u2',
        'summary': 'Updated summary',
        'description': 'New description',
        'priorityName': 'Medium',
        'labels': ['backend', 'security'],
      };
      final obj = UpdateJiraIssueRequest.fromJson(json);
      expect(obj.assigneeAccountId, 'u2');
      expect(obj.summary, 'Updated summary');
      expect(obj.description, 'New description');
      expect(obj.priorityName, 'Medium');
      expect(obj.labels, ['backend', 'security']);

      final out = obj.toJson();
      expect(out['summary'], 'Updated summary');
    });

    test('fromJson with all nulls', () {
      final obj = UpdateJiraIssueRequest.fromJson({});
      expect(obj.assigneeAccountId, isNull);
      expect(obj.summary, isNull);
      expect(obj.labels, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // JiraIssueDisplayModel (constructor only, not serializable)
  // ---------------------------------------------------------------------------
  group('JiraIssueDisplayModel', () {
    test('constructor stores all fields', () {
      final now = DateTime.now();
      final model = JiraIssueDisplayModel(
        key: 'PAY-456',
        summary: 'Payment timeout',
        statusName: 'Open',
        statusCategoryKey: 'new',
        priorityName: 'High',
        priorityIconUrl: 'https://icon.png',
        assigneeName: 'Alice',
        assigneeAvatarUrl: 'https://avatar.png',
        issuetypeName: 'Bug',
        issuetypeIconUrl: 'https://type.png',
        commentCount: 3,
        attachmentCount: 1,
        linkCount: 2,
        created: now,
        updated: now,
      );
      expect(model.key, 'PAY-456');
      expect(model.summary, 'Payment timeout');
      expect(model.statusName, 'Open');
      expect(model.statusCategoryKey, 'new');
      expect(model.priorityName, 'High');
      expect(model.assigneeName, 'Alice');
      expect(model.issuetypeName, 'Bug');
      expect(model.commentCount, 3);
      expect(model.attachmentCount, 1);
      expect(model.linkCount, 2);
      expect(model.created, now);
      expect(model.updated, now);
    });

    test('constructor defaults counts to zero', () {
      const model = JiraIssueDisplayModel(
        key: 'X-1',
        summary: 'Test',
        statusName: 'Open',
      );
      expect(model.commentCount, 0);
      expect(model.attachmentCount, 0);
      expect(model.linkCount, 0);
      expect(model.statusCategoryKey, isNull);
      expect(model.created, isNull);
    });
  });
}
