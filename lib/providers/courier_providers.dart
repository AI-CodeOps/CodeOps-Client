/// Riverpod providers for the Courier module.
///
/// Manages state, exposes API data, handles filtering/sorting, and
/// provides the reactive layer between [CourierApiService] and the UI pages.
/// Follows the same patterns as [logger_providers.dart]:
/// [Provider] for singletons, [FutureProvider] for async data,
/// [FutureProvider.family] for parameterized queries,
/// [StateProvider] for UI state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/courier_enums.dart';
import '../models/courier_models.dart';
import '../models/health_snapshot.dart';
import '../models/registry_models.dart';
import '../services/cloud/courier_api.dart';
import '../services/courier/http_execution_service.dart';
import '../services/courier/variable_resolution_service.dart';
import 'auth_providers.dart';
import 'registry_providers.dart';
import 'team_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core Singleton Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [CourierApiService] singleton for all Courier API calls.
///
/// Uses [apiClientProvider] from [auth_providers.dart] since Courier
/// is a module within the consolidated CodeOps-Server.
final courierApiProvider = Provider<CourierApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return CourierApiService(client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Collections — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all collections for the selected team.
final courierCollectionsProvider =
    FutureProvider<List<CollectionSummaryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getCollections(teamId);
});

/// Fetches paginated collections for the selected team.
final courierCollectionsPagedProvider =
    FutureProvider<PageResponse<CollectionSummaryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(courierApiProvider);
  final page = ref.watch(courierCollectionPageProvider);
  return api.getCollectionsPaged(teamId, page: page);
});

/// Fetches a single collection by ID.
final courierCollectionDetailProvider =
    FutureProvider.family<CollectionResponse, String>(
        (ref, collectionId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) throw StateError('No team selected');
  final api = ref.watch(courierApiProvider);
  return api.getCollection(teamId, collectionId);
});

/// Searches collections by query string.
final courierCollectionSearchProvider =
    FutureProvider<List<CollectionSummaryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final search = ref.watch(courierCollectionSearchQueryProvider);
  if (search.isEmpty) return [];
  final api = ref.watch(courierApiProvider);
  return api.searchCollections(teamId, query: search);
});

/// Fetches the folder tree for a collection.
final courierCollectionTreeProvider =
    FutureProvider.family<List<FolderTreeResponse>, String>(
        (ref, collectionId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getCollectionTree(teamId, collectionId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Collections — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the collections list.
final courierCollectionPageProvider = StateProvider<int>((ref) => 0);

/// ID of the currently selected collection.
final selectedCourierCollectionIdProvider =
    StateProvider<String?>((ref) => null);

/// Search query for collections.
final courierCollectionSearchQueryProvider =
    StateProvider<String>((ref) => '');

// ─────────────────────────────────────────────────────────────────────────────
// Folders — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a single folder by ID.
final courierFolderDetailProvider =
    FutureProvider.family<FolderResponse, String>((ref, folderId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) throw StateError('No team selected');
  final api = ref.watch(courierApiProvider);
  return api.getFolder(teamId, folderId);
});

/// Fetches subfolders of a folder.
final courierSubfoldersProvider =
    FutureProvider.family<List<FolderResponse>, String>((ref, folderId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getSubfolders(teamId, folderId);
});

/// Fetches requests within a folder.
final courierFolderRequestsProvider =
    FutureProvider.family<List<RequestSummaryResponse>, String>(
        (ref, folderId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getFolderRequests(teamId, folderId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Folders — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// ID of the currently selected folder.
final selectedCourierFolderIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Requests — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a single request by ID (includes headers, params, body, auth, scripts).
final courierRequestDetailProvider =
    FutureProvider.family<RequestResponse, String>((ref, requestId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) throw StateError('No team selected');
  final api = ref.watch(courierApiProvider);
  return api.getRequest(teamId, requestId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Requests — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// ID of the currently selected request.
final selectedCourierRequestIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Environments — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all environments for the selected team.
final courierEnvironmentsProvider =
    FutureProvider<List<EnvironmentResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getEnvironments(teamId);
});

/// Fetches the active environment for the selected team.
final courierActiveEnvironmentProvider =
    FutureProvider<EnvironmentResponse?>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return null;
  final api = ref.watch(courierApiProvider);
  return api.getActiveEnvironment(teamId);
});

/// Fetches a single environment by ID.
final courierEnvironmentDetailProvider =
    FutureProvider.family<EnvironmentResponse, String>(
        (ref, environmentId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) throw StateError('No team selected');
  final api = ref.watch(courierApiProvider);
  return api.getEnvironment(teamId, environmentId);
});

/// Fetches variables for an environment.
final courierEnvironmentVariablesProvider =
    FutureProvider.family<List<EnvironmentVariableResponse>, String>(
        (ref, environmentId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getEnvironmentVariables(teamId, environmentId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Environments — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// ID of the currently selected environment.
final selectedCourierEnvironmentIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Global Variables — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all global variables for the selected team.
final courierGlobalVariablesProvider =
    FutureProvider<List<GlobalVariableResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getGlobalVariables(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// History — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated request history for the selected team.
final courierHistoryProvider =
    FutureProvider<PageResponse<RequestHistoryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(courierApiProvider);
  final page = ref.watch(courierHistoryPageProvider);
  return api.getHistory(teamId, page: page);
});

/// Fetches a history entry by ID.
final courierHistoryDetailProvider =
    FutureProvider.family<RequestHistoryDetailResponse, String>(
        (ref, historyId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) throw StateError('No team selected');
  final api = ref.watch(courierApiProvider);
  return api.getHistoryEntry(teamId, historyId);
});

/// Fetches history filtered by HTTP method.
final courierHistoryByMethodProvider =
    FutureProvider<PageResponse<RequestHistoryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final method = ref.watch(courierHistoryMethodFilterProvider);
  if (method == null) return PageResponse.empty();
  final api = ref.watch(courierApiProvider);
  final page = ref.watch(courierHistoryPageProvider);
  return api.getHistoryByMethod(teamId, method, page: page);
});

// ─────────────────────────────────────────────────────────────────────────────
// History — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for the history list.
final courierHistoryPageProvider = StateProvider<int>((ref) => 0);

/// HTTP method filter for history (null = all methods).
final courierHistoryMethodFilterProvider =
    StateProvider<CourierHttpMethod?>((ref) => null);

/// Search query for history.
final courierHistorySearchProvider = StateProvider<String>((ref) => '');

/// Searches history by URL query string.
final courierHistorySearchResultsProvider =
    FutureProvider<List<RequestHistoryResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final query = ref.watch(courierHistorySearchProvider);
  if (query.trim().isEmpty) return [];
  final api = ref.watch(courierApiProvider);
  return api.searchHistory(teamId, query: query);
});

