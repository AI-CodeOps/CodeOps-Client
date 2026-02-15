/// Riverpod providers for GitHub connection data and VCS operations.
///
/// Connection data comes from the cloud service. Local git operations
/// and GitHub API calls are provided by the VCS service layer (COC-004).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/vcs_models.dart';
import '../services/logging/log_service.dart';
import '../services/vcs/git_service.dart';
import '../services/vcs/github_provider.dart';
import '../services/vcs/repo_manager.dart';
import '../services/vcs/vcs_provider.dart' as vcs;
import 'auth_providers.dart';
import 'task_providers.dart';
import 'team_providers.dart';

// ---------------------------------------------------------------------------
// Cloud connection provider (COC-003 — unchanged)
// ---------------------------------------------------------------------------

/// Fetches GitHub connections for the selected team.
final githubConnectionsProvider =
    FutureProvider<List<GitHubConnection>>((ref) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  log.d('GitHubProviders', 'Loading GitHub connections for teamId=$teamId');
  final integrationApi = ref.watch(integrationApiProvider);
  return integrationApi.getTeamGitHubConnections(teamId);
});

// ---------------------------------------------------------------------------
// Service providers
// ---------------------------------------------------------------------------

/// Provides the [GitHubProvider] singleton for GitHub REST API calls.
final vcsProviderProvider = Provider<vcs.VcsProvider>((ref) {
  return GitHubProvider();
});

/// Provides the [GitService] singleton for local git CLI operations.
final gitServiceProvider = Provider<GitService>((ref) {
  return GitService();
});

/// Provides the [RepoManager] singleton for tracking cloned repos.
final repoManagerProvider = Provider<RepoManager>((ref) {
  final gitService = ref.watch(gitServiceProvider);
  final database = ref.watch(databaseProvider);
  return RepoManager(gitService: gitService, database: database);
});

// ---------------------------------------------------------------------------
// State providers
// ---------------------------------------------------------------------------

/// Whether the VCS provider is authenticated.
final vcsAuthenticatedProvider = StateProvider<bool>((ref) => false);

/// Current VCS credentials (stored in secure storage, loaded at startup).
final vcsCredentialsProvider = StateProvider<VcsCredentials?>((ref) => null);

/// Currently selected GitHub organization login.
final selectedOrgProvider = StateProvider<String?>((ref) => null);

/// Currently selected repository full name (owner/repo).
final selectedRepoProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

/// Fetches GitHub organizations for the authenticated user.
final githubOrgsProvider =
    FutureProvider<List<VcsOrganization>>((ref) async {
  final authenticated = ref.watch(vcsAuthenticatedProvider);
  if (!authenticated) {
    log.w('GitHubProviders', 'Skipping org fetch - not authenticated');
    return [];
  }
  log.d('GitHubProviders', 'Loading GitHub organizations');
  final provider = ref.watch(vcsProviderProvider);
  return provider.getOrganizations();
});

/// Fetches repositories for a given organization login.
final orgReposProvider =
    FutureProvider.family<List<VcsRepository>, String>((ref, org) async {
  final authenticated = ref.watch(vcsAuthenticatedProvider);
  if (!authenticated) return [];
  final provider = ref.watch(vcsProviderProvider);
  return provider.getRepositories(org);
});

/// Searches repositories matching a query string.
final repoSearchResultsProvider =
    FutureProvider.family<List<VcsRepository>, String>((ref, query) async {
  if (query.length < 2) return [];
  final authenticated = ref.watch(vcsAuthenticatedProvider);
  if (!authenticated) return [];
  final provider = ref.watch(vcsProviderProvider);
  return provider.searchRepositories(query);
});

/// Fetches branches for a repository by full name.
final repoBranchesProvider =
    FutureProvider.family<List<VcsBranch>, String>((ref, fullName) async {
  final provider = ref.watch(vcsProviderProvider);
  return provider.getBranches(fullName);
});

/// Fetches pull requests for a repository by full name.
final repoPullRequestsProvider =
    FutureProvider.family<List<VcsPullRequest>, String>(
        (ref, fullName) async {
  final provider = ref.watch(vcsProviderProvider);
  return provider.getPullRequests(fullName);
});

/// Fetches commit history for a repository by full name.
final repoCommitsProvider =
    FutureProvider.family<List<VcsCommit>, String>((ref, fullName) async {
  final provider = ref.watch(vcsProviderProvider);
  return provider.getCommitHistory(fullName);
});

