/// Visual query builder for structured log search.
///
/// Provides a row-based condition editor where each row has a
/// field selector, operator selector, and value input. Supports
/// AND/OR combiners between conditions and a raw DSL mode toggle.
library;

import 'package:flutter/material.dart';

import '../../models/logger_enums.dart';
import '../../theme/colors.dart';

/// A single query condition with field, operator, and value.
class QueryCondition {
  /// The log field to filter on.
  String field;

  /// The comparison operator.
  String operator;

  /// The value to compare against.
  String value;

  /// Creates a [QueryCondition].
  QueryCondition({
    this.field = 'message',
    this.operator = 'contains',
    this.value = '',
  });
}

/// Logical combiner between conditions.
enum QueryCombiner {
  /// All conditions must match.
  and,

  /// Any condition can match.
  or;

  /// Display label.
  String get label => switch (this) {
        QueryCombiner.and => 'AND',
        QueryCombiner.or => 'OR',
      };
}

/// Available search fields for the query builder.
const _searchFields = [
  'message',
  'level',
  'serviceName',
  'sourceName',
  'loggerName',
  'threadName',
  'correlationId',
  'exceptionClass',
  'exceptionMessage',
  'hostName',
  'ipAddress',
];

/// Available comparison operators.
const _operators = [
  'equals',
  'not_equals',
  'contains',
  'not_contains',
  'starts_with',
  'ends_with',
  'gt',
  'lt',
  'gte',
  'lte',
  'exists',
  'not_exists',
  'in',
  'regex',
];

/// A visual query builder with condition rows and DSL mode toggle.
///
/// Each condition row has a field dropdown, operator dropdown, and
/// value text input. The builder emits a structured query map
/// suitable for the `/logs/query` or `/logs/dsl` endpoints.
class QueryBuilder extends StatefulWidget {
  /// Callback invoked with the structured query when Search is pressed.
  final void Function(Map<String, dynamic> query) onSearch;

  /// Callback invoked with the raw DSL string when in DSL mode.
  final void Function(String dsl)? onSearchDsl;

  /// Callback invoked when the Save button is pressed.
  final VoidCallback? onSave;

  /// Optional initial conditions to populate (e.g. from a saved query).
  final List<QueryCondition>? initialConditions;

  /// Optional initial DSL text.
  final String? initialDsl;

  /// Creates a [QueryBuilder].
  const QueryBuilder({
    super.key,
    required this.onSearch,
    this.onSearchDsl,
    this.onSave,
    this.initialConditions,
    this.initialDsl,
  });

  @override
  State<QueryBuilder> createState() => QueryBuilderState();
}

/// State for [QueryBuilder], exposed for external access to conditions.
class QueryBuilderState extends State<QueryBuilder> {
  late List<QueryCondition> _conditions;
  QueryCombiner _combiner = QueryCombiner.and;
  bool _isRawMode = false;
  late TextEditingController _dslController;

  // Time range state.
  DateTime? _startTime;
  DateTime? _endTime;
  String _timeRangeLabel = 'Last 1 hour';

  /// Returns the current conditions list.
  List<QueryCondition> get conditions => _conditions;

  /// Returns the current combiner.
  QueryCombiner get combiner => _combiner;

  /// Returns whether raw DSL mode is active.
  bool get isRawMode => _isRawMode;

  /// Sets conditions externally (e.g. from a saved query).
  void setConditions(List<QueryCondition> conditions) {
    setState(() {
      _conditions = conditions;
      _isRawMode = false;
    });
  }

