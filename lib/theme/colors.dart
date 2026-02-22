/// CodeOps color palette.
///
/// Professional dark theme colors designed for a developer tool.
/// Severity and status colors provide consistent visual feedback.
library;

import 'dart:ui';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/vault_enums.dart';

/// Centralized color definitions for the CodeOps dark theme.
class CodeOpsColors {
  CodeOpsColors._();

  /// Deep navy background.
  static const Color background = Color(0xFF1A1B2E);

  /// Card and panel background.
  static const Color surface = Color(0xFF222442);

  /// Elevated surface variant.
  static const Color surfaceVariant = Color(0xFF2A2D52);

  /// Primary indigo/purple accent.
  static const Color primary = Color(0xFF6C63FF);

  /// Darker primary variant.
  static const Color primaryVariant = Color(0xFF5A52D5);

  /// Cyan secondary accent.
  static const Color secondary = Color(0xFF00D9FF);

  /// Success green.
  static const Color success = Color(0xFF4ADE80);

  /// Warning amber.
  static const Color warning = Color(0xFFFBBF24);

  /// Error red.
  static const Color error = Color(0xFFEF4444);

  /// Deeper red for CRITICAL severity.
  static const Color critical = Color(0xFFDC2626);

  /// Primary text — near white.
  static const Color textPrimary = Color(0xFFE2E8F0);

  /// Secondary text — grey.
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Tertiary text — dim grey.
  static const Color textTertiary = Color(0xFF64748B);

  /// Subtle border color.
  static const Color border = Color(0xFF334155);

  /// Divider color.
  static const Color divider = Color(0xFF1E293B);

  /// Maps each [Severity] to its corresponding color.
  static const Map<Severity, Color> severityColors = {
    Severity.critical: critical,
    Severity.high: error,
    Severity.medium: warning,
    Severity.low: secondary,
  };

  /// Maps each [JobStatus] to its corresponding color.
  static const Map<JobStatus, Color> jobStatusColors = {
    JobStatus.pending: textTertiary,
    JobStatus.running: primary,
    JobStatus.completed: success,
    JobStatus.failed: error,
    JobStatus.cancelled: textTertiary,
  };

  /// Maps each [AgentType] to its corresponding accent color.
  static const Map<AgentType, Color> agentTypeColors = {
    AgentType.security: Color(0xFFEF4444),
    AgentType.codeQuality: Color(0xFF6C63FF),
    AgentType.buildHealth: Color(0xFF4ADE80),
    AgentType.completeness: Color(0xFF3B82F6),
    AgentType.apiContract: Color(0xFFF97316),
    AgentType.testCoverage: Color(0xFFA855F7),
    AgentType.uiUx: Color(0xFFEC4899),
    AgentType.documentation: Color(0xFF14B8A6),
    AgentType.database: Color(0xFFEAB308),
    AgentType.performance: Color(0xFF06B6D4),
    AgentType.dependency: Color(0xFF78716C),
    AgentType.architecture: Color(0xFFD946EF),
  };

  /// Maps each [TaskStatus] to its corresponding color.
  static const Map<TaskStatus, Color> taskStatusColors = {
    TaskStatus.pending: warning,
    TaskStatus.assigned: Color(0xFF3B82F6),
    TaskStatus.exported: secondary,
    TaskStatus.jiraCreated: Color(0xFF14B8A6),
    TaskStatus.completed: success,
  };

  /// Maps each [DebtStatus] to its corresponding color.
  static const Map<DebtStatus, Color> debtStatusColors = {
    DebtStatus.identified: warning,
    DebtStatus.planned: Color(0xFF3B82F6),
    DebtStatus.inProgress: primary,
    DebtStatus.resolved: success,
  };

  /// Maps each [DirectiveCategory] to its corresponding color.
  static const Map<DirectiveCategory, Color> directiveCategoryColors = {
    DirectiveCategory.architecture: error,
    DirectiveCategory.standards: Color(0xFF3B82F6),
    DirectiveCategory.conventions: secondary,
    DirectiveCategory.context: warning,
    DirectiveCategory.other: textTertiary,
  };

