/// Task generation service.
///
/// Groups findings by file, calculates priority, generates Claude Code
/// prompts, and batch-creates remediation tasks via the API.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../models/enums.dart';
import '../../models/finding.dart';
import '../../models/remediation_task.dart';
import '../cloud/task_api.dart';

/// Groups findings by file path for task generation.
class FindingGroup {
  /// The file path shared by all findings in this group.
  final String filePath;

  /// Findings in this group.
  final List<Finding> findings;

  /// Creates a [FindingGroup].
  const FindingGroup({required this.filePath, required this.findings});
}

/// Generates remediation tasks from audit findings.
class TaskGenerator {
  final TaskApi _taskApi;

  /// Creates a [TaskGenerator] backed by the given [taskApi].
  TaskGenerator(this._taskApi);

  /// Groups findings by file path, generates tasks, and batch-creates them.
  ///
  /// Returns the created tasks.
  Future<List<RemediationTask>> generateTasks({
    required String jobId,
    required List<Finding> findings,
  }) async {
    if (findings.isEmpty) return [];

    final groups = groupByFile(findings);
    final taskPayloads = <Map<String, dynamic>>[];
    var taskNumber = 1;

    for (final group in groups) {
      final priority = calculatePriority(group.findings);
      final prompt = generatePrompt(group);
      final title = _generateTitle(group);

      taskPayloads.add({
        'jobId': jobId,
        'taskNumber': taskNumber,
        'title': title,
        'description': _generateDescription(group),
        'promptMd': prompt,
        'findingIds': group.findings.map((f) => f.id).toList(),
        'priority': priority.toJson(),
      });

      taskNumber++;
    }

    return _taskApi.createTasksBatch(taskPayloads);
  }

  /// Generates a Claude Code-ready markdown prompt for a finding group.
  String generatePrompt(FindingGroup group) {
    final buffer = StringBuffer();
    buffer.writeln('# Remediation Task: ${group.filePath}');
    buffer.writeln();
    buffer.writeln('## File');
    buffer.writeln('`${group.filePath}`');
    buffer.writeln();
    buffer.writeln('## Findings to Address');
    buffer.writeln();

    for (var i = 0; i < group.findings.length; i++) {
      final finding = group.findings[i];
      buffer.writeln('### ${i + 1}. ${finding.title}');
      buffer.writeln('- **Severity:** ${finding.severity.displayName}');
      buffer.writeln('- **Agent:** ${finding.agentType.displayName}');
      if (finding.lineNumber != null) {
        buffer.writeln('- **Line:** ${finding.lineNumber}');
      }
      if (finding.description != null) {
        buffer.writeln('- **Description:** ${finding.description}');
      }
      if (finding.recommendation != null) {
        buffer.writeln('- **Recommendation:** ${finding.recommendation}');
      }
      if (finding.evidence != null) {
        buffer.writeln('- **Evidence:** ${finding.evidence}');
      }
      buffer.writeln();
    }

    buffer.writeln('## Instructions');
    buffer.writeln(
      'Review the findings above and apply the recommended fixes. '
      'Ensure all changes maintain existing functionality and pass tests.',
    );

    return buffer.toString();
  }

  /// Calculates the priority for a group based on the highest severity finding.
  Priority calculatePriority(List<Finding> findings) {
    var highestSeverity = Severity.low;
    for (final finding in findings) {
      if (finding.severity.index < highestSeverity.index) {
        highestSeverity = finding.severity;
      }
    }
    return switch (highestSeverity) {
      Severity.critical => Priority.p0,
      Severity.high => Priority.p1,
      Severity.medium => Priority.p2,
      Severity.low => Priority.p3,
    };
  }

  /// Groups findings by their file path.
  ///
  /// Findings without a file path are grouped under '(no file)'.
  List<FindingGroup> groupByFile(List<Finding> findings) {
    final groups = <String, List<Finding>>{};
    for (final finding in findings) {
      final key = finding.filePath ?? '(no file)';
      groups.putIfAbsent(key, () => []).add(finding);
    }
    return groups.entries
        .map((e) => FindingGroup(filePath: e.key, findings: e.value))
        .toList();
  }

  /// Exports a single prompt to a file.
  Future<String> exportPromptToFile(
    String prompt,
    String outputPath,
  ) async {
    final file = File(outputPath);
    await file.writeAsString(prompt);
    return outputPath;
  }

  /// Exports all task prompts as a ZIP archive.
  Future<String> exportAllAsZip({
    required List<RemediationTask> tasks,
    required String outputPath,
  }) async {
    final archive = Archive();
    for (final task in tasks) {
      if (task.promptMd != null) {
        final filename = 'task-${task.taskNumber}.md';
        final data = utf8.encode(task.promptMd!);
        archive.addFile(ArchiveFile(filename, data.length, data));
      }
    }
    final encoded = ZipEncoder().encode(archive);
    final file = File(outputPath);
    await file.writeAsBytes(encoded);
    return outputPath;
  }

  String _generateTitle(FindingGroup group) {
    final fileName = p.basename(group.filePath);
    final count = group.findings.length;
    return 'Fix $count finding${count == 1 ? '' : 's'} in $fileName';
  }

  String _generateDescription(FindingGroup group) {
    final severityCounts = <Severity, int>{};
    for (final finding in group.findings) {
      severityCounts.update(finding.severity, (v) => v + 1, ifAbsent: () => 1);
    }
    final parts = severityCounts.entries
        .map((e) => '${e.value} ${e.key.displayName}')
        .join(', ');
    return 'Address $parts finding${group.findings.length == 1 ? '' : 's'} in ${group.filePath}';
  }
}
