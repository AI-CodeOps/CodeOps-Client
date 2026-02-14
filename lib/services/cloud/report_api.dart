/// API service for report upload and download endpoints.
///
/// Handles summary reports, per-agent reports, and specification file uploads.
library;

import 'dart:convert';

import '../../models/enums.dart';
import 'api_client.dart';

/// API service for report upload and download endpoints.
///
/// Provides typed methods for uploading summary and agent reports,
/// uploading specification files, and downloading stored reports.
class ReportApi {
  final ApiClient _client;

  /// Creates a [ReportApi] backed by the given [client].
  ReportApi(this._client);

  /// Uploads a summary report (markdown string) for a job.
  ///
  /// Returns a map containing the S3 key of the stored report.
  Future<Map<String, dynamic>> uploadSummaryReport(
    String jobId,
    String markdownContent,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/reports/job/$jobId/summary',
      data: jsonEncode(markdownContent),
    );
    return response.data!;
  }

  /// Uploads a per-agent report for a job.
  ///
  /// Returns a map containing the S3 key of the stored report.
  Future<Map<String, dynamic>> uploadAgentReport(
    String jobId,
    AgentType agentType,
    String reportJson,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/reports/job/$jobId/agent/${agentType.toJson()}',
      data: jsonEncode(reportJson),
    );
    return response.data!;
  }

  /// Uploads a specification file for a job.
  ///
  /// Returns a map containing the S3 key of the stored file.
  Future<Map<String, dynamic>> uploadSpecification(
    String jobId,
    String filePath,
  ) async {
    final response = await _client.uploadFile<Map<String, dynamic>>(
      '/reports/job/$jobId/spec',
      filePath: filePath,
    );
    return response.data!;
  }

  /// Downloads a report by its [s3Key] to [savePath].
  Future<String> downloadReport(String s3Key, String savePath) async {
    final response = await _client.get<String>(
      '/reports/download',
      queryParameters: {'s3Key': s3Key},
    );
    return response.data!;
  }

  /// Downloads a specification report by its [s3Key] to [savePath].
  Future<void> downloadSpecReport(String s3Key, String savePath) async {
    await _client.downloadFile(
      '/reports/spec/download?s3Key=${Uri.encodeComponent(s3Key)}',
      savePath,
    );
  }
}
