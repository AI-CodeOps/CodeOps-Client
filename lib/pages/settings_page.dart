/// Settings page with sidebar section tabs and content panels.
///
/// Sections: Profile, Team, Integrations, Agent Config, Notifications,
/// Appearance, About.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/enums.dart';
import '../providers/agent_config_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/github_providers.dart';
import '../providers/health_providers.dart';
import '../providers/jira_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/team_providers.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../widgets/settings/agents_tab.dart';
import '../widgets/settings/api_key_tab.dart';
import '../widgets/settings/general_settings_tab.dart';

/// The application settings page.
class SettingsPage extends ConsumerStatefulWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _sections = [
    (icon: Icons.person_outline, label: 'Profile'),
    (icon: Icons.group_outlined, label: 'Team'),
    (icon: Icons.extension_outlined, label: 'Integrations'),
    (icon: Icons.smart_toy_outlined, label: 'Agent Config'),
    (icon: Icons.notifications_none, label: 'Notifications'),
    (icon: Icons.palette_outlined, label: 'Appearance'),
    (icon: Icons.info_outline, label: 'About'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(settingsSectionProvider);

    return Row(
      children: [
        // Left sidebar tabs
        Container(
          width: 200,
          color: CodeOpsColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final section = _sections[index];
              final active = index == selectedIndex;
              return ListTile(
                dense: true,
                leading: Icon(
                  section.icon,
                  size: 18,
                  color: active
                      ? CodeOpsColors.primary
                      : CodeOpsColors.textSecondary,
                ),
                title: Text(
                  section.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: active
                        ? CodeOpsColors.textPrimary
                        : CodeOpsColors.textSecondary,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
                selected: active,
                selectedTileColor:
                    CodeOpsColors.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onTap: () =>
                    ref.read(settingsSectionProvider.notifier).state = index,
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        // Right content panel
        Expanded(
          child: selectedIndex == 3
              // Agent Config manages its own scrolling (master-detail).
              ? _buildSection(selectedIndex)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _buildSection(selectedIndex),
                ),
        ),
      ],
    );
  }

  Widget _buildSection(int index) {
    return switch (index) {
      0 => const _ProfileSection(),
      1 => const _TeamSection(),
      2 => const _IntegrationsSection(),
      3 => const _AgentConfigSection(),
      4 => const _NotificationsSection(),
      5 => const _AppearanceSection(),
      6 => const _AboutSection(),
      _ => const SizedBox.shrink(),
    };
  }
}

// ---------------------------------------------------------------------------
// Profile Section
// ---------------------------------------------------------------------------

class _ProfileSection extends ConsumerStatefulWidget {
  const _ProfileSection();

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  String? _pwError;
  String? _pwSuccess;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController.text = user?.displayName ?? '';
    _avatarController.text = user?.avatarUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentPwController.text;
    final newPw = _newPwController.text;
    final confirm = _confirmPwController.text;

    if (current.isEmpty || newPw.isEmpty) {
      setState(() => _pwError = 'All fields are required.');
      return;
    }
    if (newPw != confirm) {
      setState(() => _pwError = 'Passwords do not match.');
      return;
    }
    if (newPw.length < 8) {
      setState(() => _pwError = 'Password must be at least 8 characters.');
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      await authService.changePassword(current, newPw);
      setState(() {
        _pwError = null;
        _pwSuccess = 'Password changed successfully.';
      });
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
    } catch (e) {
      setState(() {
        _pwError = 'Failed to change password.';
        _pwSuccess = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        _FieldRow(label: 'Display Name', child: TextField(controller: _nameController)),
        const SizedBox(height: 16),
        _FieldRow(
          label: 'Email',
          child: TextField(
            controller: TextEditingController(text: user?.email ?? ''),
            readOnly: true,
            style: const TextStyle(color: CodeOpsColors.textTertiary),
          ),
        ),
        const SizedBox(height: 16),
        _FieldRow(label: 'Avatar URL', child: TextField(controller: _avatarController)),
        const SizedBox(height: 32),
        Text('Change Password', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 16),
        SizedBox(
          width: 400,
          child: Column(
            children: [
              TextField(
                controller: _currentPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
              if (_pwError != null) ...[
                const SizedBox(height: 8),
                Text(_pwError!, style: const TextStyle(color: CodeOpsColors.error, fontSize: 12)),
              ],
              if (_pwSuccess != null) ...[
                const SizedBox(height: 8),
                Text(_pwSuccess!, style: const TextStyle(color: CodeOpsColors.success, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  child: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Team Section
// ---------------------------------------------------------------------------

class _TeamSection extends ConsumerWidget {
  const _TeamSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(selectedTeamProvider);
    final membersAsync = ref.watch(teamMembersProvider);
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Team', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        teamAsync.when(
          loading: () => const CircularProgressIndicator(strokeWidth: 2),
          error: (e, _) => Text('Error loading team: $e'),
          data: (team) {
            if (team == null) {
              return const Text(
                'No team selected.',
                style: TextStyle(color: CodeOpsColors.textTertiary),
              );
            }

            // Check if user is owner or admin
            final isEditable = membersAsync.whenOrNull(
                  data: (members) {
                    final me = members.where((m) => m.userId == user?.id).firstOrNull;
                    return me != null &&
                        (me.role == TeamRole.owner || me.role == TeamRole.admin);
                  },
                ) ??
                false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldRow(
                  label: 'Team Name',
                  child: TextField(
                    controller: TextEditingController(text: team.name),
                    readOnly: !isEditable,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldRow(
                  label: 'Description',
                  child: TextField(
                    controller: TextEditingController(text: team.description ?? ''),
                    readOnly: !isEditable,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldRow(
                  label: 'Teams Webhook URL',
                  child: TextField(
                    controller: TextEditingController(text: team.teamsWebhookUrl ?? ''),
                    readOnly: !isEditable,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Members', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                membersAsync.when(
                  loading: () => const CircularProgressIndicator(strokeWidth: 2),
                  error: (e, _) => Text('Error: $e'),
                  data: (members) => Text(
                    '${members.length} member${members.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: CodeOpsColors.textSecondary),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Integrations Section
// ---------------------------------------------------------------------------

class _IntegrationsSection extends ConsumerWidget {
  const _IntegrationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ghAsync = ref.watch(githubConnectionsProvider);
    final jiraAsync = ref.watch(jiraConnectionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Integrations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        Text('GitHub Connections', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ghAsync.when(
          loading: () => const CircularProgressIndicator(strokeWidth: 2),
          error: (e, _) => Text('Error: $e'),
          data: (connections) {
            if (connections.isEmpty) {
              return const Text(
                'No GitHub connections.',
                style: TextStyle(color: CodeOpsColors.textTertiary),
              );
            }
            return Column(
              children: connections.map((c) => ListTile(
                dense: true,
                leading: const Icon(Icons.code, size: 18),
                title: Text(c.name),
                subtitle: Text(c.githubUsername ?? '', style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  c.isActive == true ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: c.isActive == true ? CodeOpsColors.success : CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Jira Connections', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        jiraAsync.when(
          loading: () => const CircularProgressIndicator(strokeWidth: 2),
          error: (e, _) => Text('Error: $e'),
          data: (connections) {
            if (connections.isEmpty) {
              return const Text(
                'No Jira connections.',
                style: TextStyle(color: CodeOpsColors.textTertiary),
              );
            }
            return Column(
              children: connections.map((c) => ListTile(
                dense: true,
                leading: const Icon(Icons.task, size: 18),
                title: Text(c.name),
                subtitle: Text(c.instanceUrl, style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  c.isActive == true ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: c.isActive == true ? CodeOpsColors.success : CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Agent Config Section
// ---------------------------------------------------------------------------

class _AgentConfigSection extends ConsumerWidget {
  const _AgentConfigSection();

  static const _tabs = ['API Key', 'Agents', 'General'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(agentConfigTabProvider);

    return Column(
      children: [
        // Tab bar.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
          ),
          child: Row(
            children: [
              Text('Agent Configuration',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 24),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final active = i == selectedTab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: TextButton(
                          onPressed: () =>
                              ref.read(agentConfigTabProvider.notifier).state =
                                  i,
                          style: TextButton.styleFrom(
                            backgroundColor: active
                                ? CodeOpsColors.primary
                                    .withValues(alpha: 0.15)
                                : null,
                            foregroundColor: active
                                ? CodeOpsColors.primary
                                : CodeOpsColors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(_tabs[i],
                              style: const TextStyle(fontSize: 13)),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tab content.
        Expanded(
          child: switch (selectedTab) {
            0 => const ApiKeyTab(),
            1 => const AgentsTab(),
            2 => const GeneralSettingsTab(),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications Section
// ---------------------------------------------------------------------------

class _NotificationsSection extends ConsumerStatefulWidget {
  const _NotificationsSection();

  @override
  ConsumerState<_NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<_NotificationsSection> {
  static const _eventTypes = [
    'job_completed',
    'critical_finding',
    'health_threshold',
    'task_assigned',
    'team_invitation',
    'rca_posted',
    'weekly_digest',
    'cve_detected',
  ];

  // Local-only state since no API exists
  late final Map<String, bool> _inApp;
  late final Map<String, bool> _email;

  @override
  void initState() {
    super.initState();
    _inApp = {for (final t in _eventTypes) t: true};
    _email = {for (final t in _eventTypes) t: false};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Preferences are stored locally.',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 24),
        // Header row
        Row(
          children: [
            const Expanded(
              flex: 3,
              child: Text('Event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            SizedBox(
              width: 80,
              child: const Text('In-App', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
            ),
            SizedBox(
              width: 80,
              child: const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
            ),
          ],
        ),
        const Divider(),
        ..._eventTypes.map((type) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _formatEventType(type),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Center(
                    child: Switch(
                      value: _inApp[type]!,
                      onChanged: (v) => setState(() => _inApp[type] = v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Center(
                    child: Switch(
                      value: _email[type]!,
                      onChanged: (v) => setState(() => _email[type] = v),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static String _formatEventType(String type) {
    return type.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}

// ---------------------------------------------------------------------------
// Appearance Section
// ---------------------------------------------------------------------------

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final density = ref.watch(fontDensityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        const Text(
          'CodeOps uses a dark theme by default.',
          style: TextStyle(color: CodeOpsColors.textTertiary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text('Sidebar collapsed by default', style: TextStyle(fontSize: 13)),
          value: collapsed,
          onChanged: (v) =>
              ref.read(sidebarCollapsedProvider.notifier).state = v,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        const Text('Font Density', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Compact')),
            ButtonSegment(value: 1, label: Text('Normal')),
            ButtonSegment(value: 2, label: Text('Comfortable')),
          ],
          selected: {density},
          onSelectionChanged: (v) =>
              ref.read(fontDensityProvider.notifier).state = v.first,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Compact mode', style: TextStyle(fontSize: 13)),
          subtitle: const Text(
            'Reduces padding for denser layouts',
            style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
          value: ref.watch(compactModeProvider),
          onChanged: (v) =>
              ref.read(compactModeProvider.notifier).state = v,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// About Section
// ---------------------------------------------------------------------------

class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(teamMetricsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        _InfoRow('App Version', AppConstants.appVersion),
        _InfoRow('Server URL', AppConstants.apiBaseUrl),
        _InfoRow(
          'Server Health',
          metricsAsync.when(
            loading: () => 'Checking...',
            error: (_, __) => 'Unreachable',
            data: (_) => 'Connected',
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Automatic updates', style: TextStyle(fontSize: 13)),
          subtitle: const Text(
            'Check for updates on startup',
            style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
          ),
          value: ref.watch(autoUpdateProvider),
          onChanged: (v) =>
              ref.read(autoUpdateProvider.notifier).state = v,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Documentation'),
              onPressed: () => launchUrl(Uri.parse('https://docs.codeops.dev')),
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Release Notes'),
              onPressed: () => launchUrl(Uri.parse('https://releases.codeops.dev')),
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Report Issue'),
              onPressed: () => launchUrl(Uri.parse('https://github.com/codeops-dev/codeops-client/issues')),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: CodeOpsColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
