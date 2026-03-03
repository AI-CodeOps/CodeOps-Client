// Unit tests for ScriptEngine.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/services/courier/script_engine.dart';

void main() {
  late ScriptEngine engine;
  late RequestContext requestCtx;
  late VariableContext variableCtx;

  setUp(() {
    engine = ScriptEngine();
    requestCtx = RequestContext(url: 'https://api.example.com/data');
    variableCtx = VariableContext();
  });

  group('ScriptEngine pre-request', () {
    test('empty script returns empty result', () async {
      final result = await engine.executePreRequest(
        script: '',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(result.consoleOutput, isEmpty);
      expect(result.testResults, isEmpty);
      expect(result.error, isNull);
    });

    test('console.log produces output', () async {
      final result = await engine.executePreRequest(
        script: 'console.log("hello world");',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(result.consoleOutput, ['hello world']);
    });

    test('set environment variable', () async {
      final result = await engine.executePreRequest(
        script: 'courier.environment.set("token", "abc123");',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(variableCtx.environment['token'], 'abc123');
      expect(result.variableUpdates['env:token'], 'abc123');
    });

    test('get environment variable', () async {
      variableCtx.environment['baseUrl'] = 'https://api.test.com';
      final result = await engine.executePreRequest(
        script: 'console.log(courier.environment.get("baseUrl"));',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(result.consoleOutput, ['https://api.test.com']);
    });

    test('set global variable', () async {
      await engine.executePreRequest(
        script: 'courier.globals.set("counter", "42");',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(variableCtx.globals['counter'], '42');
    });

    test('addHeader modifies request context', () async {
      final result = await engine.executePreRequest(
        script: 'courier.request.addHeader("X-Custom", "value");',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(requestCtx.headers['X-Custom'], 'value');
      expect(result.headerUpdates['X-Custom'], 'value');
    });

    test('set request URL', () async {
      await engine.executePreRequest(
        script: 'courier.request.url = "https://new-api.test.com/v2";',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(requestCtx.url, 'https://new-api.test.com/v2');
    });

    test('script error is captured', () async {
      // Malformed courier.expect outside of test block triggers parse error.
      final result = await engine.executePreRequest(
        script: 'courier.expect(courier.response.statusCode).toBe(200);',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(result.error, isNotNull);
    });
  });

  group('ScriptEngine post-response', () {
    late ResponseContext responseCtx;

    setUp(() {
      responseCtx = ResponseContext(
        statusCode: 200,
        body: jsonEncode({'user': 'adam', 'id': 1}),
        headers: {'content-type': 'application/json; charset=utf-8'},
        responseTimeMs: 150,
      );
    });

    test('status code check passes', () async {
      final result = await engine.executePostResponse(
        script: 'courier.test("Status is 200", () => {\n'
            '  courier.expect(courier.response.statusCode).toBe(200);\n'
            '});',
        requestContext: requestCtx,
        responseContext: responseCtx,
        variables: variableCtx,
      );
      expect(result.testResults, hasLength(1));
      expect(result.testResults.first.passed, true);
      expect(result.testResults.first.name, 'Status is 200');
    });

    test('status code check fails', () async {
      final result = await engine.executePostResponse(
        script: 'courier.test("Status is 404", () => {\n'
            '  courier.expect(courier.response.statusCode).toBe(404);\n'
            '});',
        requestContext: requestCtx,
        responseContext: responseCtx,
        variables: variableCtx,
      );
      expect(result.testResults, hasLength(1));
      expect(result.testResults.first.passed, false);
      expect(result.testResults.first.errorMessage, contains('Expected 404'));
    });

    test('response time check passes', () async {
      final result = await engine.executePostResponse(
        script: 'courier.test("Fast response", () => {\n'
            '  courier.expect(courier.response.responseTime).toBeLessThan(500);\n'
            '});',
        requestContext: requestCtx,
        responseContext: responseCtx,
        variables: variableCtx,
      );
      expect(result.testResults.first.passed, true);
    });

    test('body property check passes', () async {
      final result = await engine.executePostResponse(
        script: 'courier.test("Has user", () => {\n'
            '  courier.expect(courier.response.json()).toHaveProperty("user");\n'
            '});',
        requestContext: requestCtx,
        responseContext: responseCtx,
        variables: variableCtx,
      );
      expect(result.testResults.first.passed, true);
    });

    test('toContain checks header value', () async {
      final result = await engine.executePostResponse(
        script: 'courier.test("JSON response", () => {\n'
            '  courier.expect(courier.response.header("Content-Type")).toContain("application/json");\n'
            '});',
        requestContext: requestCtx,
        responseContext: responseCtx,
        variables: variableCtx,
      );
      expect(result.testResults.first.passed, true);
    });

    test('console.log in post-response', () async {
      final result = await engine.executePostResponse(
        script: 'console.log("response received");',
        requestContext: requestCtx,
        responseContext: responseCtx,
        variables: variableCtx,
      );
      expect(result.consoleOutput, ['response received']);
    });

    test('JSON parse via response.json()', () async {
      final result = await engine.executePostResponse(
        script: 'courier.test("Parse JSON", () => {\n'
            '  courier.expect(courier.response.json()).toHaveProperty("id");\n'
            '});',
        requestContext: requestCtx,
        responseContext: responseCtx,
        variables: variableCtx,
      );
      expect(result.testResults.first.passed, true);
    });
  });

  group('ScriptEngine comments', () {
    test('single-line comments are stripped', () async {
      final result = await engine.executePreRequest(
        script: '// This is a comment\nconsole.log("works");',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(result.consoleOutput, ['works']);
    });

    test('multi-line comments are stripped', () async {
      final result = await engine.executePreRequest(
        script: '/* comment */\nconsole.log("still works");',
        requestContext: requestCtx,
        variables: variableCtx,
      );
      expect(result.consoleOutput, ['still works']);
    });
  });
}
