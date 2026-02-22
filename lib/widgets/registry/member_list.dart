/// Reorderable member list for a solution.
///
/// Supports drag-to-reorder via [ReorderableListView], remove with
/// confirmation, and click-to-navigate to service detail. Each row
/// shows drag handle, display order, service name, role badge,
/// health indicator, and remove button.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import 'service_status_badge.dart';
import 'service_type_icon.dart';

/// Reorderable member list for a solution.
///
/// Calls [onReorder] with the new ordered service ID list after
/// drag-to-reorder. Calls [onRemove] when a member is removed.
/// Tapping a member name calls [onMemberTap].
class MemberList extends StatelessWidget {
  /// The solution ID (for key generation).
  final String solutionId;

  /// Members sorted by display order.
  final List<SolutionMemberResponse> members;

  /// Called with the new ordered service IDs after reorder.
  final void Function(List<String> serviceIds) onReorder;

  /// Called with the service ID to remove.
  final void Function(String serviceId) onRemove;

  /// Called when a member name is tapped.
  final void Function(String serviceId)? onMemberTap;

  /// Creates a [MemberList].
  const MemberList({
    super.key,
    required this.solutionId,
    required this.members,
    required this.onReorder,
    required this.onRemove,
    this.onMemberTap,
  });

  void _handleReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final reordered = List<SolutionMemberResponse>.from(members);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    onReorder(reordered.map((m) => m.serviceId).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.group_outlined,
                  size: 40, color: CodeOpsColors.textTertiary),
              SizedBox(height: 8),
              Text(
                'No members yet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Add services to this solution.',
                style: TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: members.length,
      onReorder: _handleReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            elevation: 4,
            color: CodeOpsColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
            child: child,
          ),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final member = members[index];
        return _MemberRow(
          key: ValueKey(member.serviceId),
          index: index,
          member: member,
          onTap: onMemberTap != null
              ? () => onMemberTap!(member.serviceId)
              : null,
          onRemove: () => onRemove(member.serviceId),
        );
      },
    );
  }
}

/// Individual member row with drag handle, info, and remove button.
class _MemberRow extends StatelessWidget {
  final int index;
  final SolutionMemberResponse member;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  const _MemberRow({
    super.key,
    required this.index,
    required this.member,
    this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = CodeOpsColors.solutionMemberRoleColors[member.role] ??
        CodeOpsColors.textTertiary;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.drag_indicator,
                      size: 18, color: CodeOpsColors.textTertiary),
                ),
              ),
            ),
            // Order number
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ),
            // Service type icon
            if (member.serviceType != null) ...[
              ServiceTypeIcon(type: member.serviceType!),
              const SizedBox(width: 8),
            ],
            // Service name (clickable)
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Text(
                  member.serviceName ?? member.serviceSlug ?? member.serviceId,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: onTap != null
                        ? CodeOpsColors.primary
                        : CodeOpsColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                member.role.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: roleColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Health indicator
            HealthIndicator(
              status: member.serviceHealthStatus,
              showLabel: false,
            ),
            const SizedBox(width: 12),
            // Remove button
            Tooltip(
              message: 'Remove member',
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close,
                      size: 16, color: CodeOpsColors.textTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
