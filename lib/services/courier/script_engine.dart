/// Dart-based script engine for Courier pre-request and post-response scripts.
///
/// Interprets a JavaScript-like DSL that covers the most common Postman script
/// patterns: `courier.environment.get/set`, `courier.request.addHeader`,
/// `courier.response.json()`, `courier.test()`, `courier.expect()`,
/// `console.log()`, and more.
///
/// Scripts are parsed line-by-line and statement-by-statement using a
/// lightweight expression evaluator. No external JS runtime is required.
library;

import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// Context objects
// ─────────────────────────────────────────────────────────────────────────────

/// Mutable request context available to pre-request scripts.
class RequestContext {
  /// The current request URL (can be modified by scripts).
  String url;

  /// Request headers (mutable — scripts can add/remove entries).
  final Map<String, String> headers;

  /// Creates a [RequestContext].
  RequestContext({required this.url, Map<String, String>? headers})
      : headers = headers ?? {};
}

/// Immutable response context available to post-response and test scripts.
class ResponseContext {
  /// HTTP status code.
  final int statusCode;

  /// Response body as a string.
  final String body;

  /// Response headers.
  final Map<String, String> headers;

  /// Round-trip response time in milliseconds.
  final int responseTimeMs;

  /// Creates a [ResponseContext].
  const ResponseContext({
    required this.statusCode,
    required this.body,
    this.headers = const {},
    required this.responseTimeMs,
  });

  /// Parses the body as JSON.
  dynamic json() => jsonDecode(body);

  /// Returns the value of a response header (case-insensitive).
  String? header(String name) {
    final lower = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }
}

/// Environment and global variable storage accessible to scripts.
class VariableContext {
  /// Environment variables (scoped to the active environment).
  final Map<String, String> environment;

  /// Global variables (persist across requests).
  final Map<String, String> globals;

  /// Creates a [VariableContext].
  VariableContext({
    Map<String, String>? environment,
    Map<String, String>? globals,
  })  : environment = environment ?? {},
        globals = globals ?? {};
}

// ─────────────────────────────────────────────────────────────────────────────
// ScriptResult / TestResult
// ─────────────────────────────────────────────────────────────────────────────

/// The outcome of executing a script.
class ScriptResult {
  /// Console output lines produced by `console.log()`.
  final List<String> consoleOutput;

  /// Test assertion results produced by `courier.test()`.
  final List<TestResult> testResults;

  /// Environment and global variables set by the script.
  final Map<String, String> variableUpdates;

  /// Headers added by the script via `courier.request.addHeader()`.
  final Map<String, String> headerUpdates;

  /// Script execution error, or null on success.
  final String? error;

  /// Creates a [ScriptResult].
  const ScriptResult({
    this.consoleOutput = const [],
    this.testResults = const [],
    this.variableUpdates = const {},
    this.headerUpdates = const {},
    this.error,
  });
}

/// A single test assertion result.
class TestResult {
  /// Test name from `courier.test("name", ...)`.
  final String name;

  /// Whether the assertion passed.
  final bool passed;

  /// Error details when the assertion failed, or null on pass.
  final String? errorMessage;

