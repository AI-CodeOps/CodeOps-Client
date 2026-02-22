/// Status and category badges for solutions.
///
/// [SolutionStatusBadge] displays the lifecycle status (ACTIVE,
/// IN_DEVELOPMENT, DEPRECATED, ARCHIVED) as a colored badge.
/// [SolutionCategoryBadge] displays the category (PLATFORM, APPLICATION,
/// LIBRARY_SUITE, INFRASTRUCTURE, TOOLING, OTHER) as a colored badge.
library;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../theme/colors.dart';

/// Colored badge displaying solution lifecycle status.
///
/// Maps [SolutionStatus] to colors via [CodeOpsColors.solutionStatusColors].
class SolutionStatusBadge extends StatelessWidget {
  /// The solution status to display.
  final SolutionStatus status;

  /// Creates a [SolutionStatusBadge].
  const SolutionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = CodeOpsColors.solutionStatusColors[status] ??
        CodeOpsColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Colored badge displaying solution category.
///
/// Maps [SolutionCategory] to colors via
/// [CodeOpsColors.solutionCategoryColors].
class SolutionCategoryBadge extends StatelessWidget {
  /// The solution category to display.
  final SolutionCategory category;

  /// Creates a [SolutionCategoryBadge].
  const SolutionCategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = CodeOpsColors.solutionCategoryColors[category] ??
        CodeOpsColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
