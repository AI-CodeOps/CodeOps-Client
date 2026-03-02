# CodeOps-Client — Codebase Audit

**Audit Date:** 2026-03-02T01:00:00Z
**Branch:** main
**Commit:** d477b3c3cbe736380c940bb618088411f41865da
**Auditor:** Claude Code (Automated)
**Purpose:** Zero-context reference for AI-assisted development
**Audit File:** CodeOps-Client-Audit.md
**Scorecard:** CodeOps-Client-Scorecard.md
**OpenAPI Spec:** N/A (Flutter desktop client — no server-side API)

> This audit is the source of truth for the CodeOps-Client codebase structure, models, services, providers, and configuration.
> An AI reading this audit should be able to generate accurate code changes, new features, tests, and fixes without filesystem access.

---

## 1. Project Identity

```
Project Name: CodeOps-Client (codeops)
Repository URL: https://github.com/AI-CodeOps/CodeOps-Client.git
Primary Language / Framework: Dart / Flutter (Desktop — macOS, Linux, Windows)
Dart SDK: ^3.6.0
Flutter: >=3.27.0
Build Tool: Flutter CLI + build_runner for code generation
Current Branch: main
Latest Commit Hash: d477b3c3cbe736380c940bb618088411f41865da
Audit Timestamp: 2026-03-02T01:00:00Z
```

---

## 2. Directory Structure

```
lib/
├── main.dart                    ← Entry point
├── app.dart                     ← Root ConsumerWidget (CodeOpsApp)
├── router.dart                  ← GoRouter with ~80 routes
├── database/
│   ├── database.dart            ← Drift DB (25 tables, schema v8)
│   └── tables.dart              ← Drift table definitions
├── models/                      ← 38 model files (~280 classes, ~85 enums)
│   ├── enums/                   ← Enum-only files
│   └── (feature models)         ← json_serializable data classes
├── services/                    ← 65 service files
│   ├── agent/                   ← Agent config, persona manager, report parser, task generator
│   ├── analysis/                ← Health calculator, dependency scanner, tech debt tracker
│   ├── auth/                    ← AuthService, SecureStorageService
│   ├── cloud/                   ← 29 API clients (Dio-based)
│   ├── data/                    ← Scribe persistence, sync service
│   ├── datalens/                ← DB connection, query execution, schema introspection
│   ├── integration/             ← Export service
│   ├── jira/                    ← JiraService, JiraMapper
│   ├── logging/                 ← LogService, LogConfig
│   ├── orchestration/           ← Job orchestrator, agent dispatcher/monitor
│   ├── platform/                ← Claude Code detector, process manager
│   └── vcs/                     ← Git service, GitHub provider, repo manager
├── providers/                   ← 32 provider files (~450+ Riverpod providers)
├── pages/                       ← 80 page files
│   ├── (core pages)             ← Home, Login, Projects, Settings, Admin
│   ├── datalens/                ← DataLens DB browser
│   ├── fleet/                   ← Docker management
│   ├── logger/                  ← Log aggregation
│   ├── registry/                ← Service registry
│   ├── relay/                   ← Team messaging
│   └── vault_*.dart             ← Secret management
├── widgets/                     ← 372 widget files across 24 directories
├── theme/                       ← Dark theme (colors, typography, app_theme)
└── utils/                       ← Constants, date/string/file utils, fuzzy matcher
test/                            ← 478 test files (5,751 tests, all passing)
integration_test/                ← 5 integration test files
```

**Summary:** Single-package Flutter desktop app with feature-based organization. Source layer hierarchy: `models → services → providers → pages/widgets`. All code generation via `build_runner` with `json_serializable` and `drift_dev`.

**Codebase Scale:**
- Source files (lib/, non-generated): 600
- Generated files (.g.dart): 24
- Test files: 478
- Integration test files: 5
- LOC (lib/): 186,176
- LOC (test/): 98,598

---

## 3. Build & Dependency Manifest

**Path:** `pubspec.yaml`

### Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| flutter_riverpod | ^2.6.1 | State management (all providers) |
| go_router | ^14.8.1 | Declarative routing (~80 routes) |
| drift | ^2.22.1 | Local SQLite database (25 tables) |
| dio | ^5.7.0 | HTTP client for all API calls |
| json_annotation | ^4.9.0 | JSON serialization annotations |
| shared_preferences | ^2.3.4 | Token/credential storage |
| postgres | ^3.4.5 | Direct PostgreSQL connections (DataLens) |
| fl_chart | ^0.70.2 | Charts (health trends, severity, metrics) |
| re_editor | ^0.7.0 | Code editor (Scribe module) |
| flutter_markdown | ^0.7.6+2 | Markdown rendering |
| flutter_highlight | ^0.7.0 | Syntax highlighting in code blocks |
| web_socket_channel | ^3.0.2 | WebSocket for Relay real-time messaging |
| window_manager | ^0.4.3 | Desktop window management |
| file_picker | ^8.1.7 | File open/save dialogs |
| desktop_drop | ^0.5.0 | Drag-and-drop file support |
| archive | ^4.0.2 | ZIP archive creation (export) |
| pdf | ^3.11.2 | PDF report generation |
| diff_match_patch | ^0.4.1 | Text diffing (Scribe diff editor) |
| path_provider | ^2.1.5 | App support directory paths |
| path | ^1.9.1 | Path manipulation |
| collection | ^1.19.1 | Collection utilities |
| intl | ^0.19.0 | Date/number formatting |
| url_launcher | ^6.3.1 | External URL opening |
| flutter_lints | ^5.0.0 | Lint rules |

