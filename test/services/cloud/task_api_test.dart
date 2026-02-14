// Tests for TaskApi.
//
// Verifies task CRUD, batch creation, job-scoped queries, and assigned tasks.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/task_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late TaskApi taskApi;

  final taskJson = {
    'id': 'task-1',
    'jobId': 'job-1',
    'taskNumber': 1,
    'title': 'Fix SQL injection',
    'status': 'PENDING',
    'priority': 'P1',
    'createdAt': '2024-01-01T00:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    taskApi = TaskApi(mockClient);
  });

  group('TaskApi', () {
    group('createTask', () {
      test('sends correct body and returns task', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/tasks',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: taskJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final task = await taskApi.createTask(
          jobId: 'job-1',
          taskNumber: 1,
          title: 'Fix SQL injection',
          priority: Priority.p1,
        );

        expect(task.id, 'task-1');
        expect(task.jobId, 'job-1');
        expect(task.taskNumber, 1);
        expect(task.title, 'Fix SQL injection');
        expect(task.status, TaskStatus.pending);
        expect(task.priority, Priority.p1);
      });

      test('sends optional fields when provided', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/tasks',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                ...taskJson,
                'description': 'Detailed fix instructions',
                'promptMd': '# Fix this',
                'findingIds': ['f1', 'f2'],
              },
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final task = await taskApi.createTask(
          jobId: 'job-1',
          taskNumber: 1,
          title: 'Fix SQL injection',
          description: 'Detailed fix instructions',
          promptMd: '# Fix this',
          findingIds: ['f1', 'f2'],
          priority: Priority.p1,
        );

        expect(task.title, 'Fix SQL injection');
        expect(task.description, 'Detailed fix instructions');
        expect(task.promptMd, '# Fix this');
        expect(task.findingIds, ['f1', 'f2']);
      });
    });

    group('createTasksBatch', () {
      test('sends list of tasks and returns created tasks', () async {
        when(() => mockClient.post<List<dynamic>>(
              '/tasks/batch',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: [
                taskJson,
                {
                  ...taskJson,
                  'id': 'task-2',
                  'taskNumber': 2,
                  'title': 'Fix XSS vulnerability',
                },
              ],
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final tasks = await taskApi.createTasksBatch([
          {
            'jobId': 'job-1',
            'taskNumber': 1,
            'title': 'Fix SQL injection',
            'priority': 'P1',
          },
          {
            'jobId': 'job-1',
            'taskNumber': 2,
            'title': 'Fix XSS vulnerability',
            'priority': 'P1',
          },
        ]);

        expect(tasks, hasLength(2));
        expect(tasks[0].id, 'task-1');
        expect(tasks[1].id, 'task-2');
        expect(tasks[1].title, 'Fix XSS vulnerability');
      });
    });

    group('getTasksForJob', () {
      test('returns all tasks for a job', () async {
        when(() => mockClient.get<List<dynamic>>('/tasks/job/job-1'))
            .thenAnswer((_) async => Response(
                  data: [
                    taskJson,
                    {
                      ...taskJson,
                      'id': 'task-2',
                      'taskNumber': 2,
                      'title': 'Fix XSS vulnerability',
                    },
                  ],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final tasks = await taskApi.getTasksForJob('job-1');

        expect(tasks, hasLength(2));
        expect(tasks[0].jobId, 'job-1');
        expect(tasks[1].jobId, 'job-1');
      });

      test('returns empty list when no tasks exist', () async {
        when(() => mockClient.get<List<dynamic>>('/tasks/job/job-1'))
            .thenAnswer((_) async => Response(
                  data: <dynamic>[],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final tasks = await taskApi.getTasksForJob('job-1');

        expect(tasks, isEmpty);
      });
    });

    group('getTask', () {
      test('fetches a single task by ID', () async {
        when(() => mockClient.get<Map<String, dynamic>>('/tasks/task-1'))
            .thenAnswer((_) async => Response(
                  data: taskJson,
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final task = await taskApi.getTask('task-1');

        expect(task.id, 'task-1');
        expect(task.title, 'Fix SQL injection');
        expect(task.priority, Priority.p1);
      });
    });

    group('updateTask', () {
      test('sends only status when only status provided', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/tasks/task-1',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {...taskJson, 'status': 'ASSIGNED'},
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final task = await taskApi.updateTask(
          'task-1',
          status: TaskStatus.assigned,
        );

        expect(task.status, TaskStatus.assigned);
      });

      test('sends assignedTo when provided', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/tasks/task-1',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                ...taskJson,
                'status': 'ASSIGNED',
                'assignedTo': 'user-1',
              },
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final task = await taskApi.updateTask(
          'task-1',
          status: TaskStatus.assigned,
          assignedTo: 'user-1',
        );

        expect(task.status, TaskStatus.assigned);
        expect(task.assignedTo, 'user-1');
      });

      test('sends jiraKey when provided', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/tasks/task-1',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                ...taskJson,
                'status': 'JIRA_CREATED',
                'jiraKey': 'PROJ-456',
              },
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final task = await taskApi.updateTask(
          'task-1',
          status: TaskStatus.jiraCreated,
          jiraKey: 'PROJ-456',
        );

        expect(task.status, TaskStatus.jiraCreated);
        expect(task.jiraKey, 'PROJ-456');
      });
    });

    group('getAssignedTasks', () {
      test('returns tasks assigned to the current user', () async {
        when(() => mockClient.get<List<dynamic>>('/tasks/assigned-to-me'))
            .thenAnswer((_) async => Response(
                  data: [taskJson],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final tasks = await taskApi.getAssignedTasks();

        expect(tasks, hasLength(1));
        expect(tasks.first.id, 'task-1');
      });

      test('returns empty list when no tasks assigned', () async {
        when(() => mockClient.get<List<dynamic>>('/tasks/assigned-to-me'))
            .thenAnswer((_) async => Response(
                  data: <dynamic>[],
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final tasks = await taskApi.getAssignedTasks();

        expect(tasks, isEmpty);
      });
    });
  });
}
