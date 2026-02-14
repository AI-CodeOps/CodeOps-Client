/// Dispatches Claude Code agent processes with concurrency control.
///
/// Assembles persona-driven prompts, spawns `claude` CLI subprocesses via
/// [ProcessManager], and limits parallelism to [AgentDispatchConfig.maxConcurrent]
/// using a semaphore pattern. Each dispatch emits a stream of [AgentDispatchEvent]s
/// so callers can observe queue, start, output, completion, failure, and timeout
/// events in real time.
library;

import 'dart:async';

import '../../models/enums.dart';
import '../../utils/constants.dart';
import '../agent/persona_manager.dart';
import '../platform/claude_code_detector.dart';
import '../platform/process_manager.dart';

// ---------------------------------------------------------------------------
// AgentDispatchConfig
// ---------------------------------------------------------------------------

/// Configuration governing how agents are dispatched.
///
/// All fields have sensible defaults derived from [AppConstants].
class AgentDispatchConfig {
  /// Maximum number of agents allowed to run concurrently.
  final int maxConcurrent;

  /// Maximum wall-clock time an individual agent may run before being killed.
  final Duration agentTimeout;

  /// Claude model identifier passed to the `--model` flag.
  final String claudeModel;

  /// Maximum number of agentic turns the Claude CLI is allowed.
  final int maxTurns;

  /// Creates an [AgentDispatchConfig].
  ///
  /// Defaults are drawn from [AppConstants] when parameters are omitted.
  const AgentDispatchConfig({
    this.maxConcurrent = AppConstants.defaultMaxConcurrentAgents,
    this.agentTimeout = const Duration(
      minutes: AppConstants.defaultAgentTimeoutMinutes,
    ),
    this.claudeModel = AppConstants.defaultClaudeModelForDispatch,
    this.maxTurns = AppConstants.defaultMaxTurns,
  });
}

// ---------------------------------------------------------------------------
// AgentDispatchEvent hierarchy
// ---------------------------------------------------------------------------

/// Base class for events emitted during multi-agent dispatch.
sealed class AgentDispatchEvent {}

/// An agent has been added to the dispatch queue and is waiting for a slot.
class AgentQueued extends AgentDispatchEvent {
  /// The type of agent that was queued.
  final AgentType agentType;

  /// Creates an [AgentQueued] event.
  AgentQueued({required this.agentType});
}

/// An agent's process has been spawned and is now running.
class AgentStarted extends AgentDispatchEvent {
  /// The type of agent that started.
  final AgentType agentType;

  /// The managed process handle for the running agent.
  final ManagedProcess process;

  /// Creates an [AgentStarted] event.
  AgentStarted({required this.agentType, required this.process});
}

/// A line of standard output was received from a running agent.
class AgentOutput extends AgentDispatchEvent {
  /// The type of agent that produced the output.
  final AgentType agentType;

  /// A single line of stdout from the agent process.
  final String line;

  /// Creates an [AgentOutput] event.
  AgentOutput({required this.agentType, required this.line});
}

/// An agent exited normally (exit code may still indicate failure).
class AgentCompleted extends AgentDispatchEvent {
  /// The type of agent that completed.
  final AgentType agentType;

  /// The process exit code (0 typically means success).
  final int exitCode;

  /// The full accumulated standard output of the agent.
  final String output;

  /// Creates an [AgentCompleted] event.
  AgentCompleted({
    required this.agentType,
    required this.exitCode,
    required this.output,
  });
}

/// An agent process encountered an unexpected error.
class AgentFailed extends AgentDispatchEvent {
  /// The type of agent that failed.
  final AgentType agentType;

  /// A human-readable description of the failure.
  final String error;

  /// Creates an [AgentFailed] event.
  AgentFailed({required this.agentType, required this.error});
}

/// An agent exceeded its [AgentDispatchConfig.agentTimeout] and was killed.
class AgentTimedOut extends AgentDispatchEvent {
  /// The type of agent that timed out.
  final AgentType agentType;