### Dev Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| build_runner | ^2.4.14 | Code generation orchestrator |
| drift_dev | ^2.22.1 | Drift code generator |
| json_serializable | ^6.9.1 | JSON serialization generator |
| mocktail | ^1.0.4 | Test mocking framework |

### Build Commands

```
Build:     flutter build macos / flutter build linux / flutter build windows
Test:      flutter test
Run:       flutter run -d macos
CodeGen:   dart run build_runner build --delete-conflicting-outputs
Package:   flutter build macos --release
```

---

## 4. Configuration & Infrastructure Summary

### AppConstants (`lib/utils/constants.dart`)
- **CodeOps Server:** `http://localhost:8090` (API prefix: `/api/v1/`)
- **Vault Server:** `http://localhost:8097` (API prefix: `/api/v1/vault/`)
- **Relay WebSocket:** `ws://localhost:8090/ws/relay`
- **Relay heartbeat interval:** 30 seconds
- **Fleet polling interval:** 5 seconds
- **Agent timeout default:** 30 minutes
- **Max concurrent agents:** 3
- **Default Claude model:** `claude-sonnet-4-20250514`

### Connection Map
```
Database (local):   SQLite via Drift (file: codeops.db in app support dir)
Database (DataLens): PostgreSQL via direct connection (user-configured)
API Server:         CodeOps-Server at localhost:8090
Vault Server:       CodeOps-Vault at localhost:8097
WebSocket:          Relay messaging at ws://localhost:8090/ws/relay
External APIs:      Anthropic API (https://api.anthropic.com/v1/)
                    GitHub API (https://api.github.com)
                    Jira Cloud API (user-configured instance URL)
```

### CI/CD
None detected in repository.

---

## 5. Startup & Runtime Behavior

**Entry Point:** `lib/main.dart`

Startup sequence:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `LogConfig.initialize()` — sets up file logging with daily rotation
3. `WindowManager` setup — size 1440x900, min 1024x700, hidden title bar, center
4. `runApp(ProviderScope(child: CodeOpsApp()))` — Riverpod root

**CodeOpsApp (`lib/app.dart`) on mount:**
1. Bridges `authStateProvider` to GoRouter's `authNotifier` for redirect
2. On successful auth: auto-selects first team, seeds 13 built-in agent definitions
3. Refreshes Anthropic model cache from API
4. Restores GitHub PAT from secure storage and re-authenticates

**Background processes:**
- Relay WebSocket heartbeat (every 30s when connected)
- Fleet container stats polling (every 5s when viewing)
- Seal status polling (every 10s on Vault seal page)
- Log file purge on each log write (7-day retention)

---

## 6. Entity / Data Model Layer

### Local Database (Drift — SQLite)

**Path:** `lib/database/database.dart`, `lib/database/tables.dart`
**Schema Version:** 8 (incremental migrations v1→v8)
**Singleton:** `CodeOpsDatabase` with lazy instance via `getApplicationSupportDirectory()/codeops.db`

#### Tables (25)

| Table | Key Fields | Purpose |
|---|---|---|
| `Users` | id (text PK), email, displayName, role | Cached user profiles |
| `Teams` | id (text PK), name, ownerId | Team records |
| `Projects` | id (text PK), teamId, name, repoUrl, healthScore | Project metadata |
| `QaJobs` | id (text PK), projectId, mode, status, result, healthScore | QA job records |
| `AgentRuns` | id (text PK), jobId, agentType, status, score | Agent execution records |
| `Findings` | id (text PK), jobId, agentType, severity, title, filePath | Code findings |
| `RemediationTasks` | id (text PK), jobId, findingId, status, priority, title | Generated fix tasks |
| `Personas` | id (text PK), teamId, name, agentType, scope, content | Agent persona prompts |
| `Directives` | id (text PK), teamId, name, category, scope, content | Project directives |
| `TechDebtItems` | id (text PK), projectId, category, effort, impact, status | Tech debt tracking |
| `DependencyScans` | id (text PK), projectId, healthScore | Dependency scan records |
| `DependencyVulnerabilities` | id (text PK), scanId, cveId, severity, status | Vulnerability records |
| `HealthSnapshots` | id (text PK), projectId, score, agentScores | Health score history |
| `ComplianceItems` | id (text PK), jobId, specId, status, requirement | Compliance check items |
| `Specifications` | id (text PK), projectId, name, type | Compliance spec references |
| `SyncMetadata` | entityType (text PK), teamId, lastSyncAt | Sync timestamp tracking |
| `ClonedRepos` | repoFullName (text PK), localPath, projectId | Cloned repo registry |
| `AnthropicModels` | modelId (text PK), displayName | Cached Anthropic models |
| `AgentDefinitions` | id (text PK), name, agentType, isBuiltIn | Agent config definitions |
| `AgentFiles` | id (integer PK auto), agentType, fileName, content | Agent-attached files |
| `ProjectLocalConfig` | id (text PK), projectId, key, value | Per-project local settings |
| `ScribeTabs` | id (text PK), title, content, language, filePath | Persisted editor tabs |
| `ScribeSettings` | id (integer PK), fontSize, theme, wordWrap | Editor settings |
| `DatalensConnections` | id (text PK), name, host, port, database, user | DB connection configs |
| `DatalensQueryHistory` | id (text PK), connectionId, sql, status, executionTimeMs | Query history |
| `DatalensSavedQueries` | id (text PK), connectionId, name, sql, folder | Saved SQL queries |

