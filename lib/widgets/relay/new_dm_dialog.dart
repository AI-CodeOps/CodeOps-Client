/// Dialog for starting a new direct message conversation.
///
/// Displays a searchable list of team members. Selecting a member
/// calls [RelayApiService.getOrCreateConversation] to create (or
/// retrieve an existing) conversation, then returns the conversation
/// ID to the caller.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/relay_models.dart';
import '../../models/team.dart';
import '../../providers/auth_providers.dart';
import '../../providers/relay_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';

/// Dialog for starting a new direct message conversation.
///
/// Shows team members from [teamMembersProvider], filtered by a
/// search field. The current user is excluded from the list.
/// Tapping a member creates or retrieves a 1:1 conversation via
/// [RelayApiService.getOrCreateConversation] and pops with the
/// conversation ID.
class NewDmDialog extends ConsumerStatefulWidget {
  /// The team ID to load members from.
  final String teamId;

  /// Creates a [NewDmDialog].
  const NewDmDialog({required this.teamId, super.key});

  @override
  ConsumerState<NewDmDialog> createState() => _NewDmDialogState();
}

class _NewDmDialogState extends ConsumerState<NewDmDialog> {
  final _searchController = TextEditingController();
  String _filterQuery = '';
  bool _creating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Creates or retrieves a conversation with the selected member.
  Future<void> _selectMember(TeamMember member) async {
    setState(() {
      _creating = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(relayApiProvider);
      final result = await api.getOrCreateConversation(
        CreateDirectConversationRequest(
          participantIds: [member.userId],
        ),
        widget.teamId,
      );

      // Refresh conversations list
      ref.invalidate(conversationsProvider(widget.teamId));

      if (mounted) {
        Navigator.of(context).pop(result.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creating = false;
          _errorMessage = 'Failed to start conversation';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  const Icon(Icons.person_add_outlined,
                      size: 20, color: CodeOpsColors.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'New Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: CodeOpsColors.textTertiary),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 16, color: CodeOpsColors.border),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _filterQuery = value.trim().toLowerCase());
                },
                style: const TextStyle(
                    fontSize: 13, color: CodeOpsColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: CodeOpsColors.textTertiary),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: CodeOpsColors.textTertiary),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.primary),
                  ),
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.error,
                  ),
                ),
              ),

            // Member list
            Flexible(
              child: _creating
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : membersAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Failed to load members',
                          style: TextStyle(
                            fontSize: 13,
                            color: CodeOpsColors.textTertiary,
                          ),
                        ),
                      ),
                      data: (members) {
                        // Filter out current user and apply search
                        var filtered = members.where((m) {
                          if (currentUser != null &&
                              m.userId == currentUser.id) {
                            return false;
                          }
                          return true;
                        }).toList();

                        if (_filterQuery.isNotEmpty) {
                          filtered = filtered.where((m) {
                            final name =
                                (m.displayName ?? '').toLowerCase();
                            final email = (m.email ?? '').toLowerCase();
                            return name.contains(_filterQuery) ||
                                email.contains(_filterQuery);
                          }).toList();
                        }

                        // Sort alphabetically
                        filtered.sort((a, b) => (a.displayName ?? '')
                            .toLowerCase()
                            .compareTo(
                                (b.displayName ?? '').toLowerCase()));

                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No members found',
                              style: TextStyle(
                                fontSize: 13,
                                color: CodeOpsColors.textTertiary,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final member = filtered[index];
                            return _buildMemberTile(member);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single member tile in the list.
  Widget _buildMemberTile(TeamMember member) {
    final name = member.displayName ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: () => _selectMember(member),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  CodeOpsColors.primary.withValues(alpha: 0.3),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  if (member.email != null)
                    Text(
                      member.email!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
