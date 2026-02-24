// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logger_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogSourceResponse _$LogSourceResponseFromJson(Map<String, dynamic> json) =>
    LogSourceResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      serviceId: json['serviceId'] as String?,
      description: json['description'] as String?,
      environment: json['environment'] as String?,
      isActive: json['isActive'] as bool,
      teamId: json['teamId'] as String,
      lastLogReceivedAt: json['lastLogReceivedAt'] == null
          ? null
          : DateTime.parse(json['lastLogReceivedAt'] as String),
      logCount: (json['logCount'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LogSourceResponseToJson(LogSourceResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'serviceId': instance.serviceId,
      'description': instance.description,
      'environment': instance.environment,
      'isActive': instance.isActive,
      'teamId': instance.teamId,
      'lastLogReceivedAt': instance.lastLogReceivedAt?.toIso8601String(),
      'logCount': instance.logCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

CreateLogSourceRequest _$CreateLogSourceRequestFromJson(
        Map<String, dynamic> json) =>
    CreateLogSourceRequest(
      name: json['name'] as String,
      serviceId: json['serviceId'] as String?,
      description: json['description'] as String?,
      environment: json['environment'] as String?,
    );

Map<String, dynamic> _$CreateLogSourceRequestToJson(
        CreateLogSourceRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'serviceId': instance.serviceId,
      'description': instance.description,
      'environment': instance.environment,
    };

UpdateLogSourceRequest _$UpdateLogSourceRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateLogSourceRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      environment: json['environment'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UpdateLogSourceRequestToJson(
        UpdateLogSourceRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'environment': instance.environment,
      'isActive': instance.isActive,
    };

LogEntryResponse _$LogEntryResponseFromJson(Map<String, dynamic> json) =>
    LogEntryResponse(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      level: const LogLevelConverter().fromJson(json['level'] as String),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      serviceName: json['serviceName'] as String,
      correlationId: json['correlationId'] as String?,
      traceId: json['traceId'] as String?,
      spanId: json['spanId'] as String?,
      loggerName: json['loggerName'] as String?,
      threadName: json['threadName'] as String?,
      exceptionClass: json['exceptionClass'] as String?,
      exceptionMessage: json['exceptionMessage'] as String?,
      stackTrace: json['stackTrace'] as String?,
      customFields: json['customFields'] as String?,
      hostName: json['hostName'] as String?,
      ipAddress: json['ipAddress'] as String?,
      teamId: json['teamId'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$LogEntryResponseToJson(LogEntryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourceId': instance.sourceId,
      'sourceName': instance.sourceName,
      'level': const LogLevelConverter().toJson(instance.level),
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'serviceName': instance.serviceName,
      'correlationId': instance.correlationId,
      'traceId': instance.traceId,
      'spanId': instance.spanId,
      'loggerName': instance.loggerName,
      'threadName': instance.threadName,
      'exceptionClass': instance.exceptionClass,
      'exceptionMessage': instance.exceptionMessage,
      'stackTrace': instance.stackTrace,
      'customFields': instance.customFields,
      'hostName': instance.hostName,
      'ipAddress': instance.ipAddress,
      'teamId': instance.teamId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

IngestLogEntryRequest _$IngestLogEntryRequestFromJson(
        Map<String, dynamic> json) =>
    IngestLogEntryRequest(
      level: const LogLevelConverter().fromJson(json['level'] as String),
      message: json['message'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      serviceName: json['serviceName'] as String,
      correlationId: json['correlationId'] as String?,
      traceId: json['traceId'] as String?,
      spanId: json['spanId'] as String?,
      loggerName: json['loggerName'] as String?,
      threadName: json['threadName'] as String?,
      exceptionClass: json['exceptionClass'] as String?,
      exceptionMessage: json['exceptionMessage'] as String?,
      stackTrace: json['stackTrace'] as String?,
      customFields: json['customFields'] as String?,
      hostName: json['hostName'] as String?,
      ipAddress: json['ipAddress'] as String?,
    );

Map<String, dynamic> _$IngestLogEntryRequestToJson(
        IngestLogEntryRequest instance) =>
    <String, dynamic>{
      'level': const LogLevelConverter().toJson(instance.level),
      'message': instance.message,
      'timestamp': instance.timestamp?.toIso8601String(),
      'serviceName': instance.serviceName,
      'correlationId': instance.correlationId,
      'traceId': instance.traceId,
      'spanId': instance.spanId,
      'loggerName': instance.loggerName,
      'threadName': instance.threadName,
      'exceptionClass': instance.exceptionClass,
      'exceptionMessage': instance.exceptionMessage,
      'stackTrace': instance.stackTrace,
      'customFields': instance.customFields,
      'hostName': instance.hostName,
      'ipAddress': instance.ipAddress,
    };

IngestLogBatchRequest _$IngestLogBatchRequestFromJson(
        Map<String, dynamic> json) =>
    IngestLogBatchRequest(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => IngestLogEntryRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$IngestLogBatchRequestToJson(
        IngestLogBatchRequest instance) =>
    <String, dynamic>{
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };

LogQueryRequest _$LogQueryRequestFromJson(Map<String, dynamic> json) =>
    LogQueryRequest(
      serviceName: json['serviceName'] as String?,
      level: _$JsonConverterFromJson<String, LogLevel>(
          json['level'], const LogLevelConverter().fromJson),
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      correlationId: json['correlationId'] as String?,
      query: json['query'] as String?,
      loggerName: json['loggerName'] as String?,
      exceptionClass: json['exceptionClass'] as String?,
      hostName: json['hostName'] as String?,
      page: (json['page'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LogQueryRequestToJson(LogQueryRequest instance) =>
    <String, dynamic>{
      'serviceName': instance.serviceName,
      'level': _$JsonConverterToJson<String, LogLevel>(
          instance.level, const LogLevelConverter().toJson),
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'correlationId': instance.correlationId,
      'query': instance.query,
      'loggerName': instance.loggerName,
      'exceptionClass': instance.exceptionClass,
      'hostName': instance.hostName,
      'page': instance.page,
      'size': instance.size,
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

DslQueryRequest _$DslQueryRequestFromJson(Map<String, dynamic> json) =>
    DslQueryRequest(
      query: json['query'] as String,
      page: (json['page'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DslQueryRequestToJson(DslQueryRequest instance) =>
    <String, dynamic>{
      'query': instance.query,
      'page': instance.page,
      'size': instance.size,
    };

TrapConditionResponse _$TrapConditionResponseFromJson(
        Map<String, dynamic> json) =>
    TrapConditionResponse(
      id: json['id'] as String,
      conditionType: const ConditionTypeConverter()
          .fromJson(json['conditionType'] as String),
      field: json['field'] as String,
      pattern: json['pattern'] as String?,
      threshold: (json['threshold'] as num?)?.toInt(),
      windowSeconds: (json['windowSeconds'] as num?)?.toInt(),
      serviceName: json['serviceName'] as String?,
      logLevel: _$JsonConverterFromJson<String, LogLevel>(
          json['logLevel'], const LogLevelConverter().fromJson),
    );

Map<String, dynamic> _$TrapConditionResponseToJson(
        TrapConditionResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conditionType':
          const ConditionTypeConverter().toJson(instance.conditionType),
      'field': instance.field,
      'pattern': instance.pattern,
      'threshold': instance.threshold,
      'windowSeconds': instance.windowSeconds,
      'serviceName': instance.serviceName,
      'logLevel': _$JsonConverterToJson<String, LogLevel>(
          instance.logLevel, const LogLevelConverter().toJson),
    };

LogTrapResponse _$LogTrapResponseFromJson(Map<String, dynamic> json) =>
    LogTrapResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      trapType: const TrapTypeConverter().fromJson(json['trapType'] as String),
      isActive: json['isActive'] as bool,
      teamId: json['teamId'] as String,
      createdBy: json['createdBy'] as String,
      lastTriggeredAt: json['lastTriggeredAt'] == null
          ? null
          : DateTime.parse(json['lastTriggeredAt'] as String),
      triggerCount: (json['triggerCount'] as num).toInt(),
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) => TrapConditionResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LogTrapResponseToJson(LogTrapResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'trapType': const TrapTypeConverter().toJson(instance.trapType),
      'isActive': instance.isActive,
      'teamId': instance.teamId,
      'createdBy': instance.createdBy,
      'lastTriggeredAt': instance.lastTriggeredAt?.toIso8601String(),
      'triggerCount': instance.triggerCount,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

TrapTestResult _$TrapTestResultFromJson(Map<String, dynamic> json) =>
    TrapTestResult(
      matchCount: (json['matchCount'] as num).toInt(),
      totalEvaluated: (json['totalEvaluated'] as num).toInt(),
      sampleMatchIds: (json['sampleMatchIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      evaluatedFrom: DateTime.parse(json['evaluatedFrom'] as String),
      evaluatedTo: DateTime.parse(json['evaluatedTo'] as String),
      matchPercentage: (json['matchPercentage'] as num).toDouble(),
    );

Map<String, dynamic> _$TrapTestResultToJson(TrapTestResult instance) =>
    <String, dynamic>{
      'matchCount': instance.matchCount,
      'totalEvaluated': instance.totalEvaluated,
      'sampleMatchIds': instance.sampleMatchIds,
      'evaluatedFrom': instance.evaluatedFrom.toIso8601String(),
      'evaluatedTo': instance.evaluatedTo.toIso8601String(),
      'matchPercentage': instance.matchPercentage,
    };

CreateTrapConditionRequest _$CreateTrapConditionRequestFromJson(
        Map<String, dynamic> json) =>
    CreateTrapConditionRequest(
      conditionType: const ConditionTypeConverter()
          .fromJson(json['conditionType'] as String),
      field: json['field'] as String,
      pattern: json['pattern'] as String?,
      threshold: (json['threshold'] as num?)?.toInt(),
      windowSeconds: (json['windowSeconds'] as num?)?.toInt(),
      serviceName: json['serviceName'] as String?,
      logLevel: _$JsonConverterFromJson<String, LogLevel>(
          json['logLevel'], const LogLevelConverter().fromJson),
    );

Map<String, dynamic> _$CreateTrapConditionRequestToJson(
        CreateTrapConditionRequest instance) =>
    <String, dynamic>{
      'conditionType':
          const ConditionTypeConverter().toJson(instance.conditionType),
      'field': instance.field,
      'pattern': instance.pattern,
      'threshold': instance.threshold,
      'windowSeconds': instance.windowSeconds,
      'serviceName': instance.serviceName,
      'logLevel': _$JsonConverterToJson<String, LogLevel>(
          instance.logLevel, const LogLevelConverter().toJson),
    };

CreateLogTrapRequest _$CreateLogTrapRequestFromJson(
        Map<String, dynamic> json) =>
    CreateLogTrapRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      trapType: const TrapTypeConverter().fromJson(json['trapType'] as String),
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) =>
              CreateTrapConditionRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateLogTrapRequestToJson(
        CreateLogTrapRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'trapType': const TrapTypeConverter().toJson(instance.trapType),
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
    };

UpdateLogTrapRequest _$UpdateLogTrapRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateLogTrapRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      trapType: _$JsonConverterFromJson<String, TrapType>(
          json['trapType'], const TrapTypeConverter().fromJson),
      isActive: json['isActive'] as bool?,
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map((e) =>
              CreateTrapConditionRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UpdateLogTrapRequestToJson(
        UpdateLogTrapRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'trapType': _$JsonConverterToJson<String, TrapType>(
          instance.trapType, const TrapTypeConverter().toJson),
      'isActive': instance.isActive,
      'conditions': instance.conditions?.map((e) => e.toJson()).toList(),
    };

TestTrapRequest _$TestTrapRequestFromJson(Map<String, dynamic> json) =>
    TestTrapRequest(
      hoursBack: (json['hoursBack'] as num).toInt(),
    );

Map<String, dynamic> _$TestTrapRequestToJson(TestTrapRequest instance) =>
    <String, dynamic>{
      'hoursBack': instance.hoursBack,
    };

SavedQueryResponse _$SavedQueryResponseFromJson(Map<String, dynamic> json) =>
    SavedQueryResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      queryJson: json['queryJson'] as String,
      queryDsl: json['queryDsl'] as String?,
      teamId: json['teamId'] as String,
      createdBy: json['createdBy'] as String,
      isShared: json['isShared'] as bool,
      lastExecutedAt: json['lastExecutedAt'] == null
          ? null
          : DateTime.parse(json['lastExecutedAt'] as String),
      executionCount: (json['executionCount'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SavedQueryResponseToJson(SavedQueryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'queryJson': instance.queryJson,
      'queryDsl': instance.queryDsl,
      'teamId': instance.teamId,
      'createdBy': instance.createdBy,
      'isShared': instance.isShared,
      'lastExecutedAt': instance.lastExecutedAt?.toIso8601String(),
      'executionCount': instance.executionCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

QueryHistoryResponse _$QueryHistoryResponseFromJson(
        Map<String, dynamic> json) =>
    QueryHistoryResponse(
      id: json['id'] as String,
      queryJson: json['queryJson'] as String,
      queryDsl: json['queryDsl'] as String?,
      resultCount: (json['resultCount'] as num).toInt(),
      executionTimeMs: (json['executionTimeMs'] as num).toInt(),
      createdBy: json['createdBy'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$QueryHistoryResponseToJson(
        QueryHistoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'queryJson': instance.queryJson,
      'queryDsl': instance.queryDsl,
      'resultCount': instance.resultCount,
      'executionTimeMs': instance.executionTimeMs,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

CreateSavedQueryRequest _$CreateSavedQueryRequestFromJson(
        Map<String, dynamic> json) =>
    CreateSavedQueryRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      queryJson: json['queryJson'] as String,
      queryDsl: json['queryDsl'] as String?,
      isShared: json['isShared'] as bool?,
    );

Map<String, dynamic> _$CreateSavedQueryRequestToJson(
        CreateSavedQueryRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'queryJson': instance.queryJson,
      'queryDsl': instance.queryDsl,
      'isShared': instance.isShared,
    };

UpdateSavedQueryRequest _$UpdateSavedQueryRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateSavedQueryRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      queryJson: json['queryJson'] as String?,
      queryDsl: json['queryDsl'] as String?,
      isShared: json['isShared'] as bool?,
    );

Map<String, dynamic> _$UpdateSavedQueryRequestToJson(
        UpdateSavedQueryRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'queryJson': instance.queryJson,
      'queryDsl': instance.queryDsl,
      'isShared': instance.isShared,
    };

AlertChannelResponse _$AlertChannelResponseFromJson(
        Map<String, dynamic> json) =>
    AlertChannelResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      channelType: const AlertChannelTypeConverter()
          .fromJson(json['channelType'] as String),
      configuration: json['configuration'] as String,
      isActive: json['isActive'] as bool,
      teamId: json['teamId'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AlertChannelResponseToJson(
        AlertChannelResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'channelType':
          const AlertChannelTypeConverter().toJson(instance.channelType),
      'configuration': instance.configuration,
      'isActive': instance.isActive,
      'teamId': instance.teamId,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

CreateAlertChannelRequest _$CreateAlertChannelRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAlertChannelRequest(
      name: json['name'] as String,
      channelType: const AlertChannelTypeConverter()
          .fromJson(json['channelType'] as String),
      configuration: json['configuration'] as String,
    );

Map<String, dynamic> _$CreateAlertChannelRequestToJson(
        CreateAlertChannelRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'channelType':
          const AlertChannelTypeConverter().toJson(instance.channelType),
      'configuration': instance.configuration,
    };

UpdateAlertChannelRequest _$UpdateAlertChannelRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateAlertChannelRequest(
      name: json['name'] as String?,
      configuration: json['configuration'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UpdateAlertChannelRequestToJson(
        UpdateAlertChannelRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'configuration': instance.configuration,
      'isActive': instance.isActive,
    };

AlertRuleResponse _$AlertRuleResponseFromJson(Map<String, dynamic> json) =>
    AlertRuleResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      trapId: json['trapId'] as String,
      trapName: json['trapName'] as String,
      channelId: json['channelId'] as String,
      channelName: json['channelName'] as String,
      severity:
          const AlertSeverityConverter().fromJson(json['severity'] as String),
      isActive: json['isActive'] as bool,
      throttleMinutes: (json['throttleMinutes'] as num).toInt(),
      teamId: json['teamId'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AlertRuleResponseToJson(AlertRuleResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'trapId': instance.trapId,
      'trapName': instance.trapName,
      'channelId': instance.channelId,
      'channelName': instance.channelName,
      'severity': const AlertSeverityConverter().toJson(instance.severity),
      'isActive': instance.isActive,
      'throttleMinutes': instance.throttleMinutes,
      'teamId': instance.teamId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

AlertHistoryResponse _$AlertHistoryResponseFromJson(
        Map<String, dynamic> json) =>
    AlertHistoryResponse(
      id: json['id'] as String,
      ruleId: json['ruleId'] as String,
      ruleName: json['ruleName'] as String,
      trapId: json['trapId'] as String,
      trapName: json['trapName'] as String,
      channelId: json['channelId'] as String,
      channelName: json['channelName'] as String,
      severity:
          const AlertSeverityConverter().fromJson(json['severity'] as String),
      status: const AlertStatusConverter().fromJson(json['status'] as String),
      message: json['message'] as String?,
      acknowledgedBy: json['acknowledgedBy'] as String?,
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
      resolvedBy: json['resolvedBy'] as String?,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      teamId: json['teamId'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AlertHistoryResponseToJson(
        AlertHistoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ruleId': instance.ruleId,
      'ruleName': instance.ruleName,
      'trapId': instance.trapId,
      'trapName': instance.trapName,
      'channelId': instance.channelId,
      'channelName': instance.channelName,
      'severity': const AlertSeverityConverter().toJson(instance.severity),
      'status': const AlertStatusConverter().toJson(instance.status),
      'message': instance.message,
      'acknowledgedBy': instance.acknowledgedBy,
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
      'resolvedBy': instance.resolvedBy,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'teamId': instance.teamId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

CreateAlertRuleRequest _$CreateAlertRuleRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAlertRuleRequest(
      name: json['name'] as String,
      trapId: json['trapId'] as String,
      channelId: json['channelId'] as String,
      severity:
          const AlertSeverityConverter().fromJson(json['severity'] as String),
      throttleMinutes: (json['throttleMinutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateAlertRuleRequestToJson(
        CreateAlertRuleRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'trapId': instance.trapId,
      'channelId': instance.channelId,
      'severity': const AlertSeverityConverter().toJson(instance.severity),
      'throttleMinutes': instance.throttleMinutes,
    };

UpdateAlertRuleRequest _$UpdateAlertRuleRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateAlertRuleRequest(
      name: json['name'] as String?,
      trapId: json['trapId'] as String?,
      channelId: json['channelId'] as String?,
      severity: _$JsonConverterFromJson<String, AlertSeverity>(
          json['severity'], const AlertSeverityConverter().fromJson),
      isActive: json['isActive'] as bool?,
      throttleMinutes: (json['throttleMinutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpdateAlertRuleRequestToJson(
        UpdateAlertRuleRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'trapId': instance.trapId,
      'channelId': instance.channelId,
      'severity': _$JsonConverterToJson<String, AlertSeverity>(
          instance.severity, const AlertSeverityConverter().toJson),
      'isActive': instance.isActive,
      'throttleMinutes': instance.throttleMinutes,
    };

UpdateAlertStatusRequest _$UpdateAlertStatusRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateAlertStatusRequest(
      status: const AlertStatusConverter().fromJson(json['status'] as String),
    );

Map<String, dynamic> _$UpdateAlertStatusRequestToJson(
        UpdateAlertStatusRequest instance) =>
    <String, dynamic>{
      'status': const AlertStatusConverter().toJson(instance.status),
    };

MetricResponse _$MetricResponseFromJson(Map<String, dynamic> json) =>
    MetricResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      metricType:
          const MetricTypeConverter().fromJson(json['metricType'] as String),
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      serviceName: json['serviceName'] as String,
      tags: json['tags'] as String?,
      teamId: json['teamId'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MetricResponseToJson(MetricResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'metricType': const MetricTypeConverter().toJson(instance.metricType),
      'description': instance.description,
      'unit': instance.unit,
      'serviceName': instance.serviceName,
      'tags': instance.tags,
      'teamId': instance.teamId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

MetricDataPointResponse _$MetricDataPointResponseFromJson(
        Map<String, dynamic> json) =>
    MetricDataPointResponse(
      id: json['id'] as String,
      metricId: json['metricId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      tags: json['tags'] as String?,
      resolution: (json['resolution'] as num).toInt(),
    );

Map<String, dynamic> _$MetricDataPointResponseToJson(
        MetricDataPointResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'metricId': instance.metricId,
      'timestamp': instance.timestamp.toIso8601String(),
      'value': instance.value,
      'tags': instance.tags,
      'resolution': instance.resolution,
    };

TimeSeriesDataPoint _$TimeSeriesDataPointFromJson(Map<String, dynamic> json) =>
    TimeSeriesDataPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      tags: json['tags'] as String?,
    );

Map<String, dynamic> _$TimeSeriesDataPointToJson(
        TimeSeriesDataPoint instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'value': instance.value,
      'tags': instance.tags,
    };

MetricTimeSeriesResponse _$MetricTimeSeriesResponseFromJson(
        Map<String, dynamic> json) =>
    MetricTimeSeriesResponse(
      metricId: json['metricId'] as String,
      metricName: json['metricName'] as String,
      serviceName: json['serviceName'] as String,
      metricType: json['metricType'] as String,
      unit: json['unit'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      resolution: (json['resolution'] as num).toInt(),
      dataPoints: (json['dataPoints'] as List<dynamic>)
          .map((e) => TimeSeriesDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MetricTimeSeriesResponseToJson(
        MetricTimeSeriesResponse instance) =>
    <String, dynamic>{
      'metricId': instance.metricId,
      'metricName': instance.metricName,
      'serviceName': instance.serviceName,
      'metricType': instance.metricType,
      'unit': instance.unit,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'resolution': instance.resolution,
      'dataPoints': instance.dataPoints.map((e) => e.toJson()).toList(),
    };

MetricAggregationResponse _$MetricAggregationResponseFromJson(
        Map<String, dynamic> json) =>
    MetricAggregationResponse(
      metricId: json['metricId'] as String,
      metricName: json['metricName'] as String,
      serviceName: json['serviceName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      dataPointCount: (json['dataPointCount'] as num).toInt(),
      sum: (json['sum'] as num).toDouble(),
      avg: (json['avg'] as num).toDouble(),
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      p50: (json['p50'] as num).toDouble(),
      p95: (json['p95'] as num).toDouble(),
      p99: (json['p99'] as num).toDouble(),
      stddev: (json['stddev'] as num).toDouble(),
    );

Map<String, dynamic> _$MetricAggregationResponseToJson(
        MetricAggregationResponse instance) =>
    <String, dynamic>{
      'metricId': instance.metricId,
      'metricName': instance.metricName,
      'serviceName': instance.serviceName,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'dataPointCount': instance.dataPointCount,
      'sum': instance.sum,
      'avg': instance.avg,
      'min': instance.min,
      'max': instance.max,
      'p50': instance.p50,
      'p95': instance.p95,
      'p99': instance.p99,
      'stddev': instance.stddev,
    };

ServiceMetricsSummaryResponse _$ServiceMetricsSummaryResponseFromJson(
        Map<String, dynamic> json) =>
    ServiceMetricsSummaryResponse(
      serviceName: json['serviceName'] as String,
      metricCount: (json['metricCount'] as num).toInt(),
      metricsByType: Map<String, int>.from(json['metricsByType'] as Map),
      metrics: (json['metrics'] as List<dynamic>)
          .map((e) => MetricResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ServiceMetricsSummaryResponseToJson(
        ServiceMetricsSummaryResponse instance) =>
    <String, dynamic>{
      'serviceName': instance.serviceName,
      'metricCount': instance.metricCount,
      'metricsByType': instance.metricsByType,
      'metrics': instance.metrics.map((e) => e.toJson()).toList(),
    };

RegisterMetricRequest _$RegisterMetricRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterMetricRequest(
      name: json['name'] as String,
      metricType:
          const MetricTypeConverter().fromJson(json['metricType'] as String),
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      serviceName: json['serviceName'] as String,
      tags: json['tags'] as String?,
    );

Map<String, dynamic> _$RegisterMetricRequestToJson(
        RegisterMetricRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'metricType': const MetricTypeConverter().toJson(instance.metricType),
      'description': instance.description,
      'unit': instance.unit,
      'serviceName': instance.serviceName,
      'tags': instance.tags,
    };

UpdateMetricRequest _$UpdateMetricRequestFromJson(Map<String, dynamic> json) =>
    UpdateMetricRequest(
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      tags: json['tags'] as String?,
    );

Map<String, dynamic> _$UpdateMetricRequestToJson(
        UpdateMetricRequest instance) =>
    <String, dynamic>{
      'description': instance.description,
      'unit': instance.unit,
      'tags': instance.tags,
    };

MetricDataPoint _$MetricDataPointFromJson(Map<String, dynamic> json) =>
    MetricDataPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      tags: json['tags'] as String?,
    );

Map<String, dynamic> _$MetricDataPointToJson(MetricDataPoint instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'value': instance.value,
      'tags': instance.tags,
    };

PushMetricDataRequest _$PushMetricDataRequestFromJson(
        Map<String, dynamic> json) =>
    PushMetricDataRequest(
      metricId: json['metricId'] as String,
      dataPoints: (json['dataPoints'] as List<dynamic>)
          .map((e) => MetricDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PushMetricDataRequestToJson(
        PushMetricDataRequest instance) =>
    <String, dynamic>{
      'metricId': instance.metricId,
      'dataPoints': instance.dataPoints.map((e) => e.toJson()).toList(),
    };

MetricQueryRequest _$MetricQueryRequestFromJson(Map<String, dynamic> json) =>
    MetricQueryRequest(
      metricId: json['metricId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      resolution: (json['resolution'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MetricQueryRequestToJson(MetricQueryRequest instance) =>
    <String, dynamic>{
      'metricId': instance.metricId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'resolution': instance.resolution,
    };

DashboardWidgetResponse _$DashboardWidgetResponseFromJson(
        Map<String, dynamic> json) =>
    DashboardWidgetResponse(
      id: json['id'] as String,
      dashboardId: json['dashboardId'] as String,
      title: json['title'] as String,
      widgetType:
          const WidgetTypeConverter().fromJson(json['widgetType'] as String),
      queryJson: json['queryJson'] as String?,
      configJson: json['configJson'] as String?,
      gridX: (json['gridX'] as num).toInt(),
      gridY: (json['gridY'] as num).toInt(),
      gridWidth: (json['gridWidth'] as num).toInt(),
      gridHeight: (json['gridHeight'] as num).toInt(),
      sortOrder: (json['sortOrder'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DashboardWidgetResponseToJson(
        DashboardWidgetResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dashboardId': instance.dashboardId,
      'title': instance.title,
      'widgetType': const WidgetTypeConverter().toJson(instance.widgetType),
      'queryJson': instance.queryJson,
      'configJson': instance.configJson,
      'gridX': instance.gridX,
      'gridY': instance.gridY,
      'gridWidth': instance.gridWidth,
      'gridHeight': instance.gridHeight,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

DashboardResponse _$DashboardResponseFromJson(Map<String, dynamic> json) =>
    DashboardResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      teamId: json['teamId'] as String,
      createdBy: json['createdBy'] as String,
      isShared: json['isShared'] as bool,
      isTemplate: json['isTemplate'] as bool,
      refreshIntervalSeconds: (json['refreshIntervalSeconds'] as num).toInt(),
      layoutJson: json['layoutJson'] as String?,
      widgets: (json['widgets'] as List<dynamic>)
          .map((e) =>
              DashboardWidgetResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$DashboardResponseToJson(DashboardResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'teamId': instance.teamId,
      'createdBy': instance.createdBy,
      'isShared': instance.isShared,
      'isTemplate': instance.isTemplate,
      'refreshIntervalSeconds': instance.refreshIntervalSeconds,
      'layoutJson': instance.layoutJson,
      'widgets': instance.widgets.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

CreateDashboardRequest _$CreateDashboardRequestFromJson(
        Map<String, dynamic> json) =>
    CreateDashboardRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      isShared: json['isShared'] as bool?,
      refreshIntervalSeconds: (json['refreshIntervalSeconds'] as num?)?.toInt(),
      layoutJson: json['layoutJson'] as String?,
    );

Map<String, dynamic> _$CreateDashboardRequestToJson(
        CreateDashboardRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'isShared': instance.isShared,
      'refreshIntervalSeconds': instance.refreshIntervalSeconds,
      'layoutJson': instance.layoutJson,
    };

UpdateDashboardRequest _$UpdateDashboardRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateDashboardRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      isShared: json['isShared'] as bool?,
      isTemplate: json['isTemplate'] as bool?,
      refreshIntervalSeconds: (json['refreshIntervalSeconds'] as num?)?.toInt(),
      layoutJson: json['layoutJson'] as String?,
    );

Map<String, dynamic> _$UpdateDashboardRequestToJson(
        UpdateDashboardRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'isShared': instance.isShared,
      'isTemplate': instance.isTemplate,
      'refreshIntervalSeconds': instance.refreshIntervalSeconds,
      'layoutJson': instance.layoutJson,
    };

CreateDashboardWidgetRequest _$CreateDashboardWidgetRequestFromJson(
        Map<String, dynamic> json) =>
    CreateDashboardWidgetRequest(
      title: json['title'] as String,
      widgetType:
          const WidgetTypeConverter().fromJson(json['widgetType'] as String),
      queryJson: json['queryJson'] as String?,
      configJson: json['configJson'] as String?,
      gridX: (json['gridX'] as num?)?.toInt(),
      gridY: (json['gridY'] as num?)?.toInt(),
      gridWidth: (json['gridWidth'] as num?)?.toInt(),
      gridHeight: (json['gridHeight'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateDashboardWidgetRequestToJson(
        CreateDashboardWidgetRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'widgetType': const WidgetTypeConverter().toJson(instance.widgetType),
      'queryJson': instance.queryJson,
      'configJson': instance.configJson,
      'gridX': instance.gridX,
      'gridY': instance.gridY,
      'gridWidth': instance.gridWidth,
      'gridHeight': instance.gridHeight,
      'sortOrder': instance.sortOrder,
    };

UpdateDashboardWidgetRequest _$UpdateDashboardWidgetRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateDashboardWidgetRequest(
      title: json['title'] as String?,
      widgetType: _$JsonConverterFromJson<String, WidgetType>(
          json['widgetType'], const WidgetTypeConverter().fromJson),
      queryJson: json['queryJson'] as String?,
      configJson: json['configJson'] as String?,
      gridX: (json['gridX'] as num?)?.toInt(),
      gridY: (json['gridY'] as num?)?.toInt(),
      gridWidth: (json['gridWidth'] as num?)?.toInt(),
      gridHeight: (json['gridHeight'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpdateDashboardWidgetRequestToJson(
        UpdateDashboardWidgetRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'widgetType': _$JsonConverterToJson<String, WidgetType>(
          instance.widgetType, const WidgetTypeConverter().toJson),
      'queryJson': instance.queryJson,
      'configJson': instance.configJson,
      'gridX': instance.gridX,
      'gridY': instance.gridY,
      'gridWidth': instance.gridWidth,
      'gridHeight': instance.gridHeight,
      'sortOrder': instance.sortOrder,
    };

ReorderWidgetsRequest _$ReorderWidgetsRequestFromJson(
        Map<String, dynamic> json) =>
    ReorderWidgetsRequest(
      widgetIds:
          (json['widgetIds'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ReorderWidgetsRequestToJson(
        ReorderWidgetsRequest instance) =>
    <String, dynamic>{
      'widgetIds': instance.widgetIds,
    };

WidgetPositionUpdate _$WidgetPositionUpdateFromJson(
        Map<String, dynamic> json) =>
    WidgetPositionUpdate(
      widgetId: json['widgetId'] as String,
      gridX: (json['gridX'] as num).toInt(),
      gridY: (json['gridY'] as num).toInt(),
      gridWidth: (json['gridWidth'] as num).toInt(),
      gridHeight: (json['gridHeight'] as num).toInt(),
    );

Map<String, dynamic> _$WidgetPositionUpdateToJson(
        WidgetPositionUpdate instance) =>
    <String, dynamic>{
      'widgetId': instance.widgetId,
      'gridX': instance.gridX,
      'gridY': instance.gridY,
      'gridWidth': instance.gridWidth,
      'gridHeight': instance.gridHeight,
    };

UpdateLayoutRequest _$UpdateLayoutRequestFromJson(Map<String, dynamic> json) =>
    UpdateLayoutRequest(
      positions: (json['positions'] as List<dynamic>)
          .map((e) => WidgetPositionUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UpdateLayoutRequestToJson(
        UpdateLayoutRequest instance) =>
    <String, dynamic>{
      'positions': instance.positions.map((e) => e.toJson()).toList(),
    };

CreateFromTemplateRequest _$CreateFromTemplateRequestFromJson(
        Map<String, dynamic> json) =>
    CreateFromTemplateRequest(
      name: json['name'] as String,
      templateId: json['templateId'] as String,
    );

Map<String, dynamic> _$CreateFromTemplateRequestToJson(
        CreateFromTemplateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'templateId': instance.templateId,
    };

TraceSpanResponse _$TraceSpanResponseFromJson(Map<String, dynamic> json) =>
    TraceSpanResponse(
      id: json['id'] as String,
      correlationId: json['correlationId'] as String,
      traceId: json['traceId'] as String,
      spanId: json['spanId'] as String,
      parentSpanId: json['parentSpanId'] as String?,
      serviceName: json['serviceName'] as String,
      operationName: json['operationName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      status: const SpanStatusConverter().fromJson(json['status'] as String),
      statusMessage: json['statusMessage'] as String?,
      tags: json['tags'] as String?,
      teamId: json['teamId'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TraceSpanResponseToJson(TraceSpanResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'correlationId': instance.correlationId,
      'traceId': instance.traceId,
      'spanId': instance.spanId,
      'parentSpanId': instance.parentSpanId,
      'serviceName': instance.serviceName,
      'operationName': instance.operationName,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'durationMs': instance.durationMs,
      'status': const SpanStatusConverter().toJson(instance.status),
      'statusMessage': instance.statusMessage,
      'tags': instance.tags,
      'teamId': instance.teamId,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

TraceFlowResponse _$TraceFlowResponseFromJson(Map<String, dynamic> json) =>
    TraceFlowResponse(
      correlationId: json['correlationId'] as String,
      traceId: json['traceId'] as String,
      spans: (json['spans'] as List<dynamic>)
          .map((e) => TraceSpanResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDurationMs: (json['totalDurationMs'] as num).toInt(),
      spanCount: (json['spanCount'] as num).toInt(),
      hasErrors: json['hasErrors'] as bool,
    );

Map<String, dynamic> _$TraceFlowResponseToJson(TraceFlowResponse instance) =>
    <String, dynamic>{
      'correlationId': instance.correlationId,
      'traceId': instance.traceId,
      'spans': instance.spans.map((e) => e.toJson()).toList(),
      'totalDurationMs': instance.totalDurationMs,
      'spanCount': instance.spanCount,
      'hasErrors': instance.hasErrors,
    };

WaterfallSpan _$WaterfallSpanFromJson(Map<String, dynamic> json) =>
    WaterfallSpan(
      id: json['id'] as String,
      spanId: json['spanId'] as String,
      parentSpanId: json['parentSpanId'] as String?,
      serviceName: json['serviceName'] as String,
      operationName: json['operationName'] as String,
      offsetMs: (json['offsetMs'] as num).toInt(),
      durationMs: (json['durationMs'] as num).toInt(),
      status: const SpanStatusConverter().fromJson(json['status'] as String),
      statusMessage: json['statusMessage'] as String?,
      depth: (json['depth'] as num).toInt(),
      relatedLogIds: (json['relatedLogIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$WaterfallSpanToJson(WaterfallSpan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'spanId': instance.spanId,
      'parentSpanId': instance.parentSpanId,
      'serviceName': instance.serviceName,
      'operationName': instance.operationName,
      'offsetMs': instance.offsetMs,
      'durationMs': instance.durationMs,
      'status': const SpanStatusConverter().toJson(instance.status),
      'statusMessage': instance.statusMessage,
      'depth': instance.depth,
      'relatedLogIds': instance.relatedLogIds,
    };

TraceWaterfallResponse _$TraceWaterfallResponseFromJson(
        Map<String, dynamic> json) =>
    TraceWaterfallResponse(
      correlationId: json['correlationId'] as String,
      traceId: json['traceId'] as String,
      totalDurationMs: (json['totalDurationMs'] as num).toInt(),
      spanCount: (json['spanCount'] as num).toInt(),
      serviceCount: (json['serviceCount'] as num).toInt(),
      hasErrors: json['hasErrors'] as bool,
      spans: (json['spans'] as List<dynamic>)
          .map((e) => WaterfallSpan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TraceWaterfallResponseToJson(
        TraceWaterfallResponse instance) =>
    <String, dynamic>{
      'correlationId': instance.correlationId,
      'traceId': instance.traceId,
      'totalDurationMs': instance.totalDurationMs,
      'spanCount': instance.spanCount,
      'serviceCount': instance.serviceCount,
      'hasErrors': instance.hasErrors,
      'spans': instance.spans.map((e) => e.toJson()).toList(),
    };

TraceListResponse _$TraceListResponseFromJson(Map<String, dynamic> json) =>
    TraceListResponse(
      correlationId: json['correlationId'] as String,
      traceId: json['traceId'] as String,
      rootService: json['rootService'] as String,
      rootOperation: json['rootOperation'] as String,
      spanCount: (json['spanCount'] as num).toInt(),
      serviceCount: (json['serviceCount'] as num).toInt(),
      totalDurationMs: (json['totalDurationMs'] as num).toInt(),
      hasErrors: json['hasErrors'] as bool,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
    );

Map<String, dynamic> _$TraceListResponseToJson(TraceListResponse instance) =>
    <String, dynamic>{
      'correlationId': instance.correlationId,
      'traceId': instance.traceId,
      'rootService': instance.rootService,
      'rootOperation': instance.rootOperation,
      'spanCount': instance.spanCount,
      'serviceCount': instance.serviceCount,
      'totalDurationMs': instance.totalDurationMs,
      'hasErrors': instance.hasErrors,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
    };

RootCauseAnalysisResponse _$RootCauseAnalysisResponseFromJson(
        Map<String, dynamic> json) =>
    RootCauseAnalysisResponse(
      correlationId: json['correlationId'] as String,
      traceId: json['traceId'] as String,
      rootCauseSpan: TraceSpanResponse.fromJson(
          json['rootCauseSpan'] as Map<String, dynamic>),
      rootCauseService: json['rootCauseService'] as String,
      rootCauseMessage: json['rootCauseMessage'] as String,
      errorChain: (json['errorChain'] as List<dynamic>)
          .map((e) => TraceSpanResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      relatedLogEntryIds: (json['relatedLogEntryIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      impactedServiceCount: (json['impactedServiceCount'] as num).toInt(),
      totalDurationMs: (json['totalDurationMs'] as num).toInt(),
    );

Map<String, dynamic> _$RootCauseAnalysisResponseToJson(
        RootCauseAnalysisResponse instance) =>
    <String, dynamic>{
      'correlationId': instance.correlationId,
      'traceId': instance.traceId,
      'rootCauseSpan': instance.rootCauseSpan.toJson(),
      'rootCauseService': instance.rootCauseService,
      'rootCauseMessage': instance.rootCauseMessage,
      'errorChain': instance.errorChain.map((e) => e.toJson()).toList(),
      'relatedLogEntryIds': instance.relatedLogEntryIds,
      'impactedServiceCount': instance.impactedServiceCount,
      'totalDurationMs': instance.totalDurationMs,
    };

CreateTraceSpanRequest _$CreateTraceSpanRequestFromJson(
        Map<String, dynamic> json) =>
    CreateTraceSpanRequest(
      correlationId: json['correlationId'] as String,
      traceId: json['traceId'] as String,
      spanId: json['spanId'] as String,
      parentSpanId: json['parentSpanId'] as String?,
      serviceName: json['serviceName'] as String,
      operationName: json['operationName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      status: _$JsonConverterFromJson<String, SpanStatus>(
          json['status'], const SpanStatusConverter().fromJson),
      statusMessage: json['statusMessage'] as String?,
      tags: json['tags'] as String?,
    );

Map<String, dynamic> _$CreateTraceSpanRequestToJson(
        CreateTraceSpanRequest instance) =>
    <String, dynamic>{
      'correlationId': instance.correlationId,
      'traceId': instance.traceId,
      'spanId': instance.spanId,
      'parentSpanId': instance.parentSpanId,
      'serviceName': instance.serviceName,
      'operationName': instance.operationName,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'durationMs': instance.durationMs,
      'status': _$JsonConverterToJson<String, SpanStatus>(
          instance.status, const SpanStatusConverter().toJson),
      'statusMessage': instance.statusMessage,
      'tags': instance.tags,
    };

RetentionPolicyResponse _$RetentionPolicyResponseFromJson(
        Map<String, dynamic> json) =>
    RetentionPolicyResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceName: json['sourceName'] as String?,
      logLevel: _$JsonConverterFromJson<String, LogLevel>(
          json['logLevel'], const LogLevelConverter().fromJson),
      retentionDays: (json['retentionDays'] as num).toInt(),
      action:
          const RetentionActionConverter().fromJson(json['action'] as String),
      archiveDestination: json['archiveDestination'] as String?,
      isActive: json['isActive'] as bool,
      teamId: json['teamId'] as String,
      createdBy: json['createdBy'] as String,
      lastExecutedAt: json['lastExecutedAt'] == null
          ? null
          : DateTime.parse(json['lastExecutedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RetentionPolicyResponseToJson(
        RetentionPolicyResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sourceName': instance.sourceName,
      'logLevel': _$JsonConverterToJson<String, LogLevel>(
          instance.logLevel, const LogLevelConverter().toJson),
      'retentionDays': instance.retentionDays,
      'action': const RetentionActionConverter().toJson(instance.action),
      'archiveDestination': instance.archiveDestination,
      'isActive': instance.isActive,
      'teamId': instance.teamId,
      'createdBy': instance.createdBy,
      'lastExecutedAt': instance.lastExecutedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

StorageUsageResponse _$StorageUsageResponseFromJson(
        Map<String, dynamic> json) =>
    StorageUsageResponse(
      totalLogEntries: (json['totalLogEntries'] as num).toInt(),
      totalMetricDataPoints: (json['totalMetricDataPoints'] as num).toInt(),
      totalTraceSpans: (json['totalTraceSpans'] as num).toInt(),
      logEntriesByService:
          Map<String, int>.from(json['logEntriesByService'] as Map),
      logEntriesByLevel:
          Map<String, int>.from(json['logEntriesByLevel'] as Map),
      activeRetentionPolicies: (json['activeRetentionPolicies'] as num).toInt(),
      oldestLogEntry: json['oldestLogEntry'] == null
          ? null
          : DateTime.parse(json['oldestLogEntry'] as String),
      newestLogEntry: json['newestLogEntry'] == null
          ? null
          : DateTime.parse(json['newestLogEntry'] as String),
    );

Map<String, dynamic> _$StorageUsageResponseToJson(
        StorageUsageResponse instance) =>
    <String, dynamic>{
      'totalLogEntries': instance.totalLogEntries,
      'totalMetricDataPoints': instance.totalMetricDataPoints,
      'totalTraceSpans': instance.totalTraceSpans,
      'logEntriesByService': instance.logEntriesByService,
      'logEntriesByLevel': instance.logEntriesByLevel,
      'activeRetentionPolicies': instance.activeRetentionPolicies,
      'oldestLogEntry': instance.oldestLogEntry?.toIso8601String(),
      'newestLogEntry': instance.newestLogEntry?.toIso8601String(),
    };

CreateRetentionPolicyRequest _$CreateRetentionPolicyRequestFromJson(
        Map<String, dynamic> json) =>
    CreateRetentionPolicyRequest(
      name: json['name'] as String,
      sourceName: json['sourceName'] as String?,
      logLevel: _$JsonConverterFromJson<String, LogLevel>(
          json['logLevel'], const LogLevelConverter().fromJson),
      retentionDays: (json['retentionDays'] as num).toInt(),
      action:
          const RetentionActionConverter().fromJson(json['action'] as String),
      archiveDestination: json['archiveDestination'] as String?,
    );

Map<String, dynamic> _$CreateRetentionPolicyRequestToJson(
        CreateRetentionPolicyRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'sourceName': instance.sourceName,
      'logLevel': _$JsonConverterToJson<String, LogLevel>(
          instance.logLevel, const LogLevelConverter().toJson),
      'retentionDays': instance.retentionDays,
      'action': const RetentionActionConverter().toJson(instance.action),
      'archiveDestination': instance.archiveDestination,
    };

UpdateRetentionPolicyRequest _$UpdateRetentionPolicyRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateRetentionPolicyRequest(
      name: json['name'] as String?,
      sourceName: json['sourceName'] as String?,
      logLevel: _$JsonConverterFromJson<String, LogLevel>(
          json['logLevel'], const LogLevelConverter().fromJson),
      retentionDays: (json['retentionDays'] as num?)?.toInt(),
      action: _$JsonConverterFromJson<String, RetentionAction>(
          json['action'], const RetentionActionConverter().fromJson),
      archiveDestination: json['archiveDestination'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UpdateRetentionPolicyRequestToJson(
        UpdateRetentionPolicyRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'sourceName': instance.sourceName,
      'logLevel': _$JsonConverterToJson<String, LogLevel>(
          instance.logLevel, const LogLevelConverter().toJson),
      'retentionDays': instance.retentionDays,
      'action': _$JsonConverterToJson<String, RetentionAction>(
          instance.action, const RetentionActionConverter().toJson),
      'archiveDestination': instance.archiveDestination,
      'isActive': instance.isActive,
    };

AnomalyBaselineResponse _$AnomalyBaselineResponseFromJson(
        Map<String, dynamic> json) =>
    AnomalyBaselineResponse(
      id: json['id'] as String,
      serviceName: json['serviceName'] as String,
      metricName: json['metricName'] as String,
      baselineValue: (json['baselineValue'] as num).toDouble(),
      standardDeviation: (json['standardDeviation'] as num).toDouble(),
      sampleCount: (json['sampleCount'] as num).toInt(),
      windowStartTime: DateTime.parse(json['windowStartTime'] as String),
      windowEndTime: DateTime.parse(json['windowEndTime'] as String),
      deviationThreshold: (json['deviationThreshold'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      teamId: json['teamId'] as String,
      lastComputedAt: json['lastComputedAt'] == null
          ? null
          : DateTime.parse(json['lastComputedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AnomalyBaselineResponseToJson(
        AnomalyBaselineResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceName': instance.serviceName,
      'metricName': instance.metricName,
      'baselineValue': instance.baselineValue,
      'standardDeviation': instance.standardDeviation,
      'sampleCount': instance.sampleCount,
      'windowStartTime': instance.windowStartTime.toIso8601String(),
      'windowEndTime': instance.windowEndTime.toIso8601String(),
      'deviationThreshold': instance.deviationThreshold,
      'isActive': instance.isActive,
      'teamId': instance.teamId,
      'lastComputedAt': instance.lastComputedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

AnomalyCheckResponse _$AnomalyCheckResponseFromJson(
        Map<String, dynamic> json) =>
    AnomalyCheckResponse(
      serviceName: json['serviceName'] as String,
      metricName: json['metricName'] as String,
      currentValue: (json['currentValue'] as num).toDouble(),
      baselineValue: (json['baselineValue'] as num).toDouble(),
      standardDeviation: (json['standardDeviation'] as num).toDouble(),
      deviationThreshold: (json['deviationThreshold'] as num).toDouble(),
      zScore: (json['zScore'] as num).toDouble(),
      isAnomaly: json['isAnomaly'] as bool,
      direction: json['direction'] as String,
      checkedAt: DateTime.parse(json['checkedAt'] as String),
    );

Map<String, dynamic> _$AnomalyCheckResponseToJson(
        AnomalyCheckResponse instance) =>
    <String, dynamic>{
      'serviceName': instance.serviceName,
      'metricName': instance.metricName,
      'currentValue': instance.currentValue,
      'baselineValue': instance.baselineValue,
      'standardDeviation': instance.standardDeviation,
      'deviationThreshold': instance.deviationThreshold,
      'zScore': instance.zScore,
      'isAnomaly': instance.isAnomaly,
      'direction': instance.direction,
      'checkedAt': instance.checkedAt.toIso8601String(),
    };

AnomalyReportResponse _$AnomalyReportResponseFromJson(
        Map<String, dynamic> json) =>
    AnomalyReportResponse(
      teamId: json['teamId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      totalBaselines: (json['totalBaselines'] as num).toInt(),
      anomaliesDetected: (json['anomaliesDetected'] as num).toInt(),
      anomalies: (json['anomalies'] as List<dynamic>)
          .map((e) => AnomalyCheckResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      allChecks: (json['allChecks'] as List<dynamic>)
          .map((e) => AnomalyCheckResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnomalyReportResponseToJson(
        AnomalyReportResponse instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'totalBaselines': instance.totalBaselines,
      'anomaliesDetected': instance.anomaliesDetected,
      'anomalies': instance.anomalies.map((e) => e.toJson()).toList(),
      'allChecks': instance.allChecks.map((e) => e.toJson()).toList(),
    };

CreateBaselineRequest _$CreateBaselineRequestFromJson(
        Map<String, dynamic> json) =>
    CreateBaselineRequest(
      serviceName: json['serviceName'] as String,
      metricName: json['metricName'] as String,
      windowHours: (json['windowHours'] as num).toInt(),
      deviationThreshold: (json['deviationThreshold'] as num).toDouble(),
    );

Map<String, dynamic> _$CreateBaselineRequestToJson(
        CreateBaselineRequest instance) =>
    <String, dynamic>{
      'serviceName': instance.serviceName,
      'metricName': instance.metricName,
      'windowHours': instance.windowHours,
      'deviationThreshold': instance.deviationThreshold,
    };

UpdateBaselineRequest _$UpdateBaselineRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateBaselineRequest(
      windowHours: (json['windowHours'] as num?)?.toInt(),
      deviationThreshold: (json['deviationThreshold'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UpdateBaselineRequestToJson(
        UpdateBaselineRequest instance) =>
    <String, dynamic>{
      'windowHours': instance.windowHours,
      'deviationThreshold': instance.deviationThreshold,
      'isActive': instance.isActive,
    };

IngestionStatsResponse _$IngestionStatsResponseFromJson(
        Map<String, dynamic> json) =>
    IngestionStatsResponse(
      totalLogsIngested: (json['totalLogsIngested'] as num).toInt(),
      logsPerSecond: (json['logsPerSecond'] as num).toDouble(),
      activeSourceCount: (json['activeSourceCount'] as num).toInt(),
      logsByLevel: Map<String, int>.from(json['logsByLevel'] as Map),
      logsByService: Map<String, int>.from(json['logsByService'] as Map),
      since: DateTime.parse(json['since'] as String),
    );

Map<String, dynamic> _$IngestionStatsResponseToJson(
        IngestionStatsResponse instance) =>
    <String, dynamic>{
      'totalLogsIngested': instance.totalLogsIngested,
      'logsPerSecond': instance.logsPerSecond,
      'activeSourceCount': instance.activeSourceCount,
      'logsByLevel': instance.logsByLevel,
      'logsByService': instance.logsByService,
      'since': instance.since.toIso8601String(),
    };
