/// Low-level subprocess lifecycle management.
///
/// Provides [ManagedProcess] as a rich wrapper around `dart:io` [Process] and
/// [ProcessManager] to spawn, track, and tear down subprocesses with optional
/// timeouts.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// ManagedProcess
// ---------------------------------------------------------------------------

/// A running subprocess with observable stdout/stderr streams, elapsed time
/// tracking, and lifecycle helpers.
///
/// Created exclusively by [ProcessManager.spawn]. Callers should listen to
/// [stdout] and [stderr] for incremental output and await [exitCode] for
/// completion.
class ManagedProcess {
  /// Operating-system process ID.
  final int pid;

  /// The executable that was launched (e.g. `"claude"`).
  final String executable;

  /// Timestamp when the process was started.
  final DateTime startedAt;

  final Process _process;
  final StreamController<String> _stdoutController;
  final StreamController<String> _stderrController;
  final Completer<int> _exitCodeCompleter;
  bool _disposed = false;

  /// Creates a [ManagedProcess].
  ///
  /// This constructor is internal; use [ProcessManager.spawn] instead.
  ManagedProcess._({
    required this.pid,
    required this.executable,
    required this.startedAt,
    required Process process,
    required StreamController<String> stdoutController,
    required StreamController<String> stderrController,
    required Completer<int> exitCodeCompleter,
  })  : _process = process,
        _stdoutController = stdoutController,
        _stderrController = stderrController,
        _exitCodeCompleter = exitCodeCompleter;

  /// A broadcast stream of decoded stdout lines.
  Stream<String> get stdout => _stdoutController.stream;

  /// A broadcast stream of decoded stderr lines.
  Stream<String> get stderr => _stderrController.stream;

  /// Completes with the process exit code when the subprocess finishes.
  Future<int> get exitCode => _exitCodeCompleter.future;

  /// The wall-clock time elapsed since the process was spawned.
  Duration get elapsed => DateTime.now().difference(startedAt);

  /// Returns `true` if the process has not yet exited and has not been
  /// disposed.
  bool get isRunning => !_exitCodeCompleter.isCompleted && !_disposed;

  /// Sends a SIGTERM (or platform equivalent) to the subprocess.
  ///
  /// Returns `true` if the signal was successfully delivered.
  Future<bool> kill() async {
    if (!isRunning) return false;
    return _process.kill();
  }

  /// Releases all stream controllers held by this process.
  ///
  /// Callers must not interact with [stdout], [stderr], or [exitCode] after
  /// dispose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stdoutController.close();
    _stderrController.close();
    if (!_exitCodeCompleter.isCompleted) {
      _exitCodeCompleter.complete(-1);
    }
  }
}

// ---------------------------------------------------------------------------
// ProcessManager
// ---------------------------------------------------------------------------

/// Spawns, tracks, and tears down subprocesses.
///
/// Every subprocess is wrapped in a [ManagedProcess] that provides decoded
/// line-by-line output streams, elapsed-time tracking, and optional
/// timeout-based automatic termination.
///
/// Call [dispose] when the manager is no longer needed to kill all remaining
/// processes and free resources.
class ProcessManager {
  final List<ManagedProcess> _active = [];
  bool _disposed = false;

  /// Creates a [ProcessManager].
  ProcessManager();

  /// Starts a new subprocess.
  ///
  /// [executable] and [arguments] are passed directly to [Process.start].
  /// [workingDirectory] sets the subprocess working directory.
  /// [timeout], if provided, will automatically kill the process after the
  /// given duration and complete its exit code with `-1`.
  /// [environment] supplies additional environment variables.
  ///
  /// Returns a [ManagedProcess] whose [ManagedProcess.stdout] and
  /// [ManagedProcess.stderr] streams emit decoded lines as they arrive.
  Future<ManagedProcess> spawn({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    Duration? timeout,
    Map<String, String>? environment,
  }) async {
    if (_disposed) {
      throw StateError('ProcessManager has been disposed');
    }

    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );

    final stdoutController = StreamController<String>.broadcast();
    final stderrController = StreamController<String>.broadcast();
    final exitCodeCompleter = Completer<int>();

    final managed = ManagedProcess._(
      pid: process.pid,
      executable: executable,
      startedAt: DateTime.now(),
      process: process,
      stdoutController: stdoutController,
      stderrController: stderrController,
      exitCodeCompleter: exitCodeCompleter,
    );

    _active.add(managed);

    // Wire stdout line-by-line into the broadcast controller.
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          stdoutController.add,
          onError: stdoutController.addError,
          onDone: stdoutController.close,
        );

    // Wire stderr line-by-line into the broadcast controller.
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          stderrController.add,
          onError: stderrController.addError,
          onDone: stderrController.close,
        );

    // Handle normal exit.
    _handleExit(managed, process, timeout);

    return managed;
  }

  /// Kills a single [ManagedProcess] and removes it from the active list.
  Future<void> kill(ManagedProcess process) async {
    await process.kill();
    _active.remove(process);
    process.dispose();
  }

  /// Kills all active processes managed by this instance.
  Future<void> killAll() async {
    final snapshot = List<ManagedProcess>.of(_active);
    for (final process in snapshot) {
      await process.kill();
      process.dispose();
    }
    _active.clear();
  }

  /// Returns an unmodifiable view of all currently running processes.
  List<ManagedProcess> get activeProcesses =>
      List<ManagedProcess>.unmodifiable(_active);

  /// Kills all active processes and prevents future spawning.
  ///
  /// After calling dispose, [spawn] will throw a [StateError].
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    killAll();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Waits for the process to exit — optionally racing against a timeout —
  /// and completes the exit code completer.
  void _handleExit(
    ManagedProcess managed,
    Process process,
    Duration? timeout,
  ) {
    if (timeout != null) {
      _handleExitWithTimeout(managed, process, timeout);
    } else {
      _handleExitWithoutTimeout(managed, process);
    }
  }

  /// Waits for normal process exit, then cleans up.
  void _handleExitWithoutTimeout(
    ManagedProcess managed,
    Process process,
  ) {
    process.exitCode.then((code) {
      if (!managed._exitCodeCompleter.isCompleted) {
        managed._exitCodeCompleter.complete(code);
      }
      _active.remove(managed);
    });
  }

  /// Races the process exit against a timeout. If the timeout fires first
  /// the process is killed and exit code completes with `-1`.
  void _handleExitWithTimeout(
    ManagedProcess managed,
    Process process,
    Duration timeout,
  ) {
    Timer? timer;

    timer = Timer(timeout, () {
      if (managed.isRunning) {
        process.kill();
        if (!managed._exitCodeCompleter.isCompleted) {
          managed._exitCodeCompleter.complete(-1);
        }
        _active.remove(managed);
      }
    });

    process.exitCode.then((code) {
      timer?.cancel();
      if (!managed._exitCodeCompleter.isCompleted) {
        managed._exitCodeCompleter.complete(code);
      }
      _active.remove(managed);
    });
  }
}
