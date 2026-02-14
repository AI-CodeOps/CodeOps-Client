/// Dependency scan and vulnerability domain models.
///
/// Maps to the server's `DependencyScanResponse` and
/// `VulnerabilityResponse` DTOs.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'dependency_scan.g.dart';

/// Results of a dependency scan for a project.
@JsonSerializable()
class DependencyScan {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the project that was scanned.
  final String projectId;

  /// UUID of the parent QA job (if triggered by a job).
  final String? jobId;

  /// Path to the manifest file that was scanned.
  final String? manifestFile;

  /// Total number of dependencies found.
  final int? totalDependencies;

  /// Number of outdated dependencies.
  final int? outdatedCount;

  /// Number of vulnerable dependencies.
  final int? vulnerableCount;

  /// Timestamp when the scan was performed.
  final DateTime? createdAt;

  /// Creates a [DependencyScan] instance.
  const DependencyScan({
    required this.id,
    required this.projectId,
    this.jobId,
    this.manifestFile,
    this.totalDependencies,
    this.outdatedCount,
    this.vulnerableCount,
    this.createdAt,
  });

  /// Deserializes a [DependencyScan] from a JSON map.
  factory DependencyScan.fromJson(Map<String, dynamic> json) =>
      _$DependencyScanFromJson(json);

  /// Serializes this [DependencyScan] to a JSON map.
  Map<String, dynamic> toJson() => _$DependencyScanToJson(this);
}

/// A vulnerability discovered in a project dependency.
@JsonSerializable()
class DependencyVulnerability {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent dependency scan.
  final String scanId;

  /// Name of the affected dependency.
  final String dependencyName;

  /// Current version of the dependency.
  final String? currentVersion;

  /// Version that fixes the vulnerability.
  final String? fixedVersion;

  /// CVE identifier.
  final String? cveId;

  /// Severity of the vulnerability.
  @SeverityConverter()
  final Severity severity;

  /// Description of the vulnerability.
  final String? description;

  /// Current resolution status.
  @VulnerabilityStatusConverter()
  final VulnerabilityStatus status;

  /// Timestamp when the vulnerability was discovered.
  final DateTime? createdAt;

  /// Creates a [DependencyVulnerability] instance.
  const DependencyVulnerability({
    required this.id,
    required this.scanId,
    required this.dependencyName,
    this.currentVersion,
    this.fixedVersion,
    this.cveId,
    required this.severity,
    this.description,
    required this.status,
    this.createdAt,
  });

  /// Deserializes a [DependencyVulnerability] from a JSON map.
  factory DependencyVulnerability.fromJson(Map<String, dynamic> json) =>
      _$DependencyVulnerabilityFromJson(json);

  /// Serializes this [DependencyVulnerability] to a JSON map.
  Map<String, dynamic> toJson() => _$DependencyVulnerabilityToJson(this);
}
