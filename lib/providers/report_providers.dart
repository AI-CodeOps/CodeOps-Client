/// Riverpod providers for report data.
///
/// Provides agent report markdown content and project health trend data.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import 'health_providers.dart';
import 'job_providers.dart';

/// Downloads and caches an agent report by its S3 key.
///
/// Returns the markdown content as a string.
final agentReportMarkdownProvider =
    FutureProvider.family<String, String>((ref, s3Key) async {
  final reportApi = ref.watch(reportApiProvider);
  return reportApi.downloadReport(s3Key, '');
});

/// Fetches project health trend data.
///
/// Takes a record with projectId and days parameters.
final projectTrendProvider = FutureProvider.family<List<HealthSnapshot>,
    ({String projectId, int days})>((ref, params) async {
  final metricsApi = ref.watch(metricsApiProvider);
  return metricsApi.getProjectTrend(params.projectId, days: params.days);
});
