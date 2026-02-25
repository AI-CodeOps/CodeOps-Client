/// Enum types for the CodeOps-Relay module.
///
/// Each enum provides SCREAMING_SNAKE_CASE serialization matching the Server's
/// Java enums, plus a companion [JsonConverter] for use with `json_serializable`.
library;

import 'package:json_annotation/json_annotation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChannelType
// ─────────────────────────────────────────────────────────────────────────────

/// Types of channels in the Relay messaging module.
enum ChannelType {
  /// Open channel visible to all team members.
  public,

  /// Invite-only channel.
  private,

  /// Auto-created channel for a project.
  project,

  /// Auto-created channel for a registered service.
  service;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ChannelType.public => 'PUBLIC',
        ChannelType.private => 'PRIVATE',
        ChannelType.project => 'PROJECT',
        ChannelType.service => 'SERVICE',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static ChannelType fromJson(String json) => switch (json) {
        'PUBLIC' => ChannelType.public,
        'PRIVATE' => ChannelType.private,
        'PROJECT' => ChannelType.project,
        'SERVICE' => ChannelType.service,
        _ => throw ArgumentError('Unknown ChannelType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ChannelType.public => 'Public',
        ChannelType.private => 'Private',
        ChannelType.project => 'Project',
        ChannelType.service => 'Service',
      };
}

/// JSON converter for [ChannelType].
class ChannelTypeConverter extends JsonConverter<ChannelType, String> {
  /// Creates a [ChannelTypeConverter].
  const ChannelTypeConverter();

  @override
  ChannelType fromJson(String json) => ChannelType.fromJson(json);

