/// GitHub REST API v3 implementation of [VcsProvider].
///
/// Uses its own [Dio] instance targeting `https://api.github.com`,
/// separate from the app's [ApiClient] which targets the CodeOps server.
library;

import 'package:dio/dio.dart';

import '../../models/vcs_models.dart';
import '../../services/cloud/api_exceptions.dart';
import '../logging/log_service.dart';
import 'vcs_provider.dart';

/// Implements [VcsProvider] against the GitHub REST API v3.
class GitHubProvider implements VcsProvider {
  final Dio _dio;
  bool _authenticated = false;

  /// Remaining API calls before rate limiting.
  int? rateLimitRemaining;

  /// Unix timestamp when the rate limit resets.
  int? rateLimitReset;

  /// Creates a [GitHubProvider] with an optional custom [Dio] instance.
  GitHubProvider({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.github.com',
              headers: {
                'Accept': 'application/vnd.github.v3+json',
                'X-GitHub-Api-Version': '2022-11-28',
              },
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ));

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<bool> authenticate(VcsCredentials credentials) async {
    _dio.options.headers['Authorization'] = 'Bearer ${credentials.token}';
    try {
      final response = await _dio.get<Map<String, dynamic>>('/user');
      _authenticated = response.statusCode == 200;
      return _authenticated;
    } on DioException catch (e) {
      _authenticated = false;
      _mapDioException(e);
    }
  }

  @override
  Future<List<VcsOrganization>> getOrganizations() async {
    final response = await _get<List<dynamic>>('/user/orgs?per_page=100');
    final orgs = response
        .map((e) => VcsOrganization.fromGitHubJson(e as Map<String, dynamic>))
        .toList();

    // Also include the authenticated user as a pseudo-org.
    try {
      final userResponse = await _get<Map<String, dynamic>>('/user');
      orgs.insert(
        0,
        VcsOrganization(
          login: userResponse['login'] as String,
          name: userResponse['name'] as String?,
          avatarUrl: userResponse['avatar_url'] as String?,
          description: 'Personal repositories',
          publicRepos: userResponse['public_repos'] as int?,
        ),
      );
    } on ApiException {
      // If user endpoint fails, return orgs only.
    }

    return orgs;
  }