  /// Maps each [VulnerabilityStatus] to its corresponding color.
  static const Map<VulnerabilityStatus, Color> vulnerabilityStatusColors = {
    VulnerabilityStatus.open: error,
    VulnerabilityStatus.updating: Color(0xFF3B82F6),
    VulnerabilityStatus.suppressed: textTertiary,
    VulnerabilityStatus.resolved: success,
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Vault enum color maps
  // ─────────────────────────────────────────────────────────────────────────

  /// Maps each [SecretType] to its corresponding color.
  static const Map<SecretType, Color> secretTypeColors = {
    SecretType.static_: primary,
    SecretType.dynamic_: secondary,
    SecretType.reference: warning,
  };

  /// Maps each [SealStatus] to its corresponding color.
  static const Map<SealStatus, Color> sealStatusColors = {
    SealStatus.sealed: error,
    SealStatus.unsealed: success,
    SealStatus.unsealing: warning,
  };

  /// Maps each [PolicyPermission] to its corresponding color.
  static const Map<PolicyPermission, Color> policyPermissionColors = {
    PolicyPermission.read: Color(0xFF3B82F6),
    PolicyPermission.write: success,
    PolicyPermission.delete: error,
    PolicyPermission.list: secondary,
    PolicyPermission.rotate: Color(0xFFA855F7),
  };

  /// Maps each [BindingType] to its corresponding color.
  static const Map<BindingType, Color> bindingTypeColors = {
    BindingType.user: primary,
    BindingType.team: secondary,
    BindingType.service: warning,
  };

  /// Maps each [RotationStrategy] to its corresponding color.
  static const Map<RotationStrategy, Color> rotationStrategyColors = {
    RotationStrategy.randomGenerate: success,
    RotationStrategy.externalApi: Color(0xFF3B82F6),
    RotationStrategy.customScript: Color(0xFFA855F7),
  };

  /// Maps each [LeaseStatus] to its corresponding color.
  static const Map<LeaseStatus, Color> leaseStatusColors = {
    LeaseStatus.active: success,
    LeaseStatus.expired: textTertiary,
    LeaseStatus.revoked: error,
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Registry enum color maps
  // ─────────────────────────────────────────────────────────────────────────

  /// Maps each [ServiceStatus] to its corresponding color.
  static const Map<ServiceStatus, Color> serviceStatusColors = {
    ServiceStatus.active: success,
    ServiceStatus.inactive: textTertiary,
    ServiceStatus.deprecated: warning,
    ServiceStatus.archived: Color(0xFF475569),
  };

  /// Maps each [HealthStatus] to its corresponding color.
  static const Map<HealthStatus, Color> healthStatusColors = {
    HealthStatus.up: success,
    HealthStatus.down: error,
    HealthStatus.degraded: warning,
    HealthStatus.unknown: textTertiary,
  };

  /// Maps each [SolutionStatus] to its corresponding color.
  static const Map<SolutionStatus, Color> solutionStatusColors = {
    SolutionStatus.active: success,
    SolutionStatus.inDevelopment: Color(0xFF3B82F6),
    SolutionStatus.deprecated: warning,
    SolutionStatus.archived: Color(0xFF475569),
  };

  /// Maps each [SolutionCategory] to its corresponding color.
  static const Map<SolutionCategory, Color> solutionCategoryColors = {
    SolutionCategory.platform: Color(0xFFA855F7),
    SolutionCategory.application: Color(0xFF3B82F6),
    SolutionCategory.librarySuite: Color(0xFF14B8A6),
    SolutionCategory.infrastructure: Color(0xFFF97316),
    SolutionCategory.tooling: Color(0xFF06B6D4),
    SolutionCategory.other: textTertiary,
  };

  /// Maps each [SolutionMemberRole] to its corresponding color.
  static const Map<SolutionMemberRole, Color> solutionMemberRoleColors = {
    SolutionMemberRole.core: Color(0xFFA855F7),
    SolutionMemberRole.supporting: Color(0xFF3B82F6),
    SolutionMemberRole.infrastructure: Color(0xFFF97316),
    SolutionMemberRole.externalDependency: textTertiary,
  };
}