**`clearAllTables()`** — called on logout to wipe all local data.

### Model Classes (json_serializable)

**Path:** `lib/models/` — 38 files, ~280 classes, ~85 enums

All models use `@JsonSerializable()` with `JsonKey` annotations. Enums use `SCREAMING_SNAKE_CASE` values matching server-side conventions.

#### Key Model Files

| File | Key Classes | Purpose |
|---|---|---|
| `user.dart` | `User`, `TeamMember`, `AuthState` | Auth and user models |
| `team.dart` | `Team`, `TeamInvitation` | Team management |
| `project.dart` | `Project`, `ProjectMetrics` | Project metadata |
| `qa_job.dart` | `QaJob`, `AgentRun`, `JobConfig` | QA job execution |
| `finding.dart` | `Finding`, `FindingFilters` | Code findings |
| `remediation_task.dart` | `RemediationTask` | Generated fix tasks |
| `persona.dart` | `Persona`, `AgentConfig` | Agent configuration |
| `directive.dart` | `Directive` | Project directives |
| `tech_debt_item.dart` | `TechDebtItem` | Technical debt |
| `dependency_scan.dart` | `DependencyScan`, `DependencyVulnerability` | Dependency scanning |
| `health_snapshot.dart` | `HealthSnapshot` | Health history |
| `compliance.dart` | `ComplianceItem`, `Specification` | Compliance checks |
| `courier_models.dart` | 50+ classes for Courier module | API testing (collections, requests, environments, etc.) |
| `fleet_models.dart` | 30+ classes for Fleet module | Docker management |
| `logger_models.dart` | 40+ classes for Logger module | Log aggregation |
| `registry_models.dart` | 30+ classes for Registry module | Service registry |
| `relay_models.dart` | 25+ classes for Relay module | Team messaging |
| `vault_models.dart` | 30+ classes for Vault module | Secret management |
| `mcp_models.dart` | 20+ classes for MCP module | Developer profiles, sessions, documents |
| `jira_models.dart` | `JiraIssue`, `JiraComment`, `JiraProject`, etc. | Jira integration |
| `vcs_models.dart` | `VcsRepository`, `VcsBranch`, `VcsPullRequest`, etc. | VCS integration |
| `openapi_models.dart` | `OpenApiSpec`, `OpenApiEndpoint`, `OpenApiSchema` | OpenAPI parsing |

---

## 7. Enum Inventory

All enums in `lib/models/enums/` and inline in model files. Key enums:

| Enum | Values | Used In |
|---|---|---|
| `JobMode` | FULL_AUDIT, QUICK_SCAN, DEEP_SCAN, TARGETED, COMPLIANCE, BUG_INVESTIGATION | QaJob |
| `JobStatus` | PENDING, RUNNING, COMPLETED, FAILED, CANCELLED | QaJob |
| `JobResult` | PASS, WARN, FAIL | QaJob, AgentRun |
| `AgentType` | SECURITY, ARCHITECTURE, PERFORMANCE, BEST_PRACTICES, DOCUMENTATION, ERROR_HANDLING, TESTING, ACCESSIBILITY, DEPENDENCY, TYPE_SAFETY, MAINTAINABILITY | AgentRun, Persona |
| `Severity` | CRITICAL, HIGH, MEDIUM, LOW, INFO | Finding |
| `FindingStatus` | OPEN, ACKNOWLEDGED, FALSE_POSITIVE, RESOLVED, WONT_FIX | Finding |
| `TaskStatus` | PENDING, IN_PROGRESS, COMPLETED, JIRA_CREATED, EXPORTED, SKIPPED | RemediationTask |
| `TaskPriority` | CRITICAL, HIGH, MEDIUM, LOW | RemediationTask |
| `PersonaScope` | SYSTEM, TEAM | Persona |
| `DirectiveCategory` | ARCHITECTURE, CODING_STANDARDS, SECURITY, TESTING, DOCUMENTATION, PERFORMANCE, ACCESSIBILITY, CUSTOM | Directive |
| `DebtStatus` | IDENTIFIED, ACKNOWLEDGED, IN_PROGRESS, RESOLVED, WONT_FIX | TechDebtItem |
| `TeamMemberRole` | OWNER, ADMIN, LEAD, MEMBER, VIEWER | TeamMember |
| `BodyType` | NONE, FORM_DATA, X_WWW_FORM_URLENCODED, RAW_JSON, RAW_XML, RAW_HTML, RAW_TEXT, RAW_YAML, BINARY, GRAPHQL | Courier |
| `AuthType` | NO_AUTH, API_KEY, BEARER_TOKEN, BASIC_AUTH, OAUTH2_AUTHORIZATION_CODE, OAUTH2_CLIENT_CREDENTIALS, OAUTH2_IMPLICIT, OAUTH2_PASSWORD, JWT_BEARER, INHERIT_FROM_PARENT | Courier |
| `ScriptType` | PRE_REQUEST, POST_RESPONSE | Courier |
| `ContainerStatus` | RUNNING, STOPPED, PAUSED, RESTARTING, REMOVING, EXITED, DEAD, CREATED | Fleet |
| `ServiceType` | BACKEND, FRONTEND, DATABASE, CACHE, MESSAGE_BROKER, GATEWAY, MONITORING, STORAGE, SEARCH, CUSTOM | Registry |
| `ServiceStatus` | ACTIVE, INACTIVE, DEPRECATED | Registry |
| `HealthStatus` | HEALTHY, DEGRADED, UNHEALTHY, UNKNOWN | Registry |
| `SolutionStatus` | ACTIVE, INACTIVE, ARCHIVED, DEPRECATED | Registry |
| `SolutionCategory` | PRODUCT, INFRASTRUCTURE, TOOLING, TESTING, MONITORING, CUSTOM | Registry |
| `SecretType` | STATIC, DYNAMIC, TRANSIT | Vault |
| `PolicyPermission` | READ, WRITE, DELETE, LIST, ROTATE | Vault |
| `LogLevel` | VERBOSE, DEBUG, INFO, WARNING, ERROR, FATAL | Logger (client-side) |
| `PresenceStatus` | ONLINE, AWAY, DND, OFFLINE | Relay |
| `ConnectionStatus` | DISCONNECTED, CONNECTING, CONNECTED, ERROR | DataLens |

