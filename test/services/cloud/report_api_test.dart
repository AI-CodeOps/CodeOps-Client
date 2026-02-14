// Tests for ReportApi.
//
// Verifies summary report upload, per-agent report upload, specification file
// upload, report download, and spec report download endpoints.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/cloud/api_client.dart';
import 'package:codeops/services/cloud/report_api.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late ReportApi reportApi;

  setUp(() {
    mockClient = MockApiClient();
    reportApi = ReportApi(mockClient);
  });

  group('ReportApi', () {
    test('uploadSummaryReport sends correct path and returns data', () async {
      final responseData = {
        's3Key': 'reports/job-1/summary.md',
        'url': 'https://s3.example.com/reports/job-1/summary.md',
      };

      when(() => mockClient.post<Map<String, dynamic>>(
            '/reports/job/job-1/summary',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result =
          await reportApi.uploadSummaryReport('job-1', '# Summary Report');

      expect(result, responseData);
      expect(result['s3Key'], 'reports/job-1/summary.md');
      verify(() => mockClient.post<Map<String, dynamic>>(
            '/reports/job/job-1/summary',
            data: jsonEncode('# Summary Report'),
          )).called(1);
    });

    test('uploadAgentReport sends agent type in path', () async {
      final responseData = {
        's3Key': 'reports/job-1/agent/SECURITY.json',
      };

      when(() => mockClient.post<Map<String, dynamic>>(
            '/reports/job/job-1/agent/SECURITY',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await reportApi.uploadAgentReport(
        'job-1',
        AgentType.security,
        '{"findings": []}',
      );

      expect(result, responseData);
      expect(result['s3Key'], 'reports/job-1/agent/SECURITY.json');
      verify(() => mockClient.post<Map<String, dynamic>>(
            '/reports/job/job-1/agent/SECURITY',
            data: jsonEncode('{"findings": []}'),
          )).called(1);
    });

    test('uploadAgentReport uses correct path for multi-word agent types',
        () async {
      final responseData = {
        's3Key': 'reports/job-2/agent/CODE_QUALITY.json',
      };

      when(() => mockClient.post<Map<String, dynamic>>(
            '/reports/job/job-2/agent/CODE_QUALITY',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await reportApi.uploadAgentReport(
        'job-2',
        AgentType.codeQuality,
        '{"issues": []}',
      );

      expect(result['s3Key'], 'reports/job-2/agent/CODE_QUALITY.json');
      verify(() => mockClient.post<Map<String, dynamic>>(
            '/reports/job/job-2/agent/CODE_QUALITY',
            data: jsonEncode('{"issues": []}'),
          )).called(1);
    });

    test('uploadSpecification calls uploadFile with correct path', () async {
      final responseData = {
        's3Key': 'reports/job-1/spec/openapi.yaml',
      };

      when(() => mockClient.uploadFile<Map<String, dynamic>>(
            '/reports/job/job-1/spec',
            filePath: '/tmp/openapi.yaml',
          )).thenAnswer((_) async => Response(
            data: responseData,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await reportApi.uploadSpecification(
        'job-1',
        '/tmp/openapi.yaml',
      );

      expect(result, responseData);
      expect(result['s3Key'], 'reports/job-1/spec/openapi.yaml');
      verify(() => mockClient.uploadFile<Map<String, dynamic>>(
            '/reports/job/job-1/spec',
            filePath: '/tmp/openapi.yaml',
          )).called(1);
    });

    test('downloadReport uses query params and returns content', () async {
      const s3Key = 'reports/job-1/summary.md';
      const reportContent = '# Summary\nAll checks passed.';

      when(() => mockClient.get<String>(
            '/reports/download',
            queryParameters: {'s3Key': s3Key},
          )).thenAnswer((_) async => Response(
            data: reportContent,
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      final result = await reportApi.downloadReport(s3Key, '/tmp/report.md');

      expect(result, reportContent);
      verify(() => mockClient.get<String>(
            '/reports/download',
            queryParameters: {'s3Key': s3Key},
          )).called(1);
    });

    test('downloadSpecReport calls downloadFile with encoded s3Key', () async {
      const s3Key = 'reports/job-1/spec/my file.yaml';
      const savePath = '/tmp/spec.yaml';
      final encodedKey = Uri.encodeComponent(s3Key);

      when(() => mockClient.downloadFile(
            '/reports/spec/download?s3Key=$encodedKey',
            savePath,
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      await reportApi.downloadSpecReport(s3Key, savePath);

      verify(() => mockClient.downloadFile(
            '/reports/spec/download?s3Key=$encodedKey',
            savePath,
          )).called(1);
    });

    test('downloadSpecReport encodes special characters in s3Key', () async {
      const s3Key = 'reports/job-1/spec/api+contract v2.yaml';
      const savePath = '/tmp/spec.yaml';
      final encodedKey = Uri.encodeComponent(s3Key);

      when(() => mockClient.downloadFile(
            '/reports/spec/download?s3Key=$encodedKey',
            savePath,
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(),
            statusCode: 200,
          ));

      await reportApi.downloadSpecReport(s3Key, savePath);

      verify(() => mockClient.downloadFile(
            '/reports/spec/download?s3Key=$encodedKey',
            savePath,
          )).called(1);
    });
  });
}
