// Tests for DependencyApi.
//
// Verifies all 10 endpoints: scan CRUD, latest scan, vulnerability creation
// (single and batch), filtering by severity, open vulns, and status updates.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/dependency_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late DependencyApi dependencyApi;

  final scanJson = {
    'id': 'scan-1',
    'projectId': 'proj-1',
    'jobId': 'job-1',
    'manifestFile': 'pubspec.yaml',
    'totalDependencies': 45,
    'outdatedCount': 8,
    'vulnerableCount': 3,
    'createdAt': '2024-06-01T10:00:00.000Z',
  };

  final vulnJson = {
    'id': 'vuln-1',
    'scanId': 'scan-1',
    'dependencyName': 'lodash',
    'currentVersion': '4.17.20',
    'fixedVersion': '4.17.21',
    'cveId': 'CVE-2021-23337',
    'severity': 'HIGH',
    'description': 'Command injection via template',
    'status': 'OPEN',
    'createdAt': '2024-06-01T10:00:00.000Z',
  };

  final pageData = {
    'content': <Map<String, dynamic>>[],
    'page': 0,
    'size': 20,
    'totalElements': 0,
    'totalPages': 0,
    'isLast': true,
  };

  setUp(() {
    mockClient = MockApiClient();
    dependencyApi = DependencyApi(mockClient);
  });

  group('DependencyApi', () {
    // -----------------------------------------------------------------------
    // createScan
    // -----------------------------------------------------------------------
    group('createScan', () {
      test('sends required projectId and returns created scan', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/scans',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: scanJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final scan = await dependencyApi.createScan(projectId: 'proj-1');

        expect(scan.id, 'scan-1');
        expect(scan.projectId, 'proj-1');
        expect(scan.totalDependencies, 45);
      });

      test('sends all optional fields when provided', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/scans',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: scanJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await dependencyApi.createScan(
          projectId: 'proj-1',
          jobId: 'job-1',
          manifestFile: 'pubspec.yaml',
          totalDependencies: 45,
          outdatedCount: 8,
          vulnerableCount: 3,
          scanDataJson: '{"details":"scan data"}',
        );

        final captured = verify(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/scans',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;

        expect(captured['projectId'], 'proj-1');
        expect(captured['jobId'], 'job-1');
        expect(captured['manifestFile'], 'pubspec.yaml');
        expect(captured['totalDependencies'], 45);
        expect(captured['outdatedCount'], 8);
        expect(captured['vulnerableCount'], 3);
        expect(captured['scanDataJson'], '{"details":"scan data"}');
      });

      test('omits optional fields when not provided', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/scans',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: {'id': 'scan-2', 'projectId': 'proj-1'},
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await dependencyApi.createScan(projectId: 'proj-1');

        final captured = verify(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/scans',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;

        expect(captured.length, 1);
        expect(captured['projectId'], 'proj-1');
      });
    });

    // -----------------------------------------------------------------------
    // getScan
    // -----------------------------------------------------------------------
    group('getScan', () {
      test('returns single scan by ID', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/scans/scan-1',
            )).thenAnswer((_) async => Response(
              data: scanJson,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final scan = await dependencyApi.getScan('scan-1');

        expect(scan.id, 'scan-1');
        expect(scan.manifestFile, 'pubspec.yaml');
        expect(scan.outdatedCount, 8);
        expect(scan.vulnerableCount, 3);
      });
    });

    // -----------------------------------------------------------------------
    // getScansForProject (paginated)
    // -----------------------------------------------------------------------
    group('getScansForProject', () {
      test('returns paginated response', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/scans/project/proj-1',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'content': [scanJson],
                'page': 0,
                'size': 20,
                'totalElements': 1,
                'totalPages': 1,
                'isLast': true,
              },
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final page = await dependencyApi.getScansForProject('proj-1');

        expect(page.content, hasLength(1));
        expect(page.content.first.id, 'scan-1');
        expect(page.totalElements, 1);
      });

      test('sends custom pagination parameters', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/scans/project/proj-1',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: pageData,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await dependencyApi.getScansForProject('proj-1', page: 3, size: 10);

        verify(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/scans/project/proj-1',
              queryParameters: {'page': 3, 'size': 10},
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getLatestScan (single response, not paginated)
    // -----------------------------------------------------------------------
    group('getLatestScan', () {
      test('returns single scan (not paginated)', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/scans/project/proj-1/latest',
            )).thenAnswer((_) async => Response(
              data: scanJson,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final scan = await dependencyApi.getLatestScan('proj-1');

        expect(scan.id, 'scan-1');
        expect(scan.projectId, 'proj-1');
      });
    });

    // -----------------------------------------------------------------------
    // addVulnerability
    // -----------------------------------------------------------------------
    group('addVulnerability', () {
      test('sends required fields and returns created vulnerability', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/vulnerabilities',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: vulnJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final vuln = await dependencyApi.addVulnerability(
          scanId: 'scan-1',
          dependencyName: 'lodash',
          severity: Severity.high,
        );

        expect(vuln.id, 'vuln-1');
        expect(vuln.dependencyName, 'lodash');
        expect(vuln.severity, Severity.high);
        expect(vuln.status, VulnerabilityStatus.open);
      });

      test('sends all optional fields when provided', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/vulnerabilities',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: vulnJson,
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        await dependencyApi.addVulnerability(
          scanId: 'scan-1',
          dependencyName: 'lodash',
          severity: Severity.high,
          currentVersion: '4.17.20',
          fixedVersion: '4.17.21',
          cveId: 'CVE-2021-23337',
          description: 'Command injection via template',
        );

        final captured = verify(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/vulnerabilities',
              data: captureAny(named: 'data'),
            )).captured.single as Map<String, dynamic>;

        expect(captured['scanId'], 'scan-1');
        expect(captured['dependencyName'], 'lodash');
        expect(captured['severity'], 'HIGH');
        expect(captured['currentVersion'], '4.17.20');
        expect(captured['fixedVersion'], '4.17.21');
        expect(captured['cveId'], 'CVE-2021-23337');
        expect(captured['description'], 'Command injection via template');
      });
    });

    // -----------------------------------------------------------------------
    // addVulnerabilities (batch)
    // -----------------------------------------------------------------------
    group('addVulnerabilities', () {
      test('sends array body and returns list', () async {
        when(() => mockClient.post<List<dynamic>>(
              '/dependencies/vulnerabilities/batch',
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response(
              data: [
                vulnJson,
                {
                  ...vulnJson,
                  'id': 'vuln-2',
                  'dependencyName': 'express',
                  'severity': 'CRITICAL',
                },
              ],
              requestOptions: RequestOptions(),
              statusCode: 201,
            ));

        final batchVulns = [
          {'scanId': 'scan-1', 'dependencyName': 'lodash', 'severity': 'HIGH'},
          {'scanId': 'scan-1', 'dependencyName': 'express', 'severity': 'CRITICAL'},
        ];

        final vulns = await dependencyApi.addVulnerabilities(batchVulns);

        expect(vulns, hasLength(2));
        expect(vulns[0].dependencyName, 'lodash');
        expect(vulns[1].dependencyName, 'express');
        expect(vulns[1].severity, Severity.critical);

        verify(() => mockClient.post<List<dynamic>>(
              '/dependencies/vulnerabilities/batch',
              data: batchVulns,
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getVulnerabilities (paginated)
    // -----------------------------------------------------------------------
    group('getVulnerabilities', () {
      test('returns paginated vulnerabilities for a scan', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/scan/scan-1',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'content': [vulnJson],
                'page': 0,
                'size': 20,
                'totalElements': 1,
                'totalPages': 1,
                'isLast': true,
              },
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final page = await dependencyApi.getVulnerabilities('scan-1');

        expect(page.content, hasLength(1));
        expect(page.content.first.dependencyName, 'lodash');
      });

      test('sends custom pagination parameters', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/scan/scan-1',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: pageData,
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await dependencyApi.getVulnerabilities('scan-1', page: 1, size: 10);

        verify(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/scan/scan-1',
              queryParameters: {'page': 1, 'size': 10},
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // getVulnerabilitiesBySeverity — path for each Severity value
    // -----------------------------------------------------------------------
    group('getVulnerabilitiesBySeverity', () {
      for (final severity in Severity.values) {
        test('uses correct path for ${severity.toJson()}', () async {
          when(() => mockClient.get<Map<String, dynamic>>(
                '/dependencies/vulnerabilities/scan/scan-1/severity/${severity.toJson()}',
                queryParameters: any(named: 'queryParameters'),
              )).thenAnswer((_) async => Response(
                data: pageData,
                requestOptions: RequestOptions(),
                statusCode: 200,
              ));

          await dependencyApi.getVulnerabilitiesBySeverity('scan-1', severity);

          verify(() => mockClient.get<Map<String, dynamic>>(
                '/dependencies/vulnerabilities/scan/scan-1/severity/${severity.toJson()}',
                queryParameters: {'page': 0, 'size': 20},
              )).called(1);
        });
      }
    });

    // -----------------------------------------------------------------------
    // getOpenVulnerabilities
    // -----------------------------------------------------------------------
    group('getOpenVulnerabilities', () {
      test('uses correct /open path', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/scan/scan-1/open',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {
                'content': [vulnJson],
                'page': 0,
                'size': 20,
                'totalElements': 1,
                'totalPages': 1,
                'isLast': true,
              },
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final page = await dependencyApi.getOpenVulnerabilities('scan-1');

        expect(page.content, hasLength(1));
        expect(page.content.first.status, VulnerabilityStatus.open);

        verify(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/scan/scan-1/open',
              queryParameters: {'page': 0, 'size': 20},
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // updateVulnerabilityStatus — status as QUERY PARAMETER (not body)
    // -----------------------------------------------------------------------
    group('updateVulnerabilityStatus', () {
      test('sends status as query parameter, not body', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/vuln-1/status',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {...vulnJson, 'status': 'RESOLVED'},
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        final vuln = await dependencyApi.updateVulnerabilityStatus(
          'vuln-1',
          VulnerabilityStatus.resolved,
        );

        expect(vuln.status, VulnerabilityStatus.resolved);

        verify(() => mockClient.put<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/vuln-1/status',
              queryParameters: {'status': 'RESOLVED'},
            )).called(1);
      });

      test('sends UPDATING status as query parameter', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/vuln-1/status',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {...vulnJson, 'status': 'UPDATING'},
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await dependencyApi.updateVulnerabilityStatus(
          'vuln-1',
          VulnerabilityStatus.updating,
        );

        verify(() => mockClient.put<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/vuln-1/status',
              queryParameters: {'status': 'UPDATING'},
            )).called(1);
      });

      test('sends SUPPRESSED status as query parameter', () async {
        when(() => mockClient.put<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/vuln-1/status',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: {...vulnJson, 'status': 'SUPPRESSED'},
              requestOptions: RequestOptions(),
              statusCode: 200,
            ));

        await dependencyApi.updateVulnerabilityStatus(
          'vuln-1',
          VulnerabilityStatus.suppressed,
        );

        verify(() => mockClient.put<Map<String, dynamic>>(
              '/dependencies/vulnerabilities/vuln-1/status',
              queryParameters: {'status': 'SUPPRESSED'},
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // Error responses
    // -----------------------------------------------------------------------
    group('error responses', () {
      test('401 unauthorized throws DioException', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/scans/scan-1',
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: '/dependencies/scans/scan-1'),
              response: Response(
                statusCode: 401,
                data: {'message': 'Unauthorized'},
                requestOptions: RequestOptions(path: '/dependencies/scans/scan-1'),
              ),
              type: DioExceptionType.badResponse,
            ));

        expect(
          () => dependencyApi.getScan('scan-1'),
          throwsA(isA<DioException>()),
        );
      });

      test('403 forbidden throws DioException', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/scans',
              data: any(named: 'data'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: '/dependencies/scans'),
              response: Response(
                statusCode: 403,
                data: {'message': 'Forbidden'},
                requestOptions: RequestOptions(path: '/dependencies/scans'),
              ),
              type: DioExceptionType.badResponse,
            ));

        expect(
          () => dependencyApi.createScan(projectId: 'proj-1'),
          throwsA(isA<DioException>()),
        );
      });

      test('404 not found throws DioException', () async {
        when(() => mockClient.get<Map<String, dynamic>>(
              '/dependencies/scans/project/proj-1/latest',
            )).thenThrow(DioException(
              requestOptions: RequestOptions(
                path: '/dependencies/scans/project/proj-1/latest',
              ),
              response: Response(
                statusCode: 404,
                data: {'message': 'No scans found'},
                requestOptions: RequestOptions(
                  path: '/dependencies/scans/project/proj-1/latest',
                ),
              ),
              type: DioExceptionType.badResponse,
            ));

        expect(
          () => dependencyApi.getLatestScan('proj-1'),
          throwsA(isA<DioException>()),
        );
      });

      test('500 server error throws DioException', () async {
        when(() => mockClient.post<Map<String, dynamic>>(
              '/dependencies/vulnerabilities',
              data: any(named: 'data'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(
                path: '/dependencies/vulnerabilities',
              ),
              response: Response(
                statusCode: 500,
                data: {'message': 'Internal server error'},
                requestOptions: RequestOptions(
                  path: '/dependencies/vulnerabilities',
                ),
              ),
              type: DioExceptionType.badResponse,
            ));

        expect(
          () => dependencyApi.addVulnerability(
            scanId: 'scan-1',
            dependencyName: 'lodash',
            severity: Severity.high,
          ),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
