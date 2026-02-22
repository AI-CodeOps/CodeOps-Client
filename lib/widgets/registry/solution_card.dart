/// Card displaying a solution summary in the list view.
///
/// Shows name, category badge, status badge, member count,
/// description, and optional color accent from [colorHex].
library;

import 'package:flutter/material.dart';

import '../../models/registry_models.dart';
import '../../theme/colors.dart';
import 'solution_status_badge.dart';

/// Solution summary card for the solutions list.
///
/// Renders name, category, status, member count, and truncated
/// description. When [SolutionResponse.colorHex] is set, displays
/// a left border accent in that color.
class SolutionCard extends StatelessWidget {
  /// The solution to display.
  final SolutionResponse solution;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Creates a [SolutionCard].
  const SolutionCard({super.key, required this.solution, this.onTap});

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseHex(solution.colorHex);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: CodeOpsColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CodeOpsColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color accent strip
              if (accentColor != null)
                Container(width: 4, color: accentColor),
              // Card content
              Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            solution.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CodeOpsColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        SolutionCategoryBadge(category: solution.category),
                        SolutionStatusBadge(status: solution.status),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                CodeOpsColors.textTertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${solution.memberCount ?? 0} '
                            '${(solution.memberCount ?? 0) == 1 ? 'service' : 'services'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: CodeOpsColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Description
                    if (solution.description != null &&
                        solution.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        solution.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CodeOpsColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
