// Tests for AnthropicModelInfo model class.
//
// Verifies JSON parsing, display name formatting, and DB companion creation.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/anthropic_model_info.dart';

void main() {
  group('AnthropicModelInfo', () {
    test('fromApiJson parses complete response', () {
      final json = {
        'id': 'claude-sonnet-4-20250514',
        'display_name': 'Claude Sonnet 4',
        'type': 'model',
        'context_window': 200000,
        'max_output_tokens': 16384,
        'created_at': '2025-05-14T00:00:00Z',
      };

      final model = AnthropicModelInfo.fromApiJson(json);

      expect(model.id, 'claude-sonnet-4-20250514');
      expect(model.displayName, 'Claude Sonnet 4');
      expect(model.contextWindow, 200000);
      expect(model.maxOutputTokens, 16384);
      expect(model.modelFamily, 'claude-4');
    });

    test('fromApiJson falls back to formatted id when no display_name', () {
      final json = {
        'id': 'claude-haiku-4-20250514',
        'type': 'model',
      };

      final model = AnthropicModelInfo.fromApiJson(json);

      expect(model.displayName, 'Claude Haiku 4 20250514');
    });

    test('fromApiJson handles null optional fields', () {
      final json = {
        'id': 'custom-model',
        'type': 'model',
      };

      final model = AnthropicModelInfo.fromApiJson(json);

      expect(model.contextWindow, isNull);
      expect(model.maxOutputTokens, isNull);
      expect(model.modelFamily, isNull);
    });

    test('fromApiJson parses model family from id', () {
      final json = {
        'id': 'claude-opus-4-20250514',
        'display_name': 'Claude Opus 4',
        'type': 'model',
      };

      final model = AnthropicModelInfo.fromApiJson(json);

      expect(model.modelFamily, 'claude-4');
    });

    test('toDbCompanion creates valid companion', () {
      final model = AnthropicModelInfo(
        id: 'test-model',
        displayName: 'Test Model',
        modelFamily: 'test-1',
        contextWindow: 100000,
        maxOutputTokens: 8192,
        createdAt: DateTime(2025, 1, 1),
      );

      final companion = model.toDbCompanion();

      expect(companion.id.value, 'test-model');
      expect(companion.displayName.value, 'Test Model');
      expect(companion.modelFamily.value, 'test-1');
      expect(companion.contextWindow.value, 100000);
      expect(companion.maxOutputTokens.value, 8192);
    });

    test('toString includes id and displayName', () {
      final model = AnthropicModelInfo(
        id: 'model-1',
        displayName: 'My Model',
        createdAt: DateTime.now(),
      );

      expect(model.toString(), contains('model-1'));
      expect(model.toString(), contains('My Model'));
    });
  });
}
