/// Jira Cloud API data models.
///
/// Maps to Jira REST API v3 response/request formats.
/// Used by [JiraService] for direct Jira Cloud communication.
library;

import 'package:json_annotation/json_annotation.dart';

part 'jira_models.g.dart';

// ---------------------------------------------------------------------------
// Search result
// ---------------------------------------------------------------------------

/// Paginated search result from Jira JQL search.
@JsonSerializable(explicitToJson: true)
class JiraSearchResult {
  /// Index of the first result returned.
  final int startAt;

  /// Maximum number of results requested.
  final int maxResults;

  /// Total matching issues.
  final int total;

  /// Issues in this page.
  final List<JiraIssue> issues;

  /// Creates a [JiraSearchResult].
  const JiraSearchResult({
    required this.startAt,
    required this.maxResults,
    required this.total,
    required this.issues,
  });

  /// Deserializes from JSON.
  factory JiraSearchResult.fromJson(Map<String, dynamic> json) =>
      _$JiraSearchResultFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraSearchResultToJson(this);
}

// ---------------------------------------------------------------------------
// Issue
// ---------------------------------------------------------------------------

/// A Jira issue (ticket).
@JsonSerializable(explicitToJson: true)
class JiraIssue {
  /// Jira internal ID.
  final String id;

  /// Issue key (e.g. 'PAY-456').
  final String key;

  /// REST API self URL.
  final String self;

  /// Issue field values.
  final JiraIssueFields fields;

  /// Creates a [JiraIssue].
  const JiraIssue({
    required this.id,
    required this.key,
    required this.self,
    required this.fields,
  });

  /// Deserializes from JSON.
  factory JiraIssue.fromJson(Map<String, dynamic> json) =>
      _$JiraIssueFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraIssueToJson(this);
}

/// Fields on a Jira issue.
@JsonSerializable(explicitToJson: true)
class JiraIssueFields {
  /// Issue summary / title.
  final String summary;

  /// Description in ADF (Atlassian Document Format) as JSON string.
  @JsonKey(fromJson: _dynamicToString, toJson: _stringToIdentity)
  final String? description;

  /// Issue type.
  final JiraIssueType issuetype;

  /// Current workflow status.
  final JiraStatus status;

  /// Priority level.
  final JiraPriority? priority;

  /// Assigned user.
  final JiraUser? assignee;

  /// User who created the issue.
  final JiraUser? reporter;

  /// Jira project the issue belongs to.
  final JiraProject? project;

  /// ISO datetime when created.
  final String? created;

  /// ISO datetime when last updated.
  final String? updated;

  /// Components the issue belongs to.
  final List<JiraComponent>? components;

  /// Labels applied to the issue.
  final List<String>? labels;

  /// Current sprint (from agile board).
  final JiraSprint? sprint;

  /// Parent issue (for sub-tasks).
  final JiraIssue? parent;

  /// Linked issues.
  final List<JiraIssueLink>? issuelinks;

  /// Attachments on the issue.
  final List<JiraAttachment>? attachment;

  /// Comments container.
  final JiraCommentPage? comment;

  /// Creates [JiraIssueFields].
  const JiraIssueFields({
    required this.summary,
    this.description,
    required this.issuetype,
    required this.status,
    this.priority,
    this.assignee,
    this.reporter,
    this.project,
    this.created,
    this.updated,
    this.components,
    this.labels,
    this.sprint,
    this.parent,
    this.issuelinks,
    this.attachment,
    this.comment,
  });

  /// Deserializes from JSON.
  factory JiraIssueFields.fromJson(Map<String, dynamic> json) =>
      _$JiraIssueFieldsFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraIssueFieldsToJson(this);
}

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

/// Jira workflow status.
@JsonSerializable(explicitToJson: true)
class JiraStatus {
  /// Jira internal ID.
  final String id;

  /// Status name (e.g. 'Open', 'In Progress', 'Done').
  final String name;

  /// Status category grouping.
  final JiraStatusCategory? statusCategory;

