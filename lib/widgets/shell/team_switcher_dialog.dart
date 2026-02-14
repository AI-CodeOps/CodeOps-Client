/// Dialog for switching between teams.
///
/// Lists teams from [teamsProvider], highlights the currently selected team,
/// and includes an inline create-team form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/team_providers.dart';
import '../../theme/colors.dart';
import '../shared/error_panel.dart';

/// A dialog that lets the user switch teams or create a new one.
class TeamSwitcherDialog extends ConsumerStatefulWidget {
  /// Creates a [TeamSwitcherDialog].
  const TeamSwitcherDialog({super.key});

  @override
  ConsumerState<TeamSwitcherDialog> createState() =>
      _TeamSwitcherDialogState();
}

class _TeamSwitcherDialogState extends ConsumerState<TeamSwitcherDialog> {
  bool _showCreateForm = false;
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _creating = true);
    try {
      final teamApi = ref.read(teamApiProvider);
      final team = await teamApi.createTeam(name: name);
      ref.read(selectedTeamIdProvider.notifier).state = team.id;
      ref.invalidate(teamsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final selectedTeamId = ref.watch(selectedTeamIdProvider);

    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Switch Team',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: teamsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, _) => ErrorPanel.fromException(
                    error,
                    onRetry: () => ref.invalidate(teamsProvider),
                  ),
                  data: (teams) {
                    if (teams.isEmpty) {
                      return const Center(
                        child: Text(
                          'No teams found.',
                          style: TextStyle(color: CodeOpsColors.textTertiary),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: teams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final isSelected = team.id == selectedTeamId;
                        return _TeamCard(
                          name: team.name,
                          memberCount: team.memberCount ?? 0,
                          ownerName: team.ownerName ?? '',
                          isSelected: isSelected,
                          onTap: () {
                            ref.read(selectedTeamIdProvider.notifier).state =
                                team.id;
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_showCreateForm) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Team name',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _createTeam(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _creating ? null : _createTeam,
                      child: _creating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showCreateForm = true),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Team'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String name;
  final int memberCount;
  final String ownerName;
  final bool isSelected;
  final VoidCallback onTap;

  const _TeamCard({
    required this.name,
    required this.memberCount,
    required this.ownerName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CodeOpsColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? CodeOpsColors.primary : CodeOpsColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$memberCount members \u2022 Owner: $ownerName',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: CodeOpsColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
