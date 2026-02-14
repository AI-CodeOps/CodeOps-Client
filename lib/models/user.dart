/// User domain model.
///
/// Maps to the server's `UserResponse` DTO.
library;

import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// A CodeOps platform user.
@JsonSerializable()
class User {
  /// Unique identifier (UUID).
  final String id;

  /// User's email address.
  final String email;

  /// User's display name.
  final String displayName;

  /// Optional avatar image URL.
  final String? avatarUrl;

  /// Whether the user account is active.
  final bool? isActive;

  /// Timestamp of the user's last login.
  final DateTime? lastLoginAt;

  /// Timestamp when the account was created.
  final DateTime? createdAt;

  /// Creates a [User] instance.
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.isActive,
    this.lastLoginAt,
    this.createdAt,
  });

  /// Deserializes a [User] from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Serializes this [User] to a JSON map.
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
