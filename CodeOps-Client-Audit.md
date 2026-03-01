# CodeOps-Client — Codebase Audit

**Audit Date:** 2026-03-01T22:07:09Z
**Branch:** main
**Commit:** cfb887a63e00e038b119e5414e408c690cab8e5b DL-012: Query history + saved queries — history panel, bookmarks, save dialog, navigator bottom panel, 29 tests
**Auditor:** Claude Code (Automated)
**Purpose:** Zero-context reference for AI-assisted development
**Audit File:** CodeOps-Client-Audit.md
**Scorecard:** CodeOps-Client-Scorecard.md
**OpenAPI Spec:** CodeOps-Client-OpenAPI.yaml (generated separately)

> This audit is the source of truth for the CodeOps-Client codebase structure, entities, services, and configuration.
> The OpenAPI spec (CodeOps-Client-OpenAPI.yaml) is the source of truth for all endpoints, DTOs, and API contracts.
> An AI reading this audit + the OpenAPI spec should be able to generate accurate code
> changes, new features, tests, and fixes without filesystem access.

---

## 1. Project Identity

```
Project Name: CodeOps-Client
Repository URL: https://github.com/AI-CodeOps/CodeOps-Client.git
Primary Language / Framework: Dart / Flutter
Dart Version: 3.11.0
Flutter Version: 3.41.1 (stable channel)
Build Tool: Flutter CLI + build_runner (code generation)
Current Branch: main
Latest Commit Hash: cfb887a63e00e038b119e5414e408c690cab8e5b
Latest Commit Message: DL-012: Query history + saved queries — history panel, bookmarks, save dialog, navigator bottom panel, 29 tests
Audit Timestamp: 2026-03-01T22:07:09Z
```

---

## 2. Directory Structure

Single-module Flutter desktop application (macOS, Windows, Linux targets). Key directories:

```
CodeOps-Client/
├── lib/                          ← 561 hand-written Dart source files (172,622 LOC)
│   ├── main.dart                 ← Entry point
│   ├── app.dart                  ← Root widget (CodeOpsApp)
│   ├── router.dart               ← GoRouter with 64 routes
│   ├── database/                 ← Drift SQLite local cache (2 files)
│   ├── models/                   ← Domain models + enums (38 files)
│   ├── pages/                    ← Full-page route widgets (67 files)
│   │   ├── datalens/             ← DataLens database browser pages
│   │   ├── fleet/                ← Fleet Docker management pages
│   │   ├── registry/             ← Service Registry pages
│   │   └── relay/                ← Relay messaging page
│   ├── providers/                ← Riverpod providers (32 files)
│   ├── services/                 ← Business logic + API clients (65 files)
│   │   ├── agent/                ← Agent config, persona manager, report parser
│   │   ├── analysis/             ← Health calculator, dependency scanner, tech debt
│   │   ├── auth/                 ← Auth service + secure storage
│   │   ├── cloud/                ← All API clients (core, vault, registry, fleet, etc.)
│   │   ├── data/                 ← Scribe persistence, sync, diff services
│   │   ├── datalens/             ← Database connection, query execution, schema introspection
│   │   ├── integration/          ← Export service
│   │   ├── jira/                 ← Jira service + mapper
│   │   ├── logging/              ← Centralized logging (LogService, LogConfig, LogLevel)
│   │   ├── openapi_parser.dart   ← OpenAPI spec parser
│   │   ├── orchestration/        ← Job orchestrator, agent dispatcher/monitor, Vera manager
│   │   ├── platform/             ← Claude Code detector, process manager
│   │   └── vcs/                  ← Git service, GitHub provider, repo manager
│   ├── theme/                    ← Dark theme, colors, typography (3 files)
│   ├── utils/                    ← Constants, date/string/file utils, fuzzy matcher (6 files)
│   └── widgets/                  ← Reusable UI components (345 files)
│       ├── admin/                ← Admin hub tabs
│       ├── compliance/           ← Compliance wizard panels
│       ├── dashboard/            ← Home dashboard cards
│       ├── datalens/             ← DataLens browser widgets
│       ├── dependency/           ← Dependency scan widgets
│       ├── findings/             ← Findings explorer widgets
│       ├── fleet/                ← Fleet Docker widgets
│       ├── health/               ← Health dashboard panels
│       ├── jira/                 ← Jira browser widgets
│       ├── personas/             ← Persona editor/list widgets
│       ├── progress/             ← Job progress widgets
│       ├── registry/             ← Service Registry widgets
│       ├── relay/                ← Relay messaging widgets
│       ├── reports/              ← Report viewer widgets
│       ├── scribe/               ← Scribe code editor widgets
│       ├── settings/             ← Settings tabs
│       ├── shared/               ← Shared dialogs, empty states, errors
│       ├── shell/                ← Navigation shell + team switcher
│       ├── tasks/                ← Task manager widgets
│       ├── tech_debt/            ← Tech debt widgets
│       ├── vault/                ← Vault secret management widgets
│       ├── vcs/                  ← VCS/GitHub widgets
│       └── wizard/               ← Audit/compliance wizard steps
├── test/                         ← 443 unit test files (93,590 LOC with integration)
├── integration_test/             ← 5 integration test files
├── assets/
│   ├── personas/                 ← 14 agent persona markdown files
│   └── templates/                ← 5 report template markdown files
├── macos/                        ← macOS runner
├── windows/                      ← Windows runner
├── linux/                        ← Linux runner
├── pubspec.yaml                  ← Build manifest
└── analysis_options.yaml         ← Lint config
```

