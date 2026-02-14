// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthSnapshot _$HealthSnapshotFromJson(Map<String, dynamic> json) =>
    HealthSnapshot(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      jobId: json['jobId'] as String?,
      healthScore: (json['healthScore'] as num).toInt(),
      findingsBySeverity: json['findingsBySeverity'] as String?,
      techDebtScore: (json['techDebtScore'] as num?)?.toInt(),
      dependencyScore: (json['dependencyScore'] as num?)?.toInt(),
      testCoveragePercent: (json['testCoveragePercent'] as num?)?.toDouble(),
      capturedAt: json['capturedAt'] == null
          ? null
          : DateTime.parse(json['capturedAt'] as String),
    );

Map<String, dynamic> _$HealthSnapshotToJson(HealthSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'jobId': instance.jobId,
      'healthScore': instance.healthScore,
      'findingsBySeverity': instance.findingsBySeverity,
      'techDebtScore': instance.techDebtScore,
      'dependencyScore': instance.dependencyScore,
      'testCoveragePercent': instance.testCoveragePercent,
      'capturedAt': instance.capturedAt?.toIso8601String(),
    };

HealthSchedule _$HealthScheduleFromJson(Map<String, dynamic> json) =>
    HealthSchedule(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      scheduleType: const ScheduleTypeConverter()
          .fromJson(json['scheduleType'] as String),
      cronExpression: json['cronExpression'] as String?,
      agentTypes: (json['agentTypes'] as List<dynamic>?)
          ?.map((e) => const AgentTypeConverter().fromJson(e as String))
          .toList(),
      isActive: json['isActive'] as bool?,
      lastRunAt: json['lastRunAt'] == null
          ? null
          : DateTime.parse(json['lastRunAt'] as String),
      nextRunAt: json['nextRunAt'] == null
          ? null
          : DateTime.parse(json['nextRunAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$HealthScheduleToJson(HealthSchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'scheduleType':
          const ScheduleTypeConverter().toJson(instance.scheduleType),
      'cronExpression': instance.cronExpression,
      'agentTypes':
          instance.agentTypes?.map(const AgentTypeConverter().toJson).toList(),
      'isActive': instance.isActive,
      'lastRunAt': instance.lastRunAt?.toIso8601String(),
      'nextRunAt': instance.nextRunAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

PageResponse<T> _$PageResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    PageResponse<T>(
      content: (json['content'] as List<dynamic>).map(fromJsonT).toList(),
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      totalElements: (json['totalElements'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      isLast: json['isLast'] as bool,
    );

Map<String, dynamic> _$PageResponseToJson<T>(
  PageResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'content': instance.content.map(toJsonT).toList(),
      'page': instance.page,
      'size': instance.size,
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
      'isLast': instance.isLast,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
      'user': instance.user.toJson(),
    };

TeamMetrics _$TeamMetricsFromJson(Map<String, dynamic> json) => TeamMetrics(
      teamId: json['teamId'] as String,
      totalProjects: (json['totalProjects'] as num?)?.toInt(),
      totalJobs: (json['totalJobs'] as num?)?.toInt(),
      totalFindings: (json['totalFindings'] as num?)?.toInt(),
      averageHealthScore: (json['averageHealthScore'] as num?)?.toDouble(),
      projectsBelowThreshold: (json['projectsBelowThreshold'] as num?)?.toInt(),
      openCriticalFindings: (json['openCriticalFindings'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TeamMetricsToJson(TeamMetrics instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'totalProjects': instance.totalProjects,
      'totalJobs': instance.totalJobs,
      'totalFindings': instance.totalFindings,
      'averageHealthScore': instance.averageHealthScore,
      'projectsBelowThreshold': instance.projectsBelowThreshold,
      'openCriticalFindings': instance.openCriticalFindings,
    };

ProjectMetrics _$ProjectMetricsFromJson(Map<String, dynamic> json) =>
    ProjectMetrics(
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String?,
      currentHealthScore: (json['currentHealthScore'] as num?)?.toInt(),
      previousHealthScore: (json['previousHealthScore'] as num?)?.toInt(),
      totalJobs: (json['totalJobs'] as num?)?.toInt(),
      totalFindings: (json['totalFindings'] as num?)?.toInt(),
      openCritical: (json['openCritical'] as num?)?.toInt(),
      openHigh: (json['openHigh'] as num?)?.toInt(),
      techDebtItemCount: (json['techDebtItemCount'] as num?)?.toInt(),
      openVulnerabilities: (json['openVulnerabilities'] as num?)?.toInt(),
      lastAuditAt: json['lastAuditAt'] == null
          ? null
          : DateTime.parse(json['lastAuditAt'] as String),
    );

Map<String, dynamic> _$ProjectMetricsToJson(ProjectMetrics instance) =>
    <String, dynamic>{
      'projectId': instance.projectId,
      'projectName': instance.projectName,
      'currentHealthScore': instance.currentHealthScore,
      'previousHealthScore': instance.previousHealthScore,
      'totalJobs': instance.totalJobs,
      'totalFindings': instance.totalFindings,
      'openCritical': instance.openCritical,
      'openHigh': instance.openHigh,
      'techDebtItemCount': instance.techDebtItemCount,
      'openVulnerabilities': instance.openVulnerabilities,
      'lastAuditAt': instance.lastAuditAt?.toIso8601String(),
    };

GitHubConnection _$GitHubConnectionFromJson(Map<String, dynamic> json) =>
    GitHubConnection(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      authType:
          const GitHubAuthTypeConverter().fromJson(json['authType'] as String),
      githubUsername: json['githubUsername'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$GitHubConnectionToJson(GitHubConnection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'name': instance.name,
      'authType': const GitHubAuthTypeConverter().toJson(instance.authType),
      'githubUsername': instance.githubUsername,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

JiraConnection _$JiraConnectionFromJson(Map<String, dynamic> json) =>
    JiraConnection(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      name: json['name'] as String,
      instanceUrl: json['instanceUrl'] as String,
      email: json['email'] as String,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$JiraConnectionToJson(JiraConnection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'name': instance.name,
      'instanceUrl': instance.instanceUrl,
      'email': instance.email,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

BugInvestigation _$BugInvestigationFromJson(Map<String, dynamic> json) =>
    BugInvestigation(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      jiraKey: json['jiraKey'] as String?,
      jiraSummary: json['jiraSummary'] as String?,
      jiraDescription: json['jiraDescription'] as String?,
      additionalContext: json['additionalContext'] as String?,
      rcaMd: json['rcaMd'] as String?,
      impactAssessmentMd: json['impactAssessmentMd'] as String?,
      rcaS3Key: json['rcaS3Key'] as String?,
      rcaPostedToJira: json['rcaPostedToJira'] as bool?,
      fixTasksCreatedInJira: json['fixTasksCreatedInJira'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BugInvestigationToJson(BugInvestigation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'jiraKey': instance.jiraKey,
      'jiraSummary': instance.jiraSummary,
      'jiraDescription': instance.jiraDescription,
      'additionalContext': instance.additionalContext,
      'rcaMd': instance.rcaMd,
      'impactAssessmentMd': instance.impactAssessmentMd,
      'rcaS3Key': instance.rcaS3Key,
      'rcaPostedToJira': instance.rcaPostedToJira,
      'fixTasksCreatedInJira': instance.fixTasksCreatedInJira,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

SystemSetting _$SystemSettingFromJson(Map<String, dynamic> json) =>
    SystemSetting(
      key: json['key'] as String,
      value: json['value'] as String,
      updatedBy: json['updatedBy'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SystemSettingToJson(SystemSetting instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
      'updatedBy': instance.updatedBy,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

AuditLogEntry _$AuditLogEntryFromJson(Map<String, dynamic> json) =>
    AuditLogEntry(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      teamId: json['teamId'] as String?,
      action: json['action'] as String,
      entityType: json['entityType'] as String?,
      entityId: json['entityId'] as String?,
      details: json['details'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AuditLogEntryToJson(AuditLogEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'teamId': instance.teamId,
      'action': instance.action,
      'entityType': instance.entityType,
      'entityId': instance.entityId,
      'details': instance.details,
      'ipAddress': instance.ipAddress,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

NotificationPreference _$NotificationPreferenceFromJson(
        Map<String, dynamic> json) =>
    NotificationPreference(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventType: json['eventType'] as String,
      inApp: json['inApp'] as bool,
      email: json['email'] as bool,
    );

Map<String, dynamic> _$NotificationPreferenceToJson(
        NotificationPreference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'eventType': instance.eventType,
      'inApp': instance.inApp,
      'email': instance.email,
    };
