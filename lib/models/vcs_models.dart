/// Data models for the VCS (Version Control System) layer.
///
/// These are plain Dart classes — no `@JsonSerializable`, no `.g.dart`.
/// GitHub API responses are parsed via `fromGitHubJson()` factories.
/// Git CLI output is parsed via `fromGitLine()` factories where applicable.
library;

import 'enums.dart';

// ---------------------------------------------------------------------------
// FileChangeType
// ---------------------------------------------------------------------------

/// Type of change detected by `git status` or `git diff`.
enum FileChangeType {
  /// File was added.
  added,

  /// File was modified.
  modified,

  /// File was deleted.
  deleted,

  /// File was renamed.
  renamed,

  /// File was copied.
  copied,

  /// File is untracked.
  untracked;

  /// Parses the single-character status code from `git status --porcelain=v2`.
  static FileChangeType fromGitCode(String code) => switch (code) {
        'A' => FileChangeType.added,
        'M' => FileChangeType.modified,
        'D' => FileChangeType.deleted,
        'R' => FileChangeType.renamed,
        'C' => FileChangeType.copied,
        '?' => FileChangeType.untracked,
        _ => FileChangeType.modified,
      };

  /// Human-readable label.
  String get displayName => switch (this) {
        FileChangeType.added => 'Added',
        FileChangeType.modified => 'Modified',
        FileChangeType.deleted => 'Deleted',
        FileChangeType.renamed => 'Renamed',
        FileChangeType.copied => 'Copied',
        FileChangeType.untracked => 'Untracked',
      };
}

// ---------------------------------------------------------------------------
// DiffLineType
// ---------------------------------------------------------------------------

/// Type of a single line in a unified diff.
enum DiffLineType {
  /// Unchanged context line.
  context,

  /// Added line (starts with `+`).
  addition,

  /// Removed line (starts with `-`).
  deletion,

  /// Hunk header (starts with `@@`).
  header;

  /// Parses a diff line prefix character.
  static DiffLineType fromPrefix(String line) {
    if (line.startsWith('@@')) return DiffLineType.header;
    if (line.startsWith('+')) return DiffLineType.addition;
    if (line.startsWith('-')) return DiffLineType.deletion;
    return DiffLineType.context;
  }
}

// ---------------------------------------------------------------------------
// VcsCredentials
// ---------------------------------------------------------------------------

/// Credentials for authenticating with a VCS provider.
class VcsCredentials {
  /// Authentication type (PAT, OAuth, or SSH).
  final GitHubAuthType authType;

  /// The token or key value.
  final String token;

  /// Optional GitHub username associated with this credential.
  final String? username;

  /// Creates [VcsCredentials].
  const VcsCredentials({
    required this.authType,
    required this.token,
    this.username,
  });
}

// ---------------------------------------------------------------------------
// VcsOrganization
// ---------------------------------------------------------------------------

/// A GitHub organization or user account.
class VcsOrganization {
  /// GitHub login name.
  final String login;

  /// Display name.
  final String? name;

  /// Avatar image URL.
  final String? avatarUrl;

  /// Organization description.
  final String? description;

  /// Number of public repos.
  final int? publicRepos;

  /// Creates a [VcsOrganization].
  const VcsOrganization({
    required this.login,
    this.name,
    this.avatarUrl,
    this.description,
    this.publicRepos,
  });

  /// Parses a GitHub API organization JSON object.
  factory VcsOrganization.fromGitHubJson(Map<String, dynamic> json) {
    return VcsOrganization(
      login: json['login'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      description: json['description'] as String?,
      publicRepos: json['public_repos'] as int?,
    );
  }
}

// ---------------------------------------------------------------------------
// VcsRepository
// ---------------------------------------------------------------------------

/// A GitHub repository.
class VcsRepository {
  /// Unique GitHub repo ID.
  final int id;

  /// Full name (owner/repo).
  final String fullName;

  /// Short name.
  final String name;

  /// Repository description.
  final String? description;

  /// Primary programming language.
  final String? language;

  /// Star count.
  final int stargazersCount;

  /// Fork count.
  final int forksCount;

