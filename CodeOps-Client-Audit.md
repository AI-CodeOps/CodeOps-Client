# CodeOps-Client -- Codebase Audit

**Project:** CodeOps-Client
**Type:** Flutter Desktop Application (macOS)
**Audit Date:** 2026-02-18
**Auditor:** Engineer (Claude Opus 4.6)
**Source of Truth:** Actual source files on disk

---

## Table of Contents

1. [Project Identity](#1-project-identity)
2. [Directory Structure](#2-directory-structure)
3. [Build and Dependencies](#3-build-and-dependencies)
4. [Configuration](#4-configuration)
5. [Startup and Runtime](#5-startup-and-runtime)
6. [Data Model Layer](#6-data-model-layer)
7. [Enum Definitions](#7-enum-definitions)
8. [Local Database Schema](#8-local-database-schema)
9. [Service Layer](#9-service-layer)
10. [Provider Layer](#10-provider-layer)
11. [Security Architecture](#11-security-architecture)
12. [Error Handling](#12-error-handling)
13. [Page and Navigation](#13-page-and-navigation)
14. [Widget Catalog](#14-widget-catalog)
15. [Test Coverage](#15-test-coverage)
16. [Cross-Cutting Patterns](#16-cross-cutting-patterns)
17. [Known Issues](#17-known-issues)
18. [Theme and Styling](#18-theme-and-styling)
19. [Assets](#19-assets)
20. [Inter-Service Communication](#20-inter-service-communication)
21. [Infrastructure](#21-infrastructure)

---

## 1. Project Identity

| Field | Value |
|---|---|
| **Name** | `codeops` |
| **Description** | CodeOps -- AI-Powered Software Maintenance Platform |
| **Version** | 1.0.0+1 |
| **Platform** | Flutter Desktop (macOS) |
| **Dart SDK** | ^3.6.0 |
| **Flutter SDK** | >=3.27.0 |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Local Database** | Drift (SQLite) |
| **HTTP Client** | Dio |
| **Backend** | CodeOps-Server (Spring Boot, port 8090) |
| **Published** | No (`publish_to: 'none'`) |

---

## 2. Directory Structure

```
lib/
  main.dart                          -- Entry point
  app.dart                           -- MaterialApp + auth bridge
  router.dart                        -- GoRouter with 25 routes
  database/
    database.dart                    -- Drift database class (schema v7)
    tables.dart                      -- 23 Drift table definitions
    database.g.dart                  -- Generated Drift code
  models/                            -- 19 source files + 15 generated
    enums.dart                       -- 24 enums + 24 JsonConverters
    user.dart, team.dart, project.dart, qa_job.dart, agent_run.dart,
    finding.dart, remediation_task.dart, specification.dart,
    compliance_item.dart, persona.dart, directive.dart, tech_debt_item.dart,
    dependency_scan.dart, health_snapshot.dart (also: AuthResponse,
    TeamMetrics, ProjectMetrics, GitHubConnection, JiraConnection,
    BugInvestigation, SystemSetting, AuditLogEntry, NotificationPreference,
    PageResponse<T>), jira_models.dart (22 Jira classes),
    vcs_models.dart (16 VCS classes + 2 enums), scribe_models.dart (2 classes),
    anthropic_model_info.dart, agent_progress.dart (2 UI view models)
  services/                          -- 48 source files across 11 subdirectories
    agent/                           -- ReportParser, TaskGenerator, AgentConfigService, PersonaManager
    analysis/                        -- HealthCalculator, TechDebtTracker, DependencyScanner
    auth/                            -- AuthService, SecureStorageService
    cloud/                           -- ApiClient, ApiExceptions, 16 API service classes
    data/                            -- SyncService, ScribePersistenceService
    integration/                     -- ExportService
    jira/                            -- JiraService, JiraMapper
    logging/                         -- LogService, LogConfig, LogLevel
    orchestration/                   -- AgentDispatcher, AgentMonitor, JobOrchestrator,
                                        ProgressAggregator, VeraManager, BugInvestigationOrchestrator
    platform/                        -- ProcessManager, ClaudeCodeDetector
    vcs/                             -- GitService, GitHubProvider, RepoManager, VcsProvider
  providers/                         -- 24 files, ~155 providers
    admin_providers.dart, agent_config_providers.dart, agent_progress_notifier.dart,
    agent_providers.dart, auth_providers.dart, compliance_providers.dart,
    dependency_providers.dart, directive_providers.dart, finding_providers.dart,
    github_providers.dart, health_providers.dart, jira_providers.dart,
    job_providers.dart, persona_providers.dart, project_local_config_providers.dart,
    project_providers.dart, report_providers.dart, scribe_providers.dart,
    settings_providers.dart, task_providers.dart, team_providers.dart,
    tech_debt_providers.dart, user_providers.dart, wizard_providers.dart
  pages/                             -- 25 page files
    login_page.dart, home_page.dart, projects_page.dart, project_detail_page.dart,
    github_browser_page.dart, scribe_page.dart, audit_wizard_page.dart,
    compliance_wizard_page.dart, bug_investigator_page.dart, dependency_scan_page.dart,
    jira_browser_page.dart, task_manager_page.dart, task_list_page.dart,
    tech_debt_page.dart, health_dashboard_page.dart, job_history_page.dart,
    job_progress_page.dart, job_report_page.dart, findings_explorer_page.dart,
    personas_page.dart, persona_editor_page.dart, directives_page.dart,
    settings_page.dart, admin_hub_page.dart, placeholder_page.dart
  widgets/                           -- 98 files across 18 subdirectories
    admin/ (4), compliance/ (3), dashboard/ (4), dependency/ (4), findings/ (4),
    health/ (3), jira/ (11), personas/ (4), progress/ (9), reports/ (8),
    scribe/ (7), settings/ (7), shared/ (8), shell/ (2), tasks/ (5),
    tech_debt/ (4), vcs/ (17), wizard/ (8)
  theme/                             -- 3 files
    app_theme.dart, colors.dart, typography.dart
  utils/                             -- 4 files
    constants.dart, date_utils.dart, file_utils.dart, string_utils.dart
assets/
  personas/                          -- 13 agent persona markdown files
  templates/                         -- 5 report template markdown files
```

**File Counts:**

| Category | Non-Generated Files |
|---|---|
| Database | 2 |
| Models | 19 |
| Services | 48 |
| Providers | 24 |
| Pages | 25 |
| Widgets | 98 |
| Theme | 3 |
| Utils | 4 |
| App (main, app, router) | 3 |
| **Total lib/ source** | **226** |
| Generated (.g.dart, .freezed.dart) | 16 |
| Asset files (personas + templates) | 18 |
| **Total non-generated in lib/** | **241** (including generated model files counted separately) |

---

## 3. Build and Dependencies

### Direct Dependencies (29)

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | Core framework |
| `flutter_riverpod` | ^2.6.1 | State management |
| `riverpod_annotation` | ^2.6.1 | State management codegen annotations |
| `go_router` | ^14.8.1 | Declarative routing |
| `drift` | ^2.22.1 | Local SQLite ORM |
| `sqlite3_flutter_libs` | ^0.5.28 | SQLite native bindings |
| `dio` | ^5.7.0 | HTTP client |
| `json_annotation` | ^4.9.0 | JSON serialization annotations |
| `freezed_annotation` | ^2.4.4 | Immutable model annotations |
| `flutter_markdown` | ^0.7.6 | Markdown rendering |
| `flutter_highlight` | ^0.7.0 | Syntax highlighting |
| `re_editor` | ^0.8.0 | Code editor widget |
| `re_highlight` | ^0.0.3 | Highlight support for re_editor |
| `fl_chart` | ^0.70.2 | Charts (line, bar) |
| `file_picker` | ^8.1.7 | Native file picker |
| `desktop_drop` | ^0.5.0 | Drag and drop |
| `window_manager` | ^0.4.3 | Window management (macOS) |
| `split_view` | ^3.2.1 | Split pane layouts |
| `path` | ^1.9.0 | Path manipulation |
| `path_provider` | ^2.1.5 | Platform directories |
| `uuid` | ^4.5.1 | UUID generation |
| `intl` | ^0.20.1 | Date/number formatting |
| `yaml` | ^3.1.3 | YAML parsing |
| `archive` | ^4.0.2 | ZIP archive handling |
| `url_launcher` | ^6.3.1 | URL launching |
| `shared_preferences` | ^2.3.4 | Key-value storage |
| `crypto` | ^3.0.6 | Hashing |
| `package_info_plus` | ^8.1.2 | App metadata |
| `connectivity_plus` | ^6.1.1 | Network status |
| `collection` | ^1.19.0 | Collection extensions |
| `equatable` | ^2.0.7 | Value equality |
| `pdf` | ^3.11.2 | PDF generation |
| `printing` | ^5.13.4 | PDF printing |

### Dev Dependencies (8)

| Package | Version | Purpose |
|---|---|---|
| `build_runner` | ^2.4.14 | Code generation runner |
| `drift_dev` | ^2.22.1 | Drift code generation |
| `riverpod_generator` | ^2.6.4 | Riverpod code generation |
| `json_serializable` | ^6.9.0 | JSON serialization codegen |
| `freezed` | ^2.5.7 | Immutable model codegen |
| `flutter_test` | SDK | Unit/widget testing |
| `mocktail` | ^1.0.4 | Mocking library |
| `integration_test` | SDK | Integration testing |
| `flutter_lints` | ^5.0.0 | Lint rules |

### Code Generation

Run: `dart run build_runner build --delete-conflicting-outputs`

Generated output:
- `*.g.dart` -- json_serializable and Drift
- `database.g.dart` -- Drift database implementation

---

## 4. Configuration

### analysis_options.yaml
- Extends `package:flutter_lints/flutter.yaml`
- No custom rules enabled

### Constants (`lib/utils/constants.dart`)
- API: `http://localhost:8090`, prefix `/api/v1`
- Anthropic: `https://api.anthropic.com`, version `2023-06-01`
- Default model: `claude-sonnet-4-20250514` (display), `claude-sonnet-4-5-20250514` (dispatch)
- Agent defaults: 3 concurrent, 15min timeout, 50 max turns
- Health thresholds: green >= 80, yellow >= 60
- Finding deductions: critical -5.0, high -2.0, medium -0.5, low -0.0
- Deduplication: line threshold 5, title similarity 0.8
- Agent weights: Security/Architecture 1.5x, all others 1.0x

---

## 5. Startup and Runtime

### Startup Sequence (`main.dart`)
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `LogConfig.initialize()` -- centralized logging
3. `windowManager.ensureInitialized()` -- window_manager plugin
4. Configure window: 1440x900, min 1024x700, centered, title "CodeOps", hidden title bar
5. `windowManager.waitUntilReadyToShow()` -> `show()` + `focus()`
6. `runApp(ProviderScope(child: CodeOpsApp()))`

### App Initialization (`app.dart`)
- Bridges `authStateProvider` stream to `authNotifier` (ChangeNotifier for GoRouter)
- On authenticated:
  - Auto-selects team (reads stored ID, validates, falls back to first team)
  - Restores GitHub PAT from secure storage
  - Seeds 13 built-in agent definitions (idempotent)
  - Refreshes Anthropic model cache (fire-and-forget)
- MaterialApp.router with `AppTheme.darkTheme` and `router` (GoRouter)

---

## 6. Data Model Layer

I now have all the information needed. Here is the comprehensive audit document.

---

# CodeOps-Client Models & Database Schema -- Comprehensive Audit

## File Location

All source model files are in `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/`.
Database files are in `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/database/`.

---

## PART 1: ENUMERATIONS

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/enums.dart`

Every enum in this file follows an identical pattern:
- Values use camelCase in Dart
- Serialization: custom `toJson()` method returning SCREAMING_SNAKE_CASE strings
- Deserialization: static `fromJson(String)` factory
- Display: `displayName` getter returning a human-friendly label
- Each enum has a companion `JsonConverter<EnumType, String>` class (e.g., `AgentResultConverter`) for use with `@JsonSerializable()` annotations
- Dependency: `package:json_annotation/json_annotation.dart`

### 1. AgentResult
Values: `pass` (PASS), `warn` (WARN), `fail` (FAIL)
Purpose: Result of an individual agent run.

### 2. AgentStatus
Values: `pending` (PENDING), `running` (RUNNING), `completed` (COMPLETED), `failed` (FAILED)
Purpose: Lifecycle status of an agent run.

### 3. AgentType
Values: `security` (SECURITY), `codeQuality` (CODE_QUALITY), `buildHealth` (BUILD_HEALTH), `completeness` (COMPLETENESS), `apiContract` (API_CONTRACT), `testCoverage` (TEST_COVERAGE), `uiUx` (UI_UX), `documentation` (DOCUMENTATION), `database` (DATABASE), `performance` (PERFORMANCE), `dependency` (DEPENDENCY), `architecture` (ARCHITECTURE)
Purpose: The kind of QA agent that can be executed.

### 4. BusinessImpact
Values: `low` (LOW), `medium` (MEDIUM), `high` (HIGH), `critical` (CRITICAL)
Purpose: Business impact level of a tech debt item.

### 5. ComplianceStatus
Values: `met` (MET), `partial` (PARTIAL), `missing` (MISSING), `notApplicable` (NOT_APPLICABLE)
Purpose: Status of a compliance requirement check.

### 6. DebtCategory
Values: `architecture` (ARCHITECTURE), `code` (CODE), `test` (TEST), `dependency` (DEPENDENCY), `documentation` (DOCUMENTATION)
Purpose: Category of technical debt.

### 7. DebtStatus
Values: `identified` (IDENTIFIED), `planned` (PLANNED), `inProgress` (IN_PROGRESS), `resolved` (RESOLVED)
Purpose: Lifecycle status of a tech debt item.

### 8. DirectiveCategory
Values: `architecture` (ARCHITECTURE), `standards` (STANDARDS), `conventions` (CONVENTIONS), `context` (CONTEXT), `other` (OTHER)
Purpose: Category of a directive.

### 9. DirectiveScope
Values: `team` (TEAM), `project` (PROJECT), `user` (USER)
Purpose: Scope at which a directive applies.

### 10. Effort
Values: `s` (S), `m` (M), `l` (L), `xl` (XL)
Purpose: T-shirt size estimate of effort required.

### 11. FindingStatus
Values: `open` (OPEN), `acknowledged` (ACKNOWLEDGED), `falsePositive` (FALSE_POSITIVE), `fixed` (FIXED), `wontFix` (WONT_FIX)
Purpose: Status of an audit finding.

### 12. GitHubAuthType
Values: `pat` (PAT), `oauth` (OAUTH), `ssh` (SSH)
Purpose: Authentication method for GitHub connections.

### 13. InvitationStatus
Values: `pending` (PENDING), `accepted` (ACCEPTED), `expired` (EXPIRED)
Purpose: Status of a team invitation.

### 14. JobMode
Values: `audit` (AUDIT), `compliance` (COMPLIANCE), `bugInvestigate` (BUG_INVESTIGATE), `remediate` (REMEDIATE), `techDebt` (TECH_DEBT), `dependency` (DEPENDENCY), `healthMonitor` (HEALTH_MONITOR)
Purpose: The mode of a QA job determining which agents run.

### 15. JobResult
Values: `pass` (PASS), `warn` (WARN), `fail` (FAIL)
Purpose: Overall result of a QA job.

### 16. JobStatus
Values: `pending` (PENDING), `running` (RUNNING), `completed` (COMPLETED), `failed` (FAILED), `cancelled` (CANCELLED)
Purpose: Lifecycle status of a QA job.

### 17. Priority
Values: `p0` (P0), `p1` (P1), `p2` (P2), `p3` (P3)
Purpose: Priority level of a remediation task.

### 18. ScheduleType
Values: `daily` (DAILY), `weekly` (WEEKLY), `onCommit` (ON_COMMIT)
Purpose: Schedule frequency for health monitoring.

### 19. Scope
Values: `system` (SYSTEM), `team` (TEAM), `user` (USER)
Purpose: Scope at which a persona is defined.

### 20. Severity
Values: `critical` (CRITICAL), `high` (HIGH), `medium` (MEDIUM), `low` (LOW)
Purpose: Severity level of a finding or vulnerability.

### 21. SpecType
Values: `openapi` (OPENAPI), `markdown` (MARKDOWN), `screenshot` (SCREENSHOT), `figma` (FIGMA)
Purpose: Type of specification file.

### 22. TaskStatus
Values: `pending` (PENDING), `assigned` (ASSIGNED), `exported` (EXPORTED), `jiraCreated` (JIRA_CREATED), `completed` (COMPLETED)
Purpose: Lifecycle status of a remediation task.

### 23. TeamRole
Values: `owner` (OWNER), `admin` (ADMIN), `member` (MEMBER), `viewer` (VIEWER)
Purpose: Role of a team member.

### 24. VulnerabilityStatus
Values: `open` (OPEN), `updating` (UPDATING), `suppressed` (SUPPRESSED), `resolved` (RESOLVED)
Purpose: Status of a dependency vulnerability.

### Display Label Maps (const Maps at end of file)
- `agentTypeLabels`: `Map<AgentType, String>`
- `severityLabels`: `Map<Severity, String>`
- `jobModeLabels`: `Map<JobMode, String>`
- `jobStatusLabels`: `Map<JobStatus, String>`
- `priorityLabels`: `Map<Priority, String>`
- `findingStatusLabels`: `Map<FindingStatus, String>`

### VCS-only Enums (in vcs_models.dart, not in enums.dart)

**FileChangeType** -- Values: `added`, `modified`, `deleted`, `renamed`, `copied`, `untracked`. Has `fromGitCode(String)` factory parsing git porcelain codes. No JsonConverter.

**DiffLineType** -- Values: `context`, `addition`, `deletion`, `header`. Has `fromPrefix(String)` factory parsing diff line prefix. No JsonConverter.

---

## PART 2: MODEL CLASSES

### Serialization Pattern Summary
- All server-synced models use `@JsonSerializable()` + `json_annotation` + generated `.g.dart` files
- VCS models use manual `fromGitHubJson()` / `fromGitJson()` / `fromGitLine()` factories (NO codegen)
- Scribe models use manual `toJson()` / `fromJson()` (NO codegen)
- AgentProgress is a UI-only view model (NO serialization to/from server)
- AnthropicModelInfo uses manual `fromApiJson()` plus Drift `toDbCompanion()` / `fromDb()` (NO json_serializable)
- All enum fields on `@JsonSerializable` models use the corresponding `@<EnumName>Converter()` annotation
- DateTime fields are serialized as ISO 8601 strings by json_serializable
- No validation or business logic exists in any model class; they are all pure data holders

---

### 2.1 User
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/user.dart`
**Serialization:** `@JsonSerializable()` + `user.g.dart`
**Maps to:** Server `UserResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `email` | `String` | yes | -- |
| `displayName` | `String` | yes | -- |
| `avatarUrl` | `String?` | no | -- |
| `isActive` | `bool?` | no | -- |
| `lastLoginAt` | `DateTime?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** Referenced by `AuthResponse.user`, `TeamMember.userId`.

---

### 2.2 Team
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/team.dart`
**Serialization:** `@JsonSerializable()` + `team.g.dart`
**Maps to:** Server `TeamResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `description` | `String?` | no | -- |
| `ownerId` | `String` | yes | -- |
| `ownerName` | `String?` | no | -- |
| `teamsWebhookUrl` | `String?` | no | -- |
| `memberCount` | `int?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |
| `updatedAt` | `DateTime?` | no | -- |

**Relationships:** `ownerId` references User. Parent of Project, TeamMember, Invitation.

---

### 2.3 TeamMember
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/team.dart`
**Serialization:** `@JsonSerializable()` + `team.g.dart`
**Maps to:** Server `TeamMemberResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `userId` | `String` | yes | -- |
| `displayName` | `String?` | no | -- |
| `email` | `String?` | no | -- |
| `avatarUrl` | `String?` | no | -- |
| `role` | `TeamRole` | yes | `@TeamRoleConverter()` |
| `joinedAt` | `DateTime?` | no | -- |

**Relationships:** `userId` references User. Member of Team.

---

### 2.4 Invitation
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/team.dart`
**Serialization:** `@JsonSerializable()` + `team.g.dart`
**Maps to:** Server `InvitationResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `email` | `String` | yes | -- |
| `role` | `TeamRole` | yes | `@TeamRoleConverter()` |
| `status` | `InvitationStatus` | yes | `@InvitationStatusConverter()` |
| `invitedByName` | `String?` | no | -- |
| `expiresAt` | `DateTime?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** Belongs to Team (implicitly via API context).

---

### 2.5 Project
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/project.dart`
**Serialization:** `@JsonSerializable()` + `project.g.dart`
**Maps to:** Server `ProjectResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `teamId` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `description` | `String?` | no | -- |
| `githubConnectionId` | `String?` | no | -- |
| `repoUrl` | `String?` | no | -- |
| `repoFullName` | `String?` | no | -- |
| `defaultBranch` | `String?` | no | -- |
| `jiraConnectionId` | `String?` | no | -- |
| `jiraProjectKey` | `String?` | no | -- |
| `jiraDefaultIssueType` | `String?` | no | -- |
| `jiraLabels` | `List<String>?` | no | -- |
| `jiraComponent` | `String?` | no | -- |
| `techStack` | `String?` | no | -- |
| `healthScore` | `int?` | no | -- |
| `lastAuditAt` | `DateTime?` | no | -- |
| `isArchived` | `bool?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |
| `updatedAt` | `DateTime?` | no | -- |

**Relationships:** `teamId` references Team. `githubConnectionId` references GitHubConnection. `jiraConnectionId` references JiraConnection. Parent of QaJob, TechDebtItem, DependencyScan, HealthSnapshot, Directive (via projectId).

---

### 2.6 QaJob
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/qa_job.dart`
**Serialization:** `@JsonSerializable()` + `qa_job.g.dart`
**Maps to:** Server `JobResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `projectId` | `String` | yes | -- |
| `projectName` | `String?` | no | -- |
| `mode` | `JobMode` | yes | `@JobModeConverter()` |
| `status` | `JobStatus` | yes | `@JobStatusConverter()` |
| `name` | `String?` | no | -- |
| `branch` | `String?` | no | -- |
| `configJson` | `String?` | no | -- |
| `summaryMd` | `String?` | no | -- |
| `overallResult` | `JobResult?` | no | `@JobResultConverter()` |
| `healthScore` | `int?` | no | -- |
| `totalFindings` | `int?` | no | -- |
| `criticalCount` | `int?` | no | -- |
| `highCount` | `int?` | no | -- |
| `mediumCount` | `int?` | no | -- |
| `lowCount` | `int?` | no | -- |
| `jiraTicketKey` | `String?` | no | -- |
| `startedBy` | `String?` | no | -- |
| `startedByName` | `String?` | no | -- |
| `startedAt` | `DateTime?` | no | -- |
| `completedAt` | `DateTime?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `projectId` references Project. `startedBy` references User. Parent of AgentRun, Finding, RemediationTask, Specification, ComplianceItem, BugInvestigation.

---

### 2.7 JobSummary
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/qa_job.dart`
**Serialization:** `@JsonSerializable()` + `qa_job.g.dart`
**Maps to:** Server `JobSummaryResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `projectName` | `String?` | no | -- |
| `mode` | `JobMode` | yes | `@JobModeConverter()` |
| `status` | `JobStatus` | yes | `@JobStatusConverter()` |
| `name` | `String?` | no | -- |
| `overallResult` | `JobResult?` | no | `@JobResultConverter()` |
| `healthScore` | `int?` | no | -- |
| `totalFindings` | `int?` | no | -- |
| `criticalCount` | `int?` | no | -- |
| `completedAt` | `DateTime?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** Lightweight projection of QaJob for list views.

---

### 2.8 AgentRun
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/agent_run.dart`
**Serialization:** `@JsonSerializable()` + `agent_run.g.dart`
**Maps to:** Server `AgentRunResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `jobId` | `String` | yes | -- |
| `agentType` | `AgentType` | yes | `@AgentTypeConverter()` |
| `status` | `AgentStatus` | yes | `@AgentStatusConverter()` |
| `result` | `AgentResult?` | no | `@AgentResultConverter()` |
| `reportS3Key` | `String?` | no | -- |
| `score` | `int?` | no | -- |
| `findingsCount` | `int?` | no | -- |
| `criticalCount` | `int?` | no | -- |
| `highCount` | `int?` | no | -- |
| `startedAt` | `DateTime?` | no | -- |
| `completedAt` | `DateTime?` | no | -- |

**Relationships:** `jobId` references QaJob.

---

### 2.9 Finding
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/finding.dart`
**Serialization:** `@JsonSerializable()` + `finding.g.dart`
**Maps to:** Server `FindingResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `jobId` | `String` | yes | -- |
| `agentType` | `AgentType` | yes | `@AgentTypeConverter()` |
| `severity` | `Severity` | yes | `@SeverityConverter()` |
| `title` | `String` | yes | -- |
| `description` | `String?` | no | -- |
| `filePath` | `String?` | no | -- |
| `lineNumber` | `int?` | no | -- |
| `recommendation` | `String?` | no | -- |
| `evidence` | `String?` | no | -- |
| `effortEstimate` | `Effort?` | no | `@EffortConverter()` |
| `debtCategory` | `DebtCategory?` | no | `@DebtCategoryConverter()` |
| `status` | `FindingStatus` | yes | `@FindingStatusConverter()` |
| `statusChangedBy` | `String?` | no | -- |
| `statusChangedAt` | `DateTime?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `jobId` references QaJob. Referenced by RemediationTask.findingIds.

---

### 2.10 RemediationTask
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/remediation_task.dart`
**Serialization:** `@JsonSerializable()` + `remediation_task.g.dart`
**Maps to:** Server `TaskResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `jobId` | `String` | yes | -- |
| `taskNumber` | `int` | yes | -- |
| `title` | `String` | yes | -- |
| `description` | `String?` | no | -- |
| `promptMd` | `String?` | no | -- |
| `promptS3Key` | `String?` | no | -- |
| `findingIds` | `List<String>?` | no | -- |
| `priority` | `Priority?` | no | `@PriorityConverter()` |
| `status` | `TaskStatus` | yes | `@TaskStatusConverter()` |
| `assignedTo` | `String?` | no | -- |
| `assignedToName` | `String?` | no | -- |
| `jiraKey` | `String?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `jobId` references QaJob. `findingIds` references Finding (many-to-many). `assignedTo` references User.

---

### 2.11 Specification
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/specification.dart`
**Serialization:** `@JsonSerializable()` + `specification.g.dart`
**Maps to:** Server `SpecificationResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `jobId` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `specType` | `SpecType?` | no | `@SpecTypeConverter()` |
| `s3Key` | `String` | yes | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `jobId` references QaJob. Referenced by ComplianceItem.specId.

---

### 2.12 ComplianceItem
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/compliance_item.dart`
**Serialization:** `@JsonSerializable()` + `compliance_item.g.dart`
**Maps to:** Server `ComplianceItemResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `jobId` | `String` | yes | -- |
| `requirement` | `String` | yes | -- |
| `specId` | `String?` | no | -- |
| `specName` | `String?` | no | -- |
| `status` | `ComplianceStatus` | yes | `@ComplianceStatusConverter()` |
| `evidence` | `String?` | no | -- |
| `agentType` | `AgentType?` | no | `@AgentTypeConverter()` |
| `notes` | `String?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `jobId` references QaJob. `specId` references Specification.

---

### 2.13 Persona
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/persona.dart`
**Serialization:** `@JsonSerializable()` + `persona.g.dart`
**Maps to:** Server `PersonaResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `agentType` | `AgentType?` | no | `@AgentTypeConverter()` |
| `description` | `String?` | no | -- |
| `contentMd` | `String?` | no | -- |
| `scope` | `Scope` | yes | `@ScopeConverter()` |
| `teamId` | `String?` | no | -- |
| `createdBy` | `String?` | no | -- |
| `createdByName` | `String?` | no | -- |
| `isDefault` | `bool?` | no | -- |
| `version` | `int?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |
| `updatedAt` | `DateTime?` | no | -- |

**Relationships:** `teamId` references Team. `createdBy` references User.

---

### 2.14 Directive
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/directive.dart`
**Serialization:** `@JsonSerializable()` + `directive.g.dart`
**Maps to:** Server `DirectiveResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `description` | `String?` | no | -- |
| `contentMd` | `String?` | no | -- |
| `category` | `DirectiveCategory?` | no | `@DirectiveCategoryConverter()` |
| `scope` | `DirectiveScope` | yes | `@DirectiveScopeConverter()` |
| `teamId` | `String?` | no | -- |
| `projectId` | `String?` | no | -- |
| `createdBy` | `String?` | no | -- |
| `createdByName` | `String?` | no | -- |
| `version` | `int?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |
| `updatedAt` | `DateTime?` | no | -- |

**Relationships:** `teamId` references Team. `projectId` references Project. `createdBy` references User.

---

### 2.15 ProjectDirective
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/directive.dart`
**Serialization:** `@JsonSerializable()` + `directive.g.dart`
**Maps to:** Server `ProjectDirectiveResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `projectId` | `String` | yes | -- |
| `directiveId` | `String` | yes | -- |
| `directiveName` | `String?` | no | -- |
| `category` | `DirectiveCategory?` | no | `@DirectiveCategoryConverter()` |
| `enabled` | `bool?` | no | -- |

**Relationships:** `projectId` references Project. `directiveId` references Directive.

---

### 2.16 TechDebtItem
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/tech_debt_item.dart`
**Serialization:** `@JsonSerializable()` + `tech_debt_item.g.dart`
**Maps to:** Server `TechDebtItemResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `projectId` | `String` | yes | -- |
| `category` | `DebtCategory` | yes | `@DebtCategoryConverter()` |
| `title` | `String` | yes | -- |
| `description` | `String?` | no | -- |
| `filePath` | `String?` | no | -- |
| `effortEstimate` | `Effort?` | no | `@EffortConverter()` |
| `businessImpact` | `BusinessImpact?` | no | `@BusinessImpactConverter()` |
| `status` | `DebtStatus` | yes | `@DebtStatusConverter()` |
| `firstDetectedJobId` | `String?` | no | -- |
| `resolvedJobId` | `String?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |
| `updatedAt` | `DateTime?` | no | -- |

**Relationships:** `projectId` references Project. `firstDetectedJobId` and `resolvedJobId` reference QaJob.

---

### 2.17 DependencyScan
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/dependency_scan.dart`
**Serialization:** `@JsonSerializable()` + `dependency_scan.g.dart`
**Maps to:** Server `DependencyScanResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `projectId` | `String` | yes | -- |
| `jobId` | `String?` | no | -- |
| `manifestFile` | `String?` | no | -- |
| `totalDependencies` | `int?` | no | -- |
| `outdatedCount` | `int?` | no | -- |
| `vulnerableCount` | `int?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `projectId` references Project. `jobId` references QaJob. Parent of DependencyVulnerability.

---

### 2.18 DependencyVulnerability
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/dependency_scan.dart`
**Serialization:** `@JsonSerializable()` + `dependency_scan.g.dart`
**Maps to:** Server `VulnerabilityResponse` DTO

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `scanId` | `String` | yes | -- |
| `dependencyName` | `String` | yes | -- |
| `currentVersion` | `String?` | no | -- |
| `fixedVersion` | `String?` | no | -- |
| `cveId` | `String?` | no | -- |
| `severity` | `Severity` | yes | `@SeverityConverter()` |
| `description` | `String?` | no | -- |
| `status` | `VulnerabilityStatus` | yes | `@VulnerabilityStatusConverter()` |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `scanId` references DependencyScan.

---

### 2.19 HealthSnapshot
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `projectId` | `String` | yes | -- |
| `jobId` | `String?` | no | -- |
| `healthScore` | `int` | yes | -- |
| `findingsBySeverity` | `String?` | no | -- |
| `techDebtScore` | `int?` | no | -- |
| `dependencyScore` | `int?` | no | -- |
| `testCoveragePercent` | `double?` | no | -- |
| `capturedAt` | `DateTime?` | no | -- |

**Relationships:** `projectId` references Project. `jobId` references QaJob.

---

### 2.20 HealthSchedule
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `projectId` | `String` | yes | -- |
| `scheduleType` | `ScheduleType` | yes | `@ScheduleTypeConverter()` |
| `cronExpression` | `String?` | no | -- |
| `agentTypes` | `List<AgentType>?` | no | `@AgentTypeConverter()` |
| `isActive` | `bool?` | no | -- |
| `lastRunAt` | `DateTime?` | no | -- |
| `nextRunAt` | `DateTime?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `projectId` references Project.

---

### 2.21 PageResponse<T>
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable(genericArgumentFactories: true)` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `content` | `List<T>` | yes | -- |
| `page` | `int` | yes | -- |
| `size` | `int` | yes | -- |
| `totalElements` | `int` | yes | -- |
| `totalPages` | `int` | yes | -- |
| `isLast` | `bool` | yes | -- |

**Business Logic:** Has `factory PageResponse.empty()` that returns a page with no content. Generic type parameter `T` is deserialized via `fromJsonT` callback.

---

### 2.22 AuthResponse
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable(explicitToJson: true)` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `token` | `String` | yes | -- |
| `refreshToken` | `String` | yes | -- |
| `user` | `User` | yes | -- |

**Relationships:** `user` is a nested `User` object (imports `user.dart`).

---

### 2.23 TeamMetrics
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `teamId` | `String` | yes | -- |
| `totalProjects` | `int?` | no | -- |
| `totalJobs` | `int?` | no | -- |
| `totalFindings` | `int?` | no | -- |
| `averageHealthScore` | `double?` | no | -- |
| `projectsBelowThreshold` | `int?` | no | -- |
| `openCriticalFindings` | `int?` | no | -- |

**Relationships:** `teamId` references Team.

---

### 2.24 ProjectMetrics
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `projectId` | `String` | yes | -- |
| `projectName` | `String?` | no | -- |
| `currentHealthScore` | `int?` | no | -- |
| `previousHealthScore` | `int?` | no | -- |
| `totalJobs` | `int?` | no | -- |
| `totalFindings` | `int?` | no | -- |
| `openCritical` | `int?` | no | -- |
| `openHigh` | `int?` | no | -- |
| `techDebtItemCount` | `int?` | no | -- |
| `openVulnerabilities` | `int?` | no | -- |
| `lastAuditAt` | `DateTime?` | no | -- |

**Relationships:** `projectId` references Project.

---

### 2.25 GitHubConnection
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `teamId` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `authType` | `GitHubAuthType` | yes | `@GitHubAuthTypeConverter()` |
| `githubUsername` | `String?` | no | -- |
| `isActive` | `bool?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `teamId` references Team. Referenced by Project.githubConnectionId.

---

### 2.26 JiraConnection
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `teamId` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `instanceUrl` | `String` | yes | -- |
| `email` | `String` | yes | -- |
| `isActive` | `bool?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `teamId` references Team. Referenced by Project.jiraConnectionId.

---

### 2.27 BugInvestigation
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `jobId` | `String` | yes | -- |
| `jiraKey` | `String?` | no | -- |
| `jiraSummary` | `String?` | no | -- |
| `jiraDescription` | `String?` | no | -- |
| `additionalContext` | `String?` | no | -- |
| `rcaMd` | `String?` | no | -- |
| `impactAssessmentMd` | `String?` | no | -- |
| `rcaS3Key` | `String?` | no | -- |
| `rcaPostedToJira` | `bool?` | no | -- |
| `fixTasksCreatedInJira` | `bool?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `jobId` references QaJob.

---

### 2.28 SystemSetting
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `key` | `String` | yes | -- |
| `value` | `String` | yes | -- |
| `updatedBy` | `String?` | no | -- |
| `updatedAt` | `DateTime?` | no | -- |

---

### 2.29 AuditLogEntry
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `int` | yes | -- |
| `userId` | `String?` | no | -- |
| `userName` | `String?` | no | -- |
| `teamId` | `String?` | no | -- |
| `action` | `String` | yes | -- |
| `entityType` | `String?` | no | -- |
| `entityId` | `String?` | no | -- |
| `details` | `String?` | no | -- |
| `ipAddress` | `String?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |

**Relationships:** `userId` references User. `teamId` references Team.

---

### 2.30 NotificationPreference
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/health_snapshot.dart`
**Serialization:** `@JsonSerializable()` + `health_snapshot.g.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `userId` | `String` | yes | -- |
| `eventType` | `String` | yes | -- |
| `inApp` | `bool` | yes | -- |
| `email` | `bool` | yes | -- |

**Relationships:** `userId` references User.

---

### 2.31 AnthropicModelInfo
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/anthropic_model_info.dart`
**Serialization:** Manual -- `fromApiJson()`, `fromDb()`, `toDbCompanion()`. NO `@JsonSerializable`, NO `.g.dart`.
**Imports:** `package:drift/drift.dart`, `../database/database.dart`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `displayName` | `String` | yes | -- |
| `modelFamily` | `String?` | no | -- |
| `contextWindow` | `int?` | no | -- |
| `maxOutputTokens` | `int?` | no | -- |
| `createdAt` | `DateTime` | yes | -- |

**Business Logic:**
- `fromApiJson()` derives `displayName` from API's `display_name` field, falling back to `_formatModelId(id)` which title-cases the dash-separated ID.
- `fromApiJson()` derives `modelFamily` via regex on the model ID: `claude-<variant>-<version>` becomes `claude-<version>`.
- `toDbCompanion()` converts to Drift `AnthropicModelsCompanion` for database caching.
- `fromDb()` constructs from a Drift `AnthropicModel` row.

---

### 2.32 AgentProgress (UI View Model)
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/agent_progress.dart`
**Serialization:** NONE -- UI-only, in-memory view model. Not persisted.
**Imports:** `dart:ui`, `../theme/colors.dart`, `enums.dart`

| Field | Type | Required | Default |
|---|---|---|---|
| `agentRunId` | `String` | yes | -- |
| `agentType` | `AgentType` | yes | -- |
| `status` | `AgentStatus` | yes | -- |
| `result` | `AgentResult?` | no | null |
| `startedAt` | `DateTime?` | no | null |
| `completedAt` | `DateTime?` | no | null |
| `elapsed` | `Duration` | no | `Duration.zero` |
| `progressPercent` | `double` | no | `0.0` |
| `currentTurn` | `int` | no | `0` |
| `maxTurns` | `int` | no | `50` |
| `queuePosition` | `int` | no | `0` |
| `criticalCount` | `int` | no | `0` |
| `highCount` | `int` | no | `0` |
| `mediumCount` | `int` | no | `0` |
| `lowCount` | `int` | no | `0` |
| `totalFindings` | `int` | no | `0` |
| `currentActivity` | `String?` | no | null |
| `lastFileAnalyzed` | `String?` | no | null |
| `filesAnalyzed` | `int` | no | `0` |
| `score` | `int?` | no | null |
| `modelId` | `String?` | no | null |
| `outputLines` | `List<String>` | no | `const []` |
| `errorMessage` | `String?` | no | null |

**Business Logic:**
- `progressColor` getter: Returns Color based on status/result/finding counts (error for failed/fail/critical, warning for warn/high, success for pass, primary otherwise).
- `agentColor` getter: Returns agent-type-specific color from `CodeOpsColors.agentTypeColors`.
- Boolean getters: `isQueued`, `isRunning`, `isComplete`, `isFailed`.
- `copyWith()` method for immutable updates.

---

### 2.33 AgentProgressSummary (UI View Model)
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/agent_progress.dart`
**Serialization:** NONE -- UI-only aggregate.

| Field | Type | Required | Default |
|---|---|---|---|
| `total` | `int` | no | `0` |
| `running` | `int` | no | `0` |
| `queued` | `int` | no | `0` |
| `completed` | `int` | no | `0` |
| `failed` | `int` | no | `0` |
| `totalFindings` | `int` | no | `0` |
| `totalCritical` | `int` | no | `0` |

---

### 2.34 ScribeTab
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/scribe_models.dart`
**Serialization:** Manual `toJson()` / `fromJson()`. NO codegen.
**Imports:** `dart:convert`, `package:uuid/uuid.dart`, `../widgets/scribe/scribe_language.dart`

| Field | Type | Required | Default |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `title` | `String` | yes | -- |
| `filePath` | `String?` | no | null |
| `content` | `String` | no | `''` |
| `language` | `String` | no | `'plaintext'` |
| `isDirty` | `bool` | no | `false` |
| `cursorLine` | `int` | no | `0` |
| `cursorColumn` | `int` | no | `0` |
| `scrollOffset` | `double` | no | `0.0` |
| `createdAt` | `DateTime` | yes | -- |
| `lastModifiedAt` | `DateTime` | yes | -- |

**Business Logic:**
- `ScribeTab.untitled(int number)`: Factory creating a new tab with auto-incrementing title "Untitled-N" and a UUID v4 id.
- `ScribeTab.fromFile({filePath, content})`: Factory that detects language from file extension via `ScribeLanguage.fromFileName()`.
- `copyWith()` method.
- `operator ==` and `hashCode` based on `id`.

---

### 2.35 ScribeSettings
**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/scribe_models.dart`
**Serialization:** Manual `toJson()` / `fromJson()` / `toJsonString()` / `fromJsonString()`. NO codegen.

| Field | Type | Required | Default |
|---|---|---|---|
| `fontSize` | `double` | no | `14.0` |
| `tabSize` | `int` | no | `2` |
| `insertSpaces` | `bool` | no | `true` |
| `wordWrap` | `bool` | no | `false` |
| `showLineNumbers` | `bool` | no | `true` |
| `showMinimap` | `bool` | no | `false` |

**Business Logic:** `copyWith()` method. `toJsonString()` / `fromJsonString()` wrappers around JSON encode/decode.

---

## PART 3: VCS MODELS (Manual Serialization)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/vcs_models.dart`
**Serialization:** All classes use manual `fromGitHubJson()`, `fromGitJson()`, `fromGitLine()` factories. NO `@JsonSerializable`, NO `.g.dart`. Plain Dart classes.

### 3.1 VcsCredentials
| Field | Type | Required |
|---|---|---|
| `authType` | `GitHubAuthType` | yes |
| `token` | `String` | yes |
| `username` | `String?` | no |

### 3.2 VcsOrganization
| Field | Type | Required |
|---|---|---|
| `login` | `String` | yes |
| `name` | `String?` | no |
| `avatarUrl` | `String?` | no |
| `description` | `String?` | no |
| `publicRepos` | `int?` | no |

Factory: `fromGitHubJson()` maps `login`, `name`, `avatar_url`, `description`, `public_repos`.

### 3.3 VcsRepository
| Field | Type | Required | Default |
|---|---|---|---|
| `id` | `int` | yes | -- |
| `fullName` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `description` | `String?` | no | -- |
| `language` | `String?` | no | -- |
| `stargazersCount` | `int` | no | `0` |
| `forksCount` | `int` | no | `0` |
| `openIssuesCount` | `int` | no | `0` |
| `defaultBranch` | `String` | no | `'main'` |
| `isPrivate` | `bool` | no | `false` |
| `isFork` | `bool` | no | `false` |
| `isArchived` | `bool` | no | `false` |
| `cloneUrl` | `String?` | no | -- |
| `sshUrl` | `String?` | no | -- |
| `htmlUrl` | `String?` | no | -- |
| `pushedAt` | `DateTime?` | no | -- |
| `updatedAt` | `DateTime?` | no | -- |
| `ownerLogin` | `String?` | no | -- |
| `ownerAvatarUrl` | `String?` | no | -- |
| `sizeKb` | `int?` | no | -- |

Factory: `fromGitHubJson()` maps from GitHub API response, extracting nested `owner.login` and `owner.avatar_url`.

### 3.4 VcsBranch
| Field | Type | Required | Default |
|---|---|---|---|
| `name` | `String` | yes | -- |
| `sha` | `String?` | no | -- |
| `isProtected` | `bool` | no | `false` |

Factory: `fromGitHubJson()` extracts `commit.sha`.

### 3.5 VcsPullRequest
| Field | Type | Required | Default |
|---|---|---|---|
| `number` | `int` | yes | -- |
| `title` | `String` | yes | -- |
| `body` | `String?` | no | -- |
| `state` | `String` | yes | -- |
| `headBranch` | `String` | yes | -- |
| `baseBranch` | `String` | yes | -- |
| `authorLogin` | `String?` | no | -- |
| `authorAvatarUrl` | `String?` | no | -- |
| `isDraft` | `bool` | no | `false` |
| `isMerged` | `bool` | no | `false` |
| `commits` | `int?` | no | -- |
| `changedFiles` | `int?` | no | -- |
| `additions` | `int?` | no | -- |
| `deletions` | `int?` | no | -- |
| `createdAt` | `DateTime?` | no | -- |
| `updatedAt` | `DateTime?` | no | -- |
| `mergedAt` | `DateTime?` | no | -- |
| `htmlUrl` | `String?` | no | -- |

Factory: `fromGitHubJson()` extracts nested `user.login`, `head.ref`, `base.ref`.

### 3.6 CreatePRRequest
| Field | Type | Required | Default |
|---|---|---|---|
| `title` | `String` | yes | -- |
| `head` | `String` | yes | -- |
| `base` | `String` | yes | -- |
| `body` | `String?` | no | -- |
| `draft` | `bool` | no | `false` |

Has manual `toJson()` method.

### 3.7 VcsCommit
| Field | Type | Required |
|---|---|---|
| `sha` | `String` | yes |
| `message` | `String` | yes |
| `authorName` | `String?` | no |
| `authorEmail` | `String?` | no |
| `authorLogin` | `String?` | no |
| `authorAvatarUrl` | `String?` | no |
| `date` | `DateTime?` | no |
| `htmlUrl` | `String?` | no |

Computed: `shortSha` getter returns first 7 chars.
Factories: `fromGitHubJson()` and `fromGitJson()`.

### 3.8 VcsStash
| Field | Type | Required |
|---|---|---|
| `index` | `int` | yes |
| `message` | `String` | yes |
| `branch` | `String?` | no |

Factory: `fromGitLine()` parses `stash@{N}: On <branch>: <message>` format.

### 3.9 VcsTag
| Field | Type | Required |
|---|---|---|
| `name` | `String` | yes |
| `sha` | `String?` | no |
| `message` | `String?` | no |
| `taggerName` | `String?` | no |
| `date` | `DateTime?` | no |
| `zipballUrl` | `String?` | no |
| `tarballUrl` | `String?` | no |

Factory: `fromGitHubJson()` handles both tag and release JSON shapes.

### 3.10 CloneProgress
| Field | Type | Required |
|---|---|---|
| `phase` | `String` | yes |
| `percent` | `int` | yes |
| `current` | `int?` | no |
| `total` | `int?` | no |

Factory: `fromGitLine()` parses `Phase:  42% (84/200)` format from git clone stderr.

### 3.11 RepoStatus
| Field | Type | Required | Default |
|---|---|---|---|
| `branch` | `String` | yes | -- |
| `changes` | `List<FileChange>` | no | `const []` |
| `ahead` | `int` | no | `0` |
| `behind` | `int` | no | `0` |

Computed: `isClean` getter returns `changes.isEmpty`.

### 3.12 FileChange
| Field | Type | Required | Default |
|---|---|---|---|
| `path` | `String` | yes | -- |
| `type` | `FileChangeType` | yes | -- |
| `isStaged` | `bool` | no | `false` |
| `originalPath` | `String?` | no | -- |

### 3.13 DiffResult
| Field | Type | Required | Default |
|---|---|---|---|
| `filePath` | `String` | yes | -- |
| `hunks` | `List<DiffHunk>` | no | `const []` |
| `additions` | `int` | no | `0` |
| `deletions` | `int` | no | `0` |
| `isBinary` | `bool` | no | `false` |

### 3.14 DiffHunk
| Field | Type | Required | Default |
|---|---|---|---|
| `header` | `String` | yes | -- |
| `oldStart` | `int` | no | `0` |
| `oldCount` | `int` | no | `0` |
| `newStart` | `int` | no | `0` |
| `newCount` | `int` | no | `0` |
| `lines` | `List<DiffLine>` | no | `const []` |

### 3.15 DiffLine
| Field | Type | Required |
|---|---|---|
| `content` | `String` | yes |
| `type` | `DiffLineType` | yes |
| `oldLineNumber` | `int?` | no |
| `newLineNumber` | `int?` | no |

### 3.16 WorkflowRun
| Field | Type | Required |
|---|---|---|
| `id` | `int` | yes |
| `name` | `String?` | no |
| `status` | `String` | yes |
| `conclusion` | `String?` | no |
| `headBranch` | `String?` | no |
| `headSha` | `String?` | no |
| `htmlUrl` | `String?` | no |
| `runNumber` | `int?` | no |
| `createdAt` | `DateTime?` | no |
| `updatedAt` | `DateTime?` | no |

Factory: `fromGitHubJson()`.

---

## PART 4: JIRA MODELS

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/models/jira_models.dart`
**Serialization:** `@JsonSerializable()` + `jira_models.g.dart` (all classes except `JiraIssueDisplayModel`)
**Maps to:** Jira REST API v3 response/request formats

### 4.1 JiraSearchResult
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required |
|---|---|---|
| `startAt` | `int` | yes |
| `maxResults` | `int` | yes |
| `total` | `int` | yes |
| `issues` | `List<JiraIssue>` | yes |

### 4.2 JiraIssue
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required |
|---|---|---|
| `id` | `String` | yes |
| `key` | `String` | yes |
| `self` | `String` | yes |
| `fields` | `JiraIssueFields` | yes |

### 4.3 JiraIssueFields
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `summary` | `String` | yes | -- |
| `description` | `String?` | no | `@JsonKey(fromJson: _dynamicToString, toJson: _stringToIdentity)` |
| `issuetype` | `JiraIssueType` | yes | -- |
| `status` | `JiraStatus` | yes | -- |
| `priority` | `JiraPriority?` | no | -- |
| `assignee` | `JiraUser?` | no | -- |
| `reporter` | `JiraUser?` | no | -- |
| `project` | `JiraProject?` | no | -- |
| `created` | `String?` | no | -- |
| `updated` | `String?` | no | -- |
| `components` | `List<JiraComponent>?` | no | -- |
| `labels` | `List<String>?` | no | -- |
| `sprint` | `JiraSprint?` | no | -- |
| `parent` | `JiraIssue?` | no | -- |
| `issuelinks` | `List<JiraIssueLink>?` | no | -- |
| `attachment` | `List<JiraAttachment>?` | no | -- |
| `comment` | `JiraCommentPage?` | no | -- |

**Note:** `description` uses custom `_dynamicToString` converter because Jira returns ADF objects (Maps) but the model stores them as JSON strings.

### 4.4 JiraStatus
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required |
|---|---|---|
| `id` | `String` | yes |
| `name` | `String` | yes |
| `statusCategory` | `JiraStatusCategory?` | no |

### 4.5 JiraStatusCategory

| Field | Type | Required |
|---|---|---|
| `id` | `int` | yes |
| `key` | `String` | yes |
| `name` | `String` | yes |
| `colorName` | `String?` | no |

### 4.6 JiraIssueType

| Field | Type | Required |
|---|---|---|
| `id` | `String` | yes |
| `name` | `String` | yes |
| `subtask` | `bool` | yes |
| `iconUrl` | `String?` | no |

### 4.7 JiraPriority

| Field | Type | Required |
|---|---|---|
| `id` | `String` | yes |
| `name` | `String` | yes |
| `iconUrl` | `String?` | no |

### 4.8 JiraUser
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required |
|---|---|---|
| `accountId` | `String` | yes |
| `displayName` | `String?` | no |
| `emailAddress` | `String?` | no |
| `avatarUrls` | `JiraAvatarUrls?` | no |
| `active` | `bool?` | no |

### 4.9 JiraAvatarUrls

| Field | Type | Required | Annotations |
|---|---|---|---|
| `x48` | `String?` | no | `@JsonKey(name: '48x48')` |
| `x32` | `String?` | no | `@JsonKey(name: '32x32')` |
| `x24` | `String?` | no | `@JsonKey(name: '24x24')` |
| `x16` | `String?` | no | `@JsonKey(name: '16x16')` |

### 4.10 JiraProject

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `key` | `String` | yes | -- |
| `name` | `String` | yes | -- |
| `avatarUrlsMap` | `Map<String, dynamic>?` | no | `@JsonKey(name: 'avatarUrls')` |

Computed: `avatarUrl` getter extracts `48x48` or `32x32` from the map.

### 4.11 JiraComponent

| Field | Type | Required |
|---|---|---|
| `id` | `String` | yes |
| `name` | `String` | yes |

### 4.12 JiraSprint

| Field | Type | Required |
|---|---|---|
| `id` | `int` | yes |
| `name` | `String` | yes |
| `state` | `String` | yes |
| `startDate` | `String?` | no |
| `endDate` | `String?` | no |

### 4.13 JiraComment
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required | Annotations |
|---|---|---|---|
| `id` | `String` | yes | -- |
| `author` | `JiraUser?` | no | -- |
| `body` | `String?` | no | `@JsonKey(fromJson: _dynamicToString, toJson: _stringToIdentity)` |
| `created` | `String?` | no | -- |
| `updated` | `String?` | no | -- |

### 4.14 JiraCommentPage
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required |
|---|---|---|
| `total` | `int` | yes |
| `maxResults` | `int` | yes |
| `comments` | `List<JiraComment>` | yes |

### 4.15 JiraAttachment
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required |
|---|---|---|
| `id` | `String` | yes |
| `filename` | `String` | yes |
| `mimeType` | `String?` | no |
| `size` | `int?` | no |
| `content` | `String` | yes |
| `author` | `JiraUser?` | no |
| `created` | `String?` | no |

### 4.16 JiraIssueLink
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required |
|---|---|---|
| `id` | `String` | yes |
| `type` | `JiraIssueLinkType` | yes |
| `inwardIssue` | `JiraIssue?` | no |
| `outwardIssue` | `JiraIssue?` | no |

### 4.17 JiraIssueLinkType

| Field | Type | Required |
|---|---|---|
| `name` | `String` | yes |
| `inward` | `String` | yes |
| `outward` | `String` | yes |

### 4.18 JiraTransition
`@JsonSerializable(explicitToJson: true)`

| Field | Type | Required |
|---|---|---|
| `id` | `String` | yes |
| `name` | `String` | yes |
| `to` | `JiraStatus` | yes |

### 4.19 CreateJiraIssueRequest

| Field | Type | Required |
|---|---|---|
| `projectKey` | `String` | yes |
| `issueTypeName` | `String` | yes |
| `summary` | `String` | yes |
| `description` | `String?` | no |
| `assigneeAccountId` | `String?` | no |
| `priorityName` | `String?` | no |
| `labels` | `List<String>?` | no |
| `componentName` | `String?` | no |
| `parentKey` | `String?` | no |
| `sprintId` | `String?` | no |

### 4.20 CreateJiraSubTaskRequest

| Field | Type | Required |
|---|---|---|
| `parentKey` | `String` | yes |
| `projectKey` | `String` | yes |
| `summary` | `String` | yes |
| `description` | `String?` | no |
| `assigneeAccountId` | `String?` | no |
| `priorityName` | `String?` | no |

### 4.21 UpdateJiraIssueRequest

| Field | Type | Required |
|---|---|---|
| `assigneeAccountId` | `String?` | no |
| `summary` | `String?` | no |
| `description` | `String?` | no |
| `priorityName` | `String?` | no |
| `labels` | `List<String>?` | no |

### 4.22 JiraIssueDisplayModel (UI-only, no serialization)

| Field | Type | Required | Default |
|---|---|---|---|
| `key` | `String` | yes | -- |
| `summary` | `String` | yes | -- |
| `statusName` | `String` | yes | -- |
| `statusCategoryKey` | `String?` | no | -- |
| `priorityName` | `String?` | no | -- |
| `priorityIconUrl` | `String?` | no | -- |
| `assigneeName` | `String?` | no | -- |
| `assigneeAvatarUrl` | `String?` | no | -- |
| `issuetypeName` | `String?` | no | -- |
| `issuetypeIconUrl` | `String?` | no | -- |
| `commentCount` | `int` | no | `0` |
| `attachmentCount` | `int` | no | `0` |
| `linkCount` | `int` | no | `0` |
| `created` | `DateTime?` | no | -- |
| `updated` | `DateTime?` | no | -- |

### Jira JSON Helpers (file-private)
- `_dynamicToString(dynamic value)`: Converts Map or String to String (handles ADF objects)
- `_stringToIdentity(String? value)`: Identity transform for toJson

---

## PART 5: LOCAL DATABASE SCHEMA (Drift / SQLite)

**Files:**
- `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/database/tables.dart` -- Table definitions
- `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/database/database.dart` -- Database class
- `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/database/database.g.dart` -- Generated code

**Database Class:** `CodeOpsDatabase extends _$CodeOpsDatabase`
**Schema Version:** 7
**Database File:** `<app-support-dir>/codeops.db` (SQLite via `NativeDatabase.createInBackground`)
**Singleton Access:** `database` global getter

### Migration History
- v1: Initial schema (all core tables)
- v2: Added `ClonedRepos` table
- v3: Added `QaJobs.configJson` column
- v4: Added `QaJobs.summaryMd`, `QaJobs.startedByName`, `Findings.statusChangedBy`, `Findings.statusChangedAt`
- v5: Added `AnthropicModels`, `AgentDefinitions`, `AgentFiles` tables
- v6: Added `ProjectLocalConfig` table
- v7: Added `ScribeTabs`, `ScribeSettings` tables

### Registered Tables (23 total)
`Users`, `Teams`, `Projects`, `QaJobs`, `AgentRuns`, `Findings`, `RemediationTasks`, `Personas`, `Directives`, `TechDebtItems`, `DependencyScans`, `DependencyVulnerabilities`, `HealthSnapshots`, `ComplianceItems`, `Specifications`, `SyncMetadata`, `ClonedRepos`, `AnthropicModels`, `AgentDefinitions`, `AgentFiles`, `ProjectLocalConfig`, `ScribeTabs`, `ScribeSettings`

### Table Definitions

**Note:** All enum-type fields are stored as `TextColumn` containing SCREAMING_SNAKE_CASE strings. Conversion to Dart enums happens in the model layer, not in Drift.

#### Users
PK: `id` (text). Columns: `email` (text), `displayName` (text), `avatarUrl` (text?), `isActive` (bool, default true), `lastLoginAt` (dateTime?), `createdAt` (dateTime?).

#### Teams
PK: `id` (text). Columns: `name` (text), `description` (text?), `ownerId` (text), `ownerName` (text?), `teamsWebhookUrl` (text?), `memberCount` (int?), `createdAt` (dateTime?), `updatedAt` (dateTime?).

#### Projects
PK: `id` (text). Columns: `teamId` (text), `name` (text), `description` (text?), `githubConnectionId` (text?), `repoUrl` (text?), `repoFullName` (text?), `defaultBranch` (text?), `jiraConnectionId` (text?), `jiraProjectKey` (text?), `techStack` (text?), `healthScore` (int?), `lastAuditAt` (dateTime?), `isArchived` (bool, default false), `createdAt` (dateTime?), `updatedAt` (dateTime?).

**Note:** The database `Projects` table does NOT include `jiraDefaultIssueType`, `jiraLabels`, or `jiraComponent` fields that exist on the API model `Project`.

#### QaJobs
PK: `id` (text). Columns: `projectId` (text), `projectName` (text?), `mode` (text), `status` (text), `name` (text?), `branch` (text?), `configJson` (text?), `summaryMd` (text?), `overallResult` (text?), `healthScore` (int?), `totalFindings` (int?), `criticalCount` (int?), `highCount` (int?), `mediumCount` (int?), `lowCount` (int?), `jiraTicketKey` (text?), `startedBy` (text?), `startedByName` (text?), `startedAt` (dateTime?), `completedAt` (dateTime?), `createdAt` (dateTime?).

#### AgentRuns
PK: `id` (text). Columns: `jobId` (text), `agentType` (text), `status` (text), `result` (text?), `reportS3Key` (text?), `score` (int?), `findingsCount` (int?), `criticalCount` (int?), `highCount` (int?), `startedAt` (dateTime?), `completedAt` (dateTime?).

#### Findings
PK: `id` (text). Columns: `jobId` (text), `agentType` (text), `severity` (text), `title` (text), `description` (text?), `filePath` (text?), `lineNumber` (int?), `recommendation` (text?), `evidence` (text?), `effortEstimate` (text?), `debtCategory` (text?), `findingStatus` (text -- note: named `findingStatus` not `status`), `statusChangedBy` (text?), `statusChangedAt` (dateTime?), `createdAt` (dateTime?).

#### RemediationTasks
PK: `id` (text). Columns: `jobId` (text), `taskNumber` (int), `title` (text), `description` (text?), `promptMd` (text?), `priority` (text?), `status` (text), `assignedTo` (text?), `assignedToName` (text?), `jiraKey` (text?), `createdAt` (dateTime?).

**Note:** Database does NOT include `promptS3Key` or `findingIds` fields from the API model.

#### Personas
PK: `id` (text). Columns: `name` (text), `agentType` (text?), `description` (text?), `contentMd` (text?), `scope` (text), `teamId` (text?), `createdBy` (text?), `createdByName` (text?), `isDefault` (bool, default false), `version` (int?), `createdAt` (dateTime?), `updatedAt` (dateTime?).

#### Directives
PK: `id` (text). Columns: `name` (text), `description` (text?), `contentMd` (text?), `category` (text?), `scope` (text), `teamId` (text?), `projectId` (text?), `createdBy` (text?), `createdByName` (text?), `version` (int?), `createdAt` (dateTime?), `updatedAt` (dateTime?).

#### TechDebtItems
PK: `id` (text). Columns: `projectId` (text), `category` (text), `title` (text), `description` (text?), `filePath` (text?), `effortEstimate` (text?), `businessImpact` (text?), `status` (text), `firstDetectedJobId` (text?), `resolvedJobId` (text?), `createdAt` (dateTime?), `updatedAt` (dateTime?).

#### DependencyScans
PK: `id` (text). Columns: `projectId` (text), `jobId` (text?), `manifestFile` (text?), `totalDependencies` (int?), `outdatedCount` (int?), `vulnerableCount` (int?), `createdAt` (dateTime?).

#### DependencyVulnerabilities
PK: `id` (text). Columns: `scanId` (text), `dependencyName` (text), `currentVersion` (text?), `fixedVersion` (text?), `cveId` (text?), `severity` (text), `description` (text?), `status` (text), `createdAt` (dateTime?).

#### HealthSnapshots
PK: `id` (text). Columns: `projectId` (text), `jobId` (text?), `healthScore` (int, required), `findingsBySeverity` (text?), `techDebtScore` (int?), `dependencyScore` (int?), `testCoveragePercent` (real?), `capturedAt` (dateTime?).

#### ComplianceItems
PK: `id` (text). Columns: `jobId` (text), `requirement` (text), `specId` (text?), `specName` (text?), `status` (text), `evidence` (text?), `agentType` (text?), `notes` (text?), `createdAt` (dateTime?).

#### Specifications
PK: `id` (text). Columns: `jobId` (text), `name` (text), `specType` (text?), `s3Key` (text), `createdAt` (dateTime?).

#### SyncMetadata
PK: `syncTableName` (text). Columns: `lastSyncAt` (dateTime, required), `etag` (text?).
Purpose: Tracks last sync time per table for incremental sync.

#### ClonedRepos
PK: `repoFullName` (text). Columns: `localPath` (text), `projectId` (text?), `clonedAt` (dateTime?), `lastAccessedAt` (dateTime?).
Purpose: Local registry of cloned git repositories.

#### AnthropicModels
PK: `id` (text). Columns: `displayName` (text), `modelFamily` (text?), `contextWindow` (int?), `maxOutputTokens` (int?), `fetchedAt` (dateTime, required).
Purpose: Cached Anthropic model metadata from `/v1/models` API.

#### AgentDefinitions
PK: `id` (text). Columns: `name` (text), `agentType` (text?), `isQaManager` (bool, default false), `isBuiltIn` (bool, default true), `isEnabled` (bool, default true), `modelId` (text?), `temperature` (real, default 0.0), `maxRetries` (int, default 1), `timeoutMinutes` (int?), `maxTurns` (int, default 50), `systemPromptOverride` (text?), `description` (text?), `sortOrder` (int, default 0), `createdAt` (dateTime, required), `updatedAt` (dateTime, required).
Purpose: Per-agent configuration for dispatch.

#### AgentFiles
PK: `id` (text). Columns: `agentDefinitionId` (text), `fileName` (text), `fileType` (text), `contentMd` (text?), `filePath` (text?), `sortOrder` (int, default 0), `createdAt` (dateTime, required), `updatedAt` (dateTime, required).
Purpose: Files (personas, prompts, context) attached to agent definitions.

#### ProjectLocalConfig
PK: `projectId` (text). Columns: `localWorkingDir` (text?).
Purpose: Machine-local project settings (working directory path) not synced to server.

#### ScribeTabs
PK: `id` (text). Columns: `title` (text), `filePath` (text?), `content` (text), `language` (text), `isDirty` (bool, default false), `cursorLine` (int, default 0), `cursorColumn` (int, default 0), `scrollOffset` (real, default 0.0), `displayOrder` (int, required), `createdAt` (dateTime, required), `lastModifiedAt` (dateTime, required).
Purpose: Persisted Scribe editor tabs for session restoration.

#### ScribeSettings
PK: `key` (text). Columns: `value` (text). Table name override: `scribe_settings`.
Purpose: Key-value store for editor configuration (JSON blob).

### Database Methods
- `clearAllTables()`: Deletes all rows from every table in a transaction. Used during logout.

---

## PART 6: SUMMARY STATISTICS

| Category | Count |
|---|---|
| Source .dart model files | 19 |
| Generated .g.dart files | 15 |
| Total enums (enums.dart) | 24 |
| Total enums (vcs_models.dart) | 2 |
| json_serializable model classes | 30 |
| Manual-serialization model classes | 18 (16 VCS + 2 Scribe) |
| UI-only view model classes | 3 (AgentProgress, AgentProgressSummary, JiraIssueDisplayModel) |
| Hybrid serialization classes | 1 (AnthropicModelInfo) |
| Database tables (Drift) | 23 |
| Database schema version | 7 |
| JsonConverter classes | 24 |


---

## 7. Enum Definitions

See PART 1: ENUMERATIONS in Data Model Layer (Section 6) above. Summary:

- **24 enums** in `lib/models/enums.dart`, each with camelCase values, SCREAMING_SNAKE_CASE serialization, `displayName` getter, and companion `JsonConverter`
- **2 enums** in `lib/models/vcs_models.dart` (`FileChangeType`, `DiffLineType`) with git-specific factories
- **6 const label maps** for display purposes

---

## 8. Local Database Schema

See PART 5 in Data Model Layer (Section 6) above. Summary:

- **Database:** `CodeOpsDatabase` (Drift/SQLite)
- **Schema version:** 7
- **23 tables:** Users, Teams, Projects, QaJobs, AgentRuns, Findings, RemediationTasks, Personas, Directives, TechDebtItems, DependencyScans, DependencyVulnerabilities, HealthSnapshots, ComplianceItems, Specifications, SyncMetadata, ClonedRepos, AnthropicModels, AgentDefinitions, AgentFiles, ProjectLocalConfig, ScribeTabs, ScribeSettings
- **Migration history:** v1 (core) -> v2 (ClonedRepos) -> v3 (configJson) -> v4 (summaryMd, statusChanged) -> v5 (Anthropic/Agent tables) -> v6 (ProjectLocalConfig) -> v7 (Scribe tables)

---

## 9. Service Layer

I have now read every single `.dart` file in the services directory. Here is the complete documentation.

---

# CodeOps-Client Services Layer -- Complete Audit

## services/agent/

### 1. ReportParser (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/agent/report_parser.dart`)

**Purpose:** Parses standardized markdown reports produced by QA agents into structured data models.

**Constructor:** `const ReportParser()` -- No dependencies.

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `parseReport` | `ParsedReport parseReport(String markdown)` | Parses a complete markdown report into a `ParsedReport`. Delegates to `parseFindings`, `parseMetadata`, `parseExecutiveSummary`, and `parseMetrics`. Logs warnings for missing sections. |
| `parseFindings` | `List<ParsedFinding> parseFindings(String markdown)` | Extracts all findings from `### [SEVERITY] Title` headings. Parses `File`, `Line`, `Description`, `Recommendation`, `Effort`, and `Evidence` labeled fields from each finding block. |
| `parseMetadata` | `ReportMetadata parseMetadata(String markdown)` | Extracts `**Project:**`, `**Date:**`, `**Agent:**`, `**Overall:**`, and `**Score:**` fields from the report header. |
| `parseExecutiveSummary` | `String? parseExecutiveSummary(String markdown)` | Extracts content from the `## Executive Summary` section. Returns `null` if absent. |
| `parseMetrics` | `ReportMetrics? parseMetrics(String markdown)` | Extracts `## Metrics` section markdown table values (Files Reviewed, Total Findings, Critical, High, Medium, Low, Score). Returns `null` if section is missing. |

**API Endpoints:** None (local-only service).

**Error Handling:** Tolerant of missing fields, inconsistent casing, and formatting variations. Returns `null` for missing optional sections rather than throwing.

**State Managed:** None (stateless, `const` constructor).

**Data Classes Defined Here:** `ParsedReport`, `ReportMetadata`, `ParsedFinding`, `ReportMetrics`.

---

### 2. TaskGenerator (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/agent/task_generator.dart`)

**Purpose:** Groups findings by file, calculates priority, generates Claude Code prompts, and batch-creates remediation tasks via the API.

**Constructor:** `TaskGenerator(TaskApi _taskApi)`

**Dependencies:** `TaskApi`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `generateTasks` | `Future<List<RemediationTask>> generateTasks({required String jobId, required List<Finding> findings})` | Groups findings by file, generates task payloads with prompts, and batch-creates them via `TaskApi.createTasksBatch`. Returns empty list for empty findings. |
| `generatePrompt` | `String generatePrompt(FindingGroup group)` | Generates a Claude Code-ready markdown prompt for a group of findings in a single file. Includes severity, agent, line, description, recommendation, and evidence fields. |
| `calculatePriority` | `Priority calculatePriority(List<Finding> findings)` | Returns P0-P3 priority based on the highest-severity finding in the group (critical=P0, high=P1, medium=P2, low=P3). |
| `groupByFile` | `List<FindingGroup> groupByFile(List<Finding> findings)` | Groups findings by `filePath`. Findings without a file path are grouped under `'(no file)'`. |
| `exportPromptToFile` | `Future<String> exportPromptToFile(String prompt, String outputPath)` | Writes a single prompt string to a file on disk. Returns the output path. |
| `exportAllAsZip` | `Future<String> exportAllAsZip({required List<RemediationTask> tasks, required String outputPath})` | Exports all task prompts as individual `.md` files inside a ZIP archive. |

**API Endpoints:** Calls `TaskApi.createTasksBatch` -> `POST /tasks/batch`

**Error Handling:** Propagates exceptions from `TaskApi`.

**State Managed:** None.

**Data Classes Defined Here:** `FindingGroup`.

---

### 3. AgentConfigService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/agent/agent_config_service.dart`)

**Purpose:** Manages local agent definitions (CRUD), attached files, and cached Anthropic model metadata in the Drift database.

**Constructor:**
```dart
AgentConfigService({
  required CodeOpsDatabase db,
  required AnthropicApiService anthropicApi,
  required SecureStorageService secureStorage,
})
```

**Dependencies:** `CodeOpsDatabase`, `AnthropicApiService`, `SecureStorageService`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `getCachedModels` | `Future<List<AnthropicModelInfo>> getCachedModels()` | Returns all cached Anthropic models from the local `anthropicModels` table. |
| `cacheModels` | `Future<void> cacheModels(List<AnthropicModelInfo> models)` | Replaces the entire model cache in a transaction (delete all, then insert). |
| `refreshModels` | `Future<List<AnthropicModelInfo>> refreshModels()` | Reads API key from secure storage, fetches models from Anthropic API, caches them locally. Returns empty list if no API key. |
| `getAllAgents` | `Future<List<AgentDefinition>> getAllAgents()` | Returns all agent definitions ordered by `sortOrder`. |
| `getAgent` | `Future<AgentDefinition?> getAgent(String id)` | Returns a single agent definition by ID, or `null`. |
| `createAgent` | `Future<AgentDefinition> createAgent({required String name, String? description, String? agentType})` | Creates a custom (non-built-in) agent definition with auto-incremented sort order. Returns the created `AgentDefinition`. |
| `updateAgent` | `Future<void> updateAgent(String id, {String? name, String? description, String? agentType, bool? isEnabled, String? modelId, double? temperature, int? maxRetries, int? timeoutMinutes, int? maxTurns, String? systemPromptOverride})` | Updates non-null fields on an existing agent definition. Stamps `updatedAt`. |
| `deleteAgent` | `Future<void> deleteAgent(String id)` | Deletes a custom agent and its attached files in a transaction. Throws `StateError` for built-in agents. |
| `reorderAgents` | `Future<void> reorderAgents(List<String> orderedIds)` | Updates `sortOrder` for all agents based on position in the provided list. |
| `getAgentFiles` | `Future<List<AgentFile>> getAgentFiles(String agentDefinitionId)` | Returns all files for an agent, ordered by `sortOrder`. |
| `addFile` | `Future<AgentFile> addFile(String agentDefinitionId, {required String fileName, required String fileType, String? contentMd, String? filePath})` | Creates a new file record attached to an agent. |
| `updateFile` | `Future<void> updateFile(String fileId, {String? fileName, String? contentMd, String? fileType})` | Updates non-null fields on an existing file record. |
| `deleteFile` | `Future<void> deleteFile(String fileId)` | Deletes a file record by ID. |
| `importFileFromDisk` | `Future<AgentFile?> importFileFromDisk(String agentDefinitionId)` | Opens a file picker for `.md`/`.txt`/`.markdown` files, reads content, and adds as a `context` type file. Returns `null` if cancelled. |
| `seedBuiltInAgents` | `Future<void> seedBuiltInAgents()` | Idempotently seeds 13 built-in agent definitions (Vera + 12 specialists) with persona files from bundled assets. |

**API Endpoints:** Calls `AnthropicApiService.fetchModels` -> `GET https://api.anthropic.com/v1/models`

**Error Handling:** `seedBuiltInAgents` catches errors loading persona assets and logs warnings. `refreshModels` returns empty list if no API key.

**State Managed:** Local Drift database tables: `agentDefinitions`, `agentFiles`, `anthropicModels`.

---

### 4. PersonaManager (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/agent/persona_manager.dart`)

**Purpose:** Assembles complete agent prompts by layering persona content, team/project directives, agent file contents, job context, and report format instructions.

**Constructor:**
```dart
PersonaManager({
  required PersonaApi personaApi,
  required DirectiveApi directiveApi,
})
```

**Dependencies:** `PersonaApi`, `DirectiveApi`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `assemblePrompt` | `Future<String> assemblePrompt({required AgentType agentType, required String teamId, required String projectId, required JobMode mode, required String projectName, required String branch, String? additionalContext, String? jiraTicketData, List<String>? specReferences, List<String>? agentFileContents})` | Assembles a complete markdown prompt from 5 layers: persona, directives, agent files, job context, and report format instructions. Returns a single string joined with `---` separators. |
| `loadBuiltInPersona` | `Future<String> loadBuiltInPersona(AgentType agentType)` | Loads persona markdown from bundled assets at `assets/personas/agent-{kebab-type}.md`. |
| `loadTeamPersona` | `Future<String?> loadTeamPersona(String teamId, AgentType agentType)` | Fetches the team's default persona for an agent type from the server. Returns `null` if no override exists or on error. |
| `loadDirectives` | `Future<String> loadDirectives(String teamId, String projectId)` | Loads and concatenates team directives + project-scoped enabled directives. Each directive is rendered under a `###` heading. |

**API Endpoints:**
- `PersonaApi.getTeamDefaultPersona` -> `GET /personas/team/{teamId}/default/{agentType}`
- `DirectiveApi.getTeamDirectives` -> `GET /directives/team/{teamId}`
- `DirectiveApi.getProjectEnabledDirectives` -> `GET /directives/project/{projectId}/enabled`

**Error Handling:** `loadTeamPersona` catches all exceptions and falls back to built-in persona. `loadDirectives` catches exceptions on team and project directive fetches independently, continuing without them.

**State Managed:** None.

---

## services/analysis/

### 5. HealthCalculator (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/analysis/health_calculator.dart`)

**Purpose:** Computes composite health scores from agent runs using weighted averages and finding-based deductions.

**Constructor:** `const HealthCalculator()` -- No dependencies.

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `calculateCompositeScore` | `HealthResult calculateCompositeScore(List<AgentRun> agentRuns)` | Calculates a weighted average health score across all completed agent runs. Security and Architecture agents receive 1.5x weight. Returns `HealthResult` with score, result (pass/warn/fail), and per-agent scores. |
| `determineResult` | `AgentResult determineResult(int score)` | Maps a numeric score to pass/warn/fail using `AppConstants` thresholds. |
| `calculateFindingBasedScore` | `int calculateFindingBasedScore({int criticalCount = 0, int highCount = 0, int mediumCount = 0, int lowCount = 0})` | Starts at 100 and deducts per severity level using `AppConstants` reduction values. Clamped to 0-100. |
| `getAgentWeight` | `double getAgentWeight(AgentType agentType)` | Returns weight multiplier: 1.5x for Security/Architecture, 1.0x for others. |

**API Endpoints:** None (local-only).

**Error Handling:** Returns score=0, result=fail for empty input.

**State Managed:** None.

**Data Classes Defined Here:** `HealthResult`.

---

### 6. TechDebtTracker (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/analysis/tech_debt_tracker.dart`)

**Purpose:** Local analysis service for tech debt trend computations: weighted scoring, category/status breakdowns, resolution rate, priority matrix, and markdown report generation.

**Constructor:** None (all methods are `static`).

**Public Methods (all static):**

| Method | Signature | Description |
|--------|-----------|-------------|
| `computeDebtScore` | `static int computeDebtScore(List<TechDebtItem> items)` | Computes weighted debt score: `categoryWeight x effortMultiplier x impactMultiplier` per non-resolved item. |
| `computeDebtByCategory` | `static Map<DebtCategory, int> computeDebtByCategory(List<TechDebtItem> items)` | Returns count of items per `DebtCategory`. |
| `computeDebtByStatus` | `static Map<DebtStatus, int> computeDebtByStatus(List<TechDebtItem> items)` | Returns count of items per `DebtStatus`. |
| `computeResolutionRate` | `static double computeResolutionRate(List<TechDebtItem> items)` | Returns resolution percentage (0.0-100.0). Returns 0.0 for empty lists. |
| `computePriorityMatrix` | `static List<TechDebtItem> computePriorityMatrix(List<TechDebtItem> items)` | Sorts items by high impact descending, then low effort ascending (high-impact/low-effort items first). |
| `formatDebtReport` | `static String formatDebtReport(List<TechDebtItem> items, Map<String, dynamic> summary)` | Generates a full markdown tech debt report with summary, status/category breakdowns, and top-10 priority items table. |

**API Endpoints:** None (local-only).

**Error Handling:** Defaults to `Effort.s` (1) and `BusinessImpact.low` (1) for null values.

**State Managed:** None.

---

### 7. DependencyScanner (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/analysis/dependency_scanner.dart`)

**Purpose:** Local analysis service for dependency health: score calculation, vulnerability grouping, actionable filtering, and markdown report generation.

**Constructor:** None (all methods are `static`).

**Public Methods (all static):**

| Method | Signature | Description |
|--------|-----------|-------------|
| `computeDepHealthScore` | `static int computeDepHealthScore(DependencyScan scan, List<DependencyVulnerability> vulns)` | Score = 100 minus deductions (critical=25, high=10, medium=3, low=1 per non-resolved vuln), clamped 0-100. |
| `groupBySeverity` | `static Map<Severity, List<DependencyVulnerability>> groupBySeverity(List<DependencyVulnerability> vulns)` | Groups vulnerabilities by severity level. |
| `groupByStatus` | `static Map<VulnerabilityStatus, List<DependencyVulnerability>> groupByStatus(List<DependencyVulnerability> vulns)` | Groups vulnerabilities by status. |
| `getActionableVulns` | `static List<DependencyVulnerability> getActionableVulns(List<DependencyVulnerability> vulns)` | Filters to OPEN vulnerabilities that have a `fixedVersion` available. |
| `formatDepReport` | `static String formatDepReport(DependencyScan scan, List<DependencyVulnerability> vulns)` | Generates a markdown dependency health report with overview, severity summary, and recommended updates table. |

**API Endpoints:** None (local-only).

**Error Handling:** Returns score 0 if deductions exceed 100.

**State Managed:** None.

---

## services/auth/

### 8. AuthService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/auth/auth_service.dart`)

**Purpose:** Manages authentication lifecycle: login, registration, token refresh, and logout. Exposes an `authStateStream` for reactive UI binding.

**Constructor:**
```dart
AuthService({
  required ApiClient apiClient,
  required SecureStorageService secureStorage,
  required CodeOpsDatabase database,
})
```

**Dependencies:** `ApiClient`, `SecureStorageService`, `CodeOpsDatabase`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `login` | `Future<User> login(String email, String password)` | Authenticates with email/password. Stores tokens, emits `authenticated`, returns `User`. |
| `register` | `Future<User> register(String email, String password, String displayName)` | Registers new account. Stores tokens, emits `authenticated`, returns `User`. |
| `refreshToken` | `Future<void> refreshToken()` | Refreshes access token using stored refresh token. If no refresh token, emits `unauthenticated`. |
| `changePassword` | `Future<void> changePassword(String currentPassword, String newPassword)` | Changes the current user's password. |
| `logout` | `Future<void> logout()` | Clears all tokens, wipes local DB, emits `unauthenticated`. |
| `tryAutoLogin` | `Future<void> tryAutoLogin()` | Validates stored token via `GET /users/me`. On success emits `authenticated`; on failure clears tokens and emits `unauthenticated`. |
| `dispose` | `void dispose()` | Closes the `authStateStream` controller. |

**Public Getters:**

| Getter | Type | Description |
|--------|------|-------------|
| `authStateStream` | `Stream<AuthState>` | Broadcast stream of auth state changes. |
| `currentState` | `AuthState` | Current auth state (unknown/authenticated/unauthenticated). |
| `currentUser` | `User?` | Currently authenticated user, or null. |

**API Endpoints:**
- `POST /auth/login` (email, password) -> AuthResponse
- `POST /auth/register` (email, password, displayName) -> AuthResponse
- `POST /auth/refresh` (refreshToken) -> AuthResponse
- `POST /auth/change-password` (currentPassword, newPassword)
- `GET /users/me` -> User (for auto-login validation)

**Error Handling:** `tryAutoLogin` catches `DioException`, checks for `UnauthorizedException`, clears storage on 401, and emits `unauthenticated`.

**State Managed:** `_currentState` (AuthState), `_currentUser` (User?), `_authStateController` (StreamController).

---

### 9. SecureStorageService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/auth/secure_storage.dart`)

**Purpose:** Key-value storage backed by SharedPreferences (UserDefaults on macOS). Replaces flutter_secure_storage to avoid macOS Keychain password dialogs.

**Constructor:** `SecureStorageService({SharedPreferences? prefs})` -- Optional `prefs` for test injection.

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `getAuthToken` | `Future<String?> getAuthToken()` | Reads JWT access token. |
| `setAuthToken` | `Future<void> setAuthToken(String token)` | Stores JWT access token. |
| `getRefreshToken` | `Future<String?> getRefreshToken()` | Reads refresh token. |
| `setRefreshToken` | `Future<void> setRefreshToken(String token)` | Stores refresh token. |
| `getCurrentUserId` | `Future<String?> getCurrentUserId()` | Reads current user ID. |
| `setCurrentUserId` | `Future<void> setCurrentUserId(String userId)` | Stores current user ID. |
| `getSelectedTeamId` | `Future<String?> getSelectedTeamId()` | Reads selected team ID. |
| `setSelectedTeamId` | `Future<void> setSelectedTeamId(String teamId)` | Stores selected team ID. |
| `read` | `Future<String?> read(String key)` | Generic read by key. |
| `write` | `Future<void> write(String key, String value)` | Generic write key-value. |
| `delete` | `Future<void> delete(String key)` | Deletes a specific key. |
| `getAnthropicApiKey` | `Future<String?> getAnthropicApiKey()` | Reads the Anthropic API key. |
| `setAnthropicApiKey` | `Future<void> setAnthropicApiKey(String apiKey)` | Stores the Anthropic API key. |
| `deleteAnthropicApiKey` | `Future<void> deleteAnthropicApiKey()` | Deletes the Anthropic API key. |
| `clearAll` | `Future<void> clearAll()` | Clears all storage, preserving remember-me credentials and Anthropic API key across logout. |

**API Endpoints:** None (local storage only).

**Error Handling:** None -- delegates to SharedPreferences.

**State Managed:** `_prefs` (SharedPreferences, lazily initialized).

---

## services/cloud/

### 10. ApiException hierarchy (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/api_exceptions.dart`)

**Purpose:** Typed exception hierarchy for CodeOps API errors. Sealed class enabling exhaustive pattern matching.

**Classes:**
- `ApiException` (sealed base) -- `message`, `statusCode`
- `BadRequestException` (400) -- `errors: Map<String, String>?`
- `UnauthorizedException` (401)
- `ForbiddenException` (403)
- `NotFoundException` (404)
- `ConflictException` (409)
- `ValidationException` (422) -- `fieldErrors: Map<String, String>?`
- `RateLimitException` (429) -- `retryAfterSeconds: int?`
- `ServerException` (500+) -- `statusCode: int`
- `NetworkException` (null status)
- `TimeoutException` (null status)

---

### 11. ApiClient (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/api_client.dart`)

**Purpose:** Centralized HTTP client wrapping Dio with 4 interceptors: auth, refresh, error mapping, and logging.

**Constructor:** `ApiClient({required SecureStorageService secureStorage})`

**Dependencies:** `SecureStorageService`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `get` | `Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters})` | GET request. |
| `post` | `Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters})` | POST request. |
| `put` | `Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters})` | PUT request. |
| `delete` | `Future<Response<T>> delete<T>(String path, {Map<String, dynamic>? queryParameters})` | DELETE request. |
| `uploadFile` | `Future<Response<T>> uploadFile<T>(String path, {required String filePath, String fieldName = 'file'})` | Multipart file upload POST. |
| `downloadFile` | `Future<Response> downloadFile(String path, String savePath)` | Downloads a file to `savePath`. |

**Public Properties:**
- `onAuthFailure: VoidCallback?` -- Called when token refresh fails (triggers logout).
- `dio: Dio` (@visibleForTesting) -- Exposes underlying Dio.

**Interceptor Behavior:**
1. **Auth**: Attaches `Authorization: Bearer <token>` except for public paths (`/auth/login`, `/auth/register`, `/auth/refresh`, `/health`).
2. **Refresh**: On 401, attempts token refresh with a fresh Dio instance, retries original request. On failure, calls `onAuthFailure`.
3. **Error**: Maps `DioException` to typed `ApiException` subtypes.
4. **Logging**: Logs request/response with correlation IDs and timing. Never logs bodies or tokens.

**State Managed:** `_isRefreshing` (bool), `onAuthFailure` callback.

---

### 12. UserApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/user_api.dart`)

**Purpose:** API service for user endpoints.

**Constructor:** `UserApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `getCurrentUser` | `Future<User> getCurrentUser()` | `GET /users/me` |
| `getUserById` | `Future<User> getUserById(String id)` | `GET /users/{id}` |
| `updateUser` | `Future<User> updateUser(String id, {String? displayName, String? avatarUrl})` | `PUT /users/{id}` |
| `searchUsers` | `Future<List<User>> searchUsers(String query)` | `GET /users/search?q={query}` |
| `deactivateUser` | `Future<void> deactivateUser(String id)` | `PUT /users/{id}/deactivate` |
| `activateUser` | `Future<void> activateUser(String id)` | `PUT /users/{id}/activate` |

**Error Handling:** Propagates `ApiException` from `ApiClient`.

---

### 13. TeamApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/team_api.dart`)

**Purpose:** API service for team management, membership, and invitations.

**Constructor:** `TeamApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `getTeams` | `Future<List<Team>> getTeams()` | `GET /teams` |
| `createTeam` | `Future<Team> createTeam({required String name, String? description, String? teamsWebhookUrl})` | `POST /teams` |
| `getTeam` | `Future<Team> getTeam(String teamId)` | `GET /teams/{teamId}` |
| `updateTeam` | `Future<Team> updateTeam(String teamId, {String? name, String? description, String? teamsWebhookUrl})` | `PUT /teams/{teamId}` |
| `deleteTeam` | `Future<void> deleteTeam(String teamId)` | `DELETE /teams/{teamId}` |
| `getTeamMembers` | `Future<List<TeamMember>> getTeamMembers(String teamId)` | `GET /teams/{teamId}/members` |
| `updateMemberRole` | `Future<TeamMember> updateMemberRole(String teamId, String userId, TeamRole role)` | `PUT /teams/{teamId}/members/{userId}/role` |
| `removeMember` | `Future<void> removeMember(String teamId, String userId)` | `DELETE /teams/{teamId}/members/{userId}` |
| `inviteMember` | `Future<Invitation> inviteMember(String teamId, {required String email, required TeamRole role})` | `POST /teams/{teamId}/invitations` |
| `getTeamInvitations` | `Future<List<Invitation>> getTeamInvitations(String teamId)` | `GET /teams/{teamId}/invitations` |
| `cancelInvitation` | `Future<void> cancelInvitation(String teamId, String invitationId)` | `DELETE /teams/{teamId}/invitations/{invitationId}` |
| `acceptInvitation` | `Future<Team> acceptInvitation(String token)` | `POST /teams/invitations/{token}/accept` |

---

### 14. FindingApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/finding_api.dart`)

**Purpose:** API service for finding CRUD, filtering, and bulk status updates.

**Constructor:** `FindingApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createFinding` | `Future<Finding> createFinding({required String jobId, required AgentType agentType, required Severity severity, required String title, ...})` | `POST /findings` |
| `createFindingsBatch` | `Future<List<Finding>> createFindingsBatch(List<Map<String, dynamic>> findings)` | `POST /findings/batch` |
| `getJobFindings` | `Future<PageResponse<Finding>> getJobFindings(String jobId, {int page = 0, int size = 20})` | `GET /findings/job/{jobId}?page=&size=` |
| `getFinding` | `Future<Finding> getFinding(String findingId)` | `GET /findings/{findingId}` |
| `getFindingsBySeverity` | `Future<List<Finding>> getFindingsBySeverity(String jobId, Severity severity)` | `GET /findings/job/{jobId}/severity/{severity}` |
| `getFindingsByStatus` | `Future<List<Finding>> getFindingsByStatus(String jobId, FindingStatus status)` | `GET /findings/job/{jobId}/status/{status}` |
| `getFindingsByAgent` | `Future<List<Finding>> getFindingsByAgent(String jobId, AgentType agentType)` | `GET /findings/job/{jobId}/agent/{agentType}` |
| `getFindingCounts` | `Future<Map<String, dynamic>> getFindingCounts(String jobId)` | `GET /findings/job/{jobId}/counts` |
| `updateFindingStatus` | `Future<Finding> updateFindingStatus(String findingId, FindingStatus status)` | `PUT /findings/{findingId}/status` |
| `bulkUpdateStatus` | `Future<List<Finding>> bulkUpdateStatus(List<String> findingIds, FindingStatus status)` | `PUT /findings/bulk-status` |

---

### 15. ReportApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/report_api.dart`)

**Purpose:** API service for report upload/download (summary, per-agent, specification files).

**Constructor:** `ReportApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `uploadSummaryReport` | `Future<Map<String, dynamic>> uploadSummaryReport(String jobId, String markdownContent)` | `POST /reports/job/{jobId}/summary` |
| `uploadAgentReport` | `Future<Map<String, dynamic>> uploadAgentReport(String jobId, AgentType agentType, String reportJson)` | `POST /reports/job/{jobId}/agent/{agentType}` |
| `uploadSpecification` | `Future<Map<String, dynamic>> uploadSpecification(String jobId, String filePath)` | `POST /reports/job/{jobId}/spec` (multipart) |
| `downloadReport` | `Future<String> downloadReport(String s3Key, String savePath)` | `GET /reports/download?s3Key=` |
| `downloadSpecReport` | `Future<void> downloadSpecReport(String s3Key, String savePath)` | `GET /reports/spec/download?s3Key=` (file download) |

---

### 16. DirectiveApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/directive_api.dart`)

**Purpose:** API service for directive CRUD, team/project scoping, and project-directive assignment toggling.

**Constructor:** `DirectiveApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createDirective` | `Future<Directive> createDirective({required String name, required String contentMd, required DirectiveScope scope, String? description, DirectiveCategory? category, String? teamId, String? projectId})` | `POST /directives` |
| `getDirective` | `Future<Directive> getDirective(String directiveId)` | `GET /directives/{directiveId}` |
| `updateDirective` | `Future<Directive> updateDirective(String directiveId, {String? name, String? description, String? contentMd, DirectiveCategory? category})` | `PUT /directives/{directiveId}` |
| `deleteDirective` | `Future<void> deleteDirective(String directiveId)` | `DELETE /directives/{directiveId}` |
| `getTeamDirectives` | `Future<List<Directive>> getTeamDirectives(String teamId)` | `GET /directives/team/{teamId}` |
| `getProjectDirectives` | `Future<List<Directive>> getProjectDirectives(String projectId)` | `GET /directives/project/{projectId}` |
| `getProjectEnabledDirectives` | `Future<List<Directive>> getProjectEnabledDirectives(String projectId)` | `GET /directives/project/{projectId}/enabled` |
| `getProjectDirectiveAssignments` | `Future<List<ProjectDirective>> getProjectDirectiveAssignments(String projectId)` | `GET /directives/project/{projectId}/assignments` |
| `assignToProject` | `Future<ProjectDirective> assignToProject({required String projectId, required String directiveId, bool enabled = true})` | `POST /directives/assign` |
| `toggleDirective` | `Future<ProjectDirective> toggleDirective(String projectId, String directiveId, bool enabled)` | `PUT /directives/project/{projectId}/directive/{directiveId}/toggle?enabled=` |
| `removeFromProject` | `Future<void> removeFromProject(String projectId, String directiveId)` | `DELETE /directives/project/{projectId}/directive/{directiveId}` |

---

### 17. MetricsApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/metrics_api.dart`)

**Purpose:** API service for team/project aggregated metrics and health trends.

**Constructor:** `MetricsApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `getTeamMetrics` | `Future<TeamMetrics> getTeamMetrics(String teamId)` | `GET /metrics/team/{teamId}` |
| `getProjectMetrics` | `Future<ProjectMetrics> getProjectMetrics(String projectId)` | `GET /metrics/project/{projectId}` |
| `getProjectTrend` | `Future<List<HealthSnapshot>> getProjectTrend(String projectId, {int days = 30})` | `GET /metrics/project/{projectId}/trend?days=` |

---

### 18. AdminApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/admin_api.dart`)

**Purpose:** API service for admin/owner-restricted endpoints: user management, settings, audit logs, usage stats.

**Constructor:** `AdminApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `getAllUsers` | `Future<PageResponse<User>> getAllUsers({int page = 0, int size = 20})` | `GET /admin/users?page=&size=` |
| `getUserById` | `Future<User> getUserById(String userId)` | `GET /admin/users/{userId}` |
| `updateUserStatus` | `Future<User> updateUserStatus(String userId, {required bool isActive})` | `PUT /admin/users/{userId}` |
| `getAllSettings` | `Future<List<SystemSetting>> getAllSettings()` | `GET /admin/settings` |
| `getSetting` | `Future<SystemSetting> getSetting(String key)` | `GET /admin/settings/{key}` |
| `updateSetting` | `Future<SystemSetting> updateSetting({required String key, required String value})` | `PUT /admin/settings` |
| `getUsageStats` | `Future<Map<String, dynamic>> getUsageStats()` | `GET /admin/usage` |
| `getTeamAuditLog` | `Future<PageResponse<AuditLogEntry>> getTeamAuditLog(String teamId, {int page = 0, int size = 20})` | `GET /admin/audit-log/team/{teamId}?page=&size=` |
| `getUserAuditLog` | `Future<PageResponse<AuditLogEntry>> getUserAuditLog(String userId, {int page = 0, int size = 20})` | `GET /admin/audit-log/user/{userId}?page=&size=` |

---

### 19. ComplianceApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/compliance_api.dart`)

**Purpose:** API service for compliance specifications and compliance items.

**Constructor:** `ComplianceApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createSpecification` | `Future<Specification> createSpecification({required String jobId, required String name, required String s3Key, SpecType? specType})` | `POST /compliance/specs` |
| `getSpecificationsForJob` | `Future<PageResponse<Specification>> getSpecificationsForJob(String jobId, {int page = 0, int size = 20})` | `GET /compliance/specs/job/{jobId}?page=&size=` |
| `createComplianceItem` | `Future<ComplianceItem> createComplianceItem({required String jobId, required String requirement, required ComplianceStatus status, ...})` | `POST /compliance/items` |
| `createComplianceItems` | `Future<List<ComplianceItem>> createComplianceItems(List<Map<String, dynamic>> items)` | `POST /compliance/items/batch` |
| `getComplianceItemsForJob` | `Future<PageResponse<ComplianceItem>> getComplianceItemsForJob(String jobId, {int page = 0, int size = 50})` | `GET /compliance/items/job/{jobId}?page=&size=` |
| `getComplianceItemsByStatus` | `Future<PageResponse<ComplianceItem>> getComplianceItemsByStatus(String jobId, ComplianceStatus status, {int page = 0, int size = 50})` | `GET /compliance/items/job/{jobId}/status/{status}?page=&size=` |
| `getComplianceSummary` | `Future<Map<String, dynamic>> getComplianceSummary(String jobId)` | `GET /compliance/summary/job/{jobId}` |

---

### 20. TechDebtApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/tech_debt_api.dart`)

**Purpose:** API service for tech debt CRUD, filtering, status updates, and summary.

**Constructor:** `TechDebtApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createTechDebtItem` | `Future<TechDebtItem> createTechDebtItem({required String projectId, required DebtCategory category, required String title, ...})` | `POST /tech-debt` |
| `createTechDebtItems` | `Future<List<TechDebtItem>> createTechDebtItems(List<Map<String, dynamic>> items)` | `POST /tech-debt/batch` |
| `getTechDebtItem` | `Future<TechDebtItem> getTechDebtItem(String itemId)` | `GET /tech-debt/{itemId}` |
| `getTechDebtForProject` | `Future<PageResponse<TechDebtItem>> getTechDebtForProject(String projectId, {int page = 0, int size = 20})` | `GET /tech-debt/project/{projectId}?page=&size=` |
| `getTechDebtByStatus` | `Future<PageResponse<TechDebtItem>> getTechDebtByStatus(String projectId, DebtStatus status, {int page = 0, int size = 20})` | `GET /tech-debt/project/{projectId}/status/{status}?page=&size=` |
| `getTechDebtByCategory` | `Future<PageResponse<TechDebtItem>> getTechDebtByCategory(String projectId, DebtCategory category, {int page = 0, int size = 20})` | `GET /tech-debt/project/{projectId}/category/{category}?page=&size=` |
| `updateTechDebtStatus` | `Future<TechDebtItem> updateTechDebtStatus(String itemId, {required DebtStatus status, String? resolvedJobId})` | `PUT /tech-debt/{itemId}/status` |
| `deleteTechDebtItem` | `Future<void> deleteTechDebtItem(String itemId)` | `DELETE /tech-debt/{itemId}` |
| `getDebtSummary` | `Future<Map<String, dynamic>> getDebtSummary(String projectId)` | `GET /tech-debt/project/{projectId}/summary` |

---

### 21. DependencyApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/dependency_api.dart`)

**Purpose:** API service for dependency scans and vulnerabilities.

**Constructor:** `DependencyApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createScan` | `Future<DependencyScan> createScan({required String projectId, String? jobId, ...})` | `POST /dependencies/scans` |
| `getScan` | `Future<DependencyScan> getScan(String scanId)` | `GET /dependencies/scans/{scanId}` |
| `getScansForProject` | `Future<PageResponse<DependencyScan>> getScansForProject(String projectId, {int page = 0, int size = 20})` | `GET /dependencies/scans/project/{projectId}?page=&size=` |
| `getLatestScan` | `Future<DependencyScan> getLatestScan(String projectId)` | `GET /dependencies/scans/project/{projectId}/latest` |
| `addVulnerability` | `Future<DependencyVulnerability> addVulnerability({required String scanId, required String dependencyName, required Severity severity, ...})` | `POST /dependencies/vulnerabilities` |
| `addVulnerabilities` | `Future<List<DependencyVulnerability>> addVulnerabilities(List<Map<String, dynamic>> vulnerabilities)` | `POST /dependencies/vulnerabilities/batch` |
| `getVulnerabilities` | `Future<PageResponse<DependencyVulnerability>> getVulnerabilities(String scanId, {int page = 0, int size = 20})` | `GET /dependencies/vulnerabilities/scan/{scanId}?page=&size=` |
| `getVulnerabilitiesBySeverity` | `Future<PageResponse<DependencyVulnerability>> getVulnerabilitiesBySeverity(String scanId, Severity severity, {int page = 0, int size = 20})` | `GET /dependencies/vulnerabilities/scan/{scanId}/severity/{severity}?page=&size=` |
| `getOpenVulnerabilities` | `Future<PageResponse<DependencyVulnerability>> getOpenVulnerabilities(String scanId, {int page = 0, int size = 20})` | `GET /dependencies/vulnerabilities/scan/{scanId}/open?page=&size=` |
| `updateVulnerabilityStatus` | `Future<DependencyVulnerability> updateVulnerabilityStatus(String vulnerabilityId, VulnerabilityStatus status)` | `PUT /dependencies/vulnerabilities/{vulnerabilityId}/status?status=` (query param) |

---

### 22. HealthMonitorApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/health_monitor_api.dart`)

**Purpose:** API service for health monitoring schedules and snapshots.

**Constructor:** `HealthMonitorApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createSchedule` | `Future<HealthSchedule> createSchedule({required String projectId, required ScheduleType scheduleType, required List<AgentType> agentTypes, String? cronExpression})` | `POST /health-monitor/schedules` |
| `getSchedulesForProject` | `Future<List<HealthSchedule>> getSchedulesForProject(String projectId)` | `GET /health-monitor/schedules/project/{projectId}` |
| `updateSchedule` | `Future<HealthSchedule> updateSchedule(String scheduleId, bool active)` | `PUT /health-monitor/schedules/{scheduleId}?active=` |
| `deleteSchedule` | `Future<void> deleteSchedule(String scheduleId)` | `DELETE /health-monitor/schedules/{scheduleId}` |
| `createSnapshot` | `Future<HealthSnapshot> createSnapshot({required String projectId, required int healthScore, String? jobId, ...})` | `POST /health-monitor/snapshots` |
| `getSnapshots` | `Future<PageResponse<HealthSnapshot>> getSnapshots(String projectId, {int page = 0, int size = 20})` | `GET /health-monitor/snapshots/project/{projectId}?page=&size=` |
| `getLatestSnapshot` | `Future<HealthSnapshot?> getLatestSnapshot(String projectId)` | `GET /health-monitor/snapshots/project/{projectId}/latest` |
| `getHealthTrend` | `Future<List<HealthSnapshot>> getHealthTrend(String projectId, {int days = 30})` | `GET /health-monitor/snapshots/project/{projectId}/trend?limit=` |

---

### 23. IntegrationApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/integration_api.dart`)

**Purpose:** API service for GitHub and Jira connection CRUD.

**Constructor:** `IntegrationApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createGitHubConnection` | `Future<GitHubConnection> createGitHubConnection(String teamId, {required String name, required GitHubAuthType authType, required String credentials, String? githubUsername})` | `POST /integrations/github/{teamId}` |
| `getTeamGitHubConnections` | `Future<List<GitHubConnection>> getTeamGitHubConnections(String teamId)` | `GET /integrations/github/{teamId}` |
| `getGitHubConnection` | `Future<GitHubConnection> getGitHubConnection(String teamId, String connectionId)` | `GET /integrations/github/{teamId}/{connectionId}` |
| `deleteGitHubConnection` | `Future<void> deleteGitHubConnection(String teamId, String connectionId)` | `DELETE /integrations/github/{teamId}/{connectionId}` |
| `createJiraConnection` | `Future<JiraConnection> createJiraConnection(String teamId, {required String name, required String instanceUrl, required String email, required String apiToken})` | `POST /integrations/jira/{teamId}` |
| `getTeamJiraConnections` | `Future<List<JiraConnection>> getTeamJiraConnections(String teamId)` | `GET /integrations/jira/{teamId}` |
| `getJiraConnection` | `Future<JiraConnection> getJiraConnection(String teamId, String connectionId)` | `GET /integrations/jira/{teamId}/{connectionId}` |
| `deleteJiraConnection` | `Future<void> deleteJiraConnection(String teamId, String connectionId)` | `DELETE /integrations/jira/{teamId}/{connectionId}` |

---

### 24. ProjectApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/project_api.dart`)

**Purpose:** API service for project CRUD, archiving, and team-scoped listing.

**Constructor:** `ProjectApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createProject` | `Future<Project> createProject(String teamId, {required String name, String? description, ...many optional params...})` | `POST /projects/{teamId}` |
| `getTeamProjects` | `Future<List<Project>> getTeamProjects(String teamId, {bool includeArchived = false})` | `GET /projects/team/{teamId}?includeArchived=&size=100` |
| `getTeamProjectsPaged` | `Future<PageResponse<Project>> getTeamProjectsPaged(String teamId, {int page = 0, int size = 20, bool includeArchived = false})` | `GET /projects/team/{teamId}/paged?page=&size=&includeArchived=` |
| `getProject` | `Future<Project> getProject(String projectId)` | `GET /projects/{projectId}` |
| `updateProject` | `Future<Project> updateProject(String projectId, {String? name, ...many optional params...})` | `PUT /projects/{projectId}` |
| `deleteProject` | `Future<void> deleteProject(String projectId)` | `DELETE /projects/{projectId}` |
| `archiveProject` | `Future<void> archiveProject(String projectId)` | `PUT /projects/{projectId}/archive` |
| `unarchiveProject` | `Future<void> unarchiveProject(String projectId)` | `PUT /projects/{projectId}/unarchive` |

---

### 25. PersonaApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/persona_api.dart`)

**Purpose:** API service for persona CRUD, team scoping, defaults, and search by agent type.

**Constructor:** `PersonaApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createPersona` | `Future<Persona> createPersona({required String name, required String contentMd, required Scope scope, ...})` | `POST /personas` |
| `getPersona` | `Future<Persona> getPersona(String personaId)` | `GET /personas/{personaId}` |
| `updatePersona` | `Future<Persona> updatePersona(String personaId, {String? name, String? description, String? contentMd, bool? isDefault})` | `PUT /personas/{personaId}` |
| `deletePersona` | `Future<void> deletePersona(String personaId)` | `DELETE /personas/{personaId}` |
| `getTeamPersonas` | `Future<List<Persona>> getTeamPersonas(String teamId)` | `GET /personas/team/{teamId}` |
| `getTeamPersonasByAgentType` | `Future<List<Persona>> getTeamPersonasByAgentType(String teamId, AgentType agentType)` | `GET /personas/team/{teamId}/agent/{agentType}` |
| `getTeamDefaultPersona` | `Future<Persona> getTeamDefaultPersona(String teamId, AgentType agentType)` | `GET /personas/team/{teamId}/default/{agentType}` |
| `setAsDefault` | `Future<Persona> setAsDefault(String personaId)` | `PUT /personas/{personaId}/set-default` |
| `removeDefault` | `Future<Persona> removeDefault(String personaId)` | `PUT /personas/{personaId}/remove-default` |
| `getSystemPersonas` | `Future<List<Persona>> getSystemPersonas()` | `GET /personas/system` |
| `getMyPersonas` | `Future<List<Persona>> getMyPersonas()` | `GET /personas/mine` |

---

### 26. TaskApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/task_api.dart`)

**Purpose:** API service for remediation task CRUD.

**Constructor:** `TaskApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createTask` | `Future<RemediationTask> createTask({required String jobId, required int taskNumber, required String title, ...})` | `POST /tasks` |
| `createTasksBatch` | `Future<List<RemediationTask>> createTasksBatch(List<Map<String, dynamic>> tasks)` | `POST /tasks/batch` |
| `getTasksForJob` | `Future<List<RemediationTask>> getTasksForJob(String jobId)` | `GET /tasks/job/{jobId}` |
| `getTask` | `Future<RemediationTask> getTask(String taskId)` | `GET /tasks/{taskId}` |
| `updateTask` | `Future<RemediationTask> updateTask(String taskId, {TaskStatus? status, String? assignedTo, String? jiraKey})` | `PUT /tasks/{taskId}` |
| `getAssignedTasks` | `Future<List<RemediationTask>> getAssignedTasks()` | `GET /tasks/assigned-to-me` |

---

### 27. AnthropicApiService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/anthropic_api_service.dart`)

**Purpose:** Anthropic API client for model discovery and API key validation. Uses its own Dio instance targeting `https://api.anthropic.com`.

**Constructor:** `AnthropicApiService({Dio? dio})`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `validateAndFetchModels` | `Future<List<AnthropicModelInfo>> validateAndFetchModels(String apiKey)` | Sets `x-api-key` header, calls `GET /v1/models`, returns parsed models. Throws `ApiException` subtypes on failure. |
| `fetchModels` | `Future<List<AnthropicModelInfo>> fetchModels(String apiKey)` | Alias for `validateAndFetchModels`. |
| `testApiKey` | `Future<bool> testApiKey(String apiKey)` | Returns `true` if `GET /v1/models` returns 200. Never throws. |

**API Endpoints:** `GET https://api.anthropic.com/v1/models`

**Error Handling:** Maps `DioException` to typed `ApiException` subtypes (timeout, network, 400, 401, 403, 404, 429, 500+). Never logs API key values.

---

### 28. JobApi (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/cloud/job_api.dart`)

**Purpose:** API service for QA job lifecycle, agent runs, and bug investigations.

**Constructor:** `JobApi(ApiClient _client)`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `createJob` | `Future<QaJob> createJob({required String projectId, required JobMode mode, String? name, String? branch, String? configJson, String? jiraTicketKey})` | `POST /jobs` |
| `getJob` | `Future<QaJob> getJob(String jobId)` | `GET /jobs/{jobId}` |
| `updateJob` | `Future<QaJob> updateJob(String jobId, {JobStatus? status, String? summaryMd, JobResult? overallResult, int? healthScore, ...many optional params...})` | `PUT /jobs/{jobId}` |
| `deleteJob` | `Future<void> deleteJob(String jobId)` | `DELETE /jobs/{jobId}` |
| `getProjectJobs` | `Future<PageResponse<JobSummary>> getProjectJobs(String projectId, {int page = 0, int size = 20})` | `GET /jobs/project/{projectId}?page=&size=` |
| `getMyJobs` | `Future<List<JobSummary>> getMyJobs()` | `GET /jobs/mine` |
| `createAgentRun` | `Future<AgentRun> createAgentRun(String jobId, {required AgentType agentType})` | `POST /jobs/{jobId}/agents` |
| `createAgentRunsBatch` | `Future<List<AgentRun>> createAgentRunsBatch(String jobId, List<AgentType> agentTypes)` | `POST /jobs/{jobId}/agents/batch` |
| `getAgentRuns` | `Future<List<AgentRun>> getAgentRuns(String jobId)` | `GET /jobs/{jobId}/agents` |
| `updateAgentRun` | `Future<AgentRun> updateAgentRun(String agentRunId, {AgentStatus? status, AgentResult? result, ...many optional params...})` | `PUT /jobs/agents/{agentRunId}` |
| `createInvestigation` | `Future<BugInvestigation> createInvestigation(String jobId, {String? jiraKey, ...many optional params...})` | `POST /jobs/{jobId}/investigation` |
| `getInvestigation` | `Future<BugInvestigation> getInvestigation(String jobId)` | `GET /jobs/{jobId}/investigation` |
| `updateInvestigation` | `Future<BugInvestigation> updateInvestigation(String investigationId, {String? rcaMd, ...})` | `PUT /jobs/investigations/{investigationId}` |

---

## services/data/

### 29. SyncService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/data/sync_service.dart`)

**Purpose:** Synchronizes project data between the server and local Drift database. Handles offline fallback.

**Constructor:**
```dart
SyncService({
  required ProjectApi projectApi,
  required CodeOpsDatabase database,
})
```

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `syncProjects` | `Future<List<Project>> syncProjects(String teamId)` | Fetches all projects from server, upserts into local DB, removes stale records, updates `SyncMetadata`. Falls back to local cache on `NetworkException` or `TimeoutException`. |
| `syncProjectToCloud` | `Future<Project> syncProjectToCloud(Project project, String teamId)` | Pushes a local project to server via update. On `NotFoundException`, falls back to create. |

**API Endpoints:** Uses `ProjectApi.getTeamProjects`, `ProjectApi.updateProject`, `ProjectApi.createProject`.

**Error Handling:** Catches `NetworkException` and `TimeoutException` on sync, falls back to locally cached data. `syncProjectToCloud` catches `NotFoundException` and falls back to create.

**State Managed:** Local Drift `projects` and `syncMetadata` tables.

---

### 30. ScribePersistenceService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/data/scribe_persistence_service.dart`)

**Purpose:** Persists and restores Scribe editor session state (open tabs and settings) to the local Drift database.

**Constructor:** `ScribePersistenceService(CodeOpsDatabase database)`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `loadTabs` | `Future<List<ScribeTab>> loadTabs()` | Loads all persisted tabs ordered by `displayOrder`. |
| `saveTabs` | `Future<void> saveTabs(List<ScribeTab> tabs)` | Replaces all persisted tabs in a transaction (delete all, then insert). |
| `saveTab` | `Future<void> saveTab(ScribeTab tab, int displayOrder)` | Upserts a single tab by ID. |
| `removeTab` | `Future<void> removeTab(String tabId)` | Removes a single tab. |
| `clearTabs` | `Future<void> clearTabs()` | Deletes all persisted tabs. |
| `loadSettings` | `Future<ScribeSettings> loadSettings()` | Loads editor settings from JSON; returns defaults if none persisted. |
| `saveSettings` | `Future<void> saveSettings(ScribeSettings settings)` | Saves editor settings as JSON. |

**API Endpoints:** None (local database only).

**State Managed:** Local Drift `scribeTabs` and `scribeSettings` tables.

---

## services/integration/

### 31. ExportService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/integration/export_service.dart`)

**Purpose:** Exports job reports and findings in markdown, PDF, ZIP, and CSV formats with section selection and file save dialogs.

**Constructor:** `const ExportService()` -- No dependencies.

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `exportAsMarkdown` | `Future<String> exportAsMarkdown({required QaJob job, required List<AgentRun> agentRuns, required List<Finding> findings, required ExportSections sections, String? summaryMd})` | Generates a markdown report string with configurable sections. |
| `exportAsPdf` | `Future<List<int>> exportAsPdf({required QaJob job, required List<AgentRun> agentRuns, required List<Finding> findings, required ExportSections sections, String? summaryMd})` | Generates a PDF document as bytes using the `pdf` package. |
| `exportAsZip` | `Future<List<int>> exportAsZip({required QaJob job, required List<AgentRun> agentRuns, required List<Finding> findings, required ExportSections sections, String? summaryMd, Map<String, String>? agentReportContents})` | Generates a ZIP archive containing markdown, CSV, and individual agent reports. |
| `exportFindingsAsCsv` | `String exportFindingsAsCsv(List<Finding> findings)` | Generates a CSV string with headers: ID, Severity, Agent, Title, File, Line, Status, Description, Recommendation. Handles CSV escaping. |
| `saveFile` | `Future<String?> saveFile({required String suggestedName, required List<int> data, String? dialogTitle, List<String>? allowedExtensions})` | Opens a file save dialog via FilePicker and writes data to the chosen path. Returns path or `null` if cancelled. |

**API Endpoints:** None (local-only).

**Data Classes Defined Here:** `ExportSections`, `ExportFormat` (enum).

---

## services/jira/

### 32. JiraMapper (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/jira/jira_mapper.dart`)

**Purpose:** Converts between Jira Cloud API models and CodeOps internal models. Private constructor (`JiraMapper._()`) -- all methods are static.

**Public Methods (all static):**

| Method | Signature | Description |
|--------|-----------|-------------|
| `toInvestigationFields` | `static Map<String, dynamic> toInvestigationFields({required String jobId, required JiraIssue issue, required List<JiraComment> comments, String? additionalContext})` | Converts a Jira issue to fields matching `CreateBugInvestigationRequest`. JSON-encodes comments, attachments, and linked issues. |
| `taskToJiraIssue` | `static CreateJiraIssueRequest taskToJiraIssue({required RemediationTask task, required String projectKey, required String issueTypeName, ...})` | Converts a remediation task to a Jira issue creation request. |
| `tasksToJiraIssues` | `static List<CreateJiraIssueRequest> tasksToJiraIssues({required List<RemediationTask> tasks, required String projectKey, required String issueTypeName, ...})` | Bulk-converts tasks to Jira issue requests. |
| `toDisplayModel` | `static JiraIssueDisplayModel toDisplayModel(JiraIssue issue)` | Converts a full `JiraIssue` to a simplified `JiraIssueDisplayModel` for UI display. |
| `adfToMarkdown` | `static String adfToMarkdown(String? adfJson)` | Converts Atlassian Document Format JSON to markdown. Handles paragraph, heading, codeBlock, bulletList, orderedList, blockquote, and rule nodes. Falls back to raw text on parse failure. |
| `markdownToAdf` | `static String markdownToAdf(String markdown)` | Converts markdown to ADF JSON. Handles paragraphs, headings (h1-h3), and code blocks. |
| `mapStatusColor` | `static Color mapStatusColor(JiraStatusCategory? category)` | Maps Jira status category to a display color. |
| `mapStatusColorFromKey` | `static Color mapStatusColorFromKey(String? categoryKey)` | Maps a status category key string to a display color. |
| `mapPriority` | `static JiraPriorityDisplay mapPriority(String? priorityName)` | Maps Jira priority name to display properties (name, color, icon). |

**Data Classes Defined Here:** `JiraPriorityDisplay`.

---

### 33. JiraService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/jira/jira_service.dart`)

**Purpose:** Jira Cloud REST API client using Basic Auth (email:apiToken). Uses its own Dio instance.

**Constructor:** `JiraService({Dio? dio})`

**Public Methods:**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `configure` | `void configure({required String instanceUrl, required String email, required String apiToken})` | Configures Dio with Base64-encoded Basic Auth. Must be called before API methods. |
| `isConfigured` | `bool get isConfigured` | Whether credentials are set. |
| `testConnection` | `Future<bool> testConnection()` | `GET /rest/api/3/myself` -- Returns true if 200. |
| `searchIssues` | `Future<JiraSearchResult> searchIssues({required String jql, int startAt = 0, int maxResults = 50, List<String>? fields, List<String>? expand})` | `GET /rest/api/3/search/jql?jql=&startAt=&maxResults=` |
| `getIssue` | `Future<JiraIssue> getIssue(String issueKey, {List<String>? expand})` | `GET /rest/api/3/issue/{issueKey}` |
| `getComments` | `Future<List<JiraComment>> getComments(String issueKey, {int maxResults = 100})` | `GET /rest/api/3/issue/{issueKey}/comment` |
| `postComment` | `Future<JiraComment> postComment(String issueKey, String bodyMarkdown)` | `POST /rest/api/3/issue/{issueKey}/comment` (converts markdown to ADF) |
| `createIssue` | `Future<JiraIssue> createIssue(CreateJiraIssueRequest request)` | `POST /rest/api/3/issue` (then fetches full issue) |
| `createSubTask` | `Future<JiraIssue> createSubTask(CreateJiraSubTaskRequest request)` | `POST /rest/api/3/issue` with parent key |
| `createIssuesBulk` | `Future<List<JiraIssue>> createIssuesBulk(List<CreateJiraIssueRequest> requests)` | Sequential `POST /rest/api/3/issue` for each. Skips failures. |
| `updateIssue` | `Future<void> updateIssue(String issueKey, UpdateJiraIssueRequest request)` | `PUT /rest/api/3/issue/{issueKey}` |
| `getTransitions` | `Future<List<JiraTransition>> getTransitions(String issueKey)` | `GET /rest/api/3/issue/{issueKey}/transitions` |
| `transitionIssue` | `Future<void> transitionIssue(String issueKey, String transitionId)` | `POST /rest/api/3/issue/{issueKey}/transitions` |
| `getProjects` | `Future<List<JiraProject>> getProjects()` | `GET /rest/api/3/project` |
| `getSprints` | `Future<List<JiraSprint>> getSprints(int boardId, {String? state})` | `GET /rest/agile/1.0/board/{boardId}/sprint` |
| `getIssueTypes` | `Future<List<JiraIssueType>> getIssueTypes(String projectKey)` | `GET /rest/api/3/project/{projectKey}/statuses` |
| `searchUsers` | `Future<List<JiraUser>> searchUsers(String query, {int maxResults = 20})` | `GET /rest/api/3/user/search?query=&maxResults=` |
| `getPriorities` | `Future<List<JiraPriority>> getPriorities()` | `GET /rest/api/3/priority` |

**Error Handling:** Throws `StateError` if not configured. Handles 429 rate limiting with retry after delay. Rethrows all other `DioException`s.

**State Managed:** `_instanceUrl`, `_email`, `_apiToken`, `_dio` (reconfigured on `configure()`).

---

## services/logging/

### 34. LogLevel (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/logging/log_level.dart`)

**Purpose:** Enum defining log severity levels: `verbose`, `debug`, `info`, `warning`, `error`, `fatal`.

---

### 35. LogService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/logging/log_service.dart`)

**Purpose:** Singleton structured logging service. Provides six leveled methods with tagged, timestamped output to console and optional daily-rotated log files.

**Constructor:** `factory LogService()` returns singleton `_instance`.

**Top-level accessor:** `final LogService log = LogService();`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `v` | `void v(String tag, String message, [Object? error, StackTrace? stackTrace])` | Logs at VERBOSE level. |
| `d` | `void d(String tag, String message, [Object? error, StackTrace? stackTrace])` | Logs at DEBUG level. |
| `i` | `void i(String tag, String message, [Object? error, StackTrace? stackTrace])` | Logs at INFO level. |
| `w` | `void w(String tag, String message, [Object? error, StackTrace? stackTrace])` | Logs at WARNING level. |
| `e` | `void e(String tag, String message, [Object? error, StackTrace? stackTrace])` | Logs at ERROR level. |
| `f` | `void f(String tag, String message, [Object? error, StackTrace? stackTrace])` | Logs at FATAL level. |

**Behavior:** Checks `LogConfig.minimumLevel` and `LogConfig.mutedTags` before emitting. Console output uses ANSI colors in debug mode. File logging writes to `<logDirectory>/codeops-YYYY-MM-DD.log` with 7-day auto-purge.

**Error Handling:** File I/O failures are silently caught (never crash the app).

---

### 36. LogConfig (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/logging/log_config.dart`)

**Purpose:** Global logging configuration. Provides environment-aware defaults.

**Constructor:** `LogConfig._()` (private -- all members are static).

**Public Members:**

| Member | Type | Description |
|--------|------|-------------|
| `minimumLevel` | `static LogLevel` | Minimum severity to emit. Default: `debug`. |
| `enableFileLogging` | `static bool` | Whether to write to log files. Default: `false`. |
| `enableConsoleColors` | `static bool` | Whether to use ANSI colors. Default: `true`. |
| `mutedTags` | `static final Set<String>` | Tags that are silently suppressed. |
| `logDirectory` | `static String?` | Directory for log files. |
| `initialize` | `static Future<void> initialize()` | Sets environment-aware defaults: debug=console/no-file, release=info/file. Resolves log directory from `getApplicationSupportDirectory()` (or current directory in debug). |

---

## services/orchestration/

### 37. AgentMonitor (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/orchestration/agent_monitor.dart`)

**Purpose:** Monitors running agent processes, collecting stdout/stderr into buffers and racing exit codes against configurable timeouts.

**Constructor:** `AgentMonitor({required ProcessManager processManager})`

**Dependencies:** `ProcessManager`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `monitor` | `Future<AgentMonitorResult> monitor({required ManagedProcess process, required AgentType agentType, required Duration timeout, void Function(String)? onStdout, void Function(String)? onStderr})` | Monitors a single agent process to completion. Races exit code against timeout. On timeout, kills the process via ProcessManager. Returns `AgentMonitorResult` with status, output buffers, and elapsed time. |
| `monitorAll` | `Stream<AgentMonitorEvent> monitorAll({required Map<AgentType, ManagedProcess> processes, required Duration timeout})` | Monitors all agent processes concurrently. Emits `AgentProgressEvent`, `AgentCompletedEvent`, and `AgentFailedEvent` events. Stream closes after all processes resolve. |

**Data Classes/Enums Defined Here:** `AgentMonitorStatus` (enum), `AgentMonitorResult`, `AgentMonitorEvent` (sealed), `AgentProgressEvent`, `AgentCompletedEvent`, `AgentFailedEvent`.

---

### 38. ProgressAggregator (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/orchestration/progress_aggregator.dart`)

**Purpose:** Real-time progress aggregation for multi-agent QA jobs. Tracks phase, elapsed time, finding count, and latest output per agent. Emits `JobProgress` snapshots.

**Constructor:** `ProgressAggregator()` -- No dependencies.

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `progressStream` | `Stream<JobProgress> get progressStream` | Broadcast stream of `JobProgress` snapshots. |
| `currentProgress` | `JobProgress get currentProgress` | Current snapshot without waiting for stream. |
| `updateAgentStatus` | `void updateAgentStatus(AgentType agentType, AgentProgressStatus status)` | Updates a single agent's status and emits a new snapshot. |
| `reportLiveFinding` | `void reportLiveFinding(AgentType agentType, ParsedFinding finding)` | Records a live finding and emits a new snapshot. |
| `reset` | `void reset(List<AgentType> agents)` | Resets all state for a new job. Initializes all agents to `queued` phase. Restarts the elapsed stopwatch. |
| `dispose` | `void dispose()` | Stops the stopwatch and closes the stream controller. |

**State Managed:** `_agentStatuses` (Map), `_liveFindings` (List), `_stopwatch` (Stopwatch), `_totalCount` (int), `_controller` (StreamController).

**Data Classes Defined Here:** `AgentPhase` (enum), `AgentProgressStatus`, `LiveFinding`, `JobProgress`.

---

### 39. VeraManager (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/orchestration/vera_manager.dart`)

**Purpose:** Vera consolidation engine: deduplicates findings across agents, computes weighted health scores, determines overall result, and generates markdown executive summaries.

**Constructor:** `VeraManager()` -- No dependencies.

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `consolidate` | `Future<VeraReport> consolidate({required String jobId, required String projectName, required Map<AgentType, ParsedReport> agentReports, required JobMode mode})` | Full consolidation pipeline: collect all findings, deduplicate, count severities, compute weighted health score, determine overall result, generate executive summary. Returns `VeraReport`. |
| `calculateHealthScore` | `int calculateHealthScore(Map<AgentType, ParsedReport> reports)` | Computes weighted average of per-agent scores. Security/Architecture get 1.5x weight. Returns 100 for empty reports. |
| `deduplicateFindings` | `List<ParsedFinding> deduplicateFindings(List<ParsedFinding> allFindings)` | Removes duplicates based on same file path, line numbers within threshold, and title Levenshtein similarity >= threshold. Keeps higher-severity duplicate. Sorted by severity descending. |
| `determineOverallResult` | `JobResult determineOverallResult(List<ParsedFinding> findings)` | Returns `fail` if any critical, `warn` if any high, `pass` otherwise. |
| `generateExecutiveSummary` | `Future<String> generateExecutiveSummary({required String projectName, required JobMode mode, required int healthScore, required JobResult overallResult, required int totalFindings, ...})` | Generates a template-based markdown executive summary with severity breakdown table, per-agent scores table, and result interpretation. Does NOT invoke Claude. |

**Data Classes Defined Here:** `VeraReport`.

---

### 40. BugInvestigationOrchestrator (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/orchestration/bug_investigation_orchestrator.dart`)

**Purpose:** Orchestrates launching bug investigation jobs from Jira issues. Coordinates Jira data extraction, job orchestration, and investigation record creation.

**Constructor:**
```dart
BugInvestigationOrchestrator({
  required JobApi jobApi,
  required JobOrchestrator jobOrchestrator,
})
```

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `launchInvestigation` | `Future<String?> launchInvestigation({required Project project, required String branch, required String projectPath, required JiraIssue issue, required List<JiraComment> comments, required List<AgentType> selectedAgents, required AgentDispatchConfig config, String? additionalContext})` | Converts Jira ADF to markdown, builds ticket data string, fires `JobOrchestrator.executeJob` in `bugInvestigate` mode, waits up to 5s for `JobCreated` event, creates `BugInvestigation` record on server. Returns the job ID or `null` on timeout. |

**API Endpoints:** Calls `JobApi.createInvestigation` -> `POST /jobs/{jobId}/investigation`

**Error Handling:** Catches investigation record creation failures and logs warning (non-fatal). Returns `null` if `JobCreated` event not received within 5-second timeout.

---

### 41. AgentDispatcher (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/orchestration/agent_dispatcher.dart`)

**Purpose:** Dispatches Claude Code agent processes with concurrency control. Assembles prompts via PersonaManager, spawns `claude` CLI subprocesses, and limits parallelism using a semaphore pattern.

**Constructor:**
```dart
AgentDispatcher({
  required ProcessManager processManager,
  required PersonaManager personaManager,
  required ClaudeCodeDetector claudeCodeDetector,
})
```

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `activeProcesses` | `Map<AgentType, ManagedProcess> get activeProcesses` | Unmodifiable view of currently running agent processes. |
| `dispatchAgent` | `Future<ManagedProcess> dispatchAgent({required AgentType agentType, required String teamId, required String projectId, required String projectPath, required String branch, required JobMode mode, required String projectName, AgentDispatchConfig config = const AgentDispatchConfig(), ...})` | Assembles prompt, resolves `claude` executable path, spawns the process with `--print --output-format stream-json --max-turns --model -p`. Returns the `ManagedProcess`. |
| `dispatchAll` | `Stream<AgentDispatchEvent> dispatchAll({required List<AgentType> agentTypes, required String teamId, required String projectId, required String projectPath, required String branch, required JobMode mode, required String projectName, AgentDispatchConfig config = const AgentDispatchConfig(), ...})` | Dispatches multiple agents concurrently with semaphore-based throttling up to `maxConcurrent`. Emits `AgentQueued`, `AgentStarted`, `AgentOutput`, `AgentCompleted`, `AgentFailed`, and `AgentTimedOut` events. |
| `cancelAll` | `Future<void> cancelAll()` | Sets cancelled flag, kills all active processes via ProcessManager. |

**State Managed:** `_activeProcesses` (Map), `_cancelled` (bool).

**Data Classes Defined Here:** `AgentDispatchConfig`, sealed `AgentDispatchEvent` hierarchy (`AgentQueued`, `AgentStarted`, `AgentOutput`, `AgentCompleted`, `AgentFailed`, `AgentTimedOut`).

---

### 42. JobOrchestrator (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/orchestration/job_orchestrator.dart`)

**Purpose:** End-to-end job lifecycle orchestrator. Coordinates the full 10-step QA job lifecycle from server job creation through Vera consolidation, findings upload, and completion.

**Constructor:**
```dart
JobOrchestrator({
  required AgentDispatcher dispatcher,
  required AgentMonitor monitor,
  required VeraManager vera,
  required ProgressAggregator progress,
  required ReportParser parser,
  required JobApi jobApi,
  required FindingApi findingApi,
  required ReportApi reportApi,
  AgentProgressNotifier? agentProgressNotifier,
})
```

**Dependencies:** `AgentDispatcher`, `AgentMonitor`, `VeraManager`, `ProgressAggregator`, `ReportParser`, `JobApi`, `FindingApi`, `ReportApi`, `AgentProgressNotifier?`

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `activeJobId` | `String? get activeJobId` | UUID of the currently running job, or null. |
| `lifecycleStream` | `Stream<JobLifecycleEvent> get lifecycleStream` | Broadcast stream of lifecycle events. |
| `executeJob` | `Future<JobResult> executeJob({required String projectId, required String projectName, required String projectPath, required String teamId, required String branch, required JobMode mode, required List<AgentType> selectedAgents, required AgentDispatchConfig config, ...})` | Executes the 10-step lifecycle: (1) create job, (2) create agent runs, (3) set RUNNING, (4) dispatch agents, (5) parse/upload per-agent results, (6) Vera consolidation, (7) batch upload findings, (8) upload summary, (9) update job with final status/score/counts, (10) emit JobCompleted. Validates `projectPath` exists on disk. Returns `JobResult`. |
| `cancelJob` | `Future<void> cancelJob(String jobId)` | Cancels the active job: kills agents, updates server status to CANCELLED, resets progress, emits `JobCancelled`. |

**Static Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `extractResultFromStreamJson` | `static String extractResultFromStreamJson(String output)` | Scans NDJSON output backwards for a `result` event and extracts the result text. Falls back to raw output. |
| `toolDisplayName` | `static String toolDisplayName(String toolName)` | Maps Claude Code tool names (Read, Write, Bash, etc.) to human-readable activity descriptions. |

**API Endpoints Used:**
- `POST /jobs` (create job)
- `POST /jobs/{jobId}/agents/batch` (create agent runs)
- `PUT /jobs/{jobId}` (update status, results)
- `PUT /jobs/agents/{agentRunId}` (update agent run)
- `POST /findings/batch` (upload findings)
- `POST /reports/job/{jobId}/agent/{agentType}` (upload agent report)
- `POST /reports/job/{jobId}/summary` (upload summary)

**Error Handling:** Wraps entire flow in try/catch. On failure, updates job status to FAILED on server (best-effort), emits `JobFailed`, and rethrows. Validates project directory exists before starting. Cancellation checks at multiple points.

**State Managed:** `_activeJobId`, `_cancelling`, `_lifecycleController` (StreamController).

**Data Classes Defined Here:** Sealed `JobLifecycleEvent` hierarchy (`JobCreated`, `JobStarted`, `AgentPhaseStarted`, `AgentPhaseProgress`, `ConsolidationStarted`, `SyncStarted`, `JobCompleted`, `JobFailed`, `JobCancelled`).

---

## services/platform/

### 43. ProcessManager (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/platform/process_manager.dart`)

**Purpose:** Low-level subprocess lifecycle management. Spawns, tracks, and tears down subprocesses with optional timeouts.

**Constructor:** `ProcessManager()` -- No dependencies.

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `spawn` | `Future<ManagedProcess> spawn({required String executable, required List<String> arguments, required String workingDirectory, Duration? timeout, Map<String, String>? environment})` | Starts a new subprocess. Wires stdout/stderr line-by-line into broadcast controllers. Optional timeout auto-kills and completes exit code with -1. Returns `ManagedProcess`. |
| `kill` | `Future<void> kill(ManagedProcess process)` | Kills a single process and removes from active list. |
| `killAll` | `Future<void> killAll()` | Kills all active processes. |
| `activeProcesses` | `List<ManagedProcess> get activeProcesses` | Unmodifiable view of running processes. |
| `dispose` | `void dispose()` | Kills all processes and prevents future spawning. |

**Data Classes Defined Here:** `ManagedProcess` (with `pid`, `executable`, `startedAt`, `stdout` stream, `stderr` stream, `exitCode` future, `elapsed` duration, `isRunning` bool, `kill()`, `dispose()`).

**State Managed:** `_active` (List of ManagedProcess), `_disposed` (bool).

---

### 44. ClaudeCodeDetector (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/platform/claude_code_detector.dart`)

**Purpose:** Detects whether Claude Code CLI is installed, validates version, and reports availability. Cross-platform.

**Constructor:** `const ClaudeCodeDetector()` -- No dependencies.

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `isInstalled` | `Future<bool> isInstalled()` | Returns `true` if `claude` executable is found on PATH or at known locations. |
| `getVersion` | `Future<String?> getVersion()` | Runs `claude --version`, extracts semver token. Returns `null` if not installed or unparseable. |
| `getExecutablePath` | `Future<String?> getExecutablePath()` | Tries `which`/`where.exe`, then probes fallback paths (Homebrew, npm, nvm, etc.). Returns absolute path or `null`. |
| `validate` | `Future<ClaudeCodeStatus> validate()` | Full validation: checks installation and version >= `AppConstants.minClaudeCodeVersion`. Returns `available`, `notInstalled`, `versionTooOld`, or `error`. |

**Data Classes/Enums Defined Here:** `ClaudeCodeStatus` (enum: `available`, `notInstalled`, `versionTooOld`, `error`).

**Error Handling:** All methods catch all exceptions and return safe defaults (`false`, `null`, `error` status). Never throws.

---

## services/vcs/

### 45. VcsProvider (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/vcs/vcs_provider.dart`)

**Purpose:** Abstract interface for remote VCS operations (e.g., GitHub, GitLab).

**Abstract Methods:**

| Method | Signature |
|--------|-----------|
| `authenticate` | `Future<bool> authenticate(VcsCredentials credentials)` |
| `isAuthenticated` | `bool get isAuthenticated` |
| `getOrganizations` | `Future<List<VcsOrganization>> getOrganizations()` |
| `getRepositories` | `Future<List<VcsRepository>> getRepositories(String org, {int page = 1, int perPage = 30})` |
| `searchRepositories` | `Future<List<VcsRepository>> searchRepositories(String query)` |
| `getRepository` | `Future<VcsRepository> getRepository(String fullName)` |
| `getBranches` | `Future<List<VcsBranch>> getBranches(String fullName)` |
| `getPullRequests` | `Future<List<VcsPullRequest>> getPullRequests(String fullName, {String state = 'open'})` |
| `createPullRequest` | `Future<VcsPullRequest> createPullRequest(String fullName, CreatePRRequest request)` |
| `mergePullRequest` | `Future<bool> mergePullRequest(String fullName, int prNumber)` |
| `getCommitHistory` | `Future<List<VcsCommit>> getCommitHistory(String fullName, {String? sha, int perPage = 30})` |
| `getWorkflowRuns` | `Future<List<WorkflowRun>> getWorkflowRuns(String fullName, {int perPage = 10})` |
| `getReleases` | `Future<List<VcsTag>> getReleases(String fullName)` |

---

### 46. RepoManager (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/vcs/repo_manager.dart`)

**Purpose:** Manages cloned repositories on the local filesystem. Tracks repo locations in the Drift database.

**Constructor:**
```dart
RepoManager({
  required GitService gitService,
  required CodeOpsDatabase database,
})
```

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `getDefaultRepoDir` | `String getDefaultRepoDir()` | Returns `~/CodeOps/repos/`. |
| `getRepoPath` | `String getRepoPath(String fullName)` | Returns `~/CodeOps/repos/{fullName}`. |
| `registerRepo` | `Future<void> registerRepo({required String repoFullName, required String localPath, String? projectId})` | Upserts a repo record in the `clonedRepos` table. |
| `unregisterRepo` | `Future<void> unregisterRepo(String repoFullName)` | Removes a repo record. Does NOT delete files on disk. |
| `getAllRepos` | `Future<Map<String, String>> getAllRepos()` | Returns all registered repos as `fullName -> localPath`. |
| `isCloned` | `Future<bool> isCloned(String repoFullName)` | Checks if registered and directory exists on disk. |
| `getRepoStatus` | `Future<RepoStatus?> getRepoStatus(String repoFullName)` | Returns git working tree status for a registered repo. Updates `lastAccessedAt`. Returns `null` if not cloned. |
| `openInFileManager` | `Future<void> openInFileManager(String localPath)` | Opens directory in platform file manager (open/xdg-open/explorer). |
| `isValidGitRepo` | `Future<bool> isValidGitRepo(String path)` | Checks if path is a valid git repository by attempting `currentBranch`. |

**State Managed:** Local Drift `clonedRepos` table.

---

### 47. GitHubProvider (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/vcs/github_provider.dart`)

**Purpose:** GitHub REST API v3 implementation of `VcsProvider`. Uses its own Dio instance targeting `https://api.github.com`.

**Constructor:** `GitHubProvider({Dio? dio})`

**Public Methods (all implement `VcsProvider`):**

| Method | Signature | Endpoint |
|--------|-----------|----------|
| `authenticate` | `Future<bool> authenticate(VcsCredentials credentials)` | `GET /user` (sets Bearer token) |
| `getOrganizations` | `Future<List<VcsOrganization>> getOrganizations()` | `GET /user/orgs?per_page=100` + `GET /user` (adds user as pseudo-org) |
| `getRepositories` | `Future<List<VcsRepository>> getRepositories(String org, {int page = 1, int perPage = 30})` | `GET /user/repos` (own repos) or `GET /orgs/{org}/repos` |
| `searchRepositories` | `Future<List<VcsRepository>> searchRepositories(String query)` | `GET /search/repositories?q=&per_page=20` |
| `getRepository` | `Future<VcsRepository> getRepository(String fullName)` | `GET /repos/{fullName}` |
| `getBranches` | `Future<List<VcsBranch>> getBranches(String fullName)` | `GET /repos/{fullName}/branches?per_page=100` |
| `getPullRequests` | `Future<List<VcsPullRequest>> getPullRequests(String fullName, {String state = 'open'})` | `GET /repos/{fullName}/pulls?state=&per_page=30` |
| `createPullRequest` | `Future<VcsPullRequest> createPullRequest(String fullName, CreatePRRequest request)` | `POST /repos/{fullName}/pulls` |
| `mergePullRequest` | `Future<bool> mergePullRequest(String fullName, int prNumber)` | `PUT /repos/{fullName}/pulls/{prNumber}/merge` |
| `getCommitHistory` | `Future<List<VcsCommit>> getCommitHistory(String fullName, {String? sha, int perPage = 30})` | `GET /repos/{fullName}/commits?per_page=&sha=` |
| `getWorkflowRuns` | `Future<List<WorkflowRun>> getWorkflowRuns(String fullName, {int perPage = 10})` | `GET /repos/{fullName}/actions/runs?per_page=` |
| `getReleases` | `Future<List<VcsTag>> getReleases(String fullName)` | `GET /repos/{fullName}/releases?per_page=20` |
| `getReadmeContent` | `Future<String?> getReadmeContent(String fullName)` | `GET /repos/{fullName}/readme` (Accept: raw). Returns `null` on 404. |

**Error Handling:** Maps `DioException` to typed `ApiException` subtypes. Tracks `X-RateLimit-Remaining` and `X-RateLimit-Reset` headers, logs warnings when remaining < 100.

**State Managed:** `_authenticated` (bool), `rateLimitRemaining` (int?), `rateLimitReset` (int?).

---

### 48. GitService (`/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/vcs/git_service.dart`)

**Purpose:** Local `git` CLI wrapper. All operations use `dart:io` Process with `GIT_TERMINAL_PROMPT=0` to prevent interactive auth prompts.

**Constructor:** `GitService({ProcessRunner? runner})` -- Defaults to `SystemProcessRunner`.

**Dependencies:** `ProcessRunner` (abstraction over `Process.run`/`Process.start`).

**Public Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `getGitVersion` | `Future<String> getGitVersion()` | Runs `git --version`. |
| `clone` | `Future<void> clone(String url, String targetDir, {String? branch, void Function(CloneProgress)? onProgress})` | Clones with `--progress`. Streams stderr for progress callbacks. Redacts credentials in logs. Throws `GitException` on failure. |
| `pull` | `Future<String> pull(String repoDir)` | `git pull`. |
| `push` | `Future<String> push(String repoDir, {String? remote, String? branch})` | `git push [remote] [branch]`. |
| `fetchAll` | `Future<void> fetchAll(String repoDir)` | `git fetch --all`. |
| `checkout` | `Future<void> checkout(String repoDir, String ref)` | `git checkout {ref}`. |
| `createBranch` | `Future<void> createBranch(String repoDir, String name, {String? startPoint})` | `git checkout -b {name} [startPoint]`. |
| `status` | `Future<RepoStatus> status(String repoDir)` | `git status --porcelain=v2 --branch`. Parses branch, ahead/behind counts, and file changes (staged/unstaged/untracked). Returns `RepoStatus`. |
| `diff` | `Future<List<DiffResult>> diff(String repoDir, {String? path})` | `git diff [-- path]`. Parses unified diff into `DiffResult` objects with hunks and line-level additions/deletions/context. |
| `diffStat` | `Future<String> diffStat(String repoDir)` | `git diff --stat`. |
| `log` | `Future<List<VcsCommit>> log(String repoDir, {int maxCount = 30, String? branch})` | `git log --format=JSON -n {maxCount}`. Parses commits with sha, message, author, date. |
| `commit` | `Future<String> commit(String repoDir, String message, {List<String>? files, bool all = false})` | `git add` + `git commit -m`. Supports staging specific files or `--all`. |
| `merge` | `Future<String> merge(String repoDir, String branch)` | `git merge {branch}`. |
| `blame` | `Future<String> blame(String repoDir, String filePath)` | `git blame {filePath}`. |
| `stashList` | `Future<List<VcsStash>> stashList(String repoDir)` | `git stash list`. |
| `stashPush` | `Future<void> stashPush(String repoDir, {String? message})` | `git stash push [-m message]`. |
| `stashPop` | `Future<void> stashPop(String repoDir, {int? index})` | `git stash pop [stash@{index}]`. |
| `stashDrop` | `Future<void> stashDrop(String repoDir, int index)` | `git stash drop stash@{index}`. |
| `createTag` | `Future<void> createTag(String repoDir, String name, {String? message})` | `git tag [-a name -m message]`. |
| `listTags` | `Future<List<String>> listTags(String repoDir)` | `git tag -l`. |
| `currentBranch` | `Future<String> currentBranch(String repoDir)` | `git rev-parse --abbrev-ref HEAD`. |
| `remoteUrl` | `Future<String> remoteUrl(String repoDir, {String remote = 'origin'})` | `git remote get-url {remote}`. |

**Error Handling:** All commands throw `GitException` on non-zero exit code with the git command, stderr message, and exit code.

**Data Classes Defined Here:** `ProcessRunner` (abstract), `SystemProcessRunner`, `GitException`.

---

**Total files audited: 46 files across 11 subdirectories.** Every public method, constructor parameter, API endpoint, error handling approach, and managed state has been documented from the actual source code on disk.


---

## 10. Provider Layer

Now I have read every single `.dart` file in the providers directory. Here is the complete structured audit of all providers.

---

# CodeOps-Client Provider Audit

**Directory:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/`
**Total files:** 24
**Date:** 2026-02-18

---

## 1. `admin_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/admin_providers.dart`

| Provider Name | Type | State Managed | Dependencies (ref.watch / ref.read) | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `adminApiProvider` | `Provider<AdminApi>` | AdminApi service singleton | `apiClientProvider` | None -- pass-through | N/A |
| `adminTabIndexProvider` | `StateProvider<int>` | Currently selected admin tab index (default 0) | None | None | N/A |
| `adminUserSearchProvider` | `StateProvider<String>` | Search query for admin user list (default `''`) | None | None | N/A |
| `adminUserPageProvider` | `StateProvider<int>` | Current page for admin user list (default 0) | None | None | N/A |
| `auditLogPageProvider` | `StateProvider<int>` | Current page for audit log (default 0) | None | None | N/A |
| `auditLogActionFilterProvider` | `StateProvider<String?>` | Action filter for audit log (default null) | None | None | N/A |
| `adminUsersProvider` | `FutureProvider<PageResponse<User>>` | Paginated admin user list | `adminApiProvider`, `adminUserPageProvider` | Passes page and default page size to API | N/A |
| `adminUserDetailProvider` | `FutureProvider.family<User, String>` | Single user detail by userId | `adminApiProvider` | None -- pass-through | N/A |
| `systemSettingsProvider` | `FutureProvider<List<SystemSetting>>` | All system settings | `adminApiProvider` | None -- pass-through | N/A |
| `usageStatsProvider` | `FutureProvider<Map<String, dynamic>>` | Team usage statistics | `adminApiProvider` | None -- pass-through | N/A |
| `teamAuditLogProvider` | `FutureProvider<PageResponse<AuditLogEntry>>` | Paginated team audit log | `adminApiProvider`, `selectedTeamIdProvider`, `auditLogPageProvider` | Returns empty page if no team selected | N/A |
| `userAuditLogProvider` | `FutureProvider.family<PageResponse<AuditLogEntry>, String>` | Paginated audit log for a specific user | `adminApiProvider`, `auditLogPageProvider` | None -- pass-through with page | N/A |

---

## 2. `auth_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/auth_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `secureStorageProvider` | `Provider<SecureStorageService>` | Singleton secure storage service | None | None -- instantiation | N/A |
| `apiClientProvider` | `Provider<ApiClient>` | Singleton API client configured with secure storage | `secureStorageProvider` | None -- pass-through | N/A |
| `databaseProvider` | `Provider<CodeOpsDatabase>` | Local Drift database singleton | None | None -- `CodeOpsDatabase.defaults()` | N/A |
| `authServiceProvider` | `Provider<AuthService>` | Singleton auth service | `apiClientProvider`, `secureStorageProvider`, `databaseProvider` | None -- DI wiring | N/A |
| `authStateProvider` | `StreamProvider<AuthState>` | Current authentication state stream | `authServiceProvider` | None -- subscribes to `authService.authStateStream` | N/A |
| `currentUserProvider` | `StateProvider<User?>` | Currently authenticated user object (default null) | None | None | N/A |

---

## 3. `dependency_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/dependency_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `dependencyApiProvider` | `Provider<DependencyApi>` | DependencyApi singleton | `apiClientProvider` | None | N/A |
| `projectScansProvider` | `FutureProvider.family<PageResponse<DependencyScan>, String>` | Paginated scans for a project | `dependencyApiProvider` | None -- pass-through | N/A |
| `latestScanProvider` | `FutureProvider.family<DependencyScan, String>` | Latest scan for a project | `dependencyApiProvider` | None -- pass-through | N/A |
| `scanVulnerabilitiesProvider` | `FutureProvider.family<PageResponse<DependencyVulnerability>, String>` | Paginated vulnerabilities for a scan | `dependencyApiProvider` | None -- pass-through | N/A |
| `vulnsBySeverityProvider` | `FutureProvider.family<..., ({String scanId, Severity severity})>` | Vulnerabilities filtered by severity (server-side) | `dependencyApiProvider` | None -- pass-through | N/A |
| `openVulnerabilitiesProvider` | `FutureProvider.family<..., String>` | Open (unresolved) vulnerabilities for a scan | `dependencyApiProvider` | None -- pass-through | N/A |
| `selectedScanProvider` | `StateProvider<DependencyScan?>` | Currently selected scan (default null) | None | None | N/A |
| `selectedVulnerabilityProvider` | `StateProvider<DependencyVulnerability?>` | Currently selected vulnerability (default null) | None | None | N/A |
| `vulnSearchQueryProvider` | `StateProvider<String>` | Search query for vulnerability filtering (default `''`) | None | None | N/A |
| `vulnSeverityFilterProvider` | `StateProvider<Severity?>` | Severity filter for vulns (default null) | None | None | N/A |
| `vulnStatusFilterProvider` | `StateProvider<VulnerabilityStatus?>` | Status filter for vulns (default null) | None | None | N/A |
| `filteredVulnerabilitiesProvider` | `Provider.family<AsyncValue<List<DependencyVulnerability>>, String>` | Filtered vulnerability list combining all filters | `scanVulnerabilitiesProvider`, `vulnSearchQueryProvider`, `vulnSeverityFilterProvider`, `vulnStatusFilterProvider` | **Yes**: Client-side filtering by dependency name/CVE search, severity, and status | N/A |
| `depHealthScoreProvider` | `Provider.family<AsyncValue<int>, String>` | Dependency health score (0-100) per project | `latestScanProvider`, `scanVulnerabilitiesProvider` | **Yes**: Score = 100 - (critical x 25 + high x 10 + medium x 3 + low x 1) via `DependencyScanner.computeDepHealthScore` | N/A |

---

## 4. `directive_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/directive_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `directiveApiProvider` | `Provider<DirectiveApi>` | DirectiveApi singleton | `apiClientProvider` | None | N/A |
| `teamDirectivesProvider` | `FutureProvider<List<Directive>>` | All directives for selected team | `selectedTeamIdProvider`, `directiveApiProvider` | Returns `[]` if no team selected | N/A |
| `projectDirectivesProvider` | `FutureProvider.family<List<ProjectDirective>, String>` | Directive assignments for a project | `directiveApiProvider` | None -- pass-through | N/A |
| `enabledDirectivesProvider` | `FutureProvider.family<List<Directive>, String>` | Enabled directives for a project | `directiveApiProvider` | None -- pass-through | N/A |
| `selectedDirectiveProvider` | `StateProvider<Directive?>` | Currently selected directive (default null) | None | None | N/A |
| `directiveSearchQueryProvider` | `StateProvider<String>` | Search query for directives (default `''`) | None | None | N/A |
| `directiveCategoryFilterProvider` | `StateProvider<DirectiveCategory?>` | Category filter (default null) | None | None | N/A |
| `directiveScopeFilterProvider` | `StateProvider<DirectiveScope?>` | Scope filter (default null) | None | None | N/A |
| `filteredDirectivesProvider` | `Provider<AsyncValue<List<Directive>>>` | Filtered + sorted directive list | `teamDirectivesProvider`, `directiveSearchQueryProvider`, `directiveCategoryFilterProvider`, `directiveScopeFilterProvider` | **Yes**: Client-side filtering by category, scope, and search query (name/description/category display name). Sorted alphabetically by name. Implemented in `_applyDirectiveFilters()`. | N/A |

---

## 5. `finding_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/finding_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `findingApiProvider` | `Provider<FindingApi>` | FindingApi singleton | `apiClientProvider` | None | N/A |
| `jobFindingsProvider` | `FutureProvider.family<PageResponse<Finding>, ({String jobId, int page})>` | Paginated findings for a job | `findingApiProvider` | None -- pass-through | N/A |
| `findingSeverityFilterProvider` | `StateProvider<Severity?>` | Severity filter (default null) | None | None | N/A |
| `findingStatusFilterProvider` | `StateProvider<FindingStatus?>` | Status filter (default null) | None | None | N/A |
| `findingAgentFilterProvider` | `StateProvider<AgentType?>` | Agent type filter (default null) | None | None | N/A |
| `findingSeverityCountsProvider` | `FutureProvider.family<Map<String, dynamic>, String>` | Severity count breakdown by job | `findingApiProvider` | None -- pass-through | N/A |
| `findingsBySeverityProvider` | `FutureProvider.family<List<Finding>, ({String jobId, Severity severity})>` | Findings filtered server-side by severity | `findingApiProvider` | None -- pass-through | N/A |
| `findingsByAgentProvider` | `FutureProvider.family<List<Finding>, ({String jobId, AgentType agentType})>` | Findings filtered server-side by agent type | `findingApiProvider` | None -- pass-through | N/A |
| `findingsByStatusProvider` | `FutureProvider.family<List<Finding>, ({String jobId, FindingStatus status})>` | Findings filtered server-side by status | `findingApiProvider` | None -- pass-through | N/A |
| `findingProvider` | `FutureProvider.family<Finding, String>` | Single finding by ID | `findingApiProvider` | None -- pass-through | N/A |
| `findingFiltersProvider` | `StateProvider<FindingFilters>` | Composite filter state (severity, status, agentType, searchQuery, sort) | None | None -- state holder | N/A |
| `selectedFindingIdsProvider` | `StateProvider<Set<String>>` | Set of selected finding IDs for bulk operations | None | None | N/A |
| `activeFindingProvider` | `StateProvider<Finding?>` | Currently active finding for detail panel | None | None | N/A |

**Also defines class:** `FindingFilters` -- immutable filter value object with `copyWith`, `hasActiveFilters` getter.

---

## 6. `health_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/health_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `metricsApiProvider` | `Provider<MetricsApi>` | MetricsApi singleton | `apiClientProvider` | None | N/A |
| `teamMetricsProvider` | `FutureProvider<TeamMetrics?>` | Aggregated team-level metrics | `selectedTeamIdProvider`, `metricsApiProvider` | Returns null if no team selected | N/A |
| `projectMetricsProvider` | `FutureProvider.family<ProjectMetrics?, String>` | Project-level metrics | `metricsApiProvider` | None -- pass-through | N/A |
| `healthHistoryProvider` | `FutureProvider.family<List<HealthSnapshot>, String>` | Health snapshot history for a project | `healthMonitorApiProvider` | None -- pass-through | N/A |
| `healthSchedulesProvider` | `FutureProvider.family<List<HealthSchedule>, String>` | Health schedules for a project | `healthMonitorApiProvider` | None -- pass-through | N/A |
| `healthMonitorApiProvider` | `Provider<HealthMonitorApi>` | HealthMonitorApi singleton | `apiClientProvider` | None | N/A |
| `selectedHealthProjectProvider` | `StateProvider<String?>` | Selected project on health dashboard (default null) | None | None | N/A |
| `healthTrendRangeProvider` | `StateProvider<int>` | Time range in days for trend charts (default 30) | None | None | N/A |
| `latestSnapshotProvider` | `FutureProvider.family<HealthSnapshot?, String>` | Latest health snapshot for a project | `healthMonitorApiProvider` | None -- pass-through | N/A |
| `healthScoreDeltaProvider` | `Provider.family<int?, String>` | Health score delta (current - previous) | `projectMetricsProvider` | **Yes**: Computes `currentHealthScore - previousHealthScore` from project metrics. Returns null if unavailable. | N/A |
| `healthTrendProvider` | `FutureProvider.family<List<HealthSnapshot>, String>` | Health trend data respecting trend range | `healthTrendRangeProvider`, `metricsApiProvider` | Passes `days` from healthTrendRangeProvider to API | N/A |

---

## 7. `jira_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/jira_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `jiraConnectionsProvider` | `FutureProvider<List<JiraConnection>>` | Jira connections for selected team | `selectedTeamIdProvider`, `integrationApiProvider` | Returns `[]` if no team | N/A |
| `activeJiraConnectionProvider` | `StateProvider<JiraConnection?>` | Currently active Jira connection (default null) | None | None | N/A |
| `jiraServiceProvider` | `FutureProvider<JiraService?>` | Configured JiraService instance | `activeJiraConnectionProvider`, `secureStorageProvider` | **Yes**: Reads API token from secure storage by connection ID, configures the JiraService with instanceUrl/email/apiToken. Returns null if no connection or missing token. | N/A |
| `isJiraConfiguredProvider` | `Provider<bool>` | Whether Jira is usable | `jiraServiceProvider` | **Yes**: Checks if `serviceAsync.valueOrNull != null` | N/A |
| `jiraSearchQueryProvider` | `StateProvider<String>` | JQL search query (default `''`) | None | None | N/A |
| `jiraSearchStartAtProvider` | `StateProvider<int>` | Search page offset (default 0) | None | None | N/A |
| `jiraSearchResultsProvider` | `FutureProvider.autoDispose<JiraSearchResult?>` | Paginated Jira search results | `jiraSearchQueryProvider`, `jiraServiceProvider`, `jiraSearchStartAtProvider` | Returns null if JQL is empty or service unavailable | N/A |
| `jiraIssueProvider` | `FutureProvider.autoDispose.family<JiraIssue?, String>` | Single Jira issue by key | `jiraServiceProvider` | Returns null if service unavailable | N/A |
| `jiraCommentsProvider` | `FutureProvider.autoDispose.family<List<JiraComment>, String>` | Comments for a Jira issue | `jiraServiceProvider` | Returns `[]` if service unavailable | N/A |
| `selectedJiraIssueKeyProvider` | `StateProvider<String?>` | Selected issue key in browser (default null) | None | None | N/A |
| `jiraProjectsProvider` | `FutureProvider.autoDispose<List<JiraProject>>` | Jira projects for authenticated user | `jiraServiceProvider` | Returns `[]` if service unavailable | N/A |
| `jiraIssueTypesProvider` | `FutureProvider.autoDispose.family<List<JiraIssueType>, String>` | Issue types for a Jira project | `jiraServiceProvider` | Returns `[]` if service unavailable | N/A |
| `jiraUserSearchProvider` | `FutureProvider.autoDispose.family<List<JiraUser>, String>` | Jira user search results | `jiraServiceProvider` | Returns `[]` if service unavailable or query empty | N/A |
| `jiraPrioritiesProvider` | `FutureProvider.autoDispose<List<JiraPriority>>` | Jira priorities | `jiraServiceProvider` | Returns `[]` if service unavailable | N/A |
| `jiraSprintsProvider` | `FutureProvider.autoDispose.family<List<JiraSprint>, int>` | Sprints for a Jira board | `jiraServiceProvider` | Returns `[]` if service unavailable | N/A |
| `jiraTransitionsProvider` | `FutureProvider.autoDispose.family<List<JiraTransition>, String>` | Transitions for a Jira issue | `jiraServiceProvider` | Returns `[]` if service unavailable | N/A |

**Also defines helper functions:** `saveJiraApiToken()`, `deleteJiraApiToken()` -- write/delete secure storage entries for Jira tokens. And `jiraTokenKey()` for building storage keys.

---

## 8. `job_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/job_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `jobApiProvider` | `Provider<JobApi>` | JobApi singleton | `apiClientProvider` | None | N/A |
| `findingApiProvider` | `Provider<FindingApi>` | FindingApi singleton (note: duplicate name with finding_providers.dart) | `apiClientProvider` | None | N/A |
| `reportApiProvider` | `Provider<ReportApi>` | ReportApi singleton | `apiClientProvider` | None | N/A |
| `projectJobsProvider` | `FutureProvider.family<PageResponse<JobSummary>, ({String projectId, int page})>` | Paginated job history for a project | `jobApiProvider` | None -- pass-through | N/A |
| `myJobsProvider` | `FutureProvider<List<JobSummary>>` | Recent jobs for current user | `jobApiProvider` | None -- pass-through | N/A |
| `jobDetailProvider` | `FutureProvider.family<QaJob, String>` | Single job detail by ID | `jobApiProvider` | None -- pass-through | N/A |
| `activeJobIdProvider` | `StateProvider<String?>` | Currently viewed job ID (default null) | None | None | N/A |
| `agentRunsByJobProvider` | `FutureProvider.autoDispose.family<List<AgentRun>, String>` | Agent runs for a job | `jobApiProvider` | None -- pass-through | N/A |
| `jobFindingsProvider` | `FutureProvider.autoDispose.family<PageResponse<Finding>, ({String jobId, int page})>` | Paginated findings for a job (note: duplicate name with finding_providers.dart) | `findingApiProvider` | None -- pass-through | N/A |
| `jobSeverityCountsProvider` | `FutureProvider.autoDispose.family<Map<String, dynamic>, String>` | Finding severity counts for a job | `findingApiProvider` | None -- pass-through | N/A |

---

## 9. `persona_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/persona_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `personaApiProvider` | `Provider<PersonaApi>` | PersonaApi singleton | `apiClientProvider` | None | N/A |
| `teamPersonasProvider` | `FutureProvider<List<Persona>>` | All personas for selected team | `selectedTeamIdProvider`, `personaApiProvider` | Returns `[]` if no team | N/A |
| `systemPersonasProvider` | `FutureProvider<List<Persona>>` | System-level built-in personas | `personaApiProvider` | None -- pass-through | N/A |
| `myPersonasProvider` | `FutureProvider<List<Persona>>` | Personas created by current user | `personaApiProvider` | None -- pass-through | N/A |
| `personasByAgentTypeProvider` | `FutureProvider.family<List<Persona>, ({String teamId, AgentType agentType})>` | Team personas filtered by agent type | `personaApiProvider` | None -- pass-through | N/A |
| `defaultPersonaProvider` | `FutureProvider.family<Persona?, ({String teamId, AgentType agentType})>` | Default persona for a team+agentType | `personaApiProvider` | **Yes**: Catches exceptions and returns null instead | N/A |
| `selectedPersonaProvider` | `StateProvider<Persona?>` | Currently selected persona (default null) | None | None | N/A |
| `personaSearchQueryProvider` | `StateProvider<String>` | Search query for personas (default `''`) | None | None | N/A |
| `personaScopeFilterProvider` | `StateProvider<Scope?>` | Scope filter (default null) | None | None | N/A |
| `personaAgentTypeFilterProvider` | `StateProvider<AgentType?>` | Agent type filter (default null) | None | None | N/A |
| `filteredPersonasProvider` | `Provider<AsyncValue<List<Persona>>>` | Filtered + sorted combined persona list | `systemPersonasProvider`, `teamPersonasProvider`, `personaSearchQueryProvider`, `personaScopeFilterProvider`, `personaAgentTypeFilterProvider` | **Yes**: Combines system + team personas, deduplicates by ID, filters by scope/agentType/search query (name/description/agentType display name), sorts by scope index then name alphabetically. Implemented in `_applyPersonaFilters()`. | N/A |

---

## 10. `project_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/project_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `projectApiProvider` | `Provider<ProjectApi>` | ProjectApi singleton | `apiClientProvider` | None | N/A |
| `syncServiceProvider` | `Provider<SyncService>` | SyncService singleton | `projectApiProvider`, `databaseProvider` | None -- DI wiring | N/A |
| `selectedProjectIdProvider` | `StateProvider<String?>` | Selected project ID (default null) | None | None | N/A |
| `projectSyncStateProvider` | `StateProvider<SyncState>` | Current sync state (default `SyncState.idle`) | None | None | N/A |
| `projectSearchQueryProvider` | `StateProvider<String>` | Search query for projects (default `''`) | None | None | N/A |
| `projectSortProvider` | `StateProvider<ProjectSortOrder>` | Sort order (default `nameAsc`) | None | None | N/A |
| `showArchivedProvider` | `StateProvider<bool>` | Whether to show archived projects (default false) | None | None | N/A |
| `favoriteProjectIdsProvider` | `StateNotifierProvider<FavoriteProjectsNotifier, Set<String>>` | Set of favorited project IDs | None | **Yes**: Toggle favorites in/out of set | `toggle(projectId)`, `isFavorite(projectId)` |
| `teamProjectsProvider` | `FutureProvider<List<Project>>` | All projects for selected team (including archived) | `selectedTeamIdProvider`, `projectApiProvider` | Returns `[]` if no team | N/A |
| `selectedProjectProvider` | `FutureProvider<Project?>` | Currently selected project detail | `selectedProjectIdProvider`, `projectApiProvider` | Returns null if no project selected | N/A |
| `projectProvider` | `FutureProvider.family<Project, String>` | Single project by ID | `projectApiProvider` | None -- pass-through | N/A |
| `projectRecentJobsProvider` | `FutureProvider.family<PageResponse<JobSummary>, String>` | Recent jobs (first page, 10 items) for a project | `jobApiProvider` | Hardcoded page=0, size=10 | N/A |
| `projectHealthTrendProvider` | `FutureProvider.family<List<HealthSnapshot>, String>` | Health trend data for a project | `metricsApiProvider` | None -- pass-through | N/A |
| `filteredProjectsProvider` | `Provider<AsyncValue<List<Project>>>` | Filtered and sorted project list | `teamProjectsProvider`, `projectSearchQueryProvider`, `projectSortProvider`, `showArchivedProvider`, `favoriteProjectIdsProvider` | **Yes**: Filters by archived flag, search query (name/repoFullName/techStack), sorts with favorites first then by chosen sort order (nameAsc, healthScoreAsc/Desc, lastAuditDesc) | N/A |
| `jiraConnectionsProvider` | `FutureProvider<List<JiraConnection>>` | Jira connections for selected team (for dialogs) | `selectedTeamIdProvider`, `integrationApiProvider` | Returns `[]` if no team | N/A |

**Also defines enum:** `ProjectSortOrder` (nameAsc, healthScoreAsc, healthScoreDesc, lastAuditDesc).

**Also defines class:** `FavoriteProjectsNotifier` (StateNotifier) with `toggle()` and `isFavorite()` methods.

---

## 11. `report_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/report_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `agentReportMarkdownProvider` | `FutureProvider.family<String, String>` | Agent report markdown content by S3 key | `reportApiProvider` | None -- pass-through (downloads from S3) | N/A |
| `projectTrendProvider` | `FutureProvider.family<List<HealthSnapshot>, ({String projectId, int days})>` | Project health trend data with configurable days | `metricsApiProvider` | None -- pass-through | N/A |

---

## 12. `settings_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/settings_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `claudeModelProvider` | `StateProvider<String>` | Selected Claude model (default from AppConstants) | None | None | N/A |
| `maxConcurrentAgentsProvider` | `StateProvider<int>` | Max concurrent agents (default from AppConstants) | None | None | N/A |
| `agentTimeoutMinutesProvider` | `StateProvider<int>` | Agent timeout in minutes (default from AppConstants) | None | None | N/A |
| `offlineModeProvider` | `StateProvider<bool>` | Offline mode flag (default false) | None | None | N/A |
| `connectivityProvider` | `StateProvider<bool>` | Connectivity status (default true) | None | None | N/A |
| `sidebarCollapsedProvider` | `StateProvider<bool>` | Whether sidebar is collapsed (default false) | None | None | N/A |
| `settingsSectionProvider` | `StateProvider<int>` | Currently selected settings section index (default 0) | None | None | N/A |
| `fontDensityProvider` | `StateProvider<int>` | Font density: 0=compact, 1=normal, 2=comfortable (default 1) | None | None | N/A |
| `compactModeProvider` | `StateProvider<bool>` | Compact mode enabled (default false) | None | None | N/A |
| `autoUpdateProvider` | `StateProvider<bool>` | Automatic updates enabled (default true) | None | None | N/A |
| `claudeCodePathProvider` | `StateProvider<String>` | File path to Claude Code CLI binary (default `''`) | None | None | N/A |

---

## 13. `task_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/task_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `integrationApiProvider` | `Provider<IntegrationApi>` | IntegrationApi singleton | `apiClientProvider` | None | N/A |
| `taskApiProvider` | `Provider<TaskApi>` | TaskApi singleton | `apiClientProvider` | None | N/A |
| `jobTasksProvider` | `FutureProvider.family<List<RemediationTask>, String>` | Remediation tasks for a job | `taskApiProvider` | None -- pass-through | N/A |
| `myTasksProvider` | `FutureProvider<List<RemediationTask>>` | Tasks assigned to current user | `taskApiProvider` | None -- pass-through | N/A |
| `taskProvider` | `FutureProvider.family<RemediationTask, String>` | Single task by ID | `taskApiProvider` | None -- pass-through | N/A |
| `taskFilterProvider` | `StateProvider<TaskFilter>` | Filter state (status, priority, searchQuery) | None | None | N/A |
| `taskSortProvider` | `StateProvider<TaskSort>` | Sort state (default `priorityDesc`) | None | None | N/A |
| `selectedTaskIdsProvider` | `StateProvider<Set<String>>` | Multi-selected task IDs for bulk ops | None | None | N/A |
| `selectedTaskProvider` | `StateProvider<RemediationTask?>` | Active task for detail panel (default null) | None | None | N/A |
| `filteredJobTasksProvider` | `Provider.family<AsyncValue<List<RemediationTask>>, String>` | Filtered + sorted job tasks | `jobTasksProvider`, `taskFilterProvider`, `taskSortProvider` | **Yes**: Client-side filter by status/priority/searchQuery (title) and sort by priority rank, task number, or created date. Implemented in `_applyFilter()` and `_applySort()`. | N/A |
| `filteredMyTasksProvider` | `Provider<AsyncValue<List<RemediationTask>>>` | Filtered + sorted "my tasks" | `myTasksProvider`, `taskFilterProvider`, `taskSortProvider` | **Yes**: Same filter/sort logic as `filteredJobTasksProvider` | N/A |

**Also defines classes:** `TaskFilter` (immutable value object with `copyWith`, `hasActiveFilters`), **enum** `TaskSort` (priorityDesc, taskNumberAsc, createdAtDesc).

**Also defines helper functions:** `_applyFilter()`, `_applySort()`, `_priorityRank()` (P0=0, P1=1, P2=2, P3=3, null=4).

---

## 14. `team_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/team_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `teamApiProvider` | `Provider<TeamApi>` | TeamApi singleton | `apiClientProvider` | None | N/A |
| `teamsProvider` | `FutureProvider<List<Team>>` | All teams for the current user | `teamApiProvider` | None -- pass-through | N/A |
| `selectedTeamIdProvider` | `StateProvider<String?>` | Currently selected team ID (default null) | None | None | N/A |
| `selectedTeamProvider` | `FutureProvider<Team?>` | Currently selected team detail | `selectedTeamIdProvider`, `teamApiProvider` | Returns null if no team selected | N/A |
| `teamMembersProvider` | `FutureProvider<List<TeamMember>>` | Members of selected team | `selectedTeamIdProvider`, `teamApiProvider` | Returns `[]` if no team | N/A |
| `teamInvitationsProvider` | `FutureProvider<List<Invitation>>` | Pending invitations for selected team | `selectedTeamIdProvider`, `teamApiProvider` | Returns `[]` if no team | N/A |

---

## 15. `tech_debt_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/tech_debt_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `techDebtApiProvider` | `Provider<TechDebtApi>` | TechDebtApi singleton | `apiClientProvider` | None | N/A |
| `projectTechDebtProvider` | `FutureProvider.family<PageResponse<TechDebtItem>, String>` | Paginated tech debt items for a project | `techDebtApiProvider` | None -- pass-through | N/A |
| `techDebtItemProvider` | `FutureProvider.family<TechDebtItem, String>` | Single tech debt item by ID | `techDebtApiProvider` | None -- pass-through | N/A |
| `techDebtByStatusProvider` | `FutureProvider.family<..., ({String projectId, DebtStatus status})>` | Tech debt items filtered by status (server-side) | `techDebtApiProvider` | None -- pass-through | N/A |
| `techDebtByCategoryProvider` | `FutureProvider.family<..., ({String projectId, DebtCategory category})>` | Tech debt items filtered by category (server-side) | `techDebtApiProvider` | None -- pass-through | N/A |
| `debtSummaryProvider` | `FutureProvider.family<Map<String, dynamic>, String>` | Debt summary map for a project | `techDebtApiProvider` | None -- pass-through | N/A |
| `selectedTechDebtItemProvider` | `StateProvider<TechDebtItem?>` | Selected debt item for detail panel (default null) | None | None | N/A |
| `techDebtSearchQueryProvider` | `StateProvider<String>` | Search query (default `''`) | None | None | N/A |
| `techDebtStatusFilterProvider` | `StateProvider<DebtStatus?>` | Status filter (default null) | None | None | N/A |
| `techDebtCategoryFilterProvider` | `StateProvider<DebtCategory?>` | Category filter (default null) | None | None | N/A |
| `techDebtEffortFilterProvider` | `StateProvider<Effort?>` | Effort filter (default null) | None | None | N/A |
| `techDebtImpactFilterProvider` | `StateProvider<BusinessImpact?>` | Business impact filter (default null) | None | None | N/A |
| `filteredTechDebtProvider` | `Provider.family<AsyncValue<List<TechDebtItem>>, String>` | Filtered tech debt list combining all filters | `projectTechDebtProvider`, `techDebtSearchQueryProvider`, `techDebtStatusFilterProvider`, `techDebtCategoryFilterProvider`, `techDebtEffortFilterProvider`, `techDebtImpactFilterProvider` | **Yes**: Client-side filtering by search query (title/description/filePath), status, category, effort estimate, and business impact | N/A |
| `debtTrendDataProvider` | `Provider.family<AsyncValue<List<Map<String, dynamic>>>, String>` | Trend data extracted from debt summary history | `debtSummaryProvider` | **Yes**: Extracts `history` list from the summary map and returns it as trend data points | N/A |

---

## 16. `user_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/user_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `userApiProvider` | `Provider<UserApi>` | UserApi singleton | `apiClientProvider` | None | N/A |
| `currentUserProfileProvider` | `FutureProvider<User?>` | Current user profile | `authStateProvider`, `userApiProvider` | **Yes**: Skips fetch if auth state is not `authenticated`, returns null | N/A |
| `userSearchProvider` | `FutureProvider.family<List<User>, String>` | User search results | `userApiProvider` | **Yes**: Returns `[]` when query is shorter than 2 characters | N/A |

---

## 17. `agent_config_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/agent_config_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `anthropicApiServiceProvider` | `Provider<AnthropicApiService>` | AnthropicApiService singleton | None | None | N/A |
| `agentConfigServiceProvider` | `Provider<AgentConfigService>` | AgentConfigService with DI | `databaseProvider`, `anthropicApiServiceProvider`, `secureStorageProvider` | None -- DI wiring | N/A |
| `anthropicApiKeyProvider` | `FutureProvider<String?>` | Stored Anthropic API key | `secureStorageProvider` | None -- reads from secure storage | N/A |
| `apiKeyValidatedProvider` | `StateProvider<bool?>` | API key validation state: null=untested, true=valid, false=invalid | None | None | N/A |
| `anthropicModelsProvider` | `FutureProvider<List<AnthropicModelInfo>>` | Cached Anthropic models from local DB | `agentConfigServiceProvider` | None -- pass-through | N/A |
| `modelFetchFailedProvider` | `StateProvider<bool>` | Whether model fetch from Anthropic API failed (default false) | None | None | N/A |
| `agentDefinitionsProvider` | `FutureProvider<List<AgentDefinition>>` | All agent definitions sorted by sort order | `agentConfigServiceProvider` | None -- pass-through | N/A |
| `selectedAgentIdProvider` | `StateProvider<String?>` | Selected agent ID in agents tab (default null) | None | None | N/A |
| `selectedAgentProvider` | `Provider<AgentDefinition?>` | Derived selected agent definition | `selectedAgentIdProvider`, `agentDefinitionsProvider` | **Yes**: Scans agents list by ID to find the selected definition. Returns null if not found. | N/A |
| `selectedAgentFilesProvider` | `FutureProvider<List<AgentFile>>` | Files attached to selected agent | `selectedAgentIdProvider`, `agentConfigServiceProvider` | Returns `[]` if no agent selected | N/A |
| `agentConfigTabProvider` | `StateProvider<int>` | Selected tab in agent config (0=API Key, 1=Agents, 2=General; default 0) | None | None | N/A |
| `agentSearchQueryProvider` | `StateProvider<String>` | Agent search query (default `''`) | None | None | N/A |
| `editingAgentFileProvider` | `StateProvider<AgentFile?>` | AgentFile currently open in inline editor (default null) | None | None | N/A |

---

## 18. `github_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/github_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `githubConnectionsProvider` | `FutureProvider<List<GitHubConnection>>` | GitHub connections for selected team | `selectedTeamIdProvider`, `integrationApiProvider` | Returns `[]` if no team | N/A |
| `vcsProviderProvider` | `Provider<VcsProvider>` | GitHub VCS provider singleton | None | None -- instantiates GitHubProvider | N/A |
| `gitServiceProvider` | `Provider<GitService>` | Local git CLI service singleton | None | None | N/A |
| `repoManagerProvider` | `Provider<RepoManager>` | RepoManager for tracking cloned repos | `gitServiceProvider`, `databaseProvider` | None -- DI wiring | N/A |
| `vcsAuthenticatedProvider` | `StateProvider<bool>` | Whether VCS is authenticated (default false) | None | None | N/A |
| `vcsCredentialsProvider` | `StateProvider<VcsCredentials?>` | VCS credentials (default null) | None | None | N/A |
| `selectedOrgProvider` | `StateProvider<String?>` | Selected GitHub org login (default null) | None | None | N/A |
| `selectedRepoProvider` | `StateProvider<String?>` | Selected repo full name (default null) | None | None | N/A |
| `githubOrgsProvider` | `FutureProvider<List<VcsOrganization>>` | GitHub organizations for authenticated user | `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if not authenticated | N/A |
| `orgReposProvider` | `FutureProvider.family<List<VcsRepository>, String>` | Repos for an org | `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if not authenticated | N/A |
| `repoSearchResultsProvider` | `FutureProvider.family<List<VcsRepository>, String>` | Repo search results | `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if query < 2 chars or not authenticated | N/A |
| `repoBranchesProvider` | `FutureProvider.family<List<VcsBranch>, String>` | Branches for a repo | `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if not authenticated | N/A |
| `repoPullRequestsProvider` | `FutureProvider.family<List<VcsPullRequest>, String>` | PRs for a repo | `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if not authenticated | N/A |
| `repoCommitsProvider` | `FutureProvider.family<List<VcsCommit>, String>` | Commit history for a repo | `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if not authenticated | N/A |
| `repoWorkflowsProvider` | `FutureProvider.family<List<WorkflowRun>, String>` | Workflow runs for a repo | `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if not authenticated | N/A |
| `selectedRepoStatusProvider` | `FutureProvider<RepoStatus?>` | Status of selected repo if cloned | `selectedRepoProvider`, `repoManagerProvider` | Returns null if no repo selected | N/A |
| `clonedReposProvider` | `FutureProvider<Map<String, String>>` | Map of all cloned repos (fullName -> localPath) | `repoManagerProvider` | None -- pass-through | N/A |
| `selectedGithubOrgProvider` | `StateProvider<VcsOrganization?>` | Selected org object for sidebar (default null) | None | None | N/A |
| `selectedGithubRepoProvider` | `StateProvider<VcsRepository?>` | Selected repo object for detail panel (default null) | None | None | N/A |
| `githubRepoSearchQueryProvider` | `StateProvider<String>` | Search query for repo sidebar filter (default `''`) | None | None | N/A |
| `githubDetailTabProvider` | `StateProvider<int>` | Active detail tab index (0-3; default 0) | None | None | N/A |
| `githubReposForOrgProvider` | `FutureProvider<List<VcsRepository>>` | Repos for selected org (100 per page) | `selectedGithubOrgProvider`, `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if no org or not authenticated | N/A |
| `filteredGithubReposProvider` | `Provider<AsyncValue<List<VcsRepository>>>` | Filtered repos by search query | `githubReposForOrgProvider`, `githubRepoSearchQueryProvider` | **Yes**: Client-side filter by name/description matching search query | N/A |
| `githubReadmeProvider` | `FutureProvider.autoDispose<String?>` | Raw README markdown for selected repo | `selectedGithubRepoProvider`, `vcsAuthenticatedProvider`, `vcsProviderProvider` | **Yes**: Checks provider is GitHubProvider before calling `getReadmeContent` | N/A |
| `githubRepoBranchesProvider` | `FutureProvider.autoDispose<List<VcsBranch>>` | Branches for selected repo | `selectedGithubRepoProvider`, `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if no repo or not authenticated | N/A |
| `githubRepoPullRequestsProvider` | `FutureProvider.autoDispose<List<VcsPullRequest>>` | PRs for selected repo | `selectedGithubRepoProvider`, `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if no repo or not authenticated | N/A |
| `githubRepoCommitsProvider` | `FutureProvider.autoDispose<List<VcsCommit>>` | Commits for selected repo | `selectedGithubRepoProvider`, `vcsAuthenticatedProvider`, `vcsProviderProvider` | Returns `[]` if no repo or not authenticated | N/A |
| `isRepoClonedProvider` | `FutureProvider.autoDispose<bool>` | Whether selected repo is cloned locally | `selectedGithubRepoProvider`, `clonedReposProvider` | **Yes**: Checks cloned repos map for the selected repo's full name | N/A |

**Also defines function:** `restoreGitHubAuth(WidgetRef ref)` -- restores GitHub PAT from secure storage, authenticates with VCS provider, and updates state providers.

---

## 19. `project_local_config_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/project_local_config_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `projectLocalConfigProvider` | `FutureProvider.family<ProjectLocalConfigData?, String>` | Local config row for a project (machine-specific settings) | `databaseProvider` | **Yes**: Direct Drift database query selecting from `projectLocalConfig` table where `projectId` equals parameter | N/A |

**Also defines function:** `saveProjectLocalWorkingDir(WidgetRef ref, String projectId, String? path)` -- upserts the local working directory for a project in Drift and invalidates the provider.

---

## 20. `agent_progress_notifier.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/agent_progress_notifier.dart`

This file defines the `AgentProgressNotifier` class only (no top-level provider -- it is instantiated in `agent_providers.dart`).

| Class Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `AgentProgressNotifier` | `StateNotifier<Map<String, AgentProgress>>` | Map of agent run ID to AgentProgress (real-time agent state) | None (pure state notifier) | **Yes -- extensive**: Manages full agent lifecycle with progress tracking, finding counting, output buffering, queue positioning, elapsed time tracking | `initializeAgents()`, `markStarted()`, `markCompleted()`, `markFailed()`, `addFinding()`, `updateActivity()`, `updateProgress()`, `updateElapsed()`, `appendOutput()` (keeps last 50 lines), `incrementFilesAnalyzed()`, `updateQueuePositions()`, `reset()`, `agentRunIdForType()` |

---

## 21. `agent_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/agent_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `agentRunsProvider` | `FutureProvider.family<List<AgentRun>, String>` | Agent runs for a job | `jobApiProvider` | None -- pass-through | N/A |
| `selectedAgentTypesProvider` | `StateProvider<Set<AgentType>>` | Selected agent types for new job (default: all types) | None | None | N/A |
| `claudeCodeDetectorProvider` | `Provider<ClaudeCodeDetector>` | Claude Code CLI detector singleton | None | None | N/A |
| `claudeCodeStatusProvider` | `FutureProvider<ClaudeCodeStatus>` | CLI availability status | `claudeCodeDetectorProvider` | None -- runs `detector.validate()` | N/A |
| `processManagerProvider` | `Provider<ProcessManager>` | Subprocess lifecycle manager | None | **Yes**: Registers `ref.onDispose(pm.dispose)` for cleanup | N/A |
| `personaManagerProvider` | `Provider<PersonaManager>` | Prompt assembly manager | `apiClientProvider` (via PersonaApi and DirectiveApi constructors) | None -- DI wiring | N/A |
| `reportParserProvider` | `Provider<ReportParser>` | Markdown report parser singleton | None | None | N/A |
| `agentDispatcherProvider` | `Provider<AgentDispatcher>` | Claude Code subprocess spawner | `processManagerProvider`, `personaManagerProvider`, `claudeCodeDetectorProvider` | None -- DI wiring | N/A |
| `agentMonitorProvider` | `Provider<AgentMonitor>` | Process monitor | `processManagerProvider` | None -- DI wiring | N/A |
| `progressAggregatorProvider` | `Provider<ProgressAggregator>` | Real-time UI update aggregator | None | **Yes**: Registers `ref.onDispose(agg.dispose)` for cleanup | N/A |
| `veraManagerProvider` | `Provider<VeraManager>` | Post-analysis consolidation manager | None | None | N/A |
| `jobOrchestratorProvider` | `Provider<JobOrchestrator>` | Complete job lifecycle driver | `agentDispatcherProvider`, `agentMonitorProvider`, `veraManagerProvider`, `progressAggregatorProvider`, `reportParserProvider`, `jobApiProvider`, `findingApiProvider`, `reportApiProvider`, `agentProgressProvider.notifier` | None -- DI wiring (9 dependencies) | N/A |
| `jobProgressProvider` | `StreamProvider<JobProgress>` | Reactive job progress stream | `progressAggregatorProvider` | None -- subscribes to `aggregator.progressStream` | N/A |
| `jobLifecycleProvider` | `StreamProvider<JobLifecycleEvent>` | Job lifecycle events stream | `jobOrchestratorProvider` | None -- subscribes to `orchestrator.lifecycleStream` | N/A |
| `agentProgressProvider` | `StateNotifierProvider<AgentProgressNotifier, Map<String, AgentProgress>>` | Real-time agent card state (map of agentRunId -> AgentProgress) | None | Full lifecycle management via `AgentProgressNotifier` (see file 20 above) | All methods from `AgentProgressNotifier` |
| `sortedAgentProgressProvider` | `Provider<List<AgentProgress>>` | Sorted list for rendering agent cards | `agentProgressProvider` | **Yes**: Sorts by status order (running=0, pending=1, completed=2, failed=3), then by queue position within pending | N/A |
| `agentProgressSummaryProvider` | `Provider<AgentProgressSummary>` | Aggregate summary stats across all agents | `agentProgressProvider` | **Yes**: Computes total/running/queued/completed/failed counts plus totalFindings and totalCritical | N/A |
| `bugInvestigationOrchestratorProvider` | `Provider<BugInvestigationOrchestrator>` | Bug investigation orchestrator | `jobApiProvider`, `jobOrchestratorProvider` | None -- DI wiring | N/A |
| `agentDispatchConfigProvider` | `StateNotifierProvider<AgentDispatchConfigNotifier, AgentDispatchConfig>` | User-configurable dispatch config (maxConcurrent, timeout, model, maxTurns) | None | Default values from AppConstants | `setMaxConcurrent()`, `setAgentTimeout()`, `setClaudeModel()`, `setMaxTurns()` |

**Also defines class:** `AgentDispatchConfigNotifier` (StateNotifier) with `setMaxConcurrent()`, `setAgentTimeout()`, `setClaudeModel()`, `setMaxTurns()`.

---

## 22. `wizard_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/wizard_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `auditWizardStateProvider` | `StateNotifierProvider<AuditWizardNotifier, AuditWizardState>` | Full Audit Wizard multi-step flow state | None | Full wizard state machine with auto-detection of local project paths | See AuditWizardNotifier methods below |
| `jobHistoryFiltersProvider` | `StateProvider<JobHistoryFilters>` | Filter state for Job History page | None | None | N/A |
| `jobHistoryProvider` | `FutureProvider<List<JobSummary>>` | Job history wrapping `myJobsProvider` | `myJobsProvider` | None -- wraps existing provider | N/A |
| `filteredJobHistoryProvider` | `Provider<AsyncValue<List<JobSummary>>>` | Filtered job history | `jobHistoryProvider`, `jobHistoryFiltersProvider` | **Yes**: Client-side filtering by mode, status, result, search query (name/projectName), date range (dateFrom/dateTo) | N/A |
| `bugInvestigatorWizardStateProvider` | `StateNotifierProvider<BugInvestigatorWizardNotifier, BugInvestigatorWizardState>` | Bug Investigator wizard multi-step flow state | None | Full wizard state machine with auto-detection of local paths, recommended agents for bugInvestigate mode | See BugInvestigatorWizardNotifier methods below |

**`AuditWizardNotifier` methods:** `setLocalPath()`, `nextStep()`, `previousStep()`, `goToStep()`, `selectProject()` (auto-detects local path), `selectBranch()`, `toggleAgent()`, `selectAllAgents()`, `selectNoAgents()`, `selectRecommendedAgents(JobMode)`, `updateConfig()`, `setLaunching()`, `setLaunchError()`, `reset()`.

**`BugInvestigatorWizardNotifier` methods:** `nextStep()`, `previousStep()`, `goToStep()`, `selectIssue()`, `setLocalPath()`, `selectProject()` (auto-detects local path), `selectBranch()`, `toggleAgent()`, `selectRecommendedAgents()`, `setAdditionalContext()`, `updateConfig()`, `setLaunching()`, `setLaunchError()`, `reset()`.

**Also defines classes:** `JobConfig`, `SpecFile`, `JiraTicketData`, `AuditWizardState`, `BugInvestigatorWizardState`, `JobHistoryFilters`. **Enum:** `JobExecutionPhase` (creating, dispatching, running, consolidating, syncing, complete, failed, cancelled).

**Also defines function:** `detectLocalProjectPath(String projectName)` -- checks common clone locations under `$HOME`.

---

## 23. `compliance_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/compliance_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `complianceApiProvider` | `Provider<ComplianceApi>` | ComplianceApi singleton | `apiClientProvider` | None | N/A |
| `complianceWizardStateProvider` | `StateNotifierProvider<ComplianceWizardNotifier, ComplianceWizardState>` | Compliance Wizard multi-step flow state | None | Full wizard state machine with spec file management, auto-detect local paths | See ComplianceWizardNotifier methods below |
| `complianceJobSpecsProvider` | `FutureProvider.autoDispose.family<PageResponse<Specification>, String>` | Paginated specifications for a compliance job | `complianceApiProvider` | None -- pass-through | N/A |
| `complianceJobItemsProvider` | `FutureProvider.autoDispose.family<PageResponse<ComplianceItem>, String>` | Paginated compliance items for a job | `complianceApiProvider` | None -- pass-through | N/A |
| `complianceJobItemsByStatusProvider` | `FutureProvider.autoDispose.family<..., ({String jobId, ComplianceStatus status})>` | Compliance items filtered by status | `complianceApiProvider` | None -- pass-through | N/A |
| `complianceSummaryProvider` | `FutureProvider.autoDispose.family<Map<String, dynamic>, String>` | Compliance summary for a job | `complianceApiProvider` | None -- pass-through | N/A |
| `complianceScoreProvider` | `FutureProvider.autoDispose.family<double, String>` | Compliance score (0-100) derived from summary | `complianceSummaryProvider` | **Yes**: Formula: `(met + partial * 0.5) / total * 100`. Returns 0 if total is 0. | N/A |
| `complianceStatusFilterProvider` | `StateProvider<ComplianceStatus?>` | Status filter for compliance results (default null) | None | None | N/A |
| `complianceAgentFilterProvider` | `StateProvider<AgentType?>` | Agent type filter for compliance results (default null) | None | None | N/A |

**`ComplianceWizardNotifier` methods:** `nextStep()`, `previousStep()`, `goToStep()`, `setLocalPath()`, `selectProject()` (auto-detects local path), `selectBranch()`, `addSpecFiles()`, `removeSpec()`, `toggleAgent()`, `selectAllAgents()`, `selectNoAgents()`, `selectRecommendedAgents()`, `updateConfig()`, `setAdditionalContext()`, `setLaunching()`, `setLaunchError()`, `reset()`.

**Also defines class:** `ComplianceWizardState`, **constant:** `_complianceRecommendedAgents` (security, completeness, apiContract, testCoverage, uiUx).

---

## 24. `scribe_providers.dart`

**File path:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/providers/scribe_providers.dart`

| Provider Name | Type | State Managed | Dependencies | Business Logic | Key Methods |
|---|---|---|---|---|---|
| `scribeTabsProvider` | `StateProvider<List<ScribeTab>>` | List of open editor tabs (default `[]`) | None | None | N/A |
| `activeScribeTabIdProvider` | `StateProvider<String?>` | Active (visible) tab ID (default null) | None | None | N/A |
| `scribeUntitledCounterProvider` | `StateProvider<int>` | Auto-incrementing counter for "Untitled-N" names (default 1) | None | None | N/A |
| `scribeSettingsProvider` | `StateProvider<ScribeSettings>` | Editor settings (font size, tab size, word wrap, etc.) | None | None | N/A |
| `activeScribeTabProvider` | `Provider<ScribeTab?>` | Currently active tab object | `scribeTabsProvider`, `activeScribeTabIdProvider` | **Yes**: Finds matching tab from tabs list by active ID | N/A |
| `scribeHasUnsavedChangesProvider` | `Provider<bool>` | Whether any tab has unsaved changes | `scribeTabsProvider` | **Yes**: Checks `tabs.any((t) => t.isDirty)` | N/A |
| `scribeTabCountProvider` | `Provider<int>` | Total number of open tabs | `scribeTabsProvider` | **Yes**: Returns `tabs.length` | N/A |
| `scribePersistenceProvider` | `Provider<ScribePersistenceService>` | Scribe persistence service singleton | `databaseProvider` | None -- DI wiring | N/A |
| `scribeInitProvider` | `FutureProvider<void>` | Initializes Scribe state from persisted data | `scribePersistenceProvider`, `scribeTabsProvider`, `activeScribeTabIdProvider`, `scribeUntitledCounterProvider`, `scribeSettingsProvider` | **Yes**: Loads tabs and settings from Drift, sets active tab to first tab, computes max untitled counter from existing tab names | N/A |

---

## Summary Statistics

| Metric | Count |
|---|---|
| **Total provider files** | 24 |
| **Total providers defined** | ~155 (including duplicates across files) |
| **StateProvider** | ~60 |
| **FutureProvider** | ~55 |
| **FutureProvider.family** | ~30 |
| **Provider (derived/computed)** | ~18 |
| **StreamProvider** | 2 (`authStateProvider`, `jobProgressProvider`, `jobLifecycleProvider`) |
| **StateNotifierProvider** | 5 (`favoriteProjectIdsProvider`, `agentProgressProvider`, `agentDispatchConfigProvider`, `auditWizardStateProvider`, `bugInvestigatorWizardStateProvider`, `complianceWizardStateProvider`) |
| **StateNotifier classes** | 6 (`FavoriteProjectsNotifier`, `AgentProgressNotifier`, `AgentDispatchConfigNotifier`, `AuditWizardNotifier`, `BugInvestigatorWizardNotifier`, `ComplianceWizardNotifier`) |
| **Providers with significant business logic** | ~15 (filtered/sorted providers, health score computation, compliance score, agent progress management, wizard state machines) |

### Key Architectural Patterns

1. **API Service Layer**: Nearly every domain has a `Provider<XxxApi>` that wraps `apiClientProvider` -- this is consistent DI for all cloud API access.

2. **Filter/Sort Pattern**: Multiple domains (vulnerabilities, directives, personas, projects, tasks, tech debt, job history, GitHub repos) follow the same pattern: individual `StateProvider` filter/sort providers combined into a derived `Provider` or `Provider.family` that does client-side filtering and sorting.

3. **Wizard State Machine Pattern**: Three wizards (`AuditWizardNotifier`, `BugInvestigatorWizardNotifier`, `ComplianceWizardNotifier`) all follow the same `StateNotifier<XxxState>` pattern with step navigation, project selection with local path auto-detection, agent type selection, config management, and launch state tracking.

4. **Duplicate Provider Names**: `findingApiProvider` is defined in both `finding_providers.dart` and `job_providers.dart`. `jobFindingsProvider` is also defined in both files (with slightly different signatures -- the one in `job_providers.dart` uses `.autoDispose`). `jiraConnectionsProvider` is defined in both `jira_providers.dart` and `project_providers.dart`.

5. **Core Dependency Chain**: `secureStorageProvider` -> `apiClientProvider` -> every `*ApiProvider` -> every `FutureProvider` that fetches data. `selectedTeamIdProvider` is the other critical hub, watched by most team-scoped data providers.


---

## 11. Security Architecture

### Authentication Flow
1. **Login/Register:** `POST /auth/login` or `POST /auth/register` -> `AuthResponse` (JWT + refresh token + user)
2. **Token Storage:** JWT and refresh token stored in `SharedPreferences` via `SecureStorageService`
3. **Auto-Attach:** `ApiClient` interceptor attaches `Authorization: Bearer <token>` to all requests except public paths (`/auth/login`, `/auth/register`, `/auth/refresh`, `/health`)
4. **Token Refresh:** On 401 response, interceptor attempts `POST /auth/refresh` with stored refresh token using a fresh Dio instance. On success, retries original request. On failure, calls `onAuthFailure` (triggers logout).
5. **Auto-Login:** On app start, `tryAutoLogin()` validates stored token via `GET /users/me`. On failure, clears tokens and emits `unauthenticated`.
6. **Logout:** Clears all tokens, wipes entire local database, emits `unauthenticated`.

### Token Properties
- JWT expiry: 24 hours
- Refresh token expiry: 30 days
- No client-side token parsing or validation

### Credential Storage
- All credentials stored in `SharedPreferences` (UserDefaults on macOS)
- Not using flutter_secure_storage to avoid macOS Keychain password dialogs
- "Remember me" credentials, Anthropic API key, and GitHub PAT preserved across logout
- Jira API tokens stored with connection-specific keys

### Route Protection
- GoRouter redirect: unauthenticated users redirected to `/login`
- Admin pages: role-gated at widget level (checks for OWNER/ADMIN in team members)

### External API Keys
- Anthropic API key: stored locally, sent as `x-api-key` header to `api.anthropic.com`
- GitHub PAT: stored locally, sent as Bearer token to `api.github.com`
- Jira: Basic Auth (email:apiToken base64-encoded), stored locally per connection

---

## 12. Error Handling

### API Exception Hierarchy (Sealed Class)
```
ApiException (sealed)
  BadRequestException (400) -- errors: Map<String, String>?
  UnauthorizedException (401)
  ForbiddenException (403)
  NotFoundException (404)
  ConflictException (409)
  ValidationException (422) -- fieldErrors: Map<String, String>?
  RateLimitException (429) -- retryAfterSeconds: int?
  ServerException (500+) -- statusCode: int
  NetworkException (null status)
  TimeoutException (null status)
```

### Error Mapping
- `ApiClient` error interceptor maps every `DioException` to a typed `ApiException` subtype
- Enables exhaustive `switch` pattern matching in UI code
- No raw `DioException` escapes the API client layer

### Service-Level Patterns
- `SyncService`: catches `NetworkException`/`TimeoutException`, falls back to local cache
- `PersonaManager`: catches exceptions on team persona fetch, falls back to built-in
- `ClaudeCodeDetector`: catches all exceptions, returns safe defaults (never throws)
- `JobOrchestrator`: wraps entire flow in try/catch, updates server status to FAILED on error
- `LogService`: file I/O failures silently caught (never crash the app)

### Git Error Handling
- All git commands throw `GitException` on non-zero exit code
- `GitException` includes command, stderr message, and exit code

---

## 13. Page and Navigation

I now have all the source files read. Here is the complete structured audit document.

---

# CodeOps-Client: Startup, Routing, and Pages Audit

## 1. Startup Sequence (`main.dart`)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/main.dart`

**Class:** `main()` (top-level function)

**Startup Steps (in order):**

1. `WidgetsFlutterBinding.ensureInitialized()` -- ensures Flutter engine is ready
2. `LogConfig.initialize()` -- initializes the centralized logging system
3. `windowManager.ensureInitialized()` -- initializes the `window_manager` plugin
4. Configures `WindowOptions`:
   - Size: 1440x900
   - Minimum size: 1024x700
   - Centered, transparent background
   - Title: `'CodeOps'`
   - Title bar style: hidden (custom title bar)
5. `windowManager.waitUntilReadyToShow()` -- waits, then calls `show()` and `focus()`
6. Logs `'CodeOps starting'` via `log.i()`
7. Launches the app: `runApp(const ProviderScope(child: CodeOpsApp()))` -- wraps the entire app in a Riverpod `ProviderScope`

---

## 2. App Configuration (`app.dart`)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/app.dart`

**Class:** `CodeOpsApp` (extends `ConsumerWidget`)

**Responsibilities:**

1. **Auth State Bridge:** Listens to `authStateProvider` and bridges changes into a global `authNotifier` (a `ChangeNotifier` instance used by GoRouter's `refreshListenable`).
2. **Post-Authentication Initialization:** When `AuthState.authenticated` is detected:
   - Calls `_initTeamSelection(ref)` -- auto-selects the user's team:
     - Reads stored team ID from `secureStorageProvider`
     - Fetches teams via `teamApiProvider`
     - Uses the stored team if still valid, otherwise picks the first team
     - Sets `selectedTeamIdProvider` and persists the choice
     - Calls `restoreGitHubAuth(ref)` to restore GitHub PAT from storage
   - Calls `_initAgentConfig(ref)` -- seeds agent configuration:
     - Calls `agentConfigService.seedBuiltInAgents()` (idempotent, seeds 13 built-in agents)
     - Fire-and-forget: calls `agentConfigService.refreshModels()` to refresh Anthropic model cache
     - On failure, sets `modelFetchFailedProvider` to `true`
3. **MaterialApp.router:** Configures:
   - Title: `'CodeOps'`
   - Theme: `AppTheme.darkTheme`
   - Router: `router` (GoRouter instance from `router.dart`)
   - `debugShowCheckedModeBanner: false`

**Providers Consumed:**
- `authStateProvider`
- `secureStorageProvider`
- `teamApiProvider`
- `selectedTeamIdProvider`
- `agentConfigServiceProvider`
- `anthropicModelsProvider`
- `modelFetchFailedProvider`

---

## 3. Router (`router.dart`)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/router.dart`

**Router Type:** GoRouter with 24 named routes

**Auth Mechanism:**
- `AuthNotifier` class (extends `ChangeNotifier`) wraps `AuthState`
- Global instance `authNotifier` is updated by `CodeOpsApp` when auth state changes
- `refreshListenable: authNotifier` causes GoRouter to re-evaluate redirects on auth changes

**Global Redirect Logic:**
- Initial location: `/login`
- If NOT authenticated AND NOT on `/login` --> redirect to `/login`
- If authenticated AND on `/login` --> redirect to `/` (home)
- If authenticated AND on `/setup` --> allow (no redirect)
- Otherwise --> no redirect

**Route Table:**

### Routes Outside Shell (no navigation sidebar)

| # | Path | Name | Widget | Parameters | Notes |
|---|------|------|--------|------------|-------|
| 1 | `/login` | `login` | `LoginPage` | -- | Standard builder (with transitions) |
| 2 | `/setup` | `setup` | `PlaceholderPage(title: 'Setup Wizard')` | -- | Placeholder, not yet implemented |

### Routes Inside ShellRoute (wrapped in `NavigationShell`)

All routes below use `NoTransitionPage` for instant page switching within the shell.

| # | Path | Name | Widget | Parameters | Notes |
|---|------|------|--------|------------|-------|
| 3 | `/` | `home` | `HomePage` | -- | Dashboard |
| 4 | `/projects` | `projects` | `ProjectsPage` | -- | Project list |
| 5 | `/projects/:id` | `projectDetail` | `ProjectDetailPage` | `id` (path) | Project detail |
| 6 | `/repos` | `repos` | `GitHubBrowserPage` | -- | GitHub repo browser |
| 7 | `/scribe` | `scribe` | `ScribePage` | -- | Code editor |
| 8 | `/audit` | `audit` | `AuditWizardPage` | -- | Audit wizard |
| 9 | `/compliance` | `compliance` | `ComplianceWizardPage` | -- | Compliance wizard |
| 10 | `/dependencies` | `dependencies` | `DependencyScanPage` | -- | Dependency scan |
| 11 | `/bugs` | `bugs` | `BugInvestigatorPage` | `jiraKey` (query param, optional) | Bug investigator |
| 12 | `/bugs/jira` | `jiraBrowser` | `JiraBrowserPage` | -- | Jira browser |
| 13 | `/tasks` | `tasks` | `TaskManagerPage` | -- | Global task manager |
| 14 | `/tech-debt` | `techDebt` | `TechDebtPage` | -- | Tech debt tracker |
| 15 | `/health` | `health` | `HealthDashboardPage` | -- | Health dashboard |
| 16 | `/history` | `history` | `JobHistoryPage` | -- | Job history list |
| 17 | `/jobs/:id` | `jobProgress` | `JobProgressPage` | `id` (path) | Job progress / live tracking |
| 18 | `/jobs/:id/report` | `jobReport` | `JobReportPage` | `id` (path) | Job report |
| 19 | `/jobs/:id/findings` | `findingsExplorer` | `FindingsExplorerPage` | `id` (path) | Findings explorer |
| 20 | `/jobs/:id/tasks` | `taskList` | `TaskListPage` | `id` (path) | Job-specific task list |
| 21 | `/personas` | `personas` | `PersonasPage` | -- | Persona list |
| 22 | `/personas/:id/edit` | `personaEditor` | `PersonaEditorPage` | `id` (path) | Persona editor/create |
| 23 | `/directives` | `directives` | `DirectivesPage` | -- | Directive management |
| 24 | `/settings` | `settings` | `SettingsPage` | -- | Application settings |
| 25 | `/admin` | `admin` | `AdminHubPage` | -- | Admin hub (role-gated) |

---

## 4. Page Documentation

### 4.1 LoginPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/login_page.dart`
**Class:** `LoginPage` (extends `ConsumerStatefulWidget`)
**Route:** `/login`

**Display:** Centered card with two tabs: "Sign In" and "Register". Shows the CodeOps logo, tagline ("AI-Powered Software Maintenance"), and error banner when login fails.

**Key Widgets:**
- `TabBar` / `TabBarView` (2 tabs: Sign In, Register)
- `TextFormField` for email, password, display name, confirm password
- `Checkbox` for "Remember me"
- Password visibility toggle
- `ElevatedButton` for Sign In / Create Account

**Providers Consumed:**
- `authServiceProvider` -- calls `login()` / `register()`
- `secureStorageProvider` -- reads/writes remembered credentials
- `currentUserProvider` -- set on successful auth

**User Interactions:**
- Sign in with email/password
- Register with display name, email, password, confirm password
- "Remember me" checkbox (persists credentials to secure storage)
- Tab switching clears error messages
- On success, navigates to `/` via `context.go('/')`

---

### 4.2 HomePage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/home_page.dart`
**Class:** `HomePage` (extends `ConsumerWidget`)
**Route:** `/`

**Display:** Dashboard with time-of-day greeting, date, quick-start cards, recent activity, project health grid, and team overview. Responsive layout switches to stacked columns below 900px width.

**Key Widgets:**
- `QuickStartCards`
- `RecentActivity`
- `ProjectHealthGrid`
- `TeamOverview`

**Providers Consumed:**
- `currentUserProvider` -- displays user's display name

**User Interactions:**
- View dashboard data
- Quick-start cards navigate to various features

---

### 4.3 ProjectsPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/projects_page.dart`
**Class:** `ProjectsPage` (extends `ConsumerWidget`)
**Route:** `/projects`

**Display:** Top bar with search, sort dropdown (Name A-Z, Health Score, Last Audit), "Archived" filter chip, refresh button, and "New Project" button. Body is a responsive grid of project cards (2/3/4 columns based on width). Favorites pinned at top.

**Key Widgets:**
- `CodeOpsSearchBar`, `DropdownButton<ProjectSortOrder>`, `FilterChip`
- `_ProjectGrid` / `_ProjectCard` (responsive `GridView.builder`)
- `_CreateProjectDialog` (full project creation form with GitHub/Jira connection dropdowns, local working directory picker)

**Providers Consumed:**
- `filteredProjectsProvider`, `projectSortProvider`, `showArchivedProvider`
- `projectSearchQueryProvider`, `favoriteProjectIdsProvider`
- `teamProjectsProvider`, `projectApiProvider`, `selectedTeamIdProvider`
- `githubConnectionsProvider`, `jiraConnectionsProvider`
- `projectLocalConfigProvider`

**User Interactions:**
- Search/filter/sort projects
- Toggle archived projects visibility
- Favorite/unfavorite projects
- Click project card to navigate to `/projects/:id`
- Create new project via dialog (name, description, tech stack, local dir, GitHub connection, repo URL, repo full name, default branch, Jira connection, Jira project key, Jira issue type, labels, component)

---

### 4.4 ProjectDetailPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/project_detail_page.dart`
**Class:** `ProjectDetailPage` (extends `ConsumerWidget`)
**Route:** `/projects/:id`

**Display:** Scrollable page with: project header (health gauge, name, repo, tech stack, last audit, favorite/settings/archive/delete buttons), metrics cards (Total Jobs, Total Findings, Open Critical, Open High, Tech Debt Items, Vulnerabilities), health trend line chart (fl_chart), recent jobs DataTable, repository info card, Jira mapping card, directives card with toggle switches.

**Key Widgets:**
- `_ProjectHeader`, `_MetricsCards`, `_HealthTrendChart` (uses `fl_chart` `LineChart`)
- `_RecentJobsTable` (DataTable), `_RepositoryInfoCard`, `_JiraMappingCard`
- `_DirectivesCard` (with per-directive enable/disable Switch)
- `_SettingsDialog` (full edit form for project settings)

**Providers Consumed:**
- `projectProvider(projectId)`, `projectMetricsProvider(projectId)`
- `projectHealthTrendProvider(projectId)`, `projectRecentJobsProvider(projectId)`
- `projectDirectivesProvider(projectId)`, `directiveApiProvider`
- `favoriteProjectIdsProvider`, `projectApiProvider`
- `githubConnectionsProvider`, `jiraConnectionsProvider`
- `projectLocalConfigProvider`

**User Interactions:**
- Favorite/unfavorite, archive/unarchive, delete project (with confirmation dialogs)
- Edit project settings via dialog
- Toggle directives on/off
- Navigate to `/directives`, click job rows to go to `/jobs/:id`
- Browse local working directory

---

### 4.5 GitHubBrowserPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/github_browser_page.dart`
**Class:** `GitHubBrowserPage` (extends `ConsumerWidget`)
**Route:** `/repos`

**Display:** If not authenticated: "Connect GitHub" empty state with action button opening `GitHubAuthDialog`. If authenticated: master-detail layout with `RepoSidebar` (300px, left) and `RepoDetailPanel` (right).

**Key Widgets:**
- `RepoSidebar`, `RepoDetailPanel`, `GitHubAuthDialog`
- `_CreateFromRepoDialog` (creates project pre-filled from repo data)

**Providers Consumed:**
- `vcsAuthenticatedProvider`
- `teamProjectsProvider`, `projectApiProvider`, `selectedTeamIdProvider`

**User Interactions:**
- Connect GitHub account
- Browse repositories (org picker, search, repo list)
- View repo details (tabs)
- Create project from selected repository

---

### 4.6 ScribePage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/scribe_page.dart`
**Class:** `ScribePage` (extends `ConsumerStatefulWidget`)
**Route:** `/scribe`

**Display:** Multi-tab code/text editor with syntax highlighting for 30+ languages. Tab bar at top, editor area in center, status bar at bottom showing cursor position, language mode, encoding.

**Key Widgets:**
- `ScribeTabBar`, `ScribeEditor`, `ScribeStatusBar`, `ScribeEmptyState`

**Providers Consumed:**
- `scribeTabsProvider`, `activeScribeTabProvider`, `activeScribeTabIdProvider`
- `scribeSettingsProvider`, `scribeInitProvider`, `scribePersistenceProvider`
- `scribeUntitledCounterProvider`

**User Interactions:**
- New tab (Ctrl+N)
- Open file (Ctrl+O via FilePicker)
- Close tab
- Switch tabs
- Edit code content
- Change language mode from status bar
- Session persistence (tabs restored on reopen)

---

### 4.7 AuditWizardPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/audit_wizard_page.dart`
**Class:** `AuditWizardPage` (extends `ConsumerStatefulWidget`)
**Route:** `/audit`

**Display:** 4-step wizard: Source (project + branch), Agents (selector), Configuration (thresholds + model), Review (confirm + launch).

**Key Widgets:**
- `WizardScaffold` with `WizardStepDef` definitions
- `SourceStep`, `AgentSelectorStep`, `ThresholdStep`, `ReviewStep`

**Providers Consumed:**
- `auditWizardStateProvider` (notifier)
- `jobOrchestratorProvider`

**User Interactions:**
- Select project, branch, local path
- Select/deselect agents (toggle individual, select all, select none, select recommended)
- Configure thresholds: max concurrent agents, agent timeout, Claude model, max turns
- Add additional context
- Launch audit (fire-and-forget, navigates to `/jobs/:id` or `/history`)
- Cancel (reset wizard, navigate to `/`)

---

### 4.8 ComplianceWizardPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/compliance_wizard_page.dart`
**Class:** `ComplianceWizardPage` (extends `ConsumerStatefulWidget`)
**Route:** `/compliance`

**Display:** 4-step wizard: Source, Specifications (file upload), Agents, Review.

**Key Widgets:**
- `WizardScaffold`, `SourceStep`, `SpecUploadStep`, `AgentSelectorStep`, `ReviewStep`
- `_SpecTypeExplanation`, `_AdditionalContextField`, `_SpecSummaryCard`

**Providers Consumed:**
- `complianceWizardStateProvider`, `jobOrchestratorProvider`
- `reportApiProvider`, `complianceApiProvider`

**User Interactions:**
- Select project, branch, local path
- Upload specification files (OpenAPI/YAML/JSON, Markdown, screenshots, PDFs, CSV, XML)
- Select agents
- Add additional context
- Launch compliance check (uploads spec files, creates specification records, navigates to `/jobs/:id`)

---

### 4.9 BugInvestigatorPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/bug_investigator_page.dart`
**Class:** `BugInvestigatorPage` (extends `ConsumerStatefulWidget`)
**Route:** `/bugs` (optional query param: `jiraKey`)

**Display:** 3-step wizard: Select Bug (Jira issue picker + detail preview), Configure (source + agents + additional context), Review & Launch.

**Key Widgets:**
- `WizardScaffold`, `IssuePicker`, `IssueDetailPanel`, `SourceStep`, `AgentSelectorStep`
- `_BugSelectionStep`, `_ConfigureStep`, `_ReviewStep`, `_SummaryRow`

**Providers Consumed:**
- `bugInvestigatorWizardStateProvider`, `bugInvestigationOrchestratorProvider`
- `jiraCommentsProvider`, `teamProjectsProvider`

**User Interactions:**
- Select Jira issue (with optional initial key from query param)
- Auto-detect project from Jira project key
- Configure source (project, branch, local path)
- Select agents, add additional context
- Launch investigation (navigates to `/jobs/:id`)

---

### 4.10 DependencyScanPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/dependency_scan_page.dart`
**Class:** `DependencyScanPage` (extends `ConsumerStatefulWidget`)
**Route:** `/dependencies`

**Display:** Top-bottom split. Top: scan overview (project dropdown, scan metadata, health gauge, severity/status summary cards). Bottom: 3-tab view (All Vulnerabilities, CVE Alerts, Update Plan).

**Key Widgets:**
- `_ScanOverview` with `DepHealthGauge`, `_SummaryCard`
- `TabBar` / `TabBarView` with: `DepScanResults`, `CveAlertCard`, `DepUpdateList`
- `DropdownButtonFormField` for project selection

**Providers Consumed:**
- `teamProjectsProvider`, `selectedProjectIdProvider`
- `latestScanProvider(projectId)`, `scanVulnerabilitiesProvider(scanId)`
- `depHealthScoreProvider(projectId)`, `dependencyApiProvider`

**User Interactions:**
- Select project from dropdown
- View scan data (dependency count, outdated, vulnerable)
- Browse all vulnerabilities, CVE alerts, update plan
- Update vulnerability status (open, updating, suppressed, resolved)
- Bulk resolve vulnerability groups
- Export update plan
- Navigate to `/audit` to run a new scan

---

### 4.11 JiraBrowserPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/jira_browser_page.dart`
**Class:** `JiraBrowserPage` (extends `ConsumerStatefulWidget`)
**Route:** `/bugs/jira`

**Display:** If not configured: "No Jira Connection" empty state. If configured: connection selector bar, JQL search bar with presets, master-detail layout (issue list left, detail panel right).

**Key Widgets:**
- `_ConnectionBar`, `IssueSearch`, `IssueBrowser`, `IssueDetailPanel`
- `JiraConnectionDialog`

**Providers Consumed:**
- `isJiraConfiguredProvider`, `jiraConnectionsProvider`, `activeJiraConnectionProvider`
- `selectedJiraIssueKeyProvider`, `selectedProjectProvider`
- `jiraSearchResultsProvider`

**User Interactions:**
- Add/switch Jira connections
- Search issues with JQL
- Keyboard navigation (up/down arrows to navigate issues)
- Select issue to view detail panel
- Close detail panel
- "Investigate" navigates to `/bugs`

---

### 4.12 TaskManagerPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/task_manager_page.dart`
**Class:** `TaskManagerPage` (extends `ConsumerStatefulWidget`)
**Route:** `/tasks`

**Display:** Header with "Task Manager" title and 2 tabs: "My Tasks" and "By Job". My Tasks tab: filter bar (status chips, search) + master-detail layout (task list + detail panel). By Job tab: list of recent jobs linking to `/jobs/:id/tasks`.

**Key Widgets:**
- `TabBar` / `TabBarView` (2 tabs)
- `TaskListWidget`, `TaskDetailPanel`, `TaskExportDialog`

**Providers Consumed:**
- `filteredMyTasksProvider`, `myTasksProvider`, `taskFilterProvider`
- `selectedTaskIdsProvider`, `jobHistoryProvider`

**User Interactions:**
- Switch between "My Tasks" and "By Job" tabs
- Filter tasks by status, search
- Select/multi-select tasks
- View task detail in side panel
- Bulk export selected tasks
- Click job in "By Job" tab to navigate to `/jobs/:id/tasks`

---

### 4.13 TaskListPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/task_list_page.dart`
**Class:** `TaskListPage` (extends `ConsumerStatefulWidget`)
**Route:** `/jobs/:id/tasks`

**Display:** Job-scoped task list with header (back to report), filter bar (status chips, priority dropdown, search), bulk actions toolbar, master-detail layout (task list + detail panel).

**Key Widgets:**
- `TaskListWidget`, `TaskDetailPanel`
- `JiraCreateDialog` (bulk create Jira issues from tasks)
- `TaskExportDialog`

**Providers Consumed:**
- `jobDetailProvider(jobId)`, `filteredJobTasksProvider(jobId)`
- `jobTasksProvider(jobId)`, `taskFilterProvider`, `selectedTaskIdsProvider`

**User Interactions:**
- Filter tasks by status, priority, search
- Select/multi-select tasks
- View task detail in side panel
- Bulk create Jira issues from selected tasks
- Bulk export selected tasks
- Navigate back to `/jobs/:id/report`

---

### 4.14 TechDebtPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/tech_debt_page.dart`
**Class:** `TechDebtPage` (extends `ConsumerStatefulWidget`)
**Route:** `/tech-debt`

**Display:** Three-column layout. Left (20%): summary panel (project selector, debt score gauge, status summary with progress bars, category breakdown, resolution rate, quick actions). Center (flexible): debt inventory (filterable, paginated list). Right (20%): detail panel (selected item metadata, status workflow buttons, "View Source Job" link).

**Key Widgets:**
- `_SummaryPanel` with `_DebtScoreGauge`, `_StatusSummary`, `DebtCategoryBreakdown`
- `DebtInventory`
- `_DetailPanel` with status workflow buttons (Identified -> Planned -> In Progress -> Resolved)

**Providers Consumed:**
- `teamProjectsProvider`, `selectedProjectIdProvider`
- `filteredTechDebtProvider(projectId)`, `projectTechDebtProvider(projectId)`
- `debtSummaryProvider(projectId)`, `techDebtApiProvider`
- `selectedTechDebtItemProvider`

**User Interactions:**
- Select project from dropdown
- View debt score, status breakdown, category breakdown
- Browse/filter/paginate debt inventory
- Select item to view detail
- Update debt status (Plan, Start, Resolve, Reopen)
- Delete debt items (with confirmation)
- Run Tech Debt Scan (navigates to `/audit`)
- Export Debt Report
- View Source Job (navigates to `/jobs/:id/report`)

---

### 4.15 HealthDashboardPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/health_dashboard_page.dart`
**Class:** `HealthDashboardPage` (extends `ConsumerStatefulWidget`)
**Route:** `/health`

**Display:** Scrollable page with "Health Dashboard" heading, team overview + project health cards (`HealthOverviewPanel`), and selected project detail section (`HealthTrendPanel` + `ScheduleManagerPanel`).

**Key Widgets:**
- `HealthOverviewPanel`, `HealthTrendPanel`, `ScheduleManagerPanel`

**Providers Consumed:**
- `selectedHealthProjectProvider`, `teamProjectsProvider`

**User Interactions:**
- View team health overview
- Select a project to view trends and manage schedules
- Auto-selects first active project if none selected

---

### 4.16 JobHistoryPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/job_history_page.dart`
**Class:** `JobHistoryPage` (extends `ConsumerStatefulWidget`)
**Route:** `/history`

**Display:** Header with "Job History" title and "New Audit" button. Filter bar with search, mode/status/result dropdowns, clear filters. Sortable table with columns: status dot, name, project, mode badge, result badge, health score, findings count, date.

**Key Widgets:**
- `_FilterBar` with `CodeOpsSearchBar`, `_FilterChipDropdown<T>` (generic popup menu filter)
- `_JobTable`, `_JobRow`, `_SortableHeader`

**Providers Consumed:**
- `filteredJobHistoryProvider`, `jobHistoryFiltersProvider`, `jobHistoryProvider`

**User Interactions:**
- Search jobs
- Filter by mode, status, result
- Sort by health, findings, date (ascending/descending)
- Click row to navigate to `/jobs/:id`
- "New Audit" navigates to `/audit`

---

### 4.17 JobProgressPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/job_progress_page.dart`
**Class:** `JobProgressPage` (extends `ConsumerStatefulWidget`)
**Route:** `/jobs/:id`

**Display:** Real-time job execution view. Header with job name, mode badge, branch, elapsed timer, cancel button. Phase indicator (creating -> dispatching -> running -> consolidating -> syncing -> complete). Error/cancelled/completed banners. Progress bar, progress summary bar, agent status grid, live findings feed.

**Key Widgets:**
- `PhaseIndicator`, `ElapsedTimer`, `JobProgressBar`, `ProgressSummaryBar`
- `AgentStatusGrid`, `LiveFindingsFeed`
- `_ErrorBanner`, `_CompletedSummary`, `_StatChip`

**Providers Consumed:**
- `jobDetailProvider(jobId)`, `jobProgressProvider`, `jobLifecycleProvider`
- `sortedAgentProgressProvider`, `agentProgressSummaryProvider`
- `jobOrchestratorProvider`

**User Interactions:**
- Monitor real-time job progress
- Cancel running job
- On completion: "View Report" (navigates to `/jobs/:id/report`), "View Findings" (navigates to `/jobs/:id/findings`)
- On failure: "Retry" navigates to `/audit`
- Polls job detail as fallback for lifecycle stream

---

### 4.18 JobReportPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/job_report_page.dart`
**Class:** `JobReportPage` (extends `ConsumerStatefulWidget`)
**Route:** `/jobs/:id/report`

**Display:** Header bar with back button, job name, "View Findings" and "Export" buttons. Tab bar: For non-compliance jobs: Overview tab + per-completed-agent tabs. For compliance jobs: Compliance Matrix + Gap Analysis + Specifications tabs + per-completed-agent tabs. Overview tab shows executive summary card and 30-day health trend chart.

**Key Widgets:**
- `ExecutiveSummaryCard`, `TrendChart`, `AgentReportTab`
- Compliance-specific: `ComplianceResultsPanel`, `GapAnalysisPanel`, `SpecListPanel`
- `ExportDialog`

**Providers Consumed:**
- `jobDetailProvider(jobId)`, `agentRunsByJobProvider(jobId)`
- `jobFindingsProvider`, `projectTrendProvider`
- `reportApiProvider`

**User Interactions:**
- Switch between tabs (Overview, per-agent reports, compliance-specific tabs)
- View executive summary and trend data
- Export report (via dialog)
- Navigate to findings (`/jobs/:id/findings`)
- Navigate back to job (`/jobs/:id`)

---

### 4.19 FindingsExplorerPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/findings_explorer_page.dart`
**Class:** `FindingsExplorerPage` (extends `ConsumerStatefulWidget`)
**Route:** `/jobs/:id/findings`

**Display:** Header bar (back to report, "View Report" button), severity filter bar, bulk actions toolbar (when items selected), master-detail split: findings table (left) with pagination + detail panel (right) when a finding is selected.

**Key Widgets:**
- `SeverityFilterBar`, `FindingsTable`, `FindingDetailPanel`
- `FindingStatusActions`

**Providers Consumed:**
- `jobDetailProvider(jobId)`, `jobFindingsProvider`, `findingSeverityCountsProvider(jobId)`
- `selectedFindingIdsProvider`, `activeFindingProvider`, `findingFiltersProvider`
- `findingApiProvider`

**User Interactions:**
- Filter by severity, status, agent type, search query
- Paginate through findings
- Select individual findings to view detail
- Multi-select findings for bulk status changes
- Navigate back to report (`/jobs/:id/report`)

---

### 4.20 PersonasPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/personas_page.dart`
**Class:** `PersonasPage` (extends `ConsumerWidget`)
**Route:** `/personas`

**Display:** Top bar with title, search, scope filter dropdown, agent type filter dropdown, refresh/import/new buttons. Body: grid of persona cards (`PersonaList`).

**Key Widgets:**
- `CodeOpsSearchBar`, `DropdownButton<Scope?>`, `DropdownButton<AgentType?>`
- `PersonaList`

**Providers Consumed:**
- `filteredPersonasProvider`, `personaScopeFilterProvider`, `personaAgentTypeFilterProvider`
- `personaSearchQueryProvider`, `teamPersonasProvider`, `systemPersonasProvider`
- `personaApiProvider`, `selectedTeamIdProvider`

**User Interactions:**
- Search personas
- Filter by scope and agent type
- Import persona from `.md` file (via FilePicker)
- Create new persona (navigates to `/personas/new/edit`)
- Click persona card to edit

---

### 4.21 PersonaEditorPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/persona_editor_page.dart`
**Class:** `PersonaEditorPage` (extends `ConsumerStatefulWidget`)
**Route:** `/personas/:id/edit`

**Display:** Top bar (back button, persona name/title, "SYSTEM (Read-Only)" badge for system personas, Test/Export/Delete/Save buttons). Form fields (name, agent type dropdown, scope dropdown, description, default toggle). Split view: left = markdown editor (`PersonaEditorWidget`), right = live preview (`PersonaPreview`).

**Key Widgets:**
- `PersonaEditorWidget`, `PersonaPreview`, `PersonaTestRunner`
- `SplitView` (horizontal split)

**Providers Consumed:**
- `personaApiProvider`, `teamPersonasProvider`, `systemPersonasProvider`
- `selectedTeamIdProvider`

**User Interactions:**
- Edit persona name, description, agent type, scope, default toggle
- Edit markdown content in split editor/preview
- Save (create new or update existing)
- Delete (with confirmation dialog)
- Export to `.md` file
- Test persona via `PersonaTestRunner` dialog
- System personas are read-only
- Back navigation to `/personas`

---

### 4.22 DirectivesPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/directives_page.dart`
**Class:** `DirectivesPage` (extends `ConsumerStatefulWidget`)
**Route:** `/directives`

**Display:** Master-detail layout. Left panel (2/5 width): header with title, refresh button, "New" button, search bar, category/scope dropdowns, directive card list. Right panel (3/5 width): inline editor with name, category dropdown, scope dropdown, description, markdown content field, preview toggle, assign/delete/save buttons.

**Key Widgets:**
- `_DirectiveList`, `_DirectiveCard`, `_DirectiveEditor`
- `_AssignDialog` (assign directive to projects with checkbox + enable/disable switch)
- `CodeOpsSearchBar`, `DropdownButton<DirectiveCategory?>`, `DropdownButton<DirectiveScope?>`

**Providers Consumed:**
- `filteredDirectivesProvider`, `directiveCategoryFilterProvider`, `directiveScopeFilterProvider`
- `selectedDirectiveProvider`, `directiveSearchQueryProvider`
- `teamDirectivesProvider`, `directiveApiProvider`
- `selectedTeamIdProvider`, `teamProjectsProvider`, `projectDirectivesProvider`

**User Interactions:**
- Search directives, filter by category and scope
- Create new directive
- Select directive to edit in right panel
- Edit name, category, scope, description, markdown content
- Toggle markdown preview
- Save directive (create or update)
- Delete directive (with confirmation)
- Assign directive to projects (checkbox + enable/disable toggle per project)

---

### 4.23 SettingsPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/settings_page.dart`
**Class:** `SettingsPage` (extends `ConsumerStatefulWidget`)
**Route:** `/settings`

**Display:** Left sidebar (200px) with 7 section tabs, right content panel. Sections:

1. **Profile** -- display name, email (read-only), avatar URL, change password form
2. **Team** -- team name, description, Teams webhook URL, member count (editable only for owner/admin)
3. **Integrations** -- GitHub connections list, Jira connections list (showing name, username/URL, active status)
4. **Agent Config** -- 3 sub-tabs (API Key via `ApiKeyTab`, Agents via `AgentsTab`, General via `GeneralSettingsTab`), inline markdown file editor
5. **Notifications** -- toggle grid for 8 event types (job_completed, critical_finding, etc.) with In-App and Email switches (local-only state)
6. **Appearance** -- sidebar collapsed default, font density (Compact/Normal/Comfortable), compact mode toggle
7. **About** -- app version, server URL, server health status, auto-update toggle, links to docs/release notes/issues

**Key Widgets:**
- `ApiKeyTab`, `AgentsTab`, `GeneralSettingsTab`, `MarkdownEditorPanel`
- `SegmentedButton`, `SwitchListTile`

**Providers Consumed:**
- `currentUserProvider`, `authServiceProvider`, `settingsSectionProvider`
- `selectedTeamProvider`, `teamMembersProvider`
- `githubConnectionsProvider`, `jiraConnectionsProvider`
- `agentConfigServiceProvider`, `agentConfigTabProvider`, `editingAgentFileProvider`, `selectedAgentFilesProvider`
- `sidebarCollapsedProvider`, `fontDensityProvider`, `compactModeProvider`
- `autoUpdateProvider`, `teamMetricsProvider`

**User Interactions:**
- Edit profile (display name, avatar URL)
- Change password
- View team info, members
- View GitHub/Jira integration status
- Manage API key, agent configurations, general settings
- Toggle notification preferences
- Adjust appearance (sidebar, font density, compact mode)
- Toggle auto-updates
- Open external links (docs, release notes, report issue)

---

### 4.24 AdminHubPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/admin_hub_page.dart`
**Class:** `AdminHubPage` (extends `ConsumerStatefulWidget`)
**Route:** `/admin`

**Display:** Role-gated page (requires OWNER or ADMIN role). If access denied: centered lock icon with "Access Denied" message. If authorized: "Admin Hub" header, 4-tab interface (Users, System Settings, Audit Log, Usage Stats).

**Key Widgets:**
- `TabBar` / `TabBarView` (4 tabs)
- `UserManagementTab`, `SettingsManagementTab`, `AuditLogTab`, `UsageStatsTab`

**Providers Consumed:**
- `teamMembersProvider`, `currentUserProvider`, `adminTabIndexProvider`

**User Interactions:**
- Switch between 4 admin tabs
- Manage users (UserManagementTab)
- Manage system settings (SettingsManagementTab)
- View audit log (AuditLogTab)
- View usage statistics (UsageStatsTab)

---

### 4.25 PlaceholderPage

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/pages/placeholder_page.dart`
**Class:** `PlaceholderPage` (extends `StatelessWidget`)
**Route:** Used only by `/setup`

**Display:** Centered title text, route path, and "Coming soon" label. A temporary stand-in for routes not yet implemented.

**Key Widgets:** None beyond basic `Text` widgets.

**Providers Consumed:** None.

**User Interactions:** None -- display-only placeholder.

---

## 5. Navigation Structure Summary

The `NavigationShell` widget (from `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shell/navigation_shell.dart`) wraps all authenticated routes and provides the persistent sidebar navigation. The sidebar is organized into sections based on the route groupings visible in the router.

**Outside shell (unauthenticated):**
- `/login` -- LoginPage
- `/setup` -- PlaceholderPage (Setup Wizard)

**Inside shell (authenticated), grouped by sidebar section:**
- **Home:** `/`
- **Build:** `/projects`, `/projects/:id`, `/repos`, `/scribe`
- **Analyze:** `/audit`, `/compliance`, `/dependencies`
- **Maintain:** `/bugs`, `/bugs/jira`, `/tasks`, `/tech-debt`
- **Monitor:** `/health`, `/history`
- **Job detail (contextual):** `/jobs/:id`, `/jobs/:id/report`, `/jobs/:id/findings`, `/jobs/:id/tasks`
- **Configure:** `/personas`, `/personas/:id/edit`, `/directives`
- **System:** `/settings`, `/admin`


---

## 14. Widget Catalog

All 98 files have now been read. Let me compile the complete audit document.

---

# CodeOps-Client Widget Audit

## Complete Widget Inventory: `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/`

**98 files across 18 subdirectories**

---

### 1. `widgets/admin/` (4 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/admin/audit_log_tab.dart`
- **Class:** `AuditLogTab`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Paginated audit log DataTable with action type filter dropdown.
- **Providers:** `auditLogProvider`, `auditLogPageProvider`, `auditLogActionFilterProvider`
- **Interactions:** Filter by action type, page forward/back navigation.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/admin/settings_management_tab.dart`
- **Class:** `SettingsManagementTab`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Admin settings table with inline editing of key-value pairs.
- **Providers:** `adminSettingsProvider`
- **Interactions:** Edit setting value inline, Save button per row.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/admin/usage_stats_tab.dart`
- **Class:** `UsageStatsTab`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Dashboard of usage metric cards (total users, jobs, API calls, etc.).
- **Providers:** `usageStatsProvider`
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/admin/user_management_tab.dart`
- **Class:** `UserManagementTab`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Paginated user DataTable with role display and status badges.
- **Providers:** `adminUsersProvider`, `adminUsersPageProvider`
- **Interactions:** Page forward/back navigation.

---

### 2. `widgets/compliance/` (3 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/compliance/compliance_results_panel.dart`
- **Class:** `ComplianceResultsPanel`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required String jobId}`
- **Purpose:** Compliance score gauge + compliance matrix for a job's spec compliance results.
- **Providers:** `complianceResultsProvider(jobId)`
- **Interactions:** Retry on error.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/compliance/gap_analysis_panel.dart`
- **Class:** `GapAnalysisPanel`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required String jobId}`
- **Purpose:** Collapsible specification sections showing gaps with copy-as-markdown.
- **Providers:** `gapAnalysisProvider(jobId)`
- **Interactions:** Expand/collapse sections, copy gap as markdown.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/compliance/spec_list_panel.dart`
- **Class:** `SpecListPanel`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required String jobId}`
- **Purpose:** Specification files DataTable with file size, type, and download actions.
- **Providers:** `specFilesProvider(jobId)`
- **Interactions:** Download file button, retry on error.

---

### 3. `widgets/dashboard/` (4 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/dashboard/project_health_grid.dart`
- **Class:** `ProjectHealthGrid`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Grid of project cards with health score badges, colored by score range.
- **Providers:** `teamProjectsProvider`
- **Interactions:** Project card tap navigates to project health page.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/dashboard/quick_start_cards.dart`
- **Class:** `QuickStartCards`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Four hover-animated action cards (New Audit, Run Compliance, Bug Investigation, Remediation).
- **Providers:** None
- **Interactions:** Card tap navigates to respective wizard page via `context.go`.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/dashboard/recent_activity.dart`
- **Class:** `RecentActivity`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** List of recent QA jobs with status icons, project names, and relative timestamps.
- **Providers:** `recentJobsProvider`
- **Interactions:** Job row tap navigates to job report/progress page.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/dashboard/team_overview.dart`
- **Class:** `TeamOverview`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Six stat cards showing team metrics (projects, members, jobs, findings, health, uptime).
- **Providers:** `teamStatsProvider`
- **Interactions:** None (display-only).

---

### 4. `widgets/dependency/` (4 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/dependency/cve_alert_card.dart`
- **Class:** `CveAlertCard`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required CveAlert alert, VoidCallback? onViewDetails, VoidCallback? onDismiss}`
- **Purpose:** Vulnerability alert card with severity badge, CVE ID, CVSS score, and action buttons.
- **Providers:** None
- **Interactions:** "View Details" and "Dismiss" buttons.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/dependency/dep_health_gauge.dart`
- **Class:** `DepHealthGauge`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required int score, double size, double strokeWidth}`
- **Purpose:** Circular dependency health gauge using CustomPainter with 270-degree arc.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/dependency/dep_scan_results.dart`
- **Class:** `DepScanResults`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectId}`
- **Purpose:** Filterable paginated vulnerability DataTable with severity filter and search.
- **Providers:** `depScanResultsProvider(projectId)`
- **Interactions:** Severity filter chips, search field, column sorting, pagination.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/dependency/dep_update_list.dart`
- **Class:** `DepUpdateList`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required List<DepUpdate> updates, ValueChanged<DepUpdate>? onApply}`
- **Purpose:** Grouped list of dependency updates by update type (major/minor/patch).
- **Providers:** None
- **Interactions:** "Apply Update" button per dependency.

---

### 5. `widgets/findings/` (4 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/findings/finding_detail_panel.dart`
- **Class:** `FindingDetailPanel`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required Finding finding, VoidCallback? onClose}`
- **Purpose:** Side panel showing finding detail with severity, agent badge, file path, and markdown description.
- **Providers:** `findingDetailProvider(finding.id)`
- **Interactions:** Close button, retry on error.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/findings/finding_status_actions.dart`
- **Class:** `FindingStatusActions`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required List<Finding> findings, VoidCallback? onStatusChanged}`
- **Purpose:** Single and bulk status transition buttons (Accept, Reject, Defer, Reopen).
- **Providers:** `findingApiProvider`
- **Interactions:** Status transition buttons with confirmation for bulk operations.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/findings/findings_table.dart`
- **Class:** `FindingsTable`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String jobId}`
- **Purpose:** Sortable DataTable with multi-select checkboxes for findings.
- **Providers:** `jobFindingsProvider(jobId)`, `findingsSortProvider`, `selectedFindingIdsProvider`
- **Interactions:** Column sort, row checkbox select, select-all, row tap opens detail.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/findings/severity_filter_bar.dart`
- **Class:** `SeverityFilterBar`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Horizontal bar of severity toggle chips with counts, plus agent type and status dropdowns.
- **Providers:** `severityFilterProvider`, `agentTypeFilterProvider`, `statusFilterProvider`, `findingCountsProvider`
- **Interactions:** Toggle severity chips, select agent type/status dropdowns.

---

### 6. `widgets/health/` (3 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/health/health_overview_panel.dart`
- **Class:** `HealthOverviewPanel`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required String teamId}`
- **Purpose:** Team health metrics summary + per-project health score cards.
- **Providers:** `teamHealthProvider(teamId)`
- **Interactions:** Project card tap navigates to project detail.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/health/health_trend_panel.dart`
- **Class:** `HealthTrendPanel`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required String projectId}`
- **Purpose:** Time-range health score trend chart with 7d/30d/90d/All range selector.
- **Providers:** `healthTrendProvider(projectId)`
- **Interactions:** Time range toggle chips, data point tap shows tooltip.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/health/schedule_manager_panel.dart`
- **Class:** `ScheduleManagerPanel`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectId}`
- **Purpose:** Health check schedule CRUD with frequency, enabled toggle, and next-run display.
- **Providers:** `healthSchedulesProvider(projectId)`, `healthScheduleApiProvider`
- **Interactions:** Create schedule dialog, enable/disable toggle, delete with confirmation.

---

### 7. `widgets/jira/` (11 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/assignee_picker.dart`
- **Class:** `AssigneePicker`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectKey, String? initialAccountId, required ValueChanged<JiraUser?> onSelected}`
- **Purpose:** Debounced user search field with dropdown autocomplete results.
- **Providers:** `jiraUserSearchProvider(query)`
- **Interactions:** Type to search, select user from dropdown.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/bulk_create_dialog.dart`
- **Class:** `BulkCreateDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectKey, required List<BulkIssueInput> items}`
- **Purpose:** Bulk Jira issue creation dialog with per-item preview, select-all, and batch create.
- **Providers:** `jiraApiProvider`
- **Interactions:** Toggle individual items, select all/none, Create All button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/create_issue_dialog.dart`
- **Class:** `CreateIssueDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectKey, String? prefillSummary, String? prefillDescription, String? prefillIssueType}`
- **Purpose:** Single Jira issue creation form with summary, description, type, priority, assignee, and labels.
- **Providers:** `jiraApiProvider`, `jiraIssueTypesProvider(projectKey)`, `jiraPrioritiesProvider`
- **Interactions:** Form fields, Create button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/issue_browser.dart`
- **Class:** `IssueBrowser`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectKey}`
- **Purpose:** Filterable paginated issue list with status/type/priority filters.
- **Providers:** `jiraIssuesProvider`, `jiraIssuePageProvider`, `jiraIssueFilterProvider`
- **Interactions:** Filter dropdowns, pagination, issue row tap opens detail.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/issue_card.dart`
- **Class:** `IssueCard`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required JiraIssue issue, bool isSelected, VoidCallback? onTap}`
- **Purpose:** Compact issue list card with type icon, key, summary, status badge, and hover effect.
- **Providers:** None
- **Interactions:** Card tap.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/issue_detail_panel.dart`
- **Class:** `IssueDetailPanel`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required JiraIssue issue, VoidCallback? onClose}`
- **Purpose:** Full detail side-panel with metadata, description, comments, transitions, and linked issues.
- **Providers:** `jiraIssueDetailProvider(issue.key)`, `jiraApiProvider`
- **Interactions:** Close button, transition buttons, add comment, open in browser.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/issue_picker.dart`
- **Class:** `IssuePicker`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectKey, String? initialIssueKey, required ValueChanged<JiraIssue?> onSelected}`
- **Purpose:** Text field with debounced autocomplete dropdown for selecting Jira issues.
- **Providers:** `jiraIssueSearchProvider`
- **Interactions:** Type to search, select issue from dropdown.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/issue_search.dart`
- **Class:** `IssueSearch`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectKey}`
- **Purpose:** JQL search bar with preset query buttons (My Issues, Open Bugs, Recent, High Priority).
- **Providers:** `jiraJqlSearchProvider`
- **Interactions:** Preset chips, JQL text input, search button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/jira_connection_dialog.dart`
- **Class:** `JiraConnectionDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Jira Cloud connection configuration dialog (site URL, email, API token) with test connection.
- **Providers:** `jiraApiProvider`, `secureStorageProvider`, `jiraConnectionProvider`
- **Interactions:** URL/email/token fields, Test Connection, Save.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/jira_project_mapper.dart`
- **Class:** `JiraProjectMapper`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** CodeOps-to-Jira project mapping table with auto-match and manual override dropdowns.
- **Providers:** `teamProjectsProvider`, `jiraProjectsProvider`, `projectJiraMappingsProvider`
- **Interactions:** Dropdown per row to select Jira project, Auto-Map button, Save Mappings.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/jira/rca_post_dialog.dart`
- **Class:** `RcaPostDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String rcaMarkdown, required String findingId}`
- **Purpose:** Dialog to post RCA (Root Cause Analysis) as a Jira comment with issue picker and preview.
- **Providers:** `jiraApiProvider`
- **Interactions:** Issue picker, preview tab, Post Comment button.

---

### 8. `widgets/personas/` (4 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/personas/persona_editor.dart`
- **Class:** `PersonaEditorWidget`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required String initialContent, required ValueChanged<String> onChanged, bool readOnly}`
- **Purpose:** Markdown editor with formatting toolbar (bold, italic, headers, lists, code blocks) and line numbers.
- **Providers:** None
- **Interactions:** Toolbar buttons, text editing.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/personas/persona_list.dart`
- **Class:** `PersonaList`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required ValueChanged<AgentDefinition> onSelect, required ValueChanged<AgentDefinition> onEdit}`
- **Purpose:** Responsive grid of persona cards with context menus (Edit, Duplicate, Delete, Export).
- **Providers:** `agentDefinitionsProvider`
- **Interactions:** Card tap selects, context menu actions.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/personas/persona_preview.dart`
- **Class:** `PersonaPreview`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required String markdown, bool showValidation}`
- **Purpose:** Rendered markdown preview with optional validation warnings for missing persona sections.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/personas/persona_test_runner.dart`
- **Class:** `PersonaTestRunner`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required AgentDefinition agent}`
- **Purpose:** Test persona via Claude Code CLI with prompt input, streaming terminal output, and pass/fail result.
- **Providers:** `claudeCodeServiceProvider`
- **Interactions:** Prompt text field, Run Test button, terminal output display.

---

### 9. `widgets/progress/` (9 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/agent_card.dart`
- **Class:** `AgentCard`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required AgentRun agentRun, VoidCallback? onTap}`
- **Purpose:** Real-time agent status card with icon, name, status badge, elapsed timer, and progress indicator. Defines `AgentTypeMetadata.all` map for 12 agent types.
- **Providers:** None
- **Interactions:** Card tap.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/agent_output_terminal.dart`
- **Class:** `AgentOutputTerminal`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required List<String> lines, bool autoScroll}`
- **Purpose:** Dark terminal-styled auto-scrolling container for agent output lines.
- **Providers:** None
- **Interactions:** Auto-scroll with manual scroll override.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/agent_status_grid.dart`
- **Class:** `AgentStatusGrid`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required List<AgentRun> agentRuns, required JobExecutionPhase phase, ValueChanged<AgentRun>? onAgentTap}`
- **Purpose:** Responsive grid of AgentCard widgets with a VeraCard for the consolidation phase.
- **Providers:** None
- **Interactions:** Agent card tap.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/elapsed_timer.dart`
- **Class:** `ElapsedTimer`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required DateTime startTime, bool running, TextStyle? style}`
- **Purpose:** Live HH:MM:SS elapsed timer with 1-second tick.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/job_progress_bar.dart`
- **Class:** `JobProgressBar`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required JobProgress progress, double height}`
- **Purpose:** Segmented colored bar showing pass/warn/fail/running/queued agent counts.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/live_findings_feed.dart`
- **Class:** `LiveFindingsFeed`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required List<LiveFinding> findings, bool initiallyCollapsed}`
- **Purpose:** Auto-scrolling feed of live findings with severity badges and collapse toggle.
- **Providers:** None
- **Interactions:** Collapse/expand toggle button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/phase_indicator.dart`
- **Class:** `PhaseIndicator`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required JobExecutionPhase currentPhase}`
- **Purpose:** Six-phase horizontal stepper (Init, Cloning, Analyzing, Consolidating, Reporting, Complete) with animated pulsing dot on active phase.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/progress_summary_bar.dart`
- **Class:** `ProgressSummaryBar`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required AgentProgressSummary summary}`
- **Purpose:** Horizontal status bar with running/queued/done/failed agent counts and findings summary.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/vera_card.dart`
- **Class:** `VeraCard`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required JobExecutionPhase phase}`
- **Purpose:** Consolidation agent (Vera) card with gradient background and spinner during active phases.
- **Providers:** None
- **Interactions:** None (display-only).

---

### 10. `widgets/reports/` (8 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/reports/agent_report_tab.dart`
- **Class:** `AgentReportTab`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required AgentRun agentRun}`
- **Purpose:** Agent metadata header + lazy-loaded markdown report from S3.
- **Providers:** `agentReportMarkdownProvider(s3Key)`
- **Interactions:** Retry on error.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/reports/compliance_matrix.dart`
- **Class:** `ComplianceMatrix`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required List<ComplianceItem> items, ValueChanged<ComplianceItem>? onItemTap}`
- **Purpose:** Filterable sortable DataTable with status filter chips for compliance items.
- **Providers:** None
- **Interactions:** Filter chips, column sort, row tap.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/reports/executive_summary_card.dart`
- **Class:** `ExecutiveSummaryCard`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required QaJob job, required List<AgentRun> agentRuns, String? summaryMd}`
- **Purpose:** Job overview card with health gauge, severity chart, agent status summary, and markdown executive summary.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/reports/export_dialog.dart`
- **Class:** `_ExportDialogContent` (shown via `showExportDialog()` top-level function)
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String jobId}`
- **Purpose:** Export format selector (Markdown/PDF/ZIP/CSV) with section checkboxes and progress indicator.
- **Providers:** `ExportService` (injected)
- **Interactions:** Format chips, section checkboxes, Export button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/reports/health_score_gauge.dart`
- **Class:** `HealthScoreGauge`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required int score, double size, double strokeWidth, bool showLabel}`
- **Purpose:** Animated 270-degree arc gauge with CustomPainter, color-coded by score range.
- **Providers:** None
- **Interactions:** None (display-only, animated on mount).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/reports/markdown_renderer.dart`
- **Class:** `MarkdownRenderer`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required String content, bool selectable, bool shrinkWrap, EdgeInsets? padding}`
- **Purpose:** Styled markdown renderer with syntax-highlighted code blocks via flutter_highlight.
- **Providers:** None
- **Interactions:** Link tap opens URL via url_launcher.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/reports/severity_chart.dart`
- **Class:** `SeverityChart`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required Map<Severity, int> counts, SeverityChartMode mode, double height}`
- **Purpose:** Bar chart or donut chart of severity distribution using fl_chart PieChart/BarChart.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/reports/trend_chart.dart`
- **Class:** `TrendChart`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required List<HealthSnapshot> snapshots, double height, ValueChanged<HealthSnapshot>? onPointTap}`
- **Purpose:** fl_chart LineChart with pass/warn/fail threshold bands and tooltips.
- **Providers:** None
- **Interactions:** Data point tap callback.

---

### 11. `widgets/scribe/` (7 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/scribe/scribe_editor_controller.dart`
- **Class:** `ScribeEditorController`
- **Type:** `ChangeNotifier` (NOT a widget)
- **Purpose:** Wraps `CodeLineEditingController` from re_editor, exposes cursor position, selection, text content, undo/redo, and content change notifications.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/scribe/scribe_editor.dart`
- **Class:** `ScribeEditor`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, String content, String language, ValueChanged<String>? onChanged, bool readOnly, bool showLineNumbers, double fontSize, int tabSize, bool insertSpaces, bool wordWrap, bool showMinimap, String? placeholder, ScribeEditorController? controller, FocusNode? focusNode}`
- **Purpose:** Multi-language code editor using re_editor CodeEditor with syntax highlighting via re_highlight.
- **Providers:** None
- **Interactions:** Full text editing, keyboard shortcuts (Ctrl+Z undo, Ctrl+Shift+Z redo).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/scribe/scribe_empty_state.dart`
- **Class:** `ScribeEmptyState`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required VoidCallback onNewFile, required VoidCallback onOpenFile}`
- **Purpose:** Centered empty state with "New File" and "Open File" buttons plus keyboard shortcut hints.
- **Providers:** None
- **Interactions:** New File button, Open File button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/scribe/scribe_language.dart`
- **Class:** `ScribeLanguage`
- **Type:** Utility class (NOT a widget)
- **Purpose:** Maps 50+ file extensions to 31 language identifiers for syntax highlighting. Provides `supportedLanguages`, `fromExtension()`, `displayName()`.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/scribe/scribe_status_bar.dart`
- **Class:** `ScribeStatusBar`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required int cursorLine, required int cursorColumn, required String language, required ValueChanged<String> onLanguageChanged}`
- **Purpose:** Bottom status bar with language dropdown (PopupMenuButton), cursor position (Ln/Col), encoding (UTF-8), line ending (LF).
- **Providers:** None
- **Interactions:** Language mode dropdown selection.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/scribe/scribe_tab_bar.dart`
- **Class:** `ScribeTabBar`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required List<ScribeTab> tabs, String? activeTabId, required ValueChanged<String> onTabSelected, required ValueChanged<String> onTabClosed, required VoidCallback onNewTab}`
- **Purpose:** Horizontal scrollable tab bar with dirty indicators, close buttons, and "+" new tab button.
- **Providers:** None
- **Interactions:** Tab select, tab close, new tab button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/scribe/scribe_theme.dart`
- **Class:** `ScribeThemeData` / `ScribeTheme`
- **Type:** Data/factory classes (NOT widgets)
- **Purpose:** Theme configuration for the Scribe editor with Material Palenight-inspired syntax colors.

---

### 12. `widgets/settings/` (7 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/settings/agent_detail_panel.dart`
- **Class:** `AgentDetailPanel`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Right-side detail panel with model dropdown, temperature slider (with help dialog), retries, max turns, timeout, attached files list, and system prompt override.
- **Providers:** `selectedAgentProvider`, `anthropicModelsProvider`, `selectedAgentFilesProvider`, `agentConfigServiceProvider`
- **Interactions:** All fields editable with debounced auto-save, add/view/edit/delete files, temperature help button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/settings/agent_file_row.dart`
- **Class:** `AgentFileRow`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required AgentFile file, VoidCallback? onViewEdit, VoidCallback? onDelete}`
- **Purpose:** Single file row with type icon, file name, type badge, and view/edit + delete action buttons.
- **Providers:** None
- **Interactions:** View/Edit button, Delete button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/settings/agent_list_panel.dart`
- **Class:** `AgentListPanel`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Searchable grouped agent list (Vera pinned at top, built-in agents, custom agents) with enable/disable and delete actions.
- **Providers:** `agentDefinitionsProvider`, `agentSearchQueryProvider`, `selectedAgentIdProvider`, `agentConfigServiceProvider`
- **Interactions:** Search bar, agent select, enable/disable checkbox, delete custom agent, "New Agent" button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/settings/agents_tab.dart`
- **Class:** `AgentsTab`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Master-detail layout container: AgentListPanel on left + AgentDetailPanel on right.
- **Providers:** None
- **Interactions:** None (delegates to children).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/settings/api_key_tab.dart`
- **Class:** `ApiKeyTab`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Anthropic API key management with obscured input field, Test Connection/Save buttons, and cached models table.
- **Providers:** `apiKeyValidatedProvider`, `anthropicModelsProvider`, `modelFetchFailedProvider`, `secureStorageProvider`, `apiKeyProvider`, `claudeModelProvider`
- **Interactions:** Show/hide API key toggle, Test Connection, Save, Refresh Models.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/settings/general_settings_tab.dart`
- **Class:** `GeneralSettingsTab`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** System-wide defaults: model dropdown, concurrent agents slider, timeout slider, temperature display, auto-retry toggle, queue behavior radio (Parallel/Sequential).
- **Providers:** `claudeModelProvider`, `maxConcurrentAgentsProvider`, `agentTimeoutMinutesProvider`, `anthropicModelsProvider`
- **Interactions:** Model dropdown, concurrent agents slider, timeout slider, auto-retry switch, queue behavior radio.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/settings/new_agent_dialog.dart`
- **Class:** `NewAgentDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Dialog for creating a custom agent definition with name and description fields.
- **Providers:** `agentConfigServiceProvider`
- **Interactions:** Name/description text fields, Create button, Cancel.

---

### 13. `widgets/shared/` (8 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shared/confirm_dialog.dart`
- **Class:** `ConfirmDialog`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required String title, required String message, String confirmLabel, String cancelLabel, bool destructive}`
- **Purpose:** Generic confirm/cancel dialog with destructive styling option. Also provides `showConfirmDialog()` top-level function.
- **Providers:** None
- **Interactions:** Confirm button, Cancel button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shared/empty_state.dart`
- **Class:** `EmptyState`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required IconData icon, required String title, String? subtitle, String? actionLabel, VoidCallback? onAction}`
- **Purpose:** Centered empty state placeholder with icon, title, subtitle, and optional action button.
- **Providers:** None
- **Interactions:** Optional action button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shared/error_panel.dart`
- **Class:** `ErrorPanel`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required String title, required String message, VoidCallback? onRetry}`
- **Purpose:** Error display panel with `fromException` factory that maps ApiException subtypes (401, 403, 404, 500, network) to user-friendly messages.
- **Providers:** None
- **Interactions:** Retry button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shared/loading_overlay.dart`
- **Class:** `LoadingOverlay`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, String? message}`
- **Purpose:** Semi-transparent overlay with spinner and optional message, uses AbsorbPointer to block interaction.
- **Providers:** None
- **Interactions:** None (blocks all interaction).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shared/markdown_editor_dialog.dart`
- **Class:** `MarkdownEditorPanel`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required String fileName, required String fileType, required String initialContent, required OnSaveCallback onSave, required VoidCallback onClose}`
- **Purpose:** View/edit markdown file with split-pane live preview, synchronized scrolling, file type dropdown, and unsaved changes confirmation.
- **Providers:** None
- **Interactions:** Edit/View mode toggle, file type dropdown, Save button, Close with unsaved prompt.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shared/notification_toast.dart`
- **Class:** `NotificationToast`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required String message, required IconData icon, required Color color}`
- **Purpose:** Toast notification content with left-border accent color. Provides `showToast()` top-level function with `ToastType` enum (success, error, warning, info).
- **Providers:** None
- **Interactions:** None (auto-dismiss).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shared/search_bar.dart`
- **Class:** `CodeOpsSearchBar`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, String hint, required ValueChanged<String> onChanged, Duration debounceDuration}`
- **Purpose:** Debounced search text field with search icon and clear button.
- **Providers:** None
- **Interactions:** Text input (debounced), clear button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shared/temperature_help_dialog.dart`
- **Class:** `TemperatureHelpDialog`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Informational dialog explaining temperature settings (0.0 = precise, 0.5 = balanced, 1.0 = creative).
- **Providers:** None
- **Interactions:** Close button.

---

### 14. `widgets/shell/` (2 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shell/navigation_shell.dart`
- **Class:** `NavigationShell`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required Widget child}`
- **Purpose:** Main app shell with collapsible sidebar (17 nav items in 6 sections: Main, Quality, Integrations, Code Tools, Management, Admin), title bar with window drag, top bar with page name + search/notification/help buttons, and user profile popup with Switch Team/Logout.
- **Providers:** `sidebarCollapsedProvider`, `currentUserProvider`, `teamMembersProvider`
- **Interactions:** Sidebar navigation (17 items), sidebar collapse/expand, search button, notification button, help button, user menu (Switch Team dialog, Logout).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/shell/team_switcher_dialog.dart`
- **Class:** `TeamSwitcherDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Team selection dialog with team list, selection highlighting, and inline create-team form.
- **Providers:** `teamsProvider`, `selectedTeamIdProvider`
- **Interactions:** Team card tap to select, Create Team form (name + description), Cancel.

---

### 15. `widgets/tasks/` (5 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tasks/jira_create_dialog.dart`
- **Class:** Top-level function `showJiraCreateTaskDialog()` (no widget class)
- **Purpose:** Resolves Jira project from job, delegates to `CreateIssueDialog` or `BulkCreateDialog`, updates task status to JIRA_CREATED on success.
- **Providers:** `taskApiProvider`, `jiraApiProvider`
- **Interactions:** Delegates to Jira dialog widgets.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tasks/task_card.dart`
- **Class:** `TaskCard`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required RemediationTask task, bool isSelected, bool isActive, VoidCallback? onTap, ValueChanged<bool?>? onCheckboxChanged}`
- **Purpose:** Compact task card with priority color dot, task number, title, Jira badge, status chip, and selection checkbox.
- **Providers:** None
- **Interactions:** Card tap, checkbox toggle.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tasks/task_detail.dart`
- **Class:** `TaskDetailPanel`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required RemediationTask task, required String jobId, VoidCallback? onClose, VoidCallback? onTaskUpdated}`
- **Purpose:** Side panel with metadata rows, description markdown, collapsible agent prompt, related findings list, Copy Prompt and Mark Complete action buttons.
- **Providers:** `taskApiProvider`
- **Interactions:** Copy Prompt to clipboard, Mark Complete, expand/collapse prompt, close button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tasks/task_export_dialog.dart`
- **Class:** `_TaskExportDialog` (shown via `showTaskExportDialog()` top-level function)
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required List<RemediationTask> tasks, required String jobId}`
- **Purpose:** Export tasks to clipboard or markdown file with metadata/findings/priority section options. Updates task status to EXPORTED.
- **Providers:** `taskApiProvider`
- **Interactions:** Section checkboxes, Copy to Clipboard, Save to File.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tasks/task_list.dart`
- **Class:** `TaskListWidget`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required List<RemediationTask> tasks, RemediationTask? activeTask, Set<String> selectedIds, ValueChanged<RemediationTask>? onTaskTap, ValueChanged<Set<String>>? onSelectionChanged, bool isLoading}`
- **Purpose:** Scrollable list with select-all header checkbox and TaskCard items.
- **Providers:** None
- **Interactions:** Select all checkbox, individual task card tap and checkbox.

---

### 16. `widgets/tech_debt/` (4 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tech_debt/debt_category_breakdown.dart`
- **Class:** `DebtCategoryBreakdown`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required List<TechDebtItem> items}`
- **Purpose:** Donut chart of debt items by 5 categories (code_smell, complexity, duplication, deprecated, security) using fl_chart PieChart.
- **Providers:** None (uses `TechDebtTracker.computeDebtByCategory()`)
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tech_debt/debt_inventory.dart`
- **Class:** `DebtInventory`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String projectId, ValueChanged<TechDebtItem>? onItemSelected, ValueChanged<TechDebtItem>? onDelete, void Function(TechDebtItem, DebtStatus)? onStatusUpdate}`
- **Purpose:** Filterable paginated debt item list with search, status/category/effort/impact/sort dropdowns, and context menu (Mark Resolved, Delete).
- **Providers:** `filteredTechDebtProvider`, `selectedTechDebtItemProvider`, `debtStatusFilterProvider`, `debtCategoryFilterProvider`, `debtEffortFilterProvider`, `debtImpactFilterProvider`, `debtSortOrderProvider`, `debtSearchQueryProvider`
- **Interactions:** Search bar, filter dropdowns, context menu actions, item tap, pagination.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tech_debt/debt_priority_matrix.dart`
- **Class:** `DebtPriorityMatrix`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required List<TechDebtItem> items, ValueChanged<TechDebtItem>? onItemTap}`
- **Purpose:** 2D effort-vs-impact grid with positioned dots using CustomPainter (_MatrixGridPainter) for grid lines and axis labels.
- **Providers:** None
- **Interactions:** Dot tap shows tooltip, callback.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/tech_debt/debt_trend_chart.dart`
- **Class:** `DebtTrendChart`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required String projectId}`
- **Purpose:** Line chart of debt score history over time using fl_chart LineChart.
- **Providers:** `debtTrendDataProvider(projectId)`
- **Interactions:** None (display-only).

---

### 17. `widgets/vcs/` (17 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/branch_picker.dart`
- **Class:** `BranchPicker`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String repoFullName, required String currentBranch, required ValueChanged<String> onBranchSelected}`
- **Purpose:** PopupMenuButton branch selector with filter text field and protected branch indicators (main/master lock icon).
- **Providers:** `repoBranchesProvider(repoFullName)`
- **Interactions:** Open popup, filter branches, select branch.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/ci_status_badge.dart`
- **Class:** `CiStatusBadge`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required WorkflowRun run}`
- **Purpose:** Compact badge with success/failure/in_progress/queued icons and colored background.
- **Providers:** None
- **Interactions:** Click opens workflow URL via url_launcher.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/clone_dialog.dart`
- **Class:** `CloneDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required VcsRepository repo}`
- **Purpose:** Clone dialog with branch selector, target directory picker (Browse button), and streaming clone progress indicator.
- **Providers:** `gitServiceProvider`, `repoManagerProvider`, `vcsCredentialsProvider`
- **Interactions:** Branch dropdown, Browse directory button, Clone button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/commit_dialog.dart`
- **Class:** `CommitDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String repoDir, required List<FileChange> changes}`
- **Purpose:** Commit dialog with file checkboxes (select all), commit message with character count, and "Push after commit" option.
- **Providers:** `gitServiceProvider`, `selectedRepoStatusProvider`
- **Interactions:** File checkboxes, select all, commit message field, Push checkbox, Commit button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/commit_history.dart`
- **Class:** `CommitHistory`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required String repoFullName}`
- **Purpose:** Commit timeline list with short SHA, commit message, author, and relative timestamp.
- **Providers:** `repoCommitsProvider(repoFullName)`
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/create_pr_dialog.dart`
- **Class:** `CreatePRDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String repoFullName}`
- **Purpose:** Pull request creation dialog with head/base branch dropdowns, title, description, draft checkbox.
- **Providers:** `vcsProviderProvider`, `repoBranchesProvider(repoFullName)`, `repoPullRequestsProvider(repoFullName)`
- **Interactions:** Branch dropdowns, title/description fields, draft checkbox, Create PR button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/diff_viewer.dart`
- **Class:** `DiffViewer`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required List<DiffResult> diffs}`
- **Purpose:** Unified diff viewer with green additions, red deletions, line numbers, and hunk headers.
- **Providers:** None
- **Interactions:** None (display-only).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/github_auth_dialog.dart`
- **Class:** `GitHubAuthDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** GitHub PAT input dialog with obscured field, show/hide toggle, test connection, and save flow.
- **Providers:** `vcsProviderProvider`, `secureStorageProvider`, `vcsCredentialsProvider`, `vcsAuthenticatedProvider`
- **Interactions:** PAT input, show/hide toggle, Test & Save button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/new_branch_dialog.dart`
- **Class:** `NewBranchDialog`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String repoDir, required String currentBranch}`
- **Purpose:** New branch creation dialog with branch name input and validation (no spaces, .., ~).
- **Providers:** `gitServiceProvider`
- **Interactions:** Branch name field, Create button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/org_browser.dart`
- **Class:** `OrgBrowser`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Selectable list of GitHub organizations with circular avatars and org names.
- **Providers:** `githubOrgsProvider`, `selectedOrgProvider`
- **Interactions:** Org list item tap to select.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/pull_request_list.dart`
- **Class:** `PullRequestList`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required String repoFullName}`
- **Purpose:** Pull request list with status icons (open/merged/closed), PR title, author, date, and "Create PR" button.
- **Providers:** `repoPullRequestsProvider(repoFullName)`
- **Interactions:** "Create PR" button opens CreatePRDialog.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/repo_browser.dart`
- **Class:** `RepoBrowser`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Repository card grid for selected org with language badge, star/fork counts, and clone status indicator.
- **Providers:** `selectedOrgProvider`, `orgReposProvider(org)`, `clonedReposProvider`, `selectedRepoProvider`
- **Interactions:** Repo card tap to select.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/repo_detail_panel.dart`
- **Class:** `RepoDetailPanel`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Tabbed detail panel (README, Branches, PRs, Commits) with repo header and action bar (Clone/Open in Finder/View on GitHub/Refresh).
- **Providers:** `selectedGithubRepoProvider`, `githubRepoBranchesProvider`, `githubRepoPullRequestsProvider`, `githubRepoCommitsProvider`, `githubReadmeProvider`, `isRepoClonedProvider`, `clonedReposProvider`, `githubDetailTabProvider`
- **Interactions:** Tab navigation, Clone dialog, Open in Finder, View on GitHub, Refresh.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/repo_search.dart`
- **Class:** `RepoSearch`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Search bar with minimum 2-character threshold and results list for GitHub repositories.
- **Providers:** `repoSearchResultsProvider(query)`, `selectedRepoProvider`
- **Interactions:** Search input (min 2 chars), repo list item tap to select.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/repo_sidebar.dart`
- **Class:** `RepoSidebar`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key}`
- **Purpose:** Left-panel sidebar with org picker dropdown, search field, and scrollable filtered repo list with language color dots and star counts.
- **Providers:** `githubOrgsProvider`, `selectedGithubOrgProvider`, `githubReposForOrgProvider`, `selectedGithubRepoProvider`, `filteredGithubReposProvider`, `githubRepoSearchQueryProvider`, `githubDetailTabProvider`
- **Interactions:** Org dropdown, search field, repo list item tap, auto-select first org/repo on load.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/repo_status_bar.dart`
- **Class:** `RepoStatusBar`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, required RepoStatus status, required String repoDir}`
- **Purpose:** Horizontal bar showing branch name, clean/dirty state, ahead/behind counts, and Fetch/Pull/Push action buttons.
- **Providers:** `gitServiceProvider`, `selectedRepoStatusProvider`
- **Interactions:** Fetch button, Pull button, Push button (enabled when ahead > 0).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/vcs/stash_manager.dart`
- **Class:** `StashManager`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, required String repoDir}`
- **Purpose:** Git stash list with pop/drop actions per entry, "Stash Changes" button, and confirmation dialog before dropping.
- **Providers:** `gitServiceProvider`, `selectedRepoStatusProvider`
- **Interactions:** Stash Changes button, Pop button per stash, Drop button with confirm dialog.

---

### 18. `widgets/wizard/` (8 files)

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/wizard/agent_selector_step.dart`
- **Class:** `AgentSelectorStep`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required Set<AgentType> selectedAgents, required ValueChanged<AgentType> onToggle, required VoidCallback onSelectAll, required VoidCallback onSelectNone, VoidCallback? onSelectRecommended}`
- **Purpose:** Agent selection grid with agent type cards (icon, name, description, checkbox) and quick-select bar (All/None/Recommended). Responsive columns (2-4).
- **Providers:** None
- **Interactions:** Toggle individual agents, All/None/Recommended quick-select chips.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/wizard/finding_filter_step.dart`
- **Class:** `FindingFilterStep`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required List<Finding> findings, required Set<String> selectedIds, required ValueChanged<Set<String>> onSelectionChanged}`
- **Purpose:** Finding filter step with severity/agent type dropdowns, search bar, "Select visible"/"Clear all" quick actions, and selectable findings list with checkboxes.
- **Providers:** None
- **Interactions:** Severity dropdown, agent type dropdown, search, select visible, clear all, individual finding checkbox.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/wizard/jira_ticket_step.dart`
- **Class:** `JiraTicketStep`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, JiraTicketData? ticketData, required ValueChanged<String> onFetchTicket, String additionalContext, required ValueChanged<String> onContextChanged, bool isFetching, String? fetchError}`
- **Purpose:** Jira ticket key input with Fetch button, fetched ticket detail card (key, status, priority, summary, description, metadata), and additional context text field.
- **Providers:** None
- **Interactions:** Ticket key input, Fetch button, additional context text field.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/wizard/review_step.dart`
- **Class:** `ReviewStep`
- **Type:** `ConsumerWidget`
- **Constructor:** `{super.key, Project? project, String? branch, required Set<AgentType> selectedAgents, required JobConfig config, Widget? additionalInfo}`
- **Purpose:** Read-only summary cards (Source, Agents, Configuration, Additional Context) with Claude Code CLI status check and estimated time calculation.
- **Providers:** `claudeCodeStatusProvider`
- **Interactions:** None (display-only review).

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/wizard/source_step.dart`
- **Class:** `SourceStep`
- **Type:** `ConsumerStatefulWidget`
- **Constructor:** `{super.key, Project? selectedProject, String? selectedBranch, String? localPath, required ValueChanged<Project> onProjectSelected, required ValueChanged<String> onBranchSelected, ValueChanged<String>? onLocalPathSelected}`
- **Purpose:** Searchable project list from team projects, selected project detail card with branch picker and local path directory picker (via file_picker).
- **Providers:** `teamProjectsProvider`
- **Interactions:** Project search, project tile tap, branch picker, Browse directory button.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/wizard/spec_upload_step.dart`
- **Class:** `SpecUploadStep`
- **Type:** `StatefulWidget`
- **Constructor:** `{super.key, required List<SpecFile> files, required ValueChanged<List<SpecFile>> onFilesAdded, required ValueChanged<int> onFileRemoved}`
- **Purpose:** Drag-and-drop zone (desktop_drop) plus file picker for specification files (Markdown, YAML, JSON, PDF, images). Enforces 50 MB limit and accepted extensions. File list with remove capability.
- **Providers:** None
- **Interactions:** Drag-and-drop files, Browse button, remove file.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/wizard/threshold_step.dart`
- **Class:** `ThresholdStep`
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required JobConfig config, required ValueChanged<JobConfig> onConfigChanged}`
- **Purpose:** Configuration sliders for concurrent agents (1-6), timeout (5-60 min), max turns (10-100), Claude model dropdown, health score threshold bar with pass/warn number inputs, and additional context text field.
- **Providers:** None
- **Interactions:** All sliders, model dropdown, threshold inputs, additional context field.

**File:** `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/wizard/wizard_scaffold.dart`
- **Class:** `WizardScaffold` (plus `WizardStepDef` data class)
- **Type:** `StatelessWidget`
- **Constructor:** `{super.key, required String title, required List<WizardStepDef> steps, required int currentStep, VoidCallback? onBack, VoidCallback? onNext, VoidCallback? onLaunch, VoidCallback? onCancel, bool isLaunching, String launchLabel}`
- **Purpose:** Reusable multi-step wizard container with left sidebar step indicator (active/completed/pending states), main content area, top bar (title + Cancel with confirm dialog), and bottom nav bar (Back/Next/Launch buttons). Designed for Audit, Compliance, Bug Investigation, and Remediation wizard modes.
- **Providers:** None
- **Interactions:** Back button, Next button (disabled when step invalid), Launch button (final step), Cancel with confirmation dialog.

---

## Summary Statistics

| Subdirectory | File Count | Widget Classes | Non-Widget Classes |
|---|---|---|---|
| admin | 4 | 4 | 0 |
| compliance | 3 | 3 | 0 |
| dashboard | 4 | 4 | 0 |
| dependency | 4 | 4 | 0 |
| findings | 4 | 4 | 0 |
| health | 3 | 3 | 0 |
| jira | 11 | 11 | 0 |
| personas | 4 | 4 | 0 |
| progress | 9 | 9 | 0 |
| reports | 8 | 8 | 0 |
| scribe | 7 | 4 | 3 (controller, language util, theme data) |
| settings | 7 | 7 | 0 |
| shared | 8 | 8 | 0 |
| shell | 2 | 2 | 0 |
| tasks | 5 | 4 | 1 (top-level function) |
| tech_debt | 4 | 4 | 0 |
| vcs | 17 | 17 | 0 |
| wizard | 8 | 8 | 0 |
| **TOTAL** | **98** | **95** | **3** |

**Widget Type Distribution:**
- StatelessWidget: 39
- StatefulWidget: 15
- ConsumerWidget: 17
- ConsumerStatefulWidget: 24
- Non-widget (ChangeNotifier, utility, data): 3


---

## 15. Test Coverage

I now have all the data. Here is the complete audit report.

---

## CodeOps-Client Codebase Audit: Tests, TODOs, and Documentation Coverage

---

### 1. TEST COUNT SUMMARY

#### Test Files by Category

| Category | Files | Test Methods |
|---|---|---|
| **Unit Tests** | **90** | **1,501** |
| -- test/models/ | 20 | 390 |
| -- test/services/ | 46 | 748 |
| -- test/utils/ | 3 | 40 |
| -- test/providers/ | 21 | 323 |
| **Widget Tests** | **118** | **781** |
| -- test/widgets/ | 97 | 635 |
| -- test/pages/ | 21 | 146 |
| **Integration Tests** | **5** | **8** |
| -- integration_test/ | 5 | 8 |
| **Other Tests** | **6** | **45** |
| -- test/router/ | 1 | 4 |
| -- test/theme/ | 2 | 8 |
| -- test/database/ | 2 | 13 |
| -- test/integration/ | 1 | 20 |
| **TOTAL** | **219** | **2,335** |

#### Integration Test Breakdown (integration_test/)

| File | Tests |
|---|---|
| `dependency_flow_test.dart` | 2 |
| `directive_flow_test.dart` | 1 |
| `health_dashboard_flow_test.dart` | 2 |
| `persona_flow_test.dart` | 1 |
| `tech_debt_flow_test.dart` | 2 |

---

### 2. TODO / FIXME / HACK / XXX / WORKAROUND ITEMS

**Result: ZERO genuine TODO/FIXME/HACK/XXX/WORKAROUND comments found in `lib/`.**

Two grep matches were found but both are **string literals** inside application logic, not actionable code markers:

- `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/services/agent/agent_config_service.dart:427` -- String: `'Checks for missing features, TODOs, and incomplete implementations'` (description of the Completeness Agent)
- `/Users/adamallard/Documents/GitHub/CodeOps-Client/lib/widgets/progress/agent_card.dart:54` -- String: `'TODOs, stubs, placeholders, dead code'` (display description of the Completeness agent type)

Neither represents deferred work or a code deficiency.

---

### 3. DOCUMENTATION COVERAGE SUMMARY

| Metric | Count |
|---|---|
| Total `.dart` source files in `lib/` (non-generated) | 241 |
| Generated files excluded (`.g.dart` + `.freezed.dart`) | 16 |
| Files WITH at least one `///` doc comment | **241** |
| Files WITHOUT any `///` doc comment | **0** |
| **Documentation coverage** | **100%** |

Every non-generated Dart source file in `lib/` contains at least one DartDoc (`///`) comment.

---

### 4. OVERALL SUMMARY

- **219 test files** containing **2,335 test methods** across the entire project
- Unit tests dominate at **1,501 methods** (64.3%), followed by widget tests at **781 methods** (33.4%)
- Integration tests are minimal at **8 methods** across 5 files (0.3%)
- **Zero** actionable TODO/FIXME/HACK/XXX/WORKAROUND markers in source code
- **100%** documentation coverage on all 241 non-generated source files


---

## 16. Cross-Cutting Patterns

### 1. Riverpod DI Chain
`secureStorageProvider` -> `apiClientProvider` -> every `*ApiProvider` -> every `FutureProvider`. `selectedTeamIdProvider` is the hub for all team-scoped data.

### 2. Filter/Sort Pattern
Multiple domains (vulnerabilities, directives, personas, projects, tasks, tech debt, job history, GitHub repos) follow the same pattern: individual `StateProvider` filters combined into a derived `Provider` that does client-side filtering and sorting.

### 3. Wizard State Machine Pattern
Three wizards (Audit, Bug Investigator, Compliance) use identical `StateNotifier<XxxState>` pattern with step navigation, project selection with local path auto-detection, agent type selection, config management, and launch state tracking.

### 4. Agent Orchestration Pipeline
`AgentDispatcher` (spawns `claude` CLI) -> `AgentMonitor` (tracks processes) -> `ProgressAggregator` (real-time UI) -> `ReportParser` (markdown to data) -> `VeraManager` (deduplication + consolidation) -> API upload. Full pipeline managed by `JobOrchestrator`.

### 5. Serialization Patterns
- Server models: `@JsonSerializable()` + generated `.g.dart` with custom `@EnumNameConverter()` annotations
- VCS models: manual `fromGitHubJson()` / `fromGitJson()` / `fromGitLine()` factories
- Jira models: `@JsonSerializable()` with custom `_dynamicToString` for ADF fields
- Scribe models: manual `toJson()` / `fromJson()`
- AnthropicModelInfo: manual `fromApiJson()` + Drift `toDbCompanion()` / `fromDb()`
- All enums: SCREAMING_SNAKE_CASE serialization with companion JsonConverter classes

### 6. Logging
- Singleton `LogService` with 6 levels: verbose, debug, info, warning, error, fatal
- Tag-based filtering via `LogConfig.mutedTags`
- ANSI color console output in debug, daily-rotated file logging in release
- Environment-aware defaults: debug=console-only, release=file-logging at info level

### 7. Offline Support
- `SyncService` syncs projects between server and local Drift database
- Falls back to local cache on `NetworkException` / `TimeoutException`
- `SyncMetadata` table tracks last sync time per entity

---

## 17. Known Issues

**Result: ZERO genuine TODO/FIXME/HACK/XXX/WORKAROUND comments found in `lib/`.**

Two grep matches found are string literals in application logic, not actionable code markers:
- `lib/services/agent/agent_config_service.dart:427` -- String literal describing Completeness agent
- `lib/widgets/progress/agent_card.dart:54` -- String literal describing agent type display

### Duplicate Provider Names
- `findingApiProvider` is defined in both `finding_providers.dart` and `job_providers.dart`
- `jobFindingsProvider` is also defined in both files (with slightly different signatures)
- `jiraConnectionsProvider` is defined in both `jira_providers.dart` and `project_providers.dart`

---

## 18. Theme and Styling

### Theme Architecture
- **Dark-only** theme using `AppTheme.darkTheme` (no light mode)
- Font: **Inter** (primary), **JetBrains Mono** (code), fallback Fira Code
- All colors defined as static const in `CodeOpsColors`
- All text styles defined as static const in `CodeOpsTypography`

### Color Palette
| Token | Hex | Usage |
|---|---|---|
| background | `#1A1B2E` | Deep navy app background |
| surface | `#222442` | Card/panel background |
| surfaceVariant | `#2A2D52` | Elevated surface |
| primary | `#6C63FF` | Indigo/purple accent |
| primaryVariant | `#5A52D5` | Darker primary |
| secondary | `#00D9FF` | Cyan accent |
| success | `#4ADE80` | Green |
| warning | `#FBBF24` | Amber |
| error | `#EF4444` | Red |
| critical | `#DC2626` | Deep red |
| textPrimary | `#E2E8F0` | Near white |
| textSecondary | `#94A3B8` | Grey |
| textTertiary | `#64748B` | Dim grey |
| border | `#334155` | Subtle border |
| divider | `#1E293B` | Divider |

### Domain Color Maps
- `severityColors`: Map<Severity, Color> (4 entries)
- `jobStatusColors`: Map<JobStatus, Color> (5 entries)
- `agentTypeColors`: Map<AgentType, Color> (12 entries)
- `taskStatusColors`: Map<TaskStatus, Color> (5 entries)
- `debtStatusColors`: Map<DebtStatus, Color> (4 entries)
- `directiveCategoryColors`: Map<DirectiveCategory, Color> (5 entries)
- `vulnerabilityStatusColors`: Map<VulnerabilityStatus, Color> (4 entries)

### Typography Scale
12 text styles from headlineLarge (32px/w700) through labelSmall (11px/w500), plus a `code` style (JetBrains Mono, 13px/w400).

### Widget Theme Overrides
- Card: 0 elevation, 8px radius, 1px border
- AppBar: 0 elevation, not centered
- Input: filled, 8px radius, primary focus border
- ElevatedButton: primary bg, white fg, 8px radius
- Scrollbar: 0.3 alpha, 4px radius, 6px thickness

---

## 19. Assets

### Persona Files (13)

| File | Agent Type | Role |
|---|---|---|
| `agent-api-contract.md` | API_CONTRACT | API Design and Contract Compliance Reviewer |
| `agent-architecture.md` | ARCHITECTURE | Software Architecture and Structural Design Reviewer |
| `agent-build-health.md` | BUILD_HEALTH | Build Systems and CI/CD Specialist |
| `agent-code-quality.md` | CODE_QUALITY | Senior Code Reviewer |
| `agent-completeness.md` | COMPLETENESS | Implementation Completeness Auditor |
| `agent-database.md` | DATABASE | Database Design and Query Performance Analyst |
| `agent-dependency.md` | DEPENDENCY | Dependency Health and Supply Chain Security Analyst |
| `agent-documentation.md` | DOCUMENTATION | Documentation Quality Assessor |
| `agent-performance.md` | PERFORMANCE | Runtime Performance and Efficiency Analyst |
| `agent-security.md` | SECURITY | Application Security Analyst |
| `agent-test-coverage.md` | TEST_COVERAGE | Test Quality and Coverage Analyst |
| `agent-ui-ux.md` | UI_UX | Frontend Quality and Accessibility Specialist |
| `vera-manager.md` | ORCHESTRATOR | Review Manager and Executive Synthesizer |

### Template Files (5)
- `audit-report-template.md` -- Consolidated Audit Report
- `compliance-report-template.md` -- Compliance Gap Analysis Report
- `executive-summary-template.md` -- Executive Summary
- `rca-template.md` -- Root Cause Analysis Report

---

## 20. Inter-Service Communication

### CodeOps-Server API (~131 endpoints)

The client communicates with `http://localhost:8090/api/v1/` via 17 API service classes:

| Service | Prefix | Key Operations |
|---|---|---|
| Auth | `/auth/` | login, register, refresh, change-password |
| UserApi | `/users/` | getCurrentUser, getUserById, updateUser, searchUsers, activate/deactivate |
| TeamApi | `/teams/` | CRUD teams, members, invitations |
| ProjectApi | `/projects/` | CRUD projects, archive/unarchive |
| JobApi | `/jobs/` | CRUD jobs, agent runs, bug investigations |
| FindingApi | `/findings/` | CRUD findings, batch create, filter by severity/status/agent, bulk status |
| TaskApi | `/tasks/` | CRUD tasks, batch create, assigned-to-me |
| ReportApi | `/reports/` | Upload/download summary, agent, and spec reports |
| DirectiveApi | `/directives/` | CRUD directives, team/project scoping, assignment toggling |
| PersonaApi | `/personas/` | CRUD personas, team scoping, defaults, search by agent type |
| ComplianceApi | `/compliance/` | Specs, compliance items, batch create, summary |
| TechDebtApi | `/tech-debt/` | CRUD items, filter by status/category, summary |
| DependencyApi | `/dependencies/` | Scans, vulnerabilities, batch create, filter by severity |
| HealthMonitorApi | `/health-monitor/` | Schedules, snapshots, trends |
| MetricsApi | `/metrics/` | Team/project metrics, trends |
| AdminApi | `/admin/` | User management, settings, audit log, usage stats |
| IntegrationApi | `/integrations/` | GitHub/Jira connection CRUD |

### External APIs

| API | Base URL | Auth | Used By |
|---|---|---|---|
| Anthropic | `https://api.anthropic.com` | `x-api-key` header | `AnthropicApiService` -- model discovery and API key validation |
| GitHub REST v3 | `https://api.github.com` | Bearer token (PAT) | `GitHubProvider` -- orgs, repos, branches, PRs, commits, workflows, releases |
| Jira Cloud REST v3 | `https://<instance>.atlassian.net` | Basic Auth (email:apiToken) | `JiraService` -- issues, comments, transitions, projects, sprints, users |

### Local CLI
| Tool | Used By | Purpose |
|---|---|---|
| `claude` (Claude Code CLI) | `AgentDispatcher` | Spawns agent subprocesses with `--print --output-format stream-json --max-turns --model -p` |
| `git` | `GitService` | Clone, pull, push, status, diff, log, commit, merge, blame, stash, tag, branch |

---

## 21. Infrastructure

### Infrastructure Absent
This is a **desktop client application**. The following infrastructure concerns are managed by the server (CodeOps-Server), not by this client:

- Database hosting (PostgreSQL)
- Message queuing (Kafka)
- Caching (Redis)
- S3 object storage
- Container orchestration
- CI/CD pipelines
- Environment configuration beyond localhost defaults

### Client-Side Infrastructure
- **Local SQLite database** (`codeops.db`) managed by Drift with schema migrations
- **SharedPreferences** for credential and preference storage
- **File system** for cloned repos (`~/CodeOps/repos/`), log files, and exported reports
- **Window management** via window_manager plugin (macOS)
- **Process management** for spawning Claude Code CLI subprocesses

---

*End of audit. Generated from actual source files on disk. Every model, service, provider, page, widget, and configuration was read directly from the codebase.*
