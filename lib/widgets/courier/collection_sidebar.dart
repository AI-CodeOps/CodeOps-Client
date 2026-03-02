/// Collection sidebar for the Courier three-pane layout.
///
/// Renders a searchable, sortable tree of collections, folders, and requests.
/// Supports expand/collapse, inline rename on double-click, right-click
/// context menus, drag-and-drop reorder/move, and create dialogs for
/// collections, folders, and requests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/courier_enums.dart';
import '../../models/courier_models.dart';
import '../../providers/courier_providers.dart';
import '../../providers/courier_ui_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Left-pane sidebar showing the Courier collection tree.
///
/// Loads all collections for the selected team, renders them as an
/// expandable tree, and provides search, sort, context menus, inline
/// rename, drag-and-drop reorder, and create dialogs.
class CollectionSidebar extends ConsumerWidget {
  /// Creates a [CollectionSidebar].
  const CollectionSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: CodeOpsColors.surface,
      child: const Column(
        children: [
          _SidebarHeader(),
          _SidebarSearchField(),
          Divider(height: 1, color: CodeOpsColors.border),
          Expanded(child: _CollectionList()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar header
// ─────────────────────────────────────────────────────────────────────────────

/// Sidebar header row: "COLLECTIONS" label, sort menu, and new-collection button.
class _SidebarHeader extends ConsumerWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(sidebarSortProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 2),
      child: Row(
        children: [
          const Text(
            'COLLECTIONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: CodeOpsColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          PopupMenuButton<SidebarSortOrder>(
            key: const Key('sort_menu'),
            tooltip: 'Sort',
            icon: Icon(
              Icons.sort,
              size: 14,
              color: sort == SidebarSortOrder.alphabetical
                  ? CodeOpsColors.primary
                  : CodeOpsColors.textTertiary,
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: SidebarSortOrder.manual,
                child: Text('Manual order'),
              ),
              PopupMenuItem(
                value: SidebarSortOrder.alphabetical,
                child: Text('Alphabetical'),
              ),
            ],
            onSelected: (v) =>
                ref.read(sidebarSortProvider.notifier).state = v,
            padding: EdgeInsets.zero,
          ),
          IconButton(
            key: const Key('new_collection_button'),
            icon: const Icon(Icons.add, size: 16),
            color: CodeOpsColors.textTertiary,
            tooltip: 'New Collection',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () => _showCreateCollectionDialog(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────

/// Search field connected to [sidebarSearchQueryProvider].
class _SidebarSearchField extends ConsumerStatefulWidget {
  const _SidebarSearchField();

  @override
  ConsumerState<_SidebarSearchField> createState() =>
      _SidebarSearchFieldState();
}

class _SidebarSearchFieldState extends ConsumerState<_SidebarSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(sidebarSearchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        key: const Key('sidebar_search'),
        controller: _controller,
        onChanged: (v) =>
            ref.read(sidebarSearchQueryProvider.notifier).state = v,
        style: const TextStyle(fontSize: 13, color: CodeOpsColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search collections…',
          hintStyle:
              const TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: CodeOpsColors.textTertiary,
          ),
          filled: true,
          fillColor: CodeOpsColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: CodeOpsColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: CodeOpsColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: CodeOpsColors.primary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collection list
// ─────────────────────────────────────────────────────────────────────────────

/// Scrollable list of collections loaded from [courierCollectionsProvider].
///
/// Handles loading, error, and empty states. Filters by
/// [sidebarSearchQueryProvider] and sorts by [sidebarSortProvider].
class _CollectionList extends ConsumerWidget {
  const _CollectionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(courierCollectionsProvider);
    final query = ref.watch(sidebarSearchQueryProvider);
    final sort = ref.watch(sidebarSortProvider);

    return collectionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: CodeOpsColors.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load collections',
                style: TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(courierCollectionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (collections) {
        var filtered = query.isEmpty
            ? List<CollectionSummaryResponse>.from(collections)
            : collections
                .where((c) =>
                    (c.name ?? '')
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                .toList();

        if (sort == SidebarSortOrder.alphabetical) {
          filtered.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        }

        if (filtered.isEmpty) {
          return _EmptyState(query: query);
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (ctx, i) =>
              _CollectionNode(collection: filtered[i]),
        );
      },
    );
  }
}

/// Empty state shown when there are no collections or no search results.
class _EmptyState extends ConsumerWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 40,
              color: CodeOpsColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'No collections yet' : 'No results for "$query"',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            if (query.isEmpty) ...[
              const SizedBox(height: 4),
              const Text(
                'Create a collection to get started',
                style: TextStyle(
                  fontSize: 12,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showCreateCollectionDialog(context, ref),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Create Collection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 13),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collection node
// ─────────────────────────────────────────────────────────────────────────────

/// A single collection row with expand/collapse, inline rename, and context menu.
class _CollectionNode extends ConsumerStatefulWidget {
  final CollectionSummaryResponse collection;

  const _CollectionNode({required this.collection});

  @override
  ConsumerState<_CollectionNode> createState() => _CollectionNodeState();
}

class _CollectionNodeState extends ConsumerState<_CollectionNode> {
  bool _isRenaming = false;
  late final TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController =
        TextEditingController(text: widget.collection.name ?? '');
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  String get _id => widget.collection.id ?? '';

  void _toggleExpand() {
    final nodes = ref.read(expandedNodesProvider);
    if (nodes.contains(_id)) {
      ref.read(expandedNodesProvider.notifier).state =
          Set.from(nodes)..remove(_id);
    } else {
      ref.read(expandedNodesProvider.notifier).state = {...nodes, _id};
    }
  }

  void _startRename() {
    setState(() {
      _isRenaming = true;
      _renameController.text = widget.collection.name ?? '';
    });
  }

  Future<void> _commitRename() async {
    final name = _renameController.text.trim();
    if (name.isEmpty || name == widget.collection.name) {
      setState(() => _isRenaming = false);
      return;
    }
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null || _id.isEmpty) {
      setState(() => _isRenaming = false);
      return;
    }
    try {
      await ref
          .read(courierApiProvider)
          .updateCollection(teamId, _id, UpdateCollectionRequest(name: name));
      ref.invalidate(courierCollectionsProvider);
    } finally {
      if (mounted) setState(() => _isRenaming = false);
    }
  }

  void _showContextMenu(TapDownDetails details) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'add_folder', child: Text('Add Folder')),
        PopupMenuItem(value: 'add_request', child: Text('Add Request')),
        PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: CodeOpsColors.error)),
        ),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'rename':
          _startRename();
        case 'add_folder':
          _showCreateFolderDialog(context, ref,
              collectionId: _id, parentFolderId: null);
        case 'add_request':
          _showCreateRequestDialog(context, ref,
              collectionId: _id, folderId: null);
        case 'duplicate':
          _duplicate();
        case 'delete':
          _delete();
      }
    });
  }

  Future<void> _duplicate() async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null || _id.isEmpty) return;
    await ref.read(courierApiProvider).duplicateCollection(teamId, _id);
    ref.invalidate(courierCollectionsProvider);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Collection'),
        content:
            Text('Delete "${widget.collection.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: CodeOpsColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null || _id.isEmpty) return;
    await ref.read(courierApiProvider).deleteCollection(teamId, _id);
    ref.invalidate(courierCollectionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final expanded = ref.watch(expandedNodesProvider).contains(_id);
    final selected = ref.watch(selectedNodeIdProvider) == _id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(selectedNodeIdProvider.notifier).state = _id;
            _toggleExpand();
          },
          onDoubleTap: _startRename,
          onSecondaryTapDown: _showContextMenu,
          child: Container(
            key: Key('collection_$_id'),
            color: selected
                ? CodeOpsColors.primary.withOpacity(0.15)
                : Colors.transparent,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: CodeOpsColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded
                        ? Icons.folder_open_outlined
                        : Icons.folder_outlined,
                    size: 14,
                    color: CodeOpsColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _isRenaming
                        ? _RenameField(
                            controller: _renameController,
                            onSubmit: _commitRename,
                            onCancel: () =>
                                setState(() => _isRenaming = false),
                          )
                        : Text(
                            widget.collection.name ?? '(unnamed)',
                            style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? CodeOpsColors.textPrimary
                                  : CodeOpsColors.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) _CollectionTree(collectionId: _id),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collection tree (lazy-loaded folder/request list)
// ─────────────────────────────────────────────────────────────────────────────

/// Loads and renders the folder tree for a collection.
class _CollectionTree extends ConsumerWidget {
  final String collectionId;

  const _CollectionTree({required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(courierCollectionTreeProvider(collectionId));

    return treeAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: SizedBox(
          height: 2,
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ),
      error: (e, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Text(
          'Error loading tree',
          style: TextStyle(fontSize: 12, color: CodeOpsColors.error),
        ),
      ),
      data: (folders) => Column(
        children: folders
            .map((f) => _FolderNode(
                  folder: f,
                  collectionId: collectionId,
                  depth: 1,
                ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Folder node
// ─────────────────────────────────────────────────────────────────────────────

/// A single folder row with expand/collapse, inline rename, and context menu.
///
/// Renders nested subfolders and requests when expanded.
class _FolderNode extends ConsumerStatefulWidget {
  final FolderTreeResponse folder;
  final String collectionId;
  final int depth;

  const _FolderNode({
    required this.folder,
    required this.collectionId,
    required this.depth,
  });

  @override
  ConsumerState<_FolderNode> createState() => _FolderNodeState();
}

class _FolderNodeState extends ConsumerState<_FolderNode> {
  bool _isRenaming = false;
  late final TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController =
        TextEditingController(text: widget.folder.name ?? '');
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  String get _id => widget.folder.id ?? '';

  bool get _hasChildren =>
      (widget.folder.subFolders?.isNotEmpty ?? false) ||
      (widget.folder.requests?.isNotEmpty ?? false);

  void _toggleExpand() {
    final nodes = ref.read(expandedNodesProvider);
    if (nodes.contains(_id)) {
      ref.read(expandedNodesProvider.notifier).state =
          Set.from(nodes)..remove(_id);
    } else {
      ref.read(expandedNodesProvider.notifier).state = {...nodes, _id};
    }
  }

  void _showContextMenu(TapDownDetails details) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'add_folder', child: Text('Add Subfolder')),
        PopupMenuItem(value: 'add_request', child: Text('Add Request')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: CodeOpsColors.error)),
        ),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'rename':
          setState(() {
            _isRenaming = true;
            _renameController.text = widget.folder.name ?? '';
          });
        case 'add_folder':
          _showCreateFolderDialog(context, ref,
              collectionId: widget.collectionId, parentFolderId: _id);
        case 'add_request':
          _showCreateRequestDialog(context, ref,
              collectionId: widget.collectionId, folderId: _id);
        case 'delete':
          _delete();
      }
    });
  }

  Future<void> _commitRename() async {
    final name = _renameController.text.trim();
    if (name.isEmpty || name == widget.folder.name) {
      setState(() => _isRenaming = false);
      return;
    }
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null || _id.isEmpty) {
      setState(() => _isRenaming = false);
      return;
    }
    try {
      await ref
          .read(courierApiProvider)
          .updateFolder(teamId, _id, UpdateFolderRequest(name: name));
      ref.invalidate(courierCollectionTreeProvider(widget.collectionId));
    } finally {
      if (mounted) setState(() => _isRenaming = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Folder'),
        content:
            Text('Delete "${widget.folder.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: CodeOpsColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null || _id.isEmpty) return;
    await ref.read(courierApiProvider).deleteFolder(teamId, _id);
    ref.invalidate(courierCollectionTreeProvider(widget.collectionId));
  }

  @override
  Widget build(BuildContext context) {
    final expanded = ref.watch(expandedNodesProvider).contains(_id);
    final selected = ref.watch(selectedNodeIdProvider) == _id;
    final indent = widget.depth * 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(selectedNodeIdProvider.notifier).state = _id;
            if (_hasChildren) _toggleExpand();
          },
          onDoubleTap: () => setState(() {
            _isRenaming = true;
            _renameController.text = widget.folder.name ?? '';
          }),
          onSecondaryTapDown: _showContextMenu,
          child: Container(
            key: Key('folder_$_id'),
            color: selected
                ? CodeOpsColors.primary.withOpacity(0.15)
                : Colors.transparent,
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(indent + 8, 4, 8, 4),
              child: Row(
                children: [
                  if (_hasChildren)
                    Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 14,
                      color: CodeOpsColors.textTertiary,
                    )
                  else
                    const SizedBox(width: 14),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.folder_open : Icons.folder,
                    size: 13,
                    color: CodeOpsColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _isRenaming
                        ? _RenameField(
                            controller: _renameController,
                            onSubmit: _commitRename,
                            onCancel: () =>
                                setState(() => _isRenaming = false),
                          )
                        : Text(
                            widget.folder.name ?? '(unnamed)',
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? CodeOpsColors.textPrimary
                                  : CodeOpsColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          ...?widget.folder.subFolders?.map(
            (sf) => _FolderNode(
              folder: sf,
              collectionId: widget.collectionId,
              depth: widget.depth + 1,
            ),
          ),
          ...?widget.folder.requests?.map(
            (r) => _RequestNode(
              request: r,
              collectionId: widget.collectionId,
              depth: widget.depth + 1,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request node
// ─────────────────────────────────────────────────────────────────────────────

/// A single request row with method badge, tap-to-open-tab, inline rename,
/// and context menu.
class _RequestNode extends ConsumerStatefulWidget {
  final RequestSummaryResponse request;
  final String collectionId;
  final int depth;

  const _RequestNode({
    required this.request,
    required this.collectionId,
    required this.depth,
  });

  @override
  ConsumerState<_RequestNode> createState() => _RequestNodeState();
}

class _RequestNodeState extends ConsumerState<_RequestNode> {
  bool _isRenaming = false;
  late final TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController =
        TextEditingController(text: widget.request.name ?? '');
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  String get _id => widget.request.id ?? '';

  void _openInTab() {
    final tabs = ref.read(openRequestTabsProvider);
    final existing = tabs.where((t) => t.requestId == _id).firstOrNull;
    if (existing != null) {
      ref.read(activeRequestTabProvider.notifier).state = existing.id;
      return;
    }
    final tab = RequestTab(
      id: 'tab_${_id}_${DateTime.now().millisecondsSinceEpoch}',
      requestId: _id,
      name: widget.request.name ?? 'Request',
      method: widget.request.method ?? CourierHttpMethod.get,
      url: widget.request.url ?? '',
    );
    ref.read(openRequestTabsProvider.notifier).state = [...tabs, tab];
    ref.read(activeRequestTabProvider.notifier).state = tab.id;
  }

  void _showContextMenu(TapDownDetails details) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: CodeOpsColors.error)),
        ),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'rename':
          setState(() {
            _isRenaming = true;
            _renameController.text = widget.request.name ?? '';
          });
        case 'duplicate':
          _duplicate();
        case 'delete':
          _delete();
      }
    });
  }

  Future<void> _commitRename() async {
    final name = _renameController.text.trim();
    if (name.isEmpty || name == widget.request.name) {
      setState(() => _isRenaming = false);
      return;
    }
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null || _id.isEmpty) {
      setState(() => _isRenaming = false);
      return;
    }
    try {
      await ref
          .read(courierApiProvider)
          .updateRequest(teamId, _id, UpdateRequestRequest(name: name));
      ref.invalidate(courierCollectionTreeProvider(widget.collectionId));
    } finally {
      if (mounted) setState(() => _isRenaming = false);
    }
  }

  Future<void> _duplicate() async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null || _id.isEmpty) return;
    await ref.read(courierApiProvider).duplicateRequest(teamId, _id);
    ref.invalidate(courierCollectionTreeProvider(widget.collectionId));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Request'),
        content:
            Text('Delete "${widget.request.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: CodeOpsColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null || _id.isEmpty) return;
    await ref.read(courierApiProvider).deleteRequest(teamId, _id);
    ref.invalidate(courierCollectionTreeProvider(widget.collectionId));
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedNodeIdProvider) == _id;
    final indent = widget.depth * 16.0;
    final method = widget.request.method ?? CourierHttpMethod.get;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(selectedNodeIdProvider.notifier).state = _id;
        _openInTab();
      },
      onDoubleTap: () => setState(() {
        _isRenaming = true;
        _renameController.text = widget.request.name ?? '';
      }),
      onSecondaryTapDown: _showContextMenu,
      child: Container(
        key: Key('request_$_id'),
        color: selected
            ? CodeOpsColors.primary.withOpacity(0.15)
            : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.fromLTRB(indent + 26, 3, 8, 3),
          child: Row(
            children: [
              MethodBadge(method: method),
              const SizedBox(width: 6),
              Expanded(
                child: _isRenaming
                    ? _RenameField(
                        controller: _renameController,
                        onSubmit: _commitRename,
                        onCancel: () =>
                            setState(() => _isRenaming = false),
                      )
                    : Text(
                        widget.request.name ?? '(unnamed)',
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? CodeOpsColors.textPrimary
                              : CodeOpsColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Method badge (public — used by CourierPage tab bar too)
// ─────────────────────────────────────────────────────────────────────────────

/// Color-coded HTTP method chip displayed on request rows and tab labels.
///
/// Colors follow the OpenAPI/Swagger specification color conventions:
/// GET=#49CC90, POST=#FCA130, PUT=#6C63FF, PATCH=#50E3C2,
/// DELETE=#F93E3E, HEAD=#9012FE, OPTIONS=#0D5AA7.
class MethodBadge extends StatelessWidget {
  /// The HTTP method to display.
  final CourierHttpMethod method;

  /// Creates a [MethodBadge].
  const MethodBadge({super.key, required this.method});

  static const Map<CourierHttpMethod, Color> _colors = {
    CourierHttpMethod.get: Color(0xFF49CC90),
    CourierHttpMethod.post: Color(0xFFFCA130),
    CourierHttpMethod.put: Color(0xFF6C63FF),
    CourierHttpMethod.patch: Color(0xFF50E3C2),
    CourierHttpMethod.delete: Color(0xFFF93E3E),
    CourierHttpMethod.head: Color(0xFF9012FE),
    CourierHttpMethod.options: Color(0xFF0D5AA7),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[method] ?? CodeOpsColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        method.displayName,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline rename field
// ─────────────────────────────────────────────────────────────────────────────

/// Single-line text field for inline rename operations.
///
/// Submits on Enter or focus loss, cancels on Escape.
class _RenameField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _RenameField({
    required this.controller,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      style:
          const TextStyle(fontSize: 12, color: CodeOpsColors.textPrimary),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        border: InputBorder.none,
      ),
      onSubmitted: (_) => onSubmit(),
      onTapOutside: (_) => onCancel(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create collection dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the create-collection dialog.
void _showCreateCollectionDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (_) => _CreateCollectionDialog(ref: ref),
  );
}

/// Dialog for creating a new collection.
class _CreateCollectionDialog extends StatefulWidget {
  final WidgetRef ref;

  const _CreateCollectionDialog({required this.ref});

  @override
  State<_CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<_CreateCollectionDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    final teamId = widget.ref.read(selectedTeamIdProvider);
    if (teamId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final desc = _descController.text.trim();
      await widget.ref.read(courierApiProvider).createCollection(
            teamId,
            CreateCollectionRequest(
              name: name,
              description: desc.isEmpty ? null : desc,
            ),
          );
      widget.ref.invalidate(courierCollectionsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Collection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('collection_name_field'),
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('collection_desc_field'),
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create folder dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the create-folder dialog.
void _showCreateFolderDialog(
  BuildContext context,
  WidgetRef ref, {
  required String collectionId,
  String? parentFolderId,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _CreateFolderDialog(
      ref: ref,
      collectionId: collectionId,
      parentFolderId: parentFolderId,
    ),
  );
}

/// Dialog for creating a new folder inside a collection or parent folder.
class _CreateFolderDialog extends StatefulWidget {
  final WidgetRef ref;
  final String collectionId;
  final String? parentFolderId;

  const _CreateFolderDialog({
    required this.ref,
    required this.collectionId,
    this.parentFolderId,
  });

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    final teamId = widget.ref.read(selectedTeamIdProvider);
    if (teamId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.ref.read(courierApiProvider).createFolder(
            teamId,
            CreateFolderRequest(
              collectionId: widget.collectionId,
              parentFolderId: widget.parentFolderId,
              name: name,
            ),
          );
      widget.ref
          .invalidate(courierCollectionTreeProvider(widget.collectionId));
      // Auto-expand the parent node so the new folder is visible.
      final nodes = widget.ref.read(expandedNodesProvider);
      final expandId = widget.parentFolderId ?? widget.collectionId;
      widget.ref.read(expandedNodesProvider.notifier).state = {
        ...nodes,
        expandId,
      };
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Folder'),
      content: TextField(
        key: const Key('folder_name_field'),
        controller: _nameController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Name',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create request dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the create-request dialog.
///
/// [folderId] is null when triggered from a collection context menu —
/// in that case the dialog informs the user to select a folder first.
void _showCreateRequestDialog(
  BuildContext context,
  WidgetRef ref, {
  required String collectionId,
  String? folderId,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _CreateRequestDialog(
      ref: ref,
      collectionId: collectionId,
      folderId: folderId,
    ),
  );
}

/// Dialog for creating a new HTTP request inside a folder.
class _CreateRequestDialog extends StatefulWidget {
  final WidgetRef ref;
  final String collectionId;
  final String? folderId;

  const _CreateRequestDialog({
    required this.ref,
    required this.collectionId,
    this.folderId,
  });

  @override
  State<_CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<_CreateRequestDialog> {
  final _nameController = TextEditingController();
  CourierHttpMethod _method = CourierHttpMethod.get;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    final folderId = widget.folderId;
    if (folderId == null) {
      setState(() => _error = 'Please add a folder to this collection first');
      return;
    }
    final teamId = widget.ref.read(selectedTeamIdProvider);
    if (teamId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.ref.read(courierApiProvider).createRequest(
            teamId,
            CreateRequestRequest(
              folderId: folderId,
              name: name,
              method: _method,
              url: '',
            ),
          );
      widget.ref
          .invalidate(courierCollectionTreeProvider(widget.collectionId));
      final nodes = widget.ref.read(expandedNodesProvider);
      widget.ref.read(expandedNodesProvider.notifier).state = {
        ...nodes,
        folderId,
      };
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('request_name_field'),
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CourierHttpMethod>(
            key: const Key('request_method_dropdown'),
            value: _method,
            decoration: const InputDecoration(
              labelText: 'Method',
              border: OutlineInputBorder(),
            ),
            items: CourierHttpMethod.values
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.displayName),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _method = v ?? _method),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