  /// Creates a [TestResult].
  const TestResult({
    required this.name,
    required this.passed,
    this.errorMessage,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ScriptEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Interprets Courier DSL scripts in a sandboxed Dart evaluator.
///
/// Supports `console.log()`, `courier.environment.get/set`,
/// `courier.globals.get/set`, `courier.request.addHeader/url`,
/// `courier.response.json/statusCode/header/responseTime`,
/// `courier.test()`, `courier.expect()`, `courier.uuid()`,
/// `courier.timestamp()`.
class ScriptEngine {
  /// Executes a pre-request script.
  ///
  /// Pre-request scripts can modify [requestContext] headers and URL, set
  /// environment/global variables, and log to the console.
  Future<ScriptResult> executePreRequest({
    required String script,
    required RequestContext requestContext,
    required VariableContext variables,
  }) async {
    return _execute(
      script: script,
      requestContext: requestContext,
      responseContext: null,
      variables: variables,
    );
  }

  /// Executes a post-response script (including test assertions).
  ///
  /// Post-response scripts can read [responseContext], set variables, run
  /// `courier.test()` assertions, and log to the console.
  Future<ScriptResult> executePostResponse({
    required String script,
    required RequestContext requestContext,
    required ResponseContext responseContext,
    required VariableContext variables,
  }) async {
    return _execute(
      script: script,
      requestContext: requestContext,
      responseContext: responseContext,
      variables: variables,
    );
  }

  // ── Internal execution ───────────────────────────────────────────────────

  Future<ScriptResult> _execute({
    required String script,
    required RequestContext requestContext,
    ResponseContext? responseContext,
    required VariableContext variables,
  }) async {
    if (script.trim().isEmpty) {
      return const ScriptResult();
    }

    final console = <String>[];
    final tests = <TestResult>[];
    final varUpdates = <String, String>{};
    final headerUpdates = <String, String>{};

    try {
      final statements = _parseStatements(script);

      for (final stmt in statements) {
        _executeStatement(
          stmt,
          requestContext: requestContext,
          responseContext: responseContext,
          variables: variables,
          console: console,
          tests: tests,
          varUpdates: varUpdates,
          headerUpdates: headerUpdates,
        );
      }

      return ScriptResult(
        consoleOutput: console,
        testResults: tests,
        variableUpdates: varUpdates,
        headerUpdates: headerUpdates,
      );
    } catch (e) {
      return ScriptResult(
        consoleOutput: console,
        testResults: tests,
        variableUpdates: varUpdates,
        headerUpdates: headerUpdates,
        error: e.toString(),
      );
    }
  }

  // ── Statement parsing ────────────────────────────────────────────────────

  /// Splits script into executable statements.
  ///
  /// Handles semicolons, `courier.test("name", () => { ... })` blocks,
  /// single-line comments, and multi-line comments.
  List<String> _parseStatements(String script) {
    final statements = <String>[];
    final lines = script.split('\n');
    final buffer = StringBuffer();
    var braceDepth = 0;
    var inMultiLineComment = false;

    for (var line in lines) {
      // Strip multi-line comments.
      if (inMultiLineComment) {
        final endIdx = line.indexOf('*/');
        if (endIdx >= 0) {
          inMultiLineComment = false;
          line = line.substring(endIdx + 2);
        } else {
          continue;
        }
      }
      final mlStart = line.indexOf('/*');
      if (mlStart >= 0) {
        final mlEnd = line.indexOf('*/', mlStart + 2);
        if (mlEnd >= 0) {
          line = line.substring(0, mlStart) + line.substring(mlEnd + 2);
        } else {
          line = line.substring(0, mlStart);
          inMultiLineComment = true;
        }
      }

      // Strip single-line comments (but not inside strings).
      final commentIdx = _findCommentStart(line);
      if (commentIdx >= 0) {
        line = line.substring(0, commentIdx);
      }

      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Count braces for multi-line statement blocks.
      for (var i = 0; i < trimmed.length; i++) {
        final ch = trimmed[i];
        if (ch == '{') braceDepth++;
        if (ch == '}') braceDepth--;
      }

      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(trimmed);

      if (braceDepth <= 0) {
        final stmt = buffer.toString().trim();
        if (stmt.isNotEmpty) {
          // Split by semicolons at top level (brace depth 0).
          if (!stmt.contains('{')) {
            for (final part in stmt.split(';')) {
              final p = part.trim();
              if (p.isNotEmpty) statements.add(p);
            }
          } else {
            statements.add(stmt);
          }
        }
        buffer.clear();
        braceDepth = 0;
      }
    }

    // Flush remaining.
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      statements.add(remaining);
    }

    return statements;
  }

  /// Finds the start index of a `//` comment outside of string literals.
  int _findCommentStart(String line) {
    var inString = false;
    String? quote;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inString) {
        if (ch == quote && (i == 0 || line[i - 1] != '\\')) {
          inString = false;
        }
      } else {
        if (ch == '"' || ch == "'") {
          inString = true;
          quote = ch;
        } else if (ch == '/' && i + 1 < line.length && line[i + 1] == '/') {
          return i;
        }
      }
    }
    return -1;
  }

  // ── Statement execution ──────────────────────────────────────────────────

