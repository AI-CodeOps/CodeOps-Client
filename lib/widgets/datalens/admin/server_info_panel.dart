/// Server info panel for the DataLens database admin module.
///
/// Displays server version, uptime, connection gauge, timezone, database
/// size, and a searchable / filterable table of server configuration
/// parameters.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/datalens_admin_models.dart';
import '../../../providers/datalens_providers.dart';
import '../../../theme/colors.dart';

/// Panel displaying server information and configuration parameters.
///
/// Features: server overview cards (version, uptime, connections, size),
/// and a searchable parameters table with category filtering.
class ServerInfoPanel extends ConsumerStatefulWidget {
  /// Connection ID to query server info for.
  final String connectionId;

  /// Creates a [ServerInfoPanel].
  const ServerInfoPanel({super.key, required this.connectionId});

  @override
  ConsumerState<ServerInfoPanel> createState() => _ServerInfoPanelState();
}

class _ServerInfoPanelState extends ConsumerState<ServerInfoPanel> {
  ServerInfo? _serverInfo;
  List<ServerParameter> _parameters = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _loadServerInfo();
  }

  @override
  void didUpdateWidget(covariant ServerInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionId != widget.connectionId) {
      _loadServerInfo();
    }
  }

  Future<void> _loadServerInfo() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(dbAdminServiceProvider);
      final info = await service.getServerInfo(widget.connectionId);
      final params = await service.getServerParameters(widget.connectionId);
      if (mounted) {
        setState(() {
          _serverInfo = info;
          _parameters = params;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<ServerParameter> get _filteredParameters {
    var filtered = _parameters;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              (p.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    if (_categoryFilter != null) {
      filtered =
          filtered.where((p) => p.category == _categoryFilter).toList();
    }
    return filtered;
  }

  List<String> get _categories {
    final cats = _parameters
        .where((p) => p.category != null && p.category!.isNotEmpty)
        .map((p) => p.category!)
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _serverInfo == null) {
      return const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      );
    }
    if (_error != null && _serverInfo == null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 12, color: CodeOpsColors.error),
        ),
      );
    }

    return Column(
      children: [
        _buildOverview(),
        const Divider(height: 1, color: CodeOpsColors.border),
        _buildParametersToolbar(),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(child: _buildParametersTable()),
      ],
    );
  }

  Widget _buildOverview() {
    final info = _serverInfo;
    if (info == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          Expanded(child: _infoCard('Version', info.version, Icons.dns)),
          const SizedBox(width: 8),
          Expanded(
              child: _infoCard(
                  'Uptime', info.uptime ?? 'N/A', Icons.timer)),
          const SizedBox(width: 8),
          Expanded(child: _connectionGauge(info)),
          const SizedBox(width: 8),
          Expanded(
              child: _infoCard(
                  'Database Size', info.databaseSize ?? 'N/A', Icons.storage)),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CodeOpsColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: CodeOpsColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _connectionGauge(ServerInfo info) {
    final active = info.activeConnections ?? 0;
    final max = info.maxConnections ?? 100;
    final ratio = max > 0 ? active / max : 0.0;
    final gaugeColor = ratio > 0.8
        ? CodeOpsColors.error
        : ratio > 0.5
            ? CodeOpsColors.warning
            : CodeOpsColors.success;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CodeOpsColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, size: 14, color: CodeOpsColors.primary),
              const SizedBox(width: 4),
              const Text(
                'Connections',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ratio,
                    color: gaugeColor,
                    backgroundColor: CodeOpsColors.border,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$active / $max',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParametersToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          const Text(
            'Parameters',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            height: 28,
            child: TextField(
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search parameters...',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                prefixIcon: const Icon(Icons.search,
                    size: 14, color: CodeOpsColors.textTertiary),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: CodeOpsColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: CodeOpsColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: CodeOpsColors.primary),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 8),
          if (_categories.isNotEmpty)
            DropdownButton<String?>(
              value: _categoryFilter,
              dropdownColor: CodeOpsColors.surfaceVariant,
              style: const TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textPrimary,
              ),
              underline: const SizedBox.shrink(),
              hint: const Text(
                'All categories',
                style: TextStyle(fontSize: 11, color: CodeOpsColors.textTertiary),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All categories'),
                ),
                ..._categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c.length > 30 ? '${c.substring(0, 30)}...' : c,
                      ),
                    )),
              ],
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
          const Spacer(),
          Text(
            '${_filteredParameters.length} parameter${_filteredParameters.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 11,
              color: CodeOpsColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            color: CodeOpsColors.textSecondary,
            onPressed: _loadServerInfo,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildParametersTable() {
    final params = _filteredParameters;
    if (params.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'No parameters matching "$_searchQuery"'
              : 'No parameters available',
          style: const TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(CodeOpsColors.surface),
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textSecondary,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 11,
            color: CodeOpsColors.textPrimary,
          ),
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Value')),
            DataColumn(label: Text('Unit')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Source')),
          ],
          rows: params.map((p) => _buildParamRow(p)).toList(),
        ),
      ),
    );
  }

  DataRow _buildParamRow(ServerParameter param) {
    return DataRow(cells: [
      DataCell(Text(
        param.name,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
        ),
      )),
      DataCell(Text(
        param.value,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          color: CodeOpsColors.primary,
        ),
      )),
      DataCell(Text(param.unit ?? '')),
      DataCell(Text(
        _truncate(param.category ?? '', 30),
        style: const TextStyle(fontSize: 10),
      )),
      DataCell(
        SizedBox(
          width: 300,
          child: Text(
            param.description ?? '',
            style: const TextStyle(fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(Text(param.source ?? '')),
    ]);
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }
}
