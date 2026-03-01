/// Navigator bottom panel for the DataLens module.
///
/// Sits below the [DatabaseNavigatorTree] in the left panel, providing
/// tabbed access to Bookmarks (saved queries), History, and Scripts.
/// Each tab delegates to the appropriate panel widget.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'query_history_panel.dart';
import 'saved_queries_panel.dart';

/// Bottom panel for the database navigator with Bookmarks / History / Scripts.
///
/// Layout:
/// ```
/// ┌──────────────────────────────┐
/// │ [Bookmarks] [History] [Scripts]
/// ├──────────────────────────────┤
/// │ (active tab content)         │
/// └──────────────────────────────┘
/// ```
class NavigatorBottomPanel extends StatefulWidget {
  /// Called when a query is loaded from history or bookmarks.
  final ValueChanged<String>? onLoadSql;

  /// Creates a [NavigatorBottomPanel].
  const NavigatorBottomPanel({super.key, this.onLoadSql});

  @override
  State<NavigatorBottomPanel> createState() => _NavigatorBottomPanelState();
}

class _NavigatorBottomPanelState extends State<NavigatorBottomPanel> {
  int _activeTab = 0;

  static const _tabLabels = ['Bookmarks', 'History', 'Scripts'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CodeOpsColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab bar
          _buildTabBar(),
          const Divider(height: 1, color: CodeOpsColors.border),

          // Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  /// Builds the tab bar with Bookmarks / History / Scripts.
  Widget _buildTabBar() {
    return Container(
      height: 32,
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          for (var i = 0; i < _tabLabels.length; i++) _buildTab(i),
        ],
      ),
    );
  }

  /// Builds a single tab button.
  Widget _buildTab(int index) {
    final isActive = index == _activeTab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isActive ? CodeOpsColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            _tabLabels[index],
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              color: isActive
                  ? CodeOpsColors.textPrimary
                  : CodeOpsColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the content for the active tab.
  Widget _buildTabContent() {
    return switch (_activeTab) {
      0 => SavedQueriesPanel(onLoadSql: widget.onLoadSql),
      1 => QueryHistoryPanel(onLoadSql: widget.onLoadSql),
      2 => _buildScriptsPlaceholder(),
      _ => const SizedBox.shrink(),
    };
  }

  /// Placeholder for the Scripts tab (future feature).
  Widget _buildScriptsPlaceholder() {
    return const Center(
      child: Text(
        'Scripts — coming soon',
        style: TextStyle(
          color: CodeOpsColors.textTertiary,
          fontSize: 12,
        ),
      ),
    );
  }
}
