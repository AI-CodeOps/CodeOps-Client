/// Specification domain model.
///
/// Maps to the server's `SpecificationResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'specification.g.dart';

/// A specification file attached to a compliance job.
@JsonSerializable()
class Specification {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the parent QA job.
  final String jobId;

  /// Name of the specification.
  final String name;

  /// Type of specification file.
  @SpecTypeConverter()
  final SpecType? specType;

  /// S3 key for the specification file.
  final String s3Key;

  /// Timestamp when the specification was created.
  final DateTime? createdAt;

  /// Creates a [Specification] instance.
  const Specification({
    required this.id,
    required this.jobId,
    required this.name,
    this.specType,
    required this.s3Key,
    this.createdAt,
  });

  /// Deserializes a [Specification] from a JSON map.
  factory Specification.fromJson(Map<String, dynamic> json) =>
      _$SpecificationFromJson(json);

  /// Serializes this [Specification] to a JSON map.
  Map<String, dynamic> toJson() => _$SpecificationToJson(this);
}
