/// Color-coded status badge for rotation policy health.
///
/// Derives a status label and color from the fields of a
/// [RotationPolicyResponse]: `isActive`, `failureCount`,
/// `nextRotationAt`, and `maxFailures`.
library;

import 'package:flutter/material.dart';

import '../../models/vault_models.dart';
import '../../theme/colors.dart';

/// The computed rotation health status.
enum RotationStatus {
  /// Policy is active and next rotation is in the future.
  healthy,

  /// Next rotation is within 1 hour.
  dueSoon,

  /// Next rotation time has passed.
  overdue,

  /// At least one consecutive failure recorded.
  failed,

  /// Policy is inactive (manually or after max failures).
  disabled;

  /// Human-readable label.
  String get label => switch (this) {
        RotationStatus.healthy => 'Healthy',
        RotationStatus.dueSoon => 'Due Soon',
        RotationStatus.overdue => 'Overdue',
        RotationStatus.failed => 'Failed',
        RotationStatus.disabled => 'Disabled',
      };

  /// Badge color.
  Color get color => switch (this) {
        RotationStatus.healthy => CodeOpsColors.success,
        RotationStatus.dueSoon => CodeOpsColors.warning,
        RotationStatus.overdue => CodeOpsColors.error,
        RotationStatus.failed => const Color(0xFFF97316),
        RotationStatus.disabled => CodeOpsColors.textTertiary,
      };
}

/// Derives [RotationStatus] from a [RotationPolicyResponse].
RotationStatus computeRotationStatus(RotationPolicyResponse policy) {
  if (!policy.isActive) return RotationStatus.disabled;
  if (policy.failureCount > 0) return RotationStatus.failed;

  final next = policy.nextRotationAt;
  if (next == null) return RotationStatus.healthy;

  final now = DateTime.now();
  if (next.isBefore(now)) return RotationStatus.overdue;
  if (next.difference(now).inMinutes < 60) return RotationStatus.dueSoon;

  return RotationStatus.healthy;
}

/// A compact color-coded badge showing rotation health status.
class VaultRotationStatusBadge extends StatelessWidget {
  /// The rotation policy to derive status from.
  final RotationPolicyResponse policy;

  /// Creates a [VaultRotationStatusBadge].
  const VaultRotationStatusBadge({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    final status = computeRotationStatus(policy);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
