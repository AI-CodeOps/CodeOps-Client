/// Expandable detail panel for a single Vault audit log entry.
///
/// Displays all metadata fields (operation, path, resource type/ID,
/// user ID, IP address, correlation ID, error message, timestamp)
/// with copy-to-clipboard support on each value.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/vault_models.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import 'vault_audit_operation_badge.dart';

/// An expandable detail panel that shows all metadata for an
/// [AuditEntryResponse].
///
/// Each field row includes the field label and value, with a copy icon
/// that copies the value to the clipboard. The error message section
/// is highlighted in red when present.
class VaultAuditDetailRow extends StatelessWidget {
  /// The audit entry to display details for.
  final AuditEntryResponse entry;

  /// Creates a [VaultAuditDetailRow].
  const VaultAuditDetailRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operation badge + status
          Row(
            children: [
              VaultAuditOperationBadge(entry.operation),
              const SizedBox(width: 8),
              Icon(
                entry.success ? Icons.check_circle : Icons.cancel,
                size: 16,
                color:
                    entry.success ? CodeOpsColors.success : CodeOpsColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                entry.success ? 'Success' : 'Failed',
                style: TextStyle(
                  fontSize: 12,
                  color: entry.success
                      ? CodeOpsColors.success
                      : CodeOpsColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: CodeOpsColors.border),
          const SizedBox(height: 10),

          // Detail fields
          _DetailField(label: 'Path', value: entry.path),
          _DetailField(label: 'Resource Type', value: entry.resourceType),
          _DetailField(label: 'Resource ID', value: entry.resourceId),
          _DetailField(label: 'User ID', value: entry.userId),
          _DetailField(label: 'IP Address', value: entry.ipAddress),
          _DetailField(label: 'Correlation ID', value: entry.correlationId),
          _DetailField(
            label: 'Timestamp',
            value: formatDateTime(entry.createdAt),
          ),

          // Error message (highlighted)
          if (entry.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CodeOpsColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: CodeOpsColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: CodeOpsColors.error),
                      const SizedBox(width: 4),
                      const Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CodeOpsColors.error,
                        ),
                      ),
                      const Spacer(),
                      _CopyButton(value: entry.errorMessage!),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.errorMessage!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: CodeOpsColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DetailField extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailField({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          _CopyButton(value: value!),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String value;

  const _CopyButton({required this.value});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      },
      child: const Padding(
        padding: EdgeInsets.all(2),
        child: Icon(
          Icons.copy,
          size: 13,
          color: CodeOpsColors.textTertiary,
        ),
      ),
    );
  }
}