  /// Sets DSL text externally.
  void setDsl(String dsl) {
    setState(() {
      _dslController.text = dsl;
      _isRawMode = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _conditions = widget.initialConditions ??
        [QueryCondition()];
    _dslController = TextEditingController(
      text: widget.initialDsl ?? '',
    );
    // Default to last 1 hour.
    final now = DateTime.now().toUtc();
    _startTime = now.subtract(const Duration(hours: 1));
    _endTime = now;
  }

  @override
  void dispose() {
    _dslController.dispose();
    super.dispose();
  }

  /// Builds the structured query map from current conditions.
  Map<String, dynamic> _buildQuery() {
    final query = <String, dynamic>{};

    // Apply the first condition's simple fields directly.
    for (final cond in _conditions) {
      if (cond.value.isEmpty && cond.operator != 'exists' && cond.operator != 'not_exists') {
        continue;
      }
      // Map condition fields to query parameters.
      if (cond.field == 'level' && cond.operator == 'equals') {
        try {
          query['level'] = LogLevel.values
              .firstWhere((l) => l.toJson() == cond.value.toUpperCase())
              .toJson();
        } catch (_) {
          // Ignore invalid level values.
        }
      } else if (cond.field == 'serviceName' && cond.operator == 'equals') {
        query['serviceName'] = cond.value;
      } else if (cond.field == 'correlationId' && cond.operator == 'equals') {
        query['correlationId'] = cond.value;
      } else if (cond.field == 'loggerName' && cond.operator == 'equals') {
        query['loggerName'] = cond.value;
      } else if (cond.field == 'exceptionClass' && cond.operator == 'equals') {
        query['exceptionClass'] = cond.value;
      } else if (cond.field == 'hostName' && cond.operator == 'equals') {
        query['hostName'] = cond.value;
      } else {
        // For general text search, use the query field.
        query['query'] = cond.value;
      }
    }

    if (_startTime != null) {
      query['startTime'] = _startTime!.toIso8601String();
    }
    if (_endTime != null) {
      query['endTime'] = _endTime!.toIso8601String();
    }

    return query;
  }

  /// Executes the search using the current builder state.
  void _executeSearch() {
    if (_isRawMode) {
      final dsl = _dslController.text.trim();
      if (dsl.isNotEmpty) {
        widget.onSearchDsl?.call(dsl);
      }
    } else {
      widget.onSearch(_buildQuery());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with mode toggle.
          Row(
            children: [
              const Text(
                'Query Builder',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Raw mode toggle.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isRawMode ? 'DSL Mode' : 'Visual Mode',
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: _isRawMode,
                      onChanged: (value) =>
                          setState(() => _isRawMode = value),
                      activeThumbColor: CodeOpsColors.primary,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Builder content.
          if (_isRawMode)
            _buildDslInput()
          else
            _buildVisualConditions(),

          const SizedBox(height: 8),

          // Action row: time range, search, save.
          _buildActionRow(),
        ],
      ),
    );
  }

  /// Builds the DSL free-text input.
  Widget _buildDslInput() {
    return SizedBox(
      height: 80,
      child: TextField(
        controller: _dslController,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          color: CodeOpsColors.textPrimary,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: 'Enter DSL query (e.g., level:ERROR AND service:api-service)',
          hintStyle: const TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 12,
          ),
          filled: true,
          fillColor: CodeOpsColors.background,
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
      ),
    );
  }

  /// Builds the visual condition rows.
  Widget _buildVisualConditions() {
    return Column(
      children: [
        for (var i = 0; i < _conditions.length; i++) ...[
          if (i > 0) _buildCombinerRow(),
          _buildConditionRow(i),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() {
              _conditions.add(QueryCondition());
            }),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Condition'),
            style: TextButton.styleFrom(
              foregroundColor: CodeOpsColors.primary,
              textStyle: const TextStyle(fontSize: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a single condition row (field, operator, value, remove).
  Widget _buildConditionRow(int index) {
    final condition = _conditions[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Field selector.
          _CompactDropdown<String>(
            value: condition.field,
            items: _searchFields,
            width: 140,
            onChanged: (v) => setState(() => condition.field = v!),
          ),
          const SizedBox(width: 6),

          // Operator selector.
          _CompactDropdown<String>(
            value: condition.operator,
            items: _operators,
            width: 120,
            onChanged: (v) => setState(() => condition.operator = v!),
          ),
          const SizedBox(width: 6),

          // Value input.
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextField(
                onChanged: (v) => condition.value = v,
                controller: TextEditingController(text: condition.value),
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: condition.field == 'level'
                      ? 'e.g., ERROR'
                      : 'Value...',
                  hintStyle: const TextStyle(
                    color: CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: CodeOpsColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: CodeOpsColors.primary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Remove button.
          if (_conditions.length > 1)
            IconButton(
              icon: const Icon(Icons.close, size: 14),
              color: CodeOpsColors.textTertiary,
              tooltip: 'Remove condition',
              onPressed: () => setState(() {
                _conditions.removeAt(index);
              }),
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  /// Builds the AND/OR combiner row between conditions.
  Widget _buildCombinerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 40),
          InkWell(
            onTap: () => setState(() {
              _combiner = _combiner == QueryCombiner.and
                  ? QueryCombiner.or
                  : QueryCombiner.and;
            }),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: CodeOpsColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: CodeOpsColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _combiner.label,
                style: const TextStyle(
                  color: CodeOpsColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the action row with time range, search, and save buttons.
  Widget _buildActionRow() {
    return Row(
      children: [
        // Time range selector.
        PopupMenuButton<int>(
          tooltip: 'Time Range',
          color: CodeOpsColors.surface,
          onSelected: (hours) {
            setState(() {
              if (hours == 0) {
                _startTime = null;
                _endTime = null;
                _timeRangeLabel = 'All Time';
              } else {
                final now = DateTime.now().toUtc();
                _startTime = now.subtract(Duration(hours: hours));
                _endTime = now;
                _timeRangeLabel = _timeRangeLabels[hours] ?? 'Last $hours hours';
              }
            });
          },
          itemBuilder: (_) => _timeRangeLabels.entries
              .map((e) => PopupMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ))
              .toList(),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: CodeOpsColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: CodeOpsColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  _timeRangeLabel,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Search button.
        ElevatedButton.icon(
          onPressed: _executeSearch,
          icon: const Icon(Icons.search, size: 14),
          label: const Text('Search'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            minimumSize: const Size(0, 30),
          ),
        ),

        // Save button.
        if (widget.onSave != null) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: widget.onSave,
            icon: const Icon(Icons.bookmark_add_outlined, size: 14),
            label: const Text('Save'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.textSecondary,
              side: const BorderSide(color: CodeOpsColors.border),
              textStyle: const TextStyle(fontSize: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              minimumSize: const Size(0, 30),
            ),
          ),
        ],
      ],
    );
  }

  static const _timeRangeLabels = <int, String>{
    0: 'All Time',
    1: 'Last 1 hour',
    6: 'Last 6 hours',
    24: 'Last 24 hours',
    168: 'Last 7 days',
  };
}

/// A compact dropdown styled for the query builder rows.
class _CompactDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final double width;
  final ValueChanged<T?> onChanged;

  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.width,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: CodeOpsColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e.toString(),
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          dropdownColor: CodeOpsColors.surface,
          icon: const Icon(
            Icons.expand_more,
            size: 14,
            color: CodeOpsColors.textTertiary,
          ),
          isDense: true,
          isExpanded: true,
        ),
      ),
    );
  }
}
