// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persona.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Persona _$PersonaFromJson(Map<String, dynamic> json) => Persona(
      id: json['id'] as String,
      name: json['name'] as String,
      agentType: _$JsonConverterFromJson<String, AgentType>(
          json['agentType'], const AgentTypeConverter().fromJson),
      description: json['description'] as String?,
      contentMd: json['contentMd'] as String?,
      scope: const ScopeConverter().fromJson(json['scope'] as String),
      teamId: json['teamId'] as String?,
      createdBy: json['createdBy'] as String?,
      createdByName: json['createdByName'] as String?,
      isDefault: json['isDefault'] as bool?,
      version: (json['version'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PersonaToJson(Persona instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'agentType': _$JsonConverterToJson<String, AgentType>(
          instance.agentType, const AgentTypeConverter().toJson),
      'description': instance.description,
      'contentMd': instance.contentMd,
      'scope': const ScopeConverter().toJson(instance.scope),
      'teamId': instance.teamId,
      'createdBy': instance.createdBy,
      'createdByName': instance.createdByName,
      'isDefault': instance.isDefault,
      'version': instance.version,
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
