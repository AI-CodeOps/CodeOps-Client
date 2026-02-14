// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qa_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QaJob _$QaJobFromJson(Map<String, dynamic> json) => QaJob(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String?,
      mode: const JobModeConverter().fromJson(json['mode'] as String),
      status: const JobStatusConverter().fromJson(json['status'] as String),
      name: json['name'] as String?,
      branch: json['branch'] as String?,
      configJson: json['configJson'] as String?,
      summaryMd: json['summaryMd'] as String?,
      overallResult: _$JsonConverterFromJson<String, JobResult>(
          json['overallResult'], const JobResultConverter().fromJson),
      healthScore: (json['healthScore'] as num?)?.toInt(),
      totalFindings: (json['totalFindings'] as num?)?.toInt(),
      criticalCount: (json['criticalCount'] as num?)?.toInt(),
      highCount: (json['highCount'] as num?)?.toInt(),
      mediumCount: (json['mediumCount'] as num?)?.toInt(),
      lowCount: (json['lowCount'] as num?)?.toInt(),
      jiraTicketKey: json['jiraTicketKey'] as String?,
      startedBy: json['startedBy'] as String?,
      startedByName: json['startedByName'] as String?,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$QaJobToJson(QaJob instance) => <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'projectName': instance.projectName,
      'mode': const JobModeConverter().toJson(instance.mode),
      'status': const JobStatusConverter().toJson(instance.status),
      'name': instance.name,
      'branch': instance.branch,
      'configJson': instance.configJson,
      'summaryMd': instance.summaryMd,
      'overallResult': _$JsonConverterToJson<String, JobResult>(
          instance.overallResult, const JobResultConverter().toJson),
      'healthScore': instance.healthScore,
      'totalFindings': instance.totalFindings,
      'criticalCount': instance.criticalCount,
      'highCount': instance.highCount,
      'mediumCount': instance.mediumCount,
      'lowCount': instance.lowCount,
      'jiraTicketKey': instance.jiraTicketKey,
      'startedBy': instance.startedBy,
      'startedByName': instance.startedByName,
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

JobSummary _$JobSummaryFromJson(Map<String, dynamic> json) => JobSummary(
      id: json['id'] as String,
      projectName: json['projectName'] as String?,
      mode: const JobModeConverter().fromJson(json['mode'] as String),
      status: const JobStatusConverter().fromJson(json['status'] as String),
      name: json['name'] as String?,
      overallResult: _$JsonConverterFromJson<String, JobResult>(
          json['overallResult'], const JobResultConverter().fromJson),
      healthScore: (json['healthScore'] as num?)?.toInt(),
      totalFindings: (json['totalFindings'] as num?)?.toInt(),
      criticalCount: (json['criticalCount'] as num?)?.toInt(),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$JobSummaryToJson(JobSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectName': instance.projectName,
      'mode': const JobModeConverter().toJson(instance.mode),
      'status': const JobStatusConverter().toJson(instance.status),
      'name': instance.name,
      'overallResult': _$JsonConverterToJson<String, JobResult>(
          instance.overallResult, const JobResultConverter().toJson),
      'healthScore': instance.healthScore,
      'totalFindings': instance.totalFindings,
      'criticalCount': instance.criticalCount,
      'completedAt': instance.completedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
