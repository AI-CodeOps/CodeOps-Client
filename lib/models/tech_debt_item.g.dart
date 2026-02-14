// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tech_debt_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechDebtItem _$TechDebtItemFromJson(Map<String, dynamic> json) => TechDebtItem(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      category:
          const DebtCategoryConverter().fromJson(json['category'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      filePath: json['filePath'] as String?,
      effortEstimate: _$JsonConverterFromJson<String, Effort>(
          json['effortEstimate'], const EffortConverter().fromJson),
      businessImpact: _$JsonConverterFromJson<String, BusinessImpact>(
          json['businessImpact'], const BusinessImpactConverter().fromJson),
      status: const DebtStatusConverter().fromJson(json['status'] as String),
      firstDetectedJobId: json['firstDetectedJobId'] as String?,
      resolvedJobId: json['resolvedJobId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TechDebtItemToJson(TechDebtItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'category': const DebtCategoryConverter().toJson(instance.category),
      'title': instance.title,
      'description': instance.description,
      'filePath': instance.filePath,
      'effortEstimate': _$JsonConverterToJson<String, Effort>(
          instance.effortEstimate, const EffortConverter().toJson),
      'businessImpact': _$JsonConverterToJson<String, BusinessImpact>(
          instance.businessImpact, const BusinessImpactConverter().toJson),
      'status': const DebtStatusConverter().toJson(instance.status),
      'firstDetectedJobId': instance.firstDetectedJobId,
      'resolvedJobId': instance.resolvedJobId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
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
