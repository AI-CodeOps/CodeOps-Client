/// Riverpod providers for the Registry module.
///
/// Manages state, exposes API data, handles filtering/sorting, and
/// provides the reactive layer between [RegistryApi] and the UI pages.
/// Follows the same patterns as [vault_providers.dart]:
/// [Provider] for singletons, [FutureProvider] for async data,
/// [FutureProvider.family] for parameterized queries,
/// [StateProvider] for UI state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/registry_enums.dart';
import '../models/registry_models.dart';
import '../services/cloud/registry_api.dart';
import '../services/cloud/registry_api_client.dart';
import 'auth_providers.dart';
import 'team_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core Singleton Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [RegistryApiClient] singleton, configured for port 8096.
final registryApiClientProvider = Provider<RegistryApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return RegistryApiClient(secureStorage: secureStorage);
});

/// Provides the [RegistryApi] singleton for all Registry API calls.
final registryApiProvider = Provider<RegistryApi>((ref) {
  final client = ref.watch(registryApiClientProvider);
  return RegistryApi(client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Services — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a paginated service list for the selected team with filters.
final registryServicesProvider =
    FutureProvider<PageResponse<ServiceRegistrationResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(registryApiProvider);
  final status = ref.watch(registryServiceStatusFilterProvider);
  final type = ref.watch(registryServiceTypeFilterProvider);
  final search = ref.watch(registryServiceSearchProvider);
  final page = ref.watch(registryServicePageProvider);
  return api.getServicesForTeam(
    teamId,
    status: status,
    type: type,
    search: search.isEmpty ? null : search,
    page: page,
  );
});

/// Fetches a single service by ID.
final registryServiceDetailProvider =
    FutureProvider.family<ServiceRegistrationResponse, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getService(serviceId);
});

/// Fetches the complete service identity.
final registryServiceIdentityProvider =
    FutureProvider.family<ServiceIdentityResponse, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getServiceIdentity(serviceId);
});

/// Fetches a service by team and slug.
final registryServiceBySlugProvider =
    FutureProvider.family<ServiceRegistrationResponse,
        ({String teamId, String slug})>((ref, params) {
  final api = ref.watch(registryApiProvider);
  return api.getServiceBySlug(params.teamId, params.slug);
});

// ─────────────────────────────────────────────────────────────────────────────
// Services — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Currently selected service status filter (null = all statuses).
final registryServiceStatusFilterProvider =
    StateProvider<ServiceStatus?>((ref) => null);

/// Currently selected service type filter (null = all types).
final registryServiceTypeFilterProvider =
    StateProvider<ServiceType?>((ref) => null);

/// Current search query for services.
final registryServiceSearchProvider = StateProvider<String>((ref) => '');

/// Current page index for the services list.
final registryServicePageProvider = StateProvider<int>((ref) => 0);

/// ID of the currently selected service.
final selectedRegistryServiceIdProvider =
    StateProvider<String?>((ref) => null);

/// Currently selected health filter for the service list (null = all).
final registryServiceHealthFilterProvider =
    StateProvider<HealthStatus?>((ref) => null);

/// Sort field for the service list table.
final registryServiceSortFieldProvider =
    StateProvider<String>((ref) => 'name');

/// Sort direction for the service list table.
final registryServiceSortAscendingProvider =
    StateProvider<bool>((ref) => true);

/// Page size for client-side pagination of the service list.
final registryServicePageSizeProvider = StateProvider<int>((ref) => 10);

/// Filtered, sorted service list derived from [registryServicesProvider].
///
/// Applies search, status, type, and health filters client-side, then sorts
/// by the currently selected sort field.
final filteredRegistryServicesProvider =
    Provider<List<ServiceRegistrationResponse>>((ref) {
  final page = ref.watch(registryServicesProvider);
  final services = page.valueOrNull?.content ?? [];
  final search = ref.watch(registryServiceSearchProvider).toLowerCase();
  final statusFilter = ref.watch(registryServiceStatusFilterProvider);
  final typeFilter = ref.watch(registryServiceTypeFilterProvider);
  final healthFilter = ref.watch(registryServiceHealthFilterProvider);
  final sortField = ref.watch(registryServiceSortFieldProvider);
  final sortAsc = ref.watch(registryServiceSortAscendingProvider);

  var result = services.toList();

  // Search filter
  if (search.isNotEmpty) {
    result = result
        .where((s) =>
            s.name.toLowerCase().contains(search) ||
            s.slug.toLowerCase().contains(search) ||
            (s.description?.toLowerCase().contains(search) ?? false))
        .toList();
  }

  // Status filter
  if (statusFilter != null) {
    result = result.where((s) => s.status == statusFilter).toList();
  }

  // Type filter
  if (typeFilter != null) {
    result = result.where((s) => s.serviceType == typeFilter).toList();
  }

  // Health filter
  if (healthFilter != null) {
    result =
        result.where((s) => s.lastHealthStatus == healthFilter).toList();
  }

  // Sort
  result.sort((a, b) {
    final cmp = switch (sortField) {
      'name' => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      'type' => a.serviceType.displayName
          .compareTo(b.serviceType.displayName),
      'status' => a.status.displayName.compareTo(b.status.displayName),
      'health' => (a.lastHealthStatus?.displayName ?? '')
          .compareTo(b.lastHealthStatus?.displayName ?? ''),
      'lastCheck' => (a.lastHealthCheckAt ?? DateTime(2000))
          .compareTo(b.lastHealthCheckAt ?? DateTime(2000)),
      _ => 0,
    };
    return sortAsc ? cmp : -cmp;
  });

  return result;
});

