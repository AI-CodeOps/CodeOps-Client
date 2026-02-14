/// Monitors running agent processes, collecting output and detecting
/// completion, failure, and timeout.
///
/// Wraps one or more [ManagedProcess] handles, collecting their stdout/stderr
/// into buffers and racing exit codes against a configurable timeout. Results
/// are returned as [AgentMonitorResult] objects or streamed as
/// [AgentMonitorEvent]s for multi-agent monitoring.
library;

import 'dart:async';

import '../../models/enums.dart';
import '../platform/process_manager.dart';

// ---------------------------------------------------------------------------
// AgentMonitorStatus
// ---------------------------------------------------------------------------

/// Terminal status of a monitored agent process.
enum AgentMonitorStatus {
  /// The process exited with code 0.
  completed,

  /// The process exited with a non-zero code.
  failed,

  /// The process did not exit within the configured timeout.
  timedOut,

  /// The process was cancelled via external intervention.
  cancelled;

  /// Human-readable display label.
  String get displayName => switch (this) {
        AgentMonitorStatus.completed => 'Completed',
        AgentMonitorStatus.failed => 'Failed',
        AgentMonitorStatus.timedOut => 'Timed Out',
        AgentMonitorStatus.cancelled => 'Cancelled',
      };
}

// ---------------------------------------------------------------------------
// AgentMonitorResult
// ---------------------------------------------------------------------------

/// The result of monitoring a single agent process to completion.
class AgentMonitorResult {
  /// The type of agent that was monitored.
  final AgentType agentType;

  /// The process exit code, or -1 if the process timed out or was cancelled.
  final int exitCode;

  /// The full accumulated standard output.
  final String stdout;

  /// The full accumulated standard error output.
  final String stderr;

  /// Wall-clock time from the start of monitoring to completion.
  final Duration elapsed;

  /// The terminal status of the agent.
  final AgentMonitorStatus status;

  /// Creates an [AgentMonitorResult].
  const AgentMonitorResult({
    required this.agentType,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.elapsed,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// AgentMonitorEvent hierarchy
// ---------------------------------------------------------------------------

/// Base class for events emitted during multi-agent monitoring.
sealed class AgentMonitorEvent {}

/// A line of output was received from a monitored agent.
class AgentProgressEvent extends AgentMonitorEvent {
  /// The type of agent that produced the output.
  final AgentType agentType;

  /// A single line of stdout from the agent process.
  final String line;

  /// Creates an [AgentProgressEvent].
  AgentProgressEvent({required this.agentType, required this.line});
}

/// A monitored agent completed (successfully or with failure).
class AgentCompletedEvent extends AgentMonitorEvent {
  /// The full monitoring result for the completed agent.
  final AgentMonitorResult result;

  /// Creates an [AgentCompletedEvent].
  AgentCompletedEvent({required this.result});
}

/// A monitored agent encountered an unexpected error.
class AgentFailedEvent extends AgentMonitorEvent {
  /// The type of agent that failed.
  final AgentType agentType;

  /// A human-readable description of the failure.
  final String error;

  /// Creates an [AgentFailedEvent].
  AgentFailedEvent({required this.agentType, required this.error});
}

// ---------------------------------------------------------------------------
// AgentMonitor
// ---------------------------------------------------------------------------

/// Monitors agent subprocesses, collecting output and enforcing timeouts.
///
/// Uses [ProcessManager] to kill timed-out processes. Provides both a
/// single-process [monitor] method and a multi-process [monitorAll] stream.
class AgentMonitor {
  final ProcessManager _processManager;

  /// Creates an [AgentMonitor].
  AgentMonitor({required ProcessManager processManager})
      : _processManager = processManager;

  /// Monitors a single agent process to completion.
  ///
  /// Collects stdout and stderr into buffers and races the process exit code
  /// against [timeout]. If the timeout fires first, the process is killed via
  /// [ProcessManager] and the result status is [AgentMonitorStatus.timedOut].
  ///
  /// [process] is the managed process handle to monitor.
  /// [agentType] identifies the agent for result tagging.
  /// [timeout] is the maximum wall-clock duration before the process is killed.
  /// [onStdout] is an optional per-line callback for stdout data.
  /// [onStderr] is an optional per-line callback for stderr data.
  Future<AgentMonitorResult> monitor({
    required ManagedProcess process,
    required AgentType agentType,
    required Duration timeout,
    void Function(String)? onStdout,
    void Function(String)? onStderr,
  }) async {
    final stopwatch = Stopwatch()..start();
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutSubscription = process.stdout.listen((line) {
      stdoutBuffer.writeln(line);
      onStdout?.call(line);
    });

    final stderrSubscription = process.stderr.listen((line) {
      stderrBuffer.writeln(line);
      onStderr?.call(line);
    });

    // Race between normal exit and timeout.
    final timeoutCompleter = Completer<void>();
    final timer = Timer(timeout, () {
      if (!timeoutCompleter.isCompleted) {
        timeoutCompleter.complete();
      }
    });

    late final int exitCode;
    late final AgentMonitorStatus status;

    try {
      final result = await Future.any<Object>([
        process.exitCode.then((code) => code),
        timeoutCompleter.future.then((_) => 'timeout'),
      ]);

      if (result is int) {
        // Process exited before timeout.
        timer.cancel();
        exitCode = result;
        status = exitCode == 0
            ? AgentMonitorStatus.completed
            : AgentMonitorStatus.failed;
      } else {
        // Timeout fired first.
        exitCode = -1;
        status = AgentMonitorStatus.timedOut;
        try {
          await _processManager.kill(process);
        } catch (_) {
          // Process may have already exited between the race and the kill.
        }
      }
    } catch (e) {
      timer.cancel();
      exitCode = -1;
      status = AgentMonitorStatus.failed;
    }

    await stdoutSubscription.cancel();
    await stderrSubscription.cancel();
    stopwatch.stop();

    return AgentMonitorResult(
      agentType: agentType,
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
      elapsed: stopwatch.elapsed,
      status: status,
    );
  }

  /// Monitors all provided agent processes concurrently.
  ///
  /// Each process is monitored in parallel. Progress events are emitted as
  /// stdout lines arrive, and completion events are emitted when each process
  /// finishes, times out, or fails. The stream closes after all processes
  /// have been resolved.
  ///
  /// [processes] maps agent types to their running managed process handles.
  /// [timeout] is the maximum wall-clock duration before any process is killed.
  Stream<AgentMonitorEvent> monitorAll({
    required Map<AgentType, ManagedProcess> processes,
    required Duration timeout,
  }) {
    final controller = StreamController<AgentMonitorEvent>.broadcast();

    () async {
      final futures = <Future<void>>[];

      for (final entry in processes.entries) {
        final agentType = entry.key;
        final process = entry.value;

        final future = monitor(
          process: process,
          agentType: agentType,
          timeout: timeout,
          onStdout: (line) {
            controller.add(AgentProgressEvent(
              agentType: agentType,
              line: line,
            ));
          },
        ).then((result) {
          controller.add(AgentCompletedEvent(result: result));
        }).catchError((Object error) {
          controller.add(AgentFailedEvent(
            agentType: agentType,
            error: error.toString(),
          ));
        });

        futures.add(future);
      }

      await Future.wait(futures);
      await controller.close();
    }();

    return controller.stream;
  }
}