---

## 8. Repository Layer

**N/A for Flutter client.** Data persistence uses Drift (SQLite) with table definitions in `lib/database/tables.dart`. All CRUD operations are performed directly via Drift's generated companion classes in `CodeOpsDatabase`. Server-side data is fetched via API clients (Section 9).

---

## 9. Service Layer — Full Method Signatures

### 9.1 Auth Services

#### AuthService (`lib/services/auth/auth_service.dart`)
- **Injects:** `ApiClient`, `SecureStorageService`, `CodeOpsDatabase`
- `Stream<AuthState> get authStateStream` — broadcast stream of auth state changes
- `Future<AuthState> login(String email, String password, {bool rememberMe})` — POST `/api/v1/auth/login`, stores tokens, returns auth state
- `Future<AuthState> register(String email, String password, String displayName)` — POST `/api/v1/auth/register`
- `Future<void> logout()` — clears tokens and local state
- `Future<AuthState> tryAutoLogin()` — restores session from stored refresh token
- `Future<AuthState> refreshSession()` — refreshes access token using refresh token

#### SecureStorageService (`lib/services/auth/secure_storage.dart`)
- **Injects:** `SharedPreferences`
- Token storage: `saveAccessToken`, `getAccessToken`, `saveRefreshToken`, `getRefreshToken`
- API key: `saveAnthropicApiKey`, `getAnthropicApiKey`
- Team: `saveSelectedTeamId`, `getSelectedTeamId`
- `clearAll()` — clears all except remember-me credentials and Anthropic API key

### 9.2 API Client Infrastructure

#### ApiClient (`lib/services/cloud/api_client.dart`)
- **Injects:** `SecureStorageService`
- Provides configured `Dio` instance with 4 interceptors:
  1. **Auth** — injects `Authorization: Bearer <token>` header
  2. **Refresh** — on 401, attempts one token refresh, retries request
  3. **Error** — maps HTTP status codes to sealed `ApiException` hierarchy
  4. **Logging** — logs correlation IDs and elapsed time (never logs bodies/tokens)

#### ApiExceptions (`lib/services/cloud/api_exceptions.dart`)
- Sealed class hierarchy: `BadRequestException` (400), `UnauthorizedException` (401), `ForbiddenException` (403), `NotFoundException` (404), `ConflictException` (409), `ValidationException` (422), `RateLimitException` (429), `ServerException` (500+), `NetworkException`, `TimeoutException`

#### RegistryApiClient (`lib/services/cloud/registry_api_client.dart`)
- Separate Dio client for Registry module, same 4-interceptor pattern

#### VaultApiClient (`lib/services/cloud/vault_api_client.dart`)
- Separate Dio client targeting `AppConstants.vaultApiBaseUrl` (localhost:8097)

### 9.3 Cloud API Services (29 files)

All API services follow the same pattern: inject `ApiClient` (or `RegistryApiClient`/`VaultApiClient`), expose async methods returning model objects, error handling via interceptor chain. Team-scoped endpoints use `X-Team-ID` header.