/// Paginated slice of filtered services for display.
final paginatedRegistryServicesProvider =
    Provider<List<ServiceRegistrationResponse>>((ref) {
  final all = ref.watch(filteredRegistryServicesProvider);
  final page = ref.watch(registryServicePageProvider);
  final pageSize = ref.watch(registryServicePageSizeProvider);
  final start = (page * pageSize).clamp(0, all.length);
  final end = (start + pageSize).clamp(0, all.length);
  return all.sublist(start, end);
});

/// Total count of filtered services (for pagination display).
final filteredRegistryServiceCountProvider = Provider<int>((ref) {
  return ref.watch(filteredRegistryServicesProvider).length;
});

// ─────────────────────────────────────────────────────────────────────────────
// Solutions — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a paginated solution list for the selected team with filters.
final registrySolutionsProvider =
    FutureProvider<PageResponse<SolutionResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(registryApiProvider);
  final status = ref.watch(registrySolutionStatusFilterProvider);
  final category = ref.watch(registrySolutionCategoryFilterProvider);
  final page = ref.watch(registrySolutionPageProvider);
  return api.getSolutionsForTeam(
    teamId,
    status: status,
    category: category,
    page: page,
  );
});

/// Fetches a single solution by ID.
final registrySolutionDetailProvider =
    FutureProvider.family<SolutionResponse, String>((ref, solutionId) {
  final api = ref.watch(registryApiProvider);
  return api.getSolution(solutionId);
});

/// Fetches full solution detail including member list.
final registrySolutionFullDetailProvider =
    FutureProvider.family<SolutionDetailResponse, String>(
        (ref, solutionId) {
  final api = ref.watch(registryApiProvider);
  return api.getSolutionDetail(solutionId);
});

/// Fetches aggregated health status for a solution.
final registrySolutionHealthProvider =
    FutureProvider.family<SolutionHealthResponse, String>(
        (ref, solutionId) {
  final api = ref.watch(registryApiProvider);
  return api.getSolutionHealth(solutionId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Solutions — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Currently selected solution status filter (null = all statuses).
final registrySolutionStatusFilterProvider =
    StateProvider<SolutionStatus?>((ref) => null);

/// Currently selected solution category filter (null = all categories).
final registrySolutionCategoryFilterProvider =
    StateProvider<SolutionCategory?>((ref) => null);

/// Current page index for the solutions list.
final registrySolutionPageProvider = StateProvider<int>((ref) => 0);

/// ID of the currently selected solution.
final selectedRegistrySolutionIdProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Dependencies — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the complete dependency graph for the selected team.
final registryDependencyGraphProvider =
    FutureProvider<DependencyGraphResponse>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) {
    return const DependencyGraphResponse(teamId: '', nodes: [], edges: []);
  }
  final api = ref.watch(registryApiProvider);
  return api.getDependencyGraph(teamId);
});

/// Performs impact analysis from a source service.
final registryImpactAnalysisProvider =
    FutureProvider.family<ImpactAnalysisResponse, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getImpactAnalysis(serviceId);
});

/// Computes topological startup order for the selected team.
final registryStartupOrderProvider =
    FutureProvider<List<DependencyNodeResponse>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api.getStartupOrder(teamId);
});

/// Detects cycles in the team's dependency graph.
final registryCyclesProvider = FutureProvider<List<String>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api.detectCycles(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Ports — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches port allocations for a service.
final registryPortsForServiceProvider =
    FutureProvider.family<List<PortAllocationResponse>, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getPortsForService(serviceId);
});

/// Fetches the structured port map for the selected team.
final registryPortMapProvider =
    FutureProvider<PortMapResponse?>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  final environment = ref.watch(registryPortEnvironmentProvider);
  if (teamId == null) return null;
  final api = ref.watch(registryApiProvider);
  return api.getPortMap(teamId, environment: environment);
});

/// Fetches port ranges for the selected team.
final registryPortRangesProvider =
    FutureProvider<List<PortRangeResponse>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api.getPortRanges(teamId);
});

