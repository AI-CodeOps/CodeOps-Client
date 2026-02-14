/// Tech debt item domain model.
///
/// Maps to the server's `TechDebtItemResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'tech_debt_item.g.dart';

/// A tracked piece of technical debt within a project.
@JsonSerializable()
class TechDebtItem {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the owning project.
  final String projectId;

  /// Category of technical debt.
  @DebtCategoryConverter()
  final DebtCategory category;

  /// Short title describing the debt item.
  final String title;

  /// Detailed description of the debt.
  final String? description;

  /// Source file path where the debt exists.
  final String? filePath;

  /// Estimated effort to resolve.
  @EffortConverter()
  final Effort? effortEstimate;

  /// Business impact assessment.
  @BusinessImpactConverter()
  final BusinessImpact? businessImpact;

  /// Current resolution status.
  @DebtStatusConverter()
  final DebtStatus status;

  /// UUID of the job that first detected this debt.
  final String? firstDetectedJobId;

  /// UUID of the job that resolved this debt.
  final String? resolvedJobId;

  /// Timestamp when the debt was first detected.
  final DateTime? createdAt;

  /// Timestamp when the debt record was last updated.
  final DateTime? updatedAt;

  /// Creates a [TechDebtItem] instance.
  const TechDebtItem({
    required this.id,
    required this.projectId,
    required this.category,
    required this.title,
    this.description,
    this.filePath,
    this.effortEstimate,
    this.businessImpact,
    required this.status,
    this.firstDetectedJobId,
    this.resolvedJobId,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [TechDebtItem] from a JSON map.
  factory TechDebtItem.fromJson(Map<String, dynamic> json) =>
      _$TechDebtItemFromJson(json);

  /// Serializes this [TechDebtItem] to a JSON map.
  Map<String, dynamic> toJson() => _$TechDebtItemToJson(this);
}
