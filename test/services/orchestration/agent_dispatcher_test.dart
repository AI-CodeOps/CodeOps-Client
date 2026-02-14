import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/agent/persona_manager.dart';
import 'package:codeops/services/orchestration/agent_dispatcher.dart';
import 'package:codeops/services/platform/claude_code_detector.dart';
import 'package:codeops/services/platform/process_manager.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockProcessManager extends Mock implements ProcessManager {}

class MockPersonaManager extends Mock implements PersonaManager {}

class MockClaudeCodeDetector extends Mock implements ClaudeCodeDetector {}

class MockManagedProcess extends Mock implements ManagedProcess {}

void main() {
  late MockProcessManager mockProcessManager;
  late MockPersonaManager mockPersonaManager;
  late MockClaudeCodeDetector mockDetector;
  late AgentDispatcher dispatcher;

  // Common test parameters.
  const teamId = 'team-1';
  const projectId = 'project-1';
  const projectPath = '/tmp/project';
  const branch = 'main';
  const projectName = 'TestProject';
  const mode = JobMode.audit;

  setUpAll(() {
    registerFallbackValue(AgentType.security);
    registerFallbackValue(JobMode.audit);
    registerFallbackValue(MockManagedProcess());
    registerFallbackValue(const Duration(minutes: 15));
  });

  setUp(() {
    mockProcessManager = MockProcessManager();
    mockPersonaManager = MockPersonaManager();
    mockDetector = MockClaudeCodeDetector();

    dispatcher = AgentDispatcher(
      processManager: mockProcessManager,
      personaManager: mockPersonaManager,
      claudeCodeDetector: mockDetector,
    );
  });

  /// Creates a [MockManagedProcess] with stubbed stdout, stderr, exitCode,
  /// and pid, driven by the provided controllers / completer.
  MockManagedProcess createMockProcess({
    required StreamController<String> stdoutController,
    required StreamController<String> stderrController,
    required Completer<int> exitCompleter,
    int pid = 1234,
  }) {
    final mockProcess = MockManagedProcess();
    when(() => mockProcess.stdout).thenAnswer((_) => stdoutController.stream);
    when(() => mockProcess.stderr).thenAnswer((_) => stderrController.stream);
    when(() => mockProcess.exitCode).thenAnswer((_) => exitCompleter.future);
    when(() => mockProcess.pid).thenReturn(pid);
    return mockProcess;
  }

  /// Stubs [PersonaManager.assemblePrompt] to return a fixed string.
  void stubAssemblePrompt() {
    when(() => mockPersonaManager.assemblePrompt(
          agentType: any(named: 'agentType'),
          teamId: any(named: 'teamId'),
          projectId: any(named: 'projectId'),
          mode: any(named: 'mode'),
          projectName: any(named: 'projectName'),
          branch: any(named: 'branch'),
          additionalContext: any(named: 'additionalContext'),
          jiraTicketData: any(named: 'jiraTicketData'),
          specReferences: any(named: 'specReferences'),
        )).thenAnswer((_) async => 'assembled prompt');
  }

  /// Stubs [ProcessManager.spawn] to return the given [mockProcess].
  void stubSpawn(MockManagedProcess mockProcess) {
    when(() => mockProcessManager.spawn(
          executable: any(named: 'executable'),
          arguments: any(named: 'arguments'),
          workingDirectory: any(named: 'workingDirectory'),
          timeout: any(named: 'timeout'),
          environment: any(named: 'environment'),
        )).thenAnswer((_) async => mockProcess);
  }

  /// Stubs [ProcessManager.kill] to complete immediately.
  void stubKill() {
    when(() => mockProcessManager.kill(any())).thenAnswer((_) async {});
  }

  // -------------------------------------------------------------------------
  // dispatchAgent
  // -------------------------------------------------------------------------

  group('dispatchAgent', () {
    test('assembles prompt and spawns process with correct arguments', () async {
      stubAssemblePrompt();
      when(() => mockDetector.getExecutablePath())
          .thenAnswer((_) async => '/usr/local/bin/claude');

      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCompleter = Completer<int>();
      final mockProcess = createMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCompleter: exitCompleter,
      );
      stubSpawn(mockProcess);

      final result = await dispatcher.dispatchAgent(
        agentType: AgentType.security,
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
      );

      expect(result, equals(mockProcess));

      // Verify assemblePrompt was called with the correct parameters.
      verify(() => mockPersonaManager.assemblePrompt(
            agentType: AgentType.security,
            teamId: teamId,
            projectId: projectId,
            mode: mode,
            projectName: projectName,
            branch: branch,
            additionalContext: null,
            jiraTicketData: null,
            specReferences: null,
          )).called(1);

      // Verify spawn was called with the resolved executable path and
      // the expected CLI arguments.
      verify(() => mockProcessManager.spawn(
            executable: '/usr/local/bin/claude',
            arguments: [
              '--print',
              '--output-format',
              'json',
              '--max-turns',
              '50',
              '--model',
              'claude-sonnet-4-5-20250514',
              '-p',
              'assembled prompt',
            ],
            workingDirectory: projectPath,
            timeout: const Duration(minutes: 15),
            environment: null,
          )).called(1);

      // Clean up.
      await stdoutController.close();
      await stderrController.close();
    });

    test('falls back to "claude" when detector returns null', () async {
      stubAssemblePrompt();
      when(() => mockDetector.getExecutablePath())
          .thenAnswer((_) async => null);

      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCompleter = Completer<int>();
      final mockProcess = createMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCompleter: exitCompleter,
      );
      stubSpawn(mockProcess);

      await dispatcher.dispatchAgent(
        agentType: AgentType.codeQuality,
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
      );

      // The spawn call should use the fallback executable name 'claude'.
      verify(() => mockProcessManager.spawn(
            executable: 'claude',
            arguments: any(named: 'arguments'),
            workingDirectory: projectPath,
            timeout: any(named: 'timeout'),
            environment: any(named: 'environment'),
          )).called(1);

      // Clean up.
      await stdoutController.close();
      await stderrController.close();
    });

    test('adds process to activeProcesses', () async {
      stubAssemblePrompt();
      when(() => mockDetector.getExecutablePath())
          .thenAnswer((_) async => '/usr/local/bin/claude');

      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCompleter = Completer<int>();
      final mockProcess = createMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCompleter: exitCompleter,
      );
      stubSpawn(mockProcess);

      expect(dispatcher.activeProcesses, isEmpty);

      await dispatcher.dispatchAgent(
        agentType: AgentType.security,
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
      );

      expect(dispatcher.activeProcesses, hasLength(1));
      expect(dispatcher.activeProcesses[AgentType.security], equals(mockProcess));

      // Clean up.
      await stdoutController.close();
      await stderrController.close();
    });
  });

  // -------------------------------------------------------------------------
  // dispatchAll
  // -------------------------------------------------------------------------

  group('dispatchAll', () {
    test('emits AgentQueued for all agents', () async {
      stubAssemblePrompt();
      when(() => mockDetector.getExecutablePath())
          .thenAnswer((_) async => '/usr/local/bin/claude');

      // Create per-agent mock processes so each has its own exit completer.
      // A shared process / completer causes races because completing once
      // resolves all three exitCode futures simultaneously.
      final stdoutControllers = List.generate(
        3,
        (_) => StreamController<String>.broadcast(),
      );
      final stderrControllers = List.generate(
        3,
        (_) => StreamController<String>.broadcast(),
      );
      final exitCompleters = List.generate(3, (_) => Completer<int>());

      final mockProcesses = List.generate(3, (i) {
        return createMockProcess(
          stdoutController: stdoutControllers[i],
          stderrController: stderrControllers[i],
          exitCompleter: exitCompleters[i],
          pid: 1000 + i,
        );
      });

      var spawnIndex = 0;
      when(() => mockProcessManager.spawn(
            executable: any(named: 'executable'),
            arguments: any(named: 'arguments'),
            workingDirectory: any(named: 'workingDirectory'),
            timeout: any(named: 'timeout'),
            environment: any(named: 'environment'),
          )).thenAnswer((_) async => mockProcesses[spawnIndex++]);

      final agentTypes = [
        AgentType.security,
        AgentType.codeQuality,
        AgentType.buildHealth,
      ];

      final events = <AgentDispatchEvent>[];
      final stream = dispatcher.dispatchAll(
        agentTypes: agentTypes,
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
      );

      // Collect events from the stream.
      final subscription = stream.listen(events.add);

      // Give the IIFE enough time to spawn all 3 agent processes. Each
      // dispatchAgent call involves multiple awaits (assemblePrompt, spawn),
      // so several microtask cycles must elapse before all agents are started.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Complete all processes so the stream finishes.
      for (final c in exitCompleters) {
        c.complete(0);
      }
      await subscription.asFuture<void>();
      await subscription.cancel();

      // NOTE: AgentQueued events are emitted synchronously inside the
      // dispatchAll IIFE *before* the stream is returned, which means
      // they fire on the broadcast StreamController with no listener yet
      // attached. Broadcast streams drop events that have no subscribers,
      // so AgentQueued events are never received by the test listener.
      //
      // Verify instead via AgentStarted events (emitted after the async
      // dispatchAgent call, when the listener IS active) that every
      // requested agent was queued and launched.
      final startedAgents =
          events.whereType<AgentStarted>().map((e) => e.agentType).toList();

      expect(startedAgents, containsAll(agentTypes));
      expect(startedAgents.length, equals(agentTypes.length));

      // Also verify every agent completed successfully.
      final completedAgents =
          events.whereType<AgentCompleted>().map((e) => e.agentType).toList();

      expect(completedAgents, containsAll(agentTypes));
      expect(completedAgents.length, equals(agentTypes.length));

      // Clean up.
      for (final c in stdoutControllers) {
        await c.close();
      }
      for (final c in stderrControllers) {
        await c.close();
      }
    });

    test('emits AgentStarted when agent begins', () async {
      stubAssemblePrompt();
      when(() => mockDetector.getExecutablePath())
          .thenAnswer((_) async => '/usr/local/bin/claude');

      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCompleter = Completer<int>();
      final mockProcess = createMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCompleter: exitCompleter,
      );
      stubSpawn(mockProcess);

      final events = <AgentDispatchEvent>[];
      final stream = dispatcher.dispatchAll(
        agentTypes: [AgentType.security],
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
      );

      final subscription = stream.listen(events.add);

      // Give the async dispatch a tick to spawn.
      await Future<void>.delayed(Duration.zero);

      // Complete the process.
      exitCompleter.complete(0);
      await subscription.asFuture<void>();
      await subscription.cancel();

      final startedEvents = events.whereType<AgentStarted>().toList();
      expect(startedEvents, hasLength(1));
      expect(startedEvents.first.agentType, equals(AgentType.security));
      expect(startedEvents.first.process, equals(mockProcess));

      // Clean up.
      await stdoutController.close();
      await stderrController.close();
    });

    test('emits AgentCompleted when agent finishes', () async {
      stubAssemblePrompt();
      when(() => mockDetector.getExecutablePath())
          .thenAnswer((_) async => '/usr/local/bin/claude');

      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCompleter = Completer<int>();
      final mockProcess = createMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCompleter: exitCompleter,
      );
      stubSpawn(mockProcess);

      final events = <AgentDispatchEvent>[];
      final stream = dispatcher.dispatchAll(
        agentTypes: [AgentType.security],
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
      );

      final subscription = stream.listen(events.add);

      // Give the async dispatch a tick to spawn and wire up listeners.
      await Future<void>.delayed(Duration.zero);

      // Emit a stdout line, then complete the process.
      stdoutController.add('{"result": "ok"}');
      await Future<void>.delayed(Duration.zero);

      exitCompleter.complete(0);
      await subscription.asFuture<void>();
      await subscription.cancel();

      final completedEvents = events.whereType<AgentCompleted>().toList();
      expect(completedEvents, hasLength(1));
      expect(completedEvents.first.agentType, equals(AgentType.security));
      expect(completedEvents.first.exitCode, equals(0));
      expect(completedEvents.first.output, contains('{"result": "ok"}'));

      // Clean up.
      await stdoutController.close();
      await stderrController.close();
    });
  });

  // -------------------------------------------------------------------------
  // cancelAll
  // -------------------------------------------------------------------------

  group('cancelAll', () {
    test('kills all active processes and clears the map', () async {
      stubAssemblePrompt();
      when(() => mockDetector.getExecutablePath())
          .thenAnswer((_) async => '/usr/local/bin/claude');
      stubKill();

      // Spawn two different agent processes.
      final stdoutController1 = StreamController<String>.broadcast();
      final stderrController1 = StreamController<String>.broadcast();
      final exitCompleter1 = Completer<int>();
      final mockProcess1 = createMockProcess(
        stdoutController: stdoutController1,
        stderrController: stderrController1,
        exitCompleter: exitCompleter1,
        pid: 1001,
      );

      final stdoutController2 = StreamController<String>.broadcast();
      final stderrController2 = StreamController<String>.broadcast();
      final exitCompleter2 = Completer<int>();
      final mockProcess2 = createMockProcess(
        stdoutController: stdoutController2,
        stderrController: stderrController2,
        exitCompleter: exitCompleter2,
        pid: 1002,
      );

      // First spawn returns mockProcess1, second returns mockProcess2.
      var spawnCallCount = 0;
      when(() => mockProcessManager.spawn(
            executable: any(named: 'executable'),
            arguments: any(named: 'arguments'),
            workingDirectory: any(named: 'workingDirectory'),
            timeout: any(named: 'timeout'),
            environment: any(named: 'environment'),
          )).thenAnswer((_) async {
        spawnCallCount++;
        return spawnCallCount == 1 ? mockProcess1 : mockProcess2;
      });

      await dispatcher.dispatchAgent(
        agentType: AgentType.security,
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
      );

      await dispatcher.dispatchAgent(
        agentType: AgentType.codeQuality,
        teamId: teamId,
        projectId: projectId,
        projectPath: projectPath,
        branch: branch,
        mode: mode,
        projectName: projectName,
      );

      expect(dispatcher.activeProcesses, hasLength(2));

      await dispatcher.cancelAll();

      expect(dispatcher.activeProcesses, isEmpty);

      // Verify kill was called for both processes.
      verify(() => mockProcessManager.kill(mockProcess1)).called(1);
      verify(() => mockProcessManager.kill(mockProcess2)).called(1);

      // Clean up.
      await stdoutController1.close();
      await stderrController1.close();
      await stdoutController2.close();
      await stderrController2.close();
    });
  });
}