  @override
  Future<List<VcsRepository>> getRepositories(
    String org, {
    int page = 1,
    int perPage = 30,
  }) async {
    // Try user repos first (for the authenticated user's own repos).
    try {
      final userResponse = await _get<Map<String, dynamic>>('/user');
      final username = userResponse['login'] as String;
      if (org == username) {
        final response = await _get<List<dynamic>>(
          '/user/repos?per_page=$perPage&page=$page&sort=pushed&affiliation=owner',
        );
        return response
            .map((e) =>
                VcsRepository.fromGitHubJson(e as Map<String, dynamic>))
            .toList();
      }
    } on ApiException {
      // Fall through to org repos.
    }

    final response = await _get<List<dynamic>>(
      '/orgs/$org/repos?per_page=$perPage&page=$page&sort=pushed',
    );
    return response
        .map((e) => VcsRepository.fromGitHubJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VcsRepository>> searchRepositories(String query) async {
    final response = await _get<Map<String, dynamic>>(
      '/search/repositories?q=${Uri.encodeComponent(query)}&per_page=20',
    );
    final items = response['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => VcsRepository.fromGitHubJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VcsRepository> getRepository(String fullName) async {
    final response = await _get<Map<String, dynamic>>('/repos/$fullName');
    return VcsRepository.fromGitHubJson(response);
  }

  @override
  Future<List<VcsBranch>> getBranches(String fullName) async {
    final response =
        await _get<List<dynamic>>('/repos/$fullName/branches?per_page=100');
    return response
        .map((e) => VcsBranch.fromGitHubJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VcsPullRequest>> getPullRequests(
    String fullName, {
    String state = 'open',
  }) async {
    final response = await _get<List<dynamic>>(
      '/repos/$fullName/pulls?state=$state&per_page=30',
    );
    return response
        .map(
            (e) => VcsPullRequest.fromGitHubJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VcsPullRequest> createPullRequest(
    String fullName,
    CreatePRRequest request,
  ) async {
    final response = await _post<Map<String, dynamic>>(
      '/repos/$fullName/pulls',
      data: request.toJson(),
    );
    return VcsPullRequest.fromGitHubJson(response);
  }

  @override
  Future<bool> mergePullRequest(String fullName, int prNumber) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '/repos/$fullName/pulls/$prNumber/merge',
      );
      return true;
    } on DioException catch (e) {
      _mapDioException(e);
    }
  }

  @override
  Future<List<VcsCommit>> getCommitHistory(
    String fullName, {
    String? sha,
    int perPage = 30,
  }) async {
    final query = StringBuffer('/repos/$fullName/commits?per_page=$perPage');
    if (sha != null) query.write('&sha=$sha');
    final response = await _get<List<dynamic>>(query.toString());
    return response
        .map((e) => VcsCommit.fromGitHubJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WorkflowRun>> getWorkflowRuns(
    String fullName, {
    int perPage = 10,
  }) async {
    final response = await _get<Map<String, dynamic>>(
      '/repos/$fullName/actions/runs?per_page=$perPage',
    );
    final runs = response['workflow_runs'] as List<dynamic>? ?? [];
    return runs
        .map((e) => WorkflowRun.fromGitHubJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<VcsTag>> getReleases(String fullName) async {
    final response =
        await _get<List<dynamic>>('/repos/$fullName/releases?per_page=20');
    return response
        .map((e) => VcsTag.fromGitHubJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the raw README markdown for a repository.
  ///
  /// Returns `null` if the repository has no README (404).
  Future<String?> getReadmeContent(String fullName) async {
    try {
      final response = await _dio.get<String>(
        '/repos/$fullName/readme',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3.raw'},
          responseType: ResponseType.plain,
        ),
      );
      _trackRateLimit(response);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        log.d('GitHubProvider', 'No README for $fullName');
        return null;
      }
      _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<T> _get<T>(String path) async {
    try {
      final response = await _dio.get<T>(path);
      _trackRateLimit(response);
      return response.data as T;
    } on DioException catch (e) {
      _mapDioException(e);
    }
  }

  Future<T> _post<T>(String path, {Object? data}) async {
    try {
      final response = await _dio.post<T>(path, data: data);
      _trackRateLimit(response);
      return response.data as T;
    } on DioException catch (e) {
      _mapDioException(e);
    }
  }

  void _trackRateLimit(Response<dynamic> response) {
    final remaining = response.headers.value('X-RateLimit-Remaining');
    final reset = response.headers.value('X-RateLimit-Reset');
    if (remaining != null) rateLimitRemaining = int.tryParse(remaining);
    if (reset != null) rateLimitReset = int.tryParse(reset);
    log.d('GitHubProvider', 'Rate limit remaining: $rateLimitRemaining');
    if (rateLimitRemaining != null && rateLimitRemaining! < 100) {
      log.w('GitHubProvider', 'GitHub API rate limit low: $rateLimitRemaining remaining');
    }
  }

  Never _mapDioException(DioException e) {
    log.e('GitHubProvider', 'API error (status=${e.response?.statusCode})', e);
    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e.response?.data) ?? e.message ?? 'Unknown error';
    switch (statusCode) {
      case 401:
        throw UnauthorizedException('Bad token or token expired: $message');
      case 403:
        throw RateLimitException('GitHub API rate limited: $message');
      case 404:
        throw NotFoundException('Resource not found: $message');
      case 422:
        throw ValidationException('Validation failed: $message');
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw const TimeoutException('GitHub API request timed out');
        }
        if (e.type == DioExceptionType.connectionError) {
          throw const NetworkException('Cannot reach GitHub API');
        }
        throw ServerException(
          'GitHub API error: $message',
          statusCode: statusCode ?? 500,
        );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) return data['message'] as String?;
    return null;
  }
}