| Service | File | Endpoints | Module |
|---|---|---|---|
| `AdminApi` | `admin_api.dart` | User mgmt, settings, audit, usage | Admin |
| `AnthropicApiService` | `anthropic_api_service.dart` | Model listing, API key validation | Settings |
| `ComplianceApi` | `compliance_api.dart` | Spec CRUD, compliance items | Compliance |
| `CourierApiService` | `courier_api.dart` | 79 endpoints (collections, requests, envs, etc.) | Courier |
| `DependencyApi` | `dependency_api.dart` | Scans, vulnerabilities | Dependencies |
| `DirectiveApi` | `directive_api.dart` | Directive CRUD, project assignment | Directives |
| `FindingApi` | `finding_api.dart` | Finding CRUD, batch, filtering | Findings |
| `FleetApiService` | `fleet_api.dart` | 53 endpoints (containers, profiles, Docker) | Fleet |
| `HealthMonitorApi` | `health_monitor_api.dart` | Schedules, snapshots, trends | Health |
| `IntegrationApi` | `integration_api.dart` | GitHub/Jira connection CRUD | Integrations |
| `JobApi` | `job_api.dart` | Job CRUD, agent runs, investigations | Jobs |
| `LoggerApi` | `logger_api.dart` | 104 endpoints (logs, metrics, traces, traps) | Logger |
| `McpApiService` | `mcp_api.dart` | 27 endpoints (sessions, documents, profiles) | MCP |
| `MetricsApi` | `metrics_api.dart` | Team/project metrics, trends | Metrics |
| `PersonaApi` | `persona_api.dart` | Persona CRUD, team/system scope | Personas |
| `ProjectApi` | `project_api.dart` | Project CRUD, archiving | Projects |
| `RegistryApi` | `registry_api.dart` | 77 endpoints (services, solutions, deps, ports, routes) | Registry |
| `RelayApiService` | `relay_api.dart` | 59 endpoints (channels, messages, DMs, presence) | Relay |
| `RelayWebSocketService` | `relay_websocket_service.dart` | WebSocket with reconnection, subscriptions | Relay |
| `ReportApi` | `report_api.dart` | Report upload/download (S3-backed) | Reports |
| `TaskApi` | `task_api.dart` | Task CRUD, batch creation | Tasks |
| `TeamApi` | `team_api.dart` | Team CRUD, member management | Teams |
| `TechDebtApi` | `tech_debt_api.dart` | Debt item CRUD, summaries | Tech Debt |
| `UserApi` | `user_api.dart` | User profile CRUD, search | Users |
| `VaultApi` | `vault_api.dart` | 67 endpoints (secrets, policies, transit, seal) | Vault |

**Total API endpoints:** ~600+

### 9.4 Orchestration Services

#### JobOrchestrator (`lib/services/orchestration/job_orchestrator.dart`)
- **Injects:** `AgentDispatcher`, `AgentMonitor`, `VeraManager`, `ProgressAggregator`, `ReportParser`, `JobApi`, `FindingApi`, `ReportApi`
- `Future<JobResult> executeJob({...})` — 10-step lifecycle: create job → dispatch agents → monitor → parse reports → consolidate → sync findings → upload reports → update job
- `Future<void> cancelJob(String jobId)` — cancels all agent processes and updates server
- `Stream<JobLifecycleEvent> get lifecycleStream` — broadcast of lifecycle events

#### AgentDispatcher (`lib/services/orchestration/agent_dispatcher.dart`)
- **Injects:** `ProcessManager`, `PersonaManager`, `ClaudeCodeDetector`
- `Future<ManagedProcess> dispatchAgent({...})` — spawns Claude Code CLI subprocess with assembled prompt
- `Stream<AgentDispatchEvent> dispatchAll({...})` — dispatches multiple agents with semaphore concurrency control

#### AgentMonitor (`lib/services/orchestration/agent_monitor.dart`)
- Monitors agent processes to completion with timeout handling

#### VeraManager (`lib/services/orchestration/vera_manager.dart`)
- Consolidates all agent reports into a single `VeraReport` with weighted health scoring and finding deduplication

### 9.5 DataLens Services

#### DatabaseConnectionService (`lib/services/datalens/database_connection_service.dart`)
- **Injects:** `CodeOpsDatabase`
- Direct PostgreSQL connections via `postgres` driver
- CRUD for connection configs in local DB
- `connect()`, `disconnect()`, `testConnection()`, server info queries

#### QueryExecutionService (`lib/services/datalens/query_execution_service.dart`)
- `executeQuery()`, `executePagedQuery()`, `browseTable()`, `cancelQuery()`, `explainQuery()`

#### SchemaIntrospectionService (`lib/services/datalens/schema_introspection_service.dart`)
- 14 methods for schema metadata: `getSchemas`, `getTables`, `getColumns`, `getConstraints`, `getForeignKeys`, `getIndexes`, `getTableDdl`, `getRowCountEstimate`, etc.

### 9.6 Other Services

#### JiraService (`lib/services/jira/jira_service.dart`)
- Direct Jira Cloud REST API v3 client with rate-limit retry (429 + Retry-After header)
- 18 methods: search, CRUD, transitions, sprints, users, priorities

#### GitService (`lib/services/vcs/git_service.dart`)
- 22 git operations via `Process.run()`: clone, pull, push, checkout, commit, merge, blame, stash, tag, etc.
- All commands set `GIT_TERMINAL_PROMPT=0` to prevent interactive auth hangs

#### ExportService (`lib/services/integration/export_service.dart`)
- Exports reports as Markdown, PDF, or ZIP archive

#### LogService (`lib/services/logging/log_service.dart`)
- Singleton logger with 6 levels (verbose → fatal), daily file rotation, 7-day retention

---

## 10. Controller / API Layer

**N/A — Flutter desktop client.** This project consumes APIs, it does not expose them. All API interactions are documented in Section 9.3 (Cloud API Services).

---

## 11. Security Configuration

```
Authentication: JWT Bearer tokens (access + refresh)
Token Storage: SharedPreferences (SecureStorageService)
Password Handling: Passwords sent to server for auth; no local hashing
Token Refresh: Automatic via Dio interceptor on 401 response
Session Restore: tryAutoLogin() attempts refresh token restoration on app startup

Route Protection:
  - GoRouter redirect: unauthenticated users → /login
  - AuthNotifier bridges authStateProvider to GoRouter
  - Admin pages: role-gated (Owner/Admin only) via teamMembersProvider check

API Security:
  - All API calls include Authorization: Bearer <accessToken> header
  - Refresh interceptor: on 401, uses refresh token to get new access token, retries request
  - Token never logged (logging interceptor skips bodies and auth headers)

External Service Auth:
  - GitHub: Personal Access Token (stored in SharedPreferences)
  - Jira: Basic Auth (email + API token, stored per-connection)
  - Anthropic: API key (stored in SharedPreferences)
```

