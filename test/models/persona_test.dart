// Tests for Persona model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/persona.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('Persona', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'p-1',
        'name': 'Security Expert',
        'agentType': 'SECURITY',
        'description': 'Specialized security persona',
        'contentMd': '# Security Expert\nAnalyze for vulnerabilities.',
        'scope': 'TEAM',
        'teamId': 'team-1',
        'createdBy': 'user-1',
        'createdByName': 'Alice',
        'isDefault': true,
        'version': 2,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-02T00:00:00.000Z',
      };
      final persona = Persona.fromJson(json);
      expect(persona.agentType, AgentType.security);
      expect(persona.scope, Scope.team);
      expect(persona.isDefault, true);
      expect(persona.version, 2);
    });

    test('toJson round-trip', () {
      final persona = Persona(
        id: 'p1',
        name: 'Default',
        scope: Scope.system,
        agentType: AgentType.buildHealth,
      );
      final json = persona.toJson();
      expect(json['scope'], 'SYSTEM');
      expect(json['agentType'], 'BUILD_HEALTH');
      final restored = Persona.fromJson(json);
      expect(restored.scope, Scope.system);
    });
  });
}
