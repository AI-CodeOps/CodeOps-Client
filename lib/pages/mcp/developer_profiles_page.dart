/// MCP developer profiles list page.
///
/// Displays at `/mcp/profiles`. Shows all developer profiles for the
/// selected team with avatar, display name, bio, timezone, active status,
/// session count, and token count. Click a card to navigate to detail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/mcp_models.dart';
import '../../providers/mcp_profile_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The MCP developer profiles list page.
class DeveloperProfilesPage extends ConsumerWidget {
  /// Creates a [DeveloperProfilesPage].
  const DeveloperProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to view developer profiles.',
      );
    }

    final profilesAsync = ref.watch(profileListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          const SizedBox(height: 20),
          profilesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              ),
            ),
            error: (e, _) => ErrorPanel.fromException(e, onRetry: () {
              ref.invalidate(profileListProvider);
            }),
            data: (profiles) {
              if (profiles.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_outline,
                  title: 'No profiles yet',
                  subtitle:
                      'Developer profiles are created when team members connect to MCP.',
                );
              }
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final profile in profiles)
                    _ProfileCard(profile: profile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.go('/mcp'),
          child: const Text(
            'Dashboard',
            style: TextStyle(fontSize: 12, color: CodeOpsColors.primary),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Developer Profiles',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Team members with MCP developer identities',
          style: TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final DeveloperProfile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name =
        profile.displayName ?? profile.userDisplayName ?? 'Unknown';
    final isActive = profile.isActive ?? true;

    return GestureDetector(
      onTap: () => context.go('/mcp/profiles/${profile.id}'),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CodeOpsColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CodeOpsColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name + active badge
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      CodeOpsColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: CodeOpsColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CodeOpsColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.timezone != null)
                        Text(
                          profile.timezone!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: CodeOpsColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? CodeOpsColors.success.withValues(alpha: 0.15)
                        : CodeOpsColors.textTertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? CodeOpsColors.success
                          : CodeOpsColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            // Bio preview
            if (profile.bio != null && profile.bio!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                profile.bio!,
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // Bottom row: environment badge
            Row(
              children: [
                if (profile.defaultEnvironment != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          CodeOpsColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      profile.defaultEnvironment!.displayName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: CodeOpsColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 16, color: CodeOpsColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
