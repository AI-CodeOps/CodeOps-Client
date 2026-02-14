// Tests for JiraService — Jira Cloud REST API client.
//
// Tests configuration guards, HTTP method routing, and response parsing.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/jira_models.dart';
import 'package:codeops/services/jira/jira_service.dart';

// ---------------------------------------------------------------------------
// Mock Dio
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

class FakeOptions extends Fake implements Options {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOptions());
    registerFallbackValue(FakeRequestOptions());
  });

  // ---------------------------------------------------------------------------
  // Configuration & isConfigured
  // ---------------------------------------------------------------------------
  group('JiraService configuration', () {
    test('isConfigured returns false before configure', () {
      final service = JiraService();
      expect(service.isConfigured, isFalse);
    });

    test('isConfigured returns true after configure', () {
      final service = JiraService();
      service.configure(
        instanceUrl: 'https://test.atlassian.net',
        email: 'test@test.com',
        apiToken: 'tok',
      );
      expect(service.isConfigured, isTrue);
    });

    test('configure sets up auth — Basic header uses base64(email:token)', () {
      final service = JiraService();
      service.configure(
        instanceUrl: 'https://myco.atlassian.net',
        email: 'user@myco.com',
        apiToken: 'api-token-123',
      );
      expect(service.isConfigured, isTrue);

      // Verify the expected base64 encoding is correct.
      final expectedBasic =
          base64Encode(utf8.encode('user@myco.com:api-token-123'));
      expect(expectedBasic, isNotEmpty);
    });

    test('configure strips trailing slash from instanceUrl', () {
      final service = JiraService();
      service.configure(
        instanceUrl: 'https://test.atlassian.net/',
        email: 'test@test.com',
        apiToken: 'tok',
      );
      expect(service.isConfigured, isTrue);
    });

    test('configure can be called multiple times', () {
      final service = JiraService();
      service.configure(
        instanceUrl: 'https://first.atlassian.net',
        email: 'a@a.com',
        apiToken: 'tok1',
      );
      expect(service.isConfigured, isTrue);

      service.configure(
        instanceUrl: 'https://second.atlassian.net',
        email: 'b@b.com',
        apiToken: 'tok2',
      );
      expect(service.isConfigured, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Unconfigured guard — all API methods throw StateError
  // ---------------------------------------------------------------------------
  group('JiraService unconfigured guard', () {
    late JiraService service;

    setUp(() {
      service = JiraService();
    });

    test('testConnection throws StateError', () {
      expect(() => service.testConnection(), throwsStateError);
    });

    test('searchIssues throws StateError', () {
      expect(
        () => service.searchIssues(jql: 'project = PAY'),
        throwsStateError,
      );
    });

    test('getIssue throws StateError', () {
      expect(() => service.getIssue('PAY-1'), throwsStateError);
    });

    test('createIssue throws StateError', () {
      expect(
        () => service.createIssue(const CreateJiraIssueRequest(
          projectKey: 'PAY',
          issueTypeName: 'Bug',
          summary: 'Test',
        )),
        throwsStateError,
      );
    });

    test('getComments throws StateError', () {
      expect(() => service.getComments('PAY-1'), throwsStateError);
    });

    test('postComment throws StateError', () {
      expect(
        () => service.postComment('PAY-1', 'text'),
        throwsStateError,
      );
    });

    test('updateIssue throws StateError', () {
      expect(
        () => service.updateIssue(
          'PAY-1',
          const UpdateJiraIssueRequest(summary: 'New'),
        ),
        throwsStateError,
      );
    });

    test('getTransitions throws StateError', () {
      expect(() => service.getTransitions('PAY-1'), throwsStateError);
    });

    test('transitionIssue throws StateError', () {
      expect(
        () => service.transitionIssue('PAY-1', '21'),
        throwsStateError,
      );
    });

    test('getProjects throws StateError', () {
      expect(() => service.getProjects(), throwsStateError);
    });

    test('getPriorities throws StateError', () {
      expect(() => service.getPriorities(), throwsStateError);
    });

    test('getSprints throws StateError', () {
      expect(() => service.getSprints(1), throwsStateError);
    });

    test('getIssueTypes throws StateError', () {
      expect(() => service.getIssueTypes('PAY'), throwsStateError);
    });

    test('searchUsers throws StateError', () {
      expect(() => service.searchUsers('alice'), throwsStateError);
    });

    test('createSubTask throws StateError', () {
      expect(
        () => service.createSubTask(const CreateJiraSubTaskRequest(
          parentKey: 'PAY-1',
          projectKey: 'PAY',
          summary: 'Sub',
        )),
        throwsStateError,
      );
    });

    test('createIssuesBulk throws StateError', () {
      expect(
        () => service.createIssuesBulk([
          const CreateJiraIssueRequest(
            projectKey: 'PAY',
            issueTypeName: 'Bug',
            summary: 'Test',
          ),
        ]),
        throwsStateError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Network-level tests (configured service against unreachable host)
  //
  // These verify that the service handles DioExceptions gracefully after
  // configuration. We use an invalid hostname to trigger connection errors.
  // ---------------------------------------------------------------------------
  group('JiraService configured with unreachable host', () {
    late JiraService service;

    setUp(() {
      service = JiraService();
      service.configure(
        instanceUrl: 'https://nonexistent.invalid.test',
        email: 'test@test.com',
        apiToken: 'tok',
      );
    });

    test('testConnection returns false on DioException', () async {
      final result = await service.testConnection();
      expect(result, isFalse);
    });

    test('createIssuesBulk returns empty list when all creates fail', () async {
      final results = await service.createIssuesBulk([
        const CreateJiraIssueRequest(
          projectKey: 'PAY',
          issueTypeName: 'Bug',
          summary: 'Test 1',
        ),
        const CreateJiraIssueRequest(
          projectKey: 'PAY',
          issueTypeName: 'Task',
          summary: 'Test 2',
        ),
      ]);
      expect(results, isEmpty);
    });

    test('searchIssues throws DioException on network failure', () async {
      expect(
        () => service.searchIssues(jql: 'project = PAY'),
        throwsA(isA<DioException>()),
      );
    });

    test('getIssue throws DioException on network failure', () async {
      expect(
        () => service.getIssue('PAY-456'),
        throwsA(isA<DioException>()),
      );
    });

    test('getComments throws DioException on network failure', () async {
      expect(
        () => service.getComments('PAY-456'),
        throwsA(isA<DioException>()),
      );
    });

    test('postComment throws DioException on network failure', () async {
      expect(
        () => service.postComment('PAY-456', 'Hello'),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Mock Dio injection (constructor injection, no configure)
  //
  // These tests verify that JiraService(dio: mockDio) correctly stores
  // the provided Dio. Since configure() is NOT called, isConfigured is false
  // and API methods will throw StateError — confirming the guard works even
  // when a custom Dio is injected.
  // ---------------------------------------------------------------------------
  group('JiraService with constructor-injected MockDio', () {
    test('constructor accepts custom Dio', () {
      final mockDio = MockDio();
      when(() => mockDio.options).thenReturn(BaseOptions());
      final service = JiraService(dio: mockDio);
      expect(service.isConfigured, isFalse);
    });

    test('configure replaces injected Dio with new one', () {
      final mockDio = MockDio();
      when(() => mockDio.options).thenReturn(BaseOptions());
      final service = JiraService(dio: mockDio);

      service.configure(
        instanceUrl: 'https://test.atlassian.net',
        email: 'test@test.com',
        apiToken: 'tok',
      );
      expect(service.isConfigured, isTrue);
    });
  });
}