  @override
  String toJson(ChannelType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// MessageType
// ─────────────────────────────────────────────────────────────────────────────

/// Types of messages in Relay channels and conversations.
enum MessageType {
  /// Regular user-authored text message.
  text,

  /// System-generated message (join, leave, topic change).
  system,

  /// Message generated from a platform event.
  platformEvent,

  /// File attachment message.
  file;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        MessageType.text => 'TEXT',
        MessageType.system => 'SYSTEM',
        MessageType.platformEvent => 'PLATFORM_EVENT',
        MessageType.file => 'FILE',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static MessageType fromJson(String json) => switch (json) {
        'TEXT' => MessageType.text,
        'SYSTEM' => MessageType.system,
        'PLATFORM_EVENT' => MessageType.platformEvent,
        'FILE' => MessageType.file,
        _ => throw ArgumentError('Unknown MessageType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        MessageType.text => 'Text',
        MessageType.system => 'System',
        MessageType.platformEvent => 'Platform Event',
        MessageType.file => 'File',
      };
}

/// JSON converter for [MessageType].
class MessageTypeConverter extends JsonConverter<MessageType, String> {
  /// Creates a [MessageTypeConverter].
  const MessageTypeConverter();

  @override
  MessageType fromJson(String json) => MessageType.fromJson(json);

  @override
  String toJson(MessageType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// ReactionType
// ─────────────────────────────────────────────────────────────────────────────

/// Types of reactions that can be applied to messages.
enum ReactionType {
  /// Emoji reaction.
  emoji;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ReactionType.emoji => 'EMOJI',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static ReactionType fromJson(String json) => switch (json) {
        'EMOJI' => ReactionType.emoji,
        _ => throw ArgumentError('Unknown ReactionType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ReactionType.emoji => 'Emoji',
      };
}

/// JSON converter for [ReactionType].
class ReactionTypeConverter extends JsonConverter<ReactionType, String> {
  /// Creates a [ReactionTypeConverter].
  const ReactionTypeConverter();

  @override
  ReactionType fromJson(String json) => ReactionType.fromJson(json);

  @override
  String toJson(ReactionType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// PresenceStatus
// ─────────────────────────────────────────────────────────────────────────────

/// Online presence status for team members.
enum PresenceStatus {
  /// User is actively online.
  online,

  /// User is away (idle).
  away,

  /// User has enabled Do Not Disturb.
  dnd,

  /// User is offline.
  offline;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        PresenceStatus.online => 'ONLINE',
        PresenceStatus.away => 'AWAY',
        PresenceStatus.dnd => 'DND',
        PresenceStatus.offline => 'OFFLINE',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static PresenceStatus fromJson(String json) => switch (json) {
        'ONLINE' => PresenceStatus.online,
        'AWAY' => PresenceStatus.away,
        'DND' => PresenceStatus.dnd,
        'OFFLINE' => PresenceStatus.offline,
        _ => throw ArgumentError('Unknown PresenceStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        PresenceStatus.online => 'Online',
        PresenceStatus.away => 'Away',
        PresenceStatus.dnd => 'Do Not Disturb',
        PresenceStatus.offline => 'Offline',
      };
}

/// JSON converter for [PresenceStatus].
class PresenceStatusConverter extends JsonConverter<PresenceStatus, String> {
  /// Creates a [PresenceStatusConverter].
  const PresenceStatusConverter();

  @override
  PresenceStatus fromJson(String json) => PresenceStatus.fromJson(json);

  @override
  String toJson(PresenceStatus object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// PlatformEventType
// ─────────────────────────────────────────────────────────────────────────────

/// Types of platform events delivered to Relay channels.
enum PlatformEventType {
  /// A code audit has been completed.
  auditCompleted,

  /// An alert rule has fired.
  alertFired,

  /// A session has completed.
  sessionCompleted,

  /// A secret has been rotated.
  secretRotated,

  /// A container has crashed.
  containerCrashed,

  /// A service has been registered.
  serviceRegistered,

  /// A deployment has completed.
  deploymentCompleted,

  /// A build has completed.
  buildCompleted,

  /// A critical finding has been detected.
  findingCritical,

  /// A merge request has been created.
  mergeRequestCreated;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        PlatformEventType.auditCompleted => 'AUDIT_COMPLETED',
        PlatformEventType.alertFired => 'ALERT_FIRED',
        PlatformEventType.sessionCompleted => 'SESSION_COMPLETED',
        PlatformEventType.secretRotated => 'SECRET_ROTATED',
        PlatformEventType.containerCrashed => 'CONTAINER_CRASHED',
        PlatformEventType.serviceRegistered => 'SERVICE_REGISTERED',
        PlatformEventType.deploymentCompleted => 'DEPLOYMENT_COMPLETED',
        PlatformEventType.buildCompleted => 'BUILD_COMPLETED',
        PlatformEventType.findingCritical => 'FINDING_CRITICAL',
        PlatformEventType.mergeRequestCreated => 'MERGE_REQUEST_CREATED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static PlatformEventType fromJson(String json) => switch (json) {
        'AUDIT_COMPLETED' => PlatformEventType.auditCompleted,
        'ALERT_FIRED' => PlatformEventType.alertFired,
        'SESSION_COMPLETED' => PlatformEventType.sessionCompleted,
        'SECRET_ROTATED' => PlatformEventType.secretRotated,
        'CONTAINER_CRASHED' => PlatformEventType.containerCrashed,
        'SERVICE_REGISTERED' => PlatformEventType.serviceRegistered,
        'DEPLOYMENT_COMPLETED' => PlatformEventType.deploymentCompleted,
        'BUILD_COMPLETED' => PlatformEventType.buildCompleted,
        'FINDING_CRITICAL' => PlatformEventType.findingCritical,
        'MERGE_REQUEST_CREATED' => PlatformEventType.mergeRequestCreated,
        _ => throw ArgumentError('Unknown PlatformEventType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        PlatformEventType.auditCompleted => 'Audit Completed',
        PlatformEventType.alertFired => 'Alert Fired',
        PlatformEventType.sessionCompleted => 'Session Completed',
        PlatformEventType.secretRotated => 'Secret Rotated',
        PlatformEventType.containerCrashed => 'Container Crashed',
        PlatformEventType.serviceRegistered => 'Service Registered',
        PlatformEventType.deploymentCompleted => 'Deployment Completed',
        PlatformEventType.buildCompleted => 'Build Completed',
        PlatformEventType.findingCritical => 'Finding Critical',
        PlatformEventType.mergeRequestCreated => 'Merge Request Created',
      };
}

/// JSON converter for [PlatformEventType].
class PlatformEventTypeConverter
    extends JsonConverter<PlatformEventType, String> {
  /// Creates a [PlatformEventTypeConverter].
  const PlatformEventTypeConverter();

  @override
  PlatformEventType fromJson(String json) => PlatformEventType.fromJson(json);

  @override
  String toJson(PlatformEventType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// FileUploadStatus
// ─────────────────────────────────────────────────────────────────────────────

/// Upload status of a file attachment.
enum FileUploadStatus {
  /// File is currently being uploaded.
  uploading,

  /// File upload completed successfully.
  complete,

  /// File upload failed.
  failed;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        FileUploadStatus.uploading => 'UPLOADING',
        FileUploadStatus.complete => 'COMPLETE',
        FileUploadStatus.failed => 'FAILED',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static FileUploadStatus fromJson(String json) => switch (json) {
        'UPLOADING' => FileUploadStatus.uploading,
        'COMPLETE' => FileUploadStatus.complete,
        'FAILED' => FileUploadStatus.failed,
        _ => throw ArgumentError('Unknown FileUploadStatus: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        FileUploadStatus.uploading => 'Uploading',
        FileUploadStatus.complete => 'Complete',
        FileUploadStatus.failed => 'Failed',
      };
}

/// JSON converter for [FileUploadStatus].
class FileUploadStatusConverter
    extends JsonConverter<FileUploadStatus, String> {
  /// Creates a [FileUploadStatusConverter].
  const FileUploadStatusConverter();

  @override
  FileUploadStatus fromJson(String json) => FileUploadStatus.fromJson(json);

  @override
  String toJson(FileUploadStatus object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// ConversationType
// ─────────────────────────────────────────────────────────────────────────────

/// Types of direct message conversations.
enum ConversationType {
  /// One-on-one conversation between two users.
  oneOnOne,

  /// Group conversation with multiple participants.
  group;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        ConversationType.oneOnOne => 'ONE_ON_ONE',
        ConversationType.group => 'GROUP',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static ConversationType fromJson(String json) => switch (json) {
        'ONE_ON_ONE' => ConversationType.oneOnOne,
        'GROUP' => ConversationType.group,
        _ => throw ArgumentError('Unknown ConversationType: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        ConversationType.oneOnOne => 'One-on-One',
        ConversationType.group => 'Group',
      };
}

/// JSON converter for [ConversationType].
class ConversationTypeConverter
    extends JsonConverter<ConversationType, String> {
  /// Creates a [ConversationTypeConverter].
  const ConversationTypeConverter();

  @override
  ConversationType fromJson(String json) => ConversationType.fromJson(json);

  @override
  String toJson(ConversationType object) => object.toJson();
}

// ─────────────────────────────────────────────────────────────────────────────
// MemberRole
// ─────────────────────────────────────────────────────────────────────────────

/// Roles for channel members.
enum MemberRole {
  /// Channel owner with full control.
  owner,

  /// Administrator with management permissions.
  admin,

  /// Regular channel member.
  member;

  /// Serializes to the server's SCREAMING_SNAKE_CASE representation.
  String toJson() => switch (this) {
        MemberRole.owner => 'OWNER',
        MemberRole.admin => 'ADMIN',
        MemberRole.member => 'MEMBER',
      };

  /// Deserializes from the server's SCREAMING_SNAKE_CASE representation.
  static MemberRole fromJson(String json) => switch (json) {
        'OWNER' => MemberRole.owner,
        'ADMIN' => MemberRole.admin,
        'MEMBER' => MemberRole.member,
        _ => throw ArgumentError('Unknown MemberRole: $json'),
      };

  /// Human-readable display label.
  String get displayName => switch (this) {
        MemberRole.owner => 'Owner',
        MemberRole.admin => 'Admin',
        MemberRole.member => 'Member',
      };
}

/// JSON converter for [MemberRole].
class MemberRoleConverter extends JsonConverter<MemberRole, String> {
  /// Creates a [MemberRoleConverter].
  const MemberRoleConverter();

  @override
  MemberRole fromJson(String json) => MemberRole.fromJson(json);

  @override
  String toJson(MemberRole object) => object.toJson();
}
