// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'specification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Specification _$SpecificationFromJson(Map<String, dynamic> json) =>
    Specification(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      name: json['name'] as String,
      specType: _$JsonConverterFromJson<String, SpecType>(
          json['specType'], const SpecTypeConverter().fromJson),
      s3Key: json['s3Key'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SpecificationToJson(Specification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'name': instance.name,
      'specType': _$JsonConverterToJson<String, SpecType>(
          instance.specType, const SpecTypeConverter().toJson),
      's3Key': instance.s3Key,
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