---

## 12. Custom Security Components

#### ApiClient Refresh Interceptor (`lib/services/cloud/api_client.dart`)
- On 401 response: creates fresh Dio instance, POSTs to `/api/v1/auth/refresh` with stored refresh token
- On success: stores new access/refresh tokens, retries original request with new token
- On failure: clears all stored tokens, emits unauthenticated state

#### Role-based Access Control (UI-level)
- `AdminHubPage` checks `teamMembersProvider` for current user's role
- Only OWNER and ADMIN roles can access admin tabs (Users, Settings, Audit Log, Usage)

---

## 13. Exception Handling & Error Responses

#### ApiException Hierarchy (`lib/services/cloud/api_exceptions.dart`)
- Sealed class hierarchy mapping HTTP status codes to typed exceptions
- `BadRequestException` (400), `UnauthorizedException` (401), `ForbiddenException` (403), `NotFoundException` (404), `ConflictException` (409), `ValidationException` (422), `RateLimitException` (429), `ServerException` (500+), `NetworkException`, `TimeoutException`
- All have `message` and optional `statusCode` fields

#### UI Error Handling
- `ErrorPanel` widget with `fromException` factory maps `ApiException` subtypes to user-friendly messages
- `EmptyState` widget for no-data states
- `LoadingOverlay` for async operations
- `NotificationToast` for transient success/error/info messages via ScaffoldMessenger

---

## 14. Mappers / DTOs

**Framework:** `json_serializable` with `@JsonSerializable()` annotations on all model classes.

All models have `factory fromJson(Map<String, dynamic>)` and `Map<String, dynamic> toJson()` generated by `json_serializable`. Enum serialization uses `@JsonValue` annotations with SCREAMING_SNAKE_CASE values.

**JiraMapper** (`lib/services/jira/jira_mapper.dart`):
- `toInvestigationFields()` — Jira issue → bug investigation request
- `taskToJiraIssue()` / `tasksToJiraIssues()` — remediation task → Jira issue creation
- `toDisplayModel()` — full JiraIssue → simplified display model
- `adfToMarkdown()` / `markdownToAdf()` — Atlassian Document Format ↔ Markdown

**OpenApiParser** (`lib/services/openapi_parser.dart`):
- `parse(Map<String, dynamic>)` — parses OpenAPI 3.0 JSON into structured models
- Handles `$ref` resolution, `allOf`/`oneOf`/`anyOf` merging, schema flattening

---

## 15. Utility Classes & Shared Components

#### AppConstants (`lib/utils/constants.dart`)
- ~140 constants: API URLs, limits, timeouts, storage keys, Scribe editor settings, Relay WebSocket config, Fleet polling intervals

#### DateUtils (`lib/utils/date_utils.dart`)
- `formatDateTime(DateTime)`, `formatDate(DateTime)`, `formatTimeAgo(DateTime)`, `formatDuration(Duration)`

#### StringUtils (`lib/utils/string_utils.dart`)
- `truncate(String, int)`, `pluralize(String, int)`, `camelToTitle(String)`, `snakeToTitle(String)`, `isValidEmail(String)`

#### FileUtils (`lib/utils/file_utils.dart`)
- `formatFileSize(int)`, `getFileExtension(String)`, `getFileName(String)`

#### FuzzyMatcher (`lib/utils/fuzzy_matcher.dart`)
- Quick-open file search with scoring (consecutive run, word boundary, prefix, case-exact bonuses)

#### MarkdownHeadingParser (`lib/utils/markdown_heading_parser.dart`)
- `parseMarkdownHeadings(String)` — extracts heading hierarchy for Scribe TOC, handles fenced code blocks

---

## 16. Database Schema (Local)

**Engine:** SQLite via Drift
**File:** `codeops.db` in application support directory
**Schema Version:** 8
**Tables:** 25 (see Section 6 for full table listing)
**Migration Strategy:** Incremental `onUpgrade` with version-by-version migrations (v1→v8)

No live database dump applicable — this is a local-only SQLite database managed by Drift's `ddl-auto` equivalent. Schema is defined entirely by `lib/database/tables.dart`.

---

## 17. Message Broker Configuration

**Relay WebSocket** (`lib/services/cloud/relay_websocket_service.dart`):
- Connection: `ws://localhost:8090/ws/relay` (via `AppConstants.relayWebSocketUrl`)
- Protocol: STOMP-like frame-based messaging over WebSocket
- Subscriptions: channels, DMs, typing indicators, presence, platform events, notifications
- Heartbeat: every `AppConstants.relayHeartbeatIntervalSeconds` (30s)
- Reconnection: exponential backoff (1, 2, 4, 8, 16, 30 max seconds)

No traditional message broker (Kafka/RabbitMQ) in the client. The server-side Kafka/Zookeeper are consumed by CodeOps-Server, not the client.

---

## 18. Cache Layer

**Local Cache:** Drift SQLite database serves as the client-side cache for server data.

