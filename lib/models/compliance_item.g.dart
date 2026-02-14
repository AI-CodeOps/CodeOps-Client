// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compliance_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplianceItem _$ComplianceItemFromJson(Map<String, dynamic> json) =>
    ComplianceItem(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      requirement: json['requirement'] as String,
      specId: json['specId'] as String?,
      specName: json['specName'] as String?,
      status:
          const ComplianceStatusConverter().fromJson(json['status'] as String),
      evidence: json['evidence'] as String?,
      agentType: _$JsonConverterFromJson<String, AgentType>(
          json['agentType'], const AgentTypeConverter().fromJson),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ComplianceItemToJson(ComplianceItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'requirement': instance.requirement,
      'specId': instance.specId,
      'specName': instance.specName,
      'status': const ComplianceStatusConverter().toJson(instance.status),
      'evidence': instance.evidence,
      'agentType': _$JsonConverterToJson<String, AgentType>(
          instance.agentType, const AgentTypeConverter().toJson),
      'notes': instance.notes,
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