**Summary:** 561 hand-written source files, 24 generated (.g.dart) files, 172,622 LOC source, 29,753 LOC generated, 93,590 LOC tests. 448 total test files (443 unit + 5 integration).

---

## 3. Build & Dependency Manifest

**Path:** `pubspec.yaml`

### Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| flutter | SDK | UI framework |
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod code generation annotations |
| go_router | ^14.8.1 | Declarative routing |
| drift | ^2.22.1 | SQLite ORM (local cache) |
| sqlite3_flutter_libs | ^0.5.28 | SQLite native libraries |
| postgres | ^3.5.9 | PostgreSQL direct connections (DataLens) |
| dio | ^5.7.0 | HTTP client |
| flutter_markdown | ^0.7.6 | Markdown rendering |
| flutter_highlight | ^0.7.0 | Syntax highlighting |
| re_editor | ^0.8.0 | Code editor widget |
| re_highlight | ^0.0.3 | Editor syntax highlighting |
| fl_chart | ^0.70.2 | Charts and graphs |
| file_picker | ^8.1.7 | File selection dialogs |
| desktop_drop | ^0.5.0 | Drag-and-drop file support |
| window_manager | ^0.4.3 | Desktop window management |
| split_view | ^3.2.1 | Split pane layout |
| diff_match_patch | ^0.4.1 | Text diff algorithm |
| path | ^1.9.0 | Path manipulation |
| path_provider | ^2.1.5 | Platform directories |
| uuid | ^4.5.1 | UUID generation |
| intl | ^0.20.1 | Internationalization/date formatting |
| yaml | ^3.1.3 | YAML parsing |
| archive | ^4.0.2 | Archive file handling |
| url_launcher | ^6.3.1 | External URL opening |
| shared_preferences | ^2.3.4 | Key-value storage (auth tokens) |
| crypto | ^3.0.6 | Cryptographic hashing |
| package_info_plus | ^8.1.2 | App version info |
| connectivity_plus | ^6.1.1 | Network connectivity checking |
| json_annotation | ^4.9.0 | JSON serialization annotations |
| freezed_annotation | ^2.4.4 | Immutable model annotations |
| collection | ^1.19.0 | Collection utilities |
| equatable | ^2.0.7 | Value equality |
| pdf | ^3.11.2 | PDF generation |
| printing | ^5.13.4 | PDF printing/preview |

### Dev Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| build_runner | ^2.4.14 | Code generation runner |
| drift_dev | ^2.22.1 | Drift code generation |
| riverpod_generator | ^2.6.4 | Riverpod provider generation |
| json_serializable | ^6.9.0 | JSON serialization code gen |
| freezed | ^2.5.7 | Immutable model code gen |
| flutter_test | SDK | Widget testing |
| mocktail | ^1.0.4 | Mocking framework |
| integration_test | SDK | Integration testing |
| flutter_lints | ^5.0.0 | Lint rules |

### Build Commands

```
Build: flutter build macos (or windows/linux)
Test: flutter test
Test w/coverage: flutter test --coverage
Code gen: dart run build_runner build --delete-conflicting-outputs
Run (dev): flutter run -d macos
```

---

## 4. Configuration & Infrastructure Summary

### Application Configuration

- **No application.yml/properties** — this is a Flutter desktop app, not a Spring Boot service.
- **All configuration lives in `lib/utils/constants.dart`** — API base URLs, timeouts, limits, storage keys, and UI constants.
- **Key values:**
  - CodeOps-Server API: `http://localhost:8090/api/v1/`
  - Vault API: `http://localhost:8097/api/v1/vault`
  - Relay WebSocket: `ws://localhost:8090/ws/relay`
  - Fleet API prefix: `/fleet` (on CodeOps-Server)
  - JWT expiry: 24 hours
  - Refresh token expiry: 30 days
  - Default Claude model: `claude-sonnet-4-20250514`
  - Dispatch model: `claude-sonnet-4-5-20250514`
  - Anthropic API: `https://api.anthropic.com` (version `2023-06-01`)

### Local Database

- **Drift (SQLite)** via `lib/database/database.dart` and `lib/database/tables.dart`
- File: `<appSupportDir>/codeops.db`
- Schema version: 8 (with incremental migrations v1→v8)
- 25 tables mirroring server entities for offline caching

### Connection Map

```
Database: SQLite (local file via Drift) + PostgreSQL (remote via DataLens direct connections)
Cache: None (SQLite serves as local cache)
Message Broker: WebSocket (Relay real-time messaging to CodeOps-Server)
External APIs:
  - CodeOps-Server (http://localhost:8090) — all core, registry, fleet, courier, logger endpoints
  - CodeOps-Vault (http://localhost:8097) — vault secrets, policies, transit, seal
  - Anthropic API (https://api.anthropic.com) — model listing, agent dispatch
  - GitHub API (via GitHub PAT) — repos, branches, PRs, commits
  - Jira API (via Jira connections) — issues, projects, users
Cloud Services: None (all self-hosted)
```

### CI/CD

None detected.

---

## 5. Startup & Runtime Behavior

### Entry Point

`lib/main.dart` → `main()`:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `LogConfig.initialize()` — configures logging (debug vs release)
3. `windowManager.ensureInitialized()` — sets window size (1440×900), min (1024×700), centered, title "CodeOps", hidden title bar
4. `runApp(ProviderScope(child: CodeOpsApp()))` — starts the Riverpod-scoped app