  /// Open issue count.
  final int openIssuesCount;

  /// Default branch name.
  final String defaultBranch;

  /// Whether the repo is private.
  final bool isPrivate;

  /// Whether the repo is a fork.
  final bool isFork;

  /// Whether the repo is archived.
  final bool isArchived;

  /// Clone URL (HTTPS).
  final String? cloneUrl;

  /// SSH clone URL.
  final String? sshUrl;

  /// HTML page URL.
  final String? htmlUrl;

  /// Last push timestamp.
  final DateTime? pushedAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Owner login name.
  final String? ownerLogin;

  /// Owner avatar URL.
  final String? ownerAvatarUrl;

  /// Repository size in KB.
  final int? sizeKb;

  /// Creates a [VcsRepository].
  const VcsRepository({
    required this.id,
    required this.fullName,
    required this.name,
    this.description,
    this.language,
    this.stargazersCount = 0,
    this.forksCount = 0,
    this.openIssuesCount = 0,
    this.defaultBranch = 'main',
    this.isPrivate = false,
    this.isFork = false,
    this.isArchived = false,
    this.cloneUrl,
    this.sshUrl,
    this.htmlUrl,
    this.pushedAt,
    this.updatedAt,
    this.ownerLogin,
    this.ownerAvatarUrl,
    this.sizeKb,
  });

  /// Parses a GitHub API repository JSON object.
  factory VcsRepository.fromGitHubJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    return VcsRepository(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      language: json['language'] as String?,
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      defaultBranch: json['default_branch'] as String? ?? 'main',
      isPrivate: json['private'] as bool? ?? false,
      isFork: json['fork'] as bool? ?? false,
      isArchived: json['archived'] as bool? ?? false,
      cloneUrl: json['clone_url'] as String?,
      sshUrl: json['ssh_url'] as String?,
      htmlUrl: json['html_url'] as String?,
      pushedAt: json['pushed_at'] != null
          ? DateTime.tryParse(json['pushed_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      ownerLogin: owner?['login'] as String?,
      ownerAvatarUrl: owner?['avatar_url'] as String?,
      sizeKb: json['size'] as int?,
    );
  }
}

// ---------------------------------------------------------------------------
// VcsBranch
// ---------------------------------------------------------------------------

/// A git branch.
class VcsBranch {
  /// Branch name.
  final String name;

  /// Latest commit SHA.
  final String? sha;

  /// Whether this branch is protected.
  final bool isProtected;

  /// Creates a [VcsBranch].
  const VcsBranch({
    required this.name,
    this.sha,
    this.isProtected = false,
  });

