/// GitHub organization browser widget.
///
/// Displays a list of organizations with avatars. Selecting an org
/// updates [selectedOrgProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../shared/empty_state.dart';
import '../shared/error_panel.dart';

/// Displays a selectable list of GitHub organizations.
class OrgBrowser extends ConsumerWidget {
  /// Creates an [OrgBrowser].
  const OrgBrowser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(githubOrgsProvider);
    final selectedOrg = ref.watch(selectedOrgProvider);

    return orgsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(githubOrgsProvider),
      ),
      data: (orgs) {
        if (orgs.isEmpty) {
          return const EmptyState(
            icon: Icons.business,
            title: 'No Organizations',
            subtitle: 'No GitHub organizations found for this account.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: orgs.length,
          itemBuilder: (context, index) {
            final org = orgs[index];
            final isSelected = selectedOrg == org.login;

            return ListTile(
              selected: isSelected,
              selectedTileColor:
                  CodeOpsColors.primary.withValues(alpha: 0.12),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: CodeOpsColors.surfaceVariant,
                backgroundImage: org.avatarUrl != null
                    ? NetworkImage(org.avatarUrl!)
                    : null,
                child: org.avatarUrl == null
                    ? Text(
                        org.login[0].toUpperCase(),
                        style: const TextStyle(
                          color: CodeOpsColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              title: Text(
                org.name ?? org.login,
                style: TextStyle(
                  color: isSelected
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              subtitle: org.description != null
                  ? Text(
                      org.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    )
                  : null,
              onTap: () {
                ref.read(selectedOrgProvider.notifier).state = org.login;
              },
            );
          },
        );
      },
    );
  }
}