### Root Widget

`lib/app.dart` → `CodeOpsApp`:
- Listens to `authStateProvider` stream
- On authentication: auto-selects user's team, seeds built-in agents, refreshes Anthropic model cache
- Uses `MaterialApp.router` with `AppTheme.darkTheme` and `GoRouter`

### Startup Sequence
- Auth state determines initial route: `/login` if unauthenticated, `/` if authenticated
- On login success: team auto-selected → agent configs seeded (13 built-in agents) → Anthropic models refreshed (background)
- No scheduled tasks or background jobs (desktop app)

### Health Check
- No local health endpoint (this is a desktop client)
- Server health verified by API calls during `tryAutoLogin()`

---

## 6. Entity / Data Model Layer

All models live in `lib/models/`. They use `@JsonSerializable()` (json_annotation) for server DTO mapping. Generated `.g.dart` files provide `fromJson`/`toJson`. Local SQLite cache tables are defined in `lib/database/tables.dart`.

### Core Models

```
=== User (lib/models/user.dart) ===
Fields: id (String), email (String), displayName (String), avatarUrl (String?),
        isActive (bool?), lastLoginAt (DateTime?), createdAt (DateTime?)
Cache Table: Users

=== Team (lib/models/team.dart) ===
Fields: id, name, description?, ownerId, ownerName?, teamsWebhookUrl?,
        memberCount?, createdAt?, updatedAt?
Cache Table: Teams

=== TeamMember (lib/models/team.dart) ===
Fields: id, userId, displayName?, email?, avatarUrl?, role (TeamRole), joinedAt?

=== Invitation (lib/models/team.dart) ===
Fields: id, email, role (TeamRole), status (InvitationStatus),
        invitedByName?, expiresAt?, createdAt?

=== Project (lib/models/project.dart) ===
Fields: id, teamId, name, description?, githubConnectionId?, repoUrl?,
        repoFullName?, defaultBranch?, jiraConnectionId?, jiraProjectKey?,
        jiraDefaultIssueType?, jiraLabels?, jiraComponent?, techStack?,
        healthScore?, lastAuditAt?, isArchived?, createdAt?, updatedAt?
Cache Table: Projects

=== QaJob (lib/models/qa_job.dart) ===
Fields: id, projectId, projectName?, mode (JobMode), status (JobStatus),
        name?, branch?, configJson?, summaryMd?, overallResult (AgentResult?),
        healthScore?, totalFindings?, criticalCount?, highCount?, mediumCount?,
        lowCount?, jiraTicketKey?, startedBy?, startedByName?,
        startedAt?, completedAt?, createdAt?
Cache Table: QaJobs

=== AgentRun (lib/models/agent_run.dart) ===
Fields: id, jobId, agentType (AgentType), status (AgentStatus),
        result (AgentResult?), reportS3Key?, score?, findingsCount?,
        criticalCount?, highCount?, startedAt?, completedAt?
Cache Table: AgentRuns

=== Finding (lib/models/finding.dart) ===
Fields: id, jobId, agentType (AgentType), severity (Severity), title,
        description?, filePath?, lineNumber?, recommendation?, evidence?,
        effortEstimate (EffortEstimate?), debtCategory (DebtCategory?),
        findingStatus (FindingStatus), statusChangedBy?, statusChangedAt?,
        createdAt?
Cache Table: Findings

=== RemediationTask (lib/models/remediation_task.dart) ===
Fields: id, jobId, taskNumber, title, description?, promptMd?,
        priority (TaskPriority?), status (TaskStatus), assignedTo?,
        assignedToName?, jiraKey?, createdAt?
Cache Table: RemediationTasks

=== Persona (lib/models/persona.dart) ===
Fields: id, name, agentType (AgentType?), description?, contentMd?,
        scope (PersonaScope), teamId?, createdBy?, createdByName?,
        isDefault?, version?, createdAt?, updatedAt?
Cache Table: Personas

=== Directive (lib/models/directive.dart) ===
Fields: id, name, description?, contentMd?, category (DirectiveCategory?),
        scope (DirectiveScope), teamId?, projectId?, createdBy?,
        createdByName?, version?, createdAt?, updatedAt?
Cache Table: Directives

=== TechDebtItem (lib/models/tech_debt_item.dart) ===
Fields: id, projectId, category (DebtCategory), title, description?,
        filePath?, effortEstimate (EffortEstimate?),
        businessImpact (BusinessImpact?), status (DebtStatus),
        firstDetectedJobId?, resolvedJobId?, createdAt?, updatedAt?
Cache Table: TechDebtItems

=== DependencyScan (lib/models/dependency_scan.dart) ===
Fields: id, projectId, jobId?, manifestFile?, totalDependencies?,
        outdatedCount?, vulnerableCount?, vulnerabilities (list), createdAt?
Cache Table: DependencyScans

=== HealthSnapshot (lib/models/health_snapshot.dart) ===
Fields: id, projectId, jobId?, healthScore, findingsBySeverity (Map?),
        techDebtScore?, dependencyScore?, testCoveragePercent?, capturedAt?
Cache Table: HealthSnapshots

=== ComplianceItem (lib/models/compliance_item.dart) ===
Fields: id, jobId, requirement, specId?, specName?,
        status (ComplianceStatus), evidence?, agentType?, notes?, createdAt?
Cache Table: ComplianceItems

=== Specification (lib/models/specification.dart) ===
Fields: id, jobId, name, specType (SpecificationType?), s3Key, createdAt?
Cache Table: Specifications
```

