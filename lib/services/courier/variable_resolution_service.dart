/// Variable resolution service for Courier requests.
///
/// Resolves `{{variableName}}` tokens in URLs, headers, and bodies using a
/// priority chain: local → environment → collection → globals.
library;

// ─────────────────────────────────────────────────────────────────────────────
// VariableToken
// ─────────────────────────────────────────────────────────────────────────────

/// A single `{{varName}}` token found in a template string, with resolution
/// status and position information.
class VariableToken {
  /// The variable name (text inside the `{{ }}`).
  final String name;

  /// Start index of the opening `{{` in the source string.
  final int start;

  /// End index (exclusive) of the closing `}}` in the source string.
  final int end;

  /// Whether this variable resolved to a concrete value.
  final bool isResolved;

  /// Resolved value, or null if the variable name was not found in any scope.
  final String? resolvedValue;

  /// Creates a [VariableToken].
  const VariableToken({
    required this.name,
    required this.start,
    required this.end,
    required this.isResolved,
    this.resolvedValue,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// VariableResolutionService
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves `{{variableName}}` tokens in strings using a four-level priority
/// chain.
///
/// Priority order (highest first):
/// 1. **local** — request-level overrides
/// 2. **environment** — active environment variables
/// 3. **collection** — collection-level variables
/// 4. **globals** — team-wide global variables
///
/// Unresolved tokens are left unchanged in the output.
class VariableResolutionService {
  static final RegExp _tokenPattern = RegExp(r'\{\{([^}]+)\}\}');

  /// Resolves all `{{varName}}` tokens in [input].
  ///
  /// Each token is looked up in priority order: local → environment →
  /// collection → globals. Unresolved tokens remain as `{{varName}}` in the
  /// returned string.
  String resolve(
    String input, {
    Map<String, String> globals = const {},
    Map<String, String> collection = const {},
    Map<String, String> environment = const {},
    Map<String, String> local = const {},
  }) {
    return input.replaceAllMapped(_tokenPattern, (match) {
      final name = match.group(1)!.trim();
      return local[name] ??
          environment[name] ??
          collection[name] ??
          globals[name] ??
          match.group(0)!;
    });
  }

  /// Extracts all `{{varName}}` tokens from [input] with their positions and
  /// resolution status.
  ///
  /// Tokens are returned in order of appearance. Pass variable maps to populate
  /// [VariableToken.isResolved] and [VariableToken.resolvedValue].
  List<VariableToken> extractTokens(
    String input, {
    Map<String, String> globals = const {},
    Map<String, String> collection = const {},
    Map<String, String> environment = const {},
    Map<String, String> local = const {},
  }) {
    final tokens = <VariableToken>[];
    for (final match in _tokenPattern.allMatches(input)) {
      final name = match.group(1)!.trim();
      final resolved = local[name] ??
          environment[name] ??
          collection[name] ??
          globals[name];
      tokens.add(VariableToken(
        name: name,
        start: match.start,
        end: match.end,
        isResolved: resolved != null,
        resolvedValue: resolved,
      ));
    }
    return tokens;
  }

  /// Returns `true` if [input] contains at least one `{{varName}}` token.
  bool hasVariables(String input) => _tokenPattern.hasMatch(input);
}
