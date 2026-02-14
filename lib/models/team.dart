/// Team, team member, and invitation domain models.
///
/// Maps to the server's `TeamResponse`, `TeamMemberResponse`,
/// and `InvitationResponse` DTOs.
library;

import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'team.g.dart';

/// A CodeOps team — the primary organizational unit.
@JsonSerializable()
class Team {
  /// Unique identifier (UUID).
  final String id;

  /// Team name.
  final String name;

  /// Optional team description.
  final String? description;

  /// UUID of the team owner.
  final String ownerId;

  /// Display name of the team owner.
  final String? ownerName;

  /// Microsoft Teams webhook URL for notifications.
  final String? teamsWebhookUrl;

  /// Number of members in the team.
  final int? memberCount;

  /// Timestamp when the team was created.
  final DateTime? createdAt;

  /// Timestamp when the team was last updated.
  final DateTime? updatedAt;

  /// Creates a [Team] instance.
  const Team({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.ownerName,
    this.teamsWebhookUrl,
    this.memberCount,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes a [Team] from a JSON map.
  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

  /// Serializes this [Team] to a JSON map.
  Map<String, dynamic> toJson() => _$TeamToJson(this);
}

/// A member of a team with their assigned role.
@JsonSerializable()
class TeamMember {
  /// Unique identifier (UUID).
  final String id;

  /// UUID of the associated user.
  final String userId;

  /// Display name of the member.
  final String? displayName;

  /// Email address of the member.
  final String? email;

  /// Avatar image URL.
  final String? avatarUrl;

  /// Role within the team.
  @TeamRoleConverter()
  final TeamRole role;

  /// Timestamp when the member joined.
  final DateTime? joinedAt;

  /// Creates a [TeamMember] instance.
  const TeamMember({
    required this.id,
    required this.userId,
    this.displayName,
    this.email,
    this.avatarUrl,
    required this.role,
    this.joinedAt,
  });

  /// Deserializes a [TeamMember] from a JSON map.
  factory TeamMember.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberFromJson(json);

  /// Serializes this [TeamMember] to a JSON map.
  Map<String, dynamic> toJson() => _$TeamMemberToJson(this);
}

/// A pending invitation for a user to join a team.
@JsonSerializable()
class Invitation {
  /// Unique identifier (UUID).
  final String id;

  /// Email address of the invitee.
  final String email;

  /// Role the invitee will receive upon acceptance.
  @TeamRoleConverter()
  final TeamRole role;

  /// Current invitation status.
  @InvitationStatusConverter()
  final InvitationStatus status;

  /// Name of the user who sent the invitation.
  final String? invitedByName;

  /// Timestamp when the invitation expires.
  final DateTime? expiresAt;

  /// Timestamp when the invitation was created.
  final DateTime? createdAt;

  /// Creates an [Invitation] instance.
  const Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.invitedByName,
    this.expiresAt,
    this.createdAt,
  });

  /// Deserializes an [Invitation] from a JSON map.
  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);

  /// Serializes this [Invitation] to a JSON map.
  Map<String, dynamic> toJson() => _$InvitationToJson(this);
}