**SyncService** (`lib/services/data/sync_service.dart`):
- `syncProjects(teamId)` — fetches from server, persists to local DB, returns merged list
- Falls back to local cache on `NetworkException` or `TimeoutException`

**Anthropic Model Cache:**
- `AgentConfigService` caches model list in Drift `AnthropicModels` table
- Refreshed on app startup and on demand from Settings

**Scribe Tab Persistence:**
- `ScribePersistenceService` saves/loads editor tabs and settings to/from Drift

No Redis or in-memory caching layer.

---

## 19. Environment Variable Inventory

The Flutter client does not use environment variables at runtime. All configuration is hardcoded in `AppConstants` (`lib/utils/constants.dart`).

| Constant | Value | Purpose |
|---|---|---|
| `apiBaseUrl` | `http://localhost:8090` | CodeOps Server API |
| `vaultApiBaseUrl` | `http://localhost:8097` | Vault Server API |
| `relayWebSocketUrl` | `ws://localhost:8090/ws/relay` | Relay WebSocket |
| `defaultModel` | `claude-sonnet-4-20250514` | Default Claude model |
| `maxConcurrentAgents` | `3` | Agent dispatch concurrency |
| `agentTimeoutMinutes` | `30` | Agent execution timeout |

**Note:** These are compile-time constants. No `.env` file or runtime env var support.

---

## 20. Service Dependency Map

```
CodeOps-Client → Depends On:
  - CodeOps-Server (localhost:8090): All primary API calls (auth, projects, jobs, findings, etc.)
  - CodeOps-Vault (localhost:8097): Secret management API calls
  - Anthropic API (api.anthropic.com): Model listing, API key validation
  - GitHub API (api.github.com): Repository browsing, PRs, CI status
  - Jira Cloud API (user-configured): Issue management, search, comments
  - PostgreSQL (user-configured): Direct DataLens database connections
  - Claude Code CLI (local): Agent subprocess execution for QA jobs

Downstream Consumers:
  None — this is the end-user desktop client.
```

---

## 21. Known Technical Debt & Issues

### TODO/Placeholder/Stub Scan

**Result: CLEAN** — 0 actual TODO/FIXME/placeholder patterns found in source code.

2 grep hits were found but both are descriptive strings in agent persona content, not actual incomplete code:
- Agent persona descriptions containing the word "placeholder" in reference to code patterns they detect
- Not actionable technical debt

### Issues

| Issue | Location | Severity | Notes |
|---|---|---|---|
| Hardcoded localhost URLs | `lib/utils/constants.dart` | Medium | API URLs are compile-time constants; no env var or build-flavor support for staging/prod |
| Doc coverage below 100% | Various files | BLOCKING | 847/1420 classes documented (59.6%) — see Scorecard CQ-09 |
| No CI/CD pipeline | Repository root | Low | No `.github/workflows` or other CI config detected |
| SharedPreferences for tokens | `lib/services/auth/secure_storage.dart` | Medium | Uses SharedPreferences (plaintext on disk) instead of platform keychain for sensitive tokens |

---

## 22. Security Vulnerability Scan (Snyk)

**Scan Date:** 2026-03-02T00:58:00Z
**Snyk CLI Version:** 1.1296.2

### Dependency Vulnerabilities (Open Source)
```
Critical: 0
High: 0
Medium: 0
Low: 0
```
**PASS — No known vulnerabilities in dependencies.**

### Code Vulnerabilities (SAST)
Snyk Code scan not available for Dart/Flutter projects.

### IaC Findings
No Dockerfile or docker-compose.yml in this project.

---

## Provider Layer Overview

**Path:** `lib/providers/` — 32 files, ~450+ Riverpod providers

All state management uses `flutter_riverpod`. Key provider patterns:

| File | Key Providers | Purpose |
|---|---|---|
| `auth_providers.dart` | `authServiceProvider`, `currentUserProvider`, `authStateProvider`, `authNotifierProvider` | Auth state |
| `team_providers.dart` | `selectedTeamIdProvider`, `selectedTeamProvider`, `teamsProvider`, `teamMembersProvider` | Team state |
| `project_providers.dart` | `teamProjectsProvider`, `selectedProjectIdProvider`, `favoriteProjectIdsProvider` | Project state |
| `job_providers.dart` | `jobDetailProvider`, `jobProgressProvider`, `jobLifecycleProvider`, `jobHistoryProvider` | Job execution |
| `finding_providers.dart` | `jobFindingsProvider`, `findingSeverityCountsProvider`, `activeFindingProvider` | Findings |
| `persona_providers.dart` | `teamPersonasProvider`, `systemPersonasProvider`, `filteredPersonasProvider` | Personas |
| `directive_providers.dart` | `teamDirectivesProvider`, `filteredDirectivesProvider` | Directives |
| `courier_providers.dart` | 40+ providers for Courier module | API testing |
| `fleet_providers.dart` | 20+ providers for Fleet module | Docker mgmt |
| `logger_providers.dart` | 30+ providers for Logger module | Log aggregation |
| `registry_providers.dart` | 40+ providers for Registry module | Service registry |
| `relay_providers.dart` | 20+ providers for Relay module | Messaging |
| `vault_providers.dart` | 30+ providers for Vault module | Secrets |
| `datalens_providers.dart` | 15+ providers for DataLens module | DB browser |
| `github_providers.dart` | `githubOrgsProvider`, `selectedGithubRepoProvider`, etc. | GitHub browser |
| `jira_providers.dart` | `jiraServiceProvider`, `jiraSearchResultsProvider`, etc. | Jira browser |
| `scribe_providers.dart` | 20+ providers for Scribe editor state | Code editor |
| `settings_providers.dart` | `sidebarCollapsedProvider`, `fontDensityProvider`, `compactModeProvider` | UI settings |

