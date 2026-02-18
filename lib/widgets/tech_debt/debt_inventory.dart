/// Debt inventory widget displaying a filterable, paginated list of tech debt items.
///
/// Provides a filter bar (search, status, category, effort, impact, sort),
/// a scrollable list of debt item cards with color-coded badges,
/// and pagination controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/tech_debt_item.dart';
import '../../providers/tech_debt_providers.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';
import '../shared/empty_state.dart';

/// Color mapping for [DebtCategory] badges.
const Map<DebtCategory, Color> _categoryColors = {
  DebtCategory.architecture: Color(0xFFEF4444),
  DebtCategory.code: Color(0xFFFBBF24),
  DebtCategory.test: Color(0xFF3B82F6),
  DebtCategory.dependency: Color(0xFFF97316),
  DebtCategory.documentation: Color(0xFF4ADE80),
};

/// Color mapping for [DebtStatus] badges.
const Map<DebtStatus, Color> _statusColors = {
  DebtStatus.identified: Color(0xFFF97316),
  DebtStatus.planned: Color(0xFF3B82F6),
  DebtStatus.inProgress: Color(0xFFA855F7),
  DebtStatus.resolved: Color(0xFF4ADE80),
};

/// Color mapping for [Effort] badges.
const Map<Effort, Color> _effortColors = {
  Effort.s: Color(0xFF4ADE80),
  Effort.m: Color(0xFFFBBF24),
  Effort.l: Color(0xFFF97316),
  Effort.xl: Color(0xFFEF4444),
};

/// Color mapping for [BusinessImpact] badges.
const Map<BusinessImpact, Color> _impactColors = {
  BusinessImpact.low: Color(0xFF64748B),
  BusinessImpact.medium: Color(0xFFFBBF24),
  BusinessImpact.high: Color(0xFFF97316),
  BusinessImpact.critical: Color(0xFFEF4444),
};

/// Sort options for the debt inventory.
enum DebtSortOption {
  /// Sort by business impact descending.
  impactDesc,

  /// Sort by effort ascending.
  effortAsc,

  /// Sort by category.
  category,

  /// Sort by status.
  status,

  /// Sort by date descending.
  dateDesc,
}

/// A filterable, paginated inventory of tech debt items.
class DebtInventory extends ConsumerStatefulWidget {
  /// Project ID to load debt items for.
  final String projectId;

  /// Callback when a debt item is tapped.
  final ValueChanged<TechDebtItem>? onItemSelected;

  /// Callback when delete is requested.
  final ValueChanged<TechDebtItem>? onDelete;

  /// Callback when status update is requested.
  final void Function(TechDebtItem item, DebtStatus newStatus)? onStatusUpdate;

  /// Creates a [DebtInventory].
  const DebtInventory({
    super.key,
    required this.projectId,
    this.onItemSelected,
    this.onDelete,
    this.onStatusUpdate,
  });

  @override
  ConsumerState<DebtInventory> createState() => _DebtInventoryState();
}

class _DebtInventoryState extends ConsumerState<DebtInventory> {
  final _searchController = TextEditingController();
  DebtSortOption _sortOption = DebtSortOption.impactDesc;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync =
        ref.watch(filteredTechDebtProvider(widget.projectId));
    final selectedItem = ref.watch(selectedTechDebtItemProvider);

    return Column(
      children: [
        // Filter bar
        _buildFilterBar(),
        const Divider(height: 1, color: CodeOpsColors.border),
        // Item list
        Expanded(
          child: filteredAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: CodeOpsColors.error),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.account_balance_outlined,
                  title: 'No tech debt items',
                  subtitle: 'Run a tech debt scan to discover items.',
                );
              }

