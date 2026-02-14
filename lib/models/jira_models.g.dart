// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jira_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JiraSearchResult _$JiraSearchResultFromJson(Map<String, dynamic> json) =>
    JiraSearchResult(
      startAt: (json['startAt'] as num).toInt(),
      maxResults: (json['maxResults'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      issues: (json['issues'] as List<dynamic>)
          .map((e) => JiraIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JiraSearchResultToJson(JiraSearchResult instance) =>
    <String, dynamic>{
      'startAt': instance.startAt,
      'maxResults': instance.maxResults,
      'total': instance.total,
      'issues': instance.issues.map((e) => e.toJson()).toList(),
    };

JiraIssue _$JiraIssueFromJson(Map<String, dynamic> json) => JiraIssue(
      id: json['id'] as String,
      key: json['key'] as String,
      self: json['self'] as String,
      fields: JiraIssueFields.fromJson(json['fields'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JiraIssueToJson(JiraIssue instance) => <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'self': instance.self,
      'fields': instance.fields.toJson(),
    };

JiraIssueFields _$JiraIssueFieldsFromJson(Map<String, dynamic> json) =>
    JiraIssueFields(
      summary: json['summary'] as String,
      description: _dynamicToString(json['description']),
      issuetype:
          JiraIssueType.fromJson(json['issuetype'] as Map<String, dynamic>),
      status: JiraStatus.fromJson(json['status'] as Map<String, dynamic>),
      priority: json['priority'] == null
          ? null
          : JiraPriority.fromJson(json['priority'] as Map<String, dynamic>),
      assignee: json['assignee'] == null
          ? null
          : JiraUser.fromJson(json['assignee'] as Map<String, dynamic>),
      reporter: json['reporter'] == null
          ? null
          : JiraUser.fromJson(json['reporter'] as Map<String, dynamic>),
      project: json['project'] == null
          ? null
          : JiraProject.fromJson(json['project'] as Map<String, dynamic>),
      created: json['created'] as String?,
      updated: json['updated'] as String?,
      components: (json['components'] as List<dynamic>?)
          ?.map((e) => JiraComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      labels:
          (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
      sprint: json['sprint'] == null
          ? null
          : JiraSprint.fromJson(json['sprint'] as Map<String, dynamic>),
      parent: json['parent'] == null
          ? null
          : JiraIssue.fromJson(json['parent'] as Map<String, dynamic>),
      issuelinks: (json['issuelinks'] as List<dynamic>?)
          ?.map((e) => JiraIssueLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachment: (json['attachment'] as List<dynamic>?)
          ?.map((e) => JiraAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      comment: json['comment'] == null
          ? null
          : JiraCommentPage.fromJson(json['comment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JiraIssueFieldsToJson(JiraIssueFields instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'description': _stringToIdentity(instance.description),
      'issuetype': instance.issuetype.toJson(),
      'status': instance.status.toJson(),
      'priority': instance.priority?.toJson(),
      'assignee': instance.assignee?.toJson(),
      'reporter': instance.reporter?.toJson(),
      'project': instance.project?.toJson(),
      'created': instance.created,
      'updated': instance.updated,
      'components': instance.components?.map((e) => e.toJson()).toList(),
      'labels': instance.labels,
      'sprint': instance.sprint?.toJson(),
      'parent': instance.parent?.toJson(),
      'issuelinks': instance.issuelinks?.map((e) => e.toJson()).toList(),
      'attachment': instance.attachment?.map((e) => e.toJson()).toList(),
      'comment': instance.comment?.toJson(),
    };

JiraStatus _$JiraStatusFromJson(Map<String, dynamic> json) => JiraStatus(
      id: json['id'] as String,
      name: json['name'] as String,
      statusCategory: json['statusCategory'] == null
          ? null
          : JiraStatusCategory.fromJson(
              json['statusCategory'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JiraStatusToJson(JiraStatus instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'statusCategory': instance.statusCategory?.toJson(),
    };

JiraStatusCategory _$JiraStatusCategoryFromJson(Map<String, dynamic> json) =>
    JiraStatusCategory(
      id: (json['id'] as num).toInt(),
      key: json['key'] as String,
      name: json['name'] as String,
      colorName: json['colorName'] as String?,
    );

Map<String, dynamic> _$JiraStatusCategoryToJson(JiraStatusCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'name': instance.name,
      'colorName': instance.colorName,
    };

JiraIssueType _$JiraIssueTypeFromJson(Map<String, dynamic> json) =>
    JiraIssueType(
      id: json['id'] as String,
      name: json['name'] as String,
      subtask: json['subtask'] as bool,
      iconUrl: json['iconUrl'] as String?,
    );

Map<String, dynamic> _$JiraIssueTypeToJson(JiraIssueType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'subtask': instance.subtask,
      'iconUrl': instance.iconUrl,
    };

JiraPriority _$JiraPriorityFromJson(Map<String, dynamic> json) => JiraPriority(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String?,
    );

Map<String, dynamic> _$JiraPriorityToJson(JiraPriority instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconUrl': instance.iconUrl,
    };

JiraUser _$JiraUserFromJson(Map<String, dynamic> json) => JiraUser(
      accountId: json['accountId'] as String,
      displayName: json['displayName'] as String?,
      emailAddress: json['emailAddress'] as String?,
      avatarUrls: json['avatarUrls'] == null
          ? null
          : JiraAvatarUrls.fromJson(json['avatarUrls'] as Map<String, dynamic>),
      active: json['active'] as bool?,
    );

Map<String, dynamic> _$JiraUserToJson(JiraUser instance) => <String, dynamic>{
      'accountId': instance.accountId,
      'displayName': instance.displayName,
      'emailAddress': instance.emailAddress,
      'avatarUrls': instance.avatarUrls?.toJson(),
      'active': instance.active,
    };

JiraAvatarUrls _$JiraAvatarUrlsFromJson(Map<String, dynamic> json) =>
    JiraAvatarUrls(
      x48: json['48x48'] as String?,
      x32: json['32x32'] as String?,
      x24: json['24x24'] as String?,
      x16: json['16x16'] as String?,
    );

Map<String, dynamic> _$JiraAvatarUrlsToJson(JiraAvatarUrls instance) =>
    <String, dynamic>{
      '48x48': instance.x48,
      '32x32': instance.x32,
      '24x24': instance.x24,
      '16x16': instance.x16,
    };

JiraProject _$JiraProjectFromJson(Map<String, dynamic> json) => JiraProject(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      avatarUrlsMap: json['avatarUrls'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$JiraProjectToJson(JiraProject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'name': instance.name,
      'avatarUrls': instance.avatarUrlsMap,
    };

JiraComponent _$JiraComponentFromJson(Map<String, dynamic> json) =>
    JiraComponent(
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$JiraComponentToJson(JiraComponent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

JiraSprint _$JiraSprintFromJson(Map<String, dynamic> json) => JiraSprint(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      state: json['state'] as String,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
    );

Map<String, dynamic> _$JiraSprintToJson(JiraSprint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'state': instance.state,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

JiraComment _$JiraCommentFromJson(Map<String, dynamic> json) => JiraComment(
      id: json['id'] as String,
      author: json['author'] == null
          ? null
          : JiraUser.fromJson(json['author'] as Map<String, dynamic>),
      body: _dynamicToString(json['body']),
      created: json['created'] as String?,
      updated: json['updated'] as String?,
    );

Map<String, dynamic> _$JiraCommentToJson(JiraComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author?.toJson(),
      'body': _stringToIdentity(instance.body),
      'created': instance.created,
      'updated': instance.updated,
    };

JiraCommentPage _$JiraCommentPageFromJson(Map<String, dynamic> json) =>
    JiraCommentPage(
      total: (json['total'] as num).toInt(),
      maxResults: (json['maxResults'] as num).toInt(),
      comments: (json['comments'] as List<dynamic>)
          .map((e) => JiraComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JiraCommentPageToJson(JiraCommentPage instance) =>
    <String, dynamic>{
      'total': instance.total,
      'maxResults': instance.maxResults,
      'comments': instance.comments.map((e) => e.toJson()).toList(),
    };

JiraAttachment _$JiraAttachmentFromJson(Map<String, dynamic> json) =>
    JiraAttachment(
      id: json['id'] as String,
      filename: json['filename'] as String,
      mimeType: json['mimeType'] as String?,
      size: (json['size'] as num?)?.toInt(),
      content: json['content'] as String,
      author: json['author'] == null
          ? null
          : JiraUser.fromJson(json['author'] as Map<String, dynamic>),
      created: json['created'] as String?,
    );

Map<String, dynamic> _$JiraAttachmentToJson(JiraAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filename': instance.filename,
      'mimeType': instance.mimeType,
      'size': instance.size,
      'content': instance.content,
      'author': instance.author?.toJson(),
      'created': instance.created,
    };

JiraIssueLink _$JiraIssueLinkFromJson(Map<String, dynamic> json) =>
    JiraIssueLink(
      id: json['id'] as String,
      type: JiraIssueLinkType.fromJson(json['type'] as Map<String, dynamic>),
      inwardIssue: json['inwardIssue'] == null
          ? null
          : JiraIssue.fromJson(json['inwardIssue'] as Map<String, dynamic>),
      outwardIssue: json['outwardIssue'] == null
          ? null
          : JiraIssue.fromJson(json['outwardIssue'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JiraIssueLinkToJson(JiraIssueLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type.toJson(),
      'inwardIssue': instance.inwardIssue?.toJson(),
      'outwardIssue': instance.outwardIssue?.toJson(),
    };

JiraIssueLinkType _$JiraIssueLinkTypeFromJson(Map<String, dynamic> json) =>
    JiraIssueLinkType(
      name: json['name'] as String,
      inward: json['inward'] as String,
      outward: json['outward'] as String,
    );

Map<String, dynamic> _$JiraIssueLinkTypeToJson(JiraIssueLinkType instance) =>
    <String, dynamic>{
      'name': instance.name,
      'inward': instance.inward,
      'outward': instance.outward,
    };

JiraTransition _$JiraTransitionFromJson(Map<String, dynamic> json) =>
    JiraTransition(
      id: json['id'] as String,
      name: json['name'] as String,
      to: JiraStatus.fromJson(json['to'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JiraTransitionToJson(JiraTransition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'to': instance.to.toJson(),
    };

CreateJiraIssueRequest _$CreateJiraIssueRequestFromJson(
        Map<String, dynamic> json) =>
    CreateJiraIssueRequest(
      projectKey: json['projectKey'] as String,
      issueTypeName: json['issueTypeName'] as String,
      summary: json['summary'] as String,
      description: json['description'] as String?,
      assigneeAccountId: json['assigneeAccountId'] as String?,
      priorityName: json['priorityName'] as String?,
      labels:
          (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
      componentName: json['componentName'] as String?,
      parentKey: json['parentKey'] as String?,
      sprintId: json['sprintId'] as String?,
    );

Map<String, dynamic> _$CreateJiraIssueRequestToJson(
        CreateJiraIssueRequest instance) =>
    <String, dynamic>{
      'projectKey': instance.projectKey,
      'issueTypeName': instance.issueTypeName,
      'summary': instance.summary,
      'description': instance.description,
      'assigneeAccountId': instance.assigneeAccountId,
      'priorityName': instance.priorityName,
      'labels': instance.labels,
      'componentName': instance.componentName,
      'parentKey': instance.parentKey,
      'sprintId': instance.sprintId,
    };

CreateJiraSubTaskRequest _$CreateJiraSubTaskRequestFromJson(
        Map<String, dynamic> json) =>
    CreateJiraSubTaskRequest(
      parentKey: json['parentKey'] as String,
      projectKey: json['projectKey'] as String,
      summary: json['summary'] as String,
      description: json['description'] as String?,
      assigneeAccountId: json['assigneeAccountId'] as String?,
      priorityName: json['priorityName'] as String?,
    );

Map<String, dynamic> _$CreateJiraSubTaskRequestToJson(
        CreateJiraSubTaskRequest instance) =>
    <String, dynamic>{
      'parentKey': instance.parentKey,
      'projectKey': instance.projectKey,
      'summary': instance.summary,
      'description': instance.description,
      'assigneeAccountId': instance.assigneeAccountId,
      'priorityName': instance.priorityName,
    };

UpdateJiraIssueRequest _$UpdateJiraIssueRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateJiraIssueRequest(
      assigneeAccountId: json['assigneeAccountId'] as String?,
      summary: json['summary'] as String?,
      description: json['description'] as String?,
      priorityName: json['priorityName'] as String?,
      labels:
          (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$UpdateJiraIssueRequestToJson(
        UpdateJiraIssueRequest instance) =>
    <String, dynamic>{
      'assigneeAccountId': instance.assigneeAccountId,
      'summary': instance.summary,
      'description': instance.description,
      'priorityName': instance.priorityName,
      'labels': instance.labels,
    };
