/// Trace detail page — waterfall visualization with span detail panel.
///
/// **Layout:** Logger sidebar + main content area with toolbar, summary bar,
/// service color legend, waterfall timeline, and an optional span detail
/// panel on the right when a span is selected.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/logger/service_color_legend.dart';
import '../../widgets/logger/span_detail_panel.dart';
import '../../widgets/logger/trace_summary_bar.dart';
import '../../widgets/logger/trace_waterfall.dart';
import '../../widgets/shared/error_panel.dart';

/// The trace detail page showing waterfall timeline.
class TraceDetailPage extends ConsumerStatefulWidget {
  /// The correlation ID identifying the trace.
  final String correlationId;

  /// Creates a [TraceDetailPage].
  const TraceDetailPage({super.key, required this.correlationId});

  @override
  ConsumerState<TraceDetailPage> createState() => _TraceDetailPageState();
}

class _TraceDetailPageState extends ConsumerState<TraceDetailPage> {
  WaterfallSpan? _selectedSpan;

  @override
  Widget build(BuildContext context) {
    final waterfallAsync =
        ref.watch(loggerTraceWaterfallProvider(widget.correlationId));

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: waterfallAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => ErrorPanel(
                    title: 'Failed to load trace',
                    message: err.toString(),
                  ),
                  data: (waterfall) => _buildBody(waterfall),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Top toolbar with back button and title.
  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Back to Trace List',
            onPressed: () => context.go('/logger/traces'),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.account_tree_outlined,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Trace — ${widget.correlationId.length > 12 ? widget.correlationId.substring(0, 12) : widget.correlationId}...',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(
                loggerTraceWaterfallProvider(widget.correlationId)),
          ),
        ],
      ),
    );
  }

  /// Main body: summary bar, legend, waterfall, and optional detail panel.
  Widget _buildBody(TraceWaterfallResponse waterfall) {
    final serviceColors =
        TraceWaterfall.buildServiceColorMap(waterfall.spans);

    return Column(
      children: [
        TraceSummaryBar(waterfall: waterfall),
        ServiceColorLegend(serviceColors: serviceColors),
        Expanded(
          child: Row(
            children: [
              // Waterfall timeline.
              Expanded(
                flex: _selectedSpan != null ? 3 : 1,
                child: TraceWaterfall(
                  spans: waterfall.spans,
                  totalDurationMs: waterfall.totalDurationMs,
                  serviceColors: serviceColors,
                  selectedSpanId: _selectedSpan?.spanId,
                  onSpanTap: (span) {
                    setState(() {
                      _selectedSpan =
                          _selectedSpan?.spanId == span.spanId
                              ? null
                              : span;
                    });
                  },
                ),
              ),
              // Span detail panel (when a span is selected).
              if (_selectedSpan != null) ...[
                const VerticalDivider(
                    width: 1, color: CodeOpsColors.border),
                SizedBox(
                  width: 320,
                  child: SpanDetailPanel(span: _selectedSpan!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
