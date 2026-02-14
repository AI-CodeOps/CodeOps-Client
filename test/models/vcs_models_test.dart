// Tests for all VCS model classes, enums, and factory methods.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/vcs_models.dart';

void main() {
  // -------------------------------------------------------------------------
  // FileChangeType
  // -------------------------------------------------------------------------
  group('FileChangeType', () {
    test('fromGitCode maps all known codes', () {
      expect(FileChangeType.fromGitCode('A'), FileChangeType.added);
      expect(FileChangeType.fromGitCode('M'), FileChangeType.modified);
      expect(FileChangeType.fromGitCode('D'), FileChangeType.deleted);
      expect(FileChangeType.fromGitCode('R'), FileChangeType.renamed);
      expect(FileChangeType.fromGitCode('C'), FileChangeType.copied);
      expect(FileChangeType.fromGitCode('?'), FileChangeType.untracked);
    });

    test('fromGitCode defaults to modified for unknown code', () {
      expect(FileChangeType.fromGitCode('X'), FileChangeType.modified);
    });

    test('displayName returns human label', () {
      expect(FileChangeType.added.displayName, 'Added');
      expect(FileChangeType.deleted.displayName, 'Deleted');
      expect(FileChangeType.untracked.displayName, 'Untracked');
    });
  });

  // -------------------------------------------------------------------------
  // DiffLineType
  // -------------------------------------------------------------------------
  group('DiffLineType', () {
    test('fromPrefix parses addition', () {
      expect(DiffLineType.fromPrefix('+added line'), DiffLineType.addition);
    });

    test('fromPrefix parses deletion', () {
      expect(DiffLineType.fromPrefix('-removed line'), DiffLineType.deletion);
    });

    test('fromPrefix parses header', () {
      expect(
          DiffLineType.fromPrefix('@@ -1,3 +1,4 @@'), DiffLineType.header);
    });

    test('fromPrefix defaults to context', () {
      expect(DiffLineType.fromPrefix(' context line'), DiffLineType.context);
      expect(DiffLineType.fromPrefix('plain text'), DiffLineType.context);
    });
  });

  // -------------------------------------------------------------------------
  // VcsCredentials
  // -------------------------------------------------------------------------
  group('VcsCredentials', () {
    test('constructor stores all fields', () {
      const creds = VcsCredentials(
        authType: GitHubAuthType.pat,
        token: 'ghp_abc123',
        username: 'alice',
      );
      expect(creds.authType, GitHubAuthType.pat);
      expect(creds.token, 'ghp_abc123');
      expect(creds.username, 'alice');
    });
  });

  // -------------------------------------------------------------------------
  // VcsOrganization
  // -------------------------------------------------------------------------
  group('VcsOrganization', () {
    test('fromGitHubJson parses full data', () {
      final org = VcsOrganization.fromGitHubJson({
        'login': 'acme',
        'name': 'Acme Corp',
        'avatar_url': 'https://example.com/avatar.png',
        'description': 'We make stuff',
        'public_repos': 42,
      });
      expect(org.login, 'acme');
      expect(org.name, 'Acme Corp');
      expect(org.avatarUrl, 'https://example.com/avatar.png');
      expect(org.description, 'We make stuff');
      expect(org.publicRepos, 42);
    });

    test('fromGitHubJson handles null fields', () {
      final org = VcsOrganization.fromGitHubJson({
        'login': 'minimal',
      });
      expect(org.login, 'minimal');
      expect(org.name, isNull);
      expect(org.avatarUrl, isNull);
      expect(org.description, isNull);
      expect(org.publicRepos, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // VcsRepository
  // -------------------------------------------------------------------------
  group('VcsRepository', () {
    test('fromGitHubJson parses full data', () {
      final repo = VcsRepository.fromGitHubJson({
        'id': 123,
        'full_name': 'acme/widget',
        'name': 'widget',
        'description': 'A widget library',
        'language': 'Dart',
        'stargazers_count': 100,
        'forks_count': 25,
        'open_issues_count': 5,
        'default_branch': 'develop',
        'private': true,
        'fork': false,
        'archived': false,
        'clone_url': 'https://github.com/acme/widget.git',
        'ssh_url': 'git@github.com:acme/widget.git',
        'html_url': 'https://github.com/acme/widget',
        'pushed_at': '2025-01-15T10:00:00Z',
        'updated_at': '2025-01-15T10:00:00Z',
        'size': 1024,
        'owner': {
          'login': 'acme',
          'avatar_url': 'https://example.com/avatar.png',
        },
      });
      expect(repo.id, 123);
      expect(repo.fullName, 'acme/widget');
      expect(repo.name, 'widget');
      expect(repo.language, 'Dart');
      expect(repo.stargazersCount, 100);
      expect(repo.isPrivate, isTrue);
      expect(repo.defaultBranch, 'develop');
      expect(repo.ownerLogin, 'acme');
      expect(repo.sizeKb, 1024);
      expect(repo.pushedAt, isA<DateTime>());
    });

    test('fromGitHubJson handles null fields', () {
      final repo = VcsRepository.fromGitHubJson({
        'id': 1,
        'full_name': 'a/b',
        'name': 'b',
      });
      expect(repo.description, isNull);
      expect(repo.language, isNull);
      expect(repo.stargazersCount, 0);
      expect(repo.defaultBranch, 'main');
      expect(repo.isPrivate, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // VcsBranch
  // -------------------------------------------------------------------------
  group('VcsBranch', () {
    test('fromGitHubJson parses full data', () {
      final branch = VcsBranch.fromGitHubJson({
        'name': 'main',
        'protected': true,
        'commit': {'sha': 'abc123'},
      });
      expect(branch.name, 'main');
      expect(branch.sha, 'abc123');
      expect(branch.isProtected, isTrue);
    });

    test('fromGitHubJson handles missing commit', () {
      final branch = VcsBranch.fromGitHubJson({
        'name': 'dev',
      });
      expect(branch.sha, isNull);
      expect(branch.isProtected, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // VcsPullRequest
  // -------------------------------------------------------------------------
  group('VcsPullRequest', () {
    test('fromGitHubJson parses full data', () {
      final pr = VcsPullRequest.fromGitHubJson({
        'number': 42,
        'title': 'Add feature',
        'body': 'Some description',
        'state': 'open',
        'draft': true,
        'merged': false,
        'commits': 3,
        'changed_files': 5,
        'additions': 100,
        'deletions': 20,
        'created_at': '2025-01-15T10:00:00Z',
        'updated_at': '2025-01-15T12:00:00Z',
        'html_url': 'https://github.com/a/b/pull/42',
        'head': {'ref': 'feature-branch'},
        'base': {'ref': 'main'},
        'user': {
          'login': 'alice',
          'avatar_url': 'https://example.com/alice.png',
        },
      });
      expect(pr.number, 42);
      expect(pr.title, 'Add feature');
      expect(pr.state, 'open');
      expect(pr.isDraft, isTrue);
      expect(pr.headBranch, 'feature-branch');
      expect(pr.baseBranch, 'main');
      expect(pr.authorLogin, 'alice');
      expect(pr.commits, 3);
    });

    test('fromGitHubJson handles null fields', () {
      final pr = VcsPullRequest.fromGitHubJson({
        'number': 1,
        'title': 'PR',
        'state': 'open',
      });
      expect(pr.headBranch, '');
      expect(pr.baseBranch, '');
      expect(pr.authorLogin, isNull);
      expect(pr.isDraft, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // CreatePRRequest
  // -------------------------------------------------------------------------
  group('CreatePRRequest', () {
    test('toJson serializes all fields', () {
      const request = CreatePRRequest(
        title: 'New Feature',
        head: 'feature',
        base: 'main',
        body: 'Description',
        draft: true,
      );
      final json = request.toJson();
      expect(json['title'], 'New Feature');
      expect(json['head'], 'feature');
      expect(json['base'], 'main');
      expect(json['body'], 'Description');
      expect(json['draft'], true);
    });

    test('toJson omits null body', () {
      const request = CreatePRRequest(
        title: 'PR',
        head: 'h',
        base: 'b',
      );
      expect(request.toJson().containsKey('body'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // VcsCommit
  // -------------------------------------------------------------------------
  group('VcsCommit', () {
    test('fromGitHubJson parses full data', () {
      final commit = VcsCommit.fromGitHubJson({
        'sha': 'abc1234567890',
        'html_url': 'https://github.com/a/b/commit/abc',
        'commit': {
          'message': 'Fix bug',
          'author': {
            'name': 'Alice',
            'email': 'alice@test.com',
            'date': '2025-01-15T10:00:00Z',
          },
        },
        'author': {
          'login': 'alice',
          'avatar_url': 'https://example.com/alice.png',
        },
      });
      expect(commit.sha, 'abc1234567890');
      expect(commit.shortSha, 'abc1234');
      expect(commit.message, 'Fix bug');
      expect(commit.authorName, 'Alice');
      expect(commit.authorLogin, 'alice');
      expect(commit.date, isA<DateTime>());
    });

    test('fromGitJson parses git log JSON', () {
      final commit = VcsCommit.fromGitJson({
        'sha': '1234567890abcdef',
        'message': 'Update readme',
        'authorName': 'Bob',
        'authorEmail': 'bob@test.com',
        'date': '2025-01-15T10:00:00+00:00',
      });
      expect(commit.sha, '1234567890abcdef');
      expect(commit.message, 'Update readme');
      expect(commit.authorName, 'Bob');
    });

    test('shortSha handles short sha', () {
      const commit = VcsCommit(sha: 'abc', message: 'test');
      expect(commit.shortSha, 'abc');
    });
  });

  // -------------------------------------------------------------------------
  // VcsStash
  // -------------------------------------------------------------------------
  group('VcsStash', () {
    test('fromGitLine parses standard format', () {
      final stash = VcsStash.fromGitLine(
          'stash@{0}: On main: work in progress');
      expect(stash.index, 0);
      expect(stash.branch, 'main');
      expect(stash.message, 'work in progress');
    });

    test('fromGitLine parses without branch', () {
      final stash = VcsStash.fromGitLine(
          'stash@{1}: WIP on feature');
      expect(stash.index, 1);
      expect(stash.message, 'WIP on feature');
    });
  });

  // -------------------------------------------------------------------------
  // VcsTag
  // -------------------------------------------------------------------------
  group('VcsTag', () {
    test('fromGitHubJson parses release data', () {
      final tag = VcsTag.fromGitHubJson({
        'tag_name': 'v1.0.0',
        'body': 'Initial release',
        'published_at': '2025-01-15T10:00:00Z',
        'zipball_url': 'https://api.github.com/repos/a/b/zipball/v1.0.0',
        'tarball_url': 'https://api.github.com/repos/a/b/tarball/v1.0.0',
        'author': {'login': 'alice'},
      });
      expect(tag.name, 'v1.0.0');
      expect(tag.message, 'Initial release');
      expect(tag.taggerName, 'alice');
      expect(tag.date, isA<DateTime>());
    });

    test('fromGitHubJson handles minimal data', () {
      final tag = VcsTag.fromGitHubJson({'name': 'v0.1'});
      expect(tag.name, 'v0.1');
      expect(tag.message, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // CloneProgress
  // -------------------------------------------------------------------------
  group('CloneProgress', () {
    test('fromGitLine parses progress with counts', () {
      final p = CloneProgress.fromGitLine(
          'Receiving objects:  42% (84/200)');
      expect(p.phase, 'Receiving objects');
      expect(p.percent, 42);
      expect(p.current, 84);
      expect(p.total, 200);
    });

    test('fromGitLine parses progress without counts', () {
      final p = CloneProgress.fromGitLine(
          'Resolving deltas:  75%');
      expect(p.phase, 'Resolving deltas');
      expect(p.percent, 75);
      expect(p.current, isNull);
    });

    test('fromGitLine handles unparseable line', () {
      final p = CloneProgress.fromGitLine('Cloning into...');
      expect(p.percent, 0);
    });
  });

  // -------------------------------------------------------------------------
  // RepoStatus
  // -------------------------------------------------------------------------
  group('RepoStatus', () {
    test('isClean returns true when no changes', () {
      const status = RepoStatus(branch: 'main');
      expect(status.isClean, isTrue);
    });

    test('isClean returns false when changes exist', () {
      const status = RepoStatus(
        branch: 'main',
        changes: [
          FileChange(path: 'file.dart', type: FileChangeType.modified),
        ],
      );
      expect(status.isClean, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // DiffResult / DiffHunk / DiffLine
  // -------------------------------------------------------------------------
  group('DiffResult', () {
    test('constructor stores all fields', () {
      const diff = DiffResult(
        filePath: 'lib/main.dart',
        additions: 5,
        deletions: 2,
        isBinary: false,
      );
      expect(diff.filePath, 'lib/main.dart');
      expect(diff.additions, 5);
      expect(diff.deletions, 2);
      expect(diff.hunks, isEmpty);
    });
  });

  group('DiffHunk', () {
    test('constructor stores header and line counts', () {
      const hunk = DiffHunk(
        header: '@@ -1,3 +1,4 @@',
        oldStart: 1,
        oldCount: 3,
        newStart: 1,
        newCount: 4,
      );
      expect(hunk.header, '@@ -1,3 +1,4 @@');
      expect(hunk.oldStart, 1);
      expect(hunk.newCount, 4);
    });
  });

  group('DiffLine', () {
    test('constructor stores content and type', () {
      const line = DiffLine(
        content: 'added line',
        type: DiffLineType.addition,
        newLineNumber: 5,
      );
      expect(line.content, 'added line');
      expect(line.type, DiffLineType.addition);
      expect(line.newLineNumber, 5);
      expect(line.oldLineNumber, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // WorkflowRun
  // -------------------------------------------------------------------------
  group('WorkflowRun', () {
    test('fromGitHubJson parses full data', () {
      final run = WorkflowRun.fromGitHubJson({
        'id': 999,
        'name': 'CI',
        'status': 'completed',
        'conclusion': 'success',
        'head_branch': 'main',
        'head_sha': 'abc123',
        'html_url': 'https://github.com/a/b/actions/runs/999',
        'run_number': 42,
        'created_at': '2025-01-15T10:00:00Z',
        'updated_at': '2025-01-15T10:05:00Z',
      });
      expect(run.id, 999);
      expect(run.name, 'CI');
      expect(run.status, 'completed');
      expect(run.conclusion, 'success');
      expect(run.headBranch, 'main');
      expect(run.runNumber, 42);
      expect(run.createdAt, isA<DateTime>());
    });

    test('fromGitHubJson handles null fields', () {
      final run = WorkflowRun.fromGitHubJson({
        'id': 1,
        'status': 'queued',
      });
      expect(run.name, isNull);
      expect(run.conclusion, isNull);
      expect(run.headBranch, isNull);
    });
  });
}
