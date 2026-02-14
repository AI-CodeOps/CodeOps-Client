// Tests for ProcessManager.
//
// Verifies subprocess spawning, lifecycle tracking, stdout/stderr capture,
// kill/killAll semantics, dispose behaviour, timeout enforcement, and
// ManagedProcess properties (isRunning, elapsed).
//
// These tests exercise real subprocesses (echo, sleep, true, false) via
// dart:io so they are integration-level but fast and deterministic.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/services/platform/process_manager.dart';

void main() {
  late ProcessManager manager;

  setUp(() {
    manager = ProcessManager();
  });

  tearDown(() {
    manager.dispose();
  });

  // -------------------------------------------------------------------------
  // spawn
  // -------------------------------------------------------------------------
  group('spawn', () {
    test('returns ManagedProcess with valid pid', () async {
      final process = await manager.spawn(
        executable: 'true',
        arguments: [],
        workingDirectory: '/tmp',
      );

      expect(process, isA<ManagedProcess>());
      expect(process.pid, isPositive);
      expect(process.executable, 'true');
    });

    test('captures stdout output', () async {
      final process = await manager.spawn(
        executable: 'echo',
        arguments: ['hello'],
        workingDirectory: '/tmp',
      );

      final lines = await process.stdout.toList();
      expect(lines, contains('hello'));
    });

    test('exitCode completes with 0 for successful process', () async {
      final process = await manager.spawn(
        executable: 'true',
        arguments: [],
        workingDirectory: '/tmp',
      );

      final code = await process.exitCode;
      expect(code, 0);
    });

    test('exitCode completes with non-zero for failed process', () async {
      final process = await manager.spawn(
        executable: 'false',
        arguments: [],
        workingDirectory: '/tmp',
      );

      final code = await process.exitCode;
      expect(code, isNot(0));
    });

    test('process is tracked in activeProcesses while running', () async {
      final process = await manager.spawn(
        executable: 'sleep',
        arguments: ['10'],
        workingDirectory: '/tmp',
      );

      expect(manager.activeProcesses, contains(process));

      // Clean up — kill so tearDown doesn't hang.
      await manager.kill(process);
    });

    test('process is removed from activeProcesses after exit', () async {
      final process = await manager.spawn(
        executable: 'true',
        arguments: [],
        workingDirectory: '/tmp',
      );

      // Wait for the process to finish and be cleaned up.
      await process.exitCode;

      // Give the internal handler a microtask to remove it from _active.
      await Future<void>.delayed(Duration.zero);

      expect(manager.activeProcesses, isNot(contains(process)));
    });
  });

  // -------------------------------------------------------------------------
  // kill
  // -------------------------------------------------------------------------
  group('kill', () {
    test('kills a running process', () async {
      final process = await manager.spawn(
        executable: 'sleep',
        arguments: ['60'],
        workingDirectory: '/tmp',
      );

      expect(process.isRunning, isTrue);

      await manager.kill(process);

      // After kill the process should no longer be in the active list.
      expect(manager.activeProcesses, isNot(contains(process)));
    });
  });

  // -------------------------------------------------------------------------
  // killAll
  // -------------------------------------------------------------------------
  group('killAll', () {
    test('kills all active processes', () async {
      final p1 = await manager.spawn(
        executable: 'sleep',
        arguments: ['60'],
        workingDirectory: '/tmp',
      );
      final p2 = await manager.spawn(
        executable: 'sleep',
        arguments: ['60'],
        workingDirectory: '/tmp',
      );

      expect(manager.activeProcesses.length, greaterThanOrEqualTo(2));

      await manager.killAll();

      expect(manager.activeProcesses, isEmpty);
      expect(p1.isRunning, isFalse);
      expect(p2.isRunning, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------
  group('dispose', () {
    test('prevents future spawns by throwing StateError', () async {
      manager.dispose();

      expect(
        () => manager.spawn(
          executable: 'true',
          arguments: [],
          workingDirectory: '/tmp',
        ),
        throwsStateError,
      );
    });
  });

  // -------------------------------------------------------------------------
  // timeout
  // -------------------------------------------------------------------------
  group('timeout', () {
    test('process killed when timeout expires', () async {
      final process = await manager.spawn(
        executable: 'sleep',
        arguments: ['60'],
        workingDirectory: '/tmp',
        timeout: const Duration(seconds: 1),
      );

      final code = await process.exitCode;

      // Timeout completion sets exit code to -1.
      expect(code, -1);
      expect(process.isRunning, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // isRunning
  // -------------------------------------------------------------------------
  group('isRunning', () {
    test('true while running, false after exit', () async {
      final process = await manager.spawn(
        executable: 'sleep',
        arguments: ['60'],
        workingDirectory: '/tmp',
      );

      expect(process.isRunning, isTrue);

      await manager.kill(process);

      expect(process.isRunning, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // elapsed
  // -------------------------------------------------------------------------
  group('elapsed', () {
    test('returns a non-negative Duration', () async {
      final process = await manager.spawn(
        executable: 'sleep',
        arguments: ['60'],
        workingDirectory: '/tmp',
      );

      // Small delay to ensure elapsed is measurable.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final elapsed = process.elapsed;
      expect(elapsed, isA<Duration>());
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(0));

      await manager.kill(process);
    });
  });
}