### Module-Specific Models (Freezed)

```
=== Courier Models (lib/models/courier_models.dart) ===
Uses @freezed. Contains: CourierCollection, CourierRequest, CourierEnvironment,
CourierFolder, CourierVariable, CourierResponse, CourierHistoryEntry,
CourierScript, CourierHeader, CourierQueryParam, CourierFormField, CourierAuth

=== Fleet Models (lib/models/fleet_models.dart) ===
Uses @freezed. Contains: FleetContainer, ContainerPort, PortBinding,
ContainerMount, MountConfig, ContainerNetworkSetting, DockerImage,
DockerVolume, DockerNetwork, ContainerStatsSnapshot, ContainerHealthCheck,
HealthCheckResult, ServiceProfile, SolutionProfile, WorkstationProfile

=== Registry Models (lib/models/registry_models.dart) ===
Uses @freezed. Contains: RegistryService, PortAllocation, ServiceDependency,
EnvironmentConfig, ConfigVariable, RegistrySolution, SolutionMember,
ServiceRoute, InfraResource, WorkstationProfile

=== Vault Models (lib/models/vault_models.dart) ===
Uses @freezed. Contains: VaultSecret, SecretVersion, VaultPolicy,
PolicyRule, PolicyBinding, TransitKey, DynamicLease, SealStatusResponse,
VaultAuditEntry, RotationPolicy, RotationEvent

=== Relay Models (lib/models/relay_models.dart) ===
Uses @freezed. Contains: RelayChannel, RelayMessage, RelayReaction,
RelayMember, RelayConversation, RelayEvent, RelayFile, RelayPresence

=== Scribe Models (lib/models/scribe_models.dart) ===
Uses @freezed. Contains: ScribeTab, ScribeEditorSettings

=== DataLens Models (lib/models/datalens_models.dart) ===
Uses @freezed. Contains: DatabaseConnection, SchemaInfo, TableInfo,
ColumnInfo, IndexInfo, ConstraintInfo, ForeignKeyInfo, QueryResult,
QueryHistoryEntry, SavedQuery

=== Logger Models (lib/models/logger_models.dart) ===
Uses @JsonSerializable. Contains: LogSourceResponse, LogEntryResponse,
LogQueryRequest, DslQueryRequest, LogTrapResponse, SavedQueryResponse, etc.

=== Jira Models (lib/models/jira_models.dart) ===
Uses @JsonSerializable. Contains: JiraConnection, JiraProject, JiraIssue,
JiraUser, JiraTransition, JiraComment, etc.

=== MCP Models (lib/models/mcp_models.dart) ===
Uses @freezed. Contains: McpServer, McpTool, McpResource, McpPrompt,
McpServerStatus, ToolCallResult

=== VCS Models (lib/models/vcs_models.dart) ===
Uses @freezed. Contains: GitHubRepo, GitHubBranch, GitHubCommit,
GitHubPullRequest, GitHubOrg, GitBranch, GitCommit, GitDiff, GitStash

=== OpenAPI Spec Model (lib/models/openapi_spec.dart) ===
Contains: OpenApiSpec, PathItem, Operation, Parameter, SchemaObject,
RequestBody, ApiResponse
```

---

## 7. Enum Inventory

All enums live in `lib/models/enums.dart` with SCREAMING_SNAKE_CASE JSON serialization matching the server.

### Core Enums (enums.dart)

```
AgentResult: PASS, WARN, FAIL
AgentStatus: PENDING, RUNNING, COMPLETED, FAILED
AgentType: SECURITY, CODE_QUALITY, BUILD_HEALTH, COMPLETENESS, API_CONTRACT,
           TEST_COVERAGE, UI_UX, DOCUMENTATION, DATABASE, PERFORMANCE,
           DEPENDENCY, ARCHITECTURE
BusinessImpact: LOW, MEDIUM, HIGH, CRITICAL
ComplianceStatus: COMPLIANT, NON_COMPLIANT, PARTIAL, NOT_ASSESSED
DebtCategory: CODE_QUALITY, ARCHITECTURE, TESTING, DOCUMENTATION, DEPENDENCY,
              SECURITY, PERFORMANCE, INFRASTRUCTURE
DebtStatus: IDENTIFIED, PLANNED, IN_PROGRESS, RESOLVED
DirectiveCategory: ARCHITECTURE, STANDARDS, CONVENTIONS, CONTEXT, OTHER
DirectiveScope: GLOBAL, TEAM, PROJECT
EffortEstimate: TRIVIAL, SMALL, MEDIUM, LARGE, EXTRA_LARGE
FindingStatus: OPEN, ACCEPTED, REJECTED, FIXED
InvitationStatus: PENDING, ACCEPTED, DECLINED, EXPIRED, REVOKED
JobMode: FULL_AUDIT, TARGETED, BUG_INVESTIGATION, COMPLIANCE
JobStatus: PENDING, RUNNING, COMPLETED, FAILED, CANCELLED
PersonaScope: GLOBAL, TEAM
Severity: CRITICAL, HIGH, MEDIUM, LOW
SpecificationType: OPENAPI, REQUIREMENT_DOC, COMPLIANCE_SPEC, ARCHITECTURE_DOC, OTHER
TaskPriority: CRITICAL, HIGH, MEDIUM, LOW
TaskStatus: PENDING, ASSIGNED, EXPORTED, JIRA_CREATED, COMPLETED
TeamRole: OWNER, ADMIN, LEAD, MEMBER, VIEWER
VulnerabilityStatus: OPEN, UPDATING, SUPPRESSED, RESOLVED
```

