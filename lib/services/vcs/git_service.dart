/// Local git CLI wrapper.
///
/// All git operations are executed via `dart:io` [Process]. A [ProcessRunner]
/// abstraction is injected for testability. All commands set
/// `GIT_TERMINAL_PROMPT=0` to prevent interactive auth prompt hangs.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../models/vcs_models.dart';

// ---------------------------------------------------------------------------
// ProcessRunner abstraction
// ---------------------------------------------------------------------------

/// Abstraction over [Process.run] for testability.
abstract class ProcessRunner {
  /// Runs [executable] with [arguments] in [workingDirectory].
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });

  /// Starts a long-running process (e.g. clone with progress).
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
}

/// Default [ProcessRunner] using the system shell.
class SystemProcessRunner implements ProcessRunner {
  /// Creates a [SystemProcessRunner].
  const SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    return Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }
}

// ---------------------------------------------------------------------------
// GitException
// ---------------------------------------------------------------------------

/// Exception thrown when a git command fails.
class GitException implements Exception {
  /// The git command that failed.
  final String command;

  /// Error message from stderr.
  final String message;

  /// Process exit code.
  final int exitCode;

  /// Creates a [GitException].
  const GitException({
    required this.command,
    required this.message,
    required this.exitCode,
  });

  @override
  String toString() => 'GitException($command, exit $exitCode): $message';
}

// ---------------------------------------------------------------------------
// GitService
// ---------------------------------------------------------------------------

/// Wraps the local `git` CLI for repository operations.
class GitService {
  final ProcessRunner _runner;

  /// Environment variables set on every git command.
  static const _env = {'GIT_TERMINAL_PROMPT': '0'};

  /// Creates a [GitService] with an optional custom [ProcessRunner].
  GitService({ProcessRunner? runner})
      : _runner = runner ?? const SystemProcessRunner();

  /// Returns the installed git version string.
  Future<String> getGitVersion() async {
    final result = await _run(['--version']);
    return result.stdout.toString().trim();
  }

