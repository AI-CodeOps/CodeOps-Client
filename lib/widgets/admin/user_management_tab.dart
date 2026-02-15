/// Admin user management tab.
///
/// Displays a paginated data table of users with search, status toggle,
/// and pagination controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/admin_providers.dart';
import '../../theme/colors.dart';

/// Displays the admin user management data table.
class UserManagementTab extends ConsumerStatefulWidget {
  /// Creates a [UserManagementTab].
  const UserManagementTab({super.key});

  @override
  ConsumerState<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends ConsumerState<UserManagementTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final searchQuery = ref.watch(adminUserSearchProvider).toLowerCase();
    final currentPage = ref.watch(adminUserPageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: Icon(Icons.search, size: 18),
              isDense: true,
            ),
            onChanged: (v) =>
                ref.read(adminUserSearchProvider.notifier).state = v,
          ),
        ),
        const SizedBox(height: 16),

        // Data table
        usersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text(
            'Failed to load users: $e',
            style: const TextStyle(color: CodeOpsColors.error, fontSize: 13),
          ),
          data: (pageResponse) {
            var users = pageResponse.content;

            // Client-side search filter
            if (searchQuery.isNotEmpty) {
              users = users.where((u) {
                return u.displayName.toLowerCase().contains(searchQuery) ||
                    u.email.toLowerCase().contains(searchQuery);
              }).toList();
            }

            if (users.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No users found.',
                  style: TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              );
            }

            return Column(
              children: [
                DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(CodeOpsColors.surfaceVariant),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Last Active')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: users.map((user) {
                    final isActive = user.isActive ?? true;
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          user.displayName,
                          style: const TextStyle(fontSize: 13),
                        )),
                        DataCell(Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CodeOpsColors.textSecondary,
                          ),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isActive
                                      ? CodeOpsColors.success
                                      : CodeOpsColors.textTertiary)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                color: isActive
                                    ? CodeOpsColors.success
                                    : CodeOpsColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          user.lastLoginAt != null
                              ? DateFormat('M/d/yy HH:mm')
                                  .format(user.lastLoginAt!)
                              : '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CodeOpsColors.textTertiary,
                          ),
                        )),
                        DataCell(
                          TextButton(
                            onPressed: () =>
                                _toggleUserStatus(user.id, isActive),
                            child: Text(
                              isActive ? 'Deactivate' : 'Activate',
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive
                                    ? CodeOpsColors.warning
                                    : CodeOpsColors.success,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Pagination controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: currentPage > 0
                          ? () => ref
                              .read(adminUserPageProvider.notifier)
                              .state = currentPage - 1
                          : null,
                    ),
                    Text(
                      'Page ${currentPage + 1} of ${pageResponse.totalPages}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: !pageResponse.isLast
                          ? () => ref
                              .read(adminUserPageProvider.notifier)
                              .state = currentPage + 1
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggleUserStatus(String userId, bool currentlyActive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentlyActive ? 'Deactivate User' : 'Activate User'),
        content: Text(
          currentlyActive
              ? 'Are you sure you want to deactivate this user?'
              : 'Are you sure you want to activate this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              currentlyActive ? 'Deactivate' : 'Activate',
              style: TextStyle(
                color: currentlyActive
                    ? CodeOpsColors.warning
                    : CodeOpsColors.success,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminApi = ref.read(adminApiProvider);
      await adminApi.updateUserStatus(userId, isActive: !currentlyActive);
      ref.invalidate(adminUsersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $e')),
        );
      }
    }
  }
}