  /// Creates an [AgentTimedOut] event.
  AgentTimedOut({required this.agentType});
}

// ---------------------------------------------------------------------------
// AgentDispatcher
// ---------------------------------------------------------------------------

/// Dispatches Claude Code CLI agents as subprocesses with concurrency control.
///
/// Uses [ProcessManager] to spawn and track child processes,
/// [PersonaManager] to assemble agent-specific prompts, and
/// [ClaudeCodeDetector] to resolve the CLI executable path.
class AgentDispatcher {
  final ProcessManager _processManager;
  final PersonaManager _personaManager;
  final ClaudeCodeDetector _claudeCodeDetector;

  /// Currently running agent processes keyed by [AgentType].
  final Map<AgentType, ManagedProcess> _activeProcesses = {};

  /// Whether [cancelAll] has been invoked and dispatch should abort.
  bool _cancelled = false;

  /// Creates an [AgentDispatcher].
  AgentDispatcher({
    required ProcessManager processManager,
    required PersonaManager personaManager,
    required ClaudeCodeDetector claudeCodeDetector,
  })  : _processManager = processManager,
        _personaManager = personaManager,
        _claudeCodeDetector = claudeCodeDetector;

  /// Returns an unmodifiable view of the currently active agent processes.
  Map<AgentType, ManagedProcess> get activeProcesses =>
      Map.unmodifiable(_activeProcesses);

  /// Dispatches a single agent as a Claude Code subprocess.
  ///
  /// Assembles the prompt via [PersonaManager], resolves the `claude`
  /// executable path, and spawns the process with the appropriate CLI flags.
  ///
  /// [agentType] determines which persona prompt is assembled.
  /// [teamId] and [projectId] scope persona and directive lookups.
  /// [projectPath] is the working directory for the subprocess.
  /// [projectName] is a human-readable label embedded in the prompt.
  /// [branch] is the git branch being analyzed.
  /// [mode] determines the job mode context for prompt assembly.
  /// [config] governs timeout, model, and turn limits.
  ///
  /// Returns the [ManagedProcess] handle for the spawned agent.
  Future<ManagedProcess> dispatchAgent({
    required AgentType agentType,
    required String teamId,
    required String projectId,
    required String projectPath,
    required String branch,
    required JobMode mode,
    required String projectName,
    AgentDispatchConfig config = const AgentDispatchConfig(),
    String? additionalContext,
    String? jiraTicketData,
    List<String>? specReferences,
  }) async {
    final assembledPrompt = await _personaManager.assemblePrompt(
      agentType: agentType,
      teamId: teamId,
      projectId: projectId,
      mode: mode,
      projectName: projectName,
      branch: branch,
      additionalContext: additionalContext,
      jiraTicketData: jiraTicketData,
      specReferences: specReferences,
    );

    final executablePath = await _claudeCodeDetector.getExecutablePath();
    final executable = executablePath ?? 'claude';

    final arguments = <String>[
      '--print',
      '--output-format',
      'json',
      '--max-turns',
      config.maxTurns.toString(),
      '--model',
      config.claudeModel,
      '-p',
      assembledPrompt,
    ];

    final process = await _processManager.spawn(
      executable: executable,
      arguments: arguments,
      workingDirectory: projectPath,
      timeout: config.agentTimeout,
    );

    _activeProcesses[agentType] = process;
    return process;
  }

