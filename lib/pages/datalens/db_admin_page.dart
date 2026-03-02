/// Database administration page for the DataLens module.
///
/// Provides a 5-tab interface (Sessions, Table Stats, Locks, Indexes,
/// Server) with a connection selector and refresh toolbar. Each tab
/// delegates to a dedicated admin panel widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/datalens/admin/active_sessions_panel.dart';
import '../../widgets/datalens/admin/index_usage_panel.dart';
import '../../widgets/datalens/admin/lock_monitor_panel.dart';
import '../../widgets/datalens/admin/server_info_panel.dart';
import '../../widgets/datalens/admin/table_stats_panel.dart';

/// Full-screen database administration page.
///
/// Reads the selected connection and schema from providers. If no
/// connection is selected, prompts the user to pick one. Otherwise
/// renders a tab bar with five admin panels.
class DbAdminPage extends ConsumerStatefulWidget {
  /// Optional pre-selected connection ID.
  final String? connectionId;

  /// Creates a [DbAdminPage].
  const DbAdminPage({super.key, this.connectionId});

  @override
  ConsumerState<DbAdminPage> createState() => _DbAdminPageState();
}

class _DbAdminPageState extends ConsumerState<DbAdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _connectionId;
  String _schema = 'public';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _connectionId =
        widget.connectionId ?? ref.read(selectedConnectionIdProvider);
    final selectedSchema = ref.read(selectedSchemaProvider);
    if (selectedSchema != null) _schema = selectedSchema;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CodeOpsColors.background,
      body: Column(
        children: [
          _buildTitleBar(),
          const Divider(height: 1, color: CodeOpsColors.border),
          _buildTabBar(),
          const Divider(height: 1, color: CodeOpsColors.border),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            color: CodeOpsColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          const Icon(Icons.admin_panel_settings,
              size: 18, color: CodeOpsColors.primary),
          const SizedBox(width: 8),
          const Text(
            'Database Administration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          _buildConnectionSelector(),
          const SizedBox(width: 12),
          _buildSchemaSelector(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildConnectionSelector() {
    final connectionsAsync = ref.watch(datalensConnectionsProvider);

    return connectionsAsync.when(
      loading: () => const SizedBox(
        width: 150,
        child: Text(
          'Loading...',
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
      ),
      error: (e, _) => Text(
        'Error: $e',
        style: const TextStyle(fontSize: 12, color: CodeOpsColors.error),
      ),
      data: (connections) => _connectionDropdown(connections),
    );
  }

  Widget _connectionDropdown(List<DatabaseConnection> connections) {
    return DropdownButton<String>(
      value: _connectionId,
      dropdownColor: CodeOpsColors.surfaceVariant,
      style: const TextStyle(fontSize: 12, color: CodeOpsColors.textPrimary),
      underline: const SizedBox.shrink(),
      hint: const Text(
        'Select connection',
        style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
      ),
      items: connections
          .map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name ?? c.id ?? ''),
              ))
          .toList(),
      onChanged: (v) => setState(() => _connectionId = v),
    );
  }

  Widget _buildSchemaSelector() {
    if (_connectionId == null) return const SizedBox.shrink();

    final schemasAsync = ref.watch(datalensSchemasProvider);
    return schemasAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schemas) {
        if (schemas.isEmpty) return const SizedBox.shrink();
        return DropdownButton<String>(
          value: schemas.any((s) => s.name == _schema)
              ? _schema
              : schemas.first.name,
          dropdownColor: CodeOpsColors.surfaceVariant,
          style:
              const TextStyle(fontSize: 12, color: CodeOpsColors.textPrimary),
          underline: const SizedBox.shrink(),
          items: schemas
              .map((s) => DropdownMenuItem(
                    value: s.name,
                    child: Text(s.name ?? ''),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _schema = v);
          },
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: CodeOpsColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: CodeOpsColors.primary,
        unselectedLabelColor: CodeOpsColors.textTertiary,
        indicatorColor: CodeOpsColors.primary,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(
            icon: Icon(Icons.people, size: 16),
            text: 'Sessions',
          ),
          Tab(
            icon: Icon(Icons.table_chart, size: 16),
            text: 'Table Stats',
          ),
          Tab(
            icon: Icon(Icons.lock, size: 16),
            text: 'Locks',
          ),
          Tab(
            icon: Icon(Icons.speed, size: 16),
            text: 'Indexes',
          ),
          Tab(
            icon: Icon(Icons.dns, size: 16),
            text: 'Server',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_connectionId == null) {
      return const Center(
        child: Text(
          'Select a connection to view administration data',
          style: TextStyle(fontSize: 14, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        ActiveSessionsPanel(connectionId: _connectionId!),
        TableStatsPanel(connectionId: _connectionId!, schema: _schema),
        LockMonitorPanel(connectionId: _connectionId!),
        IndexUsagePanel(connectionId: _connectionId!, schema: _schema),
        ServerInfoPanel(connectionId: _connectionId!),
      ],
    );
  }
}
