/// Centralized application constants.
///
/// All magic numbers, limits, and configuration values live here.
/// Mirrors the server's AppConstants.java where applicable.
library;

/// Application-wide constant values.
class AppConstants {
  AppConstants._();

  /// Application name displayed in the UI and window title.
  static const String appName = 'CodeOps';

  /// Current application version.
  static const String appVersion = '1.0.0';

  /// CodeOps-Server base URL (core + registry + logger + courier modules).
  static const String apiBaseUrl = 'http://localhost:8090';

  /// API path prefix for all endpoints.
  static const String apiPrefix = '/api/v1';

  /// Base URL for the CodeOps Vault API (standalone service).
  static const String vaultApiBaseUrl = 'http://localhost:8097';

  /// API path prefix for all Vault endpoints.
  static const String vaultApiPrefix = '/api/v1/vault';

  /// Maximum number of members allowed in a team.
  static const int maxTeamMembers = 50;

  /// Maximum number of projects allowed per team.
  static const int maxProjectsPerTeam = 100;

  /// Maximum number of personas allowed per team.
  static const int maxPersonasPerTeam = 50;

  /// Maximum number of directives assignable to a project.
  static const int maxDirectivesPerProject = 20;

  /// Maximum report file size in megabytes.
  static const int maxReportSizeMb = 25;

  /// Maximum persona content size in kilobytes.
  static const int maxPersonaSizeKb = 100;

  /// Maximum directive content size in kilobytes.
  static const int maxDirectiveSizeKb = 200;

  /// Maximum specification file size in megabytes.
  static const int maxSpecFileSizeMb = 50;

  /// JWT access token expiry in hours.
  static const int jwtExpiryHours = 24;

  /// Refresh token expiry in days.
  static const int refreshTokenExpiryDays = 30;

  /// Team invitation expiry in days.
  static const int invitationExpiryDays = 7;

  /// Default number of concurrent agents per job.
  static const int defaultMaxConcurrentAgents = 3;

  /// Default agent timeout in minutes.
  static const int defaultAgentTimeoutMinutes = 15;

  /// Maximum number of turns an agent can take.
  static const int maxAgentTurns = 50;

  /// URL for the auto-update manifest.
  static const String updateManifestUrl =
      'https://releases.codeops.dev/latest.json';

  /// How often to check for updates (hours).
  static const int updateCheckIntervalHours = 4;

  /// Day of week for health digest (1 = Monday).
  static const int healthDigestDay = 1;

  /// Hour of day for health digest (24h format).
  static const int healthDigestHour = 8;

  /// Default page size for paginated API requests.
  static const int defaultPageSize = 20;

  /// Maximum page size for paginated API requests.
  static const int maxPageSize = 100;

  /// S3 prefix for agent reports.
  static const String s3Reports = 'reports/';

  /// S3 prefix for specification files.
  static const String s3Specs = 'specs/';

  /// S3 prefix for persona content.
  static const String s3Personas = 'personas/';

  /// S3 prefix for release artifacts.
  static const String s3Releases = 'releases/';

  /// Secure storage key for the auth token.
  static const String keyAuthToken = 'auth_token';

  /// Secure storage key for the refresh token.
  static const String keyRefreshToken = 'refresh_token';

  /// Secure storage key for the current user ID.
  static const String keyCurrentUserId = 'current_user_id';

  /// Secure storage key for the selected team ID.
  static const String keySelectedTeamId = 'selected_team_id';

  /// Secure storage key for the configured Claude model.
  static const String keyClaudeModel = 'claude_model';

  /// Secure storage key for the max concurrent agents setting.
  static const String keyMaxConcurrentAgents = 'max_concurrent_agents';

  /// Secure storage key for the agent timeout setting.
  static const String keyAgentTimeoutMinutes = 'agent_timeout_minutes';

  /// Secure storage key for the GitHub Personal Access Token.
  static const String keyGitHubPat = 'github_pat';

  /// Secure storage key for the Anthropic API key.
  static const String keyAnthropicApiKey = 'codeops_anthropic_api_key';

  /// Anthropic API base URL.
  static const String anthropicApiBaseUrl = 'https://api.anthropic.com';

  /// Anthropic API version header value.
  static const String anthropicApiVersion = '2023-06-01';

  /// Debounce duration in milliseconds for agent config auto-save.
  static const int agentConfigSaveDebounceMs = 500;

  /// Secure storage key for the "Remember Me" toggle state.
  static const String keyRememberMe = 'remember_me';

  /// Secure storage key for the remembered login email.
  static const String keyRememberedEmail = 'remembered_email';

  /// Secure storage key for the remembered login password.
  static const String keyRememberedPassword = 'remembered_password';

  /// Default Claude model identifier.
  static const String defaultClaudeModel = 'claude-sonnet-4-20250514';

  /// Health score threshold for green (healthy) status.
  static const int healthScoreGreenThreshold = 80;