  /// Dispatches multiple agents concurrently with semaphore-based throttling.
  ///
  /// Agents are queued and launched up to [AgentDispatchConfig.maxConcurrent]
  /// at a time. As each agent finishes, the next queued agent is started.
  /// Events are emitted on the returned stream to report lifecycle progress.
  ///
  /// [agentTypes] is the ordered list of agents to dispatch.
  /// [teamId] and [projectId] scope persona and directive lookups.
  /// [projectPath] is the working directory for all subprocesses.
  /// [branch] is the git branch being analyzed.
  /// [projectName] is a human-readable label embedded in prompts.
  /// [mode] determines the job mode context for prompt assembly.
  /// [config] governs concurrency, timeout, model, and turn limits.
  Stream<AgentDispatchEvent> dispatchAll({
    required List<AgentType> agentTypes,
    required String teamId,
    required String projectId,
    required String projectPath,
    required String branch,
    required JobMode mode,
    required String projectName,
    AgentDispatchConfig config = const AgentDispatchConfig(),
    String? additionalContext,
    String? jiraTicketData,
    List<String>? specReferences,
  }) {
    final controller = StreamController<AgentDispatchEvent>.broadcast();
    _cancelled = false;

    () async {
      final queue = List<AgentType>.from(agentTypes);
      var slotCount = 0;

      // Emit queued events for all agents.
      for (final agentType in queue) {
        controller.add(AgentQueued(agentType: agentType));
      }

      Future<void> launchAgent(AgentType agentType) async {
        if (_cancelled) return;

        try {
          final process = await dispatchAgent(
            agentType: agentType,
            teamId: teamId,
            projectId: projectId,
            projectPath: projectPath,
            branch: branch,
            mode: mode,
            projectName: projectName,
            config: config,
            additionalContext: additionalContext,
            jiraTicketData: jiraTicketData,
            specReferences: specReferences,
          );

          controller.add(AgentStarted(agentType: agentType, process: process));

          final stdoutBuffer = StringBuffer();

          // Listen to stdout lines and forward as events.
          final stdoutSubscription = process.stdout.listen((line) {
            stdoutBuffer.writeln(line);
            controller.add(AgentOutput(agentType: agentType, line: line));
          });

          final stderrSubscription = process.stderr.listen((_) {});

          // Race between process exit and timeout.
          final exitCode = await Future.any<int>([
            process.exitCode,
            Future.delayed(config.agentTimeout, () => -1),
          ]);

          await stdoutSubscription.cancel();
          await stderrSubscription.cancel();

          if (exitCode == -1) {
            // Timeout occurred.
            await _processManager.kill(process);
            _activeProcesses.remove(agentType);
            controller.add(AgentTimedOut(agentType: agentType));
          } else {
            _activeProcesses.remove(agentType);
            controller.add(AgentCompleted(
              agentType: agentType,
              exitCode: exitCode,
              output: stdoutBuffer.toString(),
            ));
          }
        } catch (e) {
          _activeProcesses.remove(agentType);
          controller.add(AgentFailed(
            agentType: agentType,
            error: e.toString(),
          ));
        }
      }

      // Process the queue with semaphore-based concurrency control.
      var queueIndex = 0;
      final completer = Completer<void>();

      void scheduleNext() {
        while (slotCount < config.maxConcurrent &&
            queueIndex < queue.length &&
            !_cancelled) {
          final agentType = queue[queueIndex++];
          slotCount++;

          final agentFuture = launchAgent(agentType);
          agentFuture.whenComplete(() {
            slotCount--;
            if (queueIndex < queue.length && !_cancelled) {
              scheduleNext();
            } else if (slotCount == 0 && !completer.isCompleted) {
              completer.complete();
            }
          });
        }

        // If the queue was empty from the start.
        if (queue.isEmpty && !completer.isCompleted) {
          completer.complete();
        }
      }

      scheduleNext();
      await completer.future;

      await controller.close();
    }();

    return controller.stream;
  }

  /// Cancels all running agent processes.
  ///
  /// Sets the internal cancelled flag to prevent new dispatches,
  /// then kills every active process via [ProcessManager].
  Future<void> cancelAll() async {
    _cancelled = true;
    final processes = Map<AgentType, ManagedProcess>.from(_activeProcesses);
    _activeProcesses.clear();

    for (final entry in processes.entries) {
      try {
        await _processManager.kill(entry.value);
      } catch (_) {
        // Best-effort cleanup; swallow errors from already-dead processes.
      }
    }
  }
}
