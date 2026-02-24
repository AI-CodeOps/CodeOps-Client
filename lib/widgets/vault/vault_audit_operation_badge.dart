/// Reusable color-coded operation badge for Vault audit entries.
///
/// Maps each audit operation (READ, WRITE, DELETE, SEAL, etc.) to a
/// distinct color and renders a compact pill label.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// A compact color-coded badge displaying a Vault audit operation name.
///
/// The badge background and text color are derived from the [operation]
/// string using [operationColor]. Designed for use in audit tables,
/// detail rows, and activity feeds.
class VaultAuditOperationBadge extends StatelessWidget {
  /// The operation name to display (e.g. "READ", "WRITE", "DELETE").
  final String operation;

  /// Optional fixed width. Defaults to auto-sizing.
  final double? width;

  /// Creates a [VaultAuditOperationBadge].
  const VaultAuditOperationBadge(
    this.operation, {
    super.key,
    this.width,
  });

  /// Returns the color associated with the given audit [operation].
  static Color operationColor(String operation) {
    final upper = operation.toUpperCase();
    if (upper.contains('READ') || upper.contains('LIST')) {
      return const Color(0xFF3B82F6);
    }
    if (upper.contains('WRITE') || upper.contains('CREATE')) {
      return CodeOpsColors.success;
    }
    if (upper.contains('DELETE') || upper.contains('REVOKE')) {
      return CodeOpsColors.error;
    }
    if (upper.contains('SEAL') || upper.contains('UNSEAL')) {
      return CodeOpsColors.warning;
    }
    if (upper.contains('ENCRYPT') || upper.contains('DECRYPT')) {
      return const Color(0xFFA855F7);
    }
    if (upper.contains('ROTATE')) {
      return CodeOpsColors.secondary;
    }
    return CodeOpsColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    final color = operationColor(operation);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        operation,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