  /// Health score threshold for yellow (warning) status.
  static const int healthScoreYellowThreshold = 60;

  /// Default number of days for health trend charts.
  static const int healthTrendDefaultDays = 30;

  /// Page size for recent jobs in project detail.
  static const int recentJobsPageSize = 10;

  /// Default maximum turns for Claude Code subprocess.
  static const int defaultMaxTurns = 50;

  /// Default Claude model for agent dispatch.
  static const String defaultClaudeModelForDispatch =
      'claude-sonnet-4-5-20250514';

  /// Line threshold for finding deduplication (±N lines).
  static const int deduplicationLineThreshold = 5;

  /// Title similarity threshold for finding deduplication (0.0-1.0).
  static const double deduplicationTitleSimilarityThreshold = 0.8;

  /// Weight multiplier for Security agent in health score calculation.
  static const double securityAgentWeight = 1.5;

  /// Weight multiplier for Architecture agent in health score calculation.
  static const double architectureAgentWeight = 1.5;

  /// Default weight multiplier for agents in health score calculation.
  static const double defaultAgentWeight = 1.0;

  /// Minimum required Claude Code CLI version.
  static const String minClaudeCodeVersion = '1.0.0';

  // -------------------------------------------------------------------------
  // Wizard & Job Progress constants
  // -------------------------------------------------------------------------

  /// Minimum concurrent agents allowed in wizard configuration.
  static const int maxConcurrentAgentsMin = 1;

  /// Maximum concurrent agents allowed in wizard configuration.
  static const int maxConcurrentAgentsMax = 10;

  /// Minimum agent timeout in minutes.
  static const int agentTimeoutMinutesMin = 5;

  /// Maximum agent timeout in minutes.
  static const int agentTimeoutMinutesMax = 120;

  /// Minimum max turns for Claude Code subprocess.
  static const int maxTurnsMin = 10;

  /// Maximum max turns for Claude Code subprocess.
  static const int maxTurnsMax = 100;

  /// Default pass threshold for health score (0-100).
  static const int defaultPassThreshold = 80;

  /// Default warn threshold for health score (0-100).
  static const int defaultWarnThreshold = 60;

  /// Maximum specification file size in bytes (50 MB).
  static const int maxSpecFileSizeBytes = 52428800;

  /// Maximum number of live findings visible in the feed.
  static const int maxVisibleLiveFindings = 50;

  /// Polling interval for job progress fallback in seconds.
  static const int jobPollingIntervalSeconds = 5;

  // -------------------------------------------------------------------------
  // Report & Findings constants (COC-008)
  // -------------------------------------------------------------------------

  /// Health score deduction for each critical finding.
  static const double criticalScoreReduction = 5.0;

  /// Health score deduction for each high finding.
  static const double highScoreReduction = 2.0;

  /// Health score deduction for each medium finding.
  static const double mediumScoreReduction = 0.5;

  /// Health score deduction for each low finding.
  static const double lowScoreReduction = 0.0;

  /// Default page size for findings explorer.
  static const int defaultFindingsPageSize = 20;

  /// Debounce duration for findings search in milliseconds.
  static const int findingsSearchDebounceMs = 300;

  /// Maximum filename length for exported files.
  static const int maxExportFilenameLength = 100;

  /// Health score gauge animation duration in milliseconds.
  static const int healthScoreAnimationMs = 500;

  /// Default size for health score gauge widget.
  static const double gaugeDefaultSize = 120.0;

  // -------------------------------------------------------------------------
  // Scribe constants (CS-002)
  // -------------------------------------------------------------------------

  /// Default font size for the Scribe editor.
  static const double scribeDefaultFontSize = 14.0;

  /// Minimum font size for the Scribe editor.
  static const double scribeMinFontSize = 12.0;

  /// Maximum font size for the Scribe editor.
  static const double scribeMaxFontSize = 24.0;

  /// Default tab size for the Scribe editor.
  static const int scribeDefaultTabSize = 2;

  /// Height of the Scribe status bar in logical pixels.
  static const double scribeStatusBarHeight = 28.0;

  /// Height of the Scribe tab bar in logical pixels.
  static const double scribeTabBarHeight = 36.0;

  /// Minimum width of a Scribe tab in logical pixels.
  static const double scribeTabMinWidth = 120.0;

  /// Maximum width of a Scribe tab in logical pixels.
  static const double scribeTabMaxWidth = 200.0;

  // -------------------------------------------------------------------------
  // Scribe constants (CS-004)
  // -------------------------------------------------------------------------

  /// Maximum number of recent files tracked in Scribe.
  static const int scribeMaxRecentFiles = 20;

  /// Maximum file size in bytes that Scribe will open (10 MB).
  static const int scribeMaxFileSizeBytes = 10485760;

  // -------------------------------------------------------------------------
  // Scribe constants (CS-005)
  // -------------------------------------------------------------------------

  /// Default font family for the Scribe editor.
  static const String scribeDefaultFontFamily = 'JetBrains Mono';

