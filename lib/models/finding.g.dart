// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finding.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Finding _$FindingFromJson(Map<String, dynamic> json) => Finding(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      agentType:
          const AgentTypeConverter().fromJson(json['agentType'] as String),
      severity: const SeverityConverter().fromJson(json['severity'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      filePath: json['filePath'] as String?,
      lineNumber: (json['lineNumber'] as num?)?.toInt(),
      recommendation: json['recommendation'] as String?,
      evidence: json['evidence'] as String?,
      effortEstimate: _$JsonConverterFromJson<String, Effort>(
          json['effortEstimate'], const EffortConverter().fromJson),
      debtCategory: _$JsonConverterFromJson<String, DebtCategory>(
          json['debtCategory'], const DebtCategoryConverter().fromJson),
      status: const FindingStatusConverter().fromJson(json['status'] as String),
      statusChangedBy: json['statusChangedBy'] as String?,
      statusChangedAt: json['statusChangedAt'] == null
          ? null
          : DateTime.parse(json['statusChangedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FindingToJson(Finding instance) => <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'agentType': const AgentTypeConverter().toJson(instance.agentType),
      'severity': const SeverityConverter().toJson(instance.severity),
      'title': instance.title,
      'description': instance.description,
      'filePath': instance.filePath,
      'lineNumber': instance.lineNumber,
      'recommendation': instance.recommendation,
      'evidence': instance.evidence,
      'effortEstimate': _$JsonConverterToJson<String, Effort>(
          instance.effortEstimate, const EffortConverter().toJson),
      'debtCategory': _$JsonConverterToJson<String, DebtCategory>(
          instance.debtCategory, const DebtCategoryConverter().toJson),
      'status': const FindingStatusConverter().toJson(instance.status),
      'statusChangedBy': instance.statusChangedBy,
      'statusChangedAt': instance.statusChangedAt?.toIso8601String(),
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