### Module Enums

```
Courier (courier_enums.dart): AuthType (10 values), BodyType (10 values), ScriptType (2 values)
Fleet (fleet_enums.dart): ContainerState, ContainerHealth, MountType, NetworkDriver,
    VolumeDriver, RestartPolicy, ServiceProfileStatus, SolutionProfileStatus
Registry (registry_enums.dart): ServiceType, ServiceStatus, HealthStatus, DependencyType,
    SolutionStatus, SolutionCategory, SolutionMemberRole, RouteMethod, InfraResourceType
Vault (vault_enums.dart): SecretType, SealStatus, PolicyPermission, BindingType,
    RotationStrategy, LeaseStatus, AuditOperation, TransitKeyType
Relay (relay_enums.dart): ChannelType, MessageType, EventType, PresenceStatus, MemberRole
Logger (logger_enums.dart): LogLevel, LogSourceType, TrapSeverity, TrapStatus
MCP (mcp_enums.dart): McpTransport, McpServerStatus, ToolCategory
DataLens (datalens_enums.dart): DatabaseDriver, QueryStatus
```

---

## 8. Repository Layer

No traditional repository layer. Local data access uses:
- **Drift database** (`CodeOpsDatabase`) for SQLite CRUD with generated queries
- **API clients** in `lib/services/cloud/` for server data access

---

## 9. Service Layer — Full Method Signatures

### Authentication

```
=== AuthService (lib/services/auth/auth_service.dart) ===
Injects: ApiClient, SecureStorageService, CodeOpsDatabase
Public Methods:
  - login(String email, String password): Future<User>
  - register(String email, String password, String displayName): Future<User>
  - refreshToken(): Future<void>
  - changePassword(String currentPassword, String newPassword): Future<void>
  - logout(): Future<void>
  - tryAutoLogin(): Future<void>
  - dispose(): void
Properties: authStateStream (Stream<AuthState>), currentState, currentUser

=== SecureStorageService (lib/services/auth/secure_storage.dart) ===
Backend: SharedPreferences (not Keychain — avoids macOS password dialogs)
Public Methods:
  - getAuthToken() / setAuthToken(String)
  - getRefreshToken() / setRefreshToken(String)
  - getCurrentUserId() / setCurrentUserId(String)
  - getSelectedTeamId() / setSelectedTeamId(String)
  - getAnthropicApiKey() / setAnthropicApiKey(String) / deleteAnthropicApiKey()
  - read(String key) / write(String key, String value) / delete(String key)
  - clearAll(): preserves remember-me + Anthropic API key
```

### Cloud API Clients

```
=== ApiClient (lib/services/cloud/api_client.dart) ===
Base URL: http://localhost:8090/api/v1
Interceptors: Auth (JWT attach), Refresh (401 → token refresh → retry),
              Error (HTTP → typed ApiException), Logging (correlation IDs)
Public Methods: get<T>, post<T>, put<T>, delete<T>, uploadFile<T>, downloadFile
Public paths (no auth): /auth/login, /auth/register, /auth/refresh, /health

=== API Service Clients (all in lib/services/cloud/) ===
Each wraps ApiClient and provides typed methods:
  - AdminApi: getSettings, updateSetting, getUsageStats, getAuditLog
  - AnthropicApiService: listModels (direct Anthropic API call)
  - ComplianceApi: getItems, createItem, updateItem
  - CourierApi: collection/request/environment/folder CRUD
  - DependencyApi: getScans, getScan, getVulnerabilities
  - DirectiveApi: getDirectives, createDirective, updateDirective, deleteDirective
  - FindingApi: getFindings, updateStatus, bulkUpdateStatus
  - FleetApi: containers, images, volumes, networks, service/solution/workstation profiles
  - HealthMonitorApi: getSnapshots, getLatestSnapshot, getSchedule, updateSchedule
  - IntegrationApi: getGitHubConnection, connectGitHub, connectJira
  - JobApi: createJob, getJob, getJobs, getJobReport
  - LoggerApi: log sources, entries, traps, saved queries, query history
  - McpApi: servers, tools, resources, prompts
  - MetricsApi: getDashboard, getAgentMetrics
  - PersonaApi: getPersonas, createPersona, updatePersona, deletePersona
  - ProjectApi: getProjects, getProject, createProject, updateProject
  - RegistryApi: services, solutions, dependencies, routes, ports, infra, workstations, config
  - RegistryApiClient: separate Dio instance for /api/v1/registry/ base
  - RelayApi: channels, messages, reactions, DMs, events, files
  - RelayWebSocketService: WebSocket connection for real-time messaging
  - ReportApi: getReport, downloadReport
  - TaskApi: getTasks, updateTask, exportTask
  - TeamApi: getTeams, createTeam, getMembers, invite, removeTeam
  - TechDebtApi: getItems, createItem, updateItem
  - UserApi: getCurrentUser, updateProfile, getUsers
  - VaultApi: secrets, policies, transit, dynamic, seal, audit, rotation
  - VaultApiClient: separate Dio instance for http://localhost:8097/api/v1/vault
```

### Analysis Services

