// Tests for MCP context viewer providers.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/mcp_context_providers.dart';

void main() {
  group('ContextSectionHealth', () {
    test('displayName returns correct labels', () {
      expect(ContextSectionHealth.healthy.displayName, 'Healthy');
      expect(ContextSectionHealth.stale.displayName, 'Stale');
      expect(ContextSectionHealth.missing.displayName, 'Missing');
      expect(ContextSectionHealth.notApplicable.displayName, 'N/A');
    });
  });

  group('ContextSection', () {
    test('creates with required fields', () {
      final section = ContextSection(
        title: 'Persona',
        health: ContextSectionHealth.healthy,
        data: {'agentType': 'claude'},
        itemCount: 1,
        sizeBytes: 24,
      );

      expect(section.title, 'Persona');
      expect(section.health, ContextSectionHealth.healthy);
      expect(section.data['agentType'], 'claude');
      expect(section.itemCount, 1);
      expect(section.sizeBytes, 24);
    });

    test('defaults itemCount and sizeBytes to zero', () {
      final section = ContextSection(
        title: 'Test',
        health: ContextSectionHealth.notApplicable,
        data: {},
      );

      expect(section.itemCount, 0);
      expect(section.sizeBytes, 0);
    });
  });

  group('AssembledContext', () {
    test('creates with all fields', () {
      final sections = [
        ContextSection(
          title: 'Persona',
          health: ContextSectionHealth.healthy,
          data: {'test': true},
          itemCount: 1,
          sizeBytes: 14,
        ),
        ContextSection(
          title: 'Conventions',
          health: ContextSectionHealth.missing,
          data: {'present': false},
          itemCount: 0,
          sizeBytes: 18,
        ),
      ];

      final ctx = AssembledContext(
        sections: sections,
        totalSizeBytes: 32,
        estimatedTokens: 8,
        payload: {'persona': sections[0].data},
      );

      expect(ctx.sections.length, 2);
      expect(ctx.totalSizeBytes, 32);
      expect(ctx.estimatedTokens, 8);
      expect(ctx.payload.containsKey('persona'), isTrue);
    });
  });
}