/// Fetches workflow runs for a repository by full name.
final repoWorkflowsProvider =
    FutureProvider.family<List<WorkflowRun>, String>((ref, fullName) async {
  final provider = ref.watch(vcsProviderProvider);
  return provider.getWorkflowRuns(fullName);
});

/// Returns the repo status for the currently selected repo, if cloned.
final selectedRepoStatusProvider = FutureProvider<RepoStatus?>((ref) async {
  final fullName = ref.watch(selectedRepoProvider);
  if (fullName == null) return null;
  final repoManager = ref.watch(repoManagerProvider);
  return repoManager.getRepoStatus(fullName);
});

/// Returns all cloned repos as a map of fullName → localPath.
final clonedReposProvider = FutureProvider<Map<String, String>>((ref) async {
  final repoManager = ref.watch(repoManagerProvider);
  return repoManager.getAllRepos();
});

// ---------------------------------------------------------------------------
// Master-detail layout providers (COC-020)
// ---------------------------------------------------------------------------

/// Selected GitHub organization object for the sidebar org picker.
final selectedGithubOrgProvider = StateProvider<VcsOrganization?>((ref) => null);

/// Selected repository object for the detail panel.
final selectedGithubRepoProvider = StateProvider<VcsRepository?>((ref) => null);

/// Search query text for filtering repos in the sidebar.
final githubRepoSearchQueryProvider = StateProvider<String>((ref) => '');

/// Active tab index in the detail panel (0=README, 1=Branches, 2=PRs, 3=Commits).
final githubDetailTabProvider = StateProvider<int>((ref) => 0);

/// Fetches repositories for the selected GitHub organization.
final githubReposForOrgProvider =
    FutureProvider<List<VcsRepository>>((ref) async {
  final org = ref.watch(selectedGithubOrgProvider);
  if (org == null) return [];
  final authenticated = ref.watch(vcsAuthenticatedProvider);
  if (!authenticated) return [];
  log.d('GitHubProviders', 'Loading repos for org=${org.login}');
  final provider = ref.watch(vcsProviderProvider);
  return provider.getRepositories(org.login, perPage: 100);
});

/// Repos for the selected org, filtered by the search query.
final filteredGithubReposProvider =
    Provider<AsyncValue<List<VcsRepository>>>((ref) {
  final reposAsync = ref.watch(githubReposForOrgProvider);
  final query = ref.watch(githubRepoSearchQueryProvider).toLowerCase();
  return reposAsync.whenData((repos) {
    if (query.isEmpty) return repos;
    return repos
        .where((r) =>
            r.name.toLowerCase().contains(query) ||
            (r.description?.toLowerCase().contains(query) ?? false))
        .toList();
  });
});

/// Fetches the raw README markdown for the selected repository.
final githubReadmeProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final repo = ref.watch(selectedGithubRepoProvider);
  if (repo == null) return null;
  final provider = ref.watch(vcsProviderProvider);
  if (provider is GitHubProvider) {
    return provider.getReadmeContent(repo.fullName);
  }
  return null;
});

/// Fetches branches for the selected repository.
final githubRepoBranchesProvider =
    FutureProvider.autoDispose<List<VcsBranch>>((ref) async {
  final repo = ref.watch(selectedGithubRepoProvider);
  if (repo == null) return [];
  final provider = ref.watch(vcsProviderProvider);
  return provider.getBranches(repo.fullName);
});

/// Fetches pull requests for the selected repository.
final githubRepoPullRequestsProvider =
    FutureProvider.autoDispose<List<VcsPullRequest>>((ref) async {
  final repo = ref.watch(selectedGithubRepoProvider);
  if (repo == null) return [];
  final provider = ref.watch(vcsProviderProvider);
  return provider.getPullRequests(repo.fullName);
});

/// Fetches commit history for the selected repository.
final githubRepoCommitsProvider =
    FutureProvider.autoDispose<List<VcsCommit>>((ref) async {
  final repo = ref.watch(selectedGithubRepoProvider);
  if (repo == null) return [];
  final provider = ref.watch(vcsProviderProvider);
  return provider.getCommitHistory(repo.fullName);
});

/// Whether the selected repository is cloned locally.
final isRepoClonedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(selectedGithubRepoProvider);
  if (repo == null) return false;
  final clonedMap = await ref.watch(clonedReposProvider.future);
  return clonedMap.containsKey(repo.fullName);
});
