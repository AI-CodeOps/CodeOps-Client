/// Riverpod providers for Courier UI-only state.
///
/// Manages pane sizing, open request tabs, active selections, and panel
/// visibility. Kept separate from [courier_providers.dart] which owns
/// API/async state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/courier_enums.dart';
import '../widgets/courier/key_value_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RequestTab model
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single open request tab in the Courier tab bar.
///
/// Mirrors a browser-style tab: each tab tracks the request it belongs to,
/// its display name, HTTP method, URL, and whether it has unsaved changes.
class RequestTab {
  /// Unique tab identifier (UUID-like, client-generated).
  final String id;

  /// The persisted request ID on the server, or null if this is a new,
  /// unsaved request.
  final String? requestId;

  /// Display name shown in the tab label (e.g. "GET /users" or "New Request").
  final String name;

  /// The HTTP method for this request.
  final CourierHttpMethod method;

  /// The URL currently entered for this request.
  final String url;

  /// Whether the tab has unsaved changes relative to the persisted state.
  final bool isDirty;

  /// Whether this is a newly created, never-saved request.
  final bool isNew;

  /// Creates a [RequestTab].
  const RequestTab({
    required this.id,
    this.requestId,
    required this.name,
    required this.method,
    required this.url,
    this.isDirty = false,
    this.isNew = false,
  });

