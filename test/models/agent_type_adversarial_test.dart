// Tests for the 4 adversarial AgentType values and their UI integration.
//
// Verifies color map, metadata map, label map, tier classification,
// and serialization for all 16 AgentType values.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/enums.dart';
import 'package:codeops/theme/colors.dart';
import 'package:codeops/widgets/progress/agent_card.dart';

void main() {
  group('AgentType adversarial values', () {
    test('agentType has 16 values', () {
      expect(AgentType.values.length, 16);
    });

    test('serialization matches server for all 16 values', () {
      const expected = {
        'SECURITY',
        'CODE_QUALITY',
        'BUILD_HEALTH',
        'COMPLETENESS',
        'API_CONTRACT',
        'TEST_COVERAGE',
        'UI_UX',
        'DOCUMENTATION',
        'DATABASE',
        'PERFORMANCE',
        'DEPENDENCY',
        'ARCHITECTURE',
        'CHAOS_MONKEY',
        'HOSTILE_USER',
        'COMPLIANCE_AUDITOR',
        'LOAD_SABOTEUR',
      };
      final actual = AgentType.values.map((v) => v.toJson()).toSet();
      expect(actual, expected);
    });

    test('all 16 have display names', () {
      for (final v in AgentType.values) {
        expect(v.displayName, isNotEmpty,
            reason: '${v.name} missing displayName');
      }
    });

    test('all 16 have colors', () {
      for (final v in AgentType.values) {
        expect(CodeOpsColors.agentTypeColors.containsKey(v), isTrue,
            reason: '${v.name} missing color');
      }
    });

    test('all 16 have metadata (icon + description)', () {
      for (final v in AgentType.values) {
        expect(AgentTypeMetadata.all.containsKey(v), isTrue,
            reason: '${v.name} missing metadata');
        final meta = AgentTypeMetadata.all[v]!;
        expect(meta.displayName, isNotEmpty);
        expect(meta.description, isNotEmpty);
        expect(meta.icon, isA<IconData>());
      }
    });

    test('all 16 have labels', () {
      for (final v in AgentType.values) {
        expect(agentTypeLabels.containsKey(v), isTrue,
            reason: '${v.name} missing label');
      }
    });

    test('tier classification: core=4, conditional=8, adversarial=4', () {
      final core = AgentType.values.where((t) => t.isCore).toList();
      final conditional =
          AgentType.values.where((t) => t.isConditional).toList();
      final adversarial =
          AgentType.values.where((t) => t.isAdversarial).toList();

      expect(core.length, 4);
      expect(conditional.length, 8);
      expect(adversarial.length, 4);

      expect(core, containsAll([
        AgentType.security,
        AgentType.codeQuality,
        AgentType.buildHealth,
        AgentType.completeness,
      ]));

      expect(adversarial, containsAll([
        AgentType.chaosMonkey,
        AgentType.hostileUser,
        AgentType.complianceAuditor,
        AgentType.loadSaboteur,
      ]));
    });

    test('old v1.0 values do not exist', () {
      final jsonValues = AgentType.values.map((v) => v.toJson()).toSet();
      for (final old in [
        'BEST_PRACTICES',
        'ERROR_HANDLING',
        'TESTING',
        'ACCESSIBILITY',
        'TYPE_SAFETY',
        'MAINTAINABILITY',
      ]) {
        expect(jsonValues.contains(old), isFalse,
            reason: 'Old value $old should not exist');
      }
    });
  });
}
