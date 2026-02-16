/// Root widget for the CodeOps application.
///
/// Applies the dark theme and configures the [GoRouter] for navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/agent_config_providers.dart';
import 'providers/auth_providers.dart';
import 'providers/github_providers.dart';
import 'providers/team_providers.dart';
import 'router.dart';
import 'services/auth/auth_service.dart';
import 'services/logging/log_service.dart';
import 'theme/app_theme.dart';

/// The root application widget.
class CodeOpsApp extends ConsumerWidget {
  /// Creates the [CodeOpsApp].
  const CodeOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bridge AuthService stream → GoRouter's authNotifier
    ref.listen(authStateProvider, (_, next) {
      next.whenData((state) {
        authNotifier.state = state;

        // On authentication, auto-select the user's team
        if (state == AuthState.authenticated) {
          _initTeamSelection(ref);
          _initAgentConfig(ref);
        }
      });
    });

    return MaterialApp.router(
      title: 'CodeOps',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  Future<void> _initTeamSelection(WidgetRef ref) async {
    try {
      // Check for a previously stored team ID
      final secureStorage = ref.read(secureStorageProvider);
      final storedTeamId = await secureStorage.getSelectedTeamId();

      final teamApi = ref.read(teamApiProvider);
      final teams = await teamApi.getTeams();

      if (teams.isEmpty) {
        log.w('App', 'No teams found for user');
        return;
      }

      // Use stored team if it still exists, otherwise pick the first
      final teamId = (storedTeamId != null &&
              teams.any((t) => t.id == storedTeamId))
          ? storedTeamId
          : teams.first.id;

      ref.read(selectedTeamIdProvider.notifier).state = teamId;
      await secureStorage.setSelectedTeamId(teamId);
      log.i('App', 'Team auto-selected: $teamId');

      // Restore GitHub authentication from stored PAT.
      await restoreGitHubAuth(ref);
    } catch (e) {
      log.e('App', 'Failed to auto-select team', e);
    }
  }

  /// Seeds built-in agents and refreshes Anthropic model cache on login.
  Future<void> _initAgentConfig(WidgetRef ref) async {
    try {
      final agentConfigService = ref.read(agentConfigServiceProvider);

      // Idempotent: seeds 13 built-in agents if table is empty.
      await agentConfigService.seedBuiltInAgents();
      log.i('App', 'Agent config seeded');

      // Fire-and-forget: refresh model cache in the background.
      agentConfigService.refreshModels().then((_) {
        log.i('App', 'Anthropic models refreshed');
        ref.invalidate(anthropicModelsProvider);
      }).catchError((e) {
        log.w('App', 'Failed to refresh Anthropic models', e);
        ref.read(modelFetchFailedProvider.notifier).state = true;
      });
    } catch (e) {
      log.e('App', 'Failed to initialize agent config', e);
    }
  }
}
