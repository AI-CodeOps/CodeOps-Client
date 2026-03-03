/// Browser-style open-request tab bar for the Courier module.
///
/// Shows one tab per open [RequestTab], supports click-to-activate,
/// close with dirty-state confirmation, double-click rename, drag-to-reorder,
/// and a [+] button for creating new empty requests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/courier_enums.dart';
import '../../providers/courier_ui_providers.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RequestTabBar
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal scrollable bar that shows all open [RequestTab]s above the
/// request builder.
///
/// Features:
/// - Click a tab to make it active.
/// - Close button removes the tab (with confirmation if dirty).
/// - Double-click a tab name to rename it inline.
/// - Long-press to drag-and-drop reorder.
/// - [+] button opens a new empty request tab.
class RequestTabBar extends ConsumerWidget {
  /// Creates a [RequestTabBar].
  const RequestTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(openRequestTabsProvider);
    final activeId = ref.watch(activeRequestTabProvider);

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: CodeOpsColors.background,
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.border),
          top: BorderSide(color: CodeOpsColors.border),
        ),
      ),
      child: Row(
        children: [
          // Scrollable, reorderable tab list.
          Expanded(
            child: tabs.isEmpty
                ? const _EmptyTabHint()
                : ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    buildDefaultDragHandles: false,
                    itemCount: tabs.length,
                    proxyDecorator: (child, index, animation) => Material(
                      color: Colors.transparent,
                      child: child,
                    ),
                    onReorder: (oldIndex, newIndex) {
                      final updated = List<RequestTab>.from(tabs);
                      final item = updated.removeAt(oldIndex);
                      final insertIndex =
                          newIndex > oldIndex ? newIndex - 1 : newIndex;
                      updated.insert(insertIndex, item);
                      ref.read(openRequestTabsProvider.notifier).state =
                          updated;
                    },
                    itemBuilder: (_, index) {
                      final tab = tabs[index];
                      return ReorderableDragStartListener(
                        key: ValueKey(tab.id),
                        index: index,
                        child: _OpenRequestTab(
                          tab: tab,
                          isActive: tab.id == activeId,
                          onTap: () => ref
                              .read(activeRequestTabProvider.notifier)
                              .state = tab.id,
                          onClose: () =>
                              _closeTab(context, ref, tab, tabs, activeId),
                          onRename: (name) =>
                              _renameTab(ref, tab, name, tabs),
                        ),
                      );
                    },
                  ),
          ),
          // New-request button.
          SizedBox(
            width: 36,
            child: IconButton(
              key: const Key('new_tab_button'),
              icon: const Icon(Icons.add, size: 16),
              color: CodeOpsColors.textSecondary,
              tooltip: 'New Request',
              onPressed: () => _openNewTab(ref),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab lifecycle helpers ─────────────────────────────────────────────────

  void _openNewTab(WidgetRef ref) {
    const uuid = Uuid();
    final tabId = uuid.v4();
    final newTab = RequestTab(
      id: tabId,
      name: 'New Request',
      method: CourierHttpMethod.get,
      url: '',
      isNew: true,
    );
    final updated = [...ref.read(openRequestTabsProvider), newTab];
    ref.read(openRequestTabsProvider.notifier).state = updated;
    ref.read(activeRequestTabProvider.notifier).state = tabId;
    ref.read(activeRequestStateProvider.notifier).reset();
  }

  Future<void> _closeTab(
    BuildContext context,
    WidgetRef ref,
    RequestTab tab,
    List<RequestTab> tabs,
    String? activeId,
  ) async {
    if (tab.isDirty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: CodeOpsColors.surface,
          title: const Text(
            'Unsaved Changes',
            style: TextStyle(color: CodeOpsColors.textPrimary),
          ),
          content: Text(
            '"${tab.name}" has unsaved changes. Close anyway?',
            style:
                const TextStyle(fontSize: 13, color: CodeOpsColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Close',
                style: TextStyle(color: CodeOpsColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final updated = tabs.where((t) => t.id != tab.id).toList();
    ref.read(openRequestTabsProvider.notifier).state = updated;
    if (activeId == tab.id) {
      ref.read(activeRequestTabProvider.notifier).state =
          updated.isEmpty ? null : updated.last.id;
    }
  }

  void _renameTab(
    WidgetRef ref,
    RequestTab tab,
    String newName,
    List<RequestTab> tabs,
  ) {
    if (newName.trim().isEmpty) return;
    final updated = tabs
        .map((t) => t.id == tab.id ? t.copyWith(name: newName.trim()) : t)
        .toList();
    ref.read(openRequestTabsProvider.notifier).state = updated;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyTabHint
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTabHint extends StatelessWidget {
  const _EmptyTabHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No open requests — click + to create one',
        style: TextStyle(
          fontSize: 11,
          color: CodeOpsColors.textTertiary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OpenRequestTab
// ─────────────────────────────────────────────────────────────────────────────

/// A single tab in the [RequestTabBar].
///
/// Displays the HTTP method badge, request name, dirty indicator (orange dot),
/// and a close button. Supports double-tap inline rename.
class _OpenRequestTab extends StatefulWidget {
  final RequestTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final ValueChanged<String> onRename;

  const _OpenRequestTab({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onRename,
  });

  @override
  State<_OpenRequestTab> createState() => _OpenRequestTabState();
}

class _OpenRequestTabState extends State<_OpenRequestTab> {
  bool _renaming = false;
  late TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.tab.name);
  }

  @override
  void didUpdateWidget(_OpenRequestTab old) {
    super.didUpdateWidget(old);
    if (!_renaming && old.tab.name != widget.tab.name) {
      _renameController.text = widget.tab.name;
    }
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  Color _methodColor(CourierHttpMethod m) => switch (m) {
        CourierHttpMethod.get => const Color(0xFF4ADE80),
        CourierHttpMethod.post => const Color(0xFFFBBF24),
        CourierHttpMethod.put => const Color(0xFF60A5FA),
        CourierHttpMethod.patch => const Color(0xFFA78BFA),
        CourierHttpMethod.delete => const Color(0xFFEF4444),
        CourierHttpMethod.head => const Color(0xFF34D399),
        CourierHttpMethod.options => const Color(0xFF94A3B8),
      };

  void _startRename() {
    setState(() {
      _renaming = true;
      _renameController.text = widget.tab.name;
      _renameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _renameController.text.length,
      );
    });
  }

  void _commitRename() {
    widget.onRename(_renameController.text);
    setState(() => _renaming = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _startRename,
      child: Container(
        key: Key('tab_${widget.tab.id}'),
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color:
              widget.isActive ? CodeOpsColors.surface : Colors.transparent,
          border: widget.isActive
              ? const Border(
                  top: BorderSide(color: CodeOpsColors.primary, width: 2),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Method badge.
            Text(
              widget.tab.method.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _methodColor(widget.tab.method),
              ),
            ),
            const SizedBox(width: 6),
            // Name or rename field.
            Flexible(
              child: _renaming
                  ? TextField(
                      controller: _renameController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _commitRename(),
                      onEditingComplete: _commitRename,
                    )
                  : Text(
                      widget.tab.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isActive
                            ? CodeOpsColors.textPrimary
                            : CodeOpsColors.textSecondary,
                      ),
                    ),
            ),
            // Dirty indicator.
            if (widget.tab.isDirty) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: CodeOpsColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            const SizedBox(width: 4),
            // Close button.
            InkWell(
              key: Key('close_tab_${widget.tab.id}'),
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