```
=== HealthCalculator (lib/services/analysis/health_calculator.dart) ===
Calculates weighted health scores from agent results, with configurable weights
(Security/Architecture = 1.5x, others = 1.0x).

=== DependencyScanner (lib/services/analysis/dependency_scanner.dart) ===
Parses dependency manifests and checks for outdated/vulnerable packages.

=== TechDebtTracker (lib/services/analysis/tech_debt_tracker.dart) ===
Extracts tech debt items from findings, deduplicates, and tracks over time.
```

### Orchestration Services

```
=== JobOrchestrator (lib/services/orchestration/job_orchestrator.dart) ===
Coordinates QA jobs: creates the job, dispatches agents, monitors progress.

=== AgentDispatcher (lib/services/orchestration/agent_dispatcher.dart) ===
Spawns Claude Code subprocesses for each agent with configured model, persona, and max turns.

=== AgentMonitor (lib/services/orchestration/agent_monitor.dart) ===
Polls agent run status and emits progress updates.

=== VeraManager (lib/services/orchestration/vera_manager.dart) ===
QA manager agent that reviews and aggregates all agent results.

=== ProgressAggregator (lib/services/orchestration/progress_aggregator.dart) ===
Combines per-agent progress into overall job progress.

=== BugInvestigationOrchestrator (lib/services/orchestration/bug_investigation_orchestrator.dart) ===
Specialized orchestrator for bug investigation mode.
```

### Agent Services

```
=== AgentConfigService (lib/services/agent/agent_config_service.dart) ===
Manages 13 built-in agent definitions in the local database. Seeds on first launch.

=== PersonaManager (lib/services/agent/persona_manager.dart) ===
Loads persona markdown from assets or database for agent dispatch.

=== ReportParser (lib/services/agent/report_parser.dart) ===
Parses agent output into structured findings.

=== TaskGenerator (lib/services/agent/task_generator.dart) ===
Generates remediation tasks from findings.
```

### Data Services

```
=== ScribeDiffService (lib/services/data/scribe_diff_service.dart) ===
Computes line-level diffs between file versions using diff_match_patch.

=== ScribeFileService (lib/services/data/scribe_file_service.dart) ===
Reads/writes files from/to disk for the Scribe editor.

=== ScribePersistenceService (lib/services/data/scribe_persistence_service.dart) ===
Persists Scribe tabs and settings to the local Drift database.

=== SyncService (lib/services/data/sync_service.dart) ===
Synchronizes local database cache with server data.
```

### DataLens Services

```
=== DatabaseConnectionService (lib/services/datalens/database_connection_service.dart) ===
Manages PostgreSQL connections using the postgres package.

=== QueryExecutionService (lib/services/datalens/query_execution_service.dart) ===
Executes SQL queries against connected databases and returns typed results.

=== SchemaIntrospectionService (lib/services/datalens/schema_introspection_service.dart) ===
Queries PostgreSQL information_schema for tables, columns, indexes, constraints.

=== QueryHistoryService (lib/services/datalens/query_history_service.dart) ===
Persists query history and saved queries to local database.
```

### Platform Services

```
=== ClaudeCodeDetector (lib/services/platform/claude_code_detector.dart) ===
Detects installed Claude Code CLI and validates minimum version.

=== ProcessManager (lib/services/platform/process_manager.dart) ===
Manages Claude Code subprocess lifecycle (spawn, kill, output streaming).
```

### VCS Services

```
=== GitService (lib/services/vcs/git_service.dart) ===
Local git operations via Process (clone, pull, branch, commit, diff, stash).

=== GitHubProvider (lib/services/vcs/github_provider.dart) ===
GitHub API client for repos, branches, PRs, commits (via PAT).

=== RepoManager (lib/services/vcs/repo_manager.dart) ===
Manages cloned repository registry in the local database.
```

---

## 10. Controller / API Layer — Method Signatures Only

Not applicable — this is a Flutter client app. No controllers. API communication is through service classes in `lib/services/cloud/`.

---

## 11. Security Configuration

```
Authentication: JWT Bearer token (obtained from CodeOps-Server /auth/login)
Token storage: SharedPreferences (not Keychain — see SecureStorageService docs)
Token refresh: Automatic via ApiClient refresh interceptor on 401

Public paths (no auth): /auth/login, /auth/register, /auth/refresh, /health
Protected: All other API calls require Bearer token

CORS: N/A (desktop app, not browser)
CSRF: N/A
Rate limiting: Client handles 429 responses via RateLimitException with Retry-After parsing
```

---

## 12. Custom Security Components

```
=== ApiClient Auth Interceptor ===
Attaches JWT from SecureStorageService to all non-public requests.

=== ApiClient Refresh Interceptor ===
On 401: reads refresh token → calls /auth/refresh → stores new tokens → retries original request.
Uses separate Dio instance for refresh to avoid interceptor loops.
On refresh failure: triggers onAuthFailure → AuthService sets unauthenticated.

=== ApiClient Error Interceptor ===
Maps HTTP status codes to sealed ApiException subclasses.

=== AuthNotifier (lib/router.dart) ===
ChangeNotifier that bridges AuthService stream to GoRouter for reactive redirects.
```

---

## 13. Exception Handling & Error Responses

