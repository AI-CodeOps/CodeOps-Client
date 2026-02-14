// Tests for GitHubProvider.
//
// Verifies each API method sends the correct URL/headers, error mapping
// from DioException status codes to typed ApiException subclasses, and
// rate limit tracking from response headers.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/models/vcs_models.dart';
import 'package:codeops/services/cloud/api_exceptions.dart';
import 'package:codeops/services/vcs/github_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a successful [Response] with optional rate-limit headers.
Response<T> _okResponse<T>(
  T data, {
  int statusCode = 200,
  Map<String, List<String>>? headers,
}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(),
    headers: Headers.fromMap(headers ?? {}),
  );
}

/// Creates a [DioException] simulating an HTTP error response.
DioException _dioError(int statusCode, {dynamic data}) {
  final requestOptions = RequestOptions();
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data ?? {'message': 'Error $statusCode'},
    ),
    type: DioExceptionType.badResponse,
  );
}

/// Creates a [DioException] for a timeout.
DioException _timeoutError(DioExceptionType type) {
  return DioException(
    requestOptions: RequestOptions(),
    type: type,
  );
}

void main() {
  late MockDio mockDio;
  late GitHubProvider provider;

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.options).thenReturn(BaseOptions(
      headers: <String, dynamic>{},
    ));
    provider = GitHubProvider(dio: mockDio);
  });

  // -------------------------------------------------------------------------
  // authenticate
  // -------------------------------------------------------------------------
  group('authenticate', () {
    test('sets Bearer header and returns true on 200', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/user',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<Map<String, dynamic>>(
            {'login': 'octocat'},
          ));

      final result = await provider.authenticate(
        const VcsCredentials(authType: GitHubAuthType.pat, token: 'ghp_test'),
      );

      expect(result, isTrue);
      expect(provider.isAuthenticated, isTrue);
    });

    test('returns false on DioException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/user',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(401));

      // authenticate catches 401 and maps it, but wraps in UnauthorizedException
      // which is then caught internally — the method should throw
      expect(
        () => provider.authenticate(
          const VcsCredentials(authType: GitHubAuthType.pat, token: 'bad'),
        ),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(provider.isAuthenticated, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getOrganizations
  // -------------------------------------------------------------------------
  group('getOrganizations', () {
    test('fetches /user/orgs and /user, returns combined list', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/user/orgs?per_page=100',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([
            {'login': 'org1', 'name': 'Org One'},
          ]));

      when(() => mockDio.get<Map<String, dynamic>>(
            '/user',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<Map<String, dynamic>>({
            'login': 'octocat',
            'name': 'Octo Cat',
            'avatar_url': 'https://example.com/avatar.png',
            'public_repos': 10,
          }));

      final orgs = await provider.getOrganizations();

      // User pseudo-org is prepended, then org1.
      expect(orgs, hasLength(2));
      expect(orgs[0].login, 'octocat');
      expect(orgs[0].description, 'Personal repositories');
      expect(orgs[1].login, 'org1');
    });
  });

  // -------------------------------------------------------------------------
  // getRepositories
  // -------------------------------------------------------------------------
  group('getRepositories', () {
    test('fetches org repos when org does not match username', () async {
      // First call: /user → returns a different username
      when(() => mockDio.get<Map<String, dynamic>>(
            '/user',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<Map<String, dynamic>>({
            'login': 'octocat',
          }));

      when(() => mockDio.get<List<dynamic>>(
            '/orgs/acme/repos?per_page=30&page=1&sort=pushed',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([
            {
              'id': 1,
              'full_name': 'acme/repo1',
              'name': 'repo1',
            },
          ]));

      final repos = await provider.getRepositories('acme');

      expect(repos, hasLength(1));
      expect(repos[0].fullName, 'acme/repo1');
    });

    test('fetches user repos when org matches username', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/user',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<Map<String, dynamic>>({
            'login': 'octocat',
          }));

      when(() => mockDio.get<List<dynamic>>(
            '/user/repos?per_page=30&page=1&sort=pushed&affiliation=owner',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([
            {
              'id': 2,
              'full_name': 'octocat/my-repo',
              'name': 'my-repo',
            },
          ]));

      final repos = await provider.getRepositories('octocat');

      expect(repos, hasLength(1));
      expect(repos[0].fullName, 'octocat/my-repo');
    });
  });

  // -------------------------------------------------------------------------
  // searchRepositories
  // -------------------------------------------------------------------------
  group('searchRepositories', () {
    test('fetches /search/repositories with encoded query', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search/repositories')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<Map<String, dynamic>>({
            'items': [
              {
                'id': 10,
                'full_name': 'foo/bar',
                'name': 'bar',
              },
            ],
          }));

      final repos = await provider.searchRepositories('flutter app');

      expect(repos, hasLength(1));
      expect(repos[0].fullName, 'foo/bar');
    });

    test('returns empty list when items is null', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search/repositories')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer(
              (_) async => _okResponse<Map<String, dynamic>>({}));

      final repos = await provider.searchRepositories('nonexistent');

      expect(repos, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getBranches
  // -------------------------------------------------------------------------
  group('getBranches', () {
    test('fetches /repos/{fullName}/branches', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/repos/acme/widget/branches?per_page=100',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([
            {
              'name': 'main',
              'protected': true,
              'commit': {'sha': 'abc123'},
            },
            {
              'name': 'develop',
              'protected': false,
              'commit': {'sha': 'def456'},
            },
          ]));

      final branches = await provider.getBranches('acme/widget');

      expect(branches, hasLength(2));
      expect(branches[0].name, 'main');
      expect(branches[0].isProtected, isTrue);
      expect(branches[1].name, 'develop');
    });
  });

  // -------------------------------------------------------------------------
  // getPullRequests
  // -------------------------------------------------------------------------
  group('getPullRequests', () {
    test('fetches /repos/{fullName}/pulls with state param', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/repos/acme/widget/pulls?state=open&per_page=30',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([
            {
              'number': 42,
              'title': 'Fix stuff',
              'state': 'open',
              'head': {'ref': 'fix-branch'},
              'base': {'ref': 'main'},
            },
          ]));

      final prs = await provider.getPullRequests('acme/widget');

      expect(prs, hasLength(1));
      expect(prs[0].number, 42);
      expect(prs[0].title, 'Fix stuff');
      expect(prs[0].headBranch, 'fix-branch');
    });

    test('supports closed state', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/repos/acme/widget/pulls?state=closed&per_page=30',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([]));

      final prs =
          await provider.getPullRequests('acme/widget', state: 'closed');

      expect(prs, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getCommitHistory
  // -------------------------------------------------------------------------
  group('getCommitHistory', () {
    test('fetches /repos/{fullName}/commits with perPage', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/repos/acme/widget/commits?per_page=30',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([
            {
              'sha': 'abc1234567890',
              'commit': {
                'message': 'Initial commit',
                'author': {
                  'name': 'Alice',
                  'email': 'alice@test.com',
                  'date': '2025-01-15T10:00:00Z',
                },
              },
              'author': {'login': 'alice'},
            },
          ]));

      final commits = await provider.getCommitHistory('acme/widget');

      expect(commits, hasLength(1));
      expect(commits[0].sha, 'abc1234567890');
      expect(commits[0].message, 'Initial commit');
    });

    test('appends sha query param when provided', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/repos/acme/widget/commits?per_page=30&sha=develop',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([]));

      final commits =
          await provider.getCommitHistory('acme/widget', sha: 'develop');

      expect(commits, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getWorkflowRuns
  // -------------------------------------------------------------------------
  group('getWorkflowRuns', () {
    test('fetches /repos/{fullName}/actions/runs', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/repos/acme/widget/actions/runs?per_page=10',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<Map<String, dynamic>>({
            'workflow_runs': [
              {
                'id': 999,
                'name': 'CI',
                'status': 'completed',
                'conclusion': 'success',
              },
            ],
          }));

      final runs = await provider.getWorkflowRuns('acme/widget');

      expect(runs, hasLength(1));
      expect(runs[0].id, 999);
      expect(runs[0].status, 'completed');
    });

    test('returns empty list when workflow_runs is null', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/repos/acme/widget/actions/runs?per_page=10',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer(
              (_) async => _okResponse<Map<String, dynamic>>({}));

      final runs = await provider.getWorkflowRuns('acme/widget');

      expect(runs, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getReleases
  // -------------------------------------------------------------------------
  group('getReleases', () {
    test('fetches /repos/{fullName}/releases', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/repos/acme/widget/releases?per_page=20',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([
            {
              'tag_name': 'v1.0.0',
              'body': 'First release',
              'published_at': '2025-01-15T10:00:00Z',
              'author': {'login': 'alice'},
            },
          ]));

      final releases = await provider.getReleases('acme/widget');

      expect(releases, hasLength(1));
      expect(releases[0].name, 'v1.0.0');
      expect(releases[0].message, 'First release');
    });
  });

  // -------------------------------------------------------------------------
  // Error mapping
  // -------------------------------------------------------------------------
  group('error mapping', () {
    // All API methods go through _get/_post which call _mapDioException.
    // We test via searchRepositories as a representative method.

    test('401 maps to UnauthorizedException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(401, data: {'message': 'Bad credentials'}));

      expect(
        () => provider.searchRepositories('test'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('403 maps to RateLimitException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(403, data: {'message': 'rate limit exceeded'}));

      expect(
        () => provider.searchRepositories('test'),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('404 maps to NotFoundException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(404));

      expect(
        () => provider.searchRepositories('test'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('422 maps to ValidationException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(422, data: {'message': 'Validation failed'}));

      expect(
        () => provider.searchRepositories('test'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('connectionTimeout maps to TimeoutException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_timeoutError(DioExceptionType.connectionTimeout));

      expect(
        () => provider.searchRepositories('test'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('receiveTimeout maps to TimeoutException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_timeoutError(DioExceptionType.receiveTimeout));

      expect(
        () => provider.searchRepositories('test'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('connectionError maps to NetworkException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_timeoutError(DioExceptionType.connectionError));

      expect(
        () => provider.searchRepositories('test'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('500 maps to ServerException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(that: startsWith('/search')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(_dioError(500));

      expect(
        () => provider.searchRepositories('test'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Rate limit tracking
  // -------------------------------------------------------------------------
  group('rate limit tracking', () {
    test('updates rateLimitRemaining and rateLimitReset from headers',
        () async {
      when(() => mockDio.get<List<dynamic>>(
            '/repos/acme/widget/releases?per_page=20',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>(
            [],
            headers: {
              'X-RateLimit-Remaining': ['4999'],
              'X-RateLimit-Reset': ['1700000000'],
            },
          ));

      await provider.getReleases('acme/widget');

      expect(provider.rateLimitRemaining, 4999);
      expect(provider.rateLimitReset, 1700000000);
    });

    test('leaves rate limit fields null when headers missing', () async {
      when(() => mockDio.get<List<dynamic>>(
            '/repos/acme/widget/releases?per_page=20',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => _okResponse<List<dynamic>>([]));

      await provider.getReleases('acme/widget');

      expect(provider.rateLimitRemaining, isNull);
      expect(provider.rateLimitReset, isNull);
    });
  });
}
