// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remediation_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemediationTask _$RemediationTaskFromJson(Map<String, dynamic> json) =>
    RemediationTask(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      taskNumber: (json['taskNumber'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      promptMd: json['promptMd'] as String?,
      promptS3Key: json['promptS3Key'] as String?,
      findingIds: (json['findingIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      priority: _$JsonConverterFromJson<String, Priority>(
          json['priority'], const PriorityConverter().fromJson),
      status: const TaskStatusConverter().fromJson(json['status'] as String),
      assignedTo: json['assignedTo'] as String?,
      assignedToName: json['assignedToName'] as String?,
      jiraKey: json['jiraKey'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$RemediationTaskToJson(RemediationTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'taskNumber': instance.taskNumber,
      'title': instance.title,
      'description': instance.description,
      'promptMd': instance.promptMd,
      'promptS3Key': instance.promptS3Key,
      'findingIds': instance.findingIds,
      'priority': _$JsonConverterToJson<String, Priority>(
          instance.priority, const PriorityConverter().toJson),
      'status': const TaskStatusConverter().toJson(instance.status),
      'assignedTo': instance.assignedTo,
      'assignedToName': instance.assignedToName,
      'jiraKey': instance.jiraKey,
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