  /// Parses a GitHub API branch JSON object.
  factory VcsBranch.fromGitHubJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>?;
    return VcsBranch(
      name: json['name'] as String,
      sha: commit?['sha'] as String?,
      isProtected: json['protected'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// VcsPullRequest
// ---------------------------------------------------------------------------

/// A GitHub pull request.
class VcsPullRequest {
  /// PR number.
  final int number;

  /// PR title.
  final String title;

  /// PR body/description.
  final String? body;

  /// State: open, closed, merged.
  final String state;

  /// Head branch name.
  final String headBranch;

  /// Base branch name.
  final String baseBranch;

  /// Author login name.
  final String? authorLogin;

  /// Author avatar URL.
  final String? authorAvatarUrl;

  /// Whether this is a draft PR.
  final bool isDraft;

  /// Whether this PR has been merged.
  final bool isMerged;

  /// Number of commits.
  final int? commits;

  /// Number of changed files.
  final int? changedFiles;

  /// Number of additions.
  final int? additions;

  /// Number of deletions.
  final int? deletions;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Merge timestamp.
  final DateTime? mergedAt;

  /// HTML page URL.
  final String? htmlUrl;

  /// Creates a [VcsPullRequest].
  const VcsPullRequest({
    required this.number,
    required this.title,
    this.body,
    required this.state,
    required this.headBranch,
    required this.baseBranch,
    this.authorLogin,
    this.authorAvatarUrl,
    this.isDraft = false,
    this.isMerged = false,
    this.commits,
    this.changedFiles,
    this.additions,
    this.deletions,
    this.createdAt,
    this.updatedAt,
    this.mergedAt,
    this.htmlUrl,
  });

  /// Parses a GitHub API pull request JSON object.
  factory VcsPullRequest.fromGitHubJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final head = json['head'] as Map<String, dynamic>?;
    final base = json['base'] as Map<String, dynamic>?;
    return VcsPullRequest(
      number: json['number'] as int,
      title: json['title'] as String,
      body: json['body'] as String?,
      state: json['state'] as String,
      headBranch: head?['ref'] as String? ?? '',
      baseBranch: base?['ref'] as String? ?? '',
      authorLogin: user?['login'] as String?,
      authorAvatarUrl: user?['avatar_url'] as String?,
      isDraft: json['draft'] as bool? ?? false,
      isMerged: json['merged'] as bool? ?? false,
      commits: json['commits'] as int?,
      changedFiles: json['changed_files'] as int?,
      additions: json['additions'] as int?,
      deletions: json['deletions'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      mergedAt: json['merged_at'] != null
          ? DateTime.tryParse(json['merged_at'] as String)
          : null,
      htmlUrl: json['html_url'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// CreatePRRequest
// ---------------------------------------------------------------------------

/// Request body for creating a new pull request.
class CreatePRRequest {
  /// PR title.
  final String title;

  /// Head branch name.
  final String head;

  /// Base branch name.
  final String base;

  /// PR body/description.
  final String? body;

  /// Whether to create as a draft PR.
  final bool draft;

  /// Creates a [CreatePRRequest].
  const CreatePRRequest({
    required this.title,
    required this.head,
    required this.base,
    this.body,
    this.draft = false,
  });

  /// Serializes to a JSON map for the GitHub API.
  Map<String, dynamic> toJson() => {
        'title': title,
        'head': head,
        'base': base,
        if (body != null) 'body': body,
        'draft': draft,
      };
}

// ---------------------------------------------------------------------------
// VcsCommit
// ---------------------------------------------------------------------------

/// A git commit.
class VcsCommit {
  /// Full commit SHA.
  final String sha;

  /// Short SHA (first 7 characters).
  String get shortSha => sha.length >= 7 ? sha.substring(0, 7) : sha;

  /// Commit message.
  final String message;

  /// Author name.
  final String? authorName;

  /// Author email.
  final String? authorEmail;

  /// Author GitHub login.
  final String? authorLogin;

  /// Author avatar URL.
  final String? authorAvatarUrl;

  /// Commit timestamp.
  final DateTime? date;

  /// HTML page URL.
  final String? htmlUrl;

  /// Creates a [VcsCommit].
  const VcsCommit({
    required this.sha,
    required this.message,
    this.authorName,
    this.authorEmail,
    this.authorLogin,
    this.authorAvatarUrl,
    this.date,
    this.htmlUrl,
  });

  /// Parses a GitHub API commit JSON object.
  factory VcsCommit.fromGitHubJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>?;
    final author = commit?['author'] as Map<String, dynamic>?;
    final ghAuthor = json['author'] as Map<String, dynamic>?;
    return VcsCommit(
      sha: json['sha'] as String,
      message: commit?['message'] as String? ?? '',
      authorName: author?['name'] as String?,
      authorEmail: author?['email'] as String?,
      authorLogin: ghAuthor?['login'] as String?,
      authorAvatarUrl: ghAuthor?['avatar_url'] as String?,
      date: author?['date'] != null
          ? DateTime.tryParse(author!['date'] as String)
          : null,
      htmlUrl: json['html_url'] as String?,
    );
  }

  /// Parses a git log JSON-formatted line.
  ///
  /// Expects the format produced by:
  /// `git log --format='{"sha":"%H","message":"%s","authorName":"%an","authorEmail":"%ae","date":"%aI"}'`
  factory VcsCommit.fromGitJson(Map<String, dynamic> json) {
    return VcsCommit(
      sha: json['sha'] as String,
      message: json['message'] as String? ?? '',
      authorName: json['authorName'] as String?,
      authorEmail: json['authorEmail'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// VcsStash
// ---------------------------------------------------------------------------

/// A git stash entry.
class VcsStash {
  /// Stash index (e.g. 0, 1, 2).
  final int index;

  /// Stash message.
  final String message;

  /// Branch the stash was created on.
  final String? branch;

  /// Creates a [VcsStash].
  const VcsStash({
    required this.index,
    required this.message,
    this.branch,
  });

  /// Parses a `git stash list` output line.
  ///
  /// Format: `stash@{0}: On main: some message`
  factory VcsStash.fromGitLine(String line) {
    final indexMatch = RegExp(r'stash@\{(\d+)\}').firstMatch(line);
    final index = indexMatch != null ? int.parse(indexMatch.group(1)!) : 0;

    String? branch;
    String message = line;

    final onBranch = RegExp(r'On ([^:]+): (.+)$').firstMatch(line);
    if (onBranch != null) {
      branch = onBranch.group(1);
      message = onBranch.group(2) ?? line;
    } else {
      final colonIdx = line.indexOf(': ');
      if (colonIdx != -1) {
        message = line.substring(colonIdx + 2);
      }
    }

    return VcsStash(
      index: index,
      message: message,
      branch: branch,
    );
  }
}

// ---------------------------------------------------------------------------
// VcsTag
// ---------------------------------------------------------------------------

/// A git tag.
class VcsTag {
  /// Tag name.
  final String name;

  /// Tagged commit SHA.
  final String? sha;

  /// Tag message (for annotated tags).
  final String? message;

  /// Tagger name.
  final String? taggerName;

  /// Tag creation timestamp.
  final DateTime? date;

  /// Zipball download URL.
  final String? zipballUrl;

  /// Tarball download URL.
  final String? tarballUrl;

  /// Creates a [VcsTag].
  const VcsTag({
    required this.name,
    this.sha,
    this.message,
    this.taggerName,
    this.date,
    this.zipballUrl,
    this.tarballUrl,
  });

  /// Parses a GitHub API tag/release JSON object.
  factory VcsTag.fromGitHubJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>?;
    return VcsTag(
      name: json['tag_name'] as String? ?? json['name'] as String,
      sha: commit?['sha'] as String? ?? json['node_id'] as String?,
      message: json['body'] as String?,
      taggerName: json['author'] is Map
          ? (json['author'] as Map<String, dynamic>)['login'] as String?
          : null,
      date: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      zipballUrl: json['zipball_url'] as String?,
      tarballUrl: json['tarball_url'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// CloneProgress
// ---------------------------------------------------------------------------

/// Progress of a git clone operation.
class CloneProgress {
  /// Current phase (e.g. "Receiving objects", "Resolving deltas").
  final String phase;

  /// Progress percentage (0-100).
  final int percent;

  /// Current count in the phase.
  final int? current;

  /// Total count in the phase.
  final int? total;

  /// Creates a [CloneProgress].
  const CloneProgress({
    required this.phase,
    required this.percent,
    this.current,
    this.total,
  });

  /// Parses a git clone progress line from stderr.
  ///
  /// Format: `Receiving objects:  42% (84/200)`
  factory CloneProgress.fromGitLine(String line) {
    final match =
        RegExp(r'([^:]+):\s+(\d+)%\s*(?:\((\d+)/(\d+)\))?').firstMatch(line);
    if (match != null) {
      return CloneProgress(
        phase: match.group(1)?.trim() ?? 'Cloning',
        percent: int.parse(match.group(2)!),
        current:
            match.group(3) != null ? int.parse(match.group(3)!) : null,
        total: match.group(4) != null ? int.parse(match.group(4)!) : null,
      );
    }
    return CloneProgress(phase: line.trim(), percent: 0);
  }
}

// ---------------------------------------------------------------------------
// RepoStatus
// ---------------------------------------------------------------------------

/// Working tree status of a cloned repository.
class RepoStatus {
  /// Current branch name.
  final String branch;

  /// List of changed files.
  final List<FileChange> changes;

  /// Commits ahead of remote.
  final int ahead;

  /// Commits behind remote.
  final int behind;

  /// Whether the working tree is clean (no changes).
  bool get isClean => changes.isEmpty;

  /// Creates a [RepoStatus].
  const RepoStatus({
    required this.branch,
    this.changes = const [],
    this.ahead = 0,
    this.behind = 0,
  });
}

// ---------------------------------------------------------------------------
// FileChange
// ---------------------------------------------------------------------------

/// A file change in the working tree.
class FileChange {
  /// File path relative to the repo root.
  final String path;

  /// Type of change.
  final FileChangeType type;

  /// Whether the file is staged for commit.
  final bool isStaged;

  /// Original path (for renames).
  final String? originalPath;

  /// Creates a [FileChange].
  const FileChange({
    required this.path,
    required this.type,
    this.isStaged = false,
    this.originalPath,
  });
}

// ---------------------------------------------------------------------------
// DiffResult
// ---------------------------------------------------------------------------

/// Result of a `git diff` operation.
class DiffResult {
  /// File path.
  final String filePath;

  /// Hunks in this diff.
  final List<DiffHunk> hunks;

  /// Total additions.
  final int additions;

  /// Total deletions.
  final int deletions;

  /// Whether this is a binary file diff.
  final bool isBinary;

  /// Creates a [DiffResult].
  const DiffResult({
    required this.filePath,
    this.hunks = const [],
    this.additions = 0,
    this.deletions = 0,
    this.isBinary = false,
  });
}

// ---------------------------------------------------------------------------
// DiffHunk
// ---------------------------------------------------------------------------

/// A hunk in a unified diff.
class DiffHunk {
  /// Hunk header line (e.g. `@@ -1,3 +1,4 @@`).
  final String header;

  /// Starting line in the old file.
  final int oldStart;

  /// Line count in the old file.
  final int oldCount;

  /// Starting line in the new file.
  final int newStart;

  /// Line count in the new file.
  final int newCount;

  /// Lines in this hunk.
  final List<DiffLine> lines;

  /// Creates a [DiffHunk].
  const DiffHunk({
    required this.header,
    this.oldStart = 0,
    this.oldCount = 0,
    this.newStart = 0,
    this.newCount = 0,
    this.lines = const [],
  });
}

// ---------------------------------------------------------------------------
// DiffLine
// ---------------------------------------------------------------------------

/// A single line in a diff hunk.
class DiffLine {
  /// The line content (without the prefix character).
  final String content;

  /// Type of this diff line.
  final DiffLineType type;

  /// Line number in the old file (null for additions).
  final int? oldLineNumber;

  /// Line number in the new file (null for deletions).
  final int? newLineNumber;

  /// Creates a [DiffLine].
  const DiffLine({
    required this.content,
    required this.type,
    this.oldLineNumber,
    this.newLineNumber,
  });
}

// ---------------------------------------------------------------------------
// WorkflowRun
// ---------------------------------------------------------------------------

/// A GitHub Actions workflow run.
class WorkflowRun {
  /// Workflow run ID.
  final int id;

  /// Workflow name.
  final String? name;

  /// Run status: queued, in_progress, completed.
  final String status;

  /// Conclusion: success, failure, cancelled, skipped, etc.
  final String? conclusion;

  /// Branch name.
  final String? headBranch;

  /// Head commit SHA.
  final String? headSha;

  /// HTML page URL.
  final String? htmlUrl;

  /// Run number.
  final int? runNumber;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Creates a [WorkflowRun].
  const WorkflowRun({
    required this.id,
    this.name,
    required this.status,
    this.conclusion,
    this.headBranch,
    this.headSha,
    this.htmlUrl,
    this.runNumber,
    this.createdAt,
    this.updatedAt,
  });

  /// Parses a GitHub API workflow run JSON object.
  factory WorkflowRun.fromGitHubJson(Map<String, dynamic> json) {
    return WorkflowRun(
      id: json['id'] as int,
      name: json['name'] as String?,
      status: json['status'] as String,
      conclusion: json['conclusion'] as String?,
      headBranch: json['head_branch'] as String?,
      headSha: json['head_sha'] as String?,
      htmlUrl: json['html_url'] as String?,
      runNumber: json['run_number'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
