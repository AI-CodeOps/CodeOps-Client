/// Courier main page — three-pane HTTP client layout.
///
/// Renders the [CourierToolbar], resizable collection sidebar (left),
/// request builder (center), response viewer (right), and
/// [CourierStatusBar]. Subsequent CCF tasks fill in each pane.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/courier_ui_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/courier/collection_sidebar.dart';
import '../../widgets/courier/courier_status_bar.dart';
import '../../widgets/courier/courier_toolbar.dart';
import '../../widgets/courier/request_builder.dart';
import '../../widgets/courier/request_tab_bar.dart';
import '../../widgets/courier/response_viewer.dart';

/// The Courier module root — a Postman-style three-pane HTTP client.
///
/// Layout:
/// ```
/// ┌──────────────────────────────────────────────────────────┐
/// │ CourierToolbar                                           │
/// ├──────────────────────────────────────────────────────────┤
/// │ RequestTabBar  (browser-style open-request tabs)         │
/// ├───────────┬──────────────────────────┬───────────────────┤
/// │ Collection│ Request Builder          │ Response Viewer   │
/// │ Sidebar   │ [Tab bar · builder area] │                   │
/// ├───────────┴──────────────────────────┴───────────────────┤
/// │ CourierStatusBar                                         │
/// └──────────────────────────────────────────────────────────┘
/// ```
///
/// The [requestId] and [collectionId] parameters are set by the router
/// when navigating to `/courier/request/:requestId` or
/// `/courier/collection/:collectionId`. Both are null on `/courier`.
class CourierPage extends ConsumerStatefulWidget {
  /// Pre-selected request ID to open in a tab, or null.
  final String? requestId;

  /// Pre-selected collection ID to highlight in the sidebar, or null.
  final String? collectionId;

  /// Creates a [CourierPage].
  const CourierPage({super.key, this.requestId, this.collectionId});

  @override
  ConsumerState<CourierPage> createState() => _CourierPageState();
}

class _CourierPageState extends ConsumerState<CourierPage> {
  // Minimum / maximum pane widths.
  static const double _minSidebarWidth = 200;
  static const double _maxSidebarWidth = 400;
  static const double _minResponseWidth = 300;

  @override
  void initState() {
    super.initState();
    // Apply router-supplied selections after first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.collectionId != null) {
        ref.read(selectedCollectionIdProvider.notifier).state =
            widget.collectionId;
      }
    });
  }

  // ─── Sidebar drag ────────────────────────────────────────────────────────

  void _onSidebarDrag(double delta) {
    final current = ref.read(sidebarWidthProvider);
    final updated = (current + delta).clamp(_minSidebarWidth, _maxSidebarWidth);
    ref.read(sidebarWidthProvider.notifier).state = updated;
  }

  // ─── Response pane drag ──────────────────────────────────────────────────

  void _onResponseDrag(double delta) {
    final current = ref.read(responsePaneWidthProvider);
    // Dragging right → smaller response pane; left → larger.
    final updated = (current - delta).clamp(_minResponseWidth, double.infinity);
    ref.read(responsePaneWidthProvider.notifier).state = updated;
  }

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = ref.watch(sidebarWidthProvider);
    final responseWidth = ref.watch(responsePaneWidthProvider);
    final responseCollapsed = ref.watch(responsePaneCollapsedProvider);

    return Column(
      children: [
        // ── Toolbar ─────────────────────────────────────────────────────────
        const CourierToolbar(),
        // ── Open request tab bar ─────────────────────────────────────────────
        const RequestTabBar(),
        // ── Three panes ─────────────────────────────────────────────────────
        Expanded(
          child: Row(
            children: [
              // Left: collection sidebar
              SizedBox(
                width: sidebarWidth,
                child: const CollectionSidebar(),
              ),
              // Draggable divider between sidebar and request builder
              _PaneDivider(onDrag: _onSidebarDrag),
              // Center: request builder
              const Expanded(child: RequestBuilder()),
              // Draggable divider between request builder and response viewer
              _PaneDivider(onDrag: _onResponseDrag),
              // Right: response viewer (collapsible)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: responseCollapsed ? 0 : responseWidth,
                child: responseCollapsed
                    ? const SizedBox.shrink()
                    : const ResponseViewer(),
              ),
            ],
          ),
        ),
        // ── Status bar ──────────────────────────────────────────────────────
        const CourierStatusBar(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Draggable pane divider
// ─────────────────────────────────────────────────────────────────────────────

/// Thin vertical divider between two panes that reacts to horizontal drag.
///
/// Shows [SystemMouseCursors.resizeColumn] on hover.
class _PaneDivider extends StatelessWidget {
  /// Called with the horizontal drag delta in logical pixels.
  final void Function(double delta) onDrag;

  const _PaneDivider({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: 4,
          color: CodeOpsColors.border,
          child: Center(
            child: Container(
              width: 1,
              color: CodeOpsColors.border,
            ),
          ),
        ),
      ),
    );
  }
}
