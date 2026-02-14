// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_scan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DependencyScan _$DependencyScanFromJson(Map<String, dynamic> json) =>
    DependencyScan(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      jobId: json['jobId'] as String?,
      manifestFile: json['manifestFile'] as String?,
      totalDependencies: (json['totalDependencies'] as num?)?.toInt(),
      outdatedCount: (json['outdatedCount'] as num?)?.toInt(),
      vulnerableCount: (json['vulnerableCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DependencyScanToJson(DependencyScan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'jobId': instance.jobId,
      'manifestFile': instance.manifestFile,
      'totalDependencies': instance.totalDependencies,
      'outdatedCount': instance.outdatedCount,
      'vulnerableCount': instance.vulnerableCount,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

DependencyVulnerability _$DependencyVulnerabilityFromJson(
        Map<String, dynamic> json) =>
    DependencyVulnerability(
      id: json['id'] as String,
      scanId: json['scanId'] as String,
      dependencyName: json['dependencyName'] as String,
      currentVersion: json['currentVersion'] as String?,
      fixedVersion: json['fixedVersion'] as String?,
      cveId: json['cveId'] as String?,
      severity: const SeverityConverter().fromJson(json['severity'] as String),
      description: json['description'] as String?,
      status: const VulnerabilityStatusConverter()
          .fromJson(json['status'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DependencyVulnerabilityToJson(
        DependencyVulnerability instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scanId': instance.scanId,
      'dependencyName': instance.dependencyName,
      'currentVersion': instance.currentVersion,
      'fixedVersion': instance.fixedVersion,
      'cveId': instance.cveId,
      'severity': const SeverityConverter().toJson(instance.severity),
      'description': instance.description,
      'status': const VulnerabilityStatusConverter().toJson(instance.status),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
