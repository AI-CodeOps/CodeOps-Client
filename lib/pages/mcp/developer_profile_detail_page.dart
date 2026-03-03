/// MCP developer profile detail page.
///
/// Displays at `/mcp/profiles/:profileId`. Shows profile info (editable),
/// preferences JSON editor, session history mini-table, usage stats,
/// and a token management link. "My Profile" badge for current user.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/mcp_enums.dart';
import '../../models/mcp_models.dart';
import '../../providers/auth_providers.dart';
import '../../providers/mcp_profile_providers.dart';
import '../../providers/mcp_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/scribe/scribe_editor.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The MCP developer profile detail page.
class DeveloperProfileDetailPage extends ConsumerStatefulWidget {
  /// Profile ID from the route parameter.
  final String profileId;

  /// Creates a [DeveloperProfileDetailPage].
  const DeveloperProfileDetailPage({super.key, required this.profileId});

  @override
  ConsumerState<DeveloperProfileDetailPage> createState() =>
      _DeveloperProfileDetailPageState();
}

class _DeveloperProfileDetailPageState
    extends ConsumerState<DeveloperProfileDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  String? _selectedTimezone;
  bool _isActive = true;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _populateFields(DeveloperProfile profile) {
    _nameController.text =
        profile.displayName ?? profile.userDisplayName ?? '';
    _bioController.text = profile.bio ?? '';
    _selectedTimezone = profile.timezone;
    _isActive = profile.isActive ?? true;
  }

  Future<void> _saveProfile(DeveloperProfile profile) async {
    final api = ref.read(mcpApiProvider);
    await api.updateProfile(widget.profileId, {
      'displayName': _nameController.text,
      'bio': _bioController.text,
      if (_selectedTimezone != null) 'timezone': _selectedTimezone,
    });
    ref.invalidate(profileListProvider);
    ref.invalidate(profileDetailProvider(widget.profileId));
    if (mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileDetailProvider(widget.profileId));
    final currentUser = ref.watch(currentUserProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (e, _) => ErrorPanel.fromException(e, onRetry: () {
        ref.invalidate(profileDetailProvider(widget.profileId));
      }),
      data: (profile) {
        if (profile == null) {
          return const EmptyState(
            icon: Icons.person_off_outlined,
            title: 'Profile not found',
            subtitle: 'This developer profile does not exist.',
          );
        }

        final isMyProfile = currentUser?.id == profile.userId;

        if (!_editing) {
          _populateFields(profile);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                profile: profile,
                isMyProfile: isMyProfile,
              ),
              const SizedBox(height: 20),
              // Profile info section
              _ProfileInfoSection(
                profile: profile,
                editing: _editing,
                nameController: _nameController,
                bioController: _bioController,
                selectedTimezone: _selectedTimezone,
                isActive: _isActive,
                onTimezoneChanged: (tz) =>
                    setState(() => _selectedTimezone = tz),
                onActiveChanged: (v) => setState(() => _isActive = v),
                onEdit: () {
                  _populateFields(profile);
                  setState(() => _editing = true);
                },
                onSave: () => _saveProfile(profile),
                onCancel: () => setState(() => _editing = false),
              ),
              const SizedBox(height: 20),
              // Preferences editor
              _PreferencesSection(profile: profile),
              const SizedBox(height: 20),
              // Session history
              _SessionHistorySection(profileId: widget.profileId),
              const SizedBox(height: 20),
              // Token section
              _TokenSection(profileId: widget.profileId),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DeveloperProfile profile;
  final bool isMyProfile;

  const _Header({required this.profile, required this.isMyProfile});

  @override
  Widget build(BuildContext context) {
    final name =
        profile.displayName ?? profile.userDisplayName ?? 'Unknown';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/mcp/profiles'),
              child: const Text(
                'Profiles',
                style:
                    TextStyle(fontSize: 12, color: CodeOpsColors.primary),
              ),
            ),
            const Text(' / ',
                style: TextStyle(
                    fontSize: 12, color: CodeOpsColors.textTertiary)),
            Text(
              name,
              style: const TextStyle(
                  fontSize: 12, color: CodeOpsColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CodeOpsColors.textPrimary,
              ),
            ),
            if (isMyProfile) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CodeOpsColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Info Section
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileInfoSection extends StatelessWidget {
  final DeveloperProfile profile;
  final bool editing;
  final TextEditingController nameController;
  final TextEditingController bioController;
  final String? selectedTimezone;
  final bool isActive;
  final ValueChanged<String?> onTimezoneChanged;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ProfileInfoSection({
    required this.profile,
    required this.editing,
    required this.nameController,
    required this.bioController,
    required this.selectedTimezone,
    required this.isActive,
    required this.onTimezoneChanged,
    required this.onActiveChanged,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!editing)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                      foregroundColor: CodeOpsColors.primary),
                )
              else ...[
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CodeOpsColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (editing) ...[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedTimezone,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(
                  fontSize: 13, color: CodeOpsColors.textPrimary),
              dropdownColor: CodeOpsColors.surface,
              items: const [
                DropdownMenuItem(
                    value: 'America/New_York',
                    child: Text('America/New_York')),
                DropdownMenuItem(
                    value: 'America/Chicago',
                    child: Text('America/Chicago')),
                DropdownMenuItem(
                    value: 'America/Denver',
                    child: Text('America/Denver')),
                DropdownMenuItem(
                    value: 'America/Los_Angeles',
                    child: Text('America/Los_Angeles')),
                DropdownMenuItem(
                    value: 'Europe/London',
                    child: Text('Europe/London')),
                DropdownMenuItem(
                    value: 'Europe/Berlin',
                    child: Text('Europe/Berlin')),
                DropdownMenuItem(
                    value: 'Asia/Tokyo', child: Text('Asia/Tokyo')),
                DropdownMenuItem(value: 'UTC', child: Text('UTC')),
              ],
              onChanged: onTimezoneChanged,
            ),
          ] else ...[
            _InfoRow(
              label: 'Display Name',
              value: profile.displayName ??
                  profile.userDisplayName ??
                  'Not set',
            ),
            _InfoRow(label: 'Bio', value: profile.bio ?? 'Not set'),
            _InfoRow(
                label: 'Timezone', value: profile.timezone ?? 'Not set'),
            _InfoRow(
              label: 'Environment',
              value: profile.defaultEnvironment?.displayName ?? 'Not set',
            ),
            _InfoRow(
              label: 'Status',
              value: (profile.isActive ?? true) ? 'Active' : 'Inactive',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preferences Section
// ─────────────────────────────────────────────────────────────────────────────

class _PreferencesSection extends StatelessWidget {
  final DeveloperProfile profile;

  const _PreferencesSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final prefsJson = profile.preferencesJson;
    String formatted;
    try {
      if (prefsJson != null && prefsJson.isNotEmpty) {
        final decoded = jsonDecode(prefsJson);
        formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        formatted = '{\n  \n}';
      }
    } catch (_) {
      formatted = prefsJson ?? '{}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IDE Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'JSON configuration for AI agent behavior preferences',
            style: TextStyle(
                fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ScribeEditor(
              content: formatted,
              language: 'json',
              readOnly: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session History Section
// ─────────────────────────────────────────────────────────────────────────────

class _SessionHistorySection extends ConsumerWidget {
  final String profileId;

  const _SessionHistorySection({required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(profileSessionsProvider(profileId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          sessionsAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: CodeOpsColors.primary),
              ),
            ),
            error: (_, __) => const Text(
              'Failed to load sessions',
              style: TextStyle(
                  fontSize: 12, color: CodeOpsColors.textTertiary),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No sessions yet',
                    style: TextStyle(
                        fontSize: 12, color: CodeOpsColors.textTertiary),
                  ),
                );
              }
              return Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: CodeOpsColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                            width: 80,
                            child: Text('Status',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: CodeOpsColors.textTertiary))),
                        Expanded(
                            child: Text('Project',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: CodeOpsColors.textTertiary))),
                        SizedBox(
                            width: 80,
                            child: Text('Tools',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: CodeOpsColors.textTertiary))),
                        SizedBox(
                            width: 120,
                            child: Text('Started',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: CodeOpsColors.textTertiary))),
                      ],
                    ),
                  ),
                  for (final session in sessions)
                    _SessionRow(session: session),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final McpSession session;

  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (session.id != null) {
          context.go('/mcp/sessions/${session.id}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(session.status)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  session.status?.displayName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _statusColor(session.status),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                session.projectName ?? 'Unknown',
                style: const TextStyle(
                    fontSize: 12, color: CodeOpsColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '${session.totalToolCalls ?? 0}',
                style: const TextStyle(
                    fontSize: 12, color: CodeOpsColors.textSecondary),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                _formatDate(session.startedAt),
                style: const TextStyle(
                    fontSize: 11, color: CodeOpsColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(SessionStatus? status) => switch (status) {
        SessionStatus.active => CodeOpsColors.primary,
        SessionStatus.completed => CodeOpsColors.success,
        SessionStatus.failed => CodeOpsColors.error,
        SessionStatus.cancelled => CodeOpsColors.warning,
        _ => CodeOpsColors.textTertiary,
      };

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final d = date.toLocal();
    return '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Token Section
// ─────────────────────────────────────────────────────────────────────────────

class _TokenSection extends StatelessWidget {
  final String profileId;

  const _TokenSection({required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.key, size: 20, color: CodeOpsColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Tokens',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                Text(
                  'Manage MCP authentication tokens for AI agent connections',
                  style: TextStyle(
                      fontSize: 11, color: CodeOpsColors.textTertiary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                context.go('/mcp/profiles/$profileId/tokens'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Manage Tokens'),
          ),
        ],
      ),
    );
  }
}
