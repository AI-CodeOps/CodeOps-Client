/// Workstation profile detail page.
///
/// Displays profile header with metadata, startup order timeline,
/// service list, and action buttons for edit, set default, refresh
/// startup order, and delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/startup_order_display.dart';
import '../../widgets/registry/workstation_form_dialog.dart';
import '../../widgets/shared/error_panel.dart';
import '../../widgets/shared/notification_toast.dart';

/// Workstation profile detail page.
///
/// Watches [registryWorkstationProfileDetailProvider] for profile data.
/// Provides edit, set default, refresh startup order, and delete actions.
class WorkstationDetailPage extends ConsumerWidget {
  /// The profile ID from the route parameter.
  final String profileId;

  /// Creates a [WorkstationDetailPage].
  const WorkstationDetailPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(registryWorkstationProfileDetailProvider(profileId));

    return Column(
      children: [
        // Top bar
        _TopBar(profileId: profileId),
        // Content
        Expanded(
          child: detailAsync.when(
            data: (profile) => _DetailContent(
              profileId: profileId,
              profile: profile,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel(
              title: 'Failed to Load Profile',
              message: e.toString(),
              onRetry: () => ref.invalidate(
                  registryWorkstationProfileDetailProvider(profileId)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Top bar with back button and action buttons.
class _TopBar extends ConsumerWidget {
  final String profileId;

  const _TopBar({required this.profileId});

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final detailAsync =
        ref.read(registryWorkstationProfileDetailProvider(profileId));
    final profile = detailAsync.valueOrNull;
    if (profile == null) return;

    await showWorkstationFormDialog(context, existingProfile: profile);
  }

  Future<void> _setDefault(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(registryApiProvider);
      await api.setDefaultWorkstationProfile(profileId);
      ref.invalidate(registryWorkstationProfileDetailProvider(profileId));
      ref.invalidate(registryWorkstationProfilesProvider);
      ref.invalidate(registryDefaultWorkstationProvider);
      if (context.mounted) {
        showToast(context,
            message: 'Set as default profile', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Set default failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _refreshOrder(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(registryApiProvider);
      await api.refreshStartupOrder(profileId);
      ref.invalidate(registryWorkstationProfileDetailProvider(profileId));
      if (context.mounted) {
        showToast(context,
            message: 'Startup order refreshed', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Refresh failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _deleteProfile(BuildContext context, WidgetRef ref) async {
    final detailAsync =
        ref.read(registryWorkstationProfileDetailProvider(profileId));
    final name = detailAsync.valueOrNull?.name ?? 'this profile';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Profile',
            style: TextStyle(color: CodeOpsColors.textPrimary)),
        content: Text(
          'Permanently delete "$name"? This cannot be undone.',
          style: const TextStyle(color: CodeOpsColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ref.read(registryApiProvider);
      await api.deleteWorkstationProfile(profileId);
      ref.invalidate(registryWorkstationProfilesProvider);
      if (context.mounted) {
        showToast(context,
            message: 'Profile deleted', type: ToastType.success);
        context.go('/registry/workstations');
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Delete failed: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(registryWorkstationProfileDetailProvider(profileId));
    final isDefault = detailAsync.valueOrNull?.isDefault == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 20, color: CodeOpsColors.textSecondary),
            onPressed: () => context.go('/registry/workstations'),
            tooltip: 'Back to profiles',
          ),
          const SizedBox(width: 8),
          const Text(
            'Workstation Detail',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Refresh Order
          OutlinedButton.icon(
            onPressed: () => _refreshOrder(context, ref),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh Order'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CodeOpsColors.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          // Set Default
          if (!isDefault)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: () => _setDefault(context, ref),
                icon: const Icon(Icons.star_outline,
                    size: 16, color: CodeOpsColors.warning),
                label: const Text('Set Default'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CodeOpsColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          // Edit
          OutlinedButton.icon(
            onPressed: () => _editProfile(context, ref),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CodeOpsColors.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          // Delete
          OutlinedButton.icon(
            onPressed: () => _deleteProfile(context, ref),
            icon: const Icon(Icons.delete_outline,
                size: 16, color: CodeOpsColors.error),
            label: const Text('Delete',
                style: TextStyle(color: CodeOpsColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CodeOpsColors.error),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable content with header and startup order.
class _DetailContent extends StatelessWidget {
  final String profileId;
  final WorkstationProfileResponse profile;

  const _DetailContent({required this.profileId, required this.profile});

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final services = profile.services ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header card
          _ProfileHeader(profile: profile, formatDate: _formatDate),
          const SizedBox(height: 16),
          // Startup order section
          Container(
            decoration: BoxDecoration(
              color: CodeOpsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.sort,
                          size: 16, color: CodeOpsColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Startup Order (${services.length} services)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CodeOpsColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: CodeOpsColors.divider),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: StartupOrderDisplay(
                    services: services,
                    startupOrder: profile.startupOrder ?? [],
                    onServiceTap: (serviceId) =>
                        context.go('/registry/services/$serviceId'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile header card with name, badges, description, and timestamps.
class _ProfileHeader extends StatelessWidget {
  final WorkstationProfileResponse profile;
  final String Function(DateTime) formatDate;

  const _ProfileHeader({required this.profile, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final isDefault = profile.isDefault == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDefault
              ? CodeOpsColors.primary.withValues(alpha: 0.5)
              : CodeOpsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + default badge
          Row(
            children: [
              if (isDefault) ...[
                const Icon(Icons.star, size: 20, color: CodeOpsColors.warning),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          // Badges
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.warning,
                    ),
                  ),
                ),
              if (profile.solutionId != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'From Solution',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.primary,
                    ),
                  ),
                ),
              Text(
                '${(profile.services ?? []).length} services',
                style: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
          // Description
          if (profile.description != null &&
              profile.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              profile.description!,
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
          // Timestamps
          if (profile.createdAt != null || profile.updatedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (profile.createdAt != null)
                  'Created: ${formatDate(profile.createdAt!)}',
                if (profile.updatedAt != null)
                  'Updated: ${formatDate(profile.updatedAt!)}',
              ].join('  \u00b7  '),
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