/// The currently selected history entry ID (drives the detail panel).
final selectedHistoryEntryProvider = StateProvider<String?>((ref) => null);

/// Status code filter for history (null = all).
final courierHistoryStatusFilterProvider =
    StateProvider<int?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Sharing — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches shares for a collection.
final courierCollectionSharesProvider =
    FutureProvider.family<List<CollectionShareResponse>, String>(
        (ref, collectionId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getCollectionShares(teamId, collectionId);
});

/// Fetches collections shared with the current user.
final courierSharedWithMeProvider =
    FutureProvider<List<CollectionShareResponse>>((ref) {
  final api = ref.watch(courierApiProvider);
  return api.getSharedWithMe();
});

// ─────────────────────────────────────────────────────────────────────────────
// Forking — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches forks of a collection.
final courierCollectionForksProvider =
    FutureProvider.family<List<ForkResponse>, String>(
        (ref, collectionId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getCollectionForks(teamId, collectionId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Runner — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches paginated run results for the selected team.
final courierRunResultsProvider =
    FutureProvider<PageResponse<RunResultResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(courierApiProvider);
  final page = ref.watch(courierRunResultPageProvider);
  return api.getRunResults(teamId, page: page);
});

/// Fetches a single run result by ID.
final courierRunResultDetailProvider =
    FutureProvider.family<RunResultDetailResponse, String>(
        (ref, runResultId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) throw StateError('No team selected');
  final api = ref.watch(courierApiProvider);
  return api.getRunResultDetail(teamId, runResultId);
});

/// Fetches run results for a specific collection.
final courierRunResultsByCollectionProvider =
    FutureProvider.family<List<RunResultResponse>, String>(
        (ref, collectionId) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(courierApiProvider);
  return api.getRunResultsByCollection(teamId, collectionId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Runner — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current page index for run results.
final courierRunResultPageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Code Generation — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches available code generation languages.
final courierCodeLanguagesProvider =
    FutureProvider<List<CodeSnippetResponse>>((ref) {
  final api = ref.watch(courierApiProvider);
  return api.getCodeLanguages();
});

// ─────────────────────────────────────────────────────────────────────────────
// Courier Services (CCF-003)
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [VariableResolutionService] singleton.
///
/// Resolves `{{variableName}}` tokens in URLs, headers, and bodies.
final variableResolutionServiceProvider =
    Provider<VariableResolutionService>((ref) => VariableResolutionService());

/// Provides the [HttpExecutionService] singleton.
///
/// Fires HTTP requests directly from the desktop client via Dio.
final httpExecutionServiceProvider =
    Provider<HttpExecutionService>((ref) => HttpExecutionService());

/// Stores the result of the last HTTP execution, or null when no request has
/// been fired in the current session.
final executionResultProvider =
    StateProvider<HttpExecutionResult?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Registry Integration (CCF-014)
// ─────────────────────────────────────────────────────────────────────────────

/// Re-exports registry services for Courier's service discovery panel.
///
/// Returns all active services registered in the Registry for the current
/// team. Consumed by [RegistryServicePanel].
final registryServicesForCourierProvider =
    FutureProvider<List<ServiceRegistrationResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api
      .getServicesForTeam(teamId)
      .then((page) => page.content);
});

/// Fetches API routes for a single service.
///
/// Used by the service discovery panel and URL autocomplete to suggest
/// registered route prefixes for a given service.
final serviceApiRoutesProvider =
    FutureProvider.family<List<ApiRouteResponse>, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getRoutesForService(serviceId);
});

/// Fetches ports for a single service (dev environment).
///
/// Used to construct base URLs like `http://localhost:{port}`.
final servicePortsForCourierProvider =
    FutureProvider.family<List<PortAllocationResponse>, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getPortsForService(serviceId, environment: 'dev');
});
