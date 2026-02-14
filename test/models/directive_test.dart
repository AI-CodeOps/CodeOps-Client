// Tests for Directive and ProjectDirective model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/directive.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('Directive', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'd-1',
        'name': 'Architecture Guide',
        'description': 'Defines architecture standards',
        'contentMd': '# Architecture\nFollow clean arch.',
        'category': 'ARCHITECTURE',
        'scope': 'TEAM',
        'teamId': 'team-1',
        'createdBy': 'user-1',
        'createdByName': 'Alice',
        'version': 3,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-02T00:00:00.000Z',
      };
      final directive = Directive.fromJson(json);
      expect(directive.category, DirectiveCategory.architecture);
      expect(directive.scope, DirectiveScope.team);
      expect(directive.version, 3);
    });

    test('toJson round-trip', () {
      final directive = Directive(
        id: 'd1',
        name: 'Standards',
        category: DirectiveCategory.conventions,
        scope: DirectiveScope.project,
      );
      final json = directive.toJson();
      expect(json['category'], 'CONVENTIONS');
      expect(json['scope'], 'PROJECT');
    });
  });

  group('ProjectDirective', () {
    test('fromJson with all fields', () {
      final json = {
        'projectId': 'p-1',
        'directiveId': 'd-1',
        'directiveName': 'Arch Guide',
        'category': 'STANDARDS',
        'enabled': true,
      };
      final pd = ProjectDirective.fromJson(json);
      expect(pd.category, DirectiveCategory.standards);
      expect(pd.enabled, true);
    });

    test('toJson round-trip', () {
      final pd = ProjectDirective(
        projectId: 'p1',
        directiveId: 'd1',
        category: DirectiveCategory.other,
        enabled: false,
      );
      final restored = ProjectDirective.fromJson(pd.toJson());
      expect(restored.category, DirectiveCategory.other);
      expect(restored.enabled, false);
    });
  });
}