/// Detects port conflicts for the selected team.
final registryPortConflictsProvider =
    FutureProvider<List<PortConflictResponse>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api.detectPortConflicts(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Ports — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Current environment filter for ports (defaults to "local").
final registryPortEnvironmentProvider =
    StateProvider<String>((ref) => 'local');

// ─────────────────────────────────────────────────────────────────────────────
// Routes — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches routes for a service.
final registryRoutesForServiceProvider =
    FutureProvider.family<List<ApiRouteResponse>, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getRoutesForService(serviceId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Config — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all config templates for a service.
final registryConfigTemplatesProvider =
    FutureProvider.family<List<ConfigTemplateResponse>, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getTemplatesForService(serviceId);
});

// ─────────────────────────────────────────────────────────────────────────────
// InfraResources — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a paginated infrastructure resource list for the selected team.
final registryInfraResourcesProvider =
    FutureProvider<PageResponse<InfraResourceResponse>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final api = ref.watch(registryApiProvider);
  final type = ref.watch(registryInfraTypeFilterProvider);
  final environment = ref.watch(registryInfraEnvironmentFilterProvider);
  final page = ref.watch(registryInfraPageProvider);
  return api.getInfraResourcesForTeam(
    teamId,
    type: type,
    environment: environment.isEmpty ? null : environment,
    page: page,
  );
});

/// Fetches infrastructure resources for a service.
final registryInfraResourcesForServiceProvider =
    FutureProvider.family<List<InfraResourceResponse>, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getInfraResourcesForService(serviceId);
});

/// Fetches orphaned resources for the selected team.
final registryOrphanedResourcesProvider =
    FutureProvider<List<InfraResourceResponse>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api.findOrphanedResources(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// InfraResources — UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Currently selected infra resource type filter (null = all types).
final registryInfraTypeFilterProvider =
    StateProvider<InfraResourceType?>((ref) => null);

/// Current environment filter for infra resources.
final registryInfraEnvironmentFilterProvider =
    StateProvider<String>((ref) => '');

/// Current page index for the infra resources list.
final registryInfraPageProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// Topology — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the full ecosystem topology for the selected team.
final registryTopologyProvider =
    FutureProvider<TopologyResponse?>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return null;
  final api = ref.watch(registryApiProvider);
  return api.getTopology(teamId);
});

/// Fetches topology for a specific solution.
final registrySolutionTopologyProvider =
    FutureProvider.family<TopologyResponse, String>(
        (ref, solutionId) {
  final api = ref.watch(registryApiProvider);
  return api.getSolutionTopology(solutionId);
});

/// Fetches topology neighborhood for a service.
final registryServiceNeighborhoodProvider =
    FutureProvider.family<TopologyResponse, String>((ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getServiceNeighborhood(serviceId);
});

/// Fetches ecosystem statistics for the selected team.
final registryEcosystemStatsProvider =
    FutureProvider<TopologyStatsResponse?>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return null;
  final api = ref.watch(registryApiProvider);
  return api.getEcosystemStats(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Health Management — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the team health summary (cached data).
final registryTeamHealthSummaryProvider =
    FutureProvider<TeamHealthSummaryResponse?>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return null;
  final api = ref.watch(registryApiProvider);
  return api.getTeamHealthSummary(teamId);
});

/// Fetches unhealthy services for the selected team.
final registryUnhealthyServicesProvider =
    FutureProvider<List<ServiceHealthResponse>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api.getUnhealthyServices(teamId);
});

/// Fetches services that have never been health-checked.
final registryNeverCheckedServicesProvider =
    FutureProvider<List<ServiceHealthResponse>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api.getServicesNeverChecked(teamId);
});

/// Fetches cached health status for a single service.
final registryServiceHealthCachedProvider =
    FutureProvider.family<ServiceHealthResponse, String>(
        (ref, serviceId) {
  final api = ref.watch(registryApiProvider);
  return api.getServiceHealthCached(serviceId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Workstations — Data Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all workstation profiles for the selected team.
final registryWorkstationProfilesProvider =
    FutureProvider<List<WorkstationProfileResponse>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(registryApiProvider);
  return api.getWorkstationProfilesForTeam(teamId);
});

/// Fetches a single workstation profile by ID.
final registryWorkstationProfileDetailProvider =
    FutureProvider.family<WorkstationProfileResponse, String>(
        (ref, profileId) {
  final api = ref.watch(registryApiProvider);
  return api.getWorkstationProfile(profileId);
});

/// Fetches the default workstation profile for the selected team.
final registryDefaultWorkstationProvider =
    FutureProvider<WorkstationProfileResponse?>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return null;
  final api = ref.watch(registryApiProvider);
  return api.getDefaultWorkstationProfile(teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Navigation State
// ─────────────────────────────────────────────────────────────────────────────

/// Active registry tab index.
///
/// 0=Services, 1=Solutions, 2=Ports, 3=Dependencies, 4=Topology,
/// 5=Infrastructure, 6=Config, 7=Health, 8=Workstations.
final registryActiveTabProvider = StateProvider<int>((ref) => 0);
