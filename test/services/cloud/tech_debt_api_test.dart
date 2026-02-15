// Tests for TechDebtApi.
//
// Verifies all 9 endpoints: CRUD, batch creation, filtering by status/category,
// status updates, deletion, and debt summary.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/tech_debt_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late TechDebtApi techDebtApi;

  final itemJson = {
    'id': 'debt-1',
    'projectId': 'proj-1',
    'category': 'CODE',
    'title': 'Duplicated validation logic',
    'description': 'The same validation is repeated in 3 controllers.',
    'filePath': 'src/controllers/UserController.java',
    'effortEstimate': 'M',
    'businessImpact': 'MEDIUM',
    'status': 'IDENTIFIED',
    'firstDetectedJobId': 'job-1',
    'createdAt': '2024-06-01T10:00:00.000Z',
    'updatedAt': '2024-06-01T10:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    techDebtApi = TechDebtApi(mockClient);
  });

  group('TechDebtApi', () {
    // -----------------------------------------------------------------------
    // createTechDebtItem
    // -----------------------------------------------------------------------
    group('createTechDebtItem', () {
      test('sends required fields and returns created item', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/tech-debt',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: itemJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final item = await techDebtApi.createTechDebtItem(
          projectId: 'proj-1',
          category: DebtCategory.code,
          title: 'Duplicated validation logic',
        );

        expect(item.id, 'debt-1');
        expect(item.projectId, 'proj-1');
        expect(item.category, DebtCategory.code);
        expect(item.title, 'Duplicated validation logic');
        expect(item.status, DebtStatus.identified);
      });

      test('sends all optional fields when provided', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/tech-debt',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: itemJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final item = await techDebtApi.createTechDebtItem(
          projectId: 'proj-1',
          category: DebtCategory.code,
          title: 'Duplicated validation logic',
          description: 'The same validation is repeated in 3 controllers.',
          filePath: 'src/controllers/UserController.java',
          effortEstimate: Effort.m,
          businessImpact: BusinessImpact.medium,
          firstDetectedJobId: 'job-1',
        );

        expect(item.description, 'The same validation is repeated in 3 controllers.');
        expect(item.filePath, 'src/controllers/UserController.java');
        expect(item.effortEstimate, Effort.m);
        expect(item.businessImpact, BusinessImpact.medium);
        expect(item.firstDetectedJobId, 'job-1');

        final captured = verify(() => mockClient.post<Map<String, dynamic>>(
              '/tech-debt',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;

        expect(captured['projectId'], 'proj-1');
        expect(captured['category'], 'CODE');
        expect(captured['title'], 'Duplicated validation logic');
        expect(captured['description'], 'The same validation is repeated in 3 controllers.');
        expect(captured['filePath'], 'src/controllers/UserController.java');
        expect(captured['effortEstimate'], 'M');
        expect(captured['businessImpact'], 'MEDIUM');
        expect(captured['firstDetectedJobId'], 'job-1');
      });

      test('omits optional fields when not provided', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/tech-debt',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {
                'id': 'debt-2',
                'projectId': 'proj-1',
                'category': 'ARCHITECTURE',
                'title': 'Monolith coupling',
                'status': 'IDENTIFIED',
              },
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await techDebtApi.createTechDebtItem(
          projectId: 'proj-1',
          category: DebtCategory.architecture,
          title: 'Monolith coupling',
        );

        final captured = verify(() => mockClient.post<Map<String, dynamic>>(
              '/tech-debt',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;

        expect(captured.containsKey('description'), false);
        expect(captured.containsKey('filePath'), false);
        expect(captured.containsKey('effortEstimate'), false);
        expect(captured.containsKey('businessImpact'), false);
        expect(captured.containsKey('firstDetectedJobId'), false);
      });
    });

    // -----------------------------------------------------------------------
    // createTechDebtItems (batch)
    // -----------------------------------------------------------------------
    group('createTechDebtItems', () {
      test('sends array body and returns list', () async {
        when(() => mockClient.post<List<dynamic>>(
              '/tech-debt/batch',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: [
                itemJson,
                {
                  ...itemJson,
                  'id': 'debt-2',
                  'title': 'Missing tests',
                  'category': 'TEST',
                },
              ],
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final batchItems = [
          {'projectId': 'proj-1', 'category': 'CODE', 'title': 'Duplicated validation logic'},
          {'projectId': 'proj-1', 'category': 'TEST', 'title': 'Missing tests'},
        ];

        final items = await techDebtApi.createTechDebtItems(batchItems);

        expect(items, hasLength(2));
        expect(items[0].id, 'debt-1');
        expect(items[1].id, 'debt-2');
        expect(items[1].category, DebtCategory.test);

        verify(() => mockClient.post<List<dynamic>>(
              '/tech-debt/batch',
              data: batchItems,
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getTechDebtItem
    // -----------------------------------------------------------------------
    group('getTechDebtItem', () {
      test('returns single item by ID', () async {
        when(() => mockClient.get<Map<String, dynamic>>('/tech-debt/debt-1'))
            .thenAnswer((_) async => Response(
                  data: itemJson,
                  requestOptions: RequestOptions(),
                  statusCode: 200,
                ));

        final item = await techDebtApi.getTechDebtItem('debt-1');

        expect(item.id, 'debt-1');
        expect(item.title, 'Duplicated validation logic');
        expect(item.category, DebtCategory.code);
      });
    });

    // -----------------------------------------------------------------------
    // getTechDebtForProject (paginated)
    // -----------------------------------------------------------------------
    group('getTechDebtForProject', () {
      test('returns paginated response with default params', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/tech-debt/project/proj-1',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'content': [itemJson],
                'page': 0,
                'size': 20,
                'totalElements': 1,
                'totalPages': 1,
                'isLast': true,
              },
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final page = await techDebtApi.getTechDebtForProject('proj-1');

        expect(page.content, hasLength(1));
        expect(page.content.first.id, 'debt-1');
        expect(page.totalElements, 1);
        expect(page.isLast, true);
      });

      test('sends custom page and size parameters', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/tech-debt/project/proj-1',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'content': <Map<String, dynamic>>[],
                'page': 2,
                'size': 5,
                'totalElements': 11,
                'totalPages': 3,
                'isLast': true,
              },
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await techDebtApi.getTechDebtForProject('proj-1', page: 2, size: 5);

        verify(() => mockClient.get<Map<String, dynamic>>(
              '/tech-debt/project/proj-1',
              queryParameters: {'page': 2, 'size': 5},
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getTechDebtByStatus — path construction for each DebtStatus value
    // -----------------------------------------------------------------------
    group('getTechDebtByStatus', () {
      final pageData = {
        'content': <Map<String, dynamic>>[],
        'page': 0,
        'size': 20,
        'totalElements': 0,
        'totalPages': 0,
        'isLast': true,
      };

      for (final status in DebtStatus.values) {
        test('uses correct path for ${status.toJson()}', () async {
          when(() => mockClient.get<Map<String, dynamic>>(
                '/tech-debt/project/proj-1/status/${status.toJson()}',
                queryParameters: any(named: 'queryParameters'),
              )).thenAnswer((_) async => Response(
                data: pageData,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

          await techDebtApi.getTechDebtByStatus('proj-1', status);

          verify(() => mockClient.get<Map<String, dynamic>>(
                '/tech-debt/project/proj-1/status/${status.toJson()}',
                queryParameters: {'page': 0, 'size': 20},
              )).called(1);
        });
      }
    });

    // -----------------------------------------------------------------------
    // getTechDebtByCategory — path construction for each DebtCategory value
    // -----------------------------------------------------------------------
    group('getTechDebtByCategory', () {
      final pageData = {
        'content': <Map<String, dynamic>>[],
        'page': 0,
        'size': 20,
        'totalElements': 0,
        'totalPages': 0,
        'isLast': true,
      };

      for (final category in DebtCategory.values) {
        test('uses correct path for ${category.toJson()}', () async {
          when(() => mockClient.get<Map<String, dynamic>>(
                '/tech-debt/project/proj-1/category/${category.toJson()}',
                queryParameters: any(named: 'queryParameters'),
              )).thenAnswer((_) async => Response(
                data: pageData,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

          await techDebtApi.getTechDebtByCategory('proj-1', category);

          verify(() => mockClient.get<Map<String, dynamic>>(
                '/tech-debt/project/proj-1/category/${category.toJson()}',
                queryParameters: {'page': 0, 'size': 20},
              )).called(1);
        });
      }
    });

    // -----------------------------------------------------------------------
    // updateTechDebtStatus
    // -----------------------------------------------------------------------
    group('updateTechDebtStatus', () {
      test('sends status in PUT body', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/tech-debt/debt-1/status',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {...itemJson, 'status': 'RESOLVED', 'resolvedJobId': 'job-5'},
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final item = await techDebtApi.updateTechDebtStatus(
          'debt-1',
          status: DebtStatus.resolved,
          resolvedJobId: 'job-5',
        );

        expect(item.status, DebtStatus.resolved);
        expect(item.resolvedJobId, 'job-5');

        final captured = verify(() => mockClient.put<Map<String, dynamic>>(
              '/tech-debt/debt-1/status',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;

        expect(captured['status'], 'RESOLVED');
        expect(captured['resolvedJobId'], 'job-5');
      });

      test('omits resolvedJobId when not provided', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/tech-debt/debt-1/status',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {...itemJson, 'status': 'PLANNED'},
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await techDebtApi.updateTechDebtStatus(
          'debt-1',
          status: DebtStatus.planned,
        );

        final captured = verify(() => mockClient.put<Map<String, dynamic>>(
              '/tech-debt/debt-1/status',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;

        expect(captured['status'], 'PLANNED');
        expect(captured.containsKey('resolvedJobId'), false);
      });
    });

    // -----------------------------------------------------------------------
    // deleteTechDebtItem
    // -----------------------------------------------------------------------
    group('deleteTechDebtItem', () {
      test('calls DELETE endpoint and completes', () async {
        when(() => mockClient.delete('/tech-debt/debt-1'))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(),
                  statusCode: 204,
                ));

        await techDebtApi.deleteTechDebtItem('debt-1');

        verify(() => mockClient.delete('/tech-debt/debt-1')).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getDebtSummary
    // -----------------------------------------------------------------------
    group('getDebtSummary', () {
      test('deserializes summary map', () async {
        final summaryData = {
          'totalItems': 42,
          'resolvedItems': 15,
          'identifiedItems': 20,
          'plannedItems': 5,
          'inProgressItems': 2,
          'debtScore': 128,
        };

        when(() => mockClient.get<Map<String, dynamic>>(
              '/tech-debt/project/proj-1/summary',
            )).thenAnswer((_) async => Response(
              data: summaryData,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final summary = await techDebtApi.getDebtSummary('proj-1');

        expect(summary['totalItems'], 42);
        expect(summary['resolvedItems'], 15);
        expect(summary['debtScore'], 128);
      });
    });

    // -----------------------------------------------------------------------
    // Error responses
    // -----------------------------------------------------------------------
    group('error responses', () {
      test('401 unauthorized throws DioException', () async {
        when(() => mockClient.get<Map<String, dynamic>>('/tech-debt/debt-1'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/tech-debt/debt-1'),
              response: Response(
                statusCode: 401,
                data: {'message': 'Unauthorized'},
                requestOptions: RequestOptions(path: '/tech-debt/debt-1'),
              ),
              type: DioExceptionType.badResponse,
            ));

        expect(
          () => techDebtApi.getTechDebtItem('debt-1'),
          throwsA(isA<DioException>()),
        );
      });

      test('403 forbidden throws DioException', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/tech-debt/project/proj-1',
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: '/tech-debt/project/proj-1'),
              response: Response(
                statusCode: 403,
                data: {'message': 'Forbidden'},
                requestOptions: RequestOptions(path: '/tech-debt/project/proj-1'),
              ),
              type: DioExceptionType.badResponse,
            ));

        expect(
          () => techDebtApi.getTechDebtForProject('proj-1'),
          throwsA(isA<DioException>()),
        );
      });

      test('404 not found throws DioException', () async {
        when(() => mockClient.get<Map<String, dynamic>>('/tech-debt/nonexistent'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/tech-debt/nonexistent'),
              response: Response(
                statusCode: 404,
                data: {'message': 'Not found'},
                requestOptions: RequestOptions(path: '/tech-debt/nonexistent'),
              ),
              type: DioExceptionType.badResponse,
            ));

        expect(
          () => techDebtApi.getTechDebtItem('nonexistent'),
          throwsA(isA<DioException>()),
        );
      });

      test('500 server error throws DioException', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/tech-debt',
              data: any(named: 'data'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: '/tech-debt'),
              response: Response(
                statusCode: 500,
                data: {'message': 'Internal server error'},
                requestOptions: RequestOptions(path: '/tech-debt'),
              ),
              type: DioExceptionType.badResponse,
            ));

        expect(
          () => techDebtApi.createTechDebtItem(
            projectId: 'proj-1',
            category: DebtCategory.code,
            title: 'Test',
          ),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