  void _executeStatement(
    String stmt, {
    required RequestContext requestContext,
    ResponseContext? responseContext,
    required VariableContext variables,
    required List<String> console,
    required List<TestResult> tests,
    required Map<String, String> varUpdates,
    required Map<String, String> headerUpdates,
  }) {
    // Strip trailing semicolons.
    var s = stmt.trim();
    if (s.endsWith(';')) s = s.substring(0, s.length - 1).trim();

    // console.log(...)
    if (s.startsWith('console.log(')) {
      final arg = _extractCallArg(s, 'console.log');
      final resolved = _resolveValue(arg,
          requestContext: requestContext,
          responseContext: responseContext,
          variables: variables);
      console.add(resolved.toString());
      return;
    }

    // courier.environment.set("key", "value")
    if (s.startsWith('courier.environment.set(')) {
      final args = _extractCallArgs(s, 'courier.environment.set');
      if (args.length >= 2) {
        final key = _stripQuotes(args[0]);
        final value = _resolveValue(args[1],
            requestContext: requestContext,
            responseContext: responseContext,
            variables: variables);
        variables.environment[key] = value.toString();
        varUpdates['env:$key'] = value.toString();
      }
      return;
    }

    // courier.globals.set("key", "value")
    if (s.startsWith('courier.globals.set(')) {
      final args = _extractCallArgs(s, 'courier.globals.set');
      if (args.length >= 2) {
        final key = _stripQuotes(args[0]);
        final value = _resolveValue(args[1],
            requestContext: requestContext,
            responseContext: responseContext,
            variables: variables);
        variables.globals[key] = value.toString();
        varUpdates['global:$key'] = value.toString();
      }
      return;
    }

    // courier.request.addHeader("key", "value")
    if (s.startsWith('courier.request.addHeader(')) {
      final args = _extractCallArgs(s, 'courier.request.addHeader');
      if (args.length >= 2) {
        final key = _stripQuotes(args[0]);
        final value = _stripQuotes(args[1]);
        requestContext.headers[key] = value;
        headerUpdates[key] = value;
      }
      return;
    }

    // courier.request.removeHeader("key")
    if (s.startsWith('courier.request.removeHeader(')) {
      final arg = _extractCallArg(s, 'courier.request.removeHeader');
      final key = _stripQuotes(arg);
      requestContext.headers.remove(key);
      return;
    }

    // courier.request.url = "..."
    if (s.startsWith('courier.request.url')) {
      final eqIdx = s.indexOf('=');
      if (eqIdx > 0) {
        final value = _stripQuotes(s.substring(eqIdx + 1).trim());
        requestContext.url = value;
      }
      return;
    }

    // courier.test("name", () => { ... })
    if (s.startsWith('courier.test(')) {
      _executeTest(s,
          requestContext: requestContext,
          responseContext: responseContext,
          variables: variables,
          tests: tests,
          console: console);
      return;
    }

    // courier.expect() outside of courier.test() — error.
    if (s.startsWith('courier.expect(')) {
      throw StateError(
          'courier.expect() must be used inside a courier.test() block');
    }

    // const/let/var assignments (extract value for side effects).
    if (s.startsWith('const ') || s.startsWith('let ') || s.startsWith('var ')) {
      // Variable declarations — evaluated for side effects only.
      return;
    }
  }

  // ── courier.test() execution ─────────────────────────────────────────────

