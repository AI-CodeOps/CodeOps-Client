/// Dashboard detail page — viewer and editor for a single dashboard.
///
/// Displays a grid of widgets with a toolbar containing:
/// [Edit Layout] [Add Widget] [Auto-Refresh: Ns ▼] [Time Range ▼]
/// [Save] [Share]. In edit mode widgets show remove buttons and
/// resize handles.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../services/cloud/logger_api.dart';
import '../../theme/colors.dart';
import '../../widgets/logger/dashboard_grid.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/logger/widget_config_dialog.dart';
import '../../widgets/shared/error_panel.dart';

/// Detail page for viewing and editing a single dashboard.
class DashboardDetailPage extends ConsumerStatefulWidget {
  /// The dashboard ID from the route parameter.
  final String dashboardId;

  /// Creates a [DashboardDetailPage].
  const DashboardDetailPage({super.key, required this.dashboardId});

  @override
  ConsumerState<DashboardDetailPage> createState() =>
      _DashboardDetailPageState();
}

class _DashboardDetailPageState extends ConsumerState<DashboardDetailPage> {
  bool _isEditMode = false;
  Timer? _autoRefreshTimer;
  int _refreshInterval = 30;
  String _timeRange = '1h';

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: _refreshInterval),
      (_) => ref.invalidate(
        loggerDashboardDetailProvider(widget.dashboardId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync =
        ref.watch(loggerDashboardDetailProvider(widget.dashboardId));

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: dashAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorPanel(
                  title: 'Failed to load dashboard',
                  message: err.toString(),
                ),
            data: (dashboard) => Column(
              children: [
                _buildToolbar(dashboard),
                Expanded(
                  child: DashboardGrid(
                    widgets: dashboard.widgets,
                    isEditMode: _isEditMode,
                    onRefreshWidget: (_) => ref.invalidate(
                      loggerDashboardDetailProvider(widget.dashboardId),
                    ),
                    onConfigureWidget: (w) => _showConfigDialog(
                      dashboard,
                      existing: w,
                    ),
                    onRemoveWidget: (w) =>
                        _removeWidget(dashboard.id, w.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the dashboard toolbar.
  Widget _buildToolbar(DashboardResponse dashboard) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Back to dashboards',
            onPressed: () => context.go('/logger/dashboards'),
          ),
          const SizedBox(width: 4),
          // Dashboard name
          Expanded(
            child: Text(
              dashboard.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Edit Layout toggle
          _ToolbarButton(
            icon: _isEditMode ? Icons.lock_open : Icons.edit_outlined,
            label: _isEditMode ? 'Lock Layout' : 'Edit Layout',
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          ),
          const SizedBox(width: 4),

          // Add Widget
          _ToolbarButton(
            icon: Icons.add,
            label: 'Add Widget',
            onPressed: () => _showConfigDialog(dashboard),
          ),
          const SizedBox(width: 8),

          // Auto-Refresh dropdown
          _CompactDropdown(
            label: 'Auto-Refresh',
            value: '${_refreshInterval}s',
            items: const ['10s', '30s', '60s', '120s'],
            onChanged: (v) {
              final seconds = int.parse(v.replaceAll('s', ''));
              setState(() => _refreshInterval = seconds);
              _startAutoRefresh();
            },
          ),
          const SizedBox(width: 8),

          // Time Range dropdown
          _CompactDropdown(
            label: 'Time Range',
            value: _timeRange,
            items: const ['15m', '30m', '1h', '6h', '24h', '7d'],
            onChanged: (v) => setState(() => _timeRange = v),
          ),
          const SizedBox(width: 8),

          // Save
          _ToolbarButton(
            icon: Icons.save_outlined,
            label: 'Save',
            onPressed: () => _saveDashboard(dashboard),
          ),
          const SizedBox(width: 4),

          // Share toggle
          IconButton(
            icon: Icon(
              dashboard.isShared
                  ? Icons.people_outline
                  : Icons.share_outlined,
              size: 18,
            ),
            color: dashboard.isShared
                ? CodeOpsColors.primary
                : CodeOpsColors.textSecondary,
            tooltip: dashboard.isShared ? 'Shared' : 'Share',
            onPressed: () => _toggleShare(dashboard),
          ),
        ],
      ),
    );
  }

  /// Shows the add/edit widget configuration dialog.
  Future<void> _showConfigDialog(
    DashboardResponse dashboard, {
    DashboardWidgetResponse? existing,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => WidgetConfigDialog(
        initialTitle: existing?.title,
        initialType: existing?.widgetType,
        initialQueryJson: existing?.queryJson,
      ),
    );
    if (result == null || !mounted) return;

    final api = ref.read(loggerApiProvider);
    if (existing != null) {
      await api.updateDashboardWidget(
        dashboard.id,
        existing.id,
        title: result['title'] as String,
        widgetType: result['widgetType'] as WidgetType,
        queryJson: result['queryJson'] as String?,
      );
    } else {
      await api.createDashboardWidget(
        dashboard.id,
        title: result['title'] as String,
        widgetType: result['widgetType'] as WidgetType,
        queryJson: result['queryJson'] as String?,
        gridX: 0,
        gridY: dashboard.widgets.isEmpty
            ? 0
            : dashboard.widgets
                .map((w) => w.gridY + w.gridHeight)
                .reduce((a, b) => a > b ? a : b),
        gridWidth: 4,
        gridHeight: 2,
      );
    }
    ref.invalidate(loggerDashboardDetailProvider(widget.dashboardId));
  }

  /// Removes a widget from the dashboard.
  Future<void> _removeWidget(String dashboardId, String widgetId) async {
    final api = ref.read(loggerApiProvider);
    await api.deleteDashboardWidget(dashboardId, widgetId);
    ref.invalidate(loggerDashboardDetailProvider(widget.dashboardId));
  }

  /// Saves dashboard metadata.
  Future<void> _saveDashboard(DashboardResponse dashboard) async {
    final api = ref.read(loggerApiProvider);
    await api.updateDashboard(
      dashboard.id,
      refreshIntervalSeconds: _refreshInterval,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dashboard saved')),
    );
  }

  /// Toggles sharing.
  Future<void> _toggleShare(DashboardResponse dashboard) async {
    final api = ref.read(loggerApiProvider);
    await api.updateDashboard(dashboard.id, isShared: !dashboard.isShared);
    ref.invalidate(loggerDashboardDetailProvider(widget.dashboardId));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// A compact text button with icon for the toolbar.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

/// A compact dropdown for toolbar settings.
class _CompactDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _CompactDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textTertiary,
          ),
        ),
        DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          dropdownColor: CodeOpsColors.surface,
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textPrimary,
          ),
          underline: const SizedBox.shrink(),
          isDense: true,
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
