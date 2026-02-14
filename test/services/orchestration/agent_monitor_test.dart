// Tests for AgentMonitor.
//
// Verifies single-process monitoring (completion, failure, stdout collection,
// callbacks, timeout + kill) and multi-process monitoring via monitorAll
// (completion events and progress events).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/services/platform/process_manager.dart';
import 'package:codeops/services/orchestration/agent_monitor.dart';

class MockProcessManager extends Mock implements ProcessManager {}

class MockManagedProcess extends Mock implements ManagedProcess {}

void main() {
  late MockProcessManager mockProcessManager;
  late AgentMonitor agentMonitor;

  setUpAll(() {
    registerFallbackValue(MockManagedProcess());
  });

  setUp(() {
    mockProcessManager = MockProcessManager();
    agentMonitor = AgentMonitor(processManager: mockProcessManager);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Creates a [MockManagedProcess] wired to the given controllers and
  /// completer so that stdout, stderr, and exitCode behave like a real process.
  MockManagedProcess makeMockProcess({
    required StreamController<String> stdoutController,
    required StreamController<String> stderrController,
    required Completer<int> exitCodeCompleter,
  }) {
    final process = MockManagedProcess();
    when(() => process.stdout).thenAnswer((_) => stdoutController.stream);
    when(() => process.stderr).thenAnswer((_) => stderrController.stream);
    when(() => process.exitCode).thenAnswer((_) => exitCodeCompleter.future);
    return process;
  }

  // ---------------------------------------------------------------------------
  // monitor
  // ---------------------------------------------------------------------------

  group('monitor', () {
    test('completes with status completed when exit code is 0', () async {
      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCodeCompleter = Completer<int>();

      final process = makeMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCodeCompleter: exitCodeCompleter,
      );

      final future = agentMonitor.monitor(
        process: process,
        agentType: AgentType.security,
        timeout: const Duration(seconds: 5),
      );

      await stdoutController.close();
      await stderrController.close();
      exitCodeCompleter.complete(0);

      final result = await future;

      expect(result.status, AgentMonitorStatus.completed);
      expect(result.exitCode, 0);
      expect(result.agentType, AgentType.security);
    });

    test('completes with status failed when exit code is non-zero', () async {
      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCodeCompleter = Completer<int>();

      final process = makeMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCodeCompleter: exitCodeCompleter,
      );

      final future = agentMonitor.monitor(
        process: process,
        agentType: AgentType.codeQuality,
        timeout: const Duration(seconds: 5),
      );

      await stdoutController.close();
      await stderrController.close();
      exitCodeCompleter.complete(1);

      final result = await future;

      expect(result.status, AgentMonitorStatus.failed);
      expect(result.exitCode, 1);
      expect(result.agentType, AgentType.codeQuality);
    });

    test('collects stdout output', () async {
      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCodeCompleter = Completer<int>();

      final process = makeMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCodeCompleter: exitCodeCompleter,
      );

      final future = agentMonitor.monitor(
        process: process,
        agentType: AgentType.buildHealth,
        timeout: const Duration(seconds: 5),
      );

      stdoutController.add('line 1');
      stdoutController.add('line 2');
      stdoutController.add('line 3');
      await stdoutController.close();
      await stderrController.close();
      exitCodeCompleter.complete(0);

      final result = await future;

      expect(result.stdout, contains('line 1'));
      expect(result.stdout, contains('line 2'));
      expect(result.stdout, contains('line 3'));
    });

    test('calls onStdout callback for each line', () async {
      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCodeCompleter = Completer<int>();

      final process = makeMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCodeCompleter: exitCodeCompleter,
      );

      final callbackLines = <String>[];

      final future = agentMonitor.monitor(
        process: process,
        agentType: AgentType.testCoverage,
        timeout: const Duration(seconds: 5),
        onStdout: callbackLines.add,
      );

      stdoutController.add('alpha');
      stdoutController.add('bravo');
      await stdoutController.close();
      await stderrController.close();
      exitCodeCompleter.complete(0);

      await future;

      expect(callbackLines, ['alpha', 'bravo']);
    });

    test('times out and kills process when timeout expires', () async {
      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      // Never complete the exit code — simulates a hung process.
      final exitCodeCompleter = Completer<int>();

      final process = makeMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCodeCompleter: exitCodeCompleter,
      );

      when(() => mockProcessManager.kill(any())).thenAnswer((_) async {});

      final future = agentMonitor.monitor(
        process: process,
        agentType: AgentType.performance,
        timeout: const Duration(milliseconds: 100),
      );

      final result = await future;

      expect(result.status, AgentMonitorStatus.timedOut);
      expect(result.exitCode, -1);
      expect(result.agentType, AgentType.performance);
      verify(() => mockProcessManager.kill(any())).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // monitorAll
  // ---------------------------------------------------------------------------

  group('monitorAll', () {
    test('emits AgentCompletedEvent for each process', () async {
      // Process A — security agent.
      final stdoutA = StreamController<String>.broadcast();
      final stderrA = StreamController<String>.broadcast();
      final exitA = Completer<int>();
      final processA = makeMockProcess(
        stdoutController: stdoutA,
        stderrController: stderrA,
        exitCodeCompleter: exitA,
      );

      // Process B — code quality agent.
      final stdoutB = StreamController<String>.broadcast();
      final stderrB = StreamController<String>.broadcast();
      final exitB = Completer<int>();
      final processB = makeMockProcess(
        stdoutController: stdoutB,
        stderrController: stderrB,
        exitCodeCompleter: exitB,
      );

      final stream = agentMonitor.monitorAll(
        processes: {
          AgentType.security: processA,
          AgentType.codeQuality: processB,
        },
        timeout: const Duration(seconds: 5),
      );

      // Collect events asynchronously — must subscribe to the broadcast stream
      // before any events are emitted, otherwise they are lost.
      final eventsFuture = stream.toList();

      // Allow the monitorAll IIFE to iterate both entries and set up
      // subscriptions for all processes before closing streams.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await stdoutA.close();
      await stderrA.close();
      exitA.complete(0);

      await stdoutB.close();
      await stderrB.close();
      exitB.complete(0);

      final events = await eventsFuture;

      final completedEvents =
          events.whereType<AgentCompletedEvent>().toList();
      expect(completedEvents, hasLength(2));

      final agentTypes =
          completedEvents.map((e) => e.result.agentType).toSet();
      expect(agentTypes, containsAll([AgentType.security, AgentType.codeQuality]));
    });

    test('emits AgentProgressEvent for stdout lines', () async {
      final stdoutController = StreamController<String>.broadcast();
      final stderrController = StreamController<String>.broadcast();
      final exitCodeCompleter = Completer<int>();

      final process = makeMockProcess(
        stdoutController: stdoutController,
        stderrController: stderrController,
        exitCodeCompleter: exitCodeCompleter,
      );

      final stream = agentMonitor.monitorAll(
        processes: {AgentType.security: process},
        timeout: const Duration(seconds: 5),
      );

      // Collect events asynchronously.
      final eventsFuture = stream.toList();

      // Allow the stream subscription to be set up before emitting events.
      await Future<void>.delayed(Duration.zero);

      stdoutController.add('scanning dependencies...');
      stdoutController.add('found 3 vulnerabilities');
      await stdoutController.close();
      await stderrController.close();
      exitCodeCompleter.complete(0);

      final events = await eventsFuture;

      final progressEvents =
          events.whereType<AgentProgressEvent>().toList();
      expect(progressEvents, hasLength(2));
      expect(progressEvents[0].agentType, AgentType.security);
      expect(progressEvents[0].line, 'scanning dependencies...');
      expect(progressEvents[1].line, 'found 3 vulnerabilities');
    });
  });
}
