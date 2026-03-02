/// Logger dashboards list page.
///
/// Displays three tabs: **My Dashboards**, **Shared**, and **Templates**.
/// Each tab shows a list of [DashboardResponse] cards with name,
/// description, widget count, last modified, and actions (open, duplicate,
/// share, delete). Toolbar provides [+ New Dashboard] and
/// [+ From Template] buttons.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../services/cloud/logger_api.dart';
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The dashboards list page with My / Shared / Templates tabs.
class LogDashboardsPage extends ConsumerStatefulWidget {
  /// Creates a [LogDashboardsPage].
  const LogDashboardsPage({super.key});

  @override
  ConsumerState<LogDashboardsPage> createState() => _LogDashboardsPageState();
}

class _LogDashboardsPageState extends ConsumerState<LogDashboardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return Row(
        children: [
          const LoggerSidebar(),
          const VerticalDivider(width: 1, color: CodeOpsColors.border),
          const Expanded(
            child: EmptyState(
              icon: Icons.group_off,
              title: 'No team selected',
              subtitle: 'Select a team to view dashboards.',
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              _buildToolbar(teamId),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DashboardTab(
                      provider: loggerMyDashboardsProvider,
                      emptyMessage: 'No dashboards yet',
                      ref: ref,
                      teamId: teamId,
                    ),
                    _DashboardTab(
                      provider: loggerSharedDashboardsProvider,
                      emptyMessage: 'No shared dashboards',
                      ref: ref,
                      teamId: teamId,
                    ),
                    _DashboardTab(
                      provider: loggerDashboardTemplatesProvider,
                      emptyMessage: 'No templates available',
                      ref: ref,
                      teamId: teamId,
                      isTemplateTab: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the top toolbar with title and action buttons.
  Widget _buildToolbar(String teamId) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.grid_view_outlined,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Dashboards',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Dashboard'),
            onPressed: () => _showCreateDialog(teamId),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: const Text('From Template'),
            onPressed: () => _showFromTemplateDialog(teamId),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(loggerMyDashboardsProvider);
              ref.invalidate(loggerSharedDashboardsProvider);
              ref.invalidate(loggerDashboardTemplatesProvider);
            },
          ),
        ],
      ),
    );
  }

  /// Builds the tab bar.
  Widget _buildTabBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: CodeOpsColors.primary,
        unselectedLabelColor: CodeOpsColors.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        indicatorColor: CodeOpsColors.primary,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'My Dashboards'),
          Tab(text: 'Shared'),
          Tab(text: 'Templates'),
        ],
      ),
    );
  }

  /// Shows the create-dashboard dialog.
  Future<void> _showCreateDialog(String teamId) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _CreateDashboardDialog(),
    );
    if (result == null || !mounted) return;

    final api = ref.read(loggerApiProvider);
    await api.createDashboard(
      teamId,
      name: result['name']!,
      description:
          result['description']?.isEmpty ?? true ? null : result['description'],
    );
    ref.invalidate(loggerMyDashboardsProvider);
  }

  /// Shows the from-template dialog.
  Future<void> _showFromTemplateDialog(String teamId) async {
    final templates = ref.read(loggerDashboardTemplatesProvider).valueOrNull;
    if (templates == null || templates.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No templates available')),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _FromTemplateDialog(templates: templates),
    );
    if (result == null || !mounted) return;

    final api = ref.read(loggerApiProvider);
    await api.createDashboardFromTemplate(
      teamId,
      name: result['name']!,
      templateId: result['templateId']!,
    );
    ref.invalidate(loggerMyDashboardsProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Tab
// ─────────────────────────────────────────────────────────────────────────────

/// A single tab showing a list of dashboard cards.
class _DashboardTab extends StatelessWidget {
  final FutureProvider<List<DashboardResponse>> provider;
  final String emptyMessage;
  final WidgetRef ref;
  final String teamId;
  final bool isTemplateTab;

  const _DashboardTab({
    required this.provider,
    required this.emptyMessage,
    required this.ref,
    required this.teamId,
    this.isTemplateTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(provider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorPanel(
              title: 'Failed to load dashboards',
              message: err.toString(),
            ),
      data: (dashboards) {
        if (dashboards.isEmpty) {
          return EmptyState(
            icon: Icons.grid_view_outlined,
            title: emptyMessage,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dashboards.length,
          itemBuilder: (_, i) => _DashboardCard(
            dashboard: dashboards[i],
            ref: ref,
            teamId: teamId,
            isTemplate: isTemplateTab,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Card
// ─────────────────────────────────────────────────────────────────────────────

/// A card displaying a single dashboard summary.
class _DashboardCard extends StatelessWidget {
  final DashboardResponse dashboard;
  final WidgetRef ref;
  final String teamId;
  final bool isTemplate;

  const _DashboardCard({
    required this.dashboard,
    required this.ref,
    required this.teamId,
    this.isTemplate = false,
  });

  @override
  Widget build(BuildContext context) {
    final updated = dashboard.updatedAt ?? dashboard.createdAt;
    final dateText = updated != null
        ? DateFormat('MMM d, yyyy HH:mm').format(updated)
        : 'Unknown';

    return Card(
      color: CodeOpsColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CodeOpsColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/logger/dashboards/${dashboard.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboard.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                    if (dashboard.description != null &&
                        dashboard.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dashboard.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CodeOpsColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.widgets_outlined,
                          label: '${dashboard.widgets.length} widgets',
                        ),
                        const SizedBox(width: 12),
                        _InfoChip(
                          icon: Icons.schedule,
                          label: dateText,
                        ),
                        if (dashboard.isShared) ...[
                          const SizedBox(width: 12),
                          const _InfoChip(
                            icon: Icons.people_outline,
                            label: 'Shared',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    color: CodeOpsColors.textSecondary,
                    tooltip: 'Open',
                    onPressed: () =>
                        context.go('/logger/dashboards/${dashboard.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    color: CodeOpsColors.textSecondary,
                    tooltip: 'Duplicate',
                    onPressed: () => _duplicate(context),
                  ),
                  if (!isTemplate)
                    IconButton(
                      icon: Icon(
                        dashboard.isShared
                            ? Icons.lock_outline
                            : Icons.share_outlined,
                        size: 18,
                      ),
                      color: CodeOpsColors.textSecondary,
                      tooltip: dashboard.isShared ? 'Make Private' : 'Share',
                      onPressed: () => _toggleShare(context),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: CodeOpsColors.error,
                    tooltip: 'Delete',
                    onPressed: () => _delete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _duplicate(BuildContext context) async {
    final api = ref.read(loggerApiProvider);
    await api.duplicateDashboard(
      teamId,
      dashboard.id,
      name: '${dashboard.name} (Copy)',
    );
    ref.invalidate(loggerMyDashboardsProvider);
  }

  Future<void> _toggleShare(BuildContext context) async {
    final api = ref.read(loggerApiProvider);
    await api.updateDashboard(dashboard.id, isShared: !dashboard.isShared);
    ref.invalidate(loggerMyDashboardsProvider);
    ref.invalidate(loggerSharedDashboardsProvider);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Dashboard',
            style: TextStyle(color: CodeOpsColors.textPrimary)),
        content: Text(
          'Delete "${dashboard.name}"? This cannot be undone.',
          style: const TextStyle(color: CodeOpsColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = ref.read(loggerApiProvider);
    await api.deleteDashboard(dashboard.id);
    ref.invalidate(loggerMyDashboardsProvider);
    ref.invalidate(loggerSharedDashboardsProvider);
    ref.invalidate(loggerDashboardTemplatesProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Chip
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: CodeOpsColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Dashboard Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CreateDashboardDialog extends StatefulWidget {
  const _CreateDashboardDialog();

  @override
  State<_CreateDashboardDialog> createState() => _CreateDashboardDialogState();
}

class _CreateDashboardDialogState extends State<_CreateDashboardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text(
        'New Dashboard',
        style: TextStyle(color: CodeOpsColors.textPrimary),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Dashboard Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'description': _descController.text.trim(),
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// From Template Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _FromTemplateDialog extends StatefulWidget {
  final List<DashboardResponse> templates;
  const _FromTemplateDialog({required this.templates});

  @override
  State<_FromTemplateDialog> createState() => _FromTemplateDialogState();
}

class _FromTemplateDialogState extends State<_FromTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    if (widget.templates.isNotEmpty) {
      _selectedTemplateId = widget.templates.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text(
        'Create From Template',
        style: TextStyle(color: CodeOpsColors.textPrimary),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedTemplateId,
                dropdownColor: CodeOpsColors.surface,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Template'),
                items: widget.templates
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTemplateId = v),
                validator: (v) => v == null ? 'Select a template' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: CodeOpsColors.textPrimary),
                decoration:
                    const InputDecoration(labelText: 'New Dashboard Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'templateId': _selectedTemplateId!,
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