  /// Clones [url] into [targetDir] with streaming progress.
  ///
  /// [branch] optionally checks out a specific branch.
  /// [onProgress] receives progress updates from git stderr.
  Future<void> clone(
    String url,
    String targetDir, {
    String? branch,
    void Function(CloneProgress)? onProgress,
  }) async {
    final args = ['clone', '--progress'];
    if (branch != null) args.addAll(['-b', branch]);
    args.addAll([url, targetDir]);

    final process = await _runner.start('git', args, environment: _env);

    // Git reports clone progress on stderr.
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (onProgress != null && line.contains('%')) {
        onProgress(CloneProgress.fromGitLine(line));
      }
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw GitException(
        command: 'clone',
        message: 'Clone failed with exit code $exitCode',
        exitCode: exitCode,
      );
    }
  }

  /// Pulls the latest changes from remote.
  Future<String> pull(String repoDir) async {
    final result = await _run(['pull'], workingDirectory: repoDir);
    return result.stdout.toString().trim();
  }

  /// Pushes local commits to remote.
  Future<String> push(String repoDir, {String? remote, String? branch}) async {
    final args = ['push'];
    if (remote != null) args.add(remote);
    if (branch != null) args.add(branch);
    final result = await _run(args, workingDirectory: repoDir);
    return result.stdout.toString().trim();
  }

  /// Fetches all remotes.
  Future<void> fetchAll(String repoDir) async {
    await _run(['fetch', '--all'], workingDirectory: repoDir);
  }

  /// Checks out [ref] (branch, tag, or commit SHA).
  Future<void> checkout(String repoDir, String ref) async {
    await _run(['checkout', ref], workingDirectory: repoDir);
  }

  /// Creates a new branch [name] from [startPoint].
  Future<void> createBranch(
    String repoDir,
    String name, {
    String? startPoint,
  }) async {
    final args = ['checkout', '-b', name];
    if (startPoint != null) args.add(startPoint);
    await _run(args, workingDirectory: repoDir);
  }

  /// Returns the working tree status using porcelain v2 format.
  Future<RepoStatus> status(String repoDir) async {
    final result = await _run(
      ['status', '--porcelain=v2', '--branch'],
      workingDirectory: repoDir,
    );
    final output = result.stdout.toString();
    final lines = const LineSplitter().convert(output);

    String branch = 'HEAD';
    int ahead = 0;
    int behind = 0;
    final changes = <FileChange>[];

    for (final line in lines) {
      if (line.startsWith('# branch.head ')) {
        branch = line.substring('# branch.head '.length);
      } else if (line.startsWith('# branch.ab ')) {
        final ab = RegExp(r'\+(\d+) -(\d+)').firstMatch(line);
        if (ab != null) {
          ahead = int.parse(ab.group(1)!);
          behind = int.parse(ab.group(2)!);
        }
      } else if (line.startsWith('1 ') || line.startsWith('2 ')) {
        // Changed entry.
        final parts = line.split(' ');
        if (parts.length >= 9) {
          final xy = parts[1];
          final path = parts.last;
          final indexStatus = xy[0];
          final wtStatus = xy[1];

          if (indexStatus != '.') {
            changes.add(FileChange(
              path: path,
              type: FileChangeType.fromGitCode(indexStatus),
              isStaged: true,
            ));
          }
          if (wtStatus != '.') {
            changes.add(FileChange(
              path: path,
              type: FileChangeType.fromGitCode(wtStatus),
              isStaged: false,
            ));
          }
        }
      } else if (line.startsWith('? ')) {
        // Untracked file.
        changes.add(FileChange(
          path: line.substring(2),
          type: FileChangeType.untracked,
          isStaged: false,
        ));
      }
    }

    return RepoStatus(
      branch: branch,
      changes: changes,
      ahead: ahead,
      behind: behind,
    );
  }

  /// Returns unified diff for unstaged changes, or for [path] only.
  Future<List<DiffResult>> diff(String repoDir, {String? path}) async {
    final args = ['diff'];
    if (path != null) args.addAll(['--', path]);
    final result = await _run(args, workingDirectory: repoDir);
    return _parseDiff(result.stdout.toString());
  }

  /// Returns diff stat (files changed, insertions, deletions).
  Future<String> diffStat(String repoDir) async {
    final result = await _run(['diff', '--stat'], workingDirectory: repoDir);
    return result.stdout.toString().trim();
  }

  /// Returns commit log in a parsable JSON format.
  Future<List<VcsCommit>> log(
    String repoDir, {
    int maxCount = 30,
    String? branch,
  }) async {
    final format =
        '{"sha":"%H","message":"%s","authorName":"%an","authorEmail":"%ae","date":"%aI"}';
    final args = [
      'log',
      '--format=$format',
      '-n',
      '$maxCount',
    ];
    if (branch != null) args.add(branch);
    final result = await _run(args, workingDirectory: repoDir);
    final output = result.stdout.toString().trim();
    if (output.isEmpty) return [];

    return const LineSplitter()
        .convert(output)
        .where((line) => line.isNotEmpty)
        .map((line) {
      try {
        return VcsCommit.fromGitJson(
          json.decode(line) as Map<String, dynamic>,
        );
      } catch (_) {
        return VcsCommit(sha: '', message: line);
      }
    }).toList();
  }

  /// Stages files and creates a commit.
  Future<String> commit(
    String repoDir,
    String message, {
    List<String>? files,
    bool all = false,
  }) async {
    if (all) {
      await _run(['add', '-A'], workingDirectory: repoDir);
    } else if (files != null && files.isNotEmpty) {
      await _run(['add', ...files], workingDirectory: repoDir);
    }
    final result = await _run(
      ['commit', '-m', message],
      workingDirectory: repoDir,
    );
    return result.stdout.toString().trim();
  }

  /// Merges [branch] into the current branch.
  Future<String> merge(String repoDir, String branch) async {
    final result = await _run(['merge', branch], workingDirectory: repoDir);
    return result.stdout.toString().trim();
  }

  /// Returns blame output for [filePath].
  Future<String> blame(String repoDir, String filePath) async {
    final result = await _run(
      ['blame', filePath],
      workingDirectory: repoDir,
    );
    return result.stdout.toString().trim();
  }

  /// Returns the list of stashes.
  Future<List<VcsStash>> stashList(String repoDir) async {
    final result = await _run(['stash', 'list'], workingDirectory: repoDir);
    final output = result.stdout.toString().trim();
    if (output.isEmpty) return [];
    return const LineSplitter()
        .convert(output)
        .map(VcsStash.fromGitLine)
        .toList();
  }

  /// Stashes the current working changes.
  Future<void> stashPush(String repoDir, {String? message}) async {
    final args = ['stash', 'push'];
    if (message != null) args.addAll(['-m', message]);
    await _run(args, workingDirectory: repoDir);
  }

  /// Pops the top stash entry.
  Future<void> stashPop(String repoDir, {int? index}) async {
    final args = ['stash', 'pop'];
    if (index != null) args.add('stash@{$index}');
    await _run(args, workingDirectory: repoDir);
  }

  /// Drops a stash entry by [index].
  Future<void> stashDrop(String repoDir, int index) async {
    await _run(
      ['stash', 'drop', 'stash@{$index}'],
      workingDirectory: repoDir,
    );
  }

  /// Creates an annotated tag.
  Future<void> createTag(
    String repoDir,
    String name, {
    String? message,
  }) async {
    final args = ['tag'];
    if (message != null) {
      args.addAll(['-a', name, '-m', message]);
    } else {
      args.add(name);
    }
    await _run(args, workingDirectory: repoDir);
  }

  /// Lists all tags.
  Future<List<String>> listTags(String repoDir) async {
    final result = await _run(['tag', '-l'], workingDirectory: repoDir);
    final output = result.stdout.toString().trim();
    if (output.isEmpty) return [];
    return const LineSplitter().convert(output);
  }

  /// Returns the current branch name.
  Future<String> currentBranch(String repoDir) async {
    final result = await _run(
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: repoDir,
    );
    return result.stdout.toString().trim();
  }

  /// Returns the remote URL for [remote] (defaults to "origin").
  Future<String> remoteUrl(String repoDir, {String remote = 'origin'}) async {
    final result = await _run(
      ['remote', 'get-url', remote],
      workingDirectory: repoDir,
    );
    return result.stdout.toString().trim();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<ProcessResult> _run(
    List<String> args, {
    String? workingDirectory,
  }) async {
    final result = await _runner.run(
      'git',
      args,
      workingDirectory: workingDirectory,
      environment: _env,
    );
    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      throw GitException(
        command: 'git ${args.join(' ')}',
        message: stderr.isNotEmpty ? stderr : 'Exit code ${result.exitCode}',
        exitCode: result.exitCode,
      );
    }
    return result;
  }

  List<DiffResult> _parseDiff(String output) {
    if (output.trim().isEmpty) return [];

    final results = <DiffResult>[];
    final fileBlocks = output.split(RegExp(r'^diff --git', multiLine: true));

    for (final block in fileBlocks) {
      if (block.trim().isEmpty) continue;

      String? filePath;
      final hunks = <DiffHunk>[];
      int additions = 0;
      int deletions = 0;
      bool isBinary = false;

      final lines = const LineSplitter().convert(block);
      for (final line in lines) {
        if (line.startsWith('+++ b/')) {
          filePath = line.substring(6);
        } else if (line.startsWith('--- a/') && filePath == null) {
          filePath = line.substring(6);
        } else if (line.contains('Binary files')) {
          isBinary = true;
        }
      }

      if (filePath == null && lines.isNotEmpty) {
        // Extract from the header: a/path b/path
        final headerMatch = RegExp(r'a/(.+?) b/').firstMatch(lines.first);
        filePath = headerMatch?.group(1) ?? 'unknown';
      }

      // Parse hunks.
      DiffHunk? currentHunk;
      var hunkLines = <DiffLine>[];
      int oldLine = 0;
      int newLine = 0;

      for (final line in lines) {
        final hunkMatch =
            RegExp(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@')
                .firstMatch(line);
        if (hunkMatch != null) {
          if (currentHunk != null) {
            hunks.add(DiffHunk(
              header: currentHunk.header,
              oldStart: currentHunk.oldStart,
              oldCount: currentHunk.oldCount,
              newStart: currentHunk.newStart,
              newCount: currentHunk.newCount,
              lines: List.unmodifiable(hunkLines),
            ));
          }
          oldLine = int.parse(hunkMatch.group(1)!);
          newLine = int.parse(hunkMatch.group(3)!);
          currentHunk = DiffHunk(
            header: line,
            oldStart: oldLine,
            oldCount: int.tryParse(hunkMatch.group(2) ?? '') ?? 0,
            newStart: newLine,
            newCount: int.tryParse(hunkMatch.group(4) ?? '') ?? 0,
          );
          hunkLines = [];
        } else if (currentHunk != null) {
          if (line.startsWith('+')) {
            hunkLines.add(DiffLine(
              content: line.substring(1),
              type: DiffLineType.addition,
              newLineNumber: newLine++,
            ));
            additions++;
          } else if (line.startsWith('-')) {
            hunkLines.add(DiffLine(
              content: line.substring(1),
              type: DiffLineType.deletion,
              oldLineNumber: oldLine++,
            ));
            deletions++;
          } else if (line.startsWith(' ')) {
            hunkLines.add(DiffLine(
              content: line.substring(1),
              type: DiffLineType.context,
              oldLineNumber: oldLine++,
              newLineNumber: newLine++,
            ));
          }
        }
      }

      if (currentHunk != null) {
        hunks.add(DiffHunk(
          header: currentHunk.header,
          oldStart: currentHunk.oldStart,
          oldCount: currentHunk.oldCount,
          newStart: currentHunk.newStart,
          newCount: currentHunk.newCount,
          lines: List.unmodifiable(hunkLines),
        ));
      }

      results.add(DiffResult(
        filePath: filePath ?? 'unknown',
        hunks: hunks,
        additions: additions,
        deletions: deletions,
        isBinary: isBinary,
      ));
    }

    return results;
  }
}