---

## Router Overview

**Path:** `lib/router.dart`
**Framework:** `go_router ^14.8.1`
**Total Routes:** ~80

**Structure:**
- `/login` — unauthenticated, `LoginPage`
- All other routes under `ShellRoute` with `NavigationShell` (sidebar + top bar)
- Auth redirect: unauthenticated → `/login`, authenticated from `/login` → `/`

**Key Route Groups:**
- `/` — `HomePage` (dashboard)
- `/projects`, `/projects/:id` — Project list/detail
- `/audit`, `/compliance` — Wizard pages
- `/jobs/:id`, `/jobs/:id/report`, `/jobs/:id/findings`, `/jobs/:id/tasks` — Job lifecycle
- `/history` — Job history
- `/personas`, `/personas/:id/edit` — Persona management
- `/directives` — Directive management
- `/dependencies` — Dependency scanning
- `/tech-debt` — Tech debt tracking
- `/health` — Health dashboard
- `/bugs` — Bug investigation wizard
- `/scribe` — Code editor
- `/github` — GitHub browser
- `/jira` — Jira browser
- `/settings` — Settings page
- `/admin` — Admin hub
- `/courier/*` — API testing (10+ sub-routes)
- `/fleet/*` — Docker management (12+ sub-routes)
- `/logger/*` — Log aggregation (12+ sub-routes)
- `/registry/*` — Service registry (15+ sub-routes)
- `/relay/*` — Team messaging
- `/vault/*` — Secret management (10+ sub-routes)
- `/datalens` — Database browser
- `/tasks` — Task manager

---

## Widget Layer Overview

**Path:** `lib/widgets/` — 372 files across 24 directories

| Directory | Files | Purpose |
|---|---|---|
| `admin/` | 4 | Admin hub tabs (users, settings, audit, usage) |
| `compliance/` | 3 | Compliance results, gap analysis, spec list |
| `dashboard/` | 4 | Home page cards (quick start, activity, health, team) |
| `datalens/` | 29 | Database browser (navigator tree, SQL editor, data grid, properties) |
| `dependency/` | 4 | Vulnerability scanning UI |
| `findings/` | 4 | Finding table, detail panel, severity filter |
| `fleet/` | 33 | Docker container management UI |
| `health/` | 3 | Health dashboard panels |
| `jira/` | 11 | Jira integration (issue browser, create dialog, RCA posting) |
| `logger/` | 26 | Log viewer, metrics, traces, dashboards, alerts |
| `personas/` | 4 | Persona editor, list, preview, test runner |
| `progress/` | 9 | Job progress (agent cards, phase indicator, live feed) |
| `registry/` | 59 | Service registry (topology, dependencies, ports, routes, configs) |
| `relay/` | 22 | Team messaging (channels, DMs, threads, file upload) |
| `reports/` | 8 | Job reports (executive summary, agent tabs, export) |
| `scribe/` | 35 | Code editor (tabs, diff, find/replace, command palette, settings) |
| `settings/` | 7 | Agent configuration, API key management |
| `shared/` | 8 | Reusable components (confirm dialog, empty state, error panel, search bar) |
| `shell/` | 2 | Navigation shell, team switcher |
| `tasks/` | 5 | Task cards, detail, Jira create, export |
| `tech_debt/` | 4 | Debt inventory, priority matrix, trend chart |
| `vault/` | 48 | Secret management (CRUD, policies, transit, rotation, seal) |
| `vcs/` | 17 | Git/GitHub (repo browser, clone, commit, PR, stash) |
| `wizard/` | 8 | Wizard steps (source, agents, config, review, spec upload) |

**Widget type breakdown:**
- StatelessWidget: 108 (29%)
- ConsumerStatefulWidget: 76 (20%)
- StatefulWidget: 59 (16%)
- ConsumerWidget: 49 (13%)
- Utility/ChangeNotifier classes: 11 (3%)

---

## Theme

**Path:** `lib/theme/`
**Mode:** Dark only (no light theme)

### Colors (`lib/theme/colors.dart`)
- Background: `#1A1B2E`
- Surface: `#222442`
- Primary: `#6C63FF`
- Secondary: `#00D9FF`
- Error: `#FF6B6B`
- Warning: `#FFB347`
- Success: `#4CAF50`
- Includes color maps for all major enums (Severity, JobStatus, AgentType, TaskStatus, etc.)

### Typography (`lib/theme/typography.dart`)
- Primary font: Inter
- Code font: JetBrains Mono
- 12 text styles from headlineLarge (32px) to labelSmall (11px)

### Theme (`lib/theme/app_theme.dart`)
- `AppTheme.darkTheme` — complete `ThemeData` built from `CodeOpsColors` and `CodeOpsTypography`

---

## Test Summary

```
Test Framework: flutter_test + mocktail
Test Files: 478
Total Tests: 5,751
Result: ALL PASSED
Integration Tests: 5 files
```

---

## Analysis Options

**Path:** `analysis_options.yaml`
- Extends: `package:flutter_lints/flutter.yaml`
- No custom lint rules enabled