  /// Creates a [JiraStatus].
  const JiraStatus({
    required this.id,
    required this.name,
    this.statusCategory,
  });

  /// Deserializes from JSON.
  factory JiraStatus.fromJson(Map<String, dynamic> json) =>
      _$JiraStatusFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraStatusToJson(this);
}

/// Jira status category (groups statuses into To Do / In Progress / Done).
@JsonSerializable()
class JiraStatusCategory {
  /// Jira internal ID.
  final int id;

  /// Category key: 'new', 'indeterminate', 'done'.
  final String key;

  /// Display name.
  final String name;

  /// Color name: 'blue-gray', 'yellow', 'green'.
  final String? colorName;

  /// Creates a [JiraStatusCategory].
  const JiraStatusCategory({
    required this.id,
    required this.key,
    required this.name,
    this.colorName,
  });

  /// Deserializes from JSON.
  factory JiraStatusCategory.fromJson(Map<String, dynamic> json) =>
      _$JiraStatusCategoryFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraStatusCategoryToJson(this);
}

// ---------------------------------------------------------------------------
// Issue Type
// ---------------------------------------------------------------------------

/// Jira issue type definition.
@JsonSerializable()
class JiraIssueType {
  /// Jira internal ID.
  final String id;

  /// Type name (e.g. 'Bug', 'Task', 'Story', 'Sub-task').
  final String name;

  /// Whether this type represents a sub-task.
  final bool subtask;

  /// URL to the type's icon.
  final String? iconUrl;

  /// Creates a [JiraIssueType].
  const JiraIssueType({
    required this.id,
    required this.name,
    required this.subtask,
    this.iconUrl,
  });

  /// Deserializes from JSON.
  factory JiraIssueType.fromJson(Map<String, dynamic> json) =>
      _$JiraIssueTypeFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraIssueTypeToJson(this);
}

// ---------------------------------------------------------------------------
// Priority
// ---------------------------------------------------------------------------

/// Jira issue priority.
@JsonSerializable()
class JiraPriority {
  /// Jira internal ID.
  final String id;

  /// Priority name (e.g. 'Highest', 'High', 'Medium', 'Low', 'Lowest').
  final String name;

  /// URL to the priority's icon.
  final String? iconUrl;