  /// Returns a copy of this tab with optionally updated fields.
  RequestTab copyWith({
    String? id,
    String? requestId,
    String? name,
    CourierHttpMethod? method,
    String? url,
    bool? isDirty,
    bool? isNew,
  }) {
    return RequestTab(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      isDirty: isDirty ?? this.isDirty,
      isNew: isNew ?? this.isNew,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab State
// ─────────────────────────────────────────────────────────────────────────────

/// Ordered list of open request tabs in the Courier tab bar.
final openRequestTabsProvider = StateProvider<List<RequestTab>>((ref) => []);

/// ID of the currently active (focused) request tab, or null if no tab is open.
final activeRequestTabProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Pane Layout State
// ─────────────────────────────────────────────────────────────────────────────

/// Width in pixels of the collection sidebar (left pane).
///
/// Clamped to [200, 400]. Default: 280.
final sidebarWidthProvider = StateProvider<double>((ref) => 280);

/// Width in pixels of the response viewer (right pane).
///
/// Clamped to [300, ∞]. Default: 400.
final responsePaneWidthProvider = StateProvider<double>((ref) => 400);

/// Whether the response pane is collapsed (zero-width, hidden).
final responsePaneCollapsedProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar State
// ─────────────────────────────────────────────────────────────────────────────

/// ID of the collection currently selected / expanded in the sidebar.
final selectedCollectionIdProvider = StateProvider<String?>((ref) => null);

/// Search query for filtering the collection tree in the sidebar.
final sidebarSearchQueryProvider = StateProvider<String>((ref) => '');

// ─────────────────────────────────────────────────────────────────────────────
// Environment State
// ─────────────────────────────────────────────────────────────────────────────

/// ID of the currently active environment, or null for "No Environment".
final activeEnvironmentIdProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Panel Visibility
// ─────────────────────────────────────────────────────────────────────────────

/// Whether the bottom console panel is visible.
final consoleVisibleProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar Tree State (CCF-002)
// ─────────────────────────────────────────────────────────────────────────────

/// Sort order for the collection sidebar.
enum SidebarSortOrder {
  /// Preserves the server-defined manual sort order.
  manual,

  /// Sorts collections and folders alphabetically by name.
  alphabetical,
}

/// Set of node IDs (collections and folders) that are currently expanded
/// in the sidebar tree.
///
/// Uses string IDs from [CollectionSummaryResponse.id] and
/// [FolderTreeResponse.id].
final expandedNodesProvider = StateProvider<Set<String>>((ref) => {});

/// ID of the currently selected node (collection, folder, or request)
/// in the sidebar tree, or null when nothing is selected.
final selectedNodeIdProvider = StateProvider<String?>((ref) => null);

/// Current sort order for the collection sidebar.
final sidebarSortProvider =
    StateProvider<SidebarSortOrder>((ref) => SidebarSortOrder.manual);

// ─────────────────────────────────────────────────────────────────────────────
// Request Edit State (CCF-003)
// ─────────────────────────────────────────────────────────────────────────────

// Sentinel used to distinguish "not set" from null in copyWith.
const _absent = Object();

/// Per-request connection and transport settings.
class RequestSettingsState {
  /// Whether to follow 3xx redirects automatically.
  final bool followRedirects;

  /// Request timeout in milliseconds.
  final int timeoutMs;

  /// Whether to verify SSL/TLS certificates.
  final bool sslVerify;

  /// Optional HTTP proxy URL.
  final String? proxyUrl;

  /// Creates a [RequestSettingsState] with defaults.
  const RequestSettingsState({
    this.followRedirects = true,
    this.timeoutMs = 30000,
    this.sslVerify = true,
    this.proxyUrl,
  });

  /// Returns a copy with optionally updated fields.
  RequestSettingsState copyWith({
    bool? followRedirects,
    int? timeoutMs,
    bool? sslVerify,
    Object? proxyUrl = _absent,
  }) {
    return RequestSettingsState(
      followRedirects: followRedirects ?? this.followRedirects,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      sslVerify: sslVerify ?? this.sslVerify,
      proxyUrl: identical(proxyUrl, _absent) ? this.proxyUrl : proxyUrl as String?,
    );
  }
}

/// Editable state for the request currently displayed in the builder.
///
/// Tracks the method, URL, dirty flag, and transport settings for the active
/// request tab. Updated by the URL bar and settings panel as the user edits.
class RequestEditState {
  /// HTTP method currently selected.
  final CourierHttpMethod method;

  /// URL currently entered (may contain unresolved `{{variables}}`).
  final String url;

  /// Whether the state has unsaved changes relative to the server.
  final bool isDirty;

  /// Transport and connection settings for this request.
  final RequestSettingsState settings;

  /// Creates a [RequestEditState] with defaults.
  const RequestEditState({
    this.method = CourierHttpMethod.get,
    this.url = '',
    this.isDirty = false,
    this.settings = const RequestSettingsState(),
  });

  /// Returns a copy with optionally updated fields.
  RequestEditState copyWith({
    CourierHttpMethod? method,
    String? url,
    bool? isDirty,
    RequestSettingsState? settings,
  }) {
    return RequestEditState(
      method: method ?? this.method,
      url: url ?? this.url,
      isDirty: isDirty ?? this.isDirty,
      settings: settings ?? this.settings,
    );
  }
}

/// Manages [RequestEditState] mutations.
class RequestEditNotifier extends StateNotifier<RequestEditState> {
  /// Creates a [RequestEditNotifier] with default state.
  RequestEditNotifier() : super(const RequestEditState());

  /// Sets the HTTP method and marks the state dirty.
  void setMethod(CourierHttpMethod method) =>
      state = state.copyWith(method: method, isDirty: true);

  /// Sets the URL and marks the state dirty.
  void setUrl(String url) => state = state.copyWith(url: url, isDirty: true);

  /// Updates transport settings without affecting the dirty flag.
  void setSettings(RequestSettingsState settings) =>
      state = state.copyWith(settings: settings);

  /// Loads a complete state (e.g. when switching tabs) and marks it clean.
  void load(RequestEditState newState) =>
      state = newState.copyWith(isDirty: false);

  /// Clears the dirty flag after a successful save.
  void markClean() => state = state.copyWith(isDirty: false);

  /// Resets to defaults (used when a new empty tab is opened).
  void reset() => state = const RequestEditState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Execution State (CCF-003)
// ─────────────────────────────────────────────────────────────────────────────

/// Status of an HTTP execution initiated from the request builder.
enum ExecutionStatus {
  /// No execution in progress; waiting for user action.
  idle,

  /// Request has been sent and is awaiting a response.
  running,

  /// Response received successfully (check executionResultProvider).
  done,

  /// Execution ended with an error (see [ExecutionState.error]).
  error,
}

/// Tracks whether an HTTP execution is in progress, completed, or errored.
class ExecutionState {
  /// Current execution status.
  final ExecutionStatus status;

  /// Error message when [status] is [ExecutionStatus.error], otherwise null.
  final String? error;

  /// Creates an [ExecutionState].
  const ExecutionState({
    this.status = ExecutionStatus.idle,
    this.error,
  });
}

/// Manages [ExecutionState] transitions.
class ExecutionNotifier extends StateNotifier<ExecutionState> {
  /// Creates an [ExecutionNotifier] in the idle state.
  ExecutionNotifier() : super(const ExecutionState());

  /// Transitions to [ExecutionStatus.running].
  void setRunning() =>
      state = const ExecutionState(status: ExecutionStatus.running);

  /// Transitions to [ExecutionStatus.done].
  void setDone() =>
      state = const ExecutionState(status: ExecutionStatus.done);

  /// Transitions to [ExecutionStatus.error] with [error] message.
  void setError(String error) =>
      state = ExecutionState(status: ExecutionStatus.error, error: error);

  /// Resets to [ExecutionStatus.idle].
  void reset() => state = const ExecutionState();
}

/// The editable state of the active request (method, URL, settings, dirty flag).
final activeRequestStateProvider =
    StateNotifierProvider<RequestEditNotifier, RequestEditState>(
        (ref) => RequestEditNotifier());

/// Whether an HTTP execution is currently in progress.
final executionStateProvider =
    StateNotifierProvider<ExecutionNotifier, ExecutionState>(
        (ref) => ExecutionNotifier());

// ─────────────────────────────────────────────────────────────────────────────
// Params & Headers Edit State (CCF-004)
// ─────────────────────────────────────────────────────────────────────────────

/// Editable query parameters for the active request tab.
///
/// Populated from [RequestResponse.params] when a request is loaded and
/// synced to the server via `PUT .../params` on save.
final requestParamsProvider =
    StateProvider<List<KeyValuePair>>((ref) => []);

/// Editable headers for the active request tab.
///
/// Populated from [RequestResponse.headers] when a request is loaded and
/// synced to the server via `PUT .../headers` on save.
final requestHeadersProvider =
    StateProvider<List<KeyValuePair>>((ref) => []);

/// Path variable overrides for `:name` / `{name}` patterns in the URL.
///
/// Keys are path variable names; values are user-entered replacements.
final pathVariablesProvider =
    StateProvider<Map<String, String>>((ref) => {});

// ─────────────────────────────────────────────────────────────────────────────
// Body Edit State (CCF-005)
// ─────────────────────────────────────────────────────────────────────────────

/// The selected body type for the active request tab.
///
/// Defaults to [BodyType.none]. Updated by the body type selector radio row.
final bodyTypeProvider = StateProvider<BodyType>((ref) => BodyType.none);

/// Raw body content for raw-type bodies (JSON, XML, HTML, Text, YAML).
///
/// Populated from [RequestBodyResponse.rawContent] when a request is loaded.
final bodyRawContentProvider = StateProvider<String>((ref) => '');

/// Form data pairs for form-data and x-www-form-urlencoded bodies.
///
/// Populated from [RequestBodyResponse.formData] when a request is loaded.
final bodyFormDataProvider =
    StateProvider<List<KeyValuePair>>((ref) => []);

/// GraphQL query string for GraphQL body type.
///
/// Populated from [RequestBodyResponse.graphqlQuery] when a request is loaded.
final bodyGraphqlQueryProvider = StateProvider<String>((ref) => '');

/// GraphQL variables JSON string for GraphQL body type.
///
/// Populated from [RequestBodyResponse.graphqlVariables] when loaded.
final bodyGraphqlVariablesProvider = StateProvider<String>((ref) => '');

/// Binary file name for binary body type.
///
/// Populated from [RequestBodyResponse.binaryFileName] when loaded.
final bodyBinaryFileNameProvider = StateProvider<String>((ref) => '');

