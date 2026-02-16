// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _lastLoginAtMeta =
      const VerificationMeta('lastLoginAt');
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
      'last_login_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, email, displayName, avatarUrl, isActive, lastLoginAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
          _lastLoginAtMeta,
          lastLoginAt.isAcceptableOrUnknown(
              data['last_login_at']!, _lastLoginAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      lastLoginAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_login_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  /// UUID primary key.
  final String id;

  /// User email address.
  final String email;

  /// Display name.
  final String displayName;

  /// Avatar URL.
  final String? avatarUrl;

  /// Whether the account is active.
  final bool isActive;

  /// Last login timestamp.
  final DateTime? lastLoginAt;

  /// Account creation timestamp.
  final DateTime? createdAt;
  const User(
      {required this.id,
      required this.email,
      required this.displayName,
      this.avatarUrl,
      required this.isActive,
      this.lastLoginAt,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: Value(email),
      displayName: Value(displayName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      isActive: Value(isActive),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      lastLoginAt: serializer.fromJson<DateTime?>(json['lastLoginAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'isActive': serializer.toJson<bool>(isActive),
      'lastLoginAt': serializer.toJson<DateTime?>(lastLoginAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  User copyWith(
          {String? id,
          String? email,
          String? displayName,
          Value<String?> avatarUrl = const Value.absent(),
          bool? isActive,
          Value<DateTime?> lastLoginAt = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        isActive: isActive ?? this.isActive,
        lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      lastLoginAt:
          data.lastLoginAt.present ? data.lastLoginAt.value : this.lastLoginAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isActive: $isActive, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, email, displayName, avatarUrl, isActive, lastLoginAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.avatarUrl == this.avatarUrl &&
          other.isActive == this.isActive &&
          other.lastLoginAt == this.lastLoginAt &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> displayName;
  final Value<String?> avatarUrl;
  final Value<bool> isActive;
  final Value<DateTime?> lastLoginAt;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String email,
    required String displayName,
    this.avatarUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        email = Value(email),
        displayName = Value(displayName);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? avatarUrl,
    Expression<bool>? isActive,
    Expression<DateTime>? lastLoginAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (isActive != null) 'is_active': isActive,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? email,
      Value<String>? displayName,
      Value<String?>? avatarUrl,
      Value<bool>? isActive,
      Value<DateTime?>? lastLoginAt,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('isActive: $isActive, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, Team> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerNameMeta =
      const VerificationMeta('ownerName');
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
      'owner_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _teamsWebhookUrlMeta =
      const VerificationMeta('teamsWebhookUrl');
  @override
  late final GeneratedColumn<String> teamsWebhookUrl = GeneratedColumn<String>(
      'teams_webhook_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memberCountMeta =
      const VerificationMeta('memberCount');
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
      'member_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        ownerId,
        ownerName,
        teamsWebhookUrl,
        memberCount,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(Insertable<Team> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(_ownerNameMeta,
          ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta));
    }
    if (data.containsKey('teams_webhook_url')) {
      context.handle(
          _teamsWebhookUrlMeta,
          teamsWebhookUrl.isAcceptableOrUnknown(
              data['teams_webhook_url']!, _teamsWebhookUrlMeta));
    }
    if (data.containsKey('member_count')) {
      context.handle(
          _memberCountMeta,
          memberCount.isAcceptableOrUnknown(
              data['member_count']!, _memberCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Team map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Team(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      ownerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_name']),
      teamsWebhookUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}teams_webhook_url']),
      memberCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}member_count']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class Team extends DataClass implements Insertable<Team> {
  /// UUID primary key.
  final String id;

  /// Team name.
  final String name;

  /// Description.
  final String? description;

  /// Owner UUID.
  final String ownerId;

  /// Owner display name.
  final String? ownerName;

  /// Microsoft Teams webhook URL.
  final String? teamsWebhookUrl;

  /// Member count.
  final int? memberCount;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;
  const Team(
      {required this.id,
      required this.name,
      this.description,
      required this.ownerId,
      this.ownerName,
      this.teamsWebhookUrl,
      this.memberCount,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || ownerName != null) {
      map['owner_name'] = Variable<String>(ownerName);
    }
    if (!nullToAbsent || teamsWebhookUrl != null) {
      map['teams_webhook_url'] = Variable<String>(teamsWebhookUrl);
    }
    if (!nullToAbsent || memberCount != null) {
      map['member_count'] = Variable<int>(memberCount);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      ownerId: Value(ownerId),
      ownerName: ownerName == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerName),
      teamsWebhookUrl: teamsWebhookUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(teamsWebhookUrl),
      memberCount: memberCount == null && nullToAbsent
          ? const Value.absent()
          : Value(memberCount),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Team.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Team(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      ownerName: serializer.fromJson<String?>(json['ownerName']),
      teamsWebhookUrl: serializer.fromJson<String?>(json['teamsWebhookUrl']),
      memberCount: serializer.fromJson<int?>(json['memberCount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'ownerId': serializer.toJson<String>(ownerId),
      'ownerName': serializer.toJson<String?>(ownerName),
      'teamsWebhookUrl': serializer.toJson<String?>(teamsWebhookUrl),
      'memberCount': serializer.toJson<int?>(memberCount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Team copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          String? ownerId,
          Value<String?> ownerName = const Value.absent(),
          Value<String?> teamsWebhookUrl = const Value.absent(),
          Value<int?> memberCount = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Team(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        ownerId: ownerId ?? this.ownerId,
        ownerName: ownerName.present ? ownerName.value : this.ownerName,
        teamsWebhookUrl: teamsWebhookUrl.present
            ? teamsWebhookUrl.value
            : this.teamsWebhookUrl,
        memberCount: memberCount.present ? memberCount.value : this.memberCount,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Team copyWithCompanion(TeamsCompanion data) {
    return Team(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      teamsWebhookUrl: data.teamsWebhookUrl.present
          ? data.teamsWebhookUrl.value
          : this.teamsWebhookUrl,
      memberCount:
          data.memberCount.present ? data.memberCount.value : this.memberCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Team(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('ownerId: $ownerId, ')
          ..write('ownerName: $ownerName, ')
          ..write('teamsWebhookUrl: $teamsWebhookUrl, ')
          ..write('memberCount: $memberCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, ownerId, ownerName,
      teamsWebhookUrl, memberCount, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Team &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.ownerId == this.ownerId &&
          other.ownerName == this.ownerName &&
          other.teamsWebhookUrl == this.teamsWebhookUrl &&
          other.memberCount == this.memberCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TeamsCompanion extends UpdateCompanion<Team> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> ownerId;
  final Value<String?> ownerName;
  final Value<String?> teamsWebhookUrl;
  final Value<int?> memberCount;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.teamsWebhookUrl = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String ownerId,
    this.ownerName = const Value.absent(),
    this.teamsWebhookUrl = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        ownerId = Value(ownerId);
  static Insertable<Team> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? ownerId,
    Expression<String>? ownerName,
    Expression<String>? teamsWebhookUrl,
    Expression<int>? memberCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (ownerId != null) 'owner_id': ownerId,
      if (ownerName != null) 'owner_name': ownerName,
      if (teamsWebhookUrl != null) 'teams_webhook_url': teamsWebhookUrl,
      if (memberCount != null) 'member_count': memberCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<String>? ownerId,
      Value<String?>? ownerName,
      Value<String?>? teamsWebhookUrl,
      Value<int?>? memberCount,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return TeamsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      teamsWebhookUrl: teamsWebhookUrl ?? this.teamsWebhookUrl,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (teamsWebhookUrl.present) {
      map['teams_webhook_url'] = Variable<String>(teamsWebhookUrl.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('ownerId: $ownerId, ')
          ..write('ownerName: $ownerName, ')
          ..write('teamsWebhookUrl: $teamsWebhookUrl, ')
          ..write('memberCount: $memberCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
      'team_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _githubConnectionIdMeta =
      const VerificationMeta('githubConnectionId');
  @override
  late final GeneratedColumn<String> githubConnectionId =
      GeneratedColumn<String>('github_connection_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repoUrlMeta =
      const VerificationMeta('repoUrl');
  @override
  late final GeneratedColumn<String> repoUrl = GeneratedColumn<String>(
      'repo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repoFullNameMeta =
      const VerificationMeta('repoFullName');
  @override
  late final GeneratedColumn<String> repoFullName = GeneratedColumn<String>(
      'repo_full_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _defaultBranchMeta =
      const VerificationMeta('defaultBranch');
  @override
  late final GeneratedColumn<String> defaultBranch = GeneratedColumn<String>(
      'default_branch', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jiraConnectionIdMeta =
      const VerificationMeta('jiraConnectionId');
  @override
  late final GeneratedColumn<String> jiraConnectionId = GeneratedColumn<String>(
      'jira_connection_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jiraProjectKeyMeta =
      const VerificationMeta('jiraProjectKey');
  @override
  late final GeneratedColumn<String> jiraProjectKey = GeneratedColumn<String>(
      'jira_project_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _techStackMeta =
      const VerificationMeta('techStack');
  @override
  late final GeneratedColumn<String> techStack = GeneratedColumn<String>(
      'tech_stack', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _healthScoreMeta =
      const VerificationMeta('healthScore');
  @override
  late final GeneratedColumn<int> healthScore = GeneratedColumn<int>(
      'health_score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastAuditAtMeta =
      const VerificationMeta('lastAuditAt');
  @override
  late final GeneratedColumn<DateTime> lastAuditAt = GeneratedColumn<DateTime>(
      'last_audit_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        teamId,
        name,
        description,
        githubConnectionId,
        repoUrl,
        repoFullName,
        defaultBranch,
        jiraConnectionId,
        jiraProjectKey,
        techStack,
        healthScore,
        lastAuditAt,
        isArchived,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(_teamIdMeta,
          teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta));
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('github_connection_id')) {
      context.handle(
          _githubConnectionIdMeta,
          githubConnectionId.isAcceptableOrUnknown(
              data['github_connection_id']!, _githubConnectionIdMeta));
    }
    if (data.containsKey('repo_url')) {
      context.handle(_repoUrlMeta,
          repoUrl.isAcceptableOrUnknown(data['repo_url']!, _repoUrlMeta));
    }
    if (data.containsKey('repo_full_name')) {
      context.handle(
          _repoFullNameMeta,
          repoFullName.isAcceptableOrUnknown(
              data['repo_full_name']!, _repoFullNameMeta));
    }
    if (data.containsKey('default_branch')) {
      context.handle(
          _defaultBranchMeta,
          defaultBranch.isAcceptableOrUnknown(
              data['default_branch']!, _defaultBranchMeta));
    }
    if (data.containsKey('jira_connection_id')) {
      context.handle(
          _jiraConnectionIdMeta,
          jiraConnectionId.isAcceptableOrUnknown(
              data['jira_connection_id']!, _jiraConnectionIdMeta));
    }
    if (data.containsKey('jira_project_key')) {
      context.handle(
          _jiraProjectKeyMeta,
          jiraProjectKey.isAcceptableOrUnknown(
              data['jira_project_key']!, _jiraProjectKeyMeta));
    }
    if (data.containsKey('tech_stack')) {
      context.handle(_techStackMeta,
          techStack.isAcceptableOrUnknown(data['tech_stack']!, _techStackMeta));
    }
    if (data.containsKey('health_score')) {
      context.handle(
          _healthScoreMeta,
          healthScore.isAcceptableOrUnknown(
              data['health_score']!, _healthScoreMeta));
    }
    if (data.containsKey('last_audit_at')) {
      context.handle(
          _lastAuditAtMeta,
          lastAuditAt.isAcceptableOrUnknown(
              data['last_audit_at']!, _lastAuditAtMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      teamId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      githubConnectionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}github_connection_id']),
      repoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repo_url']),
      repoFullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repo_full_name']),
      defaultBranch: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_branch']),
      jiraConnectionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}jira_connection_id']),
      jiraProjectKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}jira_project_key']),
      techStack: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tech_stack']),
      healthScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}health_score']),
      lastAuditAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_audit_at']),
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  /// UUID primary key.
  final String id;

  /// Team UUID.
  final String teamId;

  /// Project name.
  final String name;

  /// Description.
  final String? description;

  /// GitHub connection UUID.
  final String? githubConnectionId;

  /// Repository clone URL.
  final String? repoUrl;

  /// Full repository name (owner/repo).
  final String? repoFullName;

  /// Default branch.
  final String? defaultBranch;

  /// Jira connection UUID.
  final String? jiraConnectionId;

  /// Jira project key.
  final String? jiraProjectKey;

  /// Tech stack description.
  final String? techStack;

  /// Health score (0-100).
  final int? healthScore;

  /// Last audit timestamp.
  final DateTime? lastAuditAt;

  /// Whether the project is archived.
  final bool isArchived;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;
  const Project(
      {required this.id,
      required this.teamId,
      required this.name,
      this.description,
      this.githubConnectionId,
      this.repoUrl,
      this.repoFullName,
      this.defaultBranch,
      this.jiraConnectionId,
      this.jiraProjectKey,
      this.techStack,
      this.healthScore,
      this.lastAuditAt,
      required this.isArchived,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_id'] = Variable<String>(teamId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || githubConnectionId != null) {
      map['github_connection_id'] = Variable<String>(githubConnectionId);
    }
    if (!nullToAbsent || repoUrl != null) {
      map['repo_url'] = Variable<String>(repoUrl);
    }
    if (!nullToAbsent || repoFullName != null) {
      map['repo_full_name'] = Variable<String>(repoFullName);
    }
    if (!nullToAbsent || defaultBranch != null) {
      map['default_branch'] = Variable<String>(defaultBranch);
    }
    if (!nullToAbsent || jiraConnectionId != null) {
      map['jira_connection_id'] = Variable<String>(jiraConnectionId);
    }
    if (!nullToAbsent || jiraProjectKey != null) {
      map['jira_project_key'] = Variable<String>(jiraProjectKey);
    }
    if (!nullToAbsent || techStack != null) {
      map['tech_stack'] = Variable<String>(techStack);
    }
    if (!nullToAbsent || healthScore != null) {
      map['health_score'] = Variable<int>(healthScore);
    }
    if (!nullToAbsent || lastAuditAt != null) {
      map['last_audit_at'] = Variable<DateTime>(lastAuditAt);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      teamId: Value(teamId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      githubConnectionId: githubConnectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(githubConnectionId),
      repoUrl: repoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(repoUrl),
      repoFullName: repoFullName == null && nullToAbsent
          ? const Value.absent()
          : Value(repoFullName),
      defaultBranch: defaultBranch == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultBranch),
      jiraConnectionId: jiraConnectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraConnectionId),
      jiraProjectKey: jiraProjectKey == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraProjectKey),
      techStack: techStack == null && nullToAbsent
          ? const Value.absent()
          : Value(techStack),
      healthScore: healthScore == null && nullToAbsent
          ? const Value.absent()
          : Value(healthScore),
      lastAuditAt: lastAuditAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAuditAt),
      isArchived: Value(isArchived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      teamId: serializer.fromJson<String>(json['teamId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      githubConnectionId:
          serializer.fromJson<String?>(json['githubConnectionId']),
      repoUrl: serializer.fromJson<String?>(json['repoUrl']),
      repoFullName: serializer.fromJson<String?>(json['repoFullName']),
      defaultBranch: serializer.fromJson<String?>(json['defaultBranch']),
      jiraConnectionId: serializer.fromJson<String?>(json['jiraConnectionId']),
      jiraProjectKey: serializer.fromJson<String?>(json['jiraProjectKey']),
      techStack: serializer.fromJson<String?>(json['techStack']),
      healthScore: serializer.fromJson<int?>(json['healthScore']),
      lastAuditAt: serializer.fromJson<DateTime?>(json['lastAuditAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teamId': serializer.toJson<String>(teamId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'githubConnectionId': serializer.toJson<String?>(githubConnectionId),
      'repoUrl': serializer.toJson<String?>(repoUrl),
      'repoFullName': serializer.toJson<String?>(repoFullName),
      'defaultBranch': serializer.toJson<String?>(defaultBranch),
      'jiraConnectionId': serializer.toJson<String?>(jiraConnectionId),
      'jiraProjectKey': serializer.toJson<String?>(jiraProjectKey),
      'techStack': serializer.toJson<String?>(techStack),
      'healthScore': serializer.toJson<int?>(healthScore),
      'lastAuditAt': serializer.toJson<DateTime?>(lastAuditAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Project copyWith(
          {String? id,
          String? teamId,
          String? name,
          Value<String?> description = const Value.absent(),
          Value<String?> githubConnectionId = const Value.absent(),
          Value<String?> repoUrl = const Value.absent(),
          Value<String?> repoFullName = const Value.absent(),
          Value<String?> defaultBranch = const Value.absent(),
          Value<String?> jiraConnectionId = const Value.absent(),
          Value<String?> jiraProjectKey = const Value.absent(),
          Value<String?> techStack = const Value.absent(),
          Value<int?> healthScore = const Value.absent(),
          Value<DateTime?> lastAuditAt = const Value.absent(),
          bool? isArchived,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Project(
        id: id ?? this.id,
        teamId: teamId ?? this.teamId,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        githubConnectionId: githubConnectionId.present
            ? githubConnectionId.value
            : this.githubConnectionId,
        repoUrl: repoUrl.present ? repoUrl.value : this.repoUrl,
        repoFullName:
            repoFullName.present ? repoFullName.value : this.repoFullName,
        defaultBranch:
            defaultBranch.present ? defaultBranch.value : this.defaultBranch,
        jiraConnectionId: jiraConnectionId.present
            ? jiraConnectionId.value
            : this.jiraConnectionId,
        jiraProjectKey:
            jiraProjectKey.present ? jiraProjectKey.value : this.jiraProjectKey,
        techStack: techStack.present ? techStack.value : this.techStack,
        healthScore: healthScore.present ? healthScore.value : this.healthScore,
        lastAuditAt: lastAuditAt.present ? lastAuditAt.value : this.lastAuditAt,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      githubConnectionId: data.githubConnectionId.present
          ? data.githubConnectionId.value
          : this.githubConnectionId,
      repoUrl: data.repoUrl.present ? data.repoUrl.value : this.repoUrl,
      repoFullName: data.repoFullName.present
          ? data.repoFullName.value
          : this.repoFullName,
      defaultBranch: data.defaultBranch.present
          ? data.defaultBranch.value
          : this.defaultBranch,
      jiraConnectionId: data.jiraConnectionId.present
          ? data.jiraConnectionId.value
          : this.jiraConnectionId,
      jiraProjectKey: data.jiraProjectKey.present
          ? data.jiraProjectKey.value
          : this.jiraProjectKey,
      techStack: data.techStack.present ? data.techStack.value : this.techStack,
      healthScore:
          data.healthScore.present ? data.healthScore.value : this.healthScore,
      lastAuditAt:
          data.lastAuditAt.present ? data.lastAuditAt.value : this.lastAuditAt,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('githubConnectionId: $githubConnectionId, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('repoFullName: $repoFullName, ')
          ..write('defaultBranch: $defaultBranch, ')
          ..write('jiraConnectionId: $jiraConnectionId, ')
          ..write('jiraProjectKey: $jiraProjectKey, ')
          ..write('techStack: $techStack, ')
          ..write('healthScore: $healthScore, ')
          ..write('lastAuditAt: $lastAuditAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      teamId,
      name,
      description,
      githubConnectionId,
      repoUrl,
      repoFullName,
      defaultBranch,
      jiraConnectionId,
      jiraProjectKey,
      techStack,
      healthScore,
      lastAuditAt,
      isArchived,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.name == this.name &&
          other.description == this.description &&
          other.githubConnectionId == this.githubConnectionId &&
          other.repoUrl == this.repoUrl &&
          other.repoFullName == this.repoFullName &&
          other.defaultBranch == this.defaultBranch &&
          other.jiraConnectionId == this.jiraConnectionId &&
          other.jiraProjectKey == this.jiraProjectKey &&
          other.techStack == this.techStack &&
          other.healthScore == this.healthScore &&
          other.lastAuditAt == this.lastAuditAt &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> teamId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> githubConnectionId;
  final Value<String?> repoUrl;
  final Value<String?> repoFullName;
  final Value<String?> defaultBranch;
  final Value<String?> jiraConnectionId;
  final Value<String?> jiraProjectKey;
  final Value<String?> techStack;
  final Value<int?> healthScore;
  final Value<DateTime?> lastAuditAt;
  final Value<bool> isArchived;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.githubConnectionId = const Value.absent(),
    this.repoUrl = const Value.absent(),
    this.repoFullName = const Value.absent(),
    this.defaultBranch = const Value.absent(),
    this.jiraConnectionId = const Value.absent(),
    this.jiraProjectKey = const Value.absent(),
    this.techStack = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.lastAuditAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String teamId,
    required String name,
    this.description = const Value.absent(),
    this.githubConnectionId = const Value.absent(),
    this.repoUrl = const Value.absent(),
    this.repoFullName = const Value.absent(),
    this.defaultBranch = const Value.absent(),
    this.jiraConnectionId = const Value.absent(),
    this.jiraProjectKey = const Value.absent(),
    this.techStack = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.lastAuditAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        teamId = Value(teamId),
        name = Value(name);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? teamId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? githubConnectionId,
    Expression<String>? repoUrl,
    Expression<String>? repoFullName,
    Expression<String>? defaultBranch,
    Expression<String>? jiraConnectionId,
    Expression<String>? jiraProjectKey,
    Expression<String>? techStack,
    Expression<int>? healthScore,
    Expression<DateTime>? lastAuditAt,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (githubConnectionId != null)
        'github_connection_id': githubConnectionId,
      if (repoUrl != null) 'repo_url': repoUrl,
      if (repoFullName != null) 'repo_full_name': repoFullName,
      if (defaultBranch != null) 'default_branch': defaultBranch,
      if (jiraConnectionId != null) 'jira_connection_id': jiraConnectionId,
      if (jiraProjectKey != null) 'jira_project_key': jiraProjectKey,
      if (techStack != null) 'tech_stack': techStack,
      if (healthScore != null) 'health_score': healthScore,
      if (lastAuditAt != null) 'last_audit_at': lastAuditAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? teamId,
      Value<String>? name,
      Value<String?>? description,
      Value<String?>? githubConnectionId,
      Value<String?>? repoUrl,
      Value<String?>? repoFullName,
      Value<String?>? defaultBranch,
      Value<String?>? jiraConnectionId,
      Value<String?>? jiraProjectKey,
      Value<String?>? techStack,
      Value<int?>? healthScore,
      Value<DateTime?>? lastAuditAt,
      Value<bool>? isArchived,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      description: description ?? this.description,
      githubConnectionId: githubConnectionId ?? this.githubConnectionId,
      repoUrl: repoUrl ?? this.repoUrl,
      repoFullName: repoFullName ?? this.repoFullName,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      jiraConnectionId: jiraConnectionId ?? this.jiraConnectionId,
      jiraProjectKey: jiraProjectKey ?? this.jiraProjectKey,
      techStack: techStack ?? this.techStack,
      healthScore: healthScore ?? this.healthScore,
      lastAuditAt: lastAuditAt ?? this.lastAuditAt,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (githubConnectionId.present) {
      map['github_connection_id'] = Variable<String>(githubConnectionId.value);
    }
    if (repoUrl.present) {
      map['repo_url'] = Variable<String>(repoUrl.value);
    }
    if (repoFullName.present) {
      map['repo_full_name'] = Variable<String>(repoFullName.value);
    }
    if (defaultBranch.present) {
      map['default_branch'] = Variable<String>(defaultBranch.value);
    }
    if (jiraConnectionId.present) {
      map['jira_connection_id'] = Variable<String>(jiraConnectionId.value);
    }
    if (jiraProjectKey.present) {
      map['jira_project_key'] = Variable<String>(jiraProjectKey.value);
    }
    if (techStack.present) {
      map['tech_stack'] = Variable<String>(techStack.value);
    }
    if (healthScore.present) {
      map['health_score'] = Variable<int>(healthScore.value);
    }
    if (lastAuditAt.present) {
      map['last_audit_at'] = Variable<DateTime>(lastAuditAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('githubConnectionId: $githubConnectionId, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('repoFullName: $repoFullName, ')
          ..write('defaultBranch: $defaultBranch, ')
          ..write('jiraConnectionId: $jiraConnectionId, ')
          ..write('jiraProjectKey: $jiraProjectKey, ')
          ..write('techStack: $techStack, ')
          ..write('healthScore: $healthScore, ')
          ..write('lastAuditAt: $lastAuditAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QaJobsTable extends QaJobs with TableInfo<$QaJobsTable, QaJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QaJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectNameMeta =
      const VerificationMeta('projectName');
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
      'project_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
      'branch', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _configJsonMeta =
      const VerificationMeta('configJson');
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
      'config_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _summaryMdMeta =
      const VerificationMeta('summaryMd');
  @override
  late final GeneratedColumn<String> summaryMd = GeneratedColumn<String>(
      'summary_md', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _overallResultMeta =
      const VerificationMeta('overallResult');
  @override
  late final GeneratedColumn<String> overallResult = GeneratedColumn<String>(
      'overall_result', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _healthScoreMeta =
      const VerificationMeta('healthScore');
  @override
  late final GeneratedColumn<int> healthScore = GeneratedColumn<int>(
      'health_score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalFindingsMeta =
      const VerificationMeta('totalFindings');
  @override
  late final GeneratedColumn<int> totalFindings = GeneratedColumn<int>(
      'total_findings', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _criticalCountMeta =
      const VerificationMeta('criticalCount');
  @override
  late final GeneratedColumn<int> criticalCount = GeneratedColumn<int>(
      'critical_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _highCountMeta =
      const VerificationMeta('highCount');
  @override
  late final GeneratedColumn<int> highCount = GeneratedColumn<int>(
      'high_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _mediumCountMeta =
      const VerificationMeta('mediumCount');
  @override
  late final GeneratedColumn<int> mediumCount = GeneratedColumn<int>(
      'medium_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lowCountMeta =
      const VerificationMeta('lowCount');
  @override
  late final GeneratedColumn<int> lowCount = GeneratedColumn<int>(
      'low_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _jiraTicketKeyMeta =
      const VerificationMeta('jiraTicketKey');
  @override
  late final GeneratedColumn<String> jiraTicketKey = GeneratedColumn<String>(
      'jira_ticket_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedByMeta =
      const VerificationMeta('startedBy');
  @override
  late final GeneratedColumn<String> startedBy = GeneratedColumn<String>(
      'started_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedByNameMeta =
      const VerificationMeta('startedByName');
  @override
  late final GeneratedColumn<String> startedByName = GeneratedColumn<String>(
      'started_by_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        projectName,
        mode,
        status,
        name,
        branch,
        configJson,
        summaryMd,
        overallResult,
        healthScore,
        totalFindings,
        criticalCount,
        highCount,
        mediumCount,
        lowCount,
        jiraTicketKey,
        startedBy,
        startedByName,
        startedAt,
        completedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'qa_jobs';
  @override
  VerificationContext validateIntegrity(Insertable<QaJob> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('project_name')) {
      context.handle(
          _projectNameMeta,
          projectName.isAcceptableOrUnknown(
              data['project_name']!, _projectNameMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('branch')) {
      context.handle(_branchMeta,
          branch.isAcceptableOrUnknown(data['branch']!, _branchMeta));
    }
    if (data.containsKey('config_json')) {
      context.handle(
          _configJsonMeta,
          configJson.isAcceptableOrUnknown(
              data['config_json']!, _configJsonMeta));
    }
    if (data.containsKey('summary_md')) {
      context.handle(_summaryMdMeta,
          summaryMd.isAcceptableOrUnknown(data['summary_md']!, _summaryMdMeta));
    }
    if (data.containsKey('overall_result')) {
      context.handle(
          _overallResultMeta,
          overallResult.isAcceptableOrUnknown(
              data['overall_result']!, _overallResultMeta));
    }
    if (data.containsKey('health_score')) {
      context.handle(
          _healthScoreMeta,
          healthScore.isAcceptableOrUnknown(
              data['health_score']!, _healthScoreMeta));
    }
    if (data.containsKey('total_findings')) {
      context.handle(
          _totalFindingsMeta,
          totalFindings.isAcceptableOrUnknown(
              data['total_findings']!, _totalFindingsMeta));
    }
    if (data.containsKey('critical_count')) {
      context.handle(
          _criticalCountMeta,
          criticalCount.isAcceptableOrUnknown(
              data['critical_count']!, _criticalCountMeta));
    }
    if (data.containsKey('high_count')) {
      context.handle(_highCountMeta,
          highCount.isAcceptableOrUnknown(data['high_count']!, _highCountMeta));
    }
    if (data.containsKey('medium_count')) {
      context.handle(
          _mediumCountMeta,
          mediumCount.isAcceptableOrUnknown(
              data['medium_count']!, _mediumCountMeta));
    }
    if (data.containsKey('low_count')) {
      context.handle(_lowCountMeta,
          lowCount.isAcceptableOrUnknown(data['low_count']!, _lowCountMeta));
    }
    if (data.containsKey('jira_ticket_key')) {
      context.handle(
          _jiraTicketKeyMeta,
          jiraTicketKey.isAcceptableOrUnknown(
              data['jira_ticket_key']!, _jiraTicketKeyMeta));
    }
    if (data.containsKey('started_by')) {
      context.handle(_startedByMeta,
          startedBy.isAcceptableOrUnknown(data['started_by']!, _startedByMeta));
    }
    if (data.containsKey('started_by_name')) {
      context.handle(
          _startedByNameMeta,
          startedByName.isAcceptableOrUnknown(
              data['started_by_name']!, _startedByNameMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QaJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QaJob(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      projectName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_name']),
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      branch: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch']),
      configJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_json']),
      summaryMd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary_md']),
      overallResult: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overall_result']),
      healthScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}health_score']),
      totalFindings: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_findings']),
      criticalCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}critical_count']),
      highCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}high_count']),
      mediumCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}medium_count']),
      lowCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}low_count']),
      jiraTicketKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jira_ticket_key']),
      startedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}started_by']),
      startedByName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}started_by_name']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $QaJobsTable createAlias(String alias) {
    return $QaJobsTable(attachedDatabase, alias);
  }
}

class QaJob extends DataClass implements Insertable<QaJob> {
  /// UUID primary key.
  final String id;

  /// Project UUID.
  final String projectId;

  /// Project name.
  final String? projectName;

  /// Job mode (SCREAMING_SNAKE_CASE).
  final String mode;

  /// Job status (SCREAMING_SNAKE_CASE).
  final String status;

  /// Job name.
  final String? name;

  /// Branch being analyzed.
  final String? branch;

  /// Job configuration JSON.
  final String? configJson;

  /// Markdown summary.
  final String? summaryMd;

  /// Overall result (SCREAMING_SNAKE_CASE).
  final String? overallResult;

  /// Health score.
  final int? healthScore;

  /// Total findings count.
  final int? totalFindings;

  /// Critical findings count.
  final int? criticalCount;

  /// High findings count.
  final int? highCount;

  /// Medium findings count.
  final int? mediumCount;

  /// Low findings count.
  final int? lowCount;

  /// Jira ticket key.
  final String? jiraTicketKey;

  /// Starter user UUID.
  final String? startedBy;

  /// Starter display name.
  final String? startedByName;

  /// Start timestamp.
  final DateTime? startedAt;

  /// Completion timestamp.
  final DateTime? completedAt;

  /// Creation timestamp.
  final DateTime? createdAt;
  const QaJob(
      {required this.id,
      required this.projectId,
      this.projectName,
      required this.mode,
      required this.status,
      this.name,
      this.branch,
      this.configJson,
      this.summaryMd,
      this.overallResult,
      this.healthScore,
      this.totalFindings,
      this.criticalCount,
      this.highCount,
      this.mediumCount,
      this.lowCount,
      this.jiraTicketKey,
      this.startedBy,
      this.startedByName,
      this.startedAt,
      this.completedAt,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || branch != null) {
      map['branch'] = Variable<String>(branch);
    }
    if (!nullToAbsent || configJson != null) {
      map['config_json'] = Variable<String>(configJson);
    }
    if (!nullToAbsent || summaryMd != null) {
      map['summary_md'] = Variable<String>(summaryMd);
    }
    if (!nullToAbsent || overallResult != null) {
      map['overall_result'] = Variable<String>(overallResult);
    }
    if (!nullToAbsent || healthScore != null) {
      map['health_score'] = Variable<int>(healthScore);
    }
    if (!nullToAbsent || totalFindings != null) {
      map['total_findings'] = Variable<int>(totalFindings);
    }
    if (!nullToAbsent || criticalCount != null) {
      map['critical_count'] = Variable<int>(criticalCount);
    }
    if (!nullToAbsent || highCount != null) {
      map['high_count'] = Variable<int>(highCount);
    }
    if (!nullToAbsent || mediumCount != null) {
      map['medium_count'] = Variable<int>(mediumCount);
    }
    if (!nullToAbsent || lowCount != null) {
      map['low_count'] = Variable<int>(lowCount);
    }
    if (!nullToAbsent || jiraTicketKey != null) {
      map['jira_ticket_key'] = Variable<String>(jiraTicketKey);
    }
    if (!nullToAbsent || startedBy != null) {
      map['started_by'] = Variable<String>(startedBy);
    }
    if (!nullToAbsent || startedByName != null) {
      map['started_by_name'] = Variable<String>(startedByName);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  QaJobsCompanion toCompanion(bool nullToAbsent) {
    return QaJobsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      mode: Value(mode),
      status: Value(status),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      branch:
          branch == null && nullToAbsent ? const Value.absent() : Value(branch),
      configJson: configJson == null && nullToAbsent
          ? const Value.absent()
          : Value(configJson),
      summaryMd: summaryMd == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryMd),
      overallResult: overallResult == null && nullToAbsent
          ? const Value.absent()
          : Value(overallResult),
      healthScore: healthScore == null && nullToAbsent
          ? const Value.absent()
          : Value(healthScore),
      totalFindings: totalFindings == null && nullToAbsent
          ? const Value.absent()
          : Value(totalFindings),
      criticalCount: criticalCount == null && nullToAbsent
          ? const Value.absent()
          : Value(criticalCount),
      highCount: highCount == null && nullToAbsent
          ? const Value.absent()
          : Value(highCount),
      mediumCount: mediumCount == null && nullToAbsent
          ? const Value.absent()
          : Value(mediumCount),
      lowCount: lowCount == null && nullToAbsent
          ? const Value.absent()
          : Value(lowCount),
      jiraTicketKey: jiraTicketKey == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraTicketKey),
      startedBy: startedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(startedBy),
      startedByName: startedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(startedByName),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory QaJob.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QaJob(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      name: serializer.fromJson<String?>(json['name']),
      branch: serializer.fromJson<String?>(json['branch']),
      configJson: serializer.fromJson<String?>(json['configJson']),
      summaryMd: serializer.fromJson<String?>(json['summaryMd']),
      overallResult: serializer.fromJson<String?>(json['overallResult']),
      healthScore: serializer.fromJson<int?>(json['healthScore']),
      totalFindings: serializer.fromJson<int?>(json['totalFindings']),
      criticalCount: serializer.fromJson<int?>(json['criticalCount']),
      highCount: serializer.fromJson<int?>(json['highCount']),
      mediumCount: serializer.fromJson<int?>(json['mediumCount']),
      lowCount: serializer.fromJson<int?>(json['lowCount']),
      jiraTicketKey: serializer.fromJson<String?>(json['jiraTicketKey']),
      startedBy: serializer.fromJson<String?>(json['startedBy']),
      startedByName: serializer.fromJson<String?>(json['startedByName']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'projectName': serializer.toJson<String?>(projectName),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'name': serializer.toJson<String?>(name),
      'branch': serializer.toJson<String?>(branch),
      'configJson': serializer.toJson<String?>(configJson),
      'summaryMd': serializer.toJson<String?>(summaryMd),
      'overallResult': serializer.toJson<String?>(overallResult),
      'healthScore': serializer.toJson<int?>(healthScore),
      'totalFindings': serializer.toJson<int?>(totalFindings),
      'criticalCount': serializer.toJson<int?>(criticalCount),
      'highCount': serializer.toJson<int?>(highCount),
      'mediumCount': serializer.toJson<int?>(mediumCount),
      'lowCount': serializer.toJson<int?>(lowCount),
      'jiraTicketKey': serializer.toJson<String?>(jiraTicketKey),
      'startedBy': serializer.toJson<String?>(startedBy),
      'startedByName': serializer.toJson<String?>(startedByName),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  QaJob copyWith(
          {String? id,
          String? projectId,
          Value<String?> projectName = const Value.absent(),
          String? mode,
          String? status,
          Value<String?> name = const Value.absent(),
          Value<String?> branch = const Value.absent(),
          Value<String?> configJson = const Value.absent(),
          Value<String?> summaryMd = const Value.absent(),
          Value<String?> overallResult = const Value.absent(),
          Value<int?> healthScore = const Value.absent(),
          Value<int?> totalFindings = const Value.absent(),
          Value<int?> criticalCount = const Value.absent(),
          Value<int?> highCount = const Value.absent(),
          Value<int?> mediumCount = const Value.absent(),
          Value<int?> lowCount = const Value.absent(),
          Value<String?> jiraTicketKey = const Value.absent(),
          Value<String?> startedBy = const Value.absent(),
          Value<String?> startedByName = const Value.absent(),
          Value<DateTime?> startedAt = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      QaJob(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        projectName: projectName.present ? projectName.value : this.projectName,
        mode: mode ?? this.mode,
        status: status ?? this.status,
        name: name.present ? name.value : this.name,
        branch: branch.present ? branch.value : this.branch,
        configJson: configJson.present ? configJson.value : this.configJson,
        summaryMd: summaryMd.present ? summaryMd.value : this.summaryMd,
        overallResult:
            overallResult.present ? overallResult.value : this.overallResult,
        healthScore: healthScore.present ? healthScore.value : this.healthScore,
        totalFindings:
            totalFindings.present ? totalFindings.value : this.totalFindings,
        criticalCount:
            criticalCount.present ? criticalCount.value : this.criticalCount,
        highCount: highCount.present ? highCount.value : this.highCount,
        mediumCount: mediumCount.present ? mediumCount.value : this.mediumCount,
        lowCount: lowCount.present ? lowCount.value : this.lowCount,
        jiraTicketKey:
            jiraTicketKey.present ? jiraTicketKey.value : this.jiraTicketKey,
        startedBy: startedBy.present ? startedBy.value : this.startedBy,
        startedByName:
            startedByName.present ? startedByName.value : this.startedByName,
        startedAt: startedAt.present ? startedAt.value : this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  QaJob copyWithCompanion(QaJobsCompanion data) {
    return QaJob(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName:
          data.projectName.present ? data.projectName.value : this.projectName,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      name: data.name.present ? data.name.value : this.name,
      branch: data.branch.present ? data.branch.value : this.branch,
      configJson:
          data.configJson.present ? data.configJson.value : this.configJson,
      summaryMd: data.summaryMd.present ? data.summaryMd.value : this.summaryMd,
      overallResult: data.overallResult.present
          ? data.overallResult.value
          : this.overallResult,
      healthScore:
          data.healthScore.present ? data.healthScore.value : this.healthScore,
      totalFindings: data.totalFindings.present
          ? data.totalFindings.value
          : this.totalFindings,
      criticalCount: data.criticalCount.present
          ? data.criticalCount.value
          : this.criticalCount,
      highCount: data.highCount.present ? data.highCount.value : this.highCount,
      mediumCount:
          data.mediumCount.present ? data.mediumCount.value : this.mediumCount,
      lowCount: data.lowCount.present ? data.lowCount.value : this.lowCount,
      jiraTicketKey: data.jiraTicketKey.present
          ? data.jiraTicketKey.value
          : this.jiraTicketKey,
      startedBy: data.startedBy.present ? data.startedBy.value : this.startedBy,
      startedByName: data.startedByName.present
          ? data.startedByName.value
          : this.startedByName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QaJob(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('name: $name, ')
          ..write('branch: $branch, ')
          ..write('configJson: $configJson, ')
          ..write('summaryMd: $summaryMd, ')
          ..write('overallResult: $overallResult, ')
          ..write('healthScore: $healthScore, ')
          ..write('totalFindings: $totalFindings, ')
          ..write('criticalCount: $criticalCount, ')
          ..write('highCount: $highCount, ')
          ..write('mediumCount: $mediumCount, ')
          ..write('lowCount: $lowCount, ')
          ..write('jiraTicketKey: $jiraTicketKey, ')
          ..write('startedBy: $startedBy, ')
          ..write('startedByName: $startedByName, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        projectId,
        projectName,
        mode,
        status,
        name,
        branch,
        configJson,
        summaryMd,
        overallResult,
        healthScore,
        totalFindings,
        criticalCount,
        highCount,
        mediumCount,
        lowCount,
        jiraTicketKey,
        startedBy,
        startedByName,
        startedAt,
        completedAt,
        createdAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QaJob &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.name == this.name &&
          other.branch == this.branch &&
          other.configJson == this.configJson &&
          other.summaryMd == this.summaryMd &&
          other.overallResult == this.overallResult &&
          other.healthScore == this.healthScore &&
          other.totalFindings == this.totalFindings &&
          other.criticalCount == this.criticalCount &&
          other.highCount == this.highCount &&
          other.mediumCount == this.mediumCount &&
          other.lowCount == this.lowCount &&
          other.jiraTicketKey == this.jiraTicketKey &&
          other.startedBy == this.startedBy &&
          other.startedByName == this.startedByName &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt);
}

class QaJobsCompanion extends UpdateCompanion<QaJob> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String?> projectName;
  final Value<String> mode;
  final Value<String> status;
  final Value<String?> name;
  final Value<String?> branch;
  final Value<String?> configJson;
  final Value<String?> summaryMd;
  final Value<String?> overallResult;
  final Value<int?> healthScore;
  final Value<int?> totalFindings;
  final Value<int?> criticalCount;
  final Value<int?> highCount;
  final Value<int?> mediumCount;
  final Value<int?> lowCount;
  final Value<String?> jiraTicketKey;
  final Value<String?> startedBy;
  final Value<String?> startedByName;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const QaJobsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.name = const Value.absent(),
    this.branch = const Value.absent(),
    this.configJson = const Value.absent(),
    this.summaryMd = const Value.absent(),
    this.overallResult = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.totalFindings = const Value.absent(),
    this.criticalCount = const Value.absent(),
    this.highCount = const Value.absent(),
    this.mediumCount = const Value.absent(),
    this.lowCount = const Value.absent(),
    this.jiraTicketKey = const Value.absent(),
    this.startedBy = const Value.absent(),
    this.startedByName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QaJobsCompanion.insert({
    required String id,
    required String projectId,
    this.projectName = const Value.absent(),
    required String mode,
    required String status,
    this.name = const Value.absent(),
    this.branch = const Value.absent(),
    this.configJson = const Value.absent(),
    this.summaryMd = const Value.absent(),
    this.overallResult = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.totalFindings = const Value.absent(),
    this.criticalCount = const Value.absent(),
    this.highCount = const Value.absent(),
    this.mediumCount = const Value.absent(),
    this.lowCount = const Value.absent(),
    this.jiraTicketKey = const Value.absent(),
    this.startedBy = const Value.absent(),
    this.startedByName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        mode = Value(mode),
        status = Value(status);
  static Insertable<QaJob> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<String>? name,
    Expression<String>? branch,
    Expression<String>? configJson,
    Expression<String>? summaryMd,
    Expression<String>? overallResult,
    Expression<int>? healthScore,
    Expression<int>? totalFindings,
    Expression<int>? criticalCount,
    Expression<int>? highCount,
    Expression<int>? mediumCount,
    Expression<int>? lowCount,
    Expression<String>? jiraTicketKey,
    Expression<String>? startedBy,
    Expression<String>? startedByName,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (name != null) 'name': name,
      if (branch != null) 'branch': branch,
      if (configJson != null) 'config_json': configJson,
      if (summaryMd != null) 'summary_md': summaryMd,
      if (overallResult != null) 'overall_result': overallResult,
      if (healthScore != null) 'health_score': healthScore,
      if (totalFindings != null) 'total_findings': totalFindings,
      if (criticalCount != null) 'critical_count': criticalCount,
      if (highCount != null) 'high_count': highCount,
      if (mediumCount != null) 'medium_count': mediumCount,
      if (lowCount != null) 'low_count': lowCount,
      if (jiraTicketKey != null) 'jira_ticket_key': jiraTicketKey,
      if (startedBy != null) 'started_by': startedBy,
      if (startedByName != null) 'started_by_name': startedByName,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QaJobsCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String?>? projectName,
      Value<String>? mode,
      Value<String>? status,
      Value<String?>? name,
      Value<String?>? branch,
      Value<String?>? configJson,
      Value<String?>? summaryMd,
      Value<String?>? overallResult,
      Value<int?>? healthScore,
      Value<int?>? totalFindings,
      Value<int?>? criticalCount,
      Value<int?>? highCount,
      Value<int?>? mediumCount,
      Value<int?>? lowCount,
      Value<String?>? jiraTicketKey,
      Value<String?>? startedBy,
      Value<String?>? startedByName,
      Value<DateTime?>? startedAt,
      Value<DateTime?>? completedAt,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return QaJobsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      name: name ?? this.name,
      branch: branch ?? this.branch,
      configJson: configJson ?? this.configJson,
      summaryMd: summaryMd ?? this.summaryMd,
      overallResult: overallResult ?? this.overallResult,
      healthScore: healthScore ?? this.healthScore,
      totalFindings: totalFindings ?? this.totalFindings,
      criticalCount: criticalCount ?? this.criticalCount,
      highCount: highCount ?? this.highCount,
      mediumCount: mediumCount ?? this.mediumCount,
      lowCount: lowCount ?? this.lowCount,
      jiraTicketKey: jiraTicketKey ?? this.jiraTicketKey,
      startedBy: startedBy ?? this.startedBy,
      startedByName: startedByName ?? this.startedByName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (summaryMd.present) {
      map['summary_md'] = Variable<String>(summaryMd.value);
    }
    if (overallResult.present) {
      map['overall_result'] = Variable<String>(overallResult.value);
    }
    if (healthScore.present) {
      map['health_score'] = Variable<int>(healthScore.value);
    }
    if (totalFindings.present) {
      map['total_findings'] = Variable<int>(totalFindings.value);
    }
    if (criticalCount.present) {
      map['critical_count'] = Variable<int>(criticalCount.value);
    }
    if (highCount.present) {
      map['high_count'] = Variable<int>(highCount.value);
    }
    if (mediumCount.present) {
      map['medium_count'] = Variable<int>(mediumCount.value);
    }
    if (lowCount.present) {
      map['low_count'] = Variable<int>(lowCount.value);
    }
    if (jiraTicketKey.present) {
      map['jira_ticket_key'] = Variable<String>(jiraTicketKey.value);
    }
    if (startedBy.present) {
      map['started_by'] = Variable<String>(startedBy.value);
    }
    if (startedByName.present) {
      map['started_by_name'] = Variable<String>(startedByName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QaJobsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('name: $name, ')
          ..write('branch: $branch, ')
          ..write('configJson: $configJson, ')
          ..write('summaryMd: $summaryMd, ')
          ..write('overallResult: $overallResult, ')
          ..write('healthScore: $healthScore, ')
          ..write('totalFindings: $totalFindings, ')
          ..write('criticalCount: $criticalCount, ')
          ..write('highCount: $highCount, ')
          ..write('mediumCount: $mediumCount, ')
          ..write('lowCount: $lowCount, ')
          ..write('jiraTicketKey: $jiraTicketKey, ')
          ..write('startedBy: $startedBy, ')
          ..write('startedByName: $startedByName, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentRunsTable extends AgentRuns
    with TableInfo<$AgentRunsTable, AgentRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentTypeMeta =
      const VerificationMeta('agentType');
  @override
  late final GeneratedColumn<String> agentType = GeneratedColumn<String>(
      'agent_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
      'result', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reportS3KeyMeta =
      const VerificationMeta('reportS3Key');
  @override
  late final GeneratedColumn<String> reportS3Key = GeneratedColumn<String>(
      'report_s3_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _findingsCountMeta =
      const VerificationMeta('findingsCount');
  @override
  late final GeneratedColumn<int> findingsCount = GeneratedColumn<int>(
      'findings_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _criticalCountMeta =
      const VerificationMeta('criticalCount');
  @override
  late final GeneratedColumn<int> criticalCount = GeneratedColumn<int>(
      'critical_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _highCountMeta =
      const VerificationMeta('highCount');
  @override
  late final GeneratedColumn<int> highCount = GeneratedColumn<int>(
      'high_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobId,
        agentType,
        status,
        result,
        reportS3Key,
        score,
        findingsCount,
        criticalCount,
        highCount,
        startedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_runs';
  @override
  VerificationContext validateIntegrity(Insertable<AgentRun> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('agent_type')) {
      context.handle(_agentTypeMeta,
          agentType.isAcceptableOrUnknown(data['agent_type']!, _agentTypeMeta));
    } else if (isInserting) {
      context.missing(_agentTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta,
          result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    }
    if (data.containsKey('report_s3_key')) {
      context.handle(
          _reportS3KeyMeta,
          reportS3Key.isAcceptableOrUnknown(
              data['report_s3_key']!, _reportS3KeyMeta));
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('findings_count')) {
      context.handle(
          _findingsCountMeta,
          findingsCount.isAcceptableOrUnknown(
              data['findings_count']!, _findingsCountMeta));
    }
    if (data.containsKey('critical_count')) {
      context.handle(
          _criticalCountMeta,
          criticalCount.isAcceptableOrUnknown(
              data['critical_count']!, _criticalCountMeta));
    }
    if (data.containsKey('high_count')) {
      context.handle(_highCountMeta,
          highCount.isAcceptableOrUnknown(data['high_count']!, _highCountMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentRun(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      agentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      result: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result']),
      reportS3Key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}report_s3_key']),
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score']),
      findingsCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}findings_count']),
      criticalCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}critical_count']),
      highCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}high_count']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $AgentRunsTable createAlias(String alias) {
    return $AgentRunsTable(attachedDatabase, alias);
  }
}

class AgentRun extends DataClass implements Insertable<AgentRun> {
  /// UUID primary key.
  final String id;

  /// Parent job UUID.
  final String jobId;

  /// Agent type (SCREAMING_SNAKE_CASE).
  final String agentType;

  /// Agent status (SCREAMING_SNAKE_CASE).
  final String status;

  /// Agent result (SCREAMING_SNAKE_CASE).
  final String? result;

  /// S3 key for the report.
  final String? reportS3Key;

  /// Score (0-100).
  final int? score;

  /// Findings count.
  final int? findingsCount;

  /// Critical findings count.
  final int? criticalCount;

  /// High findings count.
  final int? highCount;

  /// Start timestamp.
  final DateTime? startedAt;

  /// Completion timestamp.
  final DateTime? completedAt;
  const AgentRun(
      {required this.id,
      required this.jobId,
      required this.agentType,
      required this.status,
      this.result,
      this.reportS3Key,
      this.score,
      this.findingsCount,
      this.criticalCount,
      this.highCount,
      this.startedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['agent_type'] = Variable<String>(agentType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(result);
    }
    if (!nullToAbsent || reportS3Key != null) {
      map['report_s3_key'] = Variable<String>(reportS3Key);
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || findingsCount != null) {
      map['findings_count'] = Variable<int>(findingsCount);
    }
    if (!nullToAbsent || criticalCount != null) {
      map['critical_count'] = Variable<int>(criticalCount);
    }
    if (!nullToAbsent || highCount != null) {
      map['high_count'] = Variable<int>(highCount);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  AgentRunsCompanion toCompanion(bool nullToAbsent) {
    return AgentRunsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      agentType: Value(agentType),
      status: Value(status),
      result:
          result == null && nullToAbsent ? const Value.absent() : Value(result),
      reportS3Key: reportS3Key == null && nullToAbsent
          ? const Value.absent()
          : Value(reportS3Key),
      score:
          score == null && nullToAbsent ? const Value.absent() : Value(score),
      findingsCount: findingsCount == null && nullToAbsent
          ? const Value.absent()
          : Value(findingsCount),
      criticalCount: criticalCount == null && nullToAbsent
          ? const Value.absent()
          : Value(criticalCount),
      highCount: highCount == null && nullToAbsent
          ? const Value.absent()
          : Value(highCount),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory AgentRun.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentRun(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      agentType: serializer.fromJson<String>(json['agentType']),
      status: serializer.fromJson<String>(json['status']),
      result: serializer.fromJson<String?>(json['result']),
      reportS3Key: serializer.fromJson<String?>(json['reportS3Key']),
      score: serializer.fromJson<int?>(json['score']),
      findingsCount: serializer.fromJson<int?>(json['findingsCount']),
      criticalCount: serializer.fromJson<int?>(json['criticalCount']),
      highCount: serializer.fromJson<int?>(json['highCount']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'agentType': serializer.toJson<String>(agentType),
      'status': serializer.toJson<String>(status),
      'result': serializer.toJson<String?>(result),
      'reportS3Key': serializer.toJson<String?>(reportS3Key),
      'score': serializer.toJson<int?>(score),
      'findingsCount': serializer.toJson<int?>(findingsCount),
      'criticalCount': serializer.toJson<int?>(criticalCount),
      'highCount': serializer.toJson<int?>(highCount),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  AgentRun copyWith(
          {String? id,
          String? jobId,
          String? agentType,
          String? status,
          Value<String?> result = const Value.absent(),
          Value<String?> reportS3Key = const Value.absent(),
          Value<int?> score = const Value.absent(),
          Value<int?> findingsCount = const Value.absent(),
          Value<int?> criticalCount = const Value.absent(),
          Value<int?> highCount = const Value.absent(),
          Value<DateTime?> startedAt = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent()}) =>
      AgentRun(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        agentType: agentType ?? this.agentType,
        status: status ?? this.status,
        result: result.present ? result.value : this.result,
        reportS3Key: reportS3Key.present ? reportS3Key.value : this.reportS3Key,
        score: score.present ? score.value : this.score,
        findingsCount:
            findingsCount.present ? findingsCount.value : this.findingsCount,
        criticalCount:
            criticalCount.present ? criticalCount.value : this.criticalCount,
        highCount: highCount.present ? highCount.value : this.highCount,
        startedAt: startedAt.present ? startedAt.value : this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  AgentRun copyWithCompanion(AgentRunsCompanion data) {
    return AgentRun(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      agentType: data.agentType.present ? data.agentType.value : this.agentType,
      status: data.status.present ? data.status.value : this.status,
      result: data.result.present ? data.result.value : this.result,
      reportS3Key:
          data.reportS3Key.present ? data.reportS3Key.value : this.reportS3Key,
      score: data.score.present ? data.score.value : this.score,
      findingsCount: data.findingsCount.present
          ? data.findingsCount.value
          : this.findingsCount,
      criticalCount: data.criticalCount.present
          ? data.criticalCount.value
          : this.criticalCount,
      highCount: data.highCount.present ? data.highCount.value : this.highCount,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentRun(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('agentType: $agentType, ')
          ..write('status: $status, ')
          ..write('result: $result, ')
          ..write('reportS3Key: $reportS3Key, ')
          ..write('score: $score, ')
          ..write('findingsCount: $findingsCount, ')
          ..write('criticalCount: $criticalCount, ')
          ..write('highCount: $highCount, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      jobId,
      agentType,
      status,
      result,
      reportS3Key,
      score,
      findingsCount,
      criticalCount,
      highCount,
      startedAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentRun &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.agentType == this.agentType &&
          other.status == this.status &&
          other.result == this.result &&
          other.reportS3Key == this.reportS3Key &&
          other.score == this.score &&
          other.findingsCount == this.findingsCount &&
          other.criticalCount == this.criticalCount &&
          other.highCount == this.highCount &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class AgentRunsCompanion extends UpdateCompanion<AgentRun> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<String> agentType;
  final Value<String> status;
  final Value<String?> result;
  final Value<String?> reportS3Key;
  final Value<int?> score;
  final Value<int?> findingsCount;
  final Value<int?> criticalCount;
  final Value<int?> highCount;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const AgentRunsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.agentType = const Value.absent(),
    this.status = const Value.absent(),
    this.result = const Value.absent(),
    this.reportS3Key = const Value.absent(),
    this.score = const Value.absent(),
    this.findingsCount = const Value.absent(),
    this.criticalCount = const Value.absent(),
    this.highCount = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentRunsCompanion.insert({
    required String id,
    required String jobId,
    required String agentType,
    required String status,
    this.result = const Value.absent(),
    this.reportS3Key = const Value.absent(),
    this.score = const Value.absent(),
    this.findingsCount = const Value.absent(),
    this.criticalCount = const Value.absent(),
    this.highCount = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        jobId = Value(jobId),
        agentType = Value(agentType),
        status = Value(status);
  static Insertable<AgentRun> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? agentType,
    Expression<String>? status,
    Expression<String>? result,
    Expression<String>? reportS3Key,
    Expression<int>? score,
    Expression<int>? findingsCount,
    Expression<int>? criticalCount,
    Expression<int>? highCount,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (agentType != null) 'agent_type': agentType,
      if (status != null) 'status': status,
      if (result != null) 'result': result,
      if (reportS3Key != null) 'report_s3_key': reportS3Key,
      if (score != null) 'score': score,
      if (findingsCount != null) 'findings_count': findingsCount,
      if (criticalCount != null) 'critical_count': criticalCount,
      if (highCount != null) 'high_count': highCount,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentRunsCompanion copyWith(
      {Value<String>? id,
      Value<String>? jobId,
      Value<String>? agentType,
      Value<String>? status,
      Value<String?>? result,
      Value<String?>? reportS3Key,
      Value<int?>? score,
      Value<int?>? findingsCount,
      Value<int?>? criticalCount,
      Value<int?>? highCount,
      Value<DateTime?>? startedAt,
      Value<DateTime?>? completedAt,
      Value<int>? rowid}) {
    return AgentRunsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      agentType: agentType ?? this.agentType,
      status: status ?? this.status,
      result: result ?? this.result,
      reportS3Key: reportS3Key ?? this.reportS3Key,
      score: score ?? this.score,
      findingsCount: findingsCount ?? this.findingsCount,
      criticalCount: criticalCount ?? this.criticalCount,
      highCount: highCount ?? this.highCount,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (agentType.present) {
      map['agent_type'] = Variable<String>(agentType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (reportS3Key.present) {
      map['report_s3_key'] = Variable<String>(reportS3Key.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (findingsCount.present) {
      map['findings_count'] = Variable<int>(findingsCount.value);
    }
    if (criticalCount.present) {
      map['critical_count'] = Variable<int>(criticalCount.value);
    }
    if (highCount.present) {
      map['high_count'] = Variable<int>(highCount.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentRunsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('agentType: $agentType, ')
          ..write('status: $status, ')
          ..write('result: $result, ')
          ..write('reportS3Key: $reportS3Key, ')
          ..write('score: $score, ')
          ..write('findingsCount: $findingsCount, ')
          ..write('criticalCount: $criticalCount, ')
          ..write('highCount: $highCount, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FindingsTable extends Findings with TableInfo<$FindingsTable, Finding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FindingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentTypeMeta =
      const VerificationMeta('agentType');
  @override
  late final GeneratedColumn<String> agentType = GeneratedColumn<String>(
      'agent_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lineNumberMeta =
      const VerificationMeta('lineNumber');
  @override
  late final GeneratedColumn<int> lineNumber = GeneratedColumn<int>(
      'line_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _recommendationMeta =
      const VerificationMeta('recommendation');
  @override
  late final GeneratedColumn<String> recommendation = GeneratedColumn<String>(
      'recommendation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _evidenceMeta =
      const VerificationMeta('evidence');
  @override
  late final GeneratedColumn<String> evidence = GeneratedColumn<String>(
      'evidence', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _effortEstimateMeta =
      const VerificationMeta('effortEstimate');
  @override
  late final GeneratedColumn<String> effortEstimate = GeneratedColumn<String>(
      'effort_estimate', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _debtCategoryMeta =
      const VerificationMeta('debtCategory');
  @override
  late final GeneratedColumn<String> debtCategory = GeneratedColumn<String>(
      'debt_category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _findingStatusMeta =
      const VerificationMeta('findingStatus');
  @override
  late final GeneratedColumn<String> findingStatus = GeneratedColumn<String>(
      'finding_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusChangedByMeta =
      const VerificationMeta('statusChangedBy');
  @override
  late final GeneratedColumn<String> statusChangedBy = GeneratedColumn<String>(
      'status_changed_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusChangedAtMeta =
      const VerificationMeta('statusChangedAt');
  @override
  late final GeneratedColumn<DateTime> statusChangedAt =
      GeneratedColumn<DateTime>('status_changed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobId,
        agentType,
        severity,
        title,
        description,
        filePath,
        lineNumber,
        recommendation,
        evidence,
        effortEstimate,
        debtCategory,
        findingStatus,
        statusChangedBy,
        statusChangedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'findings';
  @override
  VerificationContext validateIntegrity(Insertable<Finding> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('agent_type')) {
      context.handle(_agentTypeMeta,
          agentType.isAcceptableOrUnknown(data['agent_type']!, _agentTypeMeta));
    } else if (isInserting) {
      context.missing(_agentTypeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('line_number')) {
      context.handle(
          _lineNumberMeta,
          lineNumber.isAcceptableOrUnknown(
              data['line_number']!, _lineNumberMeta));
    }
    if (data.containsKey('recommendation')) {
      context.handle(
          _recommendationMeta,
          recommendation.isAcceptableOrUnknown(
              data['recommendation']!, _recommendationMeta));
    }
    if (data.containsKey('evidence')) {
      context.handle(_evidenceMeta,
          evidence.isAcceptableOrUnknown(data['evidence']!, _evidenceMeta));
    }
    if (data.containsKey('effort_estimate')) {
      context.handle(
          _effortEstimateMeta,
          effortEstimate.isAcceptableOrUnknown(
              data['effort_estimate']!, _effortEstimateMeta));
    }
    if (data.containsKey('debt_category')) {
      context.handle(
          _debtCategoryMeta,
          debtCategory.isAcceptableOrUnknown(
              data['debt_category']!, _debtCategoryMeta));
    }
    if (data.containsKey('finding_status')) {
      context.handle(
          _findingStatusMeta,
          findingStatus.isAcceptableOrUnknown(
              data['finding_status']!, _findingStatusMeta));
    } else if (isInserting) {
      context.missing(_findingStatusMeta);
    }
    if (data.containsKey('status_changed_by')) {
      context.handle(
          _statusChangedByMeta,
          statusChangedBy.isAcceptableOrUnknown(
              data['status_changed_by']!, _statusChangedByMeta));
    }
    if (data.containsKey('status_changed_at')) {
      context.handle(
          _statusChangedAtMeta,
          statusChangedAt.isAcceptableOrUnknown(
              data['status_changed_at']!, _statusChangedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Finding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Finding(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      agentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_type'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      lineNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_number']),
      recommendation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recommendation']),
      evidence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evidence']),
      effortEstimate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effort_estimate']),
      debtCategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}debt_category']),
      findingStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}finding_status'])!,
      statusChangedBy: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}status_changed_by']),
      statusChangedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}status_changed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $FindingsTable createAlias(String alias) {
    return $FindingsTable(attachedDatabase, alias);
  }
}

class Finding extends DataClass implements Insertable<Finding> {
  /// UUID primary key.
  final String id;

  /// Parent job UUID.
  final String jobId;

  /// Agent type (SCREAMING_SNAKE_CASE).
  final String agentType;

  /// Severity (SCREAMING_SNAKE_CASE).
  final String severity;

  /// Finding title.
  final String title;

  /// Description.
  final String? description;

  /// Source file path.
  final String? filePath;

  /// Line number.
  final int? lineNumber;

  /// Recommendation.
  final String? recommendation;

  /// Evidence.
  final String? evidence;

  /// Effort estimate (SCREAMING_SNAKE_CASE).
  final String? effortEstimate;

  /// Debt category (SCREAMING_SNAKE_CASE).
  final String? debtCategory;

  /// Finding status (SCREAMING_SNAKE_CASE).
  final String findingStatus;

  /// Status changer UUID.
  final String? statusChangedBy;

  /// Status change timestamp.
  final DateTime? statusChangedAt;

  /// Creation timestamp.
  final DateTime? createdAt;
  const Finding(
      {required this.id,
      required this.jobId,
      required this.agentType,
      required this.severity,
      required this.title,
      this.description,
      this.filePath,
      this.lineNumber,
      this.recommendation,
      this.evidence,
      this.effortEstimate,
      this.debtCategory,
      required this.findingStatus,
      this.statusChangedBy,
      this.statusChangedAt,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['agent_type'] = Variable<String>(agentType);
    map['severity'] = Variable<String>(severity);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || lineNumber != null) {
      map['line_number'] = Variable<int>(lineNumber);
    }
    if (!nullToAbsent || recommendation != null) {
      map['recommendation'] = Variable<String>(recommendation);
    }
    if (!nullToAbsent || evidence != null) {
      map['evidence'] = Variable<String>(evidence);
    }
    if (!nullToAbsent || effortEstimate != null) {
      map['effort_estimate'] = Variable<String>(effortEstimate);
    }
    if (!nullToAbsent || debtCategory != null) {
      map['debt_category'] = Variable<String>(debtCategory);
    }
    map['finding_status'] = Variable<String>(findingStatus);
    if (!nullToAbsent || statusChangedBy != null) {
      map['status_changed_by'] = Variable<String>(statusChangedBy);
    }
    if (!nullToAbsent || statusChangedAt != null) {
      map['status_changed_at'] = Variable<DateTime>(statusChangedAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  FindingsCompanion toCompanion(bool nullToAbsent) {
    return FindingsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      agentType: Value(agentType),
      severity: Value(severity),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      lineNumber: lineNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(lineNumber),
      recommendation: recommendation == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendation),
      evidence: evidence == null && nullToAbsent
          ? const Value.absent()
          : Value(evidence),
      effortEstimate: effortEstimate == null && nullToAbsent
          ? const Value.absent()
          : Value(effortEstimate),
      debtCategory: debtCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(debtCategory),
      findingStatus: Value(findingStatus),
      statusChangedBy: statusChangedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(statusChangedBy),
      statusChangedAt: statusChangedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(statusChangedAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Finding.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Finding(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      agentType: serializer.fromJson<String>(json['agentType']),
      severity: serializer.fromJson<String>(json['severity']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      lineNumber: serializer.fromJson<int?>(json['lineNumber']),
      recommendation: serializer.fromJson<String?>(json['recommendation']),
      evidence: serializer.fromJson<String?>(json['evidence']),
      effortEstimate: serializer.fromJson<String?>(json['effortEstimate']),
      debtCategory: serializer.fromJson<String?>(json['debtCategory']),
      findingStatus: serializer.fromJson<String>(json['findingStatus']),
      statusChangedBy: serializer.fromJson<String?>(json['statusChangedBy']),
      statusChangedAt: serializer.fromJson<DateTime?>(json['statusChangedAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'agentType': serializer.toJson<String>(agentType),
      'severity': serializer.toJson<String>(severity),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'filePath': serializer.toJson<String?>(filePath),
      'lineNumber': serializer.toJson<int?>(lineNumber),
      'recommendation': serializer.toJson<String?>(recommendation),
      'evidence': serializer.toJson<String?>(evidence),
      'effortEstimate': serializer.toJson<String?>(effortEstimate),
      'debtCategory': serializer.toJson<String?>(debtCategory),
      'findingStatus': serializer.toJson<String>(findingStatus),
      'statusChangedBy': serializer.toJson<String?>(statusChangedBy),
      'statusChangedAt': serializer.toJson<DateTime?>(statusChangedAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Finding copyWith(
          {String? id,
          String? jobId,
          String? agentType,
          String? severity,
          String? title,
          Value<String?> description = const Value.absent(),
          Value<String?> filePath = const Value.absent(),
          Value<int?> lineNumber = const Value.absent(),
          Value<String?> recommendation = const Value.absent(),
          Value<String?> evidence = const Value.absent(),
          Value<String?> effortEstimate = const Value.absent(),
          Value<String?> debtCategory = const Value.absent(),
          String? findingStatus,
          Value<String?> statusChangedBy = const Value.absent(),
          Value<DateTime?> statusChangedAt = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      Finding(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        agentType: agentType ?? this.agentType,
        severity: severity ?? this.severity,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        filePath: filePath.present ? filePath.value : this.filePath,
        lineNumber: lineNumber.present ? lineNumber.value : this.lineNumber,
        recommendation:
            recommendation.present ? recommendation.value : this.recommendation,
        evidence: evidence.present ? evidence.value : this.evidence,
        effortEstimate:
            effortEstimate.present ? effortEstimate.value : this.effortEstimate,
        debtCategory:
            debtCategory.present ? debtCategory.value : this.debtCategory,
        findingStatus: findingStatus ?? this.findingStatus,
        statusChangedBy: statusChangedBy.present
            ? statusChangedBy.value
            : this.statusChangedBy,
        statusChangedAt: statusChangedAt.present
            ? statusChangedAt.value
            : this.statusChangedAt,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  Finding copyWithCompanion(FindingsCompanion data) {
    return Finding(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      agentType: data.agentType.present ? data.agentType.value : this.agentType,
      severity: data.severity.present ? data.severity.value : this.severity,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      lineNumber:
          data.lineNumber.present ? data.lineNumber.value : this.lineNumber,
      recommendation: data.recommendation.present
          ? data.recommendation.value
          : this.recommendation,
      evidence: data.evidence.present ? data.evidence.value : this.evidence,
      effortEstimate: data.effortEstimate.present
          ? data.effortEstimate.value
          : this.effortEstimate,
      debtCategory: data.debtCategory.present
          ? data.debtCategory.value
          : this.debtCategory,
      findingStatus: data.findingStatus.present
          ? data.findingStatus.value
          : this.findingStatus,
      statusChangedBy: data.statusChangedBy.present
          ? data.statusChangedBy.value
          : this.statusChangedBy,
      statusChangedAt: data.statusChangedAt.present
          ? data.statusChangedAt.value
          : this.statusChangedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Finding(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('agentType: $agentType, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('filePath: $filePath, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('recommendation: $recommendation, ')
          ..write('evidence: $evidence, ')
          ..write('effortEstimate: $effortEstimate, ')
          ..write('debtCategory: $debtCategory, ')
          ..write('findingStatus: $findingStatus, ')
          ..write('statusChangedBy: $statusChangedBy, ')
          ..write('statusChangedAt: $statusChangedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      jobId,
      agentType,
      severity,
      title,
      description,
      filePath,
      lineNumber,
      recommendation,
      evidence,
      effortEstimate,
      debtCategory,
      findingStatus,
      statusChangedBy,
      statusChangedAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Finding &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.agentType == this.agentType &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.description == this.description &&
          other.filePath == this.filePath &&
          other.lineNumber == this.lineNumber &&
          other.recommendation == this.recommendation &&
          other.evidence == this.evidence &&
          other.effortEstimate == this.effortEstimate &&
          other.debtCategory == this.debtCategory &&
          other.findingStatus == this.findingStatus &&
          other.statusChangedBy == this.statusChangedBy &&
          other.statusChangedAt == this.statusChangedAt &&
          other.createdAt == this.createdAt);
}

class FindingsCompanion extends UpdateCompanion<Finding> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<String> agentType;
  final Value<String> severity;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> filePath;
  final Value<int?> lineNumber;
  final Value<String?> recommendation;
  final Value<String?> evidence;
  final Value<String?> effortEstimate;
  final Value<String?> debtCategory;
  final Value<String> findingStatus;
  final Value<String?> statusChangedBy;
  final Value<DateTime?> statusChangedAt;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const FindingsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.agentType = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.filePath = const Value.absent(),
    this.lineNumber = const Value.absent(),
    this.recommendation = const Value.absent(),
    this.evidence = const Value.absent(),
    this.effortEstimate = const Value.absent(),
    this.debtCategory = const Value.absent(),
    this.findingStatus = const Value.absent(),
    this.statusChangedBy = const Value.absent(),
    this.statusChangedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FindingsCompanion.insert({
    required String id,
    required String jobId,
    required String agentType,
    required String severity,
    required String title,
    this.description = const Value.absent(),
    this.filePath = const Value.absent(),
    this.lineNumber = const Value.absent(),
    this.recommendation = const Value.absent(),
    this.evidence = const Value.absent(),
    this.effortEstimate = const Value.absent(),
    this.debtCategory = const Value.absent(),
    required String findingStatus,
    this.statusChangedBy = const Value.absent(),
    this.statusChangedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        jobId = Value(jobId),
        agentType = Value(agentType),
        severity = Value(severity),
        title = Value(title),
        findingStatus = Value(findingStatus);
  static Insertable<Finding> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? agentType,
    Expression<String>? severity,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? filePath,
    Expression<int>? lineNumber,
    Expression<String>? recommendation,
    Expression<String>? evidence,
    Expression<String>? effortEstimate,
    Expression<String>? debtCategory,
    Expression<String>? findingStatus,
    Expression<String>? statusChangedBy,
    Expression<DateTime>? statusChangedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (agentType != null) 'agent_type': agentType,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (filePath != null) 'file_path': filePath,
      if (lineNumber != null) 'line_number': lineNumber,
      if (recommendation != null) 'recommendation': recommendation,
      if (evidence != null) 'evidence': evidence,
      if (effortEstimate != null) 'effort_estimate': effortEstimate,
      if (debtCategory != null) 'debt_category': debtCategory,
      if (findingStatus != null) 'finding_status': findingStatus,
      if (statusChangedBy != null) 'status_changed_by': statusChangedBy,
      if (statusChangedAt != null) 'status_changed_at': statusChangedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FindingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? jobId,
      Value<String>? agentType,
      Value<String>? severity,
      Value<String>? title,
      Value<String?>? description,
      Value<String?>? filePath,
      Value<int?>? lineNumber,
      Value<String?>? recommendation,
      Value<String?>? evidence,
      Value<String?>? effortEstimate,
      Value<String?>? debtCategory,
      Value<String>? findingStatus,
      Value<String?>? statusChangedBy,
      Value<DateTime?>? statusChangedAt,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return FindingsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      agentType: agentType ?? this.agentType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      lineNumber: lineNumber ?? this.lineNumber,
      recommendation: recommendation ?? this.recommendation,
      evidence: evidence ?? this.evidence,
      effortEstimate: effortEstimate ?? this.effortEstimate,
      debtCategory: debtCategory ?? this.debtCategory,
      findingStatus: findingStatus ?? this.findingStatus,
      statusChangedBy: statusChangedBy ?? this.statusChangedBy,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (agentType.present) {
      map['agent_type'] = Variable<String>(agentType.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (lineNumber.present) {
      map['line_number'] = Variable<int>(lineNumber.value);
    }
    if (recommendation.present) {
      map['recommendation'] = Variable<String>(recommendation.value);
    }
    if (evidence.present) {
      map['evidence'] = Variable<String>(evidence.value);
    }
    if (effortEstimate.present) {
      map['effort_estimate'] = Variable<String>(effortEstimate.value);
    }
    if (debtCategory.present) {
      map['debt_category'] = Variable<String>(debtCategory.value);
    }
    if (findingStatus.present) {
      map['finding_status'] = Variable<String>(findingStatus.value);
    }
    if (statusChangedBy.present) {
      map['status_changed_by'] = Variable<String>(statusChangedBy.value);
    }
    if (statusChangedAt.present) {
      map['status_changed_at'] = Variable<DateTime>(statusChangedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FindingsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('agentType: $agentType, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('filePath: $filePath, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('recommendation: $recommendation, ')
          ..write('evidence: $evidence, ')
          ..write('effortEstimate: $effortEstimate, ')
          ..write('debtCategory: $debtCategory, ')
          ..write('findingStatus: $findingStatus, ')
          ..write('statusChangedBy: $statusChangedBy, ')
          ..write('statusChangedAt: $statusChangedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemediationTasksTable extends RemediationTasks
    with TableInfo<$RemediationTasksTable, RemediationTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemediationTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskNumberMeta =
      const VerificationMeta('taskNumber');
  @override
  late final GeneratedColumn<int> taskNumber = GeneratedColumn<int>(
      'task_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _promptMdMeta =
      const VerificationMeta('promptMd');
  @override
  late final GeneratedColumn<String> promptMd = GeneratedColumn<String>(
      'prompt_md', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assignedToMeta =
      const VerificationMeta('assignedTo');
  @override
  late final GeneratedColumn<String> assignedTo = GeneratedColumn<String>(
      'assigned_to', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _assignedToNameMeta =
      const VerificationMeta('assignedToName');
  @override
  late final GeneratedColumn<String> assignedToName = GeneratedColumn<String>(
      'assigned_to_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jiraKeyMeta =
      const VerificationMeta('jiraKey');
  @override
  late final GeneratedColumn<String> jiraKey = GeneratedColumn<String>(
      'jira_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobId,
        taskNumber,
        title,
        description,
        promptMd,
        priority,
        status,
        assignedTo,
        assignedToName,
        jiraKey,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remediation_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<RemediationTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('task_number')) {
      context.handle(
          _taskNumberMeta,
          taskNumber.isAcceptableOrUnknown(
              data['task_number']!, _taskNumberMeta));
    } else if (isInserting) {
      context.missing(_taskNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('prompt_md')) {
      context.handle(_promptMdMeta,
          promptMd.isAcceptableOrUnknown(data['prompt_md']!, _promptMdMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('assigned_to')) {
      context.handle(
          _assignedToMeta,
          assignedTo.isAcceptableOrUnknown(
              data['assigned_to']!, _assignedToMeta));
    }
    if (data.containsKey('assigned_to_name')) {
      context.handle(
          _assignedToNameMeta,
          assignedToName.isAcceptableOrUnknown(
              data['assigned_to_name']!, _assignedToNameMeta));
    }
    if (data.containsKey('jira_key')) {
      context.handle(_jiraKeyMeta,
          jiraKey.isAcceptableOrUnknown(data['jira_key']!, _jiraKeyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemediationTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemediationTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      taskNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}task_number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      promptMd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt_md']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      assignedTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assigned_to']),
      assignedToName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}assigned_to_name']),
      jiraKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jira_key']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $RemediationTasksTable createAlias(String alias) {
    return $RemediationTasksTable(attachedDatabase, alias);
  }
}

class RemediationTask extends DataClass implements Insertable<RemediationTask> {
  /// UUID primary key.
  final String id;

  /// Parent job UUID.
  final String jobId;

  /// Sequential task number.
  final int taskNumber;

  /// Task title.
  final String title;

  /// Description.
  final String? description;

  /// Prompt markdown.
  final String? promptMd;

  /// Priority (SCREAMING_SNAKE_CASE).
  final String? priority;

  /// Status (SCREAMING_SNAKE_CASE).
  final String status;

  /// Assignee UUID.
  final String? assignedTo;

  /// Assignee display name.
  final String? assignedToName;

  /// Jira ticket key.
  final String? jiraKey;

  /// Creation timestamp.
  final DateTime? createdAt;
  const RemediationTask(
      {required this.id,
      required this.jobId,
      required this.taskNumber,
      required this.title,
      this.description,
      this.promptMd,
      this.priority,
      required this.status,
      this.assignedTo,
      this.assignedToName,
      this.jiraKey,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['task_number'] = Variable<int>(taskNumber);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || promptMd != null) {
      map['prompt_md'] = Variable<String>(promptMd);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<String>(priority);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || assignedTo != null) {
      map['assigned_to'] = Variable<String>(assignedTo);
    }
    if (!nullToAbsent || assignedToName != null) {
      map['assigned_to_name'] = Variable<String>(assignedToName);
    }
    if (!nullToAbsent || jiraKey != null) {
      map['jira_key'] = Variable<String>(jiraKey);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  RemediationTasksCompanion toCompanion(bool nullToAbsent) {
    return RemediationTasksCompanion(
      id: Value(id),
      jobId: Value(jobId),
      taskNumber: Value(taskNumber),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      promptMd: promptMd == null && nullToAbsent
          ? const Value.absent()
          : Value(promptMd),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      status: Value(status),
      assignedTo: assignedTo == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedTo),
      assignedToName: assignedToName == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedToName),
      jiraKey: jiraKey == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraKey),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory RemediationTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemediationTask(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      taskNumber: serializer.fromJson<int>(json['taskNumber']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      promptMd: serializer.fromJson<String?>(json['promptMd']),
      priority: serializer.fromJson<String?>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      assignedTo: serializer.fromJson<String?>(json['assignedTo']),
      assignedToName: serializer.fromJson<String?>(json['assignedToName']),
      jiraKey: serializer.fromJson<String?>(json['jiraKey']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'taskNumber': serializer.toJson<int>(taskNumber),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'promptMd': serializer.toJson<String?>(promptMd),
      'priority': serializer.toJson<String?>(priority),
      'status': serializer.toJson<String>(status),
      'assignedTo': serializer.toJson<String?>(assignedTo),
      'assignedToName': serializer.toJson<String?>(assignedToName),
      'jiraKey': serializer.toJson<String?>(jiraKey),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  RemediationTask copyWith(
          {String? id,
          String? jobId,
          int? taskNumber,
          String? title,
          Value<String?> description = const Value.absent(),
          Value<String?> promptMd = const Value.absent(),
          Value<String?> priority = const Value.absent(),
          String? status,
          Value<String?> assignedTo = const Value.absent(),
          Value<String?> assignedToName = const Value.absent(),
          Value<String?> jiraKey = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      RemediationTask(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        taskNumber: taskNumber ?? this.taskNumber,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        promptMd: promptMd.present ? promptMd.value : this.promptMd,
        priority: priority.present ? priority.value : this.priority,
        status: status ?? this.status,
        assignedTo: assignedTo.present ? assignedTo.value : this.assignedTo,
        assignedToName:
            assignedToName.present ? assignedToName.value : this.assignedToName,
        jiraKey: jiraKey.present ? jiraKey.value : this.jiraKey,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  RemediationTask copyWithCompanion(RemediationTasksCompanion data) {
    return RemediationTask(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      taskNumber:
          data.taskNumber.present ? data.taskNumber.value : this.taskNumber,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      promptMd: data.promptMd.present ? data.promptMd.value : this.promptMd,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      assignedTo:
          data.assignedTo.present ? data.assignedTo.value : this.assignedTo,
      assignedToName: data.assignedToName.present
          ? data.assignedToName.value
          : this.assignedToName,
      jiraKey: data.jiraKey.present ? data.jiraKey.value : this.jiraKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemediationTask(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('taskNumber: $taskNumber, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('promptMd: $promptMd, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('assignedToName: $assignedToName, ')
          ..write('jiraKey: $jiraKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      jobId,
      taskNumber,
      title,
      description,
      promptMd,
      priority,
      status,
      assignedTo,
      assignedToName,
      jiraKey,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemediationTask &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.taskNumber == this.taskNumber &&
          other.title == this.title &&
          other.description == this.description &&
          other.promptMd == this.promptMd &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.assignedTo == this.assignedTo &&
          other.assignedToName == this.assignedToName &&
          other.jiraKey == this.jiraKey &&
          other.createdAt == this.createdAt);
}

class RemediationTasksCompanion extends UpdateCompanion<RemediationTask> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<int> taskNumber;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> promptMd;
  final Value<String?> priority;
  final Value<String> status;
  final Value<String?> assignedTo;
  final Value<String?> assignedToName;
  final Value<String?> jiraKey;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const RemediationTasksCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.taskNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.promptMd = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.assignedToName = const Value.absent(),
    this.jiraKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemediationTasksCompanion.insert({
    required String id,
    required String jobId,
    required int taskNumber,
    required String title,
    this.description = const Value.absent(),
    this.promptMd = const Value.absent(),
    this.priority = const Value.absent(),
    required String status,
    this.assignedTo = const Value.absent(),
    this.assignedToName = const Value.absent(),
    this.jiraKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        jobId = Value(jobId),
        taskNumber = Value(taskNumber),
        title = Value(title),
        status = Value(status);
  static Insertable<RemediationTask> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<int>? taskNumber,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? promptMd,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<String>? assignedTo,
    Expression<String>? assignedToName,
    Expression<String>? jiraKey,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (taskNumber != null) 'task_number': taskNumber,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (promptMd != null) 'prompt_md': promptMd,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (assignedToName != null) 'assigned_to_name': assignedToName,
      if (jiraKey != null) 'jira_key': jiraKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemediationTasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? jobId,
      Value<int>? taskNumber,
      Value<String>? title,
      Value<String?>? description,
      Value<String?>? promptMd,
      Value<String?>? priority,
      Value<String>? status,
      Value<String?>? assignedTo,
      Value<String?>? assignedToName,
      Value<String?>? jiraKey,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return RemediationTasksCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      taskNumber: taskNumber ?? this.taskNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      promptMd: promptMd ?? this.promptMd,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      jiraKey: jiraKey ?? this.jiraKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (taskNumber.present) {
      map['task_number'] = Variable<int>(taskNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (promptMd.present) {
      map['prompt_md'] = Variable<String>(promptMd.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (assignedTo.present) {
      map['assigned_to'] = Variable<String>(assignedTo.value);
    }
    if (assignedToName.present) {
      map['assigned_to_name'] = Variable<String>(assignedToName.value);
    }
    if (jiraKey.present) {
      map['jira_key'] = Variable<String>(jiraKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemediationTasksCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('taskNumber: $taskNumber, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('promptMd: $promptMd, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('assignedToName: $assignedToName, ')
          ..write('jiraKey: $jiraKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonasTable extends Personas with TableInfo<$PersonasTable, Persona> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentTypeMeta =
      const VerificationMeta('agentType');
  @override
  late final GeneratedColumn<String> agentType = GeneratedColumn<String>(
      'agent_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMdMeta =
      const VerificationMeta('contentMd');
  @override
  late final GeneratedColumn<String> contentMd = GeneratedColumn<String>(
      'content_md', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
      'scope', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
      'team_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByNameMeta =
      const VerificationMeta('createdByName');
  @override
  late final GeneratedColumn<String> createdByName = GeneratedColumn<String>(
      'created_by_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        agentType,
        description,
        contentMd,
        scope,
        teamId,
        createdBy,
        createdByName,
        isDefault,
        version,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personas';
  @override
  VerificationContext validateIntegrity(Insertable<Persona> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('agent_type')) {
      context.handle(_agentTypeMeta,
          agentType.isAcceptableOrUnknown(data['agent_type']!, _agentTypeMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('content_md')) {
      context.handle(_contentMdMeta,
          contentMd.isAcceptableOrUnknown(data['content_md']!, _contentMdMeta));
    }
    if (data.containsKey('scope')) {
      context.handle(
          _scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(_teamIdMeta,
          teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('created_by_name')) {
      context.handle(
          _createdByNameMeta,
          createdByName.isAcceptableOrUnknown(
              data['created_by_name']!, _createdByNameMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Persona map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Persona(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      agentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_type']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      contentMd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_md']),
      scope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      teamId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_id']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      createdByName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by_name']),
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $PersonasTable createAlias(String alias) {
    return $PersonasTable(attachedDatabase, alias);
  }
}

class Persona extends DataClass implements Insertable<Persona> {
  /// UUID primary key.
  final String id;

  /// Persona name.
  final String name;

  /// Agent type (SCREAMING_SNAKE_CASE).
  final String? agentType;

  /// Description.
  final String? description;

  /// Content markdown.
  final String? contentMd;

  /// Scope (SCREAMING_SNAKE_CASE).
  final String scope;

  /// Team UUID.
  final String? teamId;

  /// Creator UUID.
  final String? createdBy;

  /// Creator display name.
  final String? createdByName;

  /// Whether this is the default persona.
  final bool isDefault;

  /// Version number.
  final int? version;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;
  const Persona(
      {required this.id,
      required this.name,
      this.agentType,
      this.description,
      this.contentMd,
      required this.scope,
      this.teamId,
      this.createdBy,
      this.createdByName,
      required this.isDefault,
      this.version,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || agentType != null) {
      map['agent_type'] = Variable<String>(agentType);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || contentMd != null) {
      map['content_md'] = Variable<String>(contentMd);
    }
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<String>(teamId);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || createdByName != null) {
      map['created_by_name'] = Variable<String>(createdByName);
    }
    map['is_default'] = Variable<bool>(isDefault);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  PersonasCompanion toCompanion(bool nullToAbsent) {
    return PersonasCompanion(
      id: Value(id),
      name: Value(name),
      agentType: agentType == null && nullToAbsent
          ? const Value.absent()
          : Value(agentType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      contentMd: contentMd == null && nullToAbsent
          ? const Value.absent()
          : Value(contentMd),
      scope: Value(scope),
      teamId:
          teamId == null && nullToAbsent ? const Value.absent() : Value(teamId),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdByName: createdByName == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByName),
      isDefault: Value(isDefault),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Persona.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Persona(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      agentType: serializer.fromJson<String?>(json['agentType']),
      description: serializer.fromJson<String?>(json['description']),
      contentMd: serializer.fromJson<String?>(json['contentMd']),
      scope: serializer.fromJson<String>(json['scope']),
      teamId: serializer.fromJson<String?>(json['teamId']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdByName: serializer.fromJson<String?>(json['createdByName']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      version: serializer.fromJson<int?>(json['version']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'agentType': serializer.toJson<String?>(agentType),
      'description': serializer.toJson<String?>(description),
      'contentMd': serializer.toJson<String?>(contentMd),
      'scope': serializer.toJson<String>(scope),
      'teamId': serializer.toJson<String?>(teamId),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdByName': serializer.toJson<String?>(createdByName),
      'isDefault': serializer.toJson<bool>(isDefault),
      'version': serializer.toJson<int?>(version),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Persona copyWith(
          {String? id,
          String? name,
          Value<String?> agentType = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> contentMd = const Value.absent(),
          String? scope,
          Value<String?> teamId = const Value.absent(),
          Value<String?> createdBy = const Value.absent(),
          Value<String?> createdByName = const Value.absent(),
          bool? isDefault,
          Value<int?> version = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Persona(
        id: id ?? this.id,
        name: name ?? this.name,
        agentType: agentType.present ? agentType.value : this.agentType,
        description: description.present ? description.value : this.description,
        contentMd: contentMd.present ? contentMd.value : this.contentMd,
        scope: scope ?? this.scope,
        teamId: teamId.present ? teamId.value : this.teamId,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        createdByName:
            createdByName.present ? createdByName.value : this.createdByName,
        isDefault: isDefault ?? this.isDefault,
        version: version.present ? version.value : this.version,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Persona copyWithCompanion(PersonasCompanion data) {
    return Persona(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      agentType: data.agentType.present ? data.agentType.value : this.agentType,
      description:
          data.description.present ? data.description.value : this.description,
      contentMd: data.contentMd.present ? data.contentMd.value : this.contentMd,
      scope: data.scope.present ? data.scope.value : this.scope,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdByName: data.createdByName.present
          ? data.createdByName.value
          : this.createdByName,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Persona(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('agentType: $agentType, ')
          ..write('description: $description, ')
          ..write('contentMd: $contentMd, ')
          ..write('scope: $scope, ')
          ..write('teamId: $teamId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdByName: $createdByName, ')
          ..write('isDefault: $isDefault, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      agentType,
      description,
      contentMd,
      scope,
      teamId,
      createdBy,
      createdByName,
      isDefault,
      version,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Persona &&
          other.id == this.id &&
          other.name == this.name &&
          other.agentType == this.agentType &&
          other.description == this.description &&
          other.contentMd == this.contentMd &&
          other.scope == this.scope &&
          other.teamId == this.teamId &&
          other.createdBy == this.createdBy &&
          other.createdByName == this.createdByName &&
          other.isDefault == this.isDefault &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PersonasCompanion extends UpdateCompanion<Persona> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> agentType;
  final Value<String?> description;
  final Value<String?> contentMd;
  final Value<String> scope;
  final Value<String?> teamId;
  final Value<String?> createdBy;
  final Value<String?> createdByName;
  final Value<bool> isDefault;
  final Value<int?> version;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const PersonasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.agentType = const Value.absent(),
    this.description = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.scope = const Value.absent(),
    this.teamId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdByName = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonasCompanion.insert({
    required String id,
    required String name,
    this.agentType = const Value.absent(),
    this.description = const Value.absent(),
    this.contentMd = const Value.absent(),
    required String scope,
    this.teamId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdByName = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        scope = Value(scope);
  static Insertable<Persona> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? agentType,
    Expression<String>? description,
    Expression<String>? contentMd,
    Expression<String>? scope,
    Expression<String>? teamId,
    Expression<String>? createdBy,
    Expression<String>? createdByName,
    Expression<bool>? isDefault,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (agentType != null) 'agent_type': agentType,
      if (description != null) 'description': description,
      if (contentMd != null) 'content_md': contentMd,
      if (scope != null) 'scope': scope,
      if (teamId != null) 'team_id': teamId,
      if (createdBy != null) 'created_by': createdBy,
      if (createdByName != null) 'created_by_name': createdByName,
      if (isDefault != null) 'is_default': isDefault,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonasCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? agentType,
      Value<String?>? description,
      Value<String?>? contentMd,
      Value<String>? scope,
      Value<String?>? teamId,
      Value<String?>? createdBy,
      Value<String?>? createdByName,
      Value<bool>? isDefault,
      Value<int?>? version,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return PersonasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      agentType: agentType ?? this.agentType,
      description: description ?? this.description,
      contentMd: contentMd ?? this.contentMd,
      scope: scope ?? this.scope,
      teamId: teamId ?? this.teamId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      isDefault: isDefault ?? this.isDefault,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (agentType.present) {
      map['agent_type'] = Variable<String>(agentType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (contentMd.present) {
      map['content_md'] = Variable<String>(contentMd.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdByName.present) {
      map['created_by_name'] = Variable<String>(createdByName.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('agentType: $agentType, ')
          ..write('description: $description, ')
          ..write('contentMd: $contentMd, ')
          ..write('scope: $scope, ')
          ..write('teamId: $teamId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdByName: $createdByName, ')
          ..write('isDefault: $isDefault, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DirectivesTable extends Directives
    with TableInfo<$DirectivesTable, Directive> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DirectivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMdMeta =
      const VerificationMeta('contentMd');
  @override
  late final GeneratedColumn<String> contentMd = GeneratedColumn<String>(
      'content_md', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
      'scope', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
      'team_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByNameMeta =
      const VerificationMeta('createdByName');
  @override
  late final GeneratedColumn<String> createdByName = GeneratedColumn<String>(
      'created_by_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        contentMd,
        category,
        scope,
        teamId,
        projectId,
        createdBy,
        createdByName,
        version,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'directives';
  @override
  VerificationContext validateIntegrity(Insertable<Directive> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('content_md')) {
      context.handle(_contentMdMeta,
          contentMd.isAcceptableOrUnknown(data['content_md']!, _contentMdMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('scope')) {
      context.handle(
          _scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(_teamIdMeta,
          teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('created_by_name')) {
      context.handle(
          _createdByNameMeta,
          createdByName.isAcceptableOrUnknown(
              data['created_by_name']!, _createdByNameMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Directive map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Directive(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      contentMd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_md']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      scope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      teamId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_id']),
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      createdByName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by_name']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $DirectivesTable createAlias(String alias) {
    return $DirectivesTable(attachedDatabase, alias);
  }
}

class Directive extends DataClass implements Insertable<Directive> {
  /// UUID primary key.
  final String id;

  /// Directive name.
  final String name;

  /// Description.
  final String? description;

  /// Content markdown.
  final String? contentMd;

  /// Category (SCREAMING_SNAKE_CASE).
  final String? category;

  /// Scope (SCREAMING_SNAKE_CASE).
  final String scope;

  /// Team UUID.
  final String? teamId;

  /// Project UUID.
  final String? projectId;

  /// Creator UUID.
  final String? createdBy;

  /// Creator display name.
  final String? createdByName;

  /// Version number.
  final int? version;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;
  const Directive(
      {required this.id,
      required this.name,
      this.description,
      this.contentMd,
      this.category,
      required this.scope,
      this.teamId,
      this.projectId,
      this.createdBy,
      this.createdByName,
      this.version,
      this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || contentMd != null) {
      map['content_md'] = Variable<String>(contentMd);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<String>(teamId);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || createdByName != null) {
      map['created_by_name'] = Variable<String>(createdByName);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  DirectivesCompanion toCompanion(bool nullToAbsent) {
    return DirectivesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      contentMd: contentMd == null && nullToAbsent
          ? const Value.absent()
          : Value(contentMd),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      scope: Value(scope),
      teamId:
          teamId == null && nullToAbsent ? const Value.absent() : Value(teamId),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdByName: createdByName == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByName),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Directive.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Directive(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      contentMd: serializer.fromJson<String?>(json['contentMd']),
      category: serializer.fromJson<String?>(json['category']),
      scope: serializer.fromJson<String>(json['scope']),
      teamId: serializer.fromJson<String?>(json['teamId']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdByName: serializer.fromJson<String?>(json['createdByName']),
      version: serializer.fromJson<int?>(json['version']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'contentMd': serializer.toJson<String?>(contentMd),
      'category': serializer.toJson<String?>(category),
      'scope': serializer.toJson<String>(scope),
      'teamId': serializer.toJson<String?>(teamId),
      'projectId': serializer.toJson<String?>(projectId),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdByName': serializer.toJson<String?>(createdByName),
      'version': serializer.toJson<int?>(version),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Directive copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          Value<String?> contentMd = const Value.absent(),
          Value<String?> category = const Value.absent(),
          String? scope,
          Value<String?> teamId = const Value.absent(),
          Value<String?> projectId = const Value.absent(),
          Value<String?> createdBy = const Value.absent(),
          Value<String?> createdByName = const Value.absent(),
          Value<int?> version = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Directive(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        contentMd: contentMd.present ? contentMd.value : this.contentMd,
        category: category.present ? category.value : this.category,
        scope: scope ?? this.scope,
        teamId: teamId.present ? teamId.value : this.teamId,
        projectId: projectId.present ? projectId.value : this.projectId,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        createdByName:
            createdByName.present ? createdByName.value : this.createdByName,
        version: version.present ? version.value : this.version,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Directive copyWithCompanion(DirectivesCompanion data) {
    return Directive(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      contentMd: data.contentMd.present ? data.contentMd.value : this.contentMd,
      category: data.category.present ? data.category.value : this.category,
      scope: data.scope.present ? data.scope.value : this.scope,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdByName: data.createdByName.present
          ? data.createdByName.value
          : this.createdByName,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Directive(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('contentMd: $contentMd, ')
          ..write('category: $category, ')
          ..write('scope: $scope, ')
          ..write('teamId: $teamId, ')
          ..write('projectId: $projectId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdByName: $createdByName, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      contentMd,
      category,
      scope,
      teamId,
      projectId,
      createdBy,
      createdByName,
      version,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Directive &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.contentMd == this.contentMd &&
          other.category == this.category &&
          other.scope == this.scope &&
          other.teamId == this.teamId &&
          other.projectId == this.projectId &&
          other.createdBy == this.createdBy &&
          other.createdByName == this.createdByName &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DirectivesCompanion extends UpdateCompanion<Directive> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> contentMd;
  final Value<String?> category;
  final Value<String> scope;
  final Value<String?> teamId;
  final Value<String?> projectId;
  final Value<String?> createdBy;
  final Value<String?> createdByName;
  final Value<int?> version;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const DirectivesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.category = const Value.absent(),
    this.scope = const Value.absent(),
    this.teamId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdByName = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DirectivesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.category = const Value.absent(),
    required String scope,
    this.teamId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdByName = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        scope = Value(scope);
  static Insertable<Directive> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? contentMd,
    Expression<String>? category,
    Expression<String>? scope,
    Expression<String>? teamId,
    Expression<String>? projectId,
    Expression<String>? createdBy,
    Expression<String>? createdByName,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (contentMd != null) 'content_md': contentMd,
      if (category != null) 'category': category,
      if (scope != null) 'scope': scope,
      if (teamId != null) 'team_id': teamId,
      if (projectId != null) 'project_id': projectId,
      if (createdBy != null) 'created_by': createdBy,
      if (createdByName != null) 'created_by_name': createdByName,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DirectivesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<String?>? contentMd,
      Value<String?>? category,
      Value<String>? scope,
      Value<String?>? teamId,
      Value<String?>? projectId,
      Value<String?>? createdBy,
      Value<String?>? createdByName,
      Value<int?>? version,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return DirectivesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      contentMd: contentMd ?? this.contentMd,
      category: category ?? this.category,
      scope: scope ?? this.scope,
      teamId: teamId ?? this.teamId,
      projectId: projectId ?? this.projectId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (contentMd.present) {
      map['content_md'] = Variable<String>(contentMd.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdByName.present) {
      map['created_by_name'] = Variable<String>(createdByName.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DirectivesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('contentMd: $contentMd, ')
          ..write('category: $category, ')
          ..write('scope: $scope, ')
          ..write('teamId: $teamId, ')
          ..write('projectId: $projectId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdByName: $createdByName, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TechDebtItemsTable extends TechDebtItems
    with TableInfo<$TechDebtItemsTable, TechDebtItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TechDebtItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _effortEstimateMeta =
      const VerificationMeta('effortEstimate');
  @override
  late final GeneratedColumn<String> effortEstimate = GeneratedColumn<String>(
      'effort_estimate', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _businessImpactMeta =
      const VerificationMeta('businessImpact');
  @override
  late final GeneratedColumn<String> businessImpact = GeneratedColumn<String>(
      'business_impact', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firstDetectedJobIdMeta =
      const VerificationMeta('firstDetectedJobId');
  @override
  late final GeneratedColumn<String> firstDetectedJobId =
      GeneratedColumn<String>('first_detected_job_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _resolvedJobIdMeta =
      const VerificationMeta('resolvedJobId');
  @override
  late final GeneratedColumn<String> resolvedJobId = GeneratedColumn<String>(
      'resolved_job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        category,
        title,
        description,
        filePath,
        effortEstimate,
        businessImpact,
        status,
        firstDetectedJobId,
        resolvedJobId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tech_debt_items';
  @override
  VerificationContext validateIntegrity(Insertable<TechDebtItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('effort_estimate')) {
      context.handle(
          _effortEstimateMeta,
          effortEstimate.isAcceptableOrUnknown(
              data['effort_estimate']!, _effortEstimateMeta));
    }
    if (data.containsKey('business_impact')) {
      context.handle(
          _businessImpactMeta,
          businessImpact.isAcceptableOrUnknown(
              data['business_impact']!, _businessImpactMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('first_detected_job_id')) {
      context.handle(
          _firstDetectedJobIdMeta,
          firstDetectedJobId.isAcceptableOrUnknown(
              data['first_detected_job_id']!, _firstDetectedJobIdMeta));
    }
    if (data.containsKey('resolved_job_id')) {
      context.handle(
          _resolvedJobIdMeta,
          resolvedJobId.isAcceptableOrUnknown(
              data['resolved_job_id']!, _resolvedJobIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TechDebtItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TechDebtItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      effortEstimate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effort_estimate']),
      businessImpact: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}business_impact']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      firstDetectedJobId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}first_detected_job_id']),
      resolvedJobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resolved_job_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $TechDebtItemsTable createAlias(String alias) {
    return $TechDebtItemsTable(attachedDatabase, alias);
  }
}

class TechDebtItem extends DataClass implements Insertable<TechDebtItem> {
  /// UUID primary key.
  final String id;

  /// Project UUID.
  final String projectId;

  /// Category (SCREAMING_SNAKE_CASE).
  final String category;

  /// Title.
  final String title;

  /// Description.
  final String? description;

  /// File path.
  final String? filePath;

  /// Effort estimate (SCREAMING_SNAKE_CASE).
  final String? effortEstimate;

  /// Business impact (SCREAMING_SNAKE_CASE).
  final String? businessImpact;

  /// Status (SCREAMING_SNAKE_CASE).
  final String status;

  /// First detection job UUID.
  final String? firstDetectedJobId;

  /// Resolution job UUID.
  final String? resolvedJobId;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;
  const TechDebtItem(
      {required this.id,
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
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || effortEstimate != null) {
      map['effort_estimate'] = Variable<String>(effortEstimate);
    }
    if (!nullToAbsent || businessImpact != null) {
      map['business_impact'] = Variable<String>(businessImpact);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || firstDetectedJobId != null) {
      map['first_detected_job_id'] = Variable<String>(firstDetectedJobId);
    }
    if (!nullToAbsent || resolvedJobId != null) {
      map['resolved_job_id'] = Variable<String>(resolvedJobId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TechDebtItemsCompanion toCompanion(bool nullToAbsent) {
    return TechDebtItemsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      category: Value(category),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      effortEstimate: effortEstimate == null && nullToAbsent
          ? const Value.absent()
          : Value(effortEstimate),
      businessImpact: businessImpact == null && nullToAbsent
          ? const Value.absent()
          : Value(businessImpact),
      status: Value(status),
      firstDetectedJobId: firstDetectedJobId == null && nullToAbsent
          ? const Value.absent()
          : Value(firstDetectedJobId),
      resolvedJobId: resolvedJobId == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedJobId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory TechDebtItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TechDebtItem(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      effortEstimate: serializer.fromJson<String?>(json['effortEstimate']),
      businessImpact: serializer.fromJson<String?>(json['businessImpact']),
      status: serializer.fromJson<String>(json['status']),
      firstDetectedJobId:
          serializer.fromJson<String?>(json['firstDetectedJobId']),
      resolvedJobId: serializer.fromJson<String?>(json['resolvedJobId']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'filePath': serializer.toJson<String?>(filePath),
      'effortEstimate': serializer.toJson<String?>(effortEstimate),
      'businessImpact': serializer.toJson<String?>(businessImpact),
      'status': serializer.toJson<String>(status),
      'firstDetectedJobId': serializer.toJson<String?>(firstDetectedJobId),
      'resolvedJobId': serializer.toJson<String?>(resolvedJobId),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  TechDebtItem copyWith(
          {String? id,
          String? projectId,
          String? category,
          String? title,
          Value<String?> description = const Value.absent(),
          Value<String?> filePath = const Value.absent(),
          Value<String?> effortEstimate = const Value.absent(),
          Value<String?> businessImpact = const Value.absent(),
          String? status,
          Value<String?> firstDetectedJobId = const Value.absent(),
          Value<String?> resolvedJobId = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      TechDebtItem(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        category: category ?? this.category,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        filePath: filePath.present ? filePath.value : this.filePath,
        effortEstimate:
            effortEstimate.present ? effortEstimate.value : this.effortEstimate,
        businessImpact:
            businessImpact.present ? businessImpact.value : this.businessImpact,
        status: status ?? this.status,
        firstDetectedJobId: firstDetectedJobId.present
            ? firstDetectedJobId.value
            : this.firstDetectedJobId,
        resolvedJobId:
            resolvedJobId.present ? resolvedJobId.value : this.resolvedJobId,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  TechDebtItem copyWithCompanion(TechDebtItemsCompanion data) {
    return TechDebtItem(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      effortEstimate: data.effortEstimate.present
          ? data.effortEstimate.value
          : this.effortEstimate,
      businessImpact: data.businessImpact.present
          ? data.businessImpact.value
          : this.businessImpact,
      status: data.status.present ? data.status.value : this.status,
      firstDetectedJobId: data.firstDetectedJobId.present
          ? data.firstDetectedJobId.value
          : this.firstDetectedJobId,
      resolvedJobId: data.resolvedJobId.present
          ? data.resolvedJobId.value
          : this.resolvedJobId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TechDebtItem(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('filePath: $filePath, ')
          ..write('effortEstimate: $effortEstimate, ')
          ..write('businessImpact: $businessImpact, ')
          ..write('status: $status, ')
          ..write('firstDetectedJobId: $firstDetectedJobId, ')
          ..write('resolvedJobId: $resolvedJobId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      projectId,
      category,
      title,
      description,
      filePath,
      effortEstimate,
      businessImpact,
      status,
      firstDetectedJobId,
      resolvedJobId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TechDebtItem &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.category == this.category &&
          other.title == this.title &&
          other.description == this.description &&
          other.filePath == this.filePath &&
          other.effortEstimate == this.effortEstimate &&
          other.businessImpact == this.businessImpact &&
          other.status == this.status &&
          other.firstDetectedJobId == this.firstDetectedJobId &&
          other.resolvedJobId == this.resolvedJobId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TechDebtItemsCompanion extends UpdateCompanion<TechDebtItem> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> category;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> filePath;
  final Value<String?> effortEstimate;
  final Value<String?> businessImpact;
  final Value<String> status;
  final Value<String?> firstDetectedJobId;
  final Value<String?> resolvedJobId;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const TechDebtItemsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.filePath = const Value.absent(),
    this.effortEstimate = const Value.absent(),
    this.businessImpact = const Value.absent(),
    this.status = const Value.absent(),
    this.firstDetectedJobId = const Value.absent(),
    this.resolvedJobId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TechDebtItemsCompanion.insert({
    required String id,
    required String projectId,
    required String category,
    required String title,
    this.description = const Value.absent(),
    this.filePath = const Value.absent(),
    this.effortEstimate = const Value.absent(),
    this.businessImpact = const Value.absent(),
    required String status,
    this.firstDetectedJobId = const Value.absent(),
    this.resolvedJobId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        category = Value(category),
        title = Value(title),
        status = Value(status);
  static Insertable<TechDebtItem> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? filePath,
    Expression<String>? effortEstimate,
    Expression<String>? businessImpact,
    Expression<String>? status,
    Expression<String>? firstDetectedJobId,
    Expression<String>? resolvedJobId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (filePath != null) 'file_path': filePath,
      if (effortEstimate != null) 'effort_estimate': effortEstimate,
      if (businessImpact != null) 'business_impact': businessImpact,
      if (status != null) 'status': status,
      if (firstDetectedJobId != null)
        'first_detected_job_id': firstDetectedJobId,
      if (resolvedJobId != null) 'resolved_job_id': resolvedJobId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TechDebtItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String>? category,
      Value<String>? title,
      Value<String?>? description,
      Value<String?>? filePath,
      Value<String?>? effortEstimate,
      Value<String?>? businessImpact,
      Value<String>? status,
      Value<String?>? firstDetectedJobId,
      Value<String?>? resolvedJobId,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return TechDebtItemsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      effortEstimate: effortEstimate ?? this.effortEstimate,
      businessImpact: businessImpact ?? this.businessImpact,
      status: status ?? this.status,
      firstDetectedJobId: firstDetectedJobId ?? this.firstDetectedJobId,
      resolvedJobId: resolvedJobId ?? this.resolvedJobId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (effortEstimate.present) {
      map['effort_estimate'] = Variable<String>(effortEstimate.value);
    }
    if (businessImpact.present) {
      map['business_impact'] = Variable<String>(businessImpact.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (firstDetectedJobId.present) {
      map['first_detected_job_id'] = Variable<String>(firstDetectedJobId.value);
    }
    if (resolvedJobId.present) {
      map['resolved_job_id'] = Variable<String>(resolvedJobId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TechDebtItemsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('filePath: $filePath, ')
          ..write('effortEstimate: $effortEstimate, ')
          ..write('businessImpact: $businessImpact, ')
          ..write('status: $status, ')
          ..write('firstDetectedJobId: $firstDetectedJobId, ')
          ..write('resolvedJobId: $resolvedJobId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DependencyScansTable extends DependencyScans
    with TableInfo<$DependencyScansTable, DependencyScan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DependencyScansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _manifestFileMeta =
      const VerificationMeta('manifestFile');
  @override
  late final GeneratedColumn<String> manifestFile = GeneratedColumn<String>(
      'manifest_file', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalDependenciesMeta =
      const VerificationMeta('totalDependencies');
  @override
  late final GeneratedColumn<int> totalDependencies = GeneratedColumn<int>(
      'total_dependencies', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _outdatedCountMeta =
      const VerificationMeta('outdatedCount');
  @override
  late final GeneratedColumn<int> outdatedCount = GeneratedColumn<int>(
      'outdated_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _vulnerableCountMeta =
      const VerificationMeta('vulnerableCount');
  @override
  late final GeneratedColumn<int> vulnerableCount = GeneratedColumn<int>(
      'vulnerable_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        jobId,
        manifestFile,
        totalDependencies,
        outdatedCount,
        vulnerableCount,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dependency_scans';
  @override
  VerificationContext validateIntegrity(Insertable<DependencyScan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    }
    if (data.containsKey('manifest_file')) {
      context.handle(
          _manifestFileMeta,
          manifestFile.isAcceptableOrUnknown(
              data['manifest_file']!, _manifestFileMeta));
    }
    if (data.containsKey('total_dependencies')) {
      context.handle(
          _totalDependenciesMeta,
          totalDependencies.isAcceptableOrUnknown(
              data['total_dependencies']!, _totalDependenciesMeta));
    }
    if (data.containsKey('outdated_count')) {
      context.handle(
          _outdatedCountMeta,
          outdatedCount.isAcceptableOrUnknown(
              data['outdated_count']!, _outdatedCountMeta));
    }
    if (data.containsKey('vulnerable_count')) {
      context.handle(
          _vulnerableCountMeta,
          vulnerableCount.isAcceptableOrUnknown(
              data['vulnerable_count']!, _vulnerableCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DependencyScan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DependencyScan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id']),
      manifestFile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manifest_file']),
      totalDependencies: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_dependencies']),
      outdatedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}outdated_count']),
      vulnerableCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}vulnerable_count']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $DependencyScansTable createAlias(String alias) {
    return $DependencyScansTable(attachedDatabase, alias);
  }
}

class DependencyScan extends DataClass implements Insertable<DependencyScan> {
  /// UUID primary key.
  final String id;

  /// Project UUID.
  final String projectId;

  /// Job UUID.
  final String? jobId;

  /// Manifest file path.
  final String? manifestFile;

  /// Total dependencies count.
  final int? totalDependencies;

  /// Outdated dependencies count.
  final int? outdatedCount;

  /// Vulnerable dependencies count.
  final int? vulnerableCount;

  /// Creation timestamp.
  final DateTime? createdAt;
  const DependencyScan(
      {required this.id,
      required this.projectId,
      this.jobId,
      this.manifestFile,
      this.totalDependencies,
      this.outdatedCount,
      this.vulnerableCount,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || manifestFile != null) {
      map['manifest_file'] = Variable<String>(manifestFile);
    }
    if (!nullToAbsent || totalDependencies != null) {
      map['total_dependencies'] = Variable<int>(totalDependencies);
    }
    if (!nullToAbsent || outdatedCount != null) {
      map['outdated_count'] = Variable<int>(outdatedCount);
    }
    if (!nullToAbsent || vulnerableCount != null) {
      map['vulnerable_count'] = Variable<int>(vulnerableCount);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  DependencyScansCompanion toCompanion(bool nullToAbsent) {
    return DependencyScansCompanion(
      id: Value(id),
      projectId: Value(projectId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      manifestFile: manifestFile == null && nullToAbsent
          ? const Value.absent()
          : Value(manifestFile),
      totalDependencies: totalDependencies == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDependencies),
      outdatedCount: outdatedCount == null && nullToAbsent
          ? const Value.absent()
          : Value(outdatedCount),
      vulnerableCount: vulnerableCount == null && nullToAbsent
          ? const Value.absent()
          : Value(vulnerableCount),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory DependencyScan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DependencyScan(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      manifestFile: serializer.fromJson<String?>(json['manifestFile']),
      totalDependencies: serializer.fromJson<int?>(json['totalDependencies']),
      outdatedCount: serializer.fromJson<int?>(json['outdatedCount']),
      vulnerableCount: serializer.fromJson<int?>(json['vulnerableCount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'jobId': serializer.toJson<String?>(jobId),
      'manifestFile': serializer.toJson<String?>(manifestFile),
      'totalDependencies': serializer.toJson<int?>(totalDependencies),
      'outdatedCount': serializer.toJson<int?>(outdatedCount),
      'vulnerableCount': serializer.toJson<int?>(vulnerableCount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  DependencyScan copyWith(
          {String? id,
          String? projectId,
          Value<String?> jobId = const Value.absent(),
          Value<String?> manifestFile = const Value.absent(),
          Value<int?> totalDependencies = const Value.absent(),
          Value<int?> outdatedCount = const Value.absent(),
          Value<int?> vulnerableCount = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      DependencyScan(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        jobId: jobId.present ? jobId.value : this.jobId,
        manifestFile:
            manifestFile.present ? manifestFile.value : this.manifestFile,
        totalDependencies: totalDependencies.present
            ? totalDependencies.value
            : this.totalDependencies,
        outdatedCount:
            outdatedCount.present ? outdatedCount.value : this.outdatedCount,
        vulnerableCount: vulnerableCount.present
            ? vulnerableCount.value
            : this.vulnerableCount,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  DependencyScan copyWithCompanion(DependencyScansCompanion data) {
    return DependencyScan(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      manifestFile: data.manifestFile.present
          ? data.manifestFile.value
          : this.manifestFile,
      totalDependencies: data.totalDependencies.present
          ? data.totalDependencies.value
          : this.totalDependencies,
      outdatedCount: data.outdatedCount.present
          ? data.outdatedCount.value
          : this.outdatedCount,
      vulnerableCount: data.vulnerableCount.present
          ? data.vulnerableCount.value
          : this.vulnerableCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DependencyScan(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('jobId: $jobId, ')
          ..write('manifestFile: $manifestFile, ')
          ..write('totalDependencies: $totalDependencies, ')
          ..write('outdatedCount: $outdatedCount, ')
          ..write('vulnerableCount: $vulnerableCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, jobId, manifestFile,
      totalDependencies, outdatedCount, vulnerableCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DependencyScan &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.jobId == this.jobId &&
          other.manifestFile == this.manifestFile &&
          other.totalDependencies == this.totalDependencies &&
          other.outdatedCount == this.outdatedCount &&
          other.vulnerableCount == this.vulnerableCount &&
          other.createdAt == this.createdAt);
}

class DependencyScansCompanion extends UpdateCompanion<DependencyScan> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String?> jobId;
  final Value<String?> manifestFile;
  final Value<int?> totalDependencies;
  final Value<int?> outdatedCount;
  final Value<int?> vulnerableCount;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const DependencyScansCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.manifestFile = const Value.absent(),
    this.totalDependencies = const Value.absent(),
    this.outdatedCount = const Value.absent(),
    this.vulnerableCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DependencyScansCompanion.insert({
    required String id,
    required String projectId,
    this.jobId = const Value.absent(),
    this.manifestFile = const Value.absent(),
    this.totalDependencies = const Value.absent(),
    this.outdatedCount = const Value.absent(),
    this.vulnerableCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId);
  static Insertable<DependencyScan> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? jobId,
    Expression<String>? manifestFile,
    Expression<int>? totalDependencies,
    Expression<int>? outdatedCount,
    Expression<int>? vulnerableCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (jobId != null) 'job_id': jobId,
      if (manifestFile != null) 'manifest_file': manifestFile,
      if (totalDependencies != null) 'total_dependencies': totalDependencies,
      if (outdatedCount != null) 'outdated_count': outdatedCount,
      if (vulnerableCount != null) 'vulnerable_count': vulnerableCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DependencyScansCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String?>? jobId,
      Value<String?>? manifestFile,
      Value<int?>? totalDependencies,
      Value<int?>? outdatedCount,
      Value<int?>? vulnerableCount,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return DependencyScansCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      jobId: jobId ?? this.jobId,
      manifestFile: manifestFile ?? this.manifestFile,
      totalDependencies: totalDependencies ?? this.totalDependencies,
      outdatedCount: outdatedCount ?? this.outdatedCount,
      vulnerableCount: vulnerableCount ?? this.vulnerableCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (manifestFile.present) {
      map['manifest_file'] = Variable<String>(manifestFile.value);
    }
    if (totalDependencies.present) {
      map['total_dependencies'] = Variable<int>(totalDependencies.value);
    }
    if (outdatedCount.present) {
      map['outdated_count'] = Variable<int>(outdatedCount.value);
    }
    if (vulnerableCount.present) {
      map['vulnerable_count'] = Variable<int>(vulnerableCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DependencyScansCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('jobId: $jobId, ')
          ..write('manifestFile: $manifestFile, ')
          ..write('totalDependencies: $totalDependencies, ')
          ..write('outdatedCount: $outdatedCount, ')
          ..write('vulnerableCount: $vulnerableCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DependencyVulnerabilitiesTable extends DependencyVulnerabilities
    with TableInfo<$DependencyVulnerabilitiesTable, DependencyVulnerability> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DependencyVulnerabilitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
      'scan_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dependencyNameMeta =
      const VerificationMeta('dependencyName');
  @override
  late final GeneratedColumn<String> dependencyName = GeneratedColumn<String>(
      'dependency_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentVersionMeta =
      const VerificationMeta('currentVersion');
  @override
  late final GeneratedColumn<String> currentVersion = GeneratedColumn<String>(
      'current_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fixedVersionMeta =
      const VerificationMeta('fixedVersion');
  @override
  late final GeneratedColumn<String> fixedVersion = GeneratedColumn<String>(
      'fixed_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cveIdMeta = const VerificationMeta('cveId');
  @override
  late final GeneratedColumn<String> cveId = GeneratedColumn<String>(
      'cve_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        scanId,
        dependencyName,
        currentVersion,
        fixedVersion,
        cveId,
        severity,
        description,
        status,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dependency_vulnerabilities';
  @override
  VerificationContext validateIntegrity(
      Insertable<DependencyVulnerability> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(_scanIdMeta,
          scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta));
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('dependency_name')) {
      context.handle(
          _dependencyNameMeta,
          dependencyName.isAcceptableOrUnknown(
              data['dependency_name']!, _dependencyNameMeta));
    } else if (isInserting) {
      context.missing(_dependencyNameMeta);
    }
    if (data.containsKey('current_version')) {
      context.handle(
          _currentVersionMeta,
          currentVersion.isAcceptableOrUnknown(
              data['current_version']!, _currentVersionMeta));
    }
    if (data.containsKey('fixed_version')) {
      context.handle(
          _fixedVersionMeta,
          fixedVersion.isAcceptableOrUnknown(
              data['fixed_version']!, _fixedVersionMeta));
    }
    if (data.containsKey('cve_id')) {
      context.handle(
          _cveIdMeta, cveId.isAcceptableOrUnknown(data['cve_id']!, _cveIdMeta));
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DependencyVulnerability map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DependencyVulnerability(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      scanId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scan_id'])!,
      dependencyName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}dependency_name'])!,
      currentVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}current_version']),
      fixedVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fixed_version']),
      cveId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cve_id']),
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $DependencyVulnerabilitiesTable createAlias(String alias) {
    return $DependencyVulnerabilitiesTable(attachedDatabase, alias);
  }
}

class DependencyVulnerability extends DataClass
    implements Insertable<DependencyVulnerability> {
  /// UUID primary key.
  final String id;

  /// Parent scan UUID.
  final String scanId;

  /// Dependency name.
  final String dependencyName;

  /// Current version.
  final String? currentVersion;

  /// Fixed version.
  final String? fixedVersion;

  /// CVE identifier.
  final String? cveId;

  /// Severity (SCREAMING_SNAKE_CASE).
  final String severity;

  /// Description.
  final String? description;

  /// Status (SCREAMING_SNAKE_CASE).
  final String status;

  /// Creation timestamp.
  final DateTime? createdAt;
  const DependencyVulnerability(
      {required this.id,
      required this.scanId,
      required this.dependencyName,
      this.currentVersion,
      this.fixedVersion,
      this.cveId,
      required this.severity,
      this.description,
      required this.status,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scan_id'] = Variable<String>(scanId);
    map['dependency_name'] = Variable<String>(dependencyName);
    if (!nullToAbsent || currentVersion != null) {
      map['current_version'] = Variable<String>(currentVersion);
    }
    if (!nullToAbsent || fixedVersion != null) {
      map['fixed_version'] = Variable<String>(fixedVersion);
    }
    if (!nullToAbsent || cveId != null) {
      map['cve_id'] = Variable<String>(cveId);
    }
    map['severity'] = Variable<String>(severity);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  DependencyVulnerabilitiesCompanion toCompanion(bool nullToAbsent) {
    return DependencyVulnerabilitiesCompanion(
      id: Value(id),
      scanId: Value(scanId),
      dependencyName: Value(dependencyName),
      currentVersion: currentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(currentVersion),
      fixedVersion: fixedVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedVersion),
      cveId:
          cveId == null && nullToAbsent ? const Value.absent() : Value(cveId),
      severity: Value(severity),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory DependencyVulnerability.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DependencyVulnerability(
      id: serializer.fromJson<String>(json['id']),
      scanId: serializer.fromJson<String>(json['scanId']),
      dependencyName: serializer.fromJson<String>(json['dependencyName']),
      currentVersion: serializer.fromJson<String?>(json['currentVersion']),
      fixedVersion: serializer.fromJson<String?>(json['fixedVersion']),
      cveId: serializer.fromJson<String?>(json['cveId']),
      severity: serializer.fromJson<String>(json['severity']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scanId': serializer.toJson<String>(scanId),
      'dependencyName': serializer.toJson<String>(dependencyName),
      'currentVersion': serializer.toJson<String?>(currentVersion),
      'fixedVersion': serializer.toJson<String?>(fixedVersion),
      'cveId': serializer.toJson<String?>(cveId),
      'severity': serializer.toJson<String>(severity),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  DependencyVulnerability copyWith(
          {String? id,
          String? scanId,
          String? dependencyName,
          Value<String?> currentVersion = const Value.absent(),
          Value<String?> fixedVersion = const Value.absent(),
          Value<String?> cveId = const Value.absent(),
          String? severity,
          Value<String?> description = const Value.absent(),
          String? status,
          Value<DateTime?> createdAt = const Value.absent()}) =>
      DependencyVulnerability(
        id: id ?? this.id,
        scanId: scanId ?? this.scanId,
        dependencyName: dependencyName ?? this.dependencyName,
        currentVersion:
            currentVersion.present ? currentVersion.value : this.currentVersion,
        fixedVersion:
            fixedVersion.present ? fixedVersion.value : this.fixedVersion,
        cveId: cveId.present ? cveId.value : this.cveId,
        severity: severity ?? this.severity,
        description: description.present ? description.value : this.description,
        status: status ?? this.status,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  DependencyVulnerability copyWithCompanion(
      DependencyVulnerabilitiesCompanion data) {
    return DependencyVulnerability(
      id: data.id.present ? data.id.value : this.id,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      dependencyName: data.dependencyName.present
          ? data.dependencyName.value
          : this.dependencyName,
      currentVersion: data.currentVersion.present
          ? data.currentVersion.value
          : this.currentVersion,
      fixedVersion: data.fixedVersion.present
          ? data.fixedVersion.value
          : this.fixedVersion,
      cveId: data.cveId.present ? data.cveId.value : this.cveId,
      severity: data.severity.present ? data.severity.value : this.severity,
      description:
          data.description.present ? data.description.value : this.description,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DependencyVulnerability(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('dependencyName: $dependencyName, ')
          ..write('currentVersion: $currentVersion, ')
          ..write('fixedVersion: $fixedVersion, ')
          ..write('cveId: $cveId, ')
          ..write('severity: $severity, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scanId, dependencyName, currentVersion,
      fixedVersion, cveId, severity, description, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DependencyVulnerability &&
          other.id == this.id &&
          other.scanId == this.scanId &&
          other.dependencyName == this.dependencyName &&
          other.currentVersion == this.currentVersion &&
          other.fixedVersion == this.fixedVersion &&
          other.cveId == this.cveId &&
          other.severity == this.severity &&
          other.description == this.description &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class DependencyVulnerabilitiesCompanion
    extends UpdateCompanion<DependencyVulnerability> {
  final Value<String> id;
  final Value<String> scanId;
  final Value<String> dependencyName;
  final Value<String?> currentVersion;
  final Value<String?> fixedVersion;
  final Value<String?> cveId;
  final Value<String> severity;
  final Value<String?> description;
  final Value<String> status;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const DependencyVulnerabilitiesCompanion({
    this.id = const Value.absent(),
    this.scanId = const Value.absent(),
    this.dependencyName = const Value.absent(),
    this.currentVersion = const Value.absent(),
    this.fixedVersion = const Value.absent(),
    this.cveId = const Value.absent(),
    this.severity = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DependencyVulnerabilitiesCompanion.insert({
    required String id,
    required String scanId,
    required String dependencyName,
    this.currentVersion = const Value.absent(),
    this.fixedVersion = const Value.absent(),
    this.cveId = const Value.absent(),
    required String severity,
    this.description = const Value.absent(),
    required String status,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        scanId = Value(scanId),
        dependencyName = Value(dependencyName),
        severity = Value(severity),
        status = Value(status);
  static Insertable<DependencyVulnerability> custom({
    Expression<String>? id,
    Expression<String>? scanId,
    Expression<String>? dependencyName,
    Expression<String>? currentVersion,
    Expression<String>? fixedVersion,
    Expression<String>? cveId,
    Expression<String>? severity,
    Expression<String>? description,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      if (dependencyName != null) 'dependency_name': dependencyName,
      if (currentVersion != null) 'current_version': currentVersion,
      if (fixedVersion != null) 'fixed_version': fixedVersion,
      if (cveId != null) 'cve_id': cveId,
      if (severity != null) 'severity': severity,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DependencyVulnerabilitiesCompanion copyWith(
      {Value<String>? id,
      Value<String>? scanId,
      Value<String>? dependencyName,
      Value<String?>? currentVersion,
      Value<String?>? fixedVersion,
      Value<String?>? cveId,
      Value<String>? severity,
      Value<String?>? description,
      Value<String>? status,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return DependencyVulnerabilitiesCompanion(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      dependencyName: dependencyName ?? this.dependencyName,
      currentVersion: currentVersion ?? this.currentVersion,
      fixedVersion: fixedVersion ?? this.fixedVersion,
      cveId: cveId ?? this.cveId,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (dependencyName.present) {
      map['dependency_name'] = Variable<String>(dependencyName.value);
    }
    if (currentVersion.present) {
      map['current_version'] = Variable<String>(currentVersion.value);
    }
    if (fixedVersion.present) {
      map['fixed_version'] = Variable<String>(fixedVersion.value);
    }
    if (cveId.present) {
      map['cve_id'] = Variable<String>(cveId.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DependencyVulnerabilitiesCompanion(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('dependencyName: $dependencyName, ')
          ..write('currentVersion: $currentVersion, ')
          ..write('fixedVersion: $fixedVersion, ')
          ..write('cveId: $cveId, ')
          ..write('severity: $severity, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthSnapshotsTable extends HealthSnapshots
    with TableInfo<$HealthSnapshotsTable, HealthSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _healthScoreMeta =
      const VerificationMeta('healthScore');
  @override
  late final GeneratedColumn<int> healthScore = GeneratedColumn<int>(
      'health_score', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _findingsBySeverityMeta =
      const VerificationMeta('findingsBySeverity');
  @override
  late final GeneratedColumn<String> findingsBySeverity =
      GeneratedColumn<String>('findings_by_severity', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _techDebtScoreMeta =
      const VerificationMeta('techDebtScore');
  @override
  late final GeneratedColumn<int> techDebtScore = GeneratedColumn<int>(
      'tech_debt_score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dependencyScoreMeta =
      const VerificationMeta('dependencyScore');
  @override
  late final GeneratedColumn<int> dependencyScore = GeneratedColumn<int>(
      'dependency_score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _testCoveragePercentMeta =
      const VerificationMeta('testCoveragePercent');
  @override
  late final GeneratedColumn<double> testCoveragePercent =
      GeneratedColumn<double>('test_coverage_percent', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _capturedAtMeta =
      const VerificationMeta('capturedAt');
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
      'captured_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        jobId,
        healthScore,
        findingsBySeverity,
        techDebtScore,
        dependencyScore,
        testCoveragePercent,
        capturedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<HealthSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    }
    if (data.containsKey('health_score')) {
      context.handle(
          _healthScoreMeta,
          healthScore.isAcceptableOrUnknown(
              data['health_score']!, _healthScoreMeta));
    } else if (isInserting) {
      context.missing(_healthScoreMeta);
    }
    if (data.containsKey('findings_by_severity')) {
      context.handle(
          _findingsBySeverityMeta,
          findingsBySeverity.isAcceptableOrUnknown(
              data['findings_by_severity']!, _findingsBySeverityMeta));
    }
    if (data.containsKey('tech_debt_score')) {
      context.handle(
          _techDebtScoreMeta,
          techDebtScore.isAcceptableOrUnknown(
              data['tech_debt_score']!, _techDebtScoreMeta));
    }
    if (data.containsKey('dependency_score')) {
      context.handle(
          _dependencyScoreMeta,
          dependencyScore.isAcceptableOrUnknown(
              data['dependency_score']!, _dependencyScoreMeta));
    }
    if (data.containsKey('test_coverage_percent')) {
      context.handle(
          _testCoveragePercentMeta,
          testCoveragePercent.isAcceptableOrUnknown(
              data['test_coverage_percent']!, _testCoveragePercentMeta));
    }
    if (data.containsKey('captured_at')) {
      context.handle(
          _capturedAtMeta,
          capturedAt.isAcceptableOrUnknown(
              data['captured_at']!, _capturedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id']),
      healthScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}health_score'])!,
      findingsBySeverity: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}findings_by_severity']),
      techDebtScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tech_debt_score']),
      dependencyScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dependency_score']),
      testCoveragePercent: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}test_coverage_percent']),
      capturedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}captured_at']),
    );
  }

  @override
  $HealthSnapshotsTable createAlias(String alias) {
    return $HealthSnapshotsTable(attachedDatabase, alias);
  }
}

class HealthSnapshot extends DataClass implements Insertable<HealthSnapshot> {
  /// UUID primary key.
  final String id;

  /// Project UUID.
  final String projectId;

  /// Job UUID.
  final String? jobId;

  /// Health score (0-100).
  final int healthScore;

  /// JSON mapping severity to count.
  final String? findingsBySeverity;

  /// Tech debt score.
  final int? techDebtScore;

  /// Dependency health score.
  final int? dependencyScore;

  /// Test coverage percentage.
  final double? testCoveragePercent;

  /// Capture timestamp.
  final DateTime? capturedAt;
  const HealthSnapshot(
      {required this.id,
      required this.projectId,
      this.jobId,
      required this.healthScore,
      this.findingsBySeverity,
      this.techDebtScore,
      this.dependencyScore,
      this.testCoveragePercent,
      this.capturedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['health_score'] = Variable<int>(healthScore);
    if (!nullToAbsent || findingsBySeverity != null) {
      map['findings_by_severity'] = Variable<String>(findingsBySeverity);
    }
    if (!nullToAbsent || techDebtScore != null) {
      map['tech_debt_score'] = Variable<int>(techDebtScore);
    }
    if (!nullToAbsent || dependencyScore != null) {
      map['dependency_score'] = Variable<int>(dependencyScore);
    }
    if (!nullToAbsent || testCoveragePercent != null) {
      map['test_coverage_percent'] = Variable<double>(testCoveragePercent);
    }
    if (!nullToAbsent || capturedAt != null) {
      map['captured_at'] = Variable<DateTime>(capturedAt);
    }
    return map;
  }

  HealthSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return HealthSnapshotsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      healthScore: Value(healthScore),
      findingsBySeverity: findingsBySeverity == null && nullToAbsent
          ? const Value.absent()
          : Value(findingsBySeverity),
      techDebtScore: techDebtScore == null && nullToAbsent
          ? const Value.absent()
          : Value(techDebtScore),
      dependencyScore: dependencyScore == null && nullToAbsent
          ? const Value.absent()
          : Value(dependencyScore),
      testCoveragePercent: testCoveragePercent == null && nullToAbsent
          ? const Value.absent()
          : Value(testCoveragePercent),
      capturedAt: capturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedAt),
    );
  }

  factory HealthSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthSnapshot(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      healthScore: serializer.fromJson<int>(json['healthScore']),
      findingsBySeverity:
          serializer.fromJson<String?>(json['findingsBySeverity']),
      techDebtScore: serializer.fromJson<int?>(json['techDebtScore']),
      dependencyScore: serializer.fromJson<int?>(json['dependencyScore']),
      testCoveragePercent:
          serializer.fromJson<double?>(json['testCoveragePercent']),
      capturedAt: serializer.fromJson<DateTime?>(json['capturedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'jobId': serializer.toJson<String?>(jobId),
      'healthScore': serializer.toJson<int>(healthScore),
      'findingsBySeverity': serializer.toJson<String?>(findingsBySeverity),
      'techDebtScore': serializer.toJson<int?>(techDebtScore),
      'dependencyScore': serializer.toJson<int?>(dependencyScore),
      'testCoveragePercent': serializer.toJson<double?>(testCoveragePercent),
      'capturedAt': serializer.toJson<DateTime?>(capturedAt),
    };
  }

  HealthSnapshot copyWith(
          {String? id,
          String? projectId,
          Value<String?> jobId = const Value.absent(),
          int? healthScore,
          Value<String?> findingsBySeverity = const Value.absent(),
          Value<int?> techDebtScore = const Value.absent(),
          Value<int?> dependencyScore = const Value.absent(),
          Value<double?> testCoveragePercent = const Value.absent(),
          Value<DateTime?> capturedAt = const Value.absent()}) =>
      HealthSnapshot(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        jobId: jobId.present ? jobId.value : this.jobId,
        healthScore: healthScore ?? this.healthScore,
        findingsBySeverity: findingsBySeverity.present
            ? findingsBySeverity.value
            : this.findingsBySeverity,
        techDebtScore:
            techDebtScore.present ? techDebtScore.value : this.techDebtScore,
        dependencyScore: dependencyScore.present
            ? dependencyScore.value
            : this.dependencyScore,
        testCoveragePercent: testCoveragePercent.present
            ? testCoveragePercent.value
            : this.testCoveragePercent,
        capturedAt: capturedAt.present ? capturedAt.value : this.capturedAt,
      );
  HealthSnapshot copyWithCompanion(HealthSnapshotsCompanion data) {
    return HealthSnapshot(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      healthScore:
          data.healthScore.present ? data.healthScore.value : this.healthScore,
      findingsBySeverity: data.findingsBySeverity.present
          ? data.findingsBySeverity.value
          : this.findingsBySeverity,
      techDebtScore: data.techDebtScore.present
          ? data.techDebtScore.value
          : this.techDebtScore,
      dependencyScore: data.dependencyScore.present
          ? data.dependencyScore.value
          : this.dependencyScore,
      testCoveragePercent: data.testCoveragePercent.present
          ? data.testCoveragePercent.value
          : this.testCoveragePercent,
      capturedAt:
          data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthSnapshot(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('jobId: $jobId, ')
          ..write('healthScore: $healthScore, ')
          ..write('findingsBySeverity: $findingsBySeverity, ')
          ..write('techDebtScore: $techDebtScore, ')
          ..write('dependencyScore: $dependencyScore, ')
          ..write('testCoveragePercent: $testCoveragePercent, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      projectId,
      jobId,
      healthScore,
      findingsBySeverity,
      techDebtScore,
      dependencyScore,
      testCoveragePercent,
      capturedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthSnapshot &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.jobId == this.jobId &&
          other.healthScore == this.healthScore &&
          other.findingsBySeverity == this.findingsBySeverity &&
          other.techDebtScore == this.techDebtScore &&
          other.dependencyScore == this.dependencyScore &&
          other.testCoveragePercent == this.testCoveragePercent &&
          other.capturedAt == this.capturedAt);
}

class HealthSnapshotsCompanion extends UpdateCompanion<HealthSnapshot> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String?> jobId;
  final Value<int> healthScore;
  final Value<String?> findingsBySeverity;
  final Value<int?> techDebtScore;
  final Value<int?> dependencyScore;
  final Value<double?> testCoveragePercent;
  final Value<DateTime?> capturedAt;
  final Value<int> rowid;
  const HealthSnapshotsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.findingsBySeverity = const Value.absent(),
    this.techDebtScore = const Value.absent(),
    this.dependencyScore = const Value.absent(),
    this.testCoveragePercent = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthSnapshotsCompanion.insert({
    required String id,
    required String projectId,
    this.jobId = const Value.absent(),
    required int healthScore,
    this.findingsBySeverity = const Value.absent(),
    this.techDebtScore = const Value.absent(),
    this.dependencyScore = const Value.absent(),
    this.testCoveragePercent = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        healthScore = Value(healthScore);
  static Insertable<HealthSnapshot> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? jobId,
    Expression<int>? healthScore,
    Expression<String>? findingsBySeverity,
    Expression<int>? techDebtScore,
    Expression<int>? dependencyScore,
    Expression<double>? testCoveragePercent,
    Expression<DateTime>? capturedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (jobId != null) 'job_id': jobId,
      if (healthScore != null) 'health_score': healthScore,
      if (findingsBySeverity != null)
        'findings_by_severity': findingsBySeverity,
      if (techDebtScore != null) 'tech_debt_score': techDebtScore,
      if (dependencyScore != null) 'dependency_score': dependencyScore,
      if (testCoveragePercent != null)
        'test_coverage_percent': testCoveragePercent,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthSnapshotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String?>? jobId,
      Value<int>? healthScore,
      Value<String?>? findingsBySeverity,
      Value<int?>? techDebtScore,
      Value<int?>? dependencyScore,
      Value<double?>? testCoveragePercent,
      Value<DateTime?>? capturedAt,
      Value<int>? rowid}) {
    return HealthSnapshotsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      jobId: jobId ?? this.jobId,
      healthScore: healthScore ?? this.healthScore,
      findingsBySeverity: findingsBySeverity ?? this.findingsBySeverity,
      techDebtScore: techDebtScore ?? this.techDebtScore,
      dependencyScore: dependencyScore ?? this.dependencyScore,
      testCoveragePercent: testCoveragePercent ?? this.testCoveragePercent,
      capturedAt: capturedAt ?? this.capturedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (healthScore.present) {
      map['health_score'] = Variable<int>(healthScore.value);
    }
    if (findingsBySeverity.present) {
      map['findings_by_severity'] = Variable<String>(findingsBySeverity.value);
    }
    if (techDebtScore.present) {
      map['tech_debt_score'] = Variable<int>(techDebtScore.value);
    }
    if (dependencyScore.present) {
      map['dependency_score'] = Variable<int>(dependencyScore.value);
    }
    if (testCoveragePercent.present) {
      map['test_coverage_percent'] =
          Variable<double>(testCoveragePercent.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('jobId: $jobId, ')
          ..write('healthScore: $healthScore, ')
          ..write('findingsBySeverity: $findingsBySeverity, ')
          ..write('techDebtScore: $techDebtScore, ')
          ..write('dependencyScore: $dependencyScore, ')
          ..write('testCoveragePercent: $testCoveragePercent, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComplianceItemsTable extends ComplianceItems
    with TableInfo<$ComplianceItemsTable, ComplianceItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComplianceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requirementMeta =
      const VerificationMeta('requirement');
  @override
  late final GeneratedColumn<String> requirement = GeneratedColumn<String>(
      'requirement', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _specIdMeta = const VerificationMeta('specId');
  @override
  late final GeneratedColumn<String> specId = GeneratedColumn<String>(
      'spec_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specNameMeta =
      const VerificationMeta('specName');
  @override
  late final GeneratedColumn<String> specName = GeneratedColumn<String>(
      'spec_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _evidenceMeta =
      const VerificationMeta('evidence');
  @override
  late final GeneratedColumn<String> evidence = GeneratedColumn<String>(
      'evidence', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _agentTypeMeta =
      const VerificationMeta('agentType');
  @override
  late final GeneratedColumn<String> agentType = GeneratedColumn<String>(
      'agent_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobId,
        requirement,
        specId,
        specName,
        status,
        evidence,
        agentType,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'compliance_items';
  @override
  VerificationContext validateIntegrity(Insertable<ComplianceItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('requirement')) {
      context.handle(
          _requirementMeta,
          requirement.isAcceptableOrUnknown(
              data['requirement']!, _requirementMeta));
    } else if (isInserting) {
      context.missing(_requirementMeta);
    }
    if (data.containsKey('spec_id')) {
      context.handle(_specIdMeta,
          specId.isAcceptableOrUnknown(data['spec_id']!, _specIdMeta));
    }
    if (data.containsKey('spec_name')) {
      context.handle(_specNameMeta,
          specName.isAcceptableOrUnknown(data['spec_name']!, _specNameMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('evidence')) {
      context.handle(_evidenceMeta,
          evidence.isAcceptableOrUnknown(data['evidence']!, _evidenceMeta));
    }
    if (data.containsKey('agent_type')) {
      context.handle(_agentTypeMeta,
          agentType.isAcceptableOrUnknown(data['agent_type']!, _agentTypeMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ComplianceItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComplianceItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      requirement: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}requirement'])!,
      specId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}spec_id']),
      specName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}spec_name']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      evidence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evidence']),
      agentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_type']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $ComplianceItemsTable createAlias(String alias) {
    return $ComplianceItemsTable(attachedDatabase, alias);
  }
}

class ComplianceItem extends DataClass implements Insertable<ComplianceItem> {
  /// UUID primary key.
  final String id;

  /// Parent job UUID.
  final String jobId;

  /// Requirement text.
  final String requirement;

  /// Spec UUID.
  final String? specId;

  /// Spec name.
  final String? specName;

  /// Status (SCREAMING_SNAKE_CASE).
  final String status;

  /// Evidence.
  final String? evidence;

  /// Agent type (SCREAMING_SNAKE_CASE).
  final String? agentType;

  /// Notes.
  final String? notes;

  /// Creation timestamp.
  final DateTime? createdAt;
  const ComplianceItem(
      {required this.id,
      required this.jobId,
      required this.requirement,
      this.specId,
      this.specName,
      required this.status,
      this.evidence,
      this.agentType,
      this.notes,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['requirement'] = Variable<String>(requirement);
    if (!nullToAbsent || specId != null) {
      map['spec_id'] = Variable<String>(specId);
    }
    if (!nullToAbsent || specName != null) {
      map['spec_name'] = Variable<String>(specName);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || evidence != null) {
      map['evidence'] = Variable<String>(evidence);
    }
    if (!nullToAbsent || agentType != null) {
      map['agent_type'] = Variable<String>(agentType);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  ComplianceItemsCompanion toCompanion(bool nullToAbsent) {
    return ComplianceItemsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      requirement: Value(requirement),
      specId:
          specId == null && nullToAbsent ? const Value.absent() : Value(specId),
      specName: specName == null && nullToAbsent
          ? const Value.absent()
          : Value(specName),
      status: Value(status),
      evidence: evidence == null && nullToAbsent
          ? const Value.absent()
          : Value(evidence),
      agentType: agentType == null && nullToAbsent
          ? const Value.absent()
          : Value(agentType),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory ComplianceItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComplianceItem(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      requirement: serializer.fromJson<String>(json['requirement']),
      specId: serializer.fromJson<String?>(json['specId']),
      specName: serializer.fromJson<String?>(json['specName']),
      status: serializer.fromJson<String>(json['status']),
      evidence: serializer.fromJson<String?>(json['evidence']),
      agentType: serializer.fromJson<String?>(json['agentType']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'requirement': serializer.toJson<String>(requirement),
      'specId': serializer.toJson<String?>(specId),
      'specName': serializer.toJson<String?>(specName),
      'status': serializer.toJson<String>(status),
      'evidence': serializer.toJson<String?>(evidence),
      'agentType': serializer.toJson<String?>(agentType),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  ComplianceItem copyWith(
          {String? id,
          String? jobId,
          String? requirement,
          Value<String?> specId = const Value.absent(),
          Value<String?> specName = const Value.absent(),
          String? status,
          Value<String?> evidence = const Value.absent(),
          Value<String?> agentType = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<DateTime?> createdAt = const Value.absent()}) =>
      ComplianceItem(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        requirement: requirement ?? this.requirement,
        specId: specId.present ? specId.value : this.specId,
        specName: specName.present ? specName.value : this.specName,
        status: status ?? this.status,
        evidence: evidence.present ? evidence.value : this.evidence,
        agentType: agentType.present ? agentType.value : this.agentType,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  ComplianceItem copyWithCompanion(ComplianceItemsCompanion data) {
    return ComplianceItem(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      requirement:
          data.requirement.present ? data.requirement.value : this.requirement,
      specId: data.specId.present ? data.specId.value : this.specId,
      specName: data.specName.present ? data.specName.value : this.specName,
      status: data.status.present ? data.status.value : this.status,
      evidence: data.evidence.present ? data.evidence.value : this.evidence,
      agentType: data.agentType.present ? data.agentType.value : this.agentType,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComplianceItem(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('requirement: $requirement, ')
          ..write('specId: $specId, ')
          ..write('specName: $specName, ')
          ..write('status: $status, ')
          ..write('evidence: $evidence, ')
          ..write('agentType: $agentType, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jobId, requirement, specId, specName,
      status, evidence, agentType, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComplianceItem &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.requirement == this.requirement &&
          other.specId == this.specId &&
          other.specName == this.specName &&
          other.status == this.status &&
          other.evidence == this.evidence &&
          other.agentType == this.agentType &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class ComplianceItemsCompanion extends UpdateCompanion<ComplianceItem> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<String> requirement;
  final Value<String?> specId;
  final Value<String?> specName;
  final Value<String> status;
  final Value<String?> evidence;
  final Value<String?> agentType;
  final Value<String?> notes;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const ComplianceItemsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.requirement = const Value.absent(),
    this.specId = const Value.absent(),
    this.specName = const Value.absent(),
    this.status = const Value.absent(),
    this.evidence = const Value.absent(),
    this.agentType = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComplianceItemsCompanion.insert({
    required String id,
    required String jobId,
    required String requirement,
    this.specId = const Value.absent(),
    this.specName = const Value.absent(),
    required String status,
    this.evidence = const Value.absent(),
    this.agentType = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        jobId = Value(jobId),
        requirement = Value(requirement),
        status = Value(status);
  static Insertable<ComplianceItem> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? requirement,
    Expression<String>? specId,
    Expression<String>? specName,
    Expression<String>? status,
    Expression<String>? evidence,
    Expression<String>? agentType,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (requirement != null) 'requirement': requirement,
      if (specId != null) 'spec_id': specId,
      if (specName != null) 'spec_name': specName,
      if (status != null) 'status': status,
      if (evidence != null) 'evidence': evidence,
      if (agentType != null) 'agent_type': agentType,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComplianceItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? jobId,
      Value<String>? requirement,
      Value<String?>? specId,
      Value<String?>? specName,
      Value<String>? status,
      Value<String?>? evidence,
      Value<String?>? agentType,
      Value<String?>? notes,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return ComplianceItemsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      requirement: requirement ?? this.requirement,
      specId: specId ?? this.specId,
      specName: specName ?? this.specName,
      status: status ?? this.status,
      evidence: evidence ?? this.evidence,
      agentType: agentType ?? this.agentType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (requirement.present) {
      map['requirement'] = Variable<String>(requirement.value);
    }
    if (specId.present) {
      map['spec_id'] = Variable<String>(specId.value);
    }
    if (specName.present) {
      map['spec_name'] = Variable<String>(specName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (evidence.present) {
      map['evidence'] = Variable<String>(evidence.value);
    }
    if (agentType.present) {
      map['agent_type'] = Variable<String>(agentType.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComplianceItemsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('requirement: $requirement, ')
          ..write('specId: $specId, ')
          ..write('specName: $specName, ')
          ..write('status: $status, ')
          ..write('evidence: $evidence, ')
          ..write('agentType: $agentType, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpecificationsTable extends Specifications
    with TableInfo<$SpecificationsTable, Specification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpecificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _specTypeMeta =
      const VerificationMeta('specType');
  @override
  late final GeneratedColumn<String> specType = GeneratedColumn<String>(
      'spec_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _s3KeyMeta = const VerificationMeta('s3Key');
  @override
  late final GeneratedColumn<String> s3Key = GeneratedColumn<String>(
      's3_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, jobId, name, specType, s3Key, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'specifications';
  @override
  VerificationContext validateIntegrity(Insertable<Specification> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('spec_type')) {
      context.handle(_specTypeMeta,
          specType.isAcceptableOrUnknown(data['spec_type']!, _specTypeMeta));
    }
    if (data.containsKey('s3_key')) {
      context.handle(
          _s3KeyMeta, s3Key.isAcceptableOrUnknown(data['s3_key']!, _s3KeyMeta));
    } else if (isInserting) {
      context.missing(_s3KeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Specification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Specification(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      specType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}spec_type']),
      s3Key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}s3_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $SpecificationsTable createAlias(String alias) {
    return $SpecificationsTable(attachedDatabase, alias);
  }
}

class Specification extends DataClass implements Insertable<Specification> {
  /// UUID primary key.
  final String id;

  /// Parent job UUID.
  final String jobId;

  /// Specification name.
  final String name;

  /// Spec type (SCREAMING_SNAKE_CASE).
  final String? specType;

  /// S3 key.
  final String s3Key;

  /// Creation timestamp.
  final DateTime? createdAt;
  const Specification(
      {required this.id,
      required this.jobId,
      required this.name,
      this.specType,
      required this.s3Key,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || specType != null) {
      map['spec_type'] = Variable<String>(specType);
    }
    map['s3_key'] = Variable<String>(s3Key);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  SpecificationsCompanion toCompanion(bool nullToAbsent) {
    return SpecificationsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      name: Value(name),
      specType: specType == null && nullToAbsent
          ? const Value.absent()
          : Value(specType),
      s3Key: Value(s3Key),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Specification.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Specification(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      name: serializer.fromJson<String>(json['name']),
      specType: serializer.fromJson<String?>(json['specType']),
      s3Key: serializer.fromJson<String>(json['s3Key']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'name': serializer.toJson<String>(name),
      'specType': serializer.toJson<String?>(specType),
      's3Key': serializer.toJson<String>(s3Key),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  Specification copyWith(
          {String? id,
          String? jobId,
          String? name,
          Value<String?> specType = const Value.absent(),
          String? s3Key,
          Value<DateTime?> createdAt = const Value.absent()}) =>
      Specification(
        id: id ?? this.id,
        jobId: jobId ?? this.jobId,
        name: name ?? this.name,
        specType: specType.present ? specType.value : this.specType,
        s3Key: s3Key ?? this.s3Key,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  Specification copyWithCompanion(SpecificationsCompanion data) {
    return Specification(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      name: data.name.present ? data.name.value : this.name,
      specType: data.specType.present ? data.specType.value : this.specType,
      s3Key: data.s3Key.present ? data.s3Key.value : this.s3Key,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Specification(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('name: $name, ')
          ..write('specType: $specType, ')
          ..write('s3Key: $s3Key, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jobId, name, specType, s3Key, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Specification &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.name == this.name &&
          other.specType == this.specType &&
          other.s3Key == this.s3Key &&
          other.createdAt == this.createdAt);
}

class SpecificationsCompanion extends UpdateCompanion<Specification> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<String> name;
  final Value<String?> specType;
  final Value<String> s3Key;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const SpecificationsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.name = const Value.absent(),
    this.specType = const Value.absent(),
    this.s3Key = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpecificationsCompanion.insert({
    required String id,
    required String jobId,
    required String name,
    this.specType = const Value.absent(),
    required String s3Key,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        jobId = Value(jobId),
        name = Value(name),
        s3Key = Value(s3Key);
  static Insertable<Specification> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? name,
    Expression<String>? specType,
    Expression<String>? s3Key,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (name != null) 'name': name,
      if (specType != null) 'spec_type': specType,
      if (s3Key != null) 's3_key': s3Key,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpecificationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? jobId,
      Value<String>? name,
      Value<String?>? specType,
      Value<String>? s3Key,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return SpecificationsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      name: name ?? this.name,
      specType: specType ?? this.specType,
      s3Key: s3Key ?? this.s3Key,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (specType.present) {
      map['spec_type'] = Variable<String>(specType.value);
    }
    if (s3Key.present) {
      map['s3_key'] = Variable<String>(s3Key.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpecificationsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('name: $name, ')
          ..write('specType: $specType, ')
          ..write('s3Key: $s3Key, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncTableNameMeta =
      const VerificationMeta('syncTableName');
  @override
  late final GeneratedColumn<String> syncTableName = GeneratedColumn<String>(
      'sync_table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
      'etag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [syncTableName, lastSyncAt, etag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_table_name')) {
      context.handle(
          _syncTableNameMeta,
          syncTableName.isAcceptableOrUnknown(
              data['sync_table_name']!, _syncTableNameMeta));
    } else if (isInserting) {
      context.missing(_syncTableNameMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    } else if (isInserting) {
      context.missing(_lastSyncAtMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
          _etagMeta, etag.isAcceptableOrUnknown(data['etag']!, _etagMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {syncTableName};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      syncTableName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sync_table_name'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at'])!,
      etag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}etag']),
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  /// Synced table name as primary key.
  final String syncTableName;

  /// Last synchronization timestamp.
  final DateTime lastSyncAt;

  /// Optional ETag for conditional requests.
  final String? etag;
  const SyncMetadataData(
      {required this.syncTableName, required this.lastSyncAt, this.etag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sync_table_name'] = Variable<String>(syncTableName);
    map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      syncTableName: Value(syncTableName),
      lastSyncAt: Value(lastSyncAt),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory SyncMetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      syncTableName: serializer.fromJson<String>(json['syncTableName']),
      lastSyncAt: serializer.fromJson<DateTime>(json['lastSyncAt']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncTableName': serializer.toJson<String>(syncTableName),
      'lastSyncAt': serializer.toJson<DateTime>(lastSyncAt),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  SyncMetadataData copyWith(
          {String? syncTableName,
          DateTime? lastSyncAt,
          Value<String?> etag = const Value.absent()}) =>
      SyncMetadataData(
        syncTableName: syncTableName ?? this.syncTableName,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        etag: etag.present ? etag.value : this.etag,
      );
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      syncTableName: data.syncTableName.present
          ? data.syncTableName.value
          : this.syncTableName,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('syncTableName: $syncTableName, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(syncTableName, lastSyncAt, etag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.syncTableName == this.syncTableName &&
          other.lastSyncAt == this.lastSyncAt &&
          other.etag == this.etag);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<String> syncTableName;
  final Value<DateTime> lastSyncAt;
  final Value<String?> etag;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.syncTableName = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String syncTableName,
    required DateTime lastSyncAt,
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : syncTableName = Value(syncTableName),
        lastSyncAt = Value(lastSyncAt);
  static Insertable<SyncMetadataData> custom({
    Expression<String>? syncTableName,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? etag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (syncTableName != null) 'sync_table_name': syncTableName,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (etag != null) 'etag': etag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith(
      {Value<String>? syncTableName,
      Value<DateTime>? lastSyncAt,
      Value<String?>? etag,
      Value<int>? rowid}) {
    return SyncMetadataCompanion(
      syncTableName: syncTableName ?? this.syncTableName,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      etag: etag ?? this.etag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncTableName.present) {
      map['sync_table_name'] = Variable<String>(syncTableName.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('syncTableName: $syncTableName, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('etag: $etag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClonedReposTable extends ClonedRepos
    with TableInfo<$ClonedReposTable, ClonedRepo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClonedReposTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _repoFullNameMeta =
      const VerificationMeta('repoFullName');
  @override
  late final GeneratedColumn<String> repoFullName = GeneratedColumn<String>(
      'repo_full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clonedAtMeta =
      const VerificationMeta('clonedAt');
  @override
  late final GeneratedColumn<DateTime> clonedAt = GeneratedColumn<DateTime>(
      'cloned_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastAccessedAtMeta =
      const VerificationMeta('lastAccessedAt');
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>('last_accessed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [repoFullName, localPath, projectId, clonedAt, lastAccessedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloned_repos';
  @override
  VerificationContext validateIntegrity(Insertable<ClonedRepo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('repo_full_name')) {
      context.handle(
          _repoFullNameMeta,
          repoFullName.isAcceptableOrUnknown(
              data['repo_full_name']!, _repoFullNameMeta));
    } else if (isInserting) {
      context.missing(_repoFullNameMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('cloned_at')) {
      context.handle(_clonedAtMeta,
          clonedAt.isAcceptableOrUnknown(data['cloned_at']!, _clonedAtMeta));
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
          _lastAccessedAtMeta,
          lastAccessedAt.isAcceptableOrUnknown(
              data['last_accessed_at']!, _lastAccessedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {repoFullName};
  @override
  ClonedRepo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClonedRepo(
      repoFullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repo_full_name'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id']),
      clonedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cloned_at']),
      lastAccessedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed_at']),
    );
  }

  @override
  $ClonedReposTable createAlias(String alias) {
    return $ClonedReposTable(attachedDatabase, alias);
  }
}

class ClonedRepo extends DataClass implements Insertable<ClonedRepo> {
  /// Full repository name (owner/repo) as primary key.
  final String repoFullName;

  /// Absolute path on the local filesystem.
  final String localPath;

  /// Optional associated project UUID.
  final String? projectId;

  /// Timestamp when the repo was cloned.
  final DateTime? clonedAt;

  /// Timestamp of the last access.
  final DateTime? lastAccessedAt;
  const ClonedRepo(
      {required this.repoFullName,
      required this.localPath,
      this.projectId,
      this.clonedAt,
      this.lastAccessedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['repo_full_name'] = Variable<String>(repoFullName);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || clonedAt != null) {
      map['cloned_at'] = Variable<DateTime>(clonedAt);
    }
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    return map;
  }

  ClonedReposCompanion toCompanion(bool nullToAbsent) {
    return ClonedReposCompanion(
      repoFullName: Value(repoFullName),
      localPath: Value(localPath),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      clonedAt: clonedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(clonedAt),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
    );
  }

  factory ClonedRepo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClonedRepo(
      repoFullName: serializer.fromJson<String>(json['repoFullName']),
      localPath: serializer.fromJson<String>(json['localPath']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      clonedAt: serializer.fromJson<DateTime?>(json['clonedAt']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'repoFullName': serializer.toJson<String>(repoFullName),
      'localPath': serializer.toJson<String>(localPath),
      'projectId': serializer.toJson<String?>(projectId),
      'clonedAt': serializer.toJson<DateTime?>(clonedAt),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
    };
  }

  ClonedRepo copyWith(
          {String? repoFullName,
          String? localPath,
          Value<String?> projectId = const Value.absent(),
          Value<DateTime?> clonedAt = const Value.absent(),
          Value<DateTime?> lastAccessedAt = const Value.absent()}) =>
      ClonedRepo(
        repoFullName: repoFullName ?? this.repoFullName,
        localPath: localPath ?? this.localPath,
        projectId: projectId.present ? projectId.value : this.projectId,
        clonedAt: clonedAt.present ? clonedAt.value : this.clonedAt,
        lastAccessedAt:
            lastAccessedAt.present ? lastAccessedAt.value : this.lastAccessedAt,
      );
  ClonedRepo copyWithCompanion(ClonedReposCompanion data) {
    return ClonedRepo(
      repoFullName: data.repoFullName.present
          ? data.repoFullName.value
          : this.repoFullName,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      clonedAt: data.clonedAt.present ? data.clonedAt.value : this.clonedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClonedRepo(')
          ..write('repoFullName: $repoFullName, ')
          ..write('localPath: $localPath, ')
          ..write('projectId: $projectId, ')
          ..write('clonedAt: $clonedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(repoFullName, localPath, projectId, clonedAt, lastAccessedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClonedRepo &&
          other.repoFullName == this.repoFullName &&
          other.localPath == this.localPath &&
          other.projectId == this.projectId &&
          other.clonedAt == this.clonedAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class ClonedReposCompanion extends UpdateCompanion<ClonedRepo> {
  final Value<String> repoFullName;
  final Value<String> localPath;
  final Value<String?> projectId;
  final Value<DateTime?> clonedAt;
  final Value<DateTime?> lastAccessedAt;
  final Value<int> rowid;
  const ClonedReposCompanion({
    this.repoFullName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.projectId = const Value.absent(),
    this.clonedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClonedReposCompanion.insert({
    required String repoFullName,
    required String localPath,
    this.projectId = const Value.absent(),
    this.clonedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : repoFullName = Value(repoFullName),
        localPath = Value(localPath);
  static Insertable<ClonedRepo> custom({
    Expression<String>? repoFullName,
    Expression<String>? localPath,
    Expression<String>? projectId,
    Expression<DateTime>? clonedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (repoFullName != null) 'repo_full_name': repoFullName,
      if (localPath != null) 'local_path': localPath,
      if (projectId != null) 'project_id': projectId,
      if (clonedAt != null) 'cloned_at': clonedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClonedReposCompanion copyWith(
      {Value<String>? repoFullName,
      Value<String>? localPath,
      Value<String?>? projectId,
      Value<DateTime?>? clonedAt,
      Value<DateTime?>? lastAccessedAt,
      Value<int>? rowid}) {
    return ClonedReposCompanion(
      repoFullName: repoFullName ?? this.repoFullName,
      localPath: localPath ?? this.localPath,
      projectId: projectId ?? this.projectId,
      clonedAt: clonedAt ?? this.clonedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (repoFullName.present) {
      map['repo_full_name'] = Variable<String>(repoFullName.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (clonedAt.present) {
      map['cloned_at'] = Variable<DateTime>(clonedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClonedReposCompanion(')
          ..write('repoFullName: $repoFullName, ')
          ..write('localPath: $localPath, ')
          ..write('projectId: $projectId, ')
          ..write('clonedAt: $clonedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnthropicModelsTable extends AnthropicModels
    with TableInfo<$AnthropicModelsTable, AnthropicModel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnthropicModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelFamilyMeta =
      const VerificationMeta('modelFamily');
  @override
  late final GeneratedColumn<String> modelFamily = GeneratedColumn<String>(
      'model_family', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contextWindowMeta =
      const VerificationMeta('contextWindow');
  @override
  late final GeneratedColumn<int> contextWindow = GeneratedColumn<int>(
      'context_window', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxOutputTokensMeta =
      const VerificationMeta('maxOutputTokens');
  @override
  late final GeneratedColumn<int> maxOutputTokens = GeneratedColumn<int>(
      'max_output_tokens', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, displayName, modelFamily, contextWindow, maxOutputTokens, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anthropic_models';
  @override
  VerificationContext validateIntegrity(Insertable<AnthropicModel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('model_family')) {
      context.handle(
          _modelFamilyMeta,
          modelFamily.isAcceptableOrUnknown(
              data['model_family']!, _modelFamilyMeta));
    }
    if (data.containsKey('context_window')) {
      context.handle(
          _contextWindowMeta,
          contextWindow.isAcceptableOrUnknown(
              data['context_window']!, _contextWindowMeta));
    }
    if (data.containsKey('max_output_tokens')) {
      context.handle(
          _maxOutputTokensMeta,
          maxOutputTokens.isAcceptableOrUnknown(
              data['max_output_tokens']!, _maxOutputTokensMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnthropicModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnthropicModel(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      modelFamily: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_family']),
      contextWindow: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}context_window']),
      maxOutputTokens: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_output_tokens']),
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $AnthropicModelsTable createAlias(String alias) {
    return $AnthropicModelsTable(attachedDatabase, alias);
  }
}

class AnthropicModel extends DataClass implements Insertable<AnthropicModel> {
  /// Model identifier (e.g. "claude-sonnet-4-20250514").
  final String id;

  /// Human-readable display name.
  final String displayName;

  /// Model family grouping (e.g. "claude-4").
  final String? modelFamily;

  /// Maximum input context window in tokens.
  final int? contextWindow;

  /// Maximum output tokens the model can generate.
  final int? maxOutputTokens;

  /// Timestamp when this model was fetched from the API.
  final DateTime fetchedAt;
  const AnthropicModel(
      {required this.id,
      required this.displayName,
      this.modelFamily,
      this.contextWindow,
      this.maxOutputTokens,
      required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || modelFamily != null) {
      map['model_family'] = Variable<String>(modelFamily);
    }
    if (!nullToAbsent || contextWindow != null) {
      map['context_window'] = Variable<int>(contextWindow);
    }
    if (!nullToAbsent || maxOutputTokens != null) {
      map['max_output_tokens'] = Variable<int>(maxOutputTokens);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  AnthropicModelsCompanion toCompanion(bool nullToAbsent) {
    return AnthropicModelsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      modelFamily: modelFamily == null && nullToAbsent
          ? const Value.absent()
          : Value(modelFamily),
      contextWindow: contextWindow == null && nullToAbsent
          ? const Value.absent()
          : Value(contextWindow),
      maxOutputTokens: maxOutputTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(maxOutputTokens),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory AnthropicModel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnthropicModel(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      modelFamily: serializer.fromJson<String?>(json['modelFamily']),
      contextWindow: serializer.fromJson<int?>(json['contextWindow']),
      maxOutputTokens: serializer.fromJson<int?>(json['maxOutputTokens']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'modelFamily': serializer.toJson<String?>(modelFamily),
      'contextWindow': serializer.toJson<int?>(contextWindow),
      'maxOutputTokens': serializer.toJson<int?>(maxOutputTokens),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  AnthropicModel copyWith(
          {String? id,
          String? displayName,
          Value<String?> modelFamily = const Value.absent(),
          Value<int?> contextWindow = const Value.absent(),
          Value<int?> maxOutputTokens = const Value.absent(),
          DateTime? fetchedAt}) =>
      AnthropicModel(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        modelFamily: modelFamily.present ? modelFamily.value : this.modelFamily,
        contextWindow:
            contextWindow.present ? contextWindow.value : this.contextWindow,
        maxOutputTokens: maxOutputTokens.present
            ? maxOutputTokens.value
            : this.maxOutputTokens,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  AnthropicModel copyWithCompanion(AnthropicModelsCompanion data) {
    return AnthropicModel(
      id: data.id.present ? data.id.value : this.id,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      modelFamily:
          data.modelFamily.present ? data.modelFamily.value : this.modelFamily,
      contextWindow: data.contextWindow.present
          ? data.contextWindow.value
          : this.contextWindow,
      maxOutputTokens: data.maxOutputTokens.present
          ? data.maxOutputTokens.value
          : this.maxOutputTokens,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnthropicModel(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('modelFamily: $modelFamily, ')
          ..write('contextWindow: $contextWindow, ')
          ..write('maxOutputTokens: $maxOutputTokens, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, displayName, modelFamily, contextWindow, maxOutputTokens, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnthropicModel &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.modelFamily == this.modelFamily &&
          other.contextWindow == this.contextWindow &&
          other.maxOutputTokens == this.maxOutputTokens &&
          other.fetchedAt == this.fetchedAt);
}

class AnthropicModelsCompanion extends UpdateCompanion<AnthropicModel> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String?> modelFamily;
  final Value<int?> contextWindow;
  final Value<int?> maxOutputTokens;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const AnthropicModelsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.modelFamily = const Value.absent(),
    this.contextWindow = const Value.absent(),
    this.maxOutputTokens = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnthropicModelsCompanion.insert({
    required String id,
    required String displayName,
    this.modelFamily = const Value.absent(),
    this.contextWindow = const Value.absent(),
    this.maxOutputTokens = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        displayName = Value(displayName),
        fetchedAt = Value(fetchedAt);
  static Insertable<AnthropicModel> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? modelFamily,
    Expression<int>? contextWindow,
    Expression<int>? maxOutputTokens,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (modelFamily != null) 'model_family': modelFamily,
      if (contextWindow != null) 'context_window': contextWindow,
      if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnthropicModelsCompanion copyWith(
      {Value<String>? id,
      Value<String>? displayName,
      Value<String?>? modelFamily,
      Value<int?>? contextWindow,
      Value<int?>? maxOutputTokens,
      Value<DateTime>? fetchedAt,
      Value<int>? rowid}) {
    return AnthropicModelsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      modelFamily: modelFamily ?? this.modelFamily,
      contextWindow: contextWindow ?? this.contextWindow,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (modelFamily.present) {
      map['model_family'] = Variable<String>(modelFamily.value);
    }
    if (contextWindow.present) {
      map['context_window'] = Variable<int>(contextWindow.value);
    }
    if (maxOutputTokens.present) {
      map['max_output_tokens'] = Variable<int>(maxOutputTokens.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnthropicModelsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('modelFamily: $modelFamily, ')
          ..write('contextWindow: $contextWindow, ')
          ..write('maxOutputTokens: $maxOutputTokens, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentDefinitionsTable extends AgentDefinitions
    with TableInfo<$AgentDefinitionsTable, AgentDefinition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentTypeMeta =
      const VerificationMeta('agentType');
  @override
  late final GeneratedColumn<String> agentType = GeneratedColumn<String>(
      'agent_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isQaManagerMeta =
      const VerificationMeta('isQaManager');
  @override
  late final GeneratedColumn<bool> isQaManager = GeneratedColumn<bool>(
      'is_qa_manager', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_qa_manager" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isBuiltInMeta =
      const VerificationMeta('isBuiltIn');
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
      'is_built_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_built_in" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _modelIdMeta =
      const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
      'model_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _temperatureMeta =
      const VerificationMeta('temperature');
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
      'temperature', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _maxRetriesMeta =
      const VerificationMeta('maxRetries');
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
      'max_retries', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _timeoutMinutesMeta =
      const VerificationMeta('timeoutMinutes');
  @override
  late final GeneratedColumn<int> timeoutMinutes = GeneratedColumn<int>(
      'timeout_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxTurnsMeta =
      const VerificationMeta('maxTurns');
  @override
  late final GeneratedColumn<int> maxTurns = GeneratedColumn<int>(
      'max_turns', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(50));
  static const VerificationMeta _systemPromptOverrideMeta =
      const VerificationMeta('systemPromptOverride');
  @override
  late final GeneratedColumn<String> systemPromptOverride =
      GeneratedColumn<String>('system_prompt_override', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        agentType,
        isQaManager,
        isBuiltIn,
        isEnabled,
        modelId,
        temperature,
        maxRetries,
        timeoutMinutes,
        maxTurns,
        systemPromptOverride,
        description,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_definitions';
  @override
  VerificationContext validateIntegrity(Insertable<AgentDefinition> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('agent_type')) {
      context.handle(_agentTypeMeta,
          agentType.isAcceptableOrUnknown(data['agent_type']!, _agentTypeMeta));
    }
    if (data.containsKey('is_qa_manager')) {
      context.handle(
          _isQaManagerMeta,
          isQaManager.isAcceptableOrUnknown(
              data['is_qa_manager']!, _isQaManagerMeta));
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
          _isBuiltInMeta,
          isBuiltIn.isAcceptableOrUnknown(
              data['is_built_in']!, _isBuiltInMeta));
    }
    if (data.containsKey('is_enabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta));
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta,
          modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    }
    if (data.containsKey('temperature')) {
      context.handle(
          _temperatureMeta,
          temperature.isAcceptableOrUnknown(
              data['temperature']!, _temperatureMeta));
    }
    if (data.containsKey('max_retries')) {
      context.handle(
          _maxRetriesMeta,
          maxRetries.isAcceptableOrUnknown(
              data['max_retries']!, _maxRetriesMeta));
    }
    if (data.containsKey('timeout_minutes')) {
      context.handle(
          _timeoutMinutesMeta,
          timeoutMinutes.isAcceptableOrUnknown(
              data['timeout_minutes']!, _timeoutMinutesMeta));
    }
    if (data.containsKey('max_turns')) {
      context.handle(_maxTurnsMeta,
          maxTurns.isAcceptableOrUnknown(data['max_turns']!, _maxTurnsMeta));
    }
    if (data.containsKey('system_prompt_override')) {
      context.handle(
          _systemPromptOverrideMeta,
          systemPromptOverride.isAcceptableOrUnknown(
              data['system_prompt_override']!, _systemPromptOverrideMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentDefinition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentDefinition(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      agentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_type']),
      isQaManager: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_qa_manager'])!,
      isBuiltIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_built_in'])!,
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
      modelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_id']),
      temperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature'])!,
      maxRetries: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_retries'])!,
      timeoutMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timeout_minutes']),
      maxTurns: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_turns'])!,
      systemPromptOverride: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}system_prompt_override']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AgentDefinitionsTable createAlias(String alias) {
    return $AgentDefinitionsTable(attachedDatabase, alias);
  }
}

class AgentDefinition extends DataClass implements Insertable<AgentDefinition> {
  /// UUID primary key.
  final String id;

  /// Agent display name.
  final String name;

  /// Agent type enum value (SCREAMING_SNAKE_CASE).
  final String? agentType;

  /// Whether this agent serves as the QA manager (Vera).
  final bool isQaManager;

  /// Whether this is a built-in agent (cannot be deleted).
  final bool isBuiltIn;

  /// Whether this agent is enabled for dispatch.
  final bool isEnabled;

  /// Override model ID for this agent (null = use system default).
  final String? modelId;

  /// Temperature setting for this agent (0.0–1.0).
  final double temperature;

  /// Maximum retry attempts on failure.
  final int maxRetries;

  /// Timeout override in minutes (null = use system default).
  final int? timeoutMinutes;

  /// Maximum agentic turns allowed.
  final int maxTurns;

  /// Optional system prompt override markdown.
  final String? systemPromptOverride;

  /// Human-readable description of the agent.
  final String? description;

  /// Display sort order.
  final int sortOrder;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;
  const AgentDefinition(
      {required this.id,
      required this.name,
      this.agentType,
      required this.isQaManager,
      required this.isBuiltIn,
      required this.isEnabled,
      this.modelId,
      required this.temperature,
      required this.maxRetries,
      this.timeoutMinutes,
      required this.maxTurns,
      this.systemPromptOverride,
      this.description,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || agentType != null) {
      map['agent_type'] = Variable<String>(agentType);
    }
    map['is_qa_manager'] = Variable<bool>(isQaManager);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['is_enabled'] = Variable<bool>(isEnabled);
    if (!nullToAbsent || modelId != null) {
      map['model_id'] = Variable<String>(modelId);
    }
    map['temperature'] = Variable<double>(temperature);
    map['max_retries'] = Variable<int>(maxRetries);
    if (!nullToAbsent || timeoutMinutes != null) {
      map['timeout_minutes'] = Variable<int>(timeoutMinutes);
    }
    map['max_turns'] = Variable<int>(maxTurns);
    if (!nullToAbsent || systemPromptOverride != null) {
      map['system_prompt_override'] = Variable<String>(systemPromptOverride);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AgentDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return AgentDefinitionsCompanion(
      id: Value(id),
      name: Value(name),
      agentType: agentType == null && nullToAbsent
          ? const Value.absent()
          : Value(agentType),
      isQaManager: Value(isQaManager),
      isBuiltIn: Value(isBuiltIn),
      isEnabled: Value(isEnabled),
      modelId: modelId == null && nullToAbsent
          ? const Value.absent()
          : Value(modelId),
      temperature: Value(temperature),
      maxRetries: Value(maxRetries),
      timeoutMinutes: timeoutMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(timeoutMinutes),
      maxTurns: Value(maxTurns),
      systemPromptOverride: systemPromptOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(systemPromptOverride),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AgentDefinition.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentDefinition(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      agentType: serializer.fromJson<String?>(json['agentType']),
      isQaManager: serializer.fromJson<bool>(json['isQaManager']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      modelId: serializer.fromJson<String?>(json['modelId']),
      temperature: serializer.fromJson<double>(json['temperature']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
      timeoutMinutes: serializer.fromJson<int?>(json['timeoutMinutes']),
      maxTurns: serializer.fromJson<int>(json['maxTurns']),
      systemPromptOverride:
          serializer.fromJson<String?>(json['systemPromptOverride']),
      description: serializer.fromJson<String?>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'agentType': serializer.toJson<String?>(agentType),
      'isQaManager': serializer.toJson<bool>(isQaManager),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'modelId': serializer.toJson<String?>(modelId),
      'temperature': serializer.toJson<double>(temperature),
      'maxRetries': serializer.toJson<int>(maxRetries),
      'timeoutMinutes': serializer.toJson<int?>(timeoutMinutes),
      'maxTurns': serializer.toJson<int>(maxTurns),
      'systemPromptOverride': serializer.toJson<String?>(systemPromptOverride),
      'description': serializer.toJson<String?>(description),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AgentDefinition copyWith(
          {String? id,
          String? name,
          Value<String?> agentType = const Value.absent(),
          bool? isQaManager,
          bool? isBuiltIn,
          bool? isEnabled,
          Value<String?> modelId = const Value.absent(),
          double? temperature,
          int? maxRetries,
          Value<int?> timeoutMinutes = const Value.absent(),
          int? maxTurns,
          Value<String?> systemPromptOverride = const Value.absent(),
          Value<String?> description = const Value.absent(),
          int? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AgentDefinition(
        id: id ?? this.id,
        name: name ?? this.name,
        agentType: agentType.present ? agentType.value : this.agentType,
        isQaManager: isQaManager ?? this.isQaManager,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        isEnabled: isEnabled ?? this.isEnabled,
        modelId: modelId.present ? modelId.value : this.modelId,
        temperature: temperature ?? this.temperature,
        maxRetries: maxRetries ?? this.maxRetries,
        timeoutMinutes:
            timeoutMinutes.present ? timeoutMinutes.value : this.timeoutMinutes,
        maxTurns: maxTurns ?? this.maxTurns,
        systemPromptOverride: systemPromptOverride.present
            ? systemPromptOverride.value
            : this.systemPromptOverride,
        description: description.present ? description.value : this.description,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AgentDefinition copyWithCompanion(AgentDefinitionsCompanion data) {
    return AgentDefinition(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      agentType: data.agentType.present ? data.agentType.value : this.agentType,
      isQaManager:
          data.isQaManager.present ? data.isQaManager.value : this.isQaManager,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      temperature:
          data.temperature.present ? data.temperature.value : this.temperature,
      maxRetries:
          data.maxRetries.present ? data.maxRetries.value : this.maxRetries,
      timeoutMinutes: data.timeoutMinutes.present
          ? data.timeoutMinutes.value
          : this.timeoutMinutes,
      maxTurns: data.maxTurns.present ? data.maxTurns.value : this.maxTurns,
      systemPromptOverride: data.systemPromptOverride.present
          ? data.systemPromptOverride.value
          : this.systemPromptOverride,
      description:
          data.description.present ? data.description.value : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentDefinition(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('agentType: $agentType, ')
          ..write('isQaManager: $isQaManager, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('modelId: $modelId, ')
          ..write('temperature: $temperature, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('timeoutMinutes: $timeoutMinutes, ')
          ..write('maxTurns: $maxTurns, ')
          ..write('systemPromptOverride: $systemPromptOverride, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      agentType,
      isQaManager,
      isBuiltIn,
      isEnabled,
      modelId,
      temperature,
      maxRetries,
      timeoutMinutes,
      maxTurns,
      systemPromptOverride,
      description,
      sortOrder,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentDefinition &&
          other.id == this.id &&
          other.name == this.name &&
          other.agentType == this.agentType &&
          other.isQaManager == this.isQaManager &&
          other.isBuiltIn == this.isBuiltIn &&
          other.isEnabled == this.isEnabled &&
          other.modelId == this.modelId &&
          other.temperature == this.temperature &&
          other.maxRetries == this.maxRetries &&
          other.timeoutMinutes == this.timeoutMinutes &&
          other.maxTurns == this.maxTurns &&
          other.systemPromptOverride == this.systemPromptOverride &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AgentDefinitionsCompanion extends UpdateCompanion<AgentDefinition> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> agentType;
  final Value<bool> isQaManager;
  final Value<bool> isBuiltIn;
  final Value<bool> isEnabled;
  final Value<String?> modelId;
  final Value<double> temperature;
  final Value<int> maxRetries;
  final Value<int?> timeoutMinutes;
  final Value<int> maxTurns;
  final Value<String?> systemPromptOverride;
  final Value<String?> description;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AgentDefinitionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.agentType = const Value.absent(),
    this.isQaManager = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.modelId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.timeoutMinutes = const Value.absent(),
    this.maxTurns = const Value.absent(),
    this.systemPromptOverride = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentDefinitionsCompanion.insert({
    required String id,
    required String name,
    this.agentType = const Value.absent(),
    this.isQaManager = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.modelId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.timeoutMinutes = const Value.absent(),
    this.maxTurns = const Value.absent(),
    this.systemPromptOverride = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AgentDefinition> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? agentType,
    Expression<bool>? isQaManager,
    Expression<bool>? isBuiltIn,
    Expression<bool>? isEnabled,
    Expression<String>? modelId,
    Expression<double>? temperature,
    Expression<int>? maxRetries,
    Expression<int>? timeoutMinutes,
    Expression<int>? maxTurns,
    Expression<String>? systemPromptOverride,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (agentType != null) 'agent_type': agentType,
      if (isQaManager != null) 'is_qa_manager': isQaManager,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (modelId != null) 'model_id': modelId,
      if (temperature != null) 'temperature': temperature,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (timeoutMinutes != null) 'timeout_minutes': timeoutMinutes,
      if (maxTurns != null) 'max_turns': maxTurns,
      if (systemPromptOverride != null)
        'system_prompt_override': systemPromptOverride,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentDefinitionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? agentType,
      Value<bool>? isQaManager,
      Value<bool>? isBuiltIn,
      Value<bool>? isEnabled,
      Value<String?>? modelId,
      Value<double>? temperature,
      Value<int>? maxRetries,
      Value<int?>? timeoutMinutes,
      Value<int>? maxTurns,
      Value<String?>? systemPromptOverride,
      Value<String?>? description,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AgentDefinitionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      agentType: agentType ?? this.agentType,
      isQaManager: isQaManager ?? this.isQaManager,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isEnabled: isEnabled ?? this.isEnabled,
      modelId: modelId ?? this.modelId,
      temperature: temperature ?? this.temperature,
      maxRetries: maxRetries ?? this.maxRetries,
      timeoutMinutes: timeoutMinutes ?? this.timeoutMinutes,
      maxTurns: maxTurns ?? this.maxTurns,
      systemPromptOverride: systemPromptOverride ?? this.systemPromptOverride,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (agentType.present) {
      map['agent_type'] = Variable<String>(agentType.value);
    }
    if (isQaManager.present) {
      map['is_qa_manager'] = Variable<bool>(isQaManager.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (timeoutMinutes.present) {
      map['timeout_minutes'] = Variable<int>(timeoutMinutes.value);
    }
    if (maxTurns.present) {
      map['max_turns'] = Variable<int>(maxTurns.value);
    }
    if (systemPromptOverride.present) {
      map['system_prompt_override'] =
          Variable<String>(systemPromptOverride.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('agentType: $agentType, ')
          ..write('isQaManager: $isQaManager, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('modelId: $modelId, ')
          ..write('temperature: $temperature, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('timeoutMinutes: $timeoutMinutes, ')
          ..write('maxTurns: $maxTurns, ')
          ..write('systemPromptOverride: $systemPromptOverride, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentFilesTable extends AgentFiles
    with TableInfo<$AgentFilesTable, AgentFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentDefinitionIdMeta =
      const VerificationMeta('agentDefinitionId');
  @override
  late final GeneratedColumn<String> agentDefinitionId =
      GeneratedColumn<String>('agent_definition_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileTypeMeta =
      const VerificationMeta('fileType');
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
      'file_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMdMeta =
      const VerificationMeta('contentMd');
  @override
  late final GeneratedColumn<String> contentMd = GeneratedColumn<String>(
      'content_md', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        agentDefinitionId,
        fileName,
        fileType,
        contentMd,
        filePath,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_files';
  @override
  VerificationContext validateIntegrity(Insertable<AgentFile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agent_definition_id')) {
      context.handle(
          _agentDefinitionIdMeta,
          agentDefinitionId.isAcceptableOrUnknown(
              data['agent_definition_id']!, _agentDefinitionIdMeta));
    } else if (isInserting) {
      context.missing(_agentDefinitionIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(_fileTypeMeta,
          fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta));
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('content_md')) {
      context.handle(_contentMdMeta,
          contentMd.isAcceptableOrUnknown(data['content_md']!, _contentMdMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentFile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      agentDefinitionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}agent_definition_id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      fileType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_type'])!,
      contentMd: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_md']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AgentFilesTable createAlias(String alias) {
    return $AgentFilesTable(attachedDatabase, alias);
  }
}

class AgentFile extends DataClass implements Insertable<AgentFile> {
  /// UUID primary key.
  final String id;

  /// Parent agent definition UUID.
  final String agentDefinitionId;

  /// Display file name.
  final String fileName;

  /// File type (e.g. "persona", "prompt", "context").
  final String fileType;

  /// Markdown content of the file.
  final String? contentMd;

  /// Optional filesystem path reference.
  final String? filePath;

  /// Display sort order within the agent.
  final int sortOrder;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;
  const AgentFile(
      {required this.id,
      required this.agentDefinitionId,
      required this.fileName,
      required this.fileType,
      this.contentMd,
      this.filePath,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agent_definition_id'] = Variable<String>(agentDefinitionId);
    map['file_name'] = Variable<String>(fileName);
    map['file_type'] = Variable<String>(fileType);
    if (!nullToAbsent || contentMd != null) {
      map['content_md'] = Variable<String>(contentMd);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AgentFilesCompanion toCompanion(bool nullToAbsent) {
    return AgentFilesCompanion(
      id: Value(id),
      agentDefinitionId: Value(agentDefinitionId),
      fileName: Value(fileName),
      fileType: Value(fileType),
      contentMd: contentMd == null && nullToAbsent
          ? const Value.absent()
          : Value(contentMd),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AgentFile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentFile(
      id: serializer.fromJson<String>(json['id']),
      agentDefinitionId: serializer.fromJson<String>(json['agentDefinitionId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileType: serializer.fromJson<String>(json['fileType']),
      contentMd: serializer.fromJson<String?>(json['contentMd']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agentDefinitionId': serializer.toJson<String>(agentDefinitionId),
      'fileName': serializer.toJson<String>(fileName),
      'fileType': serializer.toJson<String>(fileType),
      'contentMd': serializer.toJson<String?>(contentMd),
      'filePath': serializer.toJson<String?>(filePath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AgentFile copyWith(
          {String? id,
          String? agentDefinitionId,
          String? fileName,
          String? fileType,
          Value<String?> contentMd = const Value.absent(),
          Value<String?> filePath = const Value.absent(),
          int? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AgentFile(
        id: id ?? this.id,
        agentDefinitionId: agentDefinitionId ?? this.agentDefinitionId,
        fileName: fileName ?? this.fileName,
        fileType: fileType ?? this.fileType,
        contentMd: contentMd.present ? contentMd.value : this.contentMd,
        filePath: filePath.present ? filePath.value : this.filePath,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AgentFile copyWithCompanion(AgentFilesCompanion data) {
    return AgentFile(
      id: data.id.present ? data.id.value : this.id,
      agentDefinitionId: data.agentDefinitionId.present
          ? data.agentDefinitionId.value
          : this.agentDefinitionId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      contentMd: data.contentMd.present ? data.contentMd.value : this.contentMd,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentFile(')
          ..write('id: $id, ')
          ..write('agentDefinitionId: $agentDefinitionId, ')
          ..write('fileName: $fileName, ')
          ..write('fileType: $fileType, ')
          ..write('contentMd: $contentMd, ')
          ..write('filePath: $filePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, agentDefinitionId, fileName, fileType,
      contentMd, filePath, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentFile &&
          other.id == this.id &&
          other.agentDefinitionId == this.agentDefinitionId &&
          other.fileName == this.fileName &&
          other.fileType == this.fileType &&
          other.contentMd == this.contentMd &&
          other.filePath == this.filePath &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AgentFilesCompanion extends UpdateCompanion<AgentFile> {
  final Value<String> id;
  final Value<String> agentDefinitionId;
  final Value<String> fileName;
  final Value<String> fileType;
  final Value<String?> contentMd;
  final Value<String?> filePath;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AgentFilesCompanion({
    this.id = const Value.absent(),
    this.agentDefinitionId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileType = const Value.absent(),
    this.contentMd = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentFilesCompanion.insert({
    required String id,
    required String agentDefinitionId,
    required String fileName,
    required String fileType,
    this.contentMd = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        agentDefinitionId = Value(agentDefinitionId),
        fileName = Value(fileName),
        fileType = Value(fileType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AgentFile> custom({
    Expression<String>? id,
    Expression<String>? agentDefinitionId,
    Expression<String>? fileName,
    Expression<String>? fileType,
    Expression<String>? contentMd,
    Expression<String>? filePath,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentDefinitionId != null) 'agent_definition_id': agentDefinitionId,
      if (fileName != null) 'file_name': fileName,
      if (fileType != null) 'file_type': fileType,
      if (contentMd != null) 'content_md': contentMd,
      if (filePath != null) 'file_path': filePath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentFilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? agentDefinitionId,
      Value<String>? fileName,
      Value<String>? fileType,
      Value<String?>? contentMd,
      Value<String?>? filePath,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AgentFilesCompanion(
      id: id ?? this.id,
      agentDefinitionId: agentDefinitionId ?? this.agentDefinitionId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      contentMd: contentMd ?? this.contentMd,
      filePath: filePath ?? this.filePath,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (agentDefinitionId.present) {
      map['agent_definition_id'] = Variable<String>(agentDefinitionId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (contentMd.present) {
      map['content_md'] = Variable<String>(contentMd.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentFilesCompanion(')
          ..write('id: $id, ')
          ..write('agentDefinitionId: $agentDefinitionId, ')
          ..write('fileName: $fileName, ')
          ..write('fileType: $fileType, ')
          ..write('contentMd: $contentMd, ')
          ..write('filePath: $filePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CodeOpsDatabase extends GeneratedDatabase {
  _$CodeOpsDatabase(QueryExecutor e) : super(e);
  $CodeOpsDatabaseManager get managers => $CodeOpsDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $QaJobsTable qaJobs = $QaJobsTable(this);
  late final $AgentRunsTable agentRuns = $AgentRunsTable(this);
  late final $FindingsTable findings = $FindingsTable(this);
  late final $RemediationTasksTable remediationTasks =
      $RemediationTasksTable(this);
  late final $PersonasTable personas = $PersonasTable(this);
  late final $DirectivesTable directives = $DirectivesTable(this);
  late final $TechDebtItemsTable techDebtItems = $TechDebtItemsTable(this);
  late final $DependencyScansTable dependencyScans =
      $DependencyScansTable(this);
  late final $DependencyVulnerabilitiesTable dependencyVulnerabilities =
      $DependencyVulnerabilitiesTable(this);
  late final $HealthSnapshotsTable healthSnapshots =
      $HealthSnapshotsTable(this);
  late final $ComplianceItemsTable complianceItems =
      $ComplianceItemsTable(this);
  late final $SpecificationsTable specifications = $SpecificationsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  late final $ClonedReposTable clonedRepos = $ClonedReposTable(this);
  late final $AnthropicModelsTable anthropicModels =
      $AnthropicModelsTable(this);
  late final $AgentDefinitionsTable agentDefinitions =
      $AgentDefinitionsTable(this);
  late final $AgentFilesTable agentFiles = $AgentFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        teams,
        projects,
        qaJobs,
        agentRuns,
        findings,
        remediationTasks,
        personas,
        directives,
        techDebtItems,
        dependencyScans,
        dependencyVulnerabilities,
        healthSnapshots,
        complianceItems,
        specifications,
        syncMetadata,
        clonedRepos,
        anthropicModels,
        agentDefinitions,
        agentFiles
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String email,
  required String displayName,
  Value<String?> avatarUrl,
  Value<bool> isActive,
  Value<DateTime?> lastLoginAt,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> email,
  Value<String> displayName,
  Value<String?> avatarUrl,
  Value<bool> isActive,
  Value<DateTime?> lastLoginAt,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$UsersTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
      column: $table.avatarUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$CodeOpsDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$CodeOpsDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> avatarUrl = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> lastLoginAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            email: email,
            displayName: displayName,
            avatarUrl: avatarUrl,
            isActive: isActive,
            lastLoginAt: lastLoginAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String email,
            required String displayName,
            Value<String?> avatarUrl = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime?> lastLoginAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            email: email,
            displayName: displayName,
            avatarUrl: avatarUrl,
            isActive: isActive,
            lastLoginAt: lastLoginAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$CodeOpsDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$TeamsTableCreateCompanionBuilder = TeamsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  required String ownerId,
  Value<String?> ownerName,
  Value<String?> teamsWebhookUrl,
  Value<int?> memberCount,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$TeamsTableUpdateCompanionBuilder = TeamsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String> ownerId,
  Value<String?> ownerName,
  Value<String?> teamsWebhookUrl,
  Value<int?> memberCount,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$TeamsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $TeamsTable> {
  $$TeamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerName => $composableBuilder(
      column: $table.ownerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamsWebhookUrl => $composableBuilder(
      column: $table.teamsWebhookUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get memberCount => $composableBuilder(
      column: $table.memberCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TeamsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $TeamsTable> {
  $$TeamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerName => $composableBuilder(
      column: $table.ownerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamsWebhookUrl => $composableBuilder(
      column: $table.teamsWebhookUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get memberCount => $composableBuilder(
      column: $table.memberCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TeamsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $TeamsTable> {
  $$TeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get teamsWebhookUrl => $composableBuilder(
      column: $table.teamsWebhookUrl, builder: (column) => column);

  GeneratedColumn<int> get memberCount => $composableBuilder(
      column: $table.memberCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TeamsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $TeamsTable,
    Team,
    $$TeamsTableFilterComposer,
    $$TeamsTableOrderingComposer,
    $$TeamsTableAnnotationComposer,
    $$TeamsTableCreateCompanionBuilder,
    $$TeamsTableUpdateCompanionBuilder,
    (Team, BaseReferences<_$CodeOpsDatabase, $TeamsTable, Team>),
    Team,
    PrefetchHooks Function()> {
  $$TeamsTableTableManager(_$CodeOpsDatabase db, $TeamsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String?> ownerName = const Value.absent(),
            Value<String?> teamsWebhookUrl = const Value.absent(),
            Value<int?> memberCount = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeamsCompanion(
            id: id,
            name: name,
            description: description,
            ownerId: ownerId,
            ownerName: ownerName,
            teamsWebhookUrl: teamsWebhookUrl,
            memberCount: memberCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            required String ownerId,
            Value<String?> ownerName = const Value.absent(),
            Value<String?> teamsWebhookUrl = const Value.absent(),
            Value<int?> memberCount = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeamsCompanion.insert(
            id: id,
            name: name,
            description: description,
            ownerId: ownerId,
            ownerName: ownerName,
            teamsWebhookUrl: teamsWebhookUrl,
            memberCount: memberCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TeamsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $TeamsTable,
    Team,
    $$TeamsTableFilterComposer,
    $$TeamsTableOrderingComposer,
    $$TeamsTableAnnotationComposer,
    $$TeamsTableCreateCompanionBuilder,
    $$TeamsTableUpdateCompanionBuilder,
    (Team, BaseReferences<_$CodeOpsDatabase, $TeamsTable, Team>),
    Team,
    PrefetchHooks Function()>;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String teamId,
  required String name,
  Value<String?> description,
  Value<String?> githubConnectionId,
  Value<String?> repoUrl,
  Value<String?> repoFullName,
  Value<String?> defaultBranch,
  Value<String?> jiraConnectionId,
  Value<String?> jiraProjectKey,
  Value<String?> techStack,
  Value<int?> healthScore,
  Value<DateTime?> lastAuditAt,
  Value<bool> isArchived,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> teamId,
  Value<String> name,
  Value<String?> description,
  Value<String?> githubConnectionId,
  Value<String?> repoUrl,
  Value<String?> repoFullName,
  Value<String?> defaultBranch,
  Value<String?> jiraConnectionId,
  Value<String?> jiraProjectKey,
  Value<String?> techStack,
  Value<int?> healthScore,
  Value<DateTime?> lastAuditAt,
  Value<bool> isArchived,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$ProjectsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamId => $composableBuilder(
      column: $table.teamId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get githubConnectionId => $composableBuilder(
      column: $table.githubConnectionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repoUrl => $composableBuilder(
      column: $table.repoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repoFullName => $composableBuilder(
      column: $table.repoFullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultBranch => $composableBuilder(
      column: $table.defaultBranch, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jiraConnectionId => $composableBuilder(
      column: $table.jiraConnectionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jiraProjectKey => $composableBuilder(
      column: $table.jiraProjectKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get techStack => $composableBuilder(
      column: $table.techStack, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAuditAt => $composableBuilder(
      column: $table.lastAuditAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamId => $composableBuilder(
      column: $table.teamId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get githubConnectionId => $composableBuilder(
      column: $table.githubConnectionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repoUrl => $composableBuilder(
      column: $table.repoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repoFullName => $composableBuilder(
      column: $table.repoFullName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultBranch => $composableBuilder(
      column: $table.defaultBranch,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jiraConnectionId => $composableBuilder(
      column: $table.jiraConnectionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jiraProjectKey => $composableBuilder(
      column: $table.jiraProjectKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get techStack => $composableBuilder(
      column: $table.techStack, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAuditAt => $composableBuilder(
      column: $table.lastAuditAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get githubConnectionId => $composableBuilder(
      column: $table.githubConnectionId, builder: (column) => column);

  GeneratedColumn<String> get repoUrl =>
      $composableBuilder(column: $table.repoUrl, builder: (column) => column);

  GeneratedColumn<String> get repoFullName => $composableBuilder(
      column: $table.repoFullName, builder: (column) => column);

  GeneratedColumn<String> get defaultBranch => $composableBuilder(
      column: $table.defaultBranch, builder: (column) => column);

  GeneratedColumn<String> get jiraConnectionId => $composableBuilder(
      column: $table.jiraConnectionId, builder: (column) => column);

  GeneratedColumn<String> get jiraProjectKey => $composableBuilder(
      column: $table.jiraProjectKey, builder: (column) => column);

  GeneratedColumn<String> get techStack =>
      $composableBuilder(column: $table.techStack, builder: (column) => column);

  GeneratedColumn<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAuditAt => $composableBuilder(
      column: $table.lastAuditAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, BaseReferences<_$CodeOpsDatabase, $ProjectsTable, Project>),
    Project,
    PrefetchHooks Function()> {
  $$ProjectsTableTableManager(_$CodeOpsDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> teamId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> githubConnectionId = const Value.absent(),
            Value<String?> repoUrl = const Value.absent(),
            Value<String?> repoFullName = const Value.absent(),
            Value<String?> defaultBranch = const Value.absent(),
            Value<String?> jiraConnectionId = const Value.absent(),
            Value<String?> jiraProjectKey = const Value.absent(),
            Value<String?> techStack = const Value.absent(),
            Value<int?> healthScore = const Value.absent(),
            Value<DateTime?> lastAuditAt = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            teamId: teamId,
            name: name,
            description: description,
            githubConnectionId: githubConnectionId,
            repoUrl: repoUrl,
            repoFullName: repoFullName,
            defaultBranch: defaultBranch,
            jiraConnectionId: jiraConnectionId,
            jiraProjectKey: jiraProjectKey,
            techStack: techStack,
            healthScore: healthScore,
            lastAuditAt: lastAuditAt,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String teamId,
            required String name,
            Value<String?> description = const Value.absent(),
            Value<String?> githubConnectionId = const Value.absent(),
            Value<String?> repoUrl = const Value.absent(),
            Value<String?> repoFullName = const Value.absent(),
            Value<String?> defaultBranch = const Value.absent(),
            Value<String?> jiraConnectionId = const Value.absent(),
            Value<String?> jiraProjectKey = const Value.absent(),
            Value<String?> techStack = const Value.absent(),
            Value<int?> healthScore = const Value.absent(),
            Value<DateTime?> lastAuditAt = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion.insert(
            id: id,
            teamId: teamId,
            name: name,
            description: description,
            githubConnectionId: githubConnectionId,
            repoUrl: repoUrl,
            repoFullName: repoFullName,
            defaultBranch: defaultBranch,
            jiraConnectionId: jiraConnectionId,
            jiraProjectKey: jiraProjectKey,
            techStack: techStack,
            healthScore: healthScore,
            lastAuditAt: lastAuditAt,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, BaseReferences<_$CodeOpsDatabase, $ProjectsTable, Project>),
    Project,
    PrefetchHooks Function()>;
typedef $$QaJobsTableCreateCompanionBuilder = QaJobsCompanion Function({
  required String id,
  required String projectId,
  Value<String?> projectName,
  required String mode,
  required String status,
  Value<String?> name,
  Value<String?> branch,
  Value<String?> configJson,
  Value<String?> summaryMd,
  Value<String?> overallResult,
  Value<int?> healthScore,
  Value<int?> totalFindings,
  Value<int?> criticalCount,
  Value<int?> highCount,
  Value<int?> mediumCount,
  Value<int?> lowCount,
  Value<String?> jiraTicketKey,
  Value<String?> startedBy,
  Value<String?> startedByName,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$QaJobsTableUpdateCompanionBuilder = QaJobsCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String?> projectName,
  Value<String> mode,
  Value<String> status,
  Value<String?> name,
  Value<String?> branch,
  Value<String?> configJson,
  Value<String?> summaryMd,
  Value<String?> overallResult,
  Value<int?> healthScore,
  Value<int?> totalFindings,
  Value<int?> criticalCount,
  Value<int?> highCount,
  Value<int?> mediumCount,
  Value<int?> lowCount,
  Value<String?> jiraTicketKey,
  Value<String?> startedBy,
  Value<String?> startedByName,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$QaJobsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $QaJobsTable> {
  $$QaJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branch => $composableBuilder(
      column: $table.branch, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summaryMd => $composableBuilder(
      column: $table.summaryMd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overallResult => $composableBuilder(
      column: $table.overallResult, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalFindings => $composableBuilder(
      column: $table.totalFindings, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get criticalCount => $composableBuilder(
      column: $table.criticalCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get highCount => $composableBuilder(
      column: $table.highCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mediumCount => $composableBuilder(
      column: $table.mediumCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lowCount => $composableBuilder(
      column: $table.lowCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jiraTicketKey => $composableBuilder(
      column: $table.jiraTicketKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startedBy => $composableBuilder(
      column: $table.startedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startedByName => $composableBuilder(
      column: $table.startedByName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$QaJobsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $QaJobsTable> {
  $$QaJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branch => $composableBuilder(
      column: $table.branch, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summaryMd => $composableBuilder(
      column: $table.summaryMd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overallResult => $composableBuilder(
      column: $table.overallResult,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalFindings => $composableBuilder(
      column: $table.totalFindings,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get criticalCount => $composableBuilder(
      column: $table.criticalCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get highCount => $composableBuilder(
      column: $table.highCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mediumCount => $composableBuilder(
      column: $table.mediumCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lowCount => $composableBuilder(
      column: $table.lowCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jiraTicketKey => $composableBuilder(
      column: $table.jiraTicketKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startedBy => $composableBuilder(
      column: $table.startedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startedByName => $composableBuilder(
      column: $table.startedByName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$QaJobsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $QaJobsTable> {
  $$QaJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
      column: $table.projectName, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
      column: $table.configJson, builder: (column) => column);

  GeneratedColumn<String> get summaryMd =>
      $composableBuilder(column: $table.summaryMd, builder: (column) => column);

  GeneratedColumn<String> get overallResult => $composableBuilder(
      column: $table.overallResult, builder: (column) => column);

  GeneratedColumn<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => column);

  GeneratedColumn<int> get totalFindings => $composableBuilder(
      column: $table.totalFindings, builder: (column) => column);

  GeneratedColumn<int> get criticalCount => $composableBuilder(
      column: $table.criticalCount, builder: (column) => column);

  GeneratedColumn<int> get highCount =>
      $composableBuilder(column: $table.highCount, builder: (column) => column);

  GeneratedColumn<int> get mediumCount => $composableBuilder(
      column: $table.mediumCount, builder: (column) => column);

  GeneratedColumn<int> get lowCount =>
      $composableBuilder(column: $table.lowCount, builder: (column) => column);

  GeneratedColumn<String> get jiraTicketKey => $composableBuilder(
      column: $table.jiraTicketKey, builder: (column) => column);

  GeneratedColumn<String> get startedBy =>
      $composableBuilder(column: $table.startedBy, builder: (column) => column);

  GeneratedColumn<String> get startedByName => $composableBuilder(
      column: $table.startedByName, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QaJobsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $QaJobsTable,
    QaJob,
    $$QaJobsTableFilterComposer,
    $$QaJobsTableOrderingComposer,
    $$QaJobsTableAnnotationComposer,
    $$QaJobsTableCreateCompanionBuilder,
    $$QaJobsTableUpdateCompanionBuilder,
    (QaJob, BaseReferences<_$CodeOpsDatabase, $QaJobsTable, QaJob>),
    QaJob,
    PrefetchHooks Function()> {
  $$QaJobsTableTableManager(_$CodeOpsDatabase db, $QaJobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QaJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QaJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QaJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String?> projectName = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> branch = const Value.absent(),
            Value<String?> configJson = const Value.absent(),
            Value<String?> summaryMd = const Value.absent(),
            Value<String?> overallResult = const Value.absent(),
            Value<int?> healthScore = const Value.absent(),
            Value<int?> totalFindings = const Value.absent(),
            Value<int?> criticalCount = const Value.absent(),
            Value<int?> highCount = const Value.absent(),
            Value<int?> mediumCount = const Value.absent(),
            Value<int?> lowCount = const Value.absent(),
            Value<String?> jiraTicketKey = const Value.absent(),
            Value<String?> startedBy = const Value.absent(),
            Value<String?> startedByName = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QaJobsCompanion(
            id: id,
            projectId: projectId,
            projectName: projectName,
            mode: mode,
            status: status,
            name: name,
            branch: branch,
            configJson: configJson,
            summaryMd: summaryMd,
            overallResult: overallResult,
            healthScore: healthScore,
            totalFindings: totalFindings,
            criticalCount: criticalCount,
            highCount: highCount,
            mediumCount: mediumCount,
            lowCount: lowCount,
            jiraTicketKey: jiraTicketKey,
            startedBy: startedBy,
            startedByName: startedByName,
            startedAt: startedAt,
            completedAt: completedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            Value<String?> projectName = const Value.absent(),
            required String mode,
            required String status,
            Value<String?> name = const Value.absent(),
            Value<String?> branch = const Value.absent(),
            Value<String?> configJson = const Value.absent(),
            Value<String?> summaryMd = const Value.absent(),
            Value<String?> overallResult = const Value.absent(),
            Value<int?> healthScore = const Value.absent(),
            Value<int?> totalFindings = const Value.absent(),
            Value<int?> criticalCount = const Value.absent(),
            Value<int?> highCount = const Value.absent(),
            Value<int?> mediumCount = const Value.absent(),
            Value<int?> lowCount = const Value.absent(),
            Value<String?> jiraTicketKey = const Value.absent(),
            Value<String?> startedBy = const Value.absent(),
            Value<String?> startedByName = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QaJobsCompanion.insert(
            id: id,
            projectId: projectId,
            projectName: projectName,
            mode: mode,
            status: status,
            name: name,
            branch: branch,
            configJson: configJson,
            summaryMd: summaryMd,
            overallResult: overallResult,
            healthScore: healthScore,
            totalFindings: totalFindings,
            criticalCount: criticalCount,
            highCount: highCount,
            mediumCount: mediumCount,
            lowCount: lowCount,
            jiraTicketKey: jiraTicketKey,
            startedBy: startedBy,
            startedByName: startedByName,
            startedAt: startedAt,
            completedAt: completedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QaJobsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $QaJobsTable,
    QaJob,
    $$QaJobsTableFilterComposer,
    $$QaJobsTableOrderingComposer,
    $$QaJobsTableAnnotationComposer,
    $$QaJobsTableCreateCompanionBuilder,
    $$QaJobsTableUpdateCompanionBuilder,
    (QaJob, BaseReferences<_$CodeOpsDatabase, $QaJobsTable, QaJob>),
    QaJob,
    PrefetchHooks Function()>;
typedef $$AgentRunsTableCreateCompanionBuilder = AgentRunsCompanion Function({
  required String id,
  required String jobId,
  required String agentType,
  required String status,
  Value<String?> result,
  Value<String?> reportS3Key,
  Value<int?> score,
  Value<int?> findingsCount,
  Value<int?> criticalCount,
  Value<int?> highCount,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});
typedef $$AgentRunsTableUpdateCompanionBuilder = AgentRunsCompanion Function({
  Value<String> id,
  Value<String> jobId,
  Value<String> agentType,
  Value<String> status,
  Value<String?> result,
  Value<String?> reportS3Key,
  Value<int?> score,
  Value<int?> findingsCount,
  Value<int?> criticalCount,
  Value<int?> highCount,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});

class $$AgentRunsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $AgentRunsTable> {
  $$AgentRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reportS3Key => $composableBuilder(
      column: $table.reportS3Key, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get findingsCount => $composableBuilder(
      column: $table.findingsCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get criticalCount => $composableBuilder(
      column: $table.criticalCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get highCount => $composableBuilder(
      column: $table.highCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$AgentRunsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $AgentRunsTable> {
  $$AgentRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reportS3Key => $composableBuilder(
      column: $table.reportS3Key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get findingsCount => $composableBuilder(
      column: $table.findingsCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get criticalCount => $composableBuilder(
      column: $table.criticalCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get highCount => $composableBuilder(
      column: $table.highCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$AgentRunsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $AgentRunsTable> {
  $$AgentRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get agentType =>
      $composableBuilder(column: $table.agentType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get reportS3Key => $composableBuilder(
      column: $table.reportS3Key, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get findingsCount => $composableBuilder(
      column: $table.findingsCount, builder: (column) => column);

  GeneratedColumn<int> get criticalCount => $composableBuilder(
      column: $table.criticalCount, builder: (column) => column);

  GeneratedColumn<int> get highCount =>
      $composableBuilder(column: $table.highCount, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$AgentRunsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $AgentRunsTable,
    AgentRun,
    $$AgentRunsTableFilterComposer,
    $$AgentRunsTableOrderingComposer,
    $$AgentRunsTableAnnotationComposer,
    $$AgentRunsTableCreateCompanionBuilder,
    $$AgentRunsTableUpdateCompanionBuilder,
    (AgentRun, BaseReferences<_$CodeOpsDatabase, $AgentRunsTable, AgentRun>),
    AgentRun,
    PrefetchHooks Function()> {
  $$AgentRunsTableTableManager(_$CodeOpsDatabase db, $AgentRunsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> jobId = const Value.absent(),
            Value<String> agentType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> result = const Value.absent(),
            Value<String?> reportS3Key = const Value.absent(),
            Value<int?> score = const Value.absent(),
            Value<int?> findingsCount = const Value.absent(),
            Value<int?> criticalCount = const Value.absent(),
            Value<int?> highCount = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentRunsCompanion(
            id: id,
            jobId: jobId,
            agentType: agentType,
            status: status,
            result: result,
            reportS3Key: reportS3Key,
            score: score,
            findingsCount: findingsCount,
            criticalCount: criticalCount,
            highCount: highCount,
            startedAt: startedAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String jobId,
            required String agentType,
            required String status,
            Value<String?> result = const Value.absent(),
            Value<String?> reportS3Key = const Value.absent(),
            Value<int?> score = const Value.absent(),
            Value<int?> findingsCount = const Value.absent(),
            Value<int?> criticalCount = const Value.absent(),
            Value<int?> highCount = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentRunsCompanion.insert(
            id: id,
            jobId: jobId,
            agentType: agentType,
            status: status,
            result: result,
            reportS3Key: reportS3Key,
            score: score,
            findingsCount: findingsCount,
            criticalCount: criticalCount,
            highCount: highCount,
            startedAt: startedAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AgentRunsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $AgentRunsTable,
    AgentRun,
    $$AgentRunsTableFilterComposer,
    $$AgentRunsTableOrderingComposer,
    $$AgentRunsTableAnnotationComposer,
    $$AgentRunsTableCreateCompanionBuilder,
    $$AgentRunsTableUpdateCompanionBuilder,
    (AgentRun, BaseReferences<_$CodeOpsDatabase, $AgentRunsTable, AgentRun>),
    AgentRun,
    PrefetchHooks Function()>;
typedef $$FindingsTableCreateCompanionBuilder = FindingsCompanion Function({
  required String id,
  required String jobId,
  required String agentType,
  required String severity,
  required String title,
  Value<String?> description,
  Value<String?> filePath,
  Value<int?> lineNumber,
  Value<String?> recommendation,
  Value<String?> evidence,
  Value<String?> effortEstimate,
  Value<String?> debtCategory,
  required String findingStatus,
  Value<String?> statusChangedBy,
  Value<DateTime?> statusChangedAt,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$FindingsTableUpdateCompanionBuilder = FindingsCompanion Function({
  Value<String> id,
  Value<String> jobId,
  Value<String> agentType,
  Value<String> severity,
  Value<String> title,
  Value<String?> description,
  Value<String?> filePath,
  Value<int?> lineNumber,
  Value<String?> recommendation,
  Value<String?> evidence,
  Value<String?> effortEstimate,
  Value<String?> debtCategory,
  Value<String> findingStatus,
  Value<String?> statusChangedBy,
  Value<DateTime?> statusChangedAt,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$FindingsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $FindingsTable> {
  $$FindingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recommendation => $composableBuilder(
      column: $table.recommendation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evidence => $composableBuilder(
      column: $table.evidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effortEstimate => $composableBuilder(
      column: $table.effortEstimate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get debtCategory => $composableBuilder(
      column: $table.debtCategory, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get findingStatus => $composableBuilder(
      column: $table.findingStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statusChangedBy => $composableBuilder(
      column: $table.statusChangedBy,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get statusChangedAt => $composableBuilder(
      column: $table.statusChangedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$FindingsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $FindingsTable> {
  $$FindingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recommendation => $composableBuilder(
      column: $table.recommendation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evidence => $composableBuilder(
      column: $table.evidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effortEstimate => $composableBuilder(
      column: $table.effortEstimate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get debtCategory => $composableBuilder(
      column: $table.debtCategory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get findingStatus => $composableBuilder(
      column: $table.findingStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statusChangedBy => $composableBuilder(
      column: $table.statusChangedBy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get statusChangedAt => $composableBuilder(
      column: $table.statusChangedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FindingsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $FindingsTable> {
  $$FindingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get agentType =>
      $composableBuilder(column: $table.agentType, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => column);

  GeneratedColumn<String> get recommendation => $composableBuilder(
      column: $table.recommendation, builder: (column) => column);

  GeneratedColumn<String> get evidence =>
      $composableBuilder(column: $table.evidence, builder: (column) => column);

  GeneratedColumn<String> get effortEstimate => $composableBuilder(
      column: $table.effortEstimate, builder: (column) => column);

  GeneratedColumn<String> get debtCategory => $composableBuilder(
      column: $table.debtCategory, builder: (column) => column);

  GeneratedColumn<String> get findingStatus => $composableBuilder(
      column: $table.findingStatus, builder: (column) => column);

  GeneratedColumn<String> get statusChangedBy => $composableBuilder(
      column: $table.statusChangedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get statusChangedAt => $composableBuilder(
      column: $table.statusChangedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FindingsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $FindingsTable,
    Finding,
    $$FindingsTableFilterComposer,
    $$FindingsTableOrderingComposer,
    $$FindingsTableAnnotationComposer,
    $$FindingsTableCreateCompanionBuilder,
    $$FindingsTableUpdateCompanionBuilder,
    (Finding, BaseReferences<_$CodeOpsDatabase, $FindingsTable, Finding>),
    Finding,
    PrefetchHooks Function()> {
  $$FindingsTableTableManager(_$CodeOpsDatabase db, $FindingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FindingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FindingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FindingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> jobId = const Value.absent(),
            Value<String> agentType = const Value.absent(),
            Value<String> severity = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<int?> lineNumber = const Value.absent(),
            Value<String?> recommendation = const Value.absent(),
            Value<String?> evidence = const Value.absent(),
            Value<String?> effortEstimate = const Value.absent(),
            Value<String?> debtCategory = const Value.absent(),
            Value<String> findingStatus = const Value.absent(),
            Value<String?> statusChangedBy = const Value.absent(),
            Value<DateTime?> statusChangedAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FindingsCompanion(
            id: id,
            jobId: jobId,
            agentType: agentType,
            severity: severity,
            title: title,
            description: description,
            filePath: filePath,
            lineNumber: lineNumber,
            recommendation: recommendation,
            evidence: evidence,
            effortEstimate: effortEstimate,
            debtCategory: debtCategory,
            findingStatus: findingStatus,
            statusChangedBy: statusChangedBy,
            statusChangedAt: statusChangedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String jobId,
            required String agentType,
            required String severity,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<int?> lineNumber = const Value.absent(),
            Value<String?> recommendation = const Value.absent(),
            Value<String?> evidence = const Value.absent(),
            Value<String?> effortEstimate = const Value.absent(),
            Value<String?> debtCategory = const Value.absent(),
            required String findingStatus,
            Value<String?> statusChangedBy = const Value.absent(),
            Value<DateTime?> statusChangedAt = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FindingsCompanion.insert(
            id: id,
            jobId: jobId,
            agentType: agentType,
            severity: severity,
            title: title,
            description: description,
            filePath: filePath,
            lineNumber: lineNumber,
            recommendation: recommendation,
            evidence: evidence,
            effortEstimate: effortEstimate,
            debtCategory: debtCategory,
            findingStatus: findingStatus,
            statusChangedBy: statusChangedBy,
            statusChangedAt: statusChangedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FindingsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $FindingsTable,
    Finding,
    $$FindingsTableFilterComposer,
    $$FindingsTableOrderingComposer,
    $$FindingsTableAnnotationComposer,
    $$FindingsTableCreateCompanionBuilder,
    $$FindingsTableUpdateCompanionBuilder,
    (Finding, BaseReferences<_$CodeOpsDatabase, $FindingsTable, Finding>),
    Finding,
    PrefetchHooks Function()>;
typedef $$RemediationTasksTableCreateCompanionBuilder
    = RemediationTasksCompanion Function({
  required String id,
  required String jobId,
  required int taskNumber,
  required String title,
  Value<String?> description,
  Value<String?> promptMd,
  Value<String?> priority,
  required String status,
  Value<String?> assignedTo,
  Value<String?> assignedToName,
  Value<String?> jiraKey,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$RemediationTasksTableUpdateCompanionBuilder
    = RemediationTasksCompanion Function({
  Value<String> id,
  Value<String> jobId,
  Value<int> taskNumber,
  Value<String> title,
  Value<String?> description,
  Value<String?> promptMd,
  Value<String?> priority,
  Value<String> status,
  Value<String?> assignedTo,
  Value<String?> assignedToName,
  Value<String?> jiraKey,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$RemediationTasksTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $RemediationTasksTable> {
  $$RemediationTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskNumber => $composableBuilder(
      column: $table.taskNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promptMd => $composableBuilder(
      column: $table.promptMd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignedToName => $composableBuilder(
      column: $table.assignedToName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jiraKey => $composableBuilder(
      column: $table.jiraKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RemediationTasksTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $RemediationTasksTable> {
  $$RemediationTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskNumber => $composableBuilder(
      column: $table.taskNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promptMd => $composableBuilder(
      column: $table.promptMd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignedToName => $composableBuilder(
      column: $table.assignedToName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jiraKey => $composableBuilder(
      column: $table.jiraKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RemediationTasksTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $RemediationTasksTable> {
  $$RemediationTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<int> get taskNumber => $composableBuilder(
      column: $table.taskNumber, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get promptMd =>
      $composableBuilder(column: $table.promptMd, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get assignedTo => $composableBuilder(
      column: $table.assignedTo, builder: (column) => column);

  GeneratedColumn<String> get assignedToName => $composableBuilder(
      column: $table.assignedToName, builder: (column) => column);

  GeneratedColumn<String> get jiraKey =>
      $composableBuilder(column: $table.jiraKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RemediationTasksTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $RemediationTasksTable,
    RemediationTask,
    $$RemediationTasksTableFilterComposer,
    $$RemediationTasksTableOrderingComposer,
    $$RemediationTasksTableAnnotationComposer,
    $$RemediationTasksTableCreateCompanionBuilder,
    $$RemediationTasksTableUpdateCompanionBuilder,
    (
      RemediationTask,
      BaseReferences<_$CodeOpsDatabase, $RemediationTasksTable, RemediationTask>
    ),
    RemediationTask,
    PrefetchHooks Function()> {
  $$RemediationTasksTableTableManager(
      _$CodeOpsDatabase db, $RemediationTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemediationTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemediationTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemediationTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> jobId = const Value.absent(),
            Value<int> taskNumber = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> promptMd = const Value.absent(),
            Value<String?> priority = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> assignedTo = const Value.absent(),
            Value<String?> assignedToName = const Value.absent(),
            Value<String?> jiraKey = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemediationTasksCompanion(
            id: id,
            jobId: jobId,
            taskNumber: taskNumber,
            title: title,
            description: description,
            promptMd: promptMd,
            priority: priority,
            status: status,
            assignedTo: assignedTo,
            assignedToName: assignedToName,
            jiraKey: jiraKey,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String jobId,
            required int taskNumber,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<String?> promptMd = const Value.absent(),
            Value<String?> priority = const Value.absent(),
            required String status,
            Value<String?> assignedTo = const Value.absent(),
            Value<String?> assignedToName = const Value.absent(),
            Value<String?> jiraKey = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemediationTasksCompanion.insert(
            id: id,
            jobId: jobId,
            taskNumber: taskNumber,
            title: title,
            description: description,
            promptMd: promptMd,
            priority: priority,
            status: status,
            assignedTo: assignedTo,
            assignedToName: assignedToName,
            jiraKey: jiraKey,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RemediationTasksTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $RemediationTasksTable,
    RemediationTask,
    $$RemediationTasksTableFilterComposer,
    $$RemediationTasksTableOrderingComposer,
    $$RemediationTasksTableAnnotationComposer,
    $$RemediationTasksTableCreateCompanionBuilder,
    $$RemediationTasksTableUpdateCompanionBuilder,
    (
      RemediationTask,
      BaseReferences<_$CodeOpsDatabase, $RemediationTasksTable, RemediationTask>
    ),
    RemediationTask,
    PrefetchHooks Function()>;
typedef $$PersonasTableCreateCompanionBuilder = PersonasCompanion Function({
  required String id,
  required String name,
  Value<String?> agentType,
  Value<String?> description,
  Value<String?> contentMd,
  required String scope,
  Value<String?> teamId,
  Value<String?> createdBy,
  Value<String?> createdByName,
  Value<bool> isDefault,
  Value<int?> version,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$PersonasTableUpdateCompanionBuilder = PersonasCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> agentType,
  Value<String?> description,
  Value<String?> contentMd,
  Value<String> scope,
  Value<String?> teamId,
  Value<String?> createdBy,
  Value<String?> createdByName,
  Value<bool> isDefault,
  Value<int?> version,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$PersonasTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $PersonasTable> {
  $$PersonasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentMd => $composableBuilder(
      column: $table.contentMd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamId => $composableBuilder(
      column: $table.teamId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByName => $composableBuilder(
      column: $table.createdByName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PersonasTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $PersonasTable> {
  $$PersonasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentMd => $composableBuilder(
      column: $table.contentMd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamId => $composableBuilder(
      column: $table.teamId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByName => $composableBuilder(
      column: $table.createdByName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PersonasTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $PersonasTable> {
  $$PersonasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get agentType =>
      $composableBuilder(column: $table.agentType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get contentMd =>
      $composableBuilder(column: $table.contentMd, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdByName => $composableBuilder(
      column: $table.createdByName, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PersonasTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $PersonasTable,
    Persona,
    $$PersonasTableFilterComposer,
    $$PersonasTableOrderingComposer,
    $$PersonasTableAnnotationComposer,
    $$PersonasTableCreateCompanionBuilder,
    $$PersonasTableUpdateCompanionBuilder,
    (Persona, BaseReferences<_$CodeOpsDatabase, $PersonasTable, Persona>),
    Persona,
    PrefetchHooks Function()> {
  $$PersonasTableTableManager(_$CodeOpsDatabase db, $PersonasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> agentType = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> contentMd = const Value.absent(),
            Value<String> scope = const Value.absent(),
            Value<String?> teamId = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String?> createdByName = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int?> version = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonasCompanion(
            id: id,
            name: name,
            agentType: agentType,
            description: description,
            contentMd: contentMd,
            scope: scope,
            teamId: teamId,
            createdBy: createdBy,
            createdByName: createdByName,
            isDefault: isDefault,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> agentType = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> contentMd = const Value.absent(),
            required String scope,
            Value<String?> teamId = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String?> createdByName = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int?> version = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonasCompanion.insert(
            id: id,
            name: name,
            agentType: agentType,
            description: description,
            contentMd: contentMd,
            scope: scope,
            teamId: teamId,
            createdBy: createdBy,
            createdByName: createdByName,
            isDefault: isDefault,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PersonasTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $PersonasTable,
    Persona,
    $$PersonasTableFilterComposer,
    $$PersonasTableOrderingComposer,
    $$PersonasTableAnnotationComposer,
    $$PersonasTableCreateCompanionBuilder,
    $$PersonasTableUpdateCompanionBuilder,
    (Persona, BaseReferences<_$CodeOpsDatabase, $PersonasTable, Persona>),
    Persona,
    PrefetchHooks Function()>;
typedef $$DirectivesTableCreateCompanionBuilder = DirectivesCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<String?> contentMd,
  Value<String?> category,
  required String scope,
  Value<String?> teamId,
  Value<String?> projectId,
  Value<String?> createdBy,
  Value<String?> createdByName,
  Value<int?> version,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$DirectivesTableUpdateCompanionBuilder = DirectivesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String?> contentMd,
  Value<String?> category,
  Value<String> scope,
  Value<String?> teamId,
  Value<String?> projectId,
  Value<String?> createdBy,
  Value<String?> createdByName,
  Value<int?> version,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$DirectivesTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $DirectivesTable> {
  $$DirectivesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentMd => $composableBuilder(
      column: $table.contentMd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamId => $composableBuilder(
      column: $table.teamId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByName => $composableBuilder(
      column: $table.createdByName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DirectivesTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $DirectivesTable> {
  $$DirectivesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentMd => $composableBuilder(
      column: $table.contentMd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scope => $composableBuilder(
      column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamId => $composableBuilder(
      column: $table.teamId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByName => $composableBuilder(
      column: $table.createdByName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DirectivesTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $DirectivesTable> {
  $$DirectivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get contentMd =>
      $composableBuilder(column: $table.contentMd, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdByName => $composableBuilder(
      column: $table.createdByName, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DirectivesTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $DirectivesTable,
    Directive,
    $$DirectivesTableFilterComposer,
    $$DirectivesTableOrderingComposer,
    $$DirectivesTableAnnotationComposer,
    $$DirectivesTableCreateCompanionBuilder,
    $$DirectivesTableUpdateCompanionBuilder,
    (Directive, BaseReferences<_$CodeOpsDatabase, $DirectivesTable, Directive>),
    Directive,
    PrefetchHooks Function()> {
  $$DirectivesTableTableManager(_$CodeOpsDatabase db, $DirectivesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DirectivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DirectivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DirectivesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> contentMd = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String> scope = const Value.absent(),
            Value<String?> teamId = const Value.absent(),
            Value<String?> projectId = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String?> createdByName = const Value.absent(),
            Value<int?> version = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DirectivesCompanion(
            id: id,
            name: name,
            description: description,
            contentMd: contentMd,
            category: category,
            scope: scope,
            teamId: teamId,
            projectId: projectId,
            createdBy: createdBy,
            createdByName: createdByName,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            Value<String?> contentMd = const Value.absent(),
            Value<String?> category = const Value.absent(),
            required String scope,
            Value<String?> teamId = const Value.absent(),
            Value<String?> projectId = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String?> createdByName = const Value.absent(),
            Value<int?> version = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DirectivesCompanion.insert(
            id: id,
            name: name,
            description: description,
            contentMd: contentMd,
            category: category,
            scope: scope,
            teamId: teamId,
            projectId: projectId,
            createdBy: createdBy,
            createdByName: createdByName,
            version: version,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DirectivesTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $DirectivesTable,
    Directive,
    $$DirectivesTableFilterComposer,
    $$DirectivesTableOrderingComposer,
    $$DirectivesTableAnnotationComposer,
    $$DirectivesTableCreateCompanionBuilder,
    $$DirectivesTableUpdateCompanionBuilder,
    (Directive, BaseReferences<_$CodeOpsDatabase, $DirectivesTable, Directive>),
    Directive,
    PrefetchHooks Function()>;
typedef $$TechDebtItemsTableCreateCompanionBuilder = TechDebtItemsCompanion
    Function({
  required String id,
  required String projectId,
  required String category,
  required String title,
  Value<String?> description,
  Value<String?> filePath,
  Value<String?> effortEstimate,
  Value<String?> businessImpact,
  required String status,
  Value<String?> firstDetectedJobId,
  Value<String?> resolvedJobId,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$TechDebtItemsTableUpdateCompanionBuilder = TechDebtItemsCompanion
    Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> category,
  Value<String> title,
  Value<String?> description,
  Value<String?> filePath,
  Value<String?> effortEstimate,
  Value<String?> businessImpact,
  Value<String> status,
  Value<String?> firstDetectedJobId,
  Value<String?> resolvedJobId,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$TechDebtItemsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $TechDebtItemsTable> {
  $$TechDebtItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effortEstimate => $composableBuilder(
      column: $table.effortEstimate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get businessImpact => $composableBuilder(
      column: $table.businessImpact,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstDetectedJobId => $composableBuilder(
      column: $table.firstDetectedJobId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resolvedJobId => $composableBuilder(
      column: $table.resolvedJobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TechDebtItemsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $TechDebtItemsTable> {
  $$TechDebtItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effortEstimate => $composableBuilder(
      column: $table.effortEstimate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get businessImpact => $composableBuilder(
      column: $table.businessImpact,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstDetectedJobId => $composableBuilder(
      column: $table.firstDetectedJobId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resolvedJobId => $composableBuilder(
      column: $table.resolvedJobId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TechDebtItemsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $TechDebtItemsTable> {
  $$TechDebtItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get effortEstimate => $composableBuilder(
      column: $table.effortEstimate, builder: (column) => column);

  GeneratedColumn<String> get businessImpact => $composableBuilder(
      column: $table.businessImpact, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get firstDetectedJobId => $composableBuilder(
      column: $table.firstDetectedJobId, builder: (column) => column);

  GeneratedColumn<String> get resolvedJobId => $composableBuilder(
      column: $table.resolvedJobId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TechDebtItemsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $TechDebtItemsTable,
    TechDebtItem,
    $$TechDebtItemsTableFilterComposer,
    $$TechDebtItemsTableOrderingComposer,
    $$TechDebtItemsTableAnnotationComposer,
    $$TechDebtItemsTableCreateCompanionBuilder,
    $$TechDebtItemsTableUpdateCompanionBuilder,
    (
      TechDebtItem,
      BaseReferences<_$CodeOpsDatabase, $TechDebtItemsTable, TechDebtItem>
    ),
    TechDebtItem,
    PrefetchHooks Function()> {
  $$TechDebtItemsTableTableManager(
      _$CodeOpsDatabase db, $TechDebtItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TechDebtItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TechDebtItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TechDebtItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> effortEstimate = const Value.absent(),
            Value<String?> businessImpact = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> firstDetectedJobId = const Value.absent(),
            Value<String?> resolvedJobId = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TechDebtItemsCompanion(
            id: id,
            projectId: projectId,
            category: category,
            title: title,
            description: description,
            filePath: filePath,
            effortEstimate: effortEstimate,
            businessImpact: businessImpact,
            status: status,
            firstDetectedJobId: firstDetectedJobId,
            resolvedJobId: resolvedJobId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            required String category,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> effortEstimate = const Value.absent(),
            Value<String?> businessImpact = const Value.absent(),
            required String status,
            Value<String?> firstDetectedJobId = const Value.absent(),
            Value<String?> resolvedJobId = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TechDebtItemsCompanion.insert(
            id: id,
            projectId: projectId,
            category: category,
            title: title,
            description: description,
            filePath: filePath,
            effortEstimate: effortEstimate,
            businessImpact: businessImpact,
            status: status,
            firstDetectedJobId: firstDetectedJobId,
            resolvedJobId: resolvedJobId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TechDebtItemsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $TechDebtItemsTable,
    TechDebtItem,
    $$TechDebtItemsTableFilterComposer,
    $$TechDebtItemsTableOrderingComposer,
    $$TechDebtItemsTableAnnotationComposer,
    $$TechDebtItemsTableCreateCompanionBuilder,
    $$TechDebtItemsTableUpdateCompanionBuilder,
    (
      TechDebtItem,
      BaseReferences<_$CodeOpsDatabase, $TechDebtItemsTable, TechDebtItem>
    ),
    TechDebtItem,
    PrefetchHooks Function()>;
typedef $$DependencyScansTableCreateCompanionBuilder = DependencyScansCompanion
    Function({
  required String id,
  required String projectId,
  Value<String?> jobId,
  Value<String?> manifestFile,
  Value<int?> totalDependencies,
  Value<int?> outdatedCount,
  Value<int?> vulnerableCount,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$DependencyScansTableUpdateCompanionBuilder = DependencyScansCompanion
    Function({
  Value<String> id,
  Value<String> projectId,
  Value<String?> jobId,
  Value<String?> manifestFile,
  Value<int?> totalDependencies,
  Value<int?> outdatedCount,
  Value<int?> vulnerableCount,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$DependencyScansTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $DependencyScansTable> {
  $$DependencyScansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manifestFile => $composableBuilder(
      column: $table.manifestFile, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalDependencies => $composableBuilder(
      column: $table.totalDependencies,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outdatedCount => $composableBuilder(
      column: $table.outdatedCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get vulnerableCount => $composableBuilder(
      column: $table.vulnerableCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DependencyScansTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $DependencyScansTable> {
  $$DependencyScansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manifestFile => $composableBuilder(
      column: $table.manifestFile,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalDependencies => $composableBuilder(
      column: $table.totalDependencies,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outdatedCount => $composableBuilder(
      column: $table.outdatedCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get vulnerableCount => $composableBuilder(
      column: $table.vulnerableCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DependencyScansTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $DependencyScansTable> {
  $$DependencyScansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get manifestFile => $composableBuilder(
      column: $table.manifestFile, builder: (column) => column);

  GeneratedColumn<int> get totalDependencies => $composableBuilder(
      column: $table.totalDependencies, builder: (column) => column);

  GeneratedColumn<int> get outdatedCount => $composableBuilder(
      column: $table.outdatedCount, builder: (column) => column);

  GeneratedColumn<int> get vulnerableCount => $composableBuilder(
      column: $table.vulnerableCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DependencyScansTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $DependencyScansTable,
    DependencyScan,
    $$DependencyScansTableFilterComposer,
    $$DependencyScansTableOrderingComposer,
    $$DependencyScansTableAnnotationComposer,
    $$DependencyScansTableCreateCompanionBuilder,
    $$DependencyScansTableUpdateCompanionBuilder,
    (
      DependencyScan,
      BaseReferences<_$CodeOpsDatabase, $DependencyScansTable, DependencyScan>
    ),
    DependencyScan,
    PrefetchHooks Function()> {
  $$DependencyScansTableTableManager(
      _$CodeOpsDatabase db, $DependencyScansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DependencyScansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DependencyScansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DependencyScansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> manifestFile = const Value.absent(),
            Value<int?> totalDependencies = const Value.absent(),
            Value<int?> outdatedCount = const Value.absent(),
            Value<int?> vulnerableCount = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DependencyScansCompanion(
            id: id,
            projectId: projectId,
            jobId: jobId,
            manifestFile: manifestFile,
            totalDependencies: totalDependencies,
            outdatedCount: outdatedCount,
            vulnerableCount: vulnerableCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            Value<String?> jobId = const Value.absent(),
            Value<String?> manifestFile = const Value.absent(),
            Value<int?> totalDependencies = const Value.absent(),
            Value<int?> outdatedCount = const Value.absent(),
            Value<int?> vulnerableCount = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DependencyScansCompanion.insert(
            id: id,
            projectId: projectId,
            jobId: jobId,
            manifestFile: manifestFile,
            totalDependencies: totalDependencies,
            outdatedCount: outdatedCount,
            vulnerableCount: vulnerableCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DependencyScansTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $DependencyScansTable,
    DependencyScan,
    $$DependencyScansTableFilterComposer,
    $$DependencyScansTableOrderingComposer,
    $$DependencyScansTableAnnotationComposer,
    $$DependencyScansTableCreateCompanionBuilder,
    $$DependencyScansTableUpdateCompanionBuilder,
    (
      DependencyScan,
      BaseReferences<_$CodeOpsDatabase, $DependencyScansTable, DependencyScan>
    ),
    DependencyScan,
    PrefetchHooks Function()>;
typedef $$DependencyVulnerabilitiesTableCreateCompanionBuilder
    = DependencyVulnerabilitiesCompanion Function({
  required String id,
  required String scanId,
  required String dependencyName,
  Value<String?> currentVersion,
  Value<String?> fixedVersion,
  Value<String?> cveId,
  required String severity,
  Value<String?> description,
  required String status,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$DependencyVulnerabilitiesTableUpdateCompanionBuilder
    = DependencyVulnerabilitiesCompanion Function({
  Value<String> id,
  Value<String> scanId,
  Value<String> dependencyName,
  Value<String?> currentVersion,
  Value<String?> fixedVersion,
  Value<String?> cveId,
  Value<String> severity,
  Value<String?> description,
  Value<String> status,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$DependencyVulnerabilitiesTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $DependencyVulnerabilitiesTable> {
  $$DependencyVulnerabilitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scanId => $composableBuilder(
      column: $table.scanId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dependencyName => $composableBuilder(
      column: $table.dependencyName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentVersion => $composableBuilder(
      column: $table.currentVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fixedVersion => $composableBuilder(
      column: $table.fixedVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cveId => $composableBuilder(
      column: $table.cveId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DependencyVulnerabilitiesTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $DependencyVulnerabilitiesTable> {
  $$DependencyVulnerabilitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scanId => $composableBuilder(
      column: $table.scanId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dependencyName => $composableBuilder(
      column: $table.dependencyName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentVersion => $composableBuilder(
      column: $table.currentVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fixedVersion => $composableBuilder(
      column: $table.fixedVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cveId => $composableBuilder(
      column: $table.cveId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DependencyVulnerabilitiesTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $DependencyVulnerabilitiesTable> {
  $$DependencyVulnerabilitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scanId =>
      $composableBuilder(column: $table.scanId, builder: (column) => column);

  GeneratedColumn<String> get dependencyName => $composableBuilder(
      column: $table.dependencyName, builder: (column) => column);

  GeneratedColumn<String> get currentVersion => $composableBuilder(
      column: $table.currentVersion, builder: (column) => column);

  GeneratedColumn<String> get fixedVersion => $composableBuilder(
      column: $table.fixedVersion, builder: (column) => column);

  GeneratedColumn<String> get cveId =>
      $composableBuilder(column: $table.cveId, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DependencyVulnerabilitiesTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $DependencyVulnerabilitiesTable,
    DependencyVulnerability,
    $$DependencyVulnerabilitiesTableFilterComposer,
    $$DependencyVulnerabilitiesTableOrderingComposer,
    $$DependencyVulnerabilitiesTableAnnotationComposer,
    $$DependencyVulnerabilitiesTableCreateCompanionBuilder,
    $$DependencyVulnerabilitiesTableUpdateCompanionBuilder,
    (
      DependencyVulnerability,
      BaseReferences<_$CodeOpsDatabase, $DependencyVulnerabilitiesTable,
          DependencyVulnerability>
    ),
    DependencyVulnerability,
    PrefetchHooks Function()> {
  $$DependencyVulnerabilitiesTableTableManager(
      _$CodeOpsDatabase db, $DependencyVulnerabilitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DependencyVulnerabilitiesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DependencyVulnerabilitiesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DependencyVulnerabilitiesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> scanId = const Value.absent(),
            Value<String> dependencyName = const Value.absent(),
            Value<String?> currentVersion = const Value.absent(),
            Value<String?> fixedVersion = const Value.absent(),
            Value<String?> cveId = const Value.absent(),
            Value<String> severity = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DependencyVulnerabilitiesCompanion(
            id: id,
            scanId: scanId,
            dependencyName: dependencyName,
            currentVersion: currentVersion,
            fixedVersion: fixedVersion,
            cveId: cveId,
            severity: severity,
            description: description,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String scanId,
            required String dependencyName,
            Value<String?> currentVersion = const Value.absent(),
            Value<String?> fixedVersion = const Value.absent(),
            Value<String?> cveId = const Value.absent(),
            required String severity,
            Value<String?> description = const Value.absent(),
            required String status,
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DependencyVulnerabilitiesCompanion.insert(
            id: id,
            scanId: scanId,
            dependencyName: dependencyName,
            currentVersion: currentVersion,
            fixedVersion: fixedVersion,
            cveId: cveId,
            severity: severity,
            description: description,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DependencyVulnerabilitiesTableProcessedTableManager
    = ProcessedTableManager<
        _$CodeOpsDatabase,
        $DependencyVulnerabilitiesTable,
        DependencyVulnerability,
        $$DependencyVulnerabilitiesTableFilterComposer,
        $$DependencyVulnerabilitiesTableOrderingComposer,
        $$DependencyVulnerabilitiesTableAnnotationComposer,
        $$DependencyVulnerabilitiesTableCreateCompanionBuilder,
        $$DependencyVulnerabilitiesTableUpdateCompanionBuilder,
        (
          DependencyVulnerability,
          BaseReferences<_$CodeOpsDatabase, $DependencyVulnerabilitiesTable,
              DependencyVulnerability>
        ),
        DependencyVulnerability,
        PrefetchHooks Function()>;
typedef $$HealthSnapshotsTableCreateCompanionBuilder = HealthSnapshotsCompanion
    Function({
  required String id,
  required String projectId,
  Value<String?> jobId,
  required int healthScore,
  Value<String?> findingsBySeverity,
  Value<int?> techDebtScore,
  Value<int?> dependencyScore,
  Value<double?> testCoveragePercent,
  Value<DateTime?> capturedAt,
  Value<int> rowid,
});
typedef $$HealthSnapshotsTableUpdateCompanionBuilder = HealthSnapshotsCompanion
    Function({
  Value<String> id,
  Value<String> projectId,
  Value<String?> jobId,
  Value<int> healthScore,
  Value<String?> findingsBySeverity,
  Value<int?> techDebtScore,
  Value<int?> dependencyScore,
  Value<double?> testCoveragePercent,
  Value<DateTime?> capturedAt,
  Value<int> rowid,
});

class $$HealthSnapshotsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get findingsBySeverity => $composableBuilder(
      column: $table.findingsBySeverity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get techDebtScore => $composableBuilder(
      column: $table.techDebtScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dependencyScore => $composableBuilder(
      column: $table.dependencyScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get testCoveragePercent => $composableBuilder(
      column: $table.testCoveragePercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnFilters(column));
}

class $$HealthSnapshotsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get findingsBySeverity => $composableBuilder(
      column: $table.findingsBySeverity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get techDebtScore => $composableBuilder(
      column: $table.techDebtScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dependencyScore => $composableBuilder(
      column: $table.dependencyScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get testCoveragePercent => $composableBuilder(
      column: $table.testCoveragePercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnOrderings(column));
}

class $$HealthSnapshotsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $HealthSnapshotsTable> {
  $$HealthSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<int> get healthScore => $composableBuilder(
      column: $table.healthScore, builder: (column) => column);

  GeneratedColumn<String> get findingsBySeverity => $composableBuilder(
      column: $table.findingsBySeverity, builder: (column) => column);

  GeneratedColumn<int> get techDebtScore => $composableBuilder(
      column: $table.techDebtScore, builder: (column) => column);

  GeneratedColumn<int> get dependencyScore => $composableBuilder(
      column: $table.dependencyScore, builder: (column) => column);

  GeneratedColumn<double> get testCoveragePercent => $composableBuilder(
      column: $table.testCoveragePercent, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => column);
}

class $$HealthSnapshotsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $HealthSnapshotsTable,
    HealthSnapshot,
    $$HealthSnapshotsTableFilterComposer,
    $$HealthSnapshotsTableOrderingComposer,
    $$HealthSnapshotsTableAnnotationComposer,
    $$HealthSnapshotsTableCreateCompanionBuilder,
    $$HealthSnapshotsTableUpdateCompanionBuilder,
    (
      HealthSnapshot,
      BaseReferences<_$CodeOpsDatabase, $HealthSnapshotsTable, HealthSnapshot>
    ),
    HealthSnapshot,
    PrefetchHooks Function()> {
  $$HealthSnapshotsTableTableManager(
      _$CodeOpsDatabase db, $HealthSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<int> healthScore = const Value.absent(),
            Value<String?> findingsBySeverity = const Value.absent(),
            Value<int?> techDebtScore = const Value.absent(),
            Value<int?> dependencyScore = const Value.absent(),
            Value<double?> testCoveragePercent = const Value.absent(),
            Value<DateTime?> capturedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HealthSnapshotsCompanion(
            id: id,
            projectId: projectId,
            jobId: jobId,
            healthScore: healthScore,
            findingsBySeverity: findingsBySeverity,
            techDebtScore: techDebtScore,
            dependencyScore: dependencyScore,
            testCoveragePercent: testCoveragePercent,
            capturedAt: capturedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            Value<String?> jobId = const Value.absent(),
            required int healthScore,
            Value<String?> findingsBySeverity = const Value.absent(),
            Value<int?> techDebtScore = const Value.absent(),
            Value<int?> dependencyScore = const Value.absent(),
            Value<double?> testCoveragePercent = const Value.absent(),
            Value<DateTime?> capturedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HealthSnapshotsCompanion.insert(
            id: id,
            projectId: projectId,
            jobId: jobId,
            healthScore: healthScore,
            findingsBySeverity: findingsBySeverity,
            techDebtScore: techDebtScore,
            dependencyScore: dependencyScore,
            testCoveragePercent: testCoveragePercent,
            capturedAt: capturedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HealthSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $HealthSnapshotsTable,
    HealthSnapshot,
    $$HealthSnapshotsTableFilterComposer,
    $$HealthSnapshotsTableOrderingComposer,
    $$HealthSnapshotsTableAnnotationComposer,
    $$HealthSnapshotsTableCreateCompanionBuilder,
    $$HealthSnapshotsTableUpdateCompanionBuilder,
    (
      HealthSnapshot,
      BaseReferences<_$CodeOpsDatabase, $HealthSnapshotsTable, HealthSnapshot>
    ),
    HealthSnapshot,
    PrefetchHooks Function()>;
typedef $$ComplianceItemsTableCreateCompanionBuilder = ComplianceItemsCompanion
    Function({
  required String id,
  required String jobId,
  required String requirement,
  Value<String?> specId,
  Value<String?> specName,
  required String status,
  Value<String?> evidence,
  Value<String?> agentType,
  Value<String?> notes,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$ComplianceItemsTableUpdateCompanionBuilder = ComplianceItemsCompanion
    Function({
  Value<String> id,
  Value<String> jobId,
  Value<String> requirement,
  Value<String?> specId,
  Value<String?> specName,
  Value<String> status,
  Value<String?> evidence,
  Value<String?> agentType,
  Value<String?> notes,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$ComplianceItemsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $ComplianceItemsTable> {
  $$ComplianceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requirement => $composableBuilder(
      column: $table.requirement, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specId => $composableBuilder(
      column: $table.specId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specName => $composableBuilder(
      column: $table.specName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evidence => $composableBuilder(
      column: $table.evidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ComplianceItemsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $ComplianceItemsTable> {
  $$ComplianceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requirement => $composableBuilder(
      column: $table.requirement, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specId => $composableBuilder(
      column: $table.specId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specName => $composableBuilder(
      column: $table.specName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evidence => $composableBuilder(
      column: $table.evidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ComplianceItemsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $ComplianceItemsTable> {
  $$ComplianceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get requirement => $composableBuilder(
      column: $table.requirement, builder: (column) => column);

  GeneratedColumn<String> get specId =>
      $composableBuilder(column: $table.specId, builder: (column) => column);

  GeneratedColumn<String> get specName =>
      $composableBuilder(column: $table.specName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get evidence =>
      $composableBuilder(column: $table.evidence, builder: (column) => column);

  GeneratedColumn<String> get agentType =>
      $composableBuilder(column: $table.agentType, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ComplianceItemsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $ComplianceItemsTable,
    ComplianceItem,
    $$ComplianceItemsTableFilterComposer,
    $$ComplianceItemsTableOrderingComposer,
    $$ComplianceItemsTableAnnotationComposer,
    $$ComplianceItemsTableCreateCompanionBuilder,
    $$ComplianceItemsTableUpdateCompanionBuilder,
    (
      ComplianceItem,
      BaseReferences<_$CodeOpsDatabase, $ComplianceItemsTable, ComplianceItem>
    ),
    ComplianceItem,
    PrefetchHooks Function()> {
  $$ComplianceItemsTableTableManager(
      _$CodeOpsDatabase db, $ComplianceItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComplianceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComplianceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComplianceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> jobId = const Value.absent(),
            Value<String> requirement = const Value.absent(),
            Value<String?> specId = const Value.absent(),
            Value<String?> specName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> evidence = const Value.absent(),
            Value<String?> agentType = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ComplianceItemsCompanion(
            id: id,
            jobId: jobId,
            requirement: requirement,
            specId: specId,
            specName: specName,
            status: status,
            evidence: evidence,
            agentType: agentType,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String jobId,
            required String requirement,
            Value<String?> specId = const Value.absent(),
            Value<String?> specName = const Value.absent(),
            required String status,
            Value<String?> evidence = const Value.absent(),
            Value<String?> agentType = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ComplianceItemsCompanion.insert(
            id: id,
            jobId: jobId,
            requirement: requirement,
            specId: specId,
            specName: specName,
            status: status,
            evidence: evidence,
            agentType: agentType,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ComplianceItemsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $ComplianceItemsTable,
    ComplianceItem,
    $$ComplianceItemsTableFilterComposer,
    $$ComplianceItemsTableOrderingComposer,
    $$ComplianceItemsTableAnnotationComposer,
    $$ComplianceItemsTableCreateCompanionBuilder,
    $$ComplianceItemsTableUpdateCompanionBuilder,
    (
      ComplianceItem,
      BaseReferences<_$CodeOpsDatabase, $ComplianceItemsTable, ComplianceItem>
    ),
    ComplianceItem,
    PrefetchHooks Function()>;
typedef $$SpecificationsTableCreateCompanionBuilder = SpecificationsCompanion
    Function({
  required String id,
  required String jobId,
  required String name,
  Value<String?> specType,
  required String s3Key,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$SpecificationsTableUpdateCompanionBuilder = SpecificationsCompanion
    Function({
  Value<String> id,
  Value<String> jobId,
  Value<String> name,
  Value<String?> specType,
  Value<String> s3Key,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$SpecificationsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $SpecificationsTable> {
  $$SpecificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specType => $composableBuilder(
      column: $table.specType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get s3Key => $composableBuilder(
      column: $table.s3Key, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SpecificationsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $SpecificationsTable> {
  $$SpecificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specType => $composableBuilder(
      column: $table.specType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get s3Key => $composableBuilder(
      column: $table.s3Key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SpecificationsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $SpecificationsTable> {
  $$SpecificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get specType =>
      $composableBuilder(column: $table.specType, builder: (column) => column);

  GeneratedColumn<String> get s3Key =>
      $composableBuilder(column: $table.s3Key, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SpecificationsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $SpecificationsTable,
    Specification,
    $$SpecificationsTableFilterComposer,
    $$SpecificationsTableOrderingComposer,
    $$SpecificationsTableAnnotationComposer,
    $$SpecificationsTableCreateCompanionBuilder,
    $$SpecificationsTableUpdateCompanionBuilder,
    (
      Specification,
      BaseReferences<_$CodeOpsDatabase, $SpecificationsTable, Specification>
    ),
    Specification,
    PrefetchHooks Function()> {
  $$SpecificationsTableTableManager(
      _$CodeOpsDatabase db, $SpecificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpecificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpecificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpecificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> jobId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> specType = const Value.absent(),
            Value<String> s3Key = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SpecificationsCompanion(
            id: id,
            jobId: jobId,
            name: name,
            specType: specType,
            s3Key: s3Key,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String jobId,
            required String name,
            Value<String?> specType = const Value.absent(),
            required String s3Key,
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SpecificationsCompanion.insert(
            id: id,
            jobId: jobId,
            name: name,
            specType: specType,
            s3Key: s3Key,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SpecificationsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $SpecificationsTable,
    Specification,
    $$SpecificationsTableFilterComposer,
    $$SpecificationsTableOrderingComposer,
    $$SpecificationsTableAnnotationComposer,
    $$SpecificationsTableCreateCompanionBuilder,
    $$SpecificationsTableUpdateCompanionBuilder,
    (
      Specification,
      BaseReferences<_$CodeOpsDatabase, $SpecificationsTable, Specification>
    ),
    Specification,
    PrefetchHooks Function()>;
typedef $$SyncMetadataTableCreateCompanionBuilder = SyncMetadataCompanion
    Function({
  required String syncTableName,
  required DateTime lastSyncAt,
  Value<String?> etag,
  Value<int> rowid,
});
typedef $$SyncMetadataTableUpdateCompanionBuilder = SyncMetadataCompanion
    Function({
  Value<String> syncTableName,
  Value<DateTime> lastSyncAt,
  Value<String?> etag,
  Value<int> rowid,
});

class $$SyncMetadataTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncTableName => $composableBuilder(
      column: $table.syncTableName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get etag => $composableBuilder(
      column: $table.etag, builder: (column) => ColumnFilters(column));
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncTableName => $composableBuilder(
      column: $table.syncTableName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get etag => $composableBuilder(
      column: $table.etag, builder: (column) => ColumnOrderings(column));
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncTableName => $composableBuilder(
      column: $table.syncTableName, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$SyncMetadataTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $SyncMetadataTable,
    SyncMetadataData,
    $$SyncMetadataTableFilterComposer,
    $$SyncMetadataTableOrderingComposer,
    $$SyncMetadataTableAnnotationComposer,
    $$SyncMetadataTableCreateCompanionBuilder,
    $$SyncMetadataTableUpdateCompanionBuilder,
    (
      SyncMetadataData,
      BaseReferences<_$CodeOpsDatabase, $SyncMetadataTable, SyncMetadataData>
    ),
    SyncMetadataData,
    PrefetchHooks Function()> {
  $$SyncMetadataTableTableManager(
      _$CodeOpsDatabase db, $SyncMetadataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> syncTableName = const Value.absent(),
            Value<DateTime> lastSyncAt = const Value.absent(),
            Value<String?> etag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetadataCompanion(
            syncTableName: syncTableName,
            lastSyncAt: lastSyncAt,
            etag: etag,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String syncTableName,
            required DateTime lastSyncAt,
            Value<String?> etag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetadataCompanion.insert(
            syncTableName: syncTableName,
            lastSyncAt: lastSyncAt,
            etag: etag,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetadataTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $SyncMetadataTable,
    SyncMetadataData,
    $$SyncMetadataTableFilterComposer,
    $$SyncMetadataTableOrderingComposer,
    $$SyncMetadataTableAnnotationComposer,
    $$SyncMetadataTableCreateCompanionBuilder,
    $$SyncMetadataTableUpdateCompanionBuilder,
    (
      SyncMetadataData,
      BaseReferences<_$CodeOpsDatabase, $SyncMetadataTable, SyncMetadataData>
    ),
    SyncMetadataData,
    PrefetchHooks Function()>;
typedef $$ClonedReposTableCreateCompanionBuilder = ClonedReposCompanion
    Function({
  required String repoFullName,
  required String localPath,
  Value<String?> projectId,
  Value<DateTime?> clonedAt,
  Value<DateTime?> lastAccessedAt,
  Value<int> rowid,
});
typedef $$ClonedReposTableUpdateCompanionBuilder = ClonedReposCompanion
    Function({
  Value<String> repoFullName,
  Value<String> localPath,
  Value<String?> projectId,
  Value<DateTime?> clonedAt,
  Value<DateTime?> lastAccessedAt,
  Value<int> rowid,
});

class $$ClonedReposTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $ClonedReposTable> {
  $$ClonedReposTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get repoFullName => $composableBuilder(
      column: $table.repoFullName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get clonedAt => $composableBuilder(
      column: $table.clonedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnFilters(column));
}

class $$ClonedReposTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $ClonedReposTable> {
  $$ClonedReposTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get repoFullName => $composableBuilder(
      column: $table.repoFullName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get clonedAt => $composableBuilder(
      column: $table.clonedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ClonedReposTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $ClonedReposTable> {
  $$ClonedReposTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get repoFullName => $composableBuilder(
      column: $table.repoFullName, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<DateTime> get clonedAt =>
      $composableBuilder(column: $table.clonedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt, builder: (column) => column);
}

class $$ClonedReposTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $ClonedReposTable,
    ClonedRepo,
    $$ClonedReposTableFilterComposer,
    $$ClonedReposTableOrderingComposer,
    $$ClonedReposTableAnnotationComposer,
    $$ClonedReposTableCreateCompanionBuilder,
    $$ClonedReposTableUpdateCompanionBuilder,
    (
      ClonedRepo,
      BaseReferences<_$CodeOpsDatabase, $ClonedReposTable, ClonedRepo>
    ),
    ClonedRepo,
    PrefetchHooks Function()> {
  $$ClonedReposTableTableManager(_$CodeOpsDatabase db, $ClonedReposTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClonedReposTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClonedReposTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClonedReposTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> repoFullName = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String?> projectId = const Value.absent(),
            Value<DateTime?> clonedAt = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClonedReposCompanion(
            repoFullName: repoFullName,
            localPath: localPath,
            projectId: projectId,
            clonedAt: clonedAt,
            lastAccessedAt: lastAccessedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String repoFullName,
            required String localPath,
            Value<String?> projectId = const Value.absent(),
            Value<DateTime?> clonedAt = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClonedReposCompanion.insert(
            repoFullName: repoFullName,
            localPath: localPath,
            projectId: projectId,
            clonedAt: clonedAt,
            lastAccessedAt: lastAccessedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ClonedReposTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $ClonedReposTable,
    ClonedRepo,
    $$ClonedReposTableFilterComposer,
    $$ClonedReposTableOrderingComposer,
    $$ClonedReposTableAnnotationComposer,
    $$ClonedReposTableCreateCompanionBuilder,
    $$ClonedReposTableUpdateCompanionBuilder,
    (
      ClonedRepo,
      BaseReferences<_$CodeOpsDatabase, $ClonedReposTable, ClonedRepo>
    ),
    ClonedRepo,
    PrefetchHooks Function()>;
typedef $$AnthropicModelsTableCreateCompanionBuilder = AnthropicModelsCompanion
    Function({
  required String id,
  required String displayName,
  Value<String?> modelFamily,
  Value<int?> contextWindow,
  Value<int?> maxOutputTokens,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$AnthropicModelsTableUpdateCompanionBuilder = AnthropicModelsCompanion
    Function({
  Value<String> id,
  Value<String> displayName,
  Value<String?> modelFamily,
  Value<int?> contextWindow,
  Value<int?> maxOutputTokens,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$AnthropicModelsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $AnthropicModelsTable> {
  $$AnthropicModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelFamily => $composableBuilder(
      column: $table.modelFamily, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get contextWindow => $composableBuilder(
      column: $table.contextWindow, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxOutputTokens => $composableBuilder(
      column: $table.maxOutputTokens,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$AnthropicModelsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $AnthropicModelsTable> {
  $$AnthropicModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelFamily => $composableBuilder(
      column: $table.modelFamily, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get contextWindow => $composableBuilder(
      column: $table.contextWindow,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxOutputTokens => $composableBuilder(
      column: $table.maxOutputTokens,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$AnthropicModelsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $AnthropicModelsTable> {
  $$AnthropicModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get modelFamily => $composableBuilder(
      column: $table.modelFamily, builder: (column) => column);

  GeneratedColumn<int> get contextWindow => $composableBuilder(
      column: $table.contextWindow, builder: (column) => column);

  GeneratedColumn<int> get maxOutputTokens => $composableBuilder(
      column: $table.maxOutputTokens, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$AnthropicModelsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $AnthropicModelsTable,
    AnthropicModel,
    $$AnthropicModelsTableFilterComposer,
    $$AnthropicModelsTableOrderingComposer,
    $$AnthropicModelsTableAnnotationComposer,
    $$AnthropicModelsTableCreateCompanionBuilder,
    $$AnthropicModelsTableUpdateCompanionBuilder,
    (
      AnthropicModel,
      BaseReferences<_$CodeOpsDatabase, $AnthropicModelsTable, AnthropicModel>
    ),
    AnthropicModel,
    PrefetchHooks Function()> {
  $$AnthropicModelsTableTableManager(
      _$CodeOpsDatabase db, $AnthropicModelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnthropicModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnthropicModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnthropicModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> modelFamily = const Value.absent(),
            Value<int?> contextWindow = const Value.absent(),
            Value<int?> maxOutputTokens = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnthropicModelsCompanion(
            id: id,
            displayName: displayName,
            modelFamily: modelFamily,
            contextWindow: contextWindow,
            maxOutputTokens: maxOutputTokens,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String displayName,
            Value<String?> modelFamily = const Value.absent(),
            Value<int?> contextWindow = const Value.absent(),
            Value<int?> maxOutputTokens = const Value.absent(),
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AnthropicModelsCompanion.insert(
            id: id,
            displayName: displayName,
            modelFamily: modelFamily,
            contextWindow: contextWindow,
            maxOutputTokens: maxOutputTokens,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnthropicModelsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $AnthropicModelsTable,
    AnthropicModel,
    $$AnthropicModelsTableFilterComposer,
    $$AnthropicModelsTableOrderingComposer,
    $$AnthropicModelsTableAnnotationComposer,
    $$AnthropicModelsTableCreateCompanionBuilder,
    $$AnthropicModelsTableUpdateCompanionBuilder,
    (
      AnthropicModel,
      BaseReferences<_$CodeOpsDatabase, $AnthropicModelsTable, AnthropicModel>
    ),
    AnthropicModel,
    PrefetchHooks Function()>;
typedef $$AgentDefinitionsTableCreateCompanionBuilder
    = AgentDefinitionsCompanion Function({
  required String id,
  required String name,
  Value<String?> agentType,
  Value<bool> isQaManager,
  Value<bool> isBuiltIn,
  Value<bool> isEnabled,
  Value<String?> modelId,
  Value<double> temperature,
  Value<int> maxRetries,
  Value<int?> timeoutMinutes,
  Value<int> maxTurns,
  Value<String?> systemPromptOverride,
  Value<String?> description,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AgentDefinitionsTableUpdateCompanionBuilder
    = AgentDefinitionsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> agentType,
  Value<bool> isQaManager,
  Value<bool> isBuiltIn,
  Value<bool> isEnabled,
  Value<String?> modelId,
  Value<double> temperature,
  Value<int> maxRetries,
  Value<int?> timeoutMinutes,
  Value<int> maxTurns,
  Value<String?> systemPromptOverride,
  Value<String?> description,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AgentDefinitionsTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $AgentDefinitionsTable> {
  $$AgentDefinitionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isQaManager => $composableBuilder(
      column: $table.isQaManager, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
      column: $table.isBuiltIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeoutMinutes => $composableBuilder(
      column: $table.timeoutMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxTurns => $composableBuilder(
      column: $table.maxTurns, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemPromptOverride => $composableBuilder(
      column: $table.systemPromptOverride,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AgentDefinitionsTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $AgentDefinitionsTable> {
  $$AgentDefinitionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentType => $composableBuilder(
      column: $table.agentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isQaManager => $composableBuilder(
      column: $table.isQaManager, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
      column: $table.isBuiltIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeoutMinutes => $composableBuilder(
      column: $table.timeoutMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxTurns => $composableBuilder(
      column: $table.maxTurns, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemPromptOverride => $composableBuilder(
      column: $table.systemPromptOverride,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AgentDefinitionsTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $AgentDefinitionsTable> {
  $$AgentDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get agentType =>
      $composableBuilder(column: $table.agentType, builder: (column) => column);

  GeneratedColumn<bool> get isQaManager => $composableBuilder(
      column: $table.isQaManager, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
      column: $table.temperature, builder: (column) => column);

  GeneratedColumn<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => column);

  GeneratedColumn<int> get timeoutMinutes => $composableBuilder(
      column: $table.timeoutMinutes, builder: (column) => column);

  GeneratedColumn<int> get maxTurns =>
      $composableBuilder(column: $table.maxTurns, builder: (column) => column);

  GeneratedColumn<String> get systemPromptOverride => $composableBuilder(
      column: $table.systemPromptOverride, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AgentDefinitionsTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $AgentDefinitionsTable,
    AgentDefinition,
    $$AgentDefinitionsTableFilterComposer,
    $$AgentDefinitionsTableOrderingComposer,
    $$AgentDefinitionsTableAnnotationComposer,
    $$AgentDefinitionsTableCreateCompanionBuilder,
    $$AgentDefinitionsTableUpdateCompanionBuilder,
    (
      AgentDefinition,
      BaseReferences<_$CodeOpsDatabase, $AgentDefinitionsTable, AgentDefinition>
    ),
    AgentDefinition,
    PrefetchHooks Function()> {
  $$AgentDefinitionsTableTableManager(
      _$CodeOpsDatabase db, $AgentDefinitionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentDefinitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentDefinitionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentDefinitionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> agentType = const Value.absent(),
            Value<bool> isQaManager = const Value.absent(),
            Value<bool> isBuiltIn = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<String?> modelId = const Value.absent(),
            Value<double> temperature = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            Value<int?> timeoutMinutes = const Value.absent(),
            Value<int> maxTurns = const Value.absent(),
            Value<String?> systemPromptOverride = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentDefinitionsCompanion(
            id: id,
            name: name,
            agentType: agentType,
            isQaManager: isQaManager,
            isBuiltIn: isBuiltIn,
            isEnabled: isEnabled,
            modelId: modelId,
            temperature: temperature,
            maxRetries: maxRetries,
            timeoutMinutes: timeoutMinutes,
            maxTurns: maxTurns,
            systemPromptOverride: systemPromptOverride,
            description: description,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> agentType = const Value.absent(),
            Value<bool> isQaManager = const Value.absent(),
            Value<bool> isBuiltIn = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<String?> modelId = const Value.absent(),
            Value<double> temperature = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            Value<int?> timeoutMinutes = const Value.absent(),
            Value<int> maxTurns = const Value.absent(),
            Value<String?> systemPromptOverride = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentDefinitionsCompanion.insert(
            id: id,
            name: name,
            agentType: agentType,
            isQaManager: isQaManager,
            isBuiltIn: isBuiltIn,
            isEnabled: isEnabled,
            modelId: modelId,
            temperature: temperature,
            maxRetries: maxRetries,
            timeoutMinutes: timeoutMinutes,
            maxTurns: maxTurns,
            systemPromptOverride: systemPromptOverride,
            description: description,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AgentDefinitionsTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $AgentDefinitionsTable,
    AgentDefinition,
    $$AgentDefinitionsTableFilterComposer,
    $$AgentDefinitionsTableOrderingComposer,
    $$AgentDefinitionsTableAnnotationComposer,
    $$AgentDefinitionsTableCreateCompanionBuilder,
    $$AgentDefinitionsTableUpdateCompanionBuilder,
    (
      AgentDefinition,
      BaseReferences<_$CodeOpsDatabase, $AgentDefinitionsTable, AgentDefinition>
    ),
    AgentDefinition,
    PrefetchHooks Function()>;
typedef $$AgentFilesTableCreateCompanionBuilder = AgentFilesCompanion Function({
  required String id,
  required String agentDefinitionId,
  required String fileName,
  required String fileType,
  Value<String?> contentMd,
  Value<String?> filePath,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AgentFilesTableUpdateCompanionBuilder = AgentFilesCompanion Function({
  Value<String> id,
  Value<String> agentDefinitionId,
  Value<String> fileName,
  Value<String> fileType,
  Value<String?> contentMd,
  Value<String?> filePath,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AgentFilesTableFilterComposer
    extends Composer<_$CodeOpsDatabase, $AgentFilesTable> {
  $$AgentFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentDefinitionId => $composableBuilder(
      column: $table.agentDefinitionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentMd => $composableBuilder(
      column: $table.contentMd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AgentFilesTableOrderingComposer
    extends Composer<_$CodeOpsDatabase, $AgentFilesTable> {
  $$AgentFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentDefinitionId => $composableBuilder(
      column: $table.agentDefinitionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentMd => $composableBuilder(
      column: $table.contentMd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AgentFilesTableAnnotationComposer
    extends Composer<_$CodeOpsDatabase, $AgentFilesTable> {
  $$AgentFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentDefinitionId => $composableBuilder(
      column: $table.agentDefinitionId, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<String> get contentMd =>
      $composableBuilder(column: $table.contentMd, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AgentFilesTableTableManager extends RootTableManager<
    _$CodeOpsDatabase,
    $AgentFilesTable,
    AgentFile,
    $$AgentFilesTableFilterComposer,
    $$AgentFilesTableOrderingComposer,
    $$AgentFilesTableAnnotationComposer,
    $$AgentFilesTableCreateCompanionBuilder,
    $$AgentFilesTableUpdateCompanionBuilder,
    (AgentFile, BaseReferences<_$CodeOpsDatabase, $AgentFilesTable, AgentFile>),
    AgentFile,
    PrefetchHooks Function()> {
  $$AgentFilesTableTableManager(_$CodeOpsDatabase db, $AgentFilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> agentDefinitionId = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> fileType = const Value.absent(),
            Value<String?> contentMd = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentFilesCompanion(
            id: id,
            agentDefinitionId: agentDefinitionId,
            fileName: fileName,
            fileType: fileType,
            contentMd: contentMd,
            filePath: filePath,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String agentDefinitionId,
            required String fileName,
            required String fileType,
            Value<String?> contentMd = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentFilesCompanion.insert(
            id: id,
            agentDefinitionId: agentDefinitionId,
            fileName: fileName,
            fileType: fileType,
            contentMd: contentMd,
            filePath: filePath,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AgentFilesTableProcessedTableManager = ProcessedTableManager<
    _$CodeOpsDatabase,
    $AgentFilesTable,
    AgentFile,
    $$AgentFilesTableFilterComposer,
    $$AgentFilesTableOrderingComposer,
    $$AgentFilesTableAnnotationComposer,
    $$AgentFilesTableCreateCompanionBuilder,
    $$AgentFilesTableUpdateCompanionBuilder,
    (AgentFile, BaseReferences<_$CodeOpsDatabase, $AgentFilesTable, AgentFile>),
    AgentFile,
    PrefetchHooks Function()>;

class $CodeOpsDatabaseManager {
  final _$CodeOpsDatabase _db;
  $CodeOpsDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$QaJobsTableTableManager get qaJobs =>
      $$QaJobsTableTableManager(_db, _db.qaJobs);
  $$AgentRunsTableTableManager get agentRuns =>
      $$AgentRunsTableTableManager(_db, _db.agentRuns);
  $$FindingsTableTableManager get findings =>
      $$FindingsTableTableManager(_db, _db.findings);
  $$RemediationTasksTableTableManager get remediationTasks =>
      $$RemediationTasksTableTableManager(_db, _db.remediationTasks);
  $$PersonasTableTableManager get personas =>
      $$PersonasTableTableManager(_db, _db.personas);
  $$DirectivesTableTableManager get directives =>
      $$DirectivesTableTableManager(_db, _db.directives);
  $$TechDebtItemsTableTableManager get techDebtItems =>
      $$TechDebtItemsTableTableManager(_db, _db.techDebtItems);
  $$DependencyScansTableTableManager get dependencyScans =>
      $$DependencyScansTableTableManager(_db, _db.dependencyScans);
  $$DependencyVulnerabilitiesTableTableManager get dependencyVulnerabilities =>
      $$DependencyVulnerabilitiesTableTableManager(
          _db, _db.dependencyVulnerabilities);
  $$HealthSnapshotsTableTableManager get healthSnapshots =>
      $$HealthSnapshotsTableTableManager(_db, _db.healthSnapshots);
  $$ComplianceItemsTableTableManager get complianceItems =>
      $$ComplianceItemsTableTableManager(_db, _db.complianceItems);
  $$SpecificationsTableTableManager get specifications =>
      $$SpecificationsTableTableManager(_db, _db.specifications);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
  $$ClonedReposTableTableManager get clonedRepos =>
      $$ClonedReposTableTableManager(_db, _db.clonedRepos);
  $$AnthropicModelsTableTableManager get anthropicModels =>
      $$AnthropicModelsTableTableManager(_db, _db.anthropicModels);
  $$AgentDefinitionsTableTableManager get agentDefinitions =>
      $$AgentDefinitionsTableTableManager(_db, _db.agentDefinitions);
  $$AgentFilesTableTableManager get agentFiles =>
      $$AgentFilesTableTableManager(_db, _db.agentFiles);
}
