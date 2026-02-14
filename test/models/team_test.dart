// Tests for Team, TeamMember, and Invitation model serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:codeops/models/team.dart';
import 'package:codeops/models/enums.dart';

void main() {
  group('Team', () {
    test('fromJson with all fields', () {
      final json = {
        'id': 'team-1',
        'name': 'Alpha Team',
        'description': 'Test team',
        'ownerId': 'user-1',
        'ownerName': 'Owner',
        'teamsWebhookUrl': 'https://hooks.example.com',
        'memberCount': 5,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-02T00:00:00.000Z',
      };
      final team = Team.fromJson(json);
      expect(team.id, 'team-1');
      expect(team.name, 'Alpha Team');
      expect(team.memberCount, 5);
    });

    test('toJson round-trip', () {
      final team = Team(id: 't1', name: 'T1', ownerId: 'o1');
      final restored = Team.fromJson(team.toJson());
      expect(restored.id, 't1');
      expect(restored.name, 'T1');
    });
  });

  group('TeamMember', () {
    test('fromJson with role enum', () {
      final json = {
        'id': 'tm-1',
        'userId': 'u-1',
        'displayName': 'Alice',
        'email': 'alice@test.com',
        'role': 'ADMIN',
      };
      final member = TeamMember.fromJson(json);
      expect(member.role, TeamRole.admin);
      expect(member.displayName, 'Alice');
    });

    test('toJson round-trip preserves role', () {
      final member = TeamMember(id: '1', userId: 'u1', role: TeamRole.member);
      final json = member.toJson();
      expect(json['role'], 'MEMBER');
      final restored = TeamMember.fromJson(json);
      expect(restored.role, TeamRole.member);
    });
  });

  group('Invitation', () {
    test('fromJson with enums', () {
      final json = {
        'id': 'inv-1',
        'email': 'bob@test.com',
        'role': 'VIEWER',
        'status': 'PENDING',
        'invitedByName': 'Alice',
        'expiresAt': '2025-02-01T00:00:00.000Z',
        'createdAt': '2025-01-15T00:00:00.000Z',
      };
      final inv = Invitation.fromJson(json);
      expect(inv.role, TeamRole.viewer);
      expect(inv.status, InvitationStatus.pending);
      expect(inv.invitedByName, 'Alice');
    });

    test('toJson round-trip', () {
      final inv = Invitation(
        id: 'i1',
        email: 'a@b.com',
        role: TeamRole.admin,
        status: InvitationStatus.accepted,
      );
      final restored = Invitation.fromJson(inv.toJson());
      expect(restored.role, TeamRole.admin);
      expect(restored.status, InvitationStatus.accepted);
    });
  });
}
