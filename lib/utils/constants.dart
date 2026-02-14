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

  /// Base URL for the CodeOps server API.
  static const String apiBaseUrl = 'http://localhost:8090';

  /// API path prefix for all endpoints.
  static const String apiPrefix = '/api/v1';

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
}