```
=== ApiException Hierarchy (lib/services/cloud/api_exceptions.dart) ===
Sealed class hierarchy:
  - BadRequestException (400) — with optional field errors map
  - UnauthorizedException (401)
  - ForbiddenException (403)
  - NotFoundException (404)
  - ConflictException (409)
  - ValidationException (422) — with optional field errors map
  - RateLimitException (429) — with Retry-After seconds
  - ServerException (500+) — with status code
  - NetworkException (null status) — connectivity failure
  - TimeoutException (null status) — request timeout
```

---

## 14. Mappers / DTOs

No explicit mapper layer. Models use `@JsonSerializable()` or `@freezed` with generated `fromJson`/`toJson`. Conversion between server DTOs and local Drift table rows happens inline in services.

---

## 15. Utility Classes & Shared Components

```
=== AppConstants (lib/utils/constants.dart) ===
All magic numbers and config values. 140+ constants covering API URLs, limits, UI dimensions, storage keys.

=== CodeOpsDateUtils (lib/utils/date_utils.dart) ===
Methods: formatRelative, formatAbsolute, formatDuration

=== StringUtils (lib/utils/string_utils.dart) ===
Methods: truncate, capitalize, toSlug, sanitizeFilename

=== FileUtils (lib/utils/file_utils.dart) ===
Methods: readFile, writeFile, fileExists, formatFileSize

=== FuzzyMatcher (lib/utils/fuzzy_matcher.dart) ===
Methods: match — fuzzy string matching for search/filter

=== MarkdownHeadingParser (lib/utils/markdown_heading_parser.dart) ===
Methods: parse — extracts heading tree from markdown for TOC generation
```

---

## 16. Database Schema (Live)

### Local SQLite (Drift)

25 tables defined in `lib/database/tables.dart`:

| Table | Primary Key | Purpose |
|---|---|---|
| Users | id (TEXT) | Cached user profiles |
| Teams | id (TEXT) | Cached teams |
| Projects | id (TEXT) | Cached projects |
| QaJobs | id (TEXT) | Cached QA jobs |
| AgentRuns | id (TEXT) | Cached agent runs |
| Findings | id (TEXT) | Cached findings |
| RemediationTasks | id (TEXT) | Cached remediation tasks |
| Personas | id (TEXT) | Cached personas |
| Directives | id (TEXT) | Cached directives |
| TechDebtItems | id (TEXT) | Cached tech debt items |
| DependencyScans | id (TEXT) | Cached dependency scans |
| DependencyVulnerabilities | id (TEXT) | Cached CVEs |
| HealthSnapshots | id (TEXT) | Cached health snapshots |
| ComplianceItems | id (TEXT) | Cached compliance items |
| Specifications | id (TEXT) | Cached specifications |
| SyncMetadata | syncTableName (TEXT) | Last sync time per table |
| ClonedRepos | repoFullName (TEXT) | Local git clone registry |
| AnthropicModels | id (TEXT) | Cached Anthropic model metadata |
| AgentDefinitions | id (TEXT) | Agent configuration (13 built-in) |
| AgentFiles | id (TEXT) | Agent persona/prompt files |
| ProjectLocalConfig | projectId (TEXT) | Per-machine project paths |
| ScribeTabs | id (TEXT) | Open editor tabs |
| ScribeSettings | key (TEXT) | Editor settings (JSON) |
| DatalensConnections | id (TEXT) | Saved database connections |
| DatalensQueryHistory | id (TEXT) | SQL query history |
| DatalensSavedQueries | id (TEXT) | Bookmarked queries |

Server database access via DataLens uses direct PostgreSQL connections (postgres package).

---

## 17. Message Broker Configuration

WebSocket connection for Relay real-time messaging:
- URL: `ws://localhost:8090/ws/relay`
- Service: `RelayWebSocketService` (`lib/services/cloud/relay_websocket_service.dart`)
- Heartbeat: 30 seconds
- Reconnect backoff: max 30 seconds
- Used for: channel messages, DMs, reactions, presence, events

No traditional message broker (RabbitMQ/Kafka) on the client side.

---

## 18. Cache Layer

- **Local SQLite cache** via Drift — mirrors server entities for offline access
- **SyncMetadata table** tracks last sync time per table with optional ETag
- **No Redis or Caffeine** — desktop app uses SQLite as its cache layer
- Cache cleared on logout via `CodeOpsDatabase.clearAllTables()`

---

## 19. Environment Variable Inventory

No environment variables. All configuration is hardcoded in `AppConstants`. API keys (Anthropic, GitHub PAT) are stored in SharedPreferences at runtime.

---

## 20. Service Dependency Map

```
CodeOps-Client → Depends On:
  - CodeOps-Server (http://localhost:8090) — core API, registry, fleet, courier, logger, relay
  - CodeOps-Vault (http://localhost:8097) — vault secrets, policies, transit, seal, audit, rotation
  - Anthropic API (https://api.anthropic.com) — model listing
  - GitHub API (via PAT) — repos, branches, PRs
  - Jira API (via connection) — issues, projects
  - PostgreSQL databases (via DataLens) — direct SQL execution

Downstream Consumers: None (this is the desktop client UI)
```

---

## 21. Known Technical Debt & Issues

| Issue | Location | Severity | Notes |
|---|---|---|---|
| Doc coverage at 53.3% | 846 undocumented classes/enums/mixins across codebase | CRITICAL | BLOCKING — must be 100% per CONVENTIONS.md |
| Test line coverage at 54.8% | coverage/lcov.info | CRITICAL | BLOCKING — must be 100% per CONVENTIONS.md |
| PlaceholderPage still in router | lib/pages/placeholder_page.dart, router.dart:127 | Low | `/setup` route uses PlaceholderPage |
| No CI/CD pipeline | Project root | Medium | No .github/workflows or equivalent |
| Hardcoded API URLs | lib/utils/constants.dart | Medium | All URLs hardcoded, no env var support |
| SharedPreferences for tokens | lib/services/auth/secure_storage.dart | Low | Intentional for dev — move to Keychain for production |