  /// Default auto-save interval in seconds.
  static const int scribeDefaultAutoSaveIntervalSeconds = 30;

  /// Minimum auto-save interval in seconds.
  static const int scribeMinAutoSaveIntervalSeconds = 5;

  /// Maximum auto-save interval in seconds.
  static const int scribeMaxAutoSaveIntervalSeconds = 300;

  /// Debounce duration in milliseconds for settings persistence.
  static const int scribeSettingsPersistDebounceMs = 500;

  /// Width of the Scribe settings panel in logical pixels.
  static const double scribeSettingsPanelWidth = 320.0;

  // -------------------------------------------------------------------------
  // Scribe constants (CS-006)
  // -------------------------------------------------------------------------

  /// Debounce duration in milliseconds for markdown preview rendering.
  static const int scribeMarkdownPreviewDebounceMs = 300;

  /// Minimum width in logical pixels for each pane in the split view.
  static const double scribeMinSplitPaneWidth = 200.0;

  /// Default split ratio (0.0–1.0) for the editor/preview split view.
  static const double scribeDefaultSplitRatio = 0.5;

  /// Cooldown in milliseconds for bidirectional scroll synchronization.
  static const int scribeScrollSyncCooldownMs = 100;

  // -------------------------------------------------------------------------
  // Scribe constants (CS-007 — Diff Editor)
  // -------------------------------------------------------------------------

  /// Width of the diff gutter in logical pixels.
  static const double scribeDiffGutterWidth = 48.0;

  /// Height of a single line in the diff view in logical pixels.
  static const double scribeDiffLineHeight = 22.0;

  /// Number of unchanged context lines shown around changes.
  static const int scribeDiffContextLines = 3;

  /// Maximum number of closed tabs retained in diff history.
  static const int scribeDiffMaxHistory = 20;

  /// Height of the diff summary bar in logical pixels.
  static const double scribeDiffSummaryBarHeight = 32.0;

  // -------------------------------------------------------------------------
  // Scribe constants (CS-008 — Session Persistence)
  // -------------------------------------------------------------------------

  /// Debounce duration in milliseconds for session auto-persist.
  static const int scribeSessionPersistDebounceMs = 5000;

  /// Maximum number of results shown in the quick-open overlay.
  static const int scribeQuickOpenMaxResults = 50;

  /// Debounce duration in milliseconds for quick-open search input.
  static const int scribeQuickOpenSearchDebounceMs = 200;

  /// Height of the file-changed-on-disk banner in logical pixels.
  static const double scribeFileChangedBannerHeight = 36.0;

  /// Width of the recent files panel in logical pixels.
  static const double scribeRecentFilesPanelWidth = 320.0;

  /// Height of the quick-open overlay in logical pixels.
  static const double scribeQuickOpenHeight = 400.0;

  /// Width of the quick-open overlay in logical pixels.
  static const double scribeQuickOpenWidth = 500.0;

  // -------------------------------------------------------------------------
  // Scribe constants (CS-009 — Keyboard Shortcuts & Command Palette)
  // -------------------------------------------------------------------------

  /// Height of the command palette overlay in logical pixels.
  static const double scribeCommandPaletteHeight = 400.0;

  /// Width of the command palette overlay in logical pixels.
  static const double scribeCommandPaletteWidth = 520.0;

  /// Height of the find/replace panel in logical pixels.
  static const double scribeFindPanelHeight = 40.0;

  /// Height of the find/replace panel with replace row visible.
  static const double scribeFindReplacePanelHeight = 80.0;

  /// Width of the Go to Line dialog in logical pixels.
  static const double scribeGoToLineDialogWidth = 300.0;

  /// Width of the keyboard shortcuts help overlay in logical pixels.
  static const double scribeShortcutsHelpWidth = 600.0;

  /// Maximum height of the keyboard shortcuts help overlay.
  static const double scribeShortcutsHelpMaxHeight = 500.0;

  /// Maximum number of results shown in the command palette.
  static const int scribeCommandPaletteMaxResults = 30;

  // -------------------------------------------------------------------------
  // Scribe constants (CS-010 — Status Bar)
  // -------------------------------------------------------------------------

  /// Width of the language picker popup in logical pixels.
  static const double scribeLanguagePickerWidth = 260.0;

  /// Height of the language picker popup in logical pixels.
  static const double scribeLanguagePickerHeight = 360.0;

  // -------------------------------------------------------------------------
  // Relay constants (RELC-001)
  // -------------------------------------------------------------------------

  /// WebSocket URL for real-time Relay messaging.
  static const String relayWebSocketUrl = 'ws://localhost:8090/ws/relay';

  /// Heartbeat interval in seconds for Relay WebSocket keep-alive.
  static const int relayHeartbeatIntervalSeconds = 30;

  /// Maximum reconnect delay in seconds for Relay WebSocket backoff.
  static const int relayReconnectMaxDelaySeconds = 30;
}
