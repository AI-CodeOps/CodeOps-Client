/// Data model for Anthropic model metadata fetched from the API.
///
/// Plain Dart class (no codegen) following the [VcsModels] pattern.
/// Parses Anthropic `/v1/models` API responses and converts to Drift
/// companions for database caching.
library;

import 'package:drift/drift.dart';

import '../database/database.dart';

/// Metadata for a single Anthropic model.
///
/// Created from API responses via [fromApiJson] and cached locally
/// via [toDbCompanion].
class AnthropicModelInfo {
  /// Model identifier (e.g. "claude-sonnet-4-20250514").
  final String id;

  /// Human-readable display name.
  final String displayName;

  /// Model family grouping (e.g. "claude-4").
  final String? modelFamily;

  /// Maximum input context window in tokens.
  final int? contextWindow;

  /// Maximum output tokens the model can generate.
  final int? maxOutputTokens;

  /// Timestamp when this model was fetched.
  final DateTime createdAt;

  /// Creates an [AnthropicModelInfo].
  const AnthropicModelInfo({
    required this.id,
    required this.displayName,
    this.modelFamily,
    this.contextWindow,
    this.maxOutputTokens,
    required this.createdAt,
  });

  /// Parses an Anthropic API `/v1/models` list item.
  ///
  /// Expected JSON shape:
  /// ```json
  /// {
  ///   "id": "claude-sonnet-4-20250514",
  ///   "display_name": "Claude Sonnet 4",
  ///   "type": "model",
  ///   "created_at": "2025-05-14T00:00:00Z"
  /// }
  /// ```
  factory AnthropicModelInfo.fromApiJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

    // Derive display name: prefer API-provided, fall back to id.
    final displayName =
        (json['display_name'] as String?) ?? _formatModelId(id);

    // Derive model family from the id pattern (e.g. "claude-sonnet-4" → "claude-4").
    String? modelFamily;
    final match = RegExp(r'^(claude)-\w+-(\d+)').firstMatch(id);
    if (match != null) {
      modelFamily = '${match.group(1)}-${match.group(2)}';
    }

    return AnthropicModelInfo(
      id: id,
      displayName: displayName,
      modelFamily: modelFamily,
      contextWindow: json['context_window'] as int?,
      maxOutputTokens: json['max_output_tokens'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Creates an [AnthropicModelInfo] from a Drift database row.
  factory AnthropicModelInfo.fromDb(AnthropicModel row) {
    return AnthropicModelInfo(
      id: row.id,
      displayName: row.displayName,
      modelFamily: row.modelFamily,
      contextWindow: row.contextWindow,
      maxOutputTokens: row.maxOutputTokens,
      createdAt: row.fetchedAt,
    );
  }

  /// Returns a Drift companion for upserting into the cache.
  AnthropicModelsCompanion toDbCompanion() {
    return AnthropicModelsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      modelFamily: Value(modelFamily),
      contextWindow: Value(contextWindow),
      maxOutputTokens: Value(maxOutputTokens),
      fetchedAt: Value(createdAt),
    );
  }

  /// Formats a model ID into a human-readable name.
  ///
  /// "claude-sonnet-4-20250514" → "Claude Sonnet 4 20250514".
  static String _formatModelId(String id) {
    return id
        .split('-')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  @override
  String toString() => 'AnthropicModelInfo(id=$id, displayName=$displayName)';
}
