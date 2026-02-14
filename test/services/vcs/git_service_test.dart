// Tests for GitService.
//
// Verifies git CLI output parsing (status, log, stash), version detection,
// branch resolution, and error handling for non-zero exit codes.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/vcs_models.dart';
import 'package:codeops/services/vcs/git_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockProcessRunner extends Mock implements ProcessRunner {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a successful [ProcessResult].
ProcessResult _ok(String stdout, {String stderr = ''}) {
  return ProcessResult(0, 0, stdout, stderr);
}

/// Creates a failed [ProcessResult] with the given [exitCode].
ProcessResult _fail(int exitCode, {String stderr = 'fatal: error'}) {
  return ProcessResult(0, exitCode, '', stderr);
}

void main() {
  late MockProcessRunner mockRunner;
  late GitService gitService;

  setUp(() {
    mockRunner = MockProcessRunner();
    gitService = GitService(runner: mockRunner);
  });

  // -------------------------------------------------------------------------
  // getGitVersion
  // -------------------------------------------------------------------------
  group('getGitVersion', () {
    test('returns trimmed version string', () async {
      when(() => mockRunner.run(
            'git',
            ['--version'],
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok('git version 2.43.0\n'));

      final version = await gitService.getGitVersion();

      expect(version, 'git version 2.43.0');
    });

    test('throws GitException on non-zero exit code', () async {
      when(() => mockRunner.run(
            'git',
            ['--version'],
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _fail(1, stderr: 'git not found'));

      expect(
        () => gitService.getGitVersion(),
        throwsA(isA<GitException>().having(
          (e) => e.exitCode,
          'exitCode',
          1,
        )),
      );
    });
  });

  // -------------------------------------------------------------------------
  // currentBranch
  // -------------------------------------------------------------------------
  group('currentBranch', () {
    test('returns trimmed branch name', () async {
      when(() => mockRunner.run(
            'git',
            ['rev-parse', '--abbrev-ref', 'HEAD'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok('main\n'));

      final branch = await gitService.currentBranch('/repo');

      expect(branch, 'main');
    });

    test('throws GitException when not in a repo', () async {
      when(() => mockRunner.run(
            'git',
            ['rev-parse', '--abbrev-ref', 'HEAD'],
            workingDirectory: '/not-a-repo',
            environment: any(named: 'environment'),
          )).thenAnswer(
              (_) async => _fail(128, stderr: 'fatal: not a git repository'));

      expect(
        () => gitService.currentBranch('/not-a-repo'),
        throwsA(isA<GitException>().having(
          (e) => e.message,
          'message',
          contains('not a git repository'),
        )),
      );
    });
  });

  // -------------------------------------------------------------------------
  // status (porcelain v2 parsing)
  // -------------------------------------------------------------------------
  group('status', () {
    test('parses branch name from porcelain v2 output', () async {
      const output = '# branch.head main\n'
          '# branch.ab +0 -0\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      expect(status.branch, 'main');
      expect(status.ahead, 0);
      expect(status.behind, 0);
      expect(status.isClean, isTrue);
    });

    test('parses ahead/behind counts', () async {
      const output = '# branch.head feature\n'
          '# branch.ab +3 -2\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      expect(status.branch, 'feature');
      expect(status.ahead, 3);
      expect(status.behind, 2);
    });

    test('parses modified file (staged)', () async {
      const output = '# branch.head main\n'
          '1 M. N... 100644 100644 100644 abc123 def456 lib/main.dart\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      expect(status.changes, hasLength(1));
      expect(status.changes[0].path, 'lib/main.dart');
      expect(status.changes[0].type, FileChangeType.modified);
      expect(status.changes[0].isStaged, isTrue);
    });

    test('parses modified file (unstaged)', () async {
      const output = '# branch.head main\n'
          '1 .M N... 100644 100644 100644 abc123 def456 lib/main.dart\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      expect(status.changes, hasLength(1));
      expect(status.changes[0].isStaged, isFalse);
    });

    test('parses both staged and unstaged changes for same file', () async {
      const output = '# branch.head main\n'
          '1 MM N... 100644 100644 100644 abc123 def456 lib/main.dart\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      // Both staged (M in index) and unstaged (M in worktree) entries.
      expect(status.changes, hasLength(2));
      expect(status.changes[0].isStaged, isTrue);
      expect(status.changes[1].isStaged, isFalse);
    });

    test('parses untracked files', () async {
      const output = '# branch.head main\n'
          '? new_file.dart\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      expect(status.changes, hasLength(1));
      expect(status.changes[0].path, 'new_file.dart');
      expect(status.changes[0].type, FileChangeType.untracked);
      expect(status.changes[0].isStaged, isFalse);
    });

    test('parses added file', () async {
      const output = '# branch.head main\n'
          '1 A. N... 000000 100644 100644 0000000 abc1234 lib/new.dart\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      expect(status.changes, hasLength(1));
      expect(status.changes[0].type, FileChangeType.added);
      expect(status.changes[0].isStaged, isTrue);
    });

    test('parses deleted file', () async {
      const output = '# branch.head main\n'
          '1 D. N... 100644 000000 000000 abc1234 0000000 lib/old.dart\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      expect(status.changes, hasLength(1));
      expect(status.changes[0].type, FileChangeType.deleted);
    });

    test('returns clean status for empty output', () async {
      const output = '# branch.head main\n';

      when(() => mockRunner.run(
            'git',
            ['status', '--porcelain=v2', '--branch'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final status = await gitService.status('/repo');

      expect(status.isClean, isTrue);
      expect(status.changes, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // log (JSON format parsing)
  // -------------------------------------------------------------------------
  group('log', () {
    test('parses JSON-formatted commit entries', () async {
      const output =
          '{"sha":"abc1234567890","message":"Fix bug","authorName":"Alice","authorEmail":"alice@test.com","date":"2025-01-15T10:00:00+00:00"}\n'
          '{"sha":"def4567890123","message":"Add feature","authorName":"Bob","authorEmail":"bob@test.com","date":"2025-01-14T09:00:00+00:00"}\n';

      when(() => mockRunner.run(
            'git',
            any(that: contains('log')),
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final commits = await gitService.log('/repo');

      expect(commits, hasLength(2));
      expect(commits[0].sha, 'abc1234567890');
      expect(commits[0].message, 'Fix bug');
      expect(commits[0].authorName, 'Alice');
      expect(commits[0].authorEmail, 'alice@test.com');
      expect(commits[0].date, isA<DateTime>());
      expect(commits[1].sha, 'def4567890123');
      expect(commits[1].message, 'Add feature');
    });

    test('returns empty list for empty output', () async {
      when(() => mockRunner.run(
            'git',
            any(that: contains('log')),
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(''));

      final commits = await gitService.log('/repo');

      expect(commits, isEmpty);
    });

    test('handles malformed JSON lines gracefully', () async {
      const output = 'not valid json\n';

      when(() => mockRunner.run(
            'git',
            any(that: contains('log')),
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final commits = await gitService.log('/repo');

      // Falls back to VcsCommit with empty sha and line as message.
      expect(commits, hasLength(1));
      expect(commits[0].sha, '');
      expect(commits[0].message, 'not valid json');
    });

    test('passes branch argument when provided', () async {
      when(() => mockRunner.run(
            'git',
            any(that: contains('develop')),
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(''));

      await gitService.log('/repo', branch: 'develop');

      verify(() => mockRunner.run(
            'git',
            any(that: contains('develop')),
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // stashList
  // -------------------------------------------------------------------------
  group('stashList', () {
    test('parses stash entries', () async {
      const output = 'stash@{0}: On main: work in progress\n'
          'stash@{1}: On feature: half done\n';

      when(() => mockRunner.run(
            'git',
            ['stash', 'list'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(output));

      final stashes = await gitService.stashList('/repo');

      expect(stashes, hasLength(2));
      expect(stashes[0].index, 0);
      expect(stashes[0].branch, 'main');
      expect(stashes[0].message, 'work in progress');
      expect(stashes[1].index, 1);
      expect(stashes[1].branch, 'feature');
    });

    test('returns empty list when no stashes', () async {
      when(() => mockRunner.run(
            'git',
            ['stash', 'list'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(''));

      final stashes = await gitService.stashList('/repo');

      expect(stashes, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // pull
  // -------------------------------------------------------------------------
  group('pull', () {
    test('returns trimmed output on success', () async {
      when(() => mockRunner.run(
            'git',
            ['pull'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok('Already up to date.\n'));

      final result = await gitService.pull('/repo');

      expect(result, 'Already up to date.');
    });
  });

  // -------------------------------------------------------------------------
  // diff
  // -------------------------------------------------------------------------
  group('diff', () {
    test('returns empty list for clean working tree', () async {
      when(() => mockRunner.run(
            'git',
            ['diff'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(''));

      final results = await gitService.diff('/repo');

      expect(results, isEmpty);
    });

    test('parses unified diff output', () async {
      const diffOutput = 'diff --git a/lib/main.dart b/lib/main.dart\n'
          'index abc1234..def5678 100644\n'
          '--- a/lib/main.dart\n'
          '+++ b/lib/main.dart\n'
          '@@ -1,3 +1,4 @@\n'
          ' import "dart:io";\n'
          '+import "dart:async";\n'
          ' \n'
          ' void main() {\n';

      when(() => mockRunner.run(
            'git',
            ['diff'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => _ok(diffOutput));

      final results = await gitService.diff('/repo');

      expect(results, hasLength(1));
      expect(results[0].filePath, 'lib/main.dart');
      expect(results[0].additions, 1);
      expect(results[0].deletions, 0);
      expect(results[0].hunks, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  // remoteUrl
  // -------------------------------------------------------------------------
  group('remoteUrl', () {
    test('returns trimmed remote URL', () async {
      when(() => mockRunner.run(
            'git',
            ['remote', 'get-url', 'origin'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer(
              (_) async => _ok('https://github.com/acme/widget.git\n'));

      final url = await gitService.remoteUrl('/repo');

      expect(url, 'https://github.com/acme/widget.git');
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------
  group('error handling', () {
    test('non-zero exit code throws GitException with command', () async {
      when(() => mockRunner.run(
            'git',
            ['checkout', 'nonexistent'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async =>
              _fail(1, stderr: "error: pathspec 'nonexistent' did not match"));

      expect(
        () => gitService.checkout('/repo', 'nonexistent'),
        throwsA(
          isA<GitException>()
              .having((e) => e.exitCode, 'exitCode', 1)
              .having(
                  (e) => e.command, 'command', 'git checkout nonexistent')
              .having((e) => e.message, 'message',
                  contains('pathspec')),
        ),
      );
    });

    test('GitException toString includes command and exit code', () {
      const ex = GitException(
        command: 'git status',
        message: 'not a repo',
        exitCode: 128,
      );
      expect(ex.toString(), contains('git status'));
      expect(ex.toString(), contains('128'));
      expect(ex.toString(), contains('not a repo'));
    });

    test('empty stderr falls back to exit code message', () async {
      when(() => mockRunner.run(
            'git',
            ['push'],
            workingDirectory: '/repo',
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => ProcessResult(0, 1, '', ''));

      expect(
        () => gitService.push('/repo'),
        throwsA(isA<GitException>().having(
          (e) => e.message,
          'message',
          'Exit code 1',
        )),
      );
    });
  });
}