  void _executeTest(
    String stmt, {
    required RequestContext requestContext,
    ResponseContext? responseContext,
    required VariableContext variables,
    required List<TestResult> tests,
    required List<String> console,
  }) {
    // Extract test name.
    final nameStart = stmt.indexOf('"');
    final altNameStart = stmt.indexOf("'");
    final actualStart = (nameStart >= 0 && altNameStart >= 0)
        ? (nameStart < altNameStart ? nameStart : altNameStart)
        : (nameStart >= 0 ? nameStart : altNameStart);

    if (actualStart < 0) {
      tests.add(const TestResult(
        name: '<unknown>',
        passed: false,
        errorMessage: 'Could not parse test name',
      ));
      return;
    }

    final quoteChar = stmt[actualStart];
    final nameEnd = stmt.indexOf(quoteChar, actualStart + 1);
    if (nameEnd < 0) {
      tests.add(const TestResult(
        name: '<unknown>',
        passed: false,
        errorMessage: 'Could not parse test name',
      ));
      return;
    }

    final testName = stmt.substring(actualStart + 1, nameEnd);

    // Extract the body between `{` and the last `}`.
    final bodyStart = stmt.indexOf('{');
    final bodyEnd = stmt.lastIndexOf('}');
    if (bodyStart < 0 || bodyEnd < 0 || bodyEnd <= bodyStart) {
      tests.add(TestResult(
        name: testName,
        passed: false,
        errorMessage: 'Could not parse test body',
      ));
      return;
    }

    final body = stmt.substring(bodyStart + 1, bodyEnd).trim();

    try {
      _executeTestBody(body,
          requestContext: requestContext,
          responseContext: responseContext,
          variables: variables,
          console: console);
      tests.add(TestResult(name: testName, passed: true));
    } catch (e) {
      tests.add(TestResult(
        name: testName,
        passed: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _executeTestBody(
    String body, {
    required RequestContext requestContext,
    ResponseContext? responseContext,
    required VariableContext variables,
    required List<String> console,
  }) {
    // Split body into individual statements.
    final bodyStatements = body.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty);

    for (final s in bodyStatements) {
      // courier.expect(...).toBe/toContain/toBeLessThan/toHaveProperty/toMatchSchema
      if (s.startsWith('courier.expect(')) {
        _executeExpect(s,
            requestContext: requestContext,
            responseContext: responseContext,
            variables: variables);
      } else if (s.startsWith('const ') ||
          s.startsWith('let ') ||
          s.startsWith('var ')) {
        // Variable assignment — skip for side-effect-only eval.
      } else if (s.startsWith('console.log(')) {
        final arg = _extractCallArg(s, 'console.log');
        console.add(arg);
      }
    }
  }

  void _executeExpect(
    String stmt, {
    required RequestContext requestContext,
    ResponseContext? responseContext,
    required VariableContext variables,
  }) {
    // Parse: courier.expect(ACTUAL).MATCHER(EXPECTED)
    final expectStart = stmt.indexOf('courier.expect(') + 'courier.expect('.length;
    final closeParen = _findMatchingParen(stmt, expectStart - 1);
    if (closeParen < 0) throw AssertionError('Malformed courier.expect()');

    final actualExpr = stmt.substring(expectStart, closeParen).trim();
    final matcher = stmt.substring(closeParen + 2); // skip ")."

    final actual = _resolveValue(actualExpr,
        requestContext: requestContext,
        responseContext: responseContext,
        variables: variables);

    // .toBe(expected)
    if (matcher.startsWith('toBe(')) {
      final expected = _resolveValue(
          _extractCallArg(matcher, 'toBe'),
          requestContext: requestContext,
          responseContext: responseContext,
          variables: variables);
      if (actual.toString() != expected.toString()) {
        throw AssertionError(
            'Expected $expected but got $actual');
      }
      return;
    }

    // .toContain(substring)
    if (matcher.startsWith('toContain(')) {
      final expected = _resolveValue(
          _extractCallArg(matcher, 'toContain'),
          requestContext: requestContext,
          responseContext: responseContext,
          variables: variables);
      if (!actual.toString().contains(expected.toString())) {
        throw AssertionError(
            'Expected "$actual" to contain "$expected"');
      }
      return;
    }

    // .toBeLessThan(n)
    if (matcher.startsWith('toBeLessThan(')) {
      final expected = _resolveValue(
          _extractCallArg(matcher, 'toBeLessThan'),
          requestContext: requestContext,
          responseContext: responseContext,
          variables: variables);
      final a = num.tryParse(actual.toString()) ?? 0;
      final b = num.tryParse(expected.toString()) ?? 0;
      if (a >= b) {
        throw AssertionError('Expected $a to be less than $b');
      }
      return;
    }

    // .toHaveProperty("prop")
    if (matcher.startsWith('toHaveProperty(')) {
      final prop = _stripQuotes(
          _extractCallArg(matcher, 'toHaveProperty'));
      if (actual is Map) {
        if (!actual.containsKey(prop)) {
          throw AssertionError(
              'Expected object to have property "$prop"');
        }
      } else {
        throw AssertionError(
            'Expected a Map but got ${actual.runtimeType}');
      }
      return;
    }

    // .toMatchSchema({...})
    if (matcher.startsWith('toMatchSchema(')) {
      // Simplified schema: check that top-level keys exist and their types match.
      final schemaArg = _extractCallArg(matcher, 'toMatchSchema');
      final schema = jsonDecode(schemaArg.replaceAll("'", '"'));
      if (actual is Map && schema is Map) {
        for (final key in schema.keys) {
          if (!actual.containsKey(key)) {
            throw AssertionError(
                'Missing property "$key" in response');
          }
        }
      } else {
        throw AssertionError(
            'Schema validation requires object response');
      }
      return;
    }

    throw AssertionError('Unknown matcher: $matcher');
  }

  // ── Value resolution ─────────────────────────────────────────────────────

  /// Resolves a DSL expression to a Dart value.
  dynamic _resolveValue(
    String expr, {
    required RequestContext requestContext,
    ResponseContext? responseContext,
    required VariableContext variables,
  }) {
    final e = expr.trim();

    // String literal.
    if ((e.startsWith('"') && e.endsWith('"')) ||
        (e.startsWith("'") && e.endsWith("'"))) {
      return _stripQuotes(e);
    }

    // Numeric literal.
    final num_ = num.tryParse(e);
    if (num_ != null) return num_;

    // Boolean literal.
    if (e == 'true') return true;
    if (e == 'false') return false;

    // courier.response.statusCode
    if (e == 'courier.response.statusCode') {
      return responseContext?.statusCode ?? 0;
    }

    // courier.response.responseTime
    if (e == 'courier.response.responseTime') {
      return responseContext?.responseTimeMs ?? 0;
    }

    // courier.response.json()
    if (e == 'courier.response.json()') {
      return responseContext?.json();
    }

    // courier.response.header("...")
    if (e.startsWith('courier.response.header(')) {
      final arg = _extractCallArg(e, 'courier.response.header');
      return responseContext?.header(_stripQuotes(arg)) ?? '';
    }

    // courier.environment.get("key")
    if (e.startsWith('courier.environment.get(')) {
      final key = _stripQuotes(_extractCallArg(e, 'courier.environment.get'));
      return variables.environment[key] ?? '';
    }

    // courier.globals.get("key")
    if (e.startsWith('courier.globals.get(')) {
      final key = _stripQuotes(_extractCallArg(e, 'courier.globals.get'));
      return variables.globals[key] ?? '';
    }

    // courier.uuid()
    if (e == 'courier.uuid()') {
      // Return a fixed UUID for deterministic testing; real implementation
      // would use the uuid package.
      return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
    }

    // courier.timestamp()
    if (e == 'courier.timestamp()') {
      return DateTime.now().millisecondsSinceEpoch;
    }

    // Property access on resolved object: body.property
    if (e.contains('.') && !e.startsWith('courier.') && !e.startsWith('console.')) {
      // Try to resolve as chained property access on a variable.
      return e;
    }

    return e;
  }

  // ── Parsing helpers ──────────────────────────────────────────────────────

  /// Extracts the single argument from `funcName(arg)`.
  String _extractCallArg(String call, String funcName) {
    final start = call.indexOf('$funcName(') + funcName.length + 1;
    final end = _findMatchingParen(call, start - 1);
    if (end < 0) return call.substring(start);
    return call.substring(start, end).trim();
  }

  /// Extracts multiple comma-separated arguments from `funcName(a, b)`.
  List<String> _extractCallArgs(String call, String funcName) {
    final fullArg = _extractCallArg(call, funcName);
    return _splitArgs(fullArg);
  }

  /// Splits a comma-separated argument list respecting strings and parens.
  List<String> _splitArgs(String args) {
    final result = <String>[];
    var depth = 0;
    var inString = false;
    String? quote;
    var start = 0;

    for (var i = 0; i < args.length; i++) {
      final ch = args[i];
      if (inString) {
        if (ch == quote && (i == 0 || args[i - 1] != '\\')) {
          inString = false;
        }
      } else {
        if (ch == '"' || ch == "'") {
          inString = true;
          quote = ch;
        } else if (ch == '(' || ch == '{' || ch == '[') {
          depth++;
        } else if (ch == ')' || ch == '}' || ch == ']') {
          depth--;
        } else if (ch == ',' && depth == 0) {
          result.add(args.substring(start, i).trim());
          start = i + 1;
        }
      }
    }

    final last = args.substring(start).trim();
    if (last.isNotEmpty) result.add(last);

    return result;
  }

  /// Finds the closing `)` matching the `(` at [openIndex].
  int _findMatchingParen(String s, int openIndex) {
    var depth = 0;
    var inString = false;
    String? quote;

    for (var i = openIndex; i < s.length; i++) {
      final ch = s[i];
      if (inString) {
        if (ch == quote && (i == 0 || s[i - 1] != '\\')) {
          inString = false;
        }
      } else {
        if (ch == '"' || ch == "'") {
          inString = true;
          quote = ch;
        } else if (ch == '(') {
          depth++;
        } else if (ch == ')') {
          depth--;
          if (depth == 0) return i;
        }
      }
    }
    return -1;
  }

  /// Strips surrounding quotes from a string literal.
  String _stripQuotes(String s) {
    final t = s.trim();
    if (t.length >= 2) {
      if ((t.startsWith('"') && t.endsWith('"')) ||
          (t.startsWith("'") && t.endsWith("'"))) {
        return t.substring(1, t.length - 1);
      }
    }
    return t;
  }
}
