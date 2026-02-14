// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directive.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Directive _$DirectiveFromJson(Map<String, dynamic> json) => Directive(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      contentMd: json['contentMd'] as String?,
      category: _$JsonConverterFromJson<String, DirectiveCategory>(
          json['category'], const DirectiveCategoryConverter().fromJson),
      scope: const DirectiveScopeConverter().fromJson(json['scope'] as String),
      teamId: json['teamId'] as String?,
      projectId: json['projectId'] as String?,
      createdBy: json['createdBy'] as String?,
      createdByName: json['createdByName'] as String?,
      version: (json['version'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DirectiveToJson(Directive instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'contentMd': instance.contentMd,
      'category': _$JsonConverterToJson<String, DirectiveCategory>(
          instance.category, const DirectiveCategoryConverter().toJson),
      'scope': const DirectiveScopeConverter().toJson(instance.scope),
      'teamId': instance.teamId,
      'projectId': instance.projectId,
      'createdBy': instance.createdBy,
      'createdByName': instance.createdByName,
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

ProjectDirective _$ProjectDirectiveFromJson(Map<String, dynamic> json) =>
    ProjectDirective(
      projectId: json['projectId'] as String,
      directiveId: json['directiveId'] as String,
      directiveName: json['directiveName'] as String?,
      category: _$JsonConverterFromJson<String, DirectiveCategory>(
          json['category'], const DirectiveCategoryConverter().fromJson),
      enabled: json['enabled'] as bool?,
    );

Map<String, dynamic> _$ProjectDirectiveToJson(ProjectDirective instance) =>
    <String, dynamic>{
      'projectId': instance.projectId,
      'directiveId': instance.directiveId,
      'directiveName': instance.directiveName,
      'category': _$JsonConverterToJson<String, DirectiveCategory>(
          instance.category, const DirectiveCategoryConverter().toJson),
      'enabled': instance.enabled,
    };
