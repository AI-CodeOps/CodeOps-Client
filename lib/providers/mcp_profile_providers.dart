/// Developer profile and token management providers for the MCP module.
///
/// Manages profile selection, editing state, token listing, and UI state
/// for the Developer Profiles and Token Management pages.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mcp_enums.dart';
import '../models/mcp_models.dart';
import 'auth_providers.dart';
import 'mcp_providers.dart';
import 'team_providers.dart' show selectedTeamIdProvider;

// ─────────────────────────────────────────────────────────────────────────────
// Profile List Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches all developer profiles for the selected team.
final profileListProvider =
    FutureProvider.autoDispose<List<DeveloperProfile>>((ref) {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return Future.value([]);
  final api = ref.watch(mcpApiProvider);
  return api.getTeamProfiles(teamId: teamId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Profile Detail Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a single developer profile from the team profiles list.
final profileDetailProvider = FutureProvider.autoDispose
    .family<DeveloperProfile?, String>((ref, profileId) async {
  final profiles = await ref.watch(profileListProvider.future);
  return profiles.where((p) => p.id == profileId).firstOrNull;
});

/// Session history for a profile's projects (last 10 sessions via team).
final profileSessionsProvider = FutureProvider.autoDispose
    .family<List<McpSession>, String>((ref, profileId) async {
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return [];
  final api = ref.watch(mcpApiProvider);
  final page = await api.getMySessions(teamId: teamId, size: 10);
  return page.content;
});

// ─────────────────────────────────────────────────────────────────────────────
// Token Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches tokens for a developer profile.
final profileTokensProvider = FutureProvider.autoDispose
    .family<List<McpApiToken>, String>((ref, profileId) {
  final api = ref.watch(mcpApiProvider);
  return api.getTokens(profileId);
});

// ─────────────────────────────────────────────────────────────────────────────
// My Profile Detection
// ─────────────────────────────────────────────────────────────────────────────

/// Whether a given profile belongs to the current user.
final isMyProfileProvider =
    Provider.autoDispose.family<bool, String>((ref, profileUserId) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser?.id == profileUserId;
});

// ─────────────────────────────────────────────────────────────────────────────
// UI State Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Whether the profile detail page is in edit mode.
final profileEditModeProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Filter for token status on the token management page.
final tokenStatusFilterProvider =
    StateProvider.autoDispose<TokenStatus?>((ref) => null);