**TODO/FIXME/Placeholder Scan Results:** No actual TODO/FIXME/XXX markers found in source code. References to "placeholder" in code are either: (1) UI placeholder text in input fields, (2) DartDoc describing that a widget replaced a previous placeholder, or (3) agent descriptions referencing what agents check for. **No incomplete implementations detected.**

---

## 22. Security Vulnerability Scan (Snyk)

Scan Date: 2026-03-01T22:07:09Z
Snyk CLI Version: Available (installed via npm)

### Dependency Vulnerabilities (Open Source)
Critical: 0
High: 0
Medium: 0
Low: 0

**PASS — No known vulnerabilities in dependencies.**

### Code Vulnerabilities (SAST)
**PASS — No code vulnerabilities detected.**

### IaC Findings
N/A — No Dockerfile or docker-compose in this project.

---

## Centralized Logging

```
=== LogService (lib/services/logging/log_service.dart) ===
Singleton accessed via top-level `log` getter.
Levels: verbose, debug, info, warning, error, fatal
Format: [HH:MM:SS.mmm] [LEVEL] [Tag] Message
Features:
  - ANSI colors in debug builds
  - Daily rotated file logging in release builds (7-day retention)
  - Tag-based muting
  - Level gating via LogConfig.minimumLevel
  - Sensitive data contract: callers must NOT pass tokens/passwords

=== LogConfig (lib/services/logging/log_config.dart) ===
Debug: level=debug, console colors=on, file logging=off
Release: level=info, console colors=off, file logging=on
Log dir: <appSupportDir>/logs (release) or ./logs (debug)
```

---

## Theme & UI

```
=== AppTheme (lib/theme/app_theme.dart) ===
Dark theme only. Uses CodeOpsColors and CodeOpsTypography.

=== CodeOpsColors (lib/theme/colors.dart) ===
Background: #1A1B2E (deep navy), Surface: #222442, Primary: #6C63FF (indigo),
Secondary: #00D9FF (cyan), Success: #4ADE80, Warning: #FBBF24, Error: #EF4444.
Maps for: Severity, JobStatus, AgentType, TaskStatus, DebtStatus,
DirectiveCategory, VulnerabilityStatus, SecretType, SealStatus,
PolicyPermission, BindingType, RotationStrategy, LeaseStatus,
ServiceStatus, HealthStatus, SolutionStatus, SolutionCategory, SolutionMemberRole.
Diff editor colors: diffAdded, diffRemoved, diffModified + highlights.

=== NavigationShell (lib/widgets/shell/navigation_shell.dart) ===
Collapsible sidebar (64/240px) + top bar + content area.
Sections: NAVIGATE, SOURCE, DEVELOP, ANALYZE, MAINTAIN, MONITOR, TEAM,
VAULT, REGISTRY, FLEET, DATALENS, COMMUNICATE.
Bottom: Settings, Admin (role-gated), User profile with logout/team switch.
```

---

## Router (64 Routes)

All routes defined in `lib/router.dart`. Auth redirect: unauthenticated → `/login`, authenticated on `/login` → `/`.

| # | Path | Page | Notes |
|---|---|---|---|
| 1 | /login | LoginPage | Outside shell |
| 2 | /setup | PlaceholderPage | Outside shell |
| 3 | / | HomePage | Dashboard |
| 4 | /projects | ProjectsPage | |
| 5 | /projects/:id | ProjectDetailPage | |
| 6 | /repos | GitHubBrowserPage | |
| 7 | /scribe | ScribePage | Code editor |
| 8 | /audit | AuditWizardPage | |
| 9 | /compliance | ComplianceWizardPage | |
| 10 | /dependencies | DependencyScanPage | |
| 11 | /bugs | BugInvestigatorPage | ?jiraKey= optional |
| 12 | /bugs/jira | JiraBrowserPage | |
| 13 | /tasks | TaskManagerPage | |
| 14 | /tech-debt | TechDebtPage | |
| 15 | /health | HealthDashboardPage | |
| 16 | /history | JobHistoryPage | |
| 17 | /jobs/:id | JobProgressPage | |
| 18 | /jobs/:id/report | JobReportPage | |
| 19 | /jobs/:id/findings | FindingsExplorerPage | |
| 20 | /jobs/:id/tasks | TaskListPage | |
| 21 | /personas | PersonasPage | |
| 22 | /personas/:id/edit | PersonaEditorPage | |
| 23 | /directives | DirectivesPage | |
| 24 | /settings | SettingsPage | |
| 25 | /admin | AdminHubPage | |
| 26-32 | /vault/* | Vault pages | Dashboard, secrets, policies, transit, dynamic, rotation, seal, audit |
| 33-48 | /registry/* | Registry pages | Services, solutions, dependencies, topology, infra, routes, config, ports, workstations, API docs |
| 49-60 | /fleet/* | Fleet pages | Dashboard, containers, service/solution/workstation profiles, images, volumes, networks |
| 61 | /datalens | DatalensPage | Database browser |
| 62-65 | /relay/* | Relay pages | Messaging shell, channels, threads, DMs |
