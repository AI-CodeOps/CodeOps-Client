/// Card displaying all port allocations for a service.
///
/// Shows port type, number, protocol, environment, and allocation info
/// in a compact table layout with color-coded port type labels.
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';

/// Card displaying port allocations for a service.
///
/// Renders a table of port type, number, protocol, environment,
/// and description. Shows an empty state when no ports are allocated.
class PortListCard extends StatelessWidget {
  /// The port allocations to display.
  final List<PortAllocationResponse> ports;

  /// Creates a [PortListCard].
  const PortListCard({super.key, required this.ports});

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      title: 'Port Allocations',
      count: ports.length,
      icon: Icons.dns_outlined,
      emptyMessage: 'No ports allocated',
      isEmpty: ports.isEmpty,
      child: Column(
        children: [
          // Header row
          const _TableHeader(
            columns: ['Type', 'Port', 'Protocol', 'Env', 'Description'],
          ),
          const Divider(height: 1, color: CodeOpsColors.border),
          // Data rows
          ...ports.map(
            (port) => _PortRow(port: port),
          ),
        ],
      ),
    );
  }
}

class _PortRow extends StatelessWidget {
  final PortAllocationResponse port;

  const _PortRow({required this.port});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CodeOpsColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Port type badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CodeOpsColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                port.portType.displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
          ),
          // Port number
          Expanded(
            child: Text(
              '${port.portNumber}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
          // Protocol
          Expanded(
            child: Text(
              port.protocol ?? 'TCP',
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          // Environment
          Expanded(
            child: Text(
              port.environment,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          // Description
          Expanded(
            flex: 2,
            child: Text(
              port.description ?? (port.isAutoAllocated == true ? 'Auto-allocated' : ''),
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Card Components
// ---------------------------------------------------------------------------

/// Reusable card container with title, count badge, and empty state.
class _CardContainer extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final String emptyMessage;
  final bool isEmpty;
  final Widget child;

  const _CardContainer({
    required this.title,
    required this.count,
    required this.icon,
    required this.emptyMessage,
    required this.isEmpty,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: CodeOpsColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}

/// Header row for card tables.
class _TableHeader extends StatelessWidget {
  final List<String> columns;

  const _TableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CodeOpsColors.surfaceVariant,
      child: Row(
        children: columns
            .map(
              (col) => Expanded(
                flex: (col == 'Type' || col == 'Description') ? 2 : 1,
                child: Text(
                  col,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
