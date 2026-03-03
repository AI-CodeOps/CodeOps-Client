// Widget tests for My Profile badge detection.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/mcp_enums.dart';
import 'package:codeops/models/mcp_models.dart';
import 'package:codeops/models/user.dart';
import 'package:codeops/pages/mcp/developer_profile_detail_page.dart';
import 'package:codeops/providers/auth_providers.dart';
import 'package:codeops/providers/mcp_profile_providers.dart';

void main() {
  final profile = DeveloperProfile(
    id: 'dev-1',
    displayName: 'Adam',
    isActive: true,
    userId: 'user-1',
    defaultEnvironment: McpEnvironment.local,
  );

  group('My Profile badge', () {
    testWidgets('shows My Profile badge when userId matches current user',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
              (ref) => User(id: 'user-1', email: 'adam@allard.com', displayName: 'Adam')),
          profileDetailProvider.overrideWith(
              (ref, id) => Future.value(profile)),
          profileSessionsProvider
              .overrideWith((ref, id) => Future.value([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeveloperProfileDetailPage(profileId: 'dev-1'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
    });
  });
}