              final sorted = _sortItems(items);
              // Client-side pagination
              final pageSize = AppConstants.defaultPageSize;
              final totalPages = (sorted.length / pageSize).ceil();
              final pageItems = sorted
                  .skip(_currentPage * pageSize)
                  .take(pageSize)
                  .toList();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) {
                        final item = pageItems[index];
                        final isSelected = selectedItem?.id == item.id;
                        return _DebtItemCard(
                          item: item,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(selectedTechDebtItemProvider.notifier)
                                .state = item;
                            widget.onItemSelected?.call(item);
                          },
                          onDelete: widget.onDelete,
                          onStatusUpdate: widget.onStatusUpdate,
                        );
                      },
                    ),
                  ),
                  if (totalPages > 1)
                    _buildPagination(totalPages),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: CodeOpsColors.surface,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Search
          SizedBox(
            width: 200,
            height: 36,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, size: 16),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: CodeOpsColors.border),
                ),
              ),
              onChanged: (value) {
                ref.read(techDebtSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          // Status filter
          _buildDropdown<DebtStatus?>(
            value: ref.watch(techDebtStatusFilterProvider),
            hint: 'Status',
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...DebtStatus.values.map(
                (s) => DropdownMenuItem(value: s, child: Text(s.displayName)),
              ),
            ],
            onChanged: (v) =>
                ref.read(techDebtStatusFilterProvider.notifier).state = v,
          ),
          // Category filter
          _buildDropdown<DebtCategory?>(
            value: ref.watch(techDebtCategoryFilterProvider),
            hint: 'Category',
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...DebtCategory.values.map(
                (c) => DropdownMenuItem(value: c, child: Text(c.displayName)),
              ),
            ],
            onChanged: (v) =>
                ref.read(techDebtCategoryFilterProvider.notifier).state = v,
          ),
          // Effort filter
          _buildDropdown<Effort?>(
            value: ref.watch(techDebtEffortFilterProvider),
            hint: 'Effort',
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...Effort.values.map(
                (e) => DropdownMenuItem(value: e, child: Text(e.toJson())),
              ),
            ],
            onChanged: (v) =>
                ref.read(techDebtEffortFilterProvider.notifier).state = v,
          ),
          // Impact filter
          _buildDropdown<BusinessImpact?>(
            value: ref.watch(techDebtImpactFilterProvider),
            hint: 'Impact',
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...BusinessImpact.values.map(
                (i) => DropdownMenuItem(value: i, child: Text(i.displayName)),
              ),
            ],
            onChanged: (v) =>
                ref.read(techDebtImpactFilterProvider.notifier).state = v,
          ),
          // Sort
          _buildDropdown<DebtSortOption>(
            value: _sortOption,
            hint: 'Sort',
            items: const [
              DropdownMenuItem(
                value: DebtSortOption.impactDesc,
                child: Text('Impact (desc)'),
              ),
              DropdownMenuItem(
                value: DebtSortOption.effortAsc,
                child: Text('Effort (asc)'),
              ),
              DropdownMenuItem(
                value: DebtSortOption.category,
                child: Text('Category'),
              ),
              DropdownMenuItem(
                value: DebtSortOption.status,
                child: Text('Status'),
              ),
              DropdownMenuItem(
                value: DebtSortOption.dateDesc,
                child: Text('Date (newest)'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _sortOption = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      height: 36,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textPrimary,
          ),
          dropdownColor: CodeOpsColors.surface,
          isDense: true,
        ),
      ),
    );
  }

  List<TechDebtItem> _sortItems(List<TechDebtItem> items) {
    final sorted = List<TechDebtItem>.from(items);
    switch (_sortOption) {
      case DebtSortOption.impactDesc:
        sorted.sort((a, b) {
          final ai = BusinessImpact.values.indexOf(
            a.businessImpact ?? BusinessImpact.low,
          );
          final bi = BusinessImpact.values.indexOf(
            b.businessImpact ?? BusinessImpact.low,
          );
          return bi.compareTo(ai);
        });
      case DebtSortOption.effortAsc:
        sorted.sort((a, b) {
          final ae = Effort.values.indexOf(a.effortEstimate ?? Effort.s);
          final be = Effort.values.indexOf(b.effortEstimate ?? Effort.s);
          return ae.compareTo(be);
        });
      case DebtSortOption.category:
        sorted.sort(
          (a, b) => a.category.index.compareTo(b.category.index),
        );
      case DebtSortOption.status:
        sorted.sort(
          (a, b) => a.status.index.compareTo(b.status.index),
        );
      case DebtSortOption.dateDesc:
        sorted.sort((a, b) {
          final ad = a.createdAt ?? DateTime(2000);
          final bd = b.createdAt ?? DateTime(2000);
          return bd.compareTo(ad);
        });
    }
    return sorted;
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }
}

/// A single debt item card with category, status, effort, and impact badges.
class _DebtItemCard extends StatelessWidget {
  final TechDebtItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<TechDebtItem>? onDelete;
  final void Function(TechDebtItem, DebtStatus)? onStatusUpdate;

  const _DebtItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
    this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: Card(
        color: isSelected
            ? CodeOpsColors.primary.withValues(alpha: 0.1)
            : CodeOpsColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color:
                isSelected ? CodeOpsColors.primary : CodeOpsColors.border,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _badge(
                      item.category.displayName,
                      _categoryColors[item.category]!,
                    ),
                    _badge(
                      item.status.displayName,
                      _statusColors[item.status]!,
                    ),
                    if (item.effortEstimate != null)
                      _badge(
                        item.effortEstimate!.toJson(),
                        _effortColors[item.effortEstimate]!,
                      ),
                    if (item.businessImpact != null)
                      _badge(
                        item.businessImpact!.displayName,
                        _impactColors[item.businessImpact]!,
                      ),
                  ],
                ),
                // File path
                if (item.filePath != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.filePath!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: CodeOpsColors.textTertiary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: item.filePath!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Path copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 14,
                          color: CodeOpsColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
                // Timestamps
                const SizedBox(height: 4),
                Text(
                  item.createdAt != null
                      ? 'Created ${_formatDate(item.createdAt!)}'
                      : '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: CodeOpsColors.surface,
      items: [
        const PopupMenuItem(value: 'status', child: Text('Edit Status')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: CodeOpsColors.error)),
        ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == 'delete') {
        onDelete?.call(item);
      } else if (value == 'status') {
        _showStatusPicker(context);
      }
    });
  }

  void _showStatusPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Status'),
        children: DebtStatus.values.map((status) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.of(ctx).pop();
              onStatusUpdate?.call(item, status);
            },
            child: Text(status.displayName),
          );
        }).toList(),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
