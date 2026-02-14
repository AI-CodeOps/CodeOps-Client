/// Abstract VCS (Version Control System) provider interface.
///
/// Defines the contract for remote VCS operations (e.g. GitHub, GitLab).
/// Concrete implementations handle provider-specific API calls.
library;

import '../../models/vcs_models.dart';

/// Abstract interface for interacting with a remote VCS provider.
abstract class VcsProvider {
  /// Authenticates with the provider using [credentials].
  ///
  /// Returns `true` if authentication succeeds.
  Future<bool> authenticate(VcsCredentials credentials);

  /// Whether the provider is currently authenticated.
  bool get isAuthenticated;

  /// Fetches organizations (or user accounts) accessible by the token.
  Future<List<VcsOrganization>> getOrganizations();

  /// Fetches repositories for the given [org] login.
  ///
  /// [page] and [perPage] control pagination.
  Future<List<VcsRepository>> getRepositories(
    String org, {
    int page = 1,
    int perPage = 30,
  });

  /// Searches repositories matching [query].
  Future<List<VcsRepository>> searchRepositories(String query);

  /// Fetches a single repository by [fullName] (owner/repo).
  Future<VcsRepository> getRepository(String fullName);

  /// Fetches branches for a repository by [fullName].
  Future<List<VcsBranch>> getBranches(String fullName);

  /// Fetches pull requests for a repository by [fullName].
  ///
  /// [state] can be "open", "closed", or "all".
  Future<List<VcsPullRequest>> getPullRequests(
    String fullName, {
    String state = 'open',
  });

  /// Creates a pull request on repository [fullName].
  Future<VcsPullRequest> createPullRequest(
    String fullName,
    CreatePRRequest request,
  );

  /// Merges a pull request [prNumber] on repository [fullName].
  Future<bool> mergePullRequest(String fullName, int prNumber);

  /// Fetches commit history for a repository by [fullName].
  ///
  /// Optional [sha] specifies the branch/tag/sha to start from.
  Future<List<VcsCommit>> getCommitHistory(
    String fullName, {
    String? sha,
    int perPage = 30,
  });

  /// Fetches GitHub Actions workflow runs for a repository by [fullName].
  Future<List<WorkflowRun>> getWorkflowRuns(
    String fullName, {
    int perPage = 10,
  });

  /// Fetches releases/tags for a repository by [fullName].
  Future<List<VcsTag>> getReleases(String fullName);
}
