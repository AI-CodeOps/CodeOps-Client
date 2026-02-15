// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      githubConnectionId: json['githubConnectionId'] as String?,
      repoUrl: json['repoUrl'] as String?,
      repoFullName: json['repoFullName'] as String?,
      defaultBranch: json['defaultBranch'] as String?,
      jiraConnectionId: json['jiraConnectionId'] as String?,
      jiraProjectKey: json['jiraProjectKey'] as String?,
      jiraDefaultIssueType: json['jiraDefaultIssueType'] as String?,
      jiraLabels: (json['jiraLabels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      jiraComponent: json['jiraComponent'] as String?,
      techStack: json['techStack'] as String?,
      healthScore: (json['healthScore'] as num?)?.toInt(),
      lastAuditAt: json['lastAuditAt'] == null
          ? null
          : DateTime.parse(json['lastAuditAt'] as String),
      isArchived: json['isArchived'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'name': instance.name,
      'description': instance.description,
      'githubConnectionId': instance.githubConnectionId,
      'repoUrl': instance.repoUrl,
      'repoFullName': instance.repoFullName,
      'defaultBranch': instance.defaultBranch,
      'jiraConnectionId': instance.jiraConnectionId,
      'jiraProjectKey': instance.jiraProjectKey,
      'jiraDefaultIssueType': instance.jiraDefaultIssueType,
      'jiraLabels': instance.jiraLabels,
      'jiraComponent': instance.jiraComponent,
      'techStack': instance.techStack,
      'healthScore': instance.healthScore,
      'lastAuditAt': instance.lastAuditAt?.toIso8601String(),
      'isArchived': instance.isArchived,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