  /// Creates a [JiraPriority].
  const JiraPriority({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  /// Deserializes from JSON.
  factory JiraPriority.fromJson(Map<String, dynamic> json) =>
      _$JiraPriorityFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraPriorityToJson(this);
}

// ---------------------------------------------------------------------------
// User
// ---------------------------------------------------------------------------

/// Jira user account.
@JsonSerializable(explicitToJson: true)
class JiraUser {
  /// Atlassian account ID.
  final String accountId;

  /// Display name.
  final String? displayName;

  /// Email address (may be null depending on Jira privacy settings).
  final String? emailAddress;

  /// Avatar image URLs at various sizes.
  final JiraAvatarUrls? avatarUrls;

  /// Whether the account is active.
  final bool? active;

  /// Creates a [JiraUser].
  const JiraUser({
    required this.accountId,
    this.displayName,
    this.emailAddress,
    this.avatarUrls,
    this.active,
  });

  /// Deserializes from JSON.
  factory JiraUser.fromJson(Map<String, dynamic> json) =>
      _$JiraUserFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraUserToJson(this);
}

/// Avatar URLs at standard Jira sizes.
@JsonSerializable()
class JiraAvatarUrls {
  /// 48x48 avatar URL.
  @JsonKey(name: '48x48')
  final String? x48;

  /// 32x32 avatar URL.
  @JsonKey(name: '32x32')
  final String? x32;

  /// 24x24 avatar URL.
  @JsonKey(name: '24x24')
  final String? x24;

  /// 16x16 avatar URL.
  @JsonKey(name: '16x16')
  final String? x16;

  /// Creates [JiraAvatarUrls].
  const JiraAvatarUrls({this.x48, this.x32, this.x24, this.x16});

  /// Deserializes from JSON.
  factory JiraAvatarUrls.fromJson(Map<String, dynamic> json) =>
      _$JiraAvatarUrlsFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraAvatarUrlsToJson(this);
}

// ---------------------------------------------------------------------------
// Project
// ---------------------------------------------------------------------------

/// Jira project.
@JsonSerializable()
class JiraProject {
  /// Jira internal ID.
  final String id;

  /// Project key (e.g. 'PAY').
  final String key;

  /// Project name.
  final String name;

  /// Avatar URL.
  @JsonKey(name: 'avatarUrls')
  final Map<String, dynamic>? avatarUrlsMap;

  /// Creates a [JiraProject].
  const JiraProject({
    required this.id,
    required this.key,
    required this.name,
    this.avatarUrlsMap,
  });

  /// Returns the best available avatar URL.
  String? get avatarUrl {
    if (avatarUrlsMap == null) return null;
    return avatarUrlsMap!['48x48'] as String? ??
        avatarUrlsMap!['32x32'] as String?;
  }

  /// Deserializes from JSON.
  factory JiraProject.fromJson(Map<String, dynamic> json) =>
      _$JiraProjectFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraProjectToJson(this);
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

/// Jira project component.
@JsonSerializable()
class JiraComponent {
  /// Jira internal ID.
  final String id;

  /// Component name.
  final String name;

  /// Creates a [JiraComponent].
  const JiraComponent({required this.id, required this.name});

  /// Deserializes from JSON.
  factory JiraComponent.fromJson(Map<String, dynamic> json) =>
      _$JiraComponentFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraComponentToJson(this);
}

// ---------------------------------------------------------------------------
// Sprint
// ---------------------------------------------------------------------------

/// Jira agile sprint.
@JsonSerializable()
class JiraSprint {
  /// Sprint ID.
  final int id;

  /// Sprint name.
  final String name;

  /// Sprint state: 'active', 'closed', 'future'.
  final String state;

  /// ISO datetime when sprint started.
  final String? startDate;

  /// ISO datetime when sprint ends.
  final String? endDate;

  /// Creates a [JiraSprint].
  const JiraSprint({
    required this.id,
    required this.name,
    required this.state,
    this.startDate,
    this.endDate,
  });

  /// Deserializes from JSON.
  factory JiraSprint.fromJson(Map<String, dynamic> json) =>
      _$JiraSprintFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraSprintToJson(this);
}

// ---------------------------------------------------------------------------
// Comment
// ---------------------------------------------------------------------------

/// A Jira issue comment.
@JsonSerializable(explicitToJson: true)
class JiraComment {
  /// Comment ID.
  final String id;

  /// Comment author.
  final JiraUser? author;

  /// Comment body in ADF JSON.
  @JsonKey(fromJson: _dynamicToString, toJson: _stringToIdentity)
  final String? body;

  /// ISO datetime when created.
  final String? created;

  /// ISO datetime when last updated.
  final String? updated;

  /// Creates a [JiraComment].
  const JiraComment({
    required this.id,
    this.author,
    this.body,
    this.created,
    this.updated,
  });

  /// Deserializes from JSON.
  factory JiraComment.fromJson(Map<String, dynamic> json) =>
      _$JiraCommentFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraCommentToJson(this);
}

/// Paginated comments response.
@JsonSerializable(explicitToJson: true)
class JiraCommentPage {
  /// Total comment count.
  final int total;

  /// Maximum results returned.
  final int maxResults;

  /// Comments in this page.
  final List<JiraComment> comments;

  /// Creates a [JiraCommentPage].
  const JiraCommentPage({
    required this.total,
    required this.maxResults,
    required this.comments,
  });

  /// Deserializes from JSON.
  factory JiraCommentPage.fromJson(Map<String, dynamic> json) =>
      _$JiraCommentPageFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraCommentPageToJson(this);
}

// ---------------------------------------------------------------------------
// Attachment
// ---------------------------------------------------------------------------

/// A Jira issue attachment.
@JsonSerializable(explicitToJson: true)
class JiraAttachment {
  /// Attachment ID.
  final String id;

  /// Original filename.
  final String filename;

  /// MIME type.
  final String? mimeType;

  /// File size in bytes.
  final int? size;

  /// Download URL.
  final String content;

  /// User who attached the file.
  final JiraUser? author;

  /// ISO datetime when attached.
  final String? created;

  /// Creates a [JiraAttachment].
  const JiraAttachment({
    required this.id,
    required this.filename,
    this.mimeType,
    this.size,
    required this.content,
    this.author,
    this.created,
  });

  /// Deserializes from JSON.
  factory JiraAttachment.fromJson(Map<String, dynamic> json) =>
      _$JiraAttachmentFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraAttachmentToJson(this);
}

// ---------------------------------------------------------------------------
// Issue Link
// ---------------------------------------------------------------------------

/// A link between two Jira issues.
@JsonSerializable(explicitToJson: true)
class JiraIssueLink {
  /// Link ID.
  final String id;

  /// Link type (e.g. 'Blocks', 'Duplicate').
  final JiraIssueLinkType type;

  /// Inward issue (e.g. 'is blocked by' this issue).
  final JiraIssue? inwardIssue;

  /// Outward issue (e.g. this issue 'blocks').
  final JiraIssue? outwardIssue;

  /// Creates a [JiraIssueLink].
  const JiraIssueLink({
    required this.id,
    required this.type,
    this.inwardIssue,
    this.outwardIssue,
  });

  /// Deserializes from JSON.
  factory JiraIssueLink.fromJson(Map<String, dynamic> json) =>
      _$JiraIssueLinkFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraIssueLinkToJson(this);
}

/// Type of link between Jira issues.
@JsonSerializable()
class JiraIssueLinkType {
  /// Link type name (e.g. 'Blocks', 'Duplicate', 'Relates').
  final String name;

  /// Inward description (e.g. 'is blocked by').
  final String inward;

  /// Outward description (e.g. 'blocks').
  final String outward;

  /// Creates a [JiraIssueLinkType].
  const JiraIssueLinkType({
    required this.name,
    required this.inward,
    required this.outward,
  });

  /// Deserializes from JSON.
  factory JiraIssueLinkType.fromJson(Map<String, dynamic> json) =>
      _$JiraIssueLinkTypeFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraIssueLinkTypeToJson(this);
}

// ---------------------------------------------------------------------------
// Transition
// ---------------------------------------------------------------------------

/// An available workflow transition for a Jira issue.
@JsonSerializable(explicitToJson: true)
class JiraTransition {
  /// Transition ID.
  final String id;

  /// Transition name (e.g. 'In Progress', 'Done').
  final String name;

  /// Target status after transition.
  final JiraStatus to;

  /// Creates a [JiraTransition].
  const JiraTransition({
    required this.id,
    required this.name,
    required this.to,
  });

  /// Deserializes from JSON.
  factory JiraTransition.fromJson(Map<String, dynamic> json) =>
      _$JiraTransitionFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$JiraTransitionToJson(this);
}

// ---------------------------------------------------------------------------
// Request models
// ---------------------------------------------------------------------------

/// Request to create a new Jira issue.
@JsonSerializable()
class CreateJiraIssueRequest {
  /// Jira project key (e.g. 'PAY').
  final String projectKey;

  /// Issue type name (e.g. 'Bug', 'Task').
  final String issueTypeName;

  /// Issue summary / title.
  final String summary;

  /// Issue description (ADF JSON or plain text).
  final String? description;

  /// Assignee's Atlassian account ID.
  final String? assigneeAccountId;

  /// Priority name (e.g. 'High').
  final String? priorityName;

  /// Labels to apply.
  final List<String>? labels;

  /// Component name to assign.
  final String? componentName;

  /// Parent issue key (for sub-tasks).
  final String? parentKey;

  /// Sprint ID to add the issue to.
  final String? sprintId;

  /// Creates a [CreateJiraIssueRequest].
  const CreateJiraIssueRequest({
    required this.projectKey,
    required this.issueTypeName,
    required this.summary,
    this.description,
    this.assigneeAccountId,
    this.priorityName,
    this.labels,
    this.componentName,
    this.parentKey,
    this.sprintId,
  });

  /// Deserializes from JSON.
  factory CreateJiraIssueRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateJiraIssueRequestFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$CreateJiraIssueRequestToJson(this);
}

/// Request to create a sub-task under a parent issue.
@JsonSerializable()
class CreateJiraSubTaskRequest {
  /// Parent issue key (e.g. 'PAY-456').
  final String parentKey;

  /// Jira project key.
  final String projectKey;

  /// Sub-task summary.
  final String summary;

  /// Sub-task description.
  final String? description;

  /// Assignee's Atlassian account ID.
  final String? assigneeAccountId;

  /// Priority name.
  final String? priorityName;

  /// Creates a [CreateJiraSubTaskRequest].
  const CreateJiraSubTaskRequest({
    required this.parentKey,
    required this.projectKey,
    required this.summary,
    this.description,
    this.assigneeAccountId,
    this.priorityName,
  });

  /// Deserializes from JSON.
  factory CreateJiraSubTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateJiraSubTaskRequestFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$CreateJiraSubTaskRequestToJson(this);
}

/// Request to update a Jira issue's fields.
@JsonSerializable()
class UpdateJiraIssueRequest {
  /// New assignee account ID.
  final String? assigneeAccountId;

  /// New summary.
  final String? summary;

  /// New description.
  final String? description;

  /// New priority name.
  final String? priorityName;

  /// New labels.
  final List<String>? labels;

  /// Creates an [UpdateJiraIssueRequest].
  const UpdateJiraIssueRequest({
    this.assigneeAccountId,
    this.summary,
    this.description,
    this.priorityName,
    this.labels,
  });

  /// Deserializes from JSON.
  factory UpdateJiraIssueRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateJiraIssueRequestFromJson(json);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => _$UpdateJiraIssueRequestToJson(this);
}

// ---------------------------------------------------------------------------
// Display models (not API models — used by UI)
// ---------------------------------------------------------------------------

/// Simplified Jira issue for list/card display.
class JiraIssueDisplayModel {
  /// Issue key (e.g. 'PAY-456').
  final String key;

  /// Issue summary.
  final String summary;

  /// Status display name.
  final String statusName;

  /// Status category key for coloring.
  final String? statusCategoryKey;

  /// Priority display name.
  final String? priorityName;

  /// Priority icon URL.
  final String? priorityIconUrl;

  /// Assignee display name.
  final String? assigneeName;

  /// Assignee avatar URL.
  final String? assigneeAvatarUrl;

  /// Issue type name.
  final String? issuetypeName;

  /// Issue type icon URL.
  final String? issuetypeIconUrl;

  /// Number of comments.
  final int commentCount;

  /// Number of attachments.
  final int attachmentCount;

  /// Number of linked issues.
  final int linkCount;

  /// When the issue was created.
  final DateTime? created;

  /// When the issue was last updated.
  final DateTime? updated;

  /// Creates a [JiraIssueDisplayModel].
  const JiraIssueDisplayModel({
    required this.key,
    required this.summary,
    required this.statusName,
    this.statusCategoryKey,
    this.priorityName,
    this.priorityIconUrl,
    this.assigneeName,
    this.assigneeAvatarUrl,
    this.issuetypeName,
    this.issuetypeIconUrl,
    this.commentCount = 0,
    this.attachmentCount = 0,
    this.linkCount = 0,
    this.created,
    this.updated,
  });
}

// ---------------------------------------------------------------------------
// JSON helpers
// ---------------------------------------------------------------------------

/// Converts a dynamic value (Map or String) to a JSON string representation.
///
/// Jira returns description and comment body as ADF objects (Map), but we
/// store them as JSON strings for simpler handling.
String? _dynamicToString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  // ADF comes as a Map — encode it for storage.
  return value.toString();
}

/// Identity transform for toJson.
dynamic _stringToIdentity(String? value) => value;
