/// Solution detail page.
///
/// Displays solution header with metadata, aggregated health summary,
/// and member list with drag-to-reorder, add, and remove actions.
/// Supports edit and delete operations via header action buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/registry/add_member_dialog.dart';
import '../../widgets/registry/member_list.dart';
import '../../widgets/registry/solution_form_dialog.dart';
import '../../widgets/registry/solution_health_summary.dart';
import '../../widgets/registry/solution_status_badge.dart';
import '../../widgets/shared/error_panel.dart';
import '../../widgets/shared/notification_toast.dart';

/// Solution detail page.
///
/// Watches [registrySolutionFullDetailProvider] for the solution detail
/// with member list, and [registrySolutionHealthProvider] for aggregated
/// health. Provides edit, delete, add member, remove member, and
/// reorder member actions.
class SolutionDetailPage extends ConsumerWidget {
  /// The solution ID from the route parameter.
  final String solutionId;

  /// Creates a [SolutionDetailPage].
  const SolutionDetailPage({super.key, required this.solutionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(registrySolutionFullDetailProvider(solutionId));

    return Column(
      children: [
        // Header bar
        _TopBar(solutionId: solutionId),
        // Content
        Expanded(
          child: detailAsync.when(
            data: (detail) => _DetailContent(
              solutionId: solutionId,
              detail: detail,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel(
              title: 'Failed to Load Solution',
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(registrySolutionFullDetailProvider(solutionId)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Top bar with back button and action buttons.
class _TopBar extends ConsumerWidget {
  final String solutionId;

  const _TopBar({required this.solutionId});

  Future<void> _deleteSolution(BuildContext context, WidgetRef ref) async {
    final detailAsync =
        ref.read(registrySolutionFullDetailProvider(solutionId));
    final name = detailAsync.valueOrNull?.name ?? 'this solution';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Solution',
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
      await api.deleteSolution(solutionId);
      ref.invalidate(registrySolutionsProvider);
      if (context.mounted) {
        showToast(context,
            message: 'Solution deleted', type: ToastType.success);
        context.go('/registry/solutions');
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Delete failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _editSolution(BuildContext context, WidgetRef ref) async {
    final detailAsync =
        ref.read(registrySolutionFullDetailProvider(solutionId));
    final detail = detailAsync.valueOrNull;
    if (detail == null) return;

    // Convert SolutionDetailResponse to SolutionResponse for the form
    final solutionResponse = SolutionResponse(
      id: detail.id,
      teamId: detail.teamId,
      name: detail.name,
      slug: detail.slug,
      description: detail.description,
      category: detail.category,
      status: detail.status,
      iconName: detail.iconName,
      colorHex: detail.colorHex,
      ownerUserId: detail.ownerUserId,
      repositoryUrl: detail.repositoryUrl,
      documentationUrl: detail.documentationUrl,
      metadataJson: detail.metadataJson,
      createdByUserId: detail.createdByUserId,
      memberCount: detail.members.length,
      createdAt: detail.createdAt,
      updatedAt: detail.updatedAt,
    );

    await showSolutionFormDialog(context, existingSolution: solutionResponse);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => context.go('/registry/solutions'),
            tooltip: 'Back to solutions',
          ),
          const SizedBox(width: 8),
          const Text(
            'Solution Detail',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _editSolution(context, ref),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CodeOpsColors.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _deleteSolution(context, ref),
            icon:
                const Icon(Icons.delete_outline, size: 16, color: CodeOpsColors.error),
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

/// Scrollable content with header, health, and members.
class _DetailContent extends ConsumerWidget {
  final String solutionId;
  final SolutionDetailResponse detail;

  const _DetailContent({required this.solutionId, required this.detail});

  Future<void> _removeMember(
      BuildContext context, WidgetRef ref, String serviceId) async {
    final member = detail.members
        .where((m) => m.serviceId == serviceId)
        .firstOrNull;
    final name = member?.serviceName ?? serviceId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Remove Member',
            style: TextStyle(color: CodeOpsColors.textPrimary)),
        content: Text(
          'Remove "$name" from this solution?',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ref.read(registryApiProvider);
      await api.removeSolutionMember(solutionId, serviceId);
      ref.invalidate(registrySolutionFullDetailProvider(solutionId));
      ref.invalidate(registrySolutionHealthProvider(solutionId));
      if (context.mounted) {
        showToast(context,
            message: '$name removed', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Remove failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _reorderMembers(WidgetRef ref, List<String> serviceIds) async {
    try {
      final api = ref.read(registryApiProvider);
      await api.reorderSolutionMembers(solutionId, serviceIds);
      ref.invalidate(registrySolutionFullDetailProvider(solutionId));
    } catch (_) {
      // Revert happens via provider refresh
      ref.invalidate(registrySolutionFullDetailProvider(solutionId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(registrySolutionHealthProvider(solutionId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solution header card
          _SolutionHeader(detail: detail),
          const SizedBox(height: 16),
          // Health summary
          healthAsync.when(
            data: (health) => SolutionHealthSummary(health: health),
            loading: () => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CodeOpsColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CodeOpsColors.border),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading health data...',
                    style: TextStyle(
                      fontSize: 13,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Members section
          Container(
            decoration: BoxDecoration(
              color: CodeOpsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Members header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 16, color: CodeOpsColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Members (${detail.members.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CodeOpsColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => showAddMemberDialog(
                          context,
                          solutionId: solutionId,
                          existingMemberServiceIds: detail.members
                              .map((m) => m.serviceId)
                              .toSet(),
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Member'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: CodeOpsColors.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: CodeOpsColors.divider),
                // Member list
                MemberList(
                  solutionId: solutionId,
                  members: detail.members,
                  onReorder: (serviceIds) =>
                      _reorderMembers(ref, serviceIds),
                  onRemove: (serviceId) =>
                      _removeMember(context, ref, serviceId),
                  onMemberTap: (serviceId) =>
                      context.go('/registry/services/$serviceId'),
                ),
              ],
            ),
          ),
          // Drag hint
          if (detail.members.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Drag handles to reorder \u00b7 Click name to view service',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Solution header card with metadata.
class _SolutionHeader extends StatelessWidget {
  final SolutionDetailResponse detail;

  const _SolutionHeader({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            detail.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Slug + badges
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                detail.slug,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: CodeOpsColors.textTertiary,
                ),
              ),
              SolutionCategoryBadge(category: detail.category),
              SolutionStatusBadge(status: detail.status),
            ],
          ),
          // Description
          if (detail.description != null &&
              detail.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detail.description!,
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
          // URLs
          if (detail.repositoryUrl != null ||
              detail.documentationUrl != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (detail.repositoryUrl != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.code,
                          size: 14, color: CodeOpsColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        detail.repositoryUrl!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CodeOpsColors.primary,
                        ),
                      ),
                    ],
                  ),
                if (detail.documentationUrl != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 14, color: CodeOpsColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        detail.documentationUrl!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CodeOpsColors.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          // Timestamps
          if (detail.createdAt != null || detail.updatedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (detail.createdAt != null)
                  'Created: ${_formatDate(detail.createdAt!)}',
                if (detail.updatedAt != null)
                  'Updated: ${_formatDate(detail.updatedAt!)}',
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

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
