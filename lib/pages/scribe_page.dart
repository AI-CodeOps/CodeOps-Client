/// The Scribe page — a multi-tab code and text editor integrated into
/// the CodeOps desktop application.
///
/// Scribe provides syntax-highlighted editing for 30+ languages with
/// tabbed file management, session persistence, an optional sidebar,
/// and a status bar showing cursor position, language mode, and encoding.
///
/// This page is the standalone Scribe experience at the `/scribe` route.
/// The underlying [ScribeEditor] widget is also consumed by other Control
/// Plane modules (Courier, DataLens, Logger, Registry, Vault).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scribe_diff_models.dart';
import '../models/scribe_models.dart';
import '../providers/scribe_providers.dart';
import '../services/logging/log_service.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../widgets/scribe/scribe_command_palette.dart';
import '../widgets/scribe/scribe_diff_editor.dart';
import '../widgets/scribe/scribe_diff_selector.dart';
import '../widgets/scribe/scribe_drop_target.dart';
import '../widgets/scribe/scribe_editor.dart';
import '../widgets/scribe/scribe_empty_state.dart';
import '../widgets/scribe/scribe_file_changed_banner.dart';
import '../widgets/scribe/scribe_find_panel.dart';
import '../widgets/scribe/scribe_go_to_line_dialog.dart';
import '../widgets/scribe/scribe_language.dart';
import '../widgets/scribe/scribe_markdown_split.dart';
import '../widgets/scribe/scribe_markdown_toc.dart';
import '../widgets/scribe/scribe_new_file_dialog.dart';
import '../widgets/scribe/scribe_preview_controls.dart';
import '../widgets/scribe/scribe_quick_open.dart';
import '../widgets/scribe/scribe_recent_files.dart';
import '../widgets/scribe/scribe_save_dialog.dart';
import '../widgets/scribe/scribe_settings_panel.dart';
import '../widgets/scribe/scribe_shortcut_registry.dart';
import '../widgets/scribe/scribe_shortcuts_help.dart';
import '../widgets/scribe/scribe_sidebar.dart';
import '../widgets/scribe/scribe_status_bar.dart';
import '../widgets/scribe/scribe_tab_bar.dart';
import '../widgets/scribe/scribe_url_dialog.dart';

/// The Scribe page — multi-tab code editor at `/scribe`.
class ScribePage extends ConsumerStatefulWidget {
  /// Creates a [ScribePage].
  const ScribePage({super.key});

  @override
  ConsumerState<ScribePage> createState() => _ScribePageState();
}

class _ScribePageState extends ConsumerState<ScribePage>
    with WidgetsBindingObserver {
  static const String _tag = 'ScribePage';

  int _cursorLine = 0;
  int _cursorColumn = 0;
  int _selectedChars = 0;
  int _selectedLines = 0;

  Timer? _autoSaveTimer;
  bool _autoSaveEnabled = false;
  int _autoSaveIntervalSeconds = 30;

  /// Whether the diff comparison selector is visible.
  bool _showDiffSelector = false;

  /// The tab ID pre-selected as the left side of a comparison.
  String? _diffLeftTabId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger session restoration.
    Future.microtask(() => ref.read(scribeInitProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      // Persist session immediately when the app is backgrounded or closing.
      ref.read(scribeTabsProvider.notifier).persistSessionNow();
    } else if (state == AppLifecycleState.resumed) {
      // Check for file changes on disk when the app is resumed.
      _checkFilesChangedOnDisk();
    }
  }

  /// Checks whether any file-backed tab has been modified on disk since
  /// the tab's [lastModifiedAt] timestamp.
  Future<void> _checkFilesChangedOnDisk() async {
    final tabs = ref.read(scribeTabsProvider);
    final changed = <String, bool>{};
    for (final tab in tabs) {
      if (tab.filePath == null) continue;
      try {
        final file = File(tab.filePath!);
        if (!file.existsSync()) continue;
        final stat = await file.stat();
        if (stat.modified.isAfter(tab.lastModifiedAt)) {
          changed[tab.id] = true;
        }
      } on FileSystemException {
        // Ignore unreadable files.
      }
    }
    if (changed.isNotEmpty) {
      ref.read(scribeFileChangedTabsProvider.notifier).state = changed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(scribeTabsProvider);
    final activeTab = ref.watch(activeScribeTabProvider);
    final sidebarVisible = ref.watch(scribeSidebarVisibleProvider);
    final settingsPanelVisible =
        ref.watch(scribeSettingsPanelVisibleProvider);
    final settings = ref.watch(scribeSettingsProvider);
    final recentFilesPanelVisible =
        ref.watch(scribeRecentFilesPanelVisibleProvider);
    final quickOpenVisible = ref.watch(scribeQuickOpenVisibleProvider);
    final fileChangedTabs = ref.watch(scribeFileChangedTabsProvider);
    final findPanelVisible = ref.watch(scribeFindPanelVisibleProvider);
    final findReplaceVisible = ref.watch(scribeFindReplaceVisibleProvider);
    final commandPaletteVisible =
        ref.watch(scribeCommandPaletteVisibleProvider);
    final shortcutsHelpVisible =
        ref.watch(scribeShortcutsHelpVisibleProvider);

    // Manage auto-save timer when settings change.
    _updateAutoSaveTimer(settings);

    return CallbackShortcuts(
      bindings: ScribeShortcutRegistry.buildBindings({
        'file.new': _handleNewTab,
        'file.open': _handleOpenFile,
        'file.newDialog': _handleNewFileDialog,
        'file.save': _handleSave,
        'file.saveAs': _handleSaveAs,
        'file.saveAll': _handleSaveAll,
        'editor.find': _handleToggleFind,
        'editor.findReplace': _handleToggleFindReplace,
        'editor.goToLine': _handleGoToLine,
        'view.sidebar': _handleToggleSidebar,
        'view.preview': _handleTogglePreview,
        'view.recentFiles': _handleToggleRecentFiles,
        'view.quickOpen': _handleToggleQuickOpen,
        'view.commandPalette': _handleToggleCommandPalette,
        'view.shortcutsHelp': _handleToggleShortcutsHelp,
        'tabs.close': _handleCloseActiveTab,
        'tabs.next': _handleNextTab,
        'tabs.prev': _handlePrevTab,
        'tabs.reopen': _handleReopenLastClosed,
      }),
      child: Focus(
        autofocus: true,
        child: ScribeDropTarget(
          onFilesDropped: _handleFilesDropped,
          child: Column(
            children: [
              if (tabs.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: ScribeTabBar(
                        tabs: tabs,
                        activeTabId: activeTab?.id,
                        onTabSelected: _handleTabSelected,
                        onTabClosed: _handleTabClosed,
                        onNewTab: _handleNewTab,
                        onCloseOthers: _handleCloseOtherTabs,
                        onCloseAll: _handleCloseAllTabs,
                        onCloseToRight: _handleCloseToRight,
                        onCloseSaved: _handleCloseSavedTabs,
                        onCopyFilePath: _handleCopyFilePath,
                        onRevealInFinder: _handleRevealInFinder,
                        onCompareWith: _handleCompareWith,
                        onReorder: _handleReorderTabs,
                        onToggleSidebar: _handleToggleSidebar,
                        sidebarVisible: sidebarVisible,
                        onNewFileDialog: _handleNewFileDialog,
                        onOpenUrl: _handleOpenUrlDialog,
                      ),
                    ),
                    if (activeTab != null &&
                        activeTab.language == 'markdown') ...[
                      ScribeMarkdownToc(
                        content: activeTab.content,
                        currentLine: _cursorLine,
                        onHeadingSelected: _handleHeadingSelected,
                      ),
                      const SizedBox(width: 4),
                      ScribePreviewControls(
                        mode: _getPreviewMode(activeTab.id),
                        onModeChanged: (mode) =>
                            _handlePreviewModeChanged(activeTab.id, mode),
                      ),
                      const SizedBox(width: 4),
                    ],
                    _SettingsGearButton(
                      isActive: settingsPanelVisible,
                      onPressed: _handleToggleSettingsPanel,
                    ),
                  ],
                ),
              // Diff selector bar (CS-007).
              if (_showDiffSelector && tabs.length > 1)
                ScribeDiffSelector(
                  tabs: tabs,
                  initialLeftTabId: _diffLeftTabId,
                  onCompare: _handleStartCompare,
                  onClose: _handleCloseDiffSelector,
                ),
              // File changed on disk banner (CS-008).
              if (activeTab != null &&
                  fileChangedTabs[activeTab.id] == true)
                ScribeFileChangedBanner(
                  fileName: activeTab.title,
                  onReload: () => _handleReloadFromDisk(activeTab.id),
                  onKeep: () => _handleKeepContent(activeTab.id),
                ),
              // Find panel (CS-009).
              if (findPanelVisible && activeTab != null)
                ScribeFindPanel(
                  showReplace: findReplaceVisible,
                  onClose: _handleCloseFind,
                  onToggleReplace: _handleToggleFindReplaceRow,
                ),
              if (tabs.isNotEmpty && activeTab != null)
                Expanded(
                  child: Stack(
                    children: [
                      _buildMainContent(
                        tabs: tabs,
                        activeTab: activeTab,
                        settings: settings,
                        sidebarVisible: sidebarVisible,
                        settingsPanelVisible: settingsPanelVisible,
                        recentFilesPanelVisible: recentFilesPanelVisible,
                      ),
                      // Quick-open overlay (CS-008).
                      if (quickOpenVisible)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _handleCloseQuickOpen,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              color: Colors.black26,
                              alignment: Alignment.topCenter,
                              padding: const EdgeInsets.only(top: 40),
                              child: ScribeQuickOpen(
                                items: _buildQuickOpenItems(),
                                onSelect: _handleQuickOpenSelect,
                                onClose: _handleCloseQuickOpen,
                              ),
                            ),
                          ),
                        ),
                      // Command palette overlay (CS-009).
                      if (commandPaletteVisible)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _handleCloseCommandPalette,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              color: Colors.black26,
                              alignment: Alignment.topCenter,
                              padding: const EdgeInsets.only(top: 40),
                              child: ScribeCommandPalette(
                                commands: ScribeShortcutRegistry.commands,
                                onSelect: _handleCommandPaletteSelect,
                                onClose: _handleCloseCommandPalette,
                              ),
                            ),
                          ),
                        ),
                      // Keyboard shortcuts help overlay (CS-009).
                      if (shortcutsHelpVisible)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _handleCloseShortcutsHelp,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              color: Colors.black26,
                              alignment: Alignment.center,
                              child: ScribeShortcutsHelp(
                                onClose: _handleCloseShortcutsHelp,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ScribeEmptyState(
                    onNewFile: _handleNewTab,
                    onOpenFile: _handleOpenFile,
                  ),
                ),
              if (tabs.isNotEmpty && activeTab != null)
                ScribeStatusBar(
                  cursorLine: _cursorLine,
                  cursorColumn: _cursorColumn,
                  language: activeTab.language,
                  onLanguageChanged: (lang) =>
                      _handleLanguageChanged(activeTab, lang),
                  selectedChars: _selectedChars,
                  selectedLines: _selectedLines,
                  insertSpaces: settings.insertSpaces,
                  tabSize: settings.tabSize,
                  onInsertSpacesChanged: (useSpaces) {
                    if (useSpaces != settings.insertSpaces) {
                      ref
                          .read(scribeSettingsProvider.notifier)
                          .toggleInsertSpaces();
                    }
                  },
                  onTabSizeChanged: (size) => ref
                      .read(scribeSettingsProvider.notifier)
                      .updateTabSize(size),
                  encoding: activeTab.encoding,
                  onEncodingChanged: (enc) => ref
                      .read(scribeTabsProvider.notifier)
                      .updateEncoding(activeTab.id, enc),
                  lineEnding: activeTab.lineEnding,
                  onLineEndingChanged: (le) => ref
                      .read(scribeTabsProvider.notifier)
                      .updateLineEnding(activeTab.id, le),
                  content: activeTab.content,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab creation
  // ---------------------------------------------------------------------------

  /// Creates a new untitled tab.
  void _handleNewTab() {
    final counter = ref.read(scribeUntitledCounterProvider);
    ref.read(scribeUntitledCounterProvider.notifier).state = counter + 1;
    ref.read(scribeTabsProvider.notifier).openTab(
          title: 'Untitled-$counter',
        );
  }

  /// Opens a file picker (multi-select) and creates tabs from selected files.
  Future<void> _handleOpenFile() async {
    final fileService = ref.read(scribeFileServiceProvider);
    final tabs = await fileService.openFiles();
    for (final tab in tabs) {
      ref.read(scribeTabsProvider.notifier).openTab(
            title: tab.title,
            content: tab.content,
            language: tab.language,
            filePath: tab.filePath,
          );
      if (tab.filePath != null) {
        await _trackRecentFile(tab.filePath!);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Tab selection
  // ---------------------------------------------------------------------------

  /// Switches to the selected tab.
  void _handleTabSelected(String tabId) {
    ref.read(activeScribeTabIdProvider.notifier).state = tabId;
    final tab =
        ref.read(scribeTabsProvider).where((t) => t.id == tabId).firstOrNull;
    if (tab != null) {
      setState(() {
        _cursorLine = tab.cursorLine;
        _cursorColumn = tab.cursorColumn;
        _selectedChars = 0;
        _selectedLines = 0;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Keyboard shortcuts — tab navigation
  // ---------------------------------------------------------------------------

  /// Cycles to the next tab (wraps around).
  void _handleNextTab() {
    final tabs = ref.read(scribeTabsProvider);
    if (tabs.length < 2) return;

    final activeId = ref.read(activeScribeTabIdProvider);
    final currentIndex = tabs.indexWhere((t) => t.id == activeId);
    final nextIndex = (currentIndex + 1) % tabs.length;
    _handleTabSelected(tabs[nextIndex].id);
  }

  /// Cycles to the previous tab (wraps around).
  void _handlePrevTab() {
    final tabs = ref.read(scribeTabsProvider);
    if (tabs.length < 2) return;

    final activeId = ref.read(activeScribeTabIdProvider);
    final currentIndex = tabs.indexWhere((t) => t.id == activeId);
    final prevIndex = (currentIndex - 1 + tabs.length) % tabs.length;
    _handleTabSelected(tabs[prevIndex].id);
  }

  // ---------------------------------------------------------------------------
  // Save operations (CS-004)
  // ---------------------------------------------------------------------------

  /// Saves the active tab (Ctrl+S).
  ///
  /// If the tab has no file path, triggers Save As instead.
  void _handleSave() {
    final activeTab = ref.read(activeScribeTabProvider);
    if (activeTab == null) return;

    if (activeTab.filePath == null) {
      _handleSaveAs();
    } else {
      _saveTab(activeTab);
    }
  }

  /// Opens a Save As dialog for the active tab (Ctrl+Shift+S).
  void _handleSaveAs() {
    final activeTab = ref.read(activeScribeTabProvider);
    if (activeTab == null) return;
    _saveTabAs(activeTab);
  }

  /// Saves all dirty tabs (Ctrl+Alt+S).
  ///
  /// Tabs without a file path are skipped (they would need Save As).
  void _handleSaveAll() {
    final tabs = ref.read(scribeTabsProvider);
    for (final tab in tabs) {
      if (tab.isDirty && tab.filePath != null) {
        _saveTab(tab);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Tab closing — with save confirmation for dirty tabs
  // ---------------------------------------------------------------------------

  /// Closes the active tab via Ctrl+W.
  void _handleCloseActiveTab() {
    final activeId = ref.read(activeScribeTabIdProvider);
    if (activeId != null) {
      _handleTabClosed(activeId);
    }
  }

  /// Closes a single tab. Shows save confirmation if dirty.
  Future<void> _handleTabClosed(String tabId) async {
    final tab =
        ref.read(scribeTabsProvider).where((t) => t.id == tabId).firstOrNull;
    if (tab == null) return;

    if (tab.isDirty) {
      if (!mounted) return;
      final action = await ScribeSaveDialog.show(context, tab: tab);
      switch (action) {
        case ScribeSaveAction.save:
          await _saveTab(tab);
          ref.read(scribeTabsProvider.notifier).closeTab(tabId);
        case ScribeSaveAction.dontSave:
          ref.read(scribeTabsProvider.notifier).closeTab(tabId);
        case ScribeSaveAction.cancel:
          return;
      }
    } else {
      ref.read(scribeTabsProvider.notifier).closeTab(tabId);
    }
  }

  /// Closes all tabs except the specified one. Shows batch save dialog
  /// if any tabs being removed are dirty.
  Future<void> _handleCloseOtherTabs(String tabId) async {
    final tabs = ref.read(scribeTabsProvider);
    final dirtyOthers =
        tabs.where((t) => t.id != tabId && t.isDirty).toList();

    if (dirtyOthers.isNotEmpty) {
      if (!mounted) return;
      final result = await ScribeSaveDialog.showBatch(
        context,
        dirtyTabs: dirtyOthers,
      );
      switch (result.action) {
        case ScribeSaveAction.save:
          for (final id in result.selectedTabIds) {
            final t = tabs.where((t) => t.id == id).firstOrNull;
            if (t != null) await _saveTab(t);
          }
          ref.read(scribeTabsProvider.notifier).closeOtherTabs(tabId);
        case ScribeSaveAction.dontSave:
          ref.read(scribeTabsProvider.notifier).closeOtherTabs(tabId);
        case ScribeSaveAction.cancel:
          return;
      }
    } else {
      ref.read(scribeTabsProvider.notifier).closeOtherTabs(tabId);
    }
  }

  /// Closes all tabs. Shows batch save dialog if any are dirty.
  Future<void> _handleCloseAllTabs() async {
    final tabs = ref.read(scribeTabsProvider);
    final dirtyTabs = tabs.where((t) => t.isDirty).toList();

    if (dirtyTabs.isNotEmpty) {
      if (!mounted) return;
      final result = await ScribeSaveDialog.showBatch(
        context,
        dirtyTabs: dirtyTabs,
      );
      switch (result.action) {
        case ScribeSaveAction.save:
          for (final id in result.selectedTabIds) {
            final t = tabs.where((t) => t.id == id).firstOrNull;
            if (t != null) await _saveTab(t);
          }
          ref.read(scribeTabsProvider.notifier).closeAllTabs();
        case ScribeSaveAction.dontSave:
          ref.read(scribeTabsProvider.notifier).closeAllTabs();
        case ScribeSaveAction.cancel:
          return;
      }
    } else {
      ref.read(scribeTabsProvider.notifier).closeAllTabs();
    }
  }

  /// Closes all tabs to the right of the specified one.
  Future<void> _handleCloseToRight(String tabId) async {
    final tabs = ref.read(scribeTabsProvider);
    final index = tabs.indexWhere((t) => t.id == tabId);
    if (index < 0 || index >= tabs.length - 1) return;

    final rightTabs = tabs.sublist(index + 1);
    final dirtyRight = rightTabs.where((t) => t.isDirty).toList();

    if (dirtyRight.isNotEmpty) {
      if (!mounted) return;
      final result = await ScribeSaveDialog.showBatch(
        context,
        dirtyTabs: dirtyRight,
      );
      switch (result.action) {
        case ScribeSaveAction.save:
          for (final id in result.selectedTabIds) {
            final t = tabs.where((t) => t.id == id).firstOrNull;
            if (t != null) await _saveTab(t);
          }
          ref.read(scribeTabsProvider.notifier).closeTabsToRight(tabId);
        case ScribeSaveAction.dontSave:
          ref.read(scribeTabsProvider.notifier).closeTabsToRight(tabId);
        case ScribeSaveAction.cancel:
          return;
      }
    } else {
      ref.read(scribeTabsProvider.notifier).closeTabsToRight(tabId);
    }
  }

  /// Closes all saved (non-dirty) tabs. No dialog needed.
  void _handleCloseSavedTabs() {
    ref.read(scribeTabsProvider.notifier).closeSavedTabs();
  }

  /// Reopens the most recently closed tab via Ctrl+Shift+T.
  void _handleReopenLastClosed() {
    ref.read(scribeTabsProvider.notifier).reopenLastClosed();
  }

  // ---------------------------------------------------------------------------
  // File path operations
  // ---------------------------------------------------------------------------

  /// Copies the file path of the given tab to the clipboard.
  void _handleCopyFilePath(String tabId) {
    final tab =
        ref.read(scribeTabsProvider).where((t) => t.id == tabId).firstOrNull;
    if (tab?.filePath == null) return;
    Clipboard.setData(ClipboardData(text: tab!.filePath!));
  }

  /// Reveals the tab's file in Finder (macOS) or file manager.
  void _handleRevealInFinder(String tabId) {
    final tab =
        ref.read(scribeTabsProvider).where((t) => t.id == tabId).firstOrNull;
    if (tab?.filePath == null) return;

    if (Platform.isMacOS) {
      Process.run('open', ['-R', tab!.filePath!]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [File(tab!.filePath!).parent.path]);
    }
  }

  // ---------------------------------------------------------------------------
  // Drag and drop (CS-004)
  // ---------------------------------------------------------------------------

  /// Handles files dropped onto the Scribe editor.
  Future<void> _handleFilesDropped(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        final content = await file.readAsString();
        final tab = ScribeTab.fromFile(filePath: path, content: content);
        ref.read(scribeTabsProvider.notifier).openTab(
              title: tab.title,
              content: tab.content,
              language: tab.language,
              filePath: tab.filePath,
            );
        await _trackRecentFile(path);
      } on FormatException catch (e) {
        log.w(_tag, 'Skipping binary/unreadable dropped file: $path', e);
      } on FileSystemException catch (e) {
        log.w(_tag, 'Failed to read dropped file: $path', e);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Tab reordering and sidebar
  // ---------------------------------------------------------------------------

  /// Reorders tabs via drag-drop.
  void _handleReorderTabs(int oldIndex, int newIndex) {
    ref.read(scribeTabsProvider.notifier).reorderTabs(oldIndex, newIndex);
  }

  /// Toggles the sidebar visibility.
  void _handleToggleSidebar() {
    ref.read(scribeSidebarVisibleProvider.notifier).state =
        !ref.read(scribeSidebarVisibleProvider);
  }

  /// Toggles the settings panel visibility.
  void _handleToggleSettingsPanel() {
    ref.read(scribeSettingsPanelVisibleProvider.notifier).state =
        !ref.read(scribeSettingsPanelVisibleProvider);
  }

  // ---------------------------------------------------------------------------
  // Auto-save (CS-005)
  // ---------------------------------------------------------------------------

  /// Updates the auto-save timer when settings change.
  ///
  /// Compares cached values to avoid unnecessary timer recreation.
  void _updateAutoSaveTimer(ScribeSettings settings) {
    if (settings.autoSave == _autoSaveEnabled &&
        settings.autoSaveIntervalSeconds == _autoSaveIntervalSeconds) {
      return;
    }

    _autoSaveEnabled = settings.autoSave;
    _autoSaveIntervalSeconds = settings.autoSaveIntervalSeconds;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;

    if (_autoSaveEnabled) {
      _autoSaveTimer = Timer.periodic(
        Duration(seconds: _autoSaveIntervalSeconds),
        (_) => _handleAutoSave(),
      );
    }
  }

  /// Saves all dirty tabs that have a file path (auto-save tick).
  void _handleAutoSave() {
    final tabs = ref.read(scribeTabsProvider);
    for (final tab in tabs) {
      if (tab.isDirty && tab.filePath != null) {
        _saveTab(tab);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Markdown preview (CS-006)
  // ---------------------------------------------------------------------------

  /// Returns the current [ScribePreviewMode] for the given tab.
  ScribePreviewMode _getPreviewMode(String tabId) {
    final modes = ref.read(scribePreviewModeProvider);
    final modeStr = modes[tabId] ?? 'editor';
    return ScribePreviewMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => ScribePreviewMode.editor,
    );
  }

  /// Returns the current split ratio for the given tab.
  double _getSplitRatio(String tabId) {
    final ratios = ref.read(scribeSplitRatioProvider);
    return ratios[tabId] ?? AppConstants.scribeDefaultSplitRatio;
  }

  /// Handles preview mode changes from the controls.
  void _handlePreviewModeChanged(String tabId, ScribePreviewMode mode) {
    final modes = {...ref.read(scribePreviewModeProvider)};
    modes[tabId] = mode.name;
    ref.read(scribePreviewModeProvider.notifier).state = modes;
  }

  /// Handles split ratio changes from the divider drag.
  void _handleSplitRatioChanged(String tabId, double ratio) {
    final ratios = {...ref.read(scribeSplitRatioProvider)};
    ratios[tabId] = ratio;
    ref.read(scribeSplitRatioProvider.notifier).state = ratios;
  }

  /// Toggles the preview mode for the active tab via Ctrl+Shift+V.
  ///
  /// Cycles: editor → split → preview → editor. Only applies to
  /// markdown tabs; no-op for non-markdown tabs.
  void _handleTogglePreview() {
    final activeTab = ref.read(activeScribeTabProvider);
    if (activeTab == null || activeTab.language != 'markdown') return;

    final current = _getPreviewMode(activeTab.id);
    final next = switch (current) {
      ScribePreviewMode.editor => ScribePreviewMode.split,
      ScribePreviewMode.split => ScribePreviewMode.preview,
      ScribePreviewMode.preview => ScribePreviewMode.editor,
    };
    _handlePreviewModeChanged(activeTab.id, next);
  }

  /// Handles heading selection from the TOC dropdown.
  void _handleHeadingSelected(int line) {
    // Update cursor position to the heading line.
    setState(() {
      _cursorLine = line;
      _cursorColumn = 0;
    });
  }

  /// Builds the editor area, wrapping in [ScribeMarkdownSplit] for
  /// markdown tabs.
  Widget _buildEditorWithPreview(ScribeTab tab, ScribeSettings settings) {
    final editorWidget = _EditorArea(
      key: ValueKey('editor-${tab.id}'),
      tab: tab,
      settings: settings,
      onChanged: (value) => _handleContentChanged(tab, value),
      onCursorChanged: _handleCursorChanged,
      onSelectionChanged: _handleSelectionChanged,
    );

    if (tab.language != 'markdown') {
      return editorWidget;
    }

    final mode = _getPreviewMode(tab.id);
    final ratio = _getSplitRatio(tab.id);

    return ScribeMarkdownSplit(
      key: ValueKey('split-${tab.id}'),
      editor: editorWidget,
      content: tab.content,
      mode: mode,
      splitRatio: ratio,
      onSplitRatioChanged: (r) => _handleSplitRatioChanged(tab.id, r),
    );
  }

  // ---------------------------------------------------------------------------
  // Diff comparison (CS-007)
  // ---------------------------------------------------------------------------

  /// Opens the diff selector with a pre-selected left tab.
  void _handleCompareWith(String tabId) {
    setState(() {
      _showDiffSelector = true;
      _diffLeftTabId = tabId;
    });
  }

  /// Closes the diff selector and clears diff state.
  void _handleCloseDiffSelector() {
    setState(() {
      _showDiffSelector = false;
      _diffLeftTabId = null;
    });
    ref.read(scribeDiffStateProvider.notifier).state = null;
  }

  /// Starts a diff comparison between two tabs.
  void _handleStartCompare(String leftTabId, String rightTabId) {
    final tabs = ref.read(scribeTabsProvider);
    final leftTab =
        tabs.where((t) => t.id == leftTabId).firstOrNull;
    final rightTab =
        tabs.where((t) => t.id == rightTabId).firstOrNull;
    if (leftTab == null || rightTab == null) return;

    final diffService = ref.read(scribeDiffServiceProvider);
    final diffState = diffService.computeDiff(
      leftTabId: leftTabId,
      rightTabId: rightTabId,
      leftText: leftTab.content,
      rightText: rightTab.content,
    );

    ref.read(scribeDiffStateProvider.notifier).state = diffState;
  }

  /// Builds the main content area, showing either the diff editor or
  /// the regular editor/preview, with optional sidebar and panels.
  Widget _buildMainContent({
    required List<ScribeTab> tabs,
    required ScribeTab activeTab,
    required ScribeSettings settings,
    required bool sidebarVisible,
    required bool settingsPanelVisible,
    required bool recentFilesPanelVisible,
  }) {
    final diffState = ref.watch(scribeDiffStateProvider);

    return Row(
      children: [
        if (sidebarVisible)
          ScribeSidebar(
            tabs: tabs,
            activeTabId: activeTab.id,
            onTabSelected: _handleTabSelected,
          ),
        if (sidebarVisible)
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: CodeOpsColors.border,
          ),
        Expanded(
          child: diffState != null
              ? _buildDiffView(diffState, tabs)
              : _buildEditorWithPreview(activeTab, settings),
        ),
        if (settingsPanelVisible) ...[
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: CodeOpsColors.border,
          ),
          ScribeSettingsPanel(
            onClose: _handleToggleSettingsPanel,
          ),
        ],
        // Recent files panel (CS-008).
        if (recentFilesPanelVisible) ...[
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: CodeOpsColors.border,
          ),
          ScribeRecentFiles(
            recentFiles: ref.watch(scribeRecentFilesProvider),
            onOpen: _handleOpenRecentFile,
            onRemove: _handleRemoveRecentFile,
            onClearAll: _handleClearRecentFiles,
            onClose: _handleToggleRecentFiles,
          ),
        ],
      ],
    );
  }

  /// Builds the diff editor view.
  Widget _buildDiffView(DiffState diffState, List<ScribeTab> tabs) {
    final viewMode = ref.watch(scribeDiffViewModeProvider);
    final collapseUnchanged = ref.watch(scribeCollapseUnchangedProvider);
    final diffService = ref.read(scribeDiffServiceProvider);

    final displayLines = collapseUnchanged
        ? diffService.collapseUnchanged(diffState.lines)
        : diffState.lines;

    final leftTab =
        tabs.where((t) => t.id == diffState.leftTabId).firstOrNull;
    final rightTab =
        tabs.where((t) => t.id == diffState.rightTabId).firstOrNull;

    return ScribeDiffEditor(
      diffState: diffState,
      viewMode: viewMode,
      collapseUnchanged: collapseUnchanged,
      displayLines: displayLines,
      onViewModeChanged: (mode) =>
          ref.read(scribeDiffViewModeProvider.notifier).state = mode,
      onCollapseChanged: (value) =>
          ref.read(scribeCollapseUnchangedProvider.notifier).state = value,
      leftTitle: leftTab?.title,
      rightTitle: rightTab?.title,
    );
  }

  // ---------------------------------------------------------------------------
  // Session persistence (CS-008)
  // ---------------------------------------------------------------------------

  /// Toggles the recent files panel via Ctrl+Shift+O.
  void _handleToggleRecentFiles() {
    final current = ref.read(scribeRecentFilesPanelVisibleProvider);
    ref.read(scribeRecentFilesPanelVisibleProvider.notifier).state = !current;
    // Close quick-open if switching to recent files.
    if (!current) {
      ref.read(scribeQuickOpenVisibleProvider.notifier).state = false;
    }
  }

  /// Toggles the quick-open overlay via Ctrl+P.
  void _handleToggleQuickOpen() {
    final current = ref.read(scribeQuickOpenVisibleProvider);
    ref.read(scribeQuickOpenVisibleProvider.notifier).state = !current;
    // Close recent files if switching to quick-open.
    if (!current) {
      ref.read(scribeRecentFilesPanelVisibleProvider.notifier).state = false;
    }
  }

  /// Closes the quick-open overlay.
  void _handleCloseQuickOpen() {
    ref.read(scribeQuickOpenVisibleProvider.notifier).state = false;
  }

  /// Opens a file from the recent files list.
  Future<void> _handleOpenRecentFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        log.w(_tag, 'Recent file no longer exists: $filePath');
        return;
      }
      final content = await file.readAsString();
      final tab = ScribeTab.fromFile(filePath: filePath, content: content);
      ref.read(scribeTabsProvider.notifier).openTab(
            title: tab.title,
            content: tab.content,
            language: tab.language,
            filePath: tab.filePath,
          );
    } on FormatException catch (e) {
      log.w(_tag, 'Cannot open binary file: $filePath', e);
    } on FileSystemException catch (e) {
      log.w(_tag, 'Cannot read file: $filePath', e);
    }
  }

  /// Removes a file from the recent files list.
  Future<void> _handleRemoveRecentFile(String filePath) async {
    final recentFiles = [...ref.read(scribeRecentFilesProvider)];
    recentFiles.remove(filePath);
    ref.read(scribeRecentFilesProvider.notifier).state = recentFiles;
    final fileService = ref.read(scribeFileServiceProvider);
    await fileService.clearRecentFiles();
    for (final f in recentFiles) {
      await fileService.addRecentFile(f);
    }
  }

  /// Clears all recent files.
  Future<void> _handleClearRecentFiles() async {
    ref.read(scribeRecentFilesProvider.notifier).state = [];
    await ref.read(scribeFileServiceProvider).clearRecentFiles();
  }

  /// Builds the list of quick-open items from open tabs and recent files.
  List<QuickOpenItem> _buildQuickOpenItems() {
    final tabs = ref.read(scribeTabsProvider);
    final recentFiles = ref.read(scribeRecentFilesProvider);
    final items = <QuickOpenItem>[];

    // Open tabs first.
    for (final tab in tabs) {
      items.add(QuickOpenItem(
        title: tab.title,
        subtitle: tab.filePath ?? 'Unsaved',
        id: tab.id,
        isOpenTab: true,
      ));
    }

    // Recent files (skip any that are already open).
    final openPaths = tabs.map((t) => t.filePath).whereType<String>().toSet();
    for (final path in recentFiles) {
      if (openPaths.contains(path)) continue;
      final lastSlash = path.lastIndexOf('/');
      final fileName = lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
      items.add(QuickOpenItem(
        title: fileName,
        subtitle: path,
        id: path,
        isOpenTab: false,
      ));
    }

    return items;
  }

  /// Handles selecting an item from the quick-open overlay.
  void _handleQuickOpenSelect(QuickOpenItem item) {
    _handleCloseQuickOpen();

    if (item.isOpenTab) {
      // Switch to the open tab.
      _handleTabSelected(item.id);
    } else {
      // Open from recent files.
      _handleOpenRecentFile(item.id);
    }
  }

  /// Reloads the file content from disk for the given tab.
  Future<void> _handleReloadFromDisk(String tabId) async {
    final tab = ref.read(scribeTabsProvider)
        .where((t) => t.id == tabId)
        .firstOrNull;
    if (tab?.filePath == null) return;

    try {
      final content = await File(tab!.filePath!).readAsString();
      ref.read(scribeTabsProvider.notifier).updateContent(tabId, content);
      ref.read(scribeTabsProvider.notifier).markClean(tabId);
    } on FileSystemException catch (e) {
      log.e(_tag, 'Failed to reload file: ${tab!.filePath}', e);
    }

    // Clear the changed flag.
    final changed = {...ref.read(scribeFileChangedTabsProvider)};
    changed.remove(tabId);
    ref.read(scribeFileChangedTabsProvider.notifier).state = changed;
  }

  /// Keeps the current tab content and dismisses the file-changed banner.
  void _handleKeepContent(String tabId) {
    final changed = {...ref.read(scribeFileChangedTabsProvider)};
    changed.remove(tabId);
    ref.read(scribeFileChangedTabsProvider.notifier).state = changed;
  }

  // ---------------------------------------------------------------------------
  // Find & Replace (CS-009)
  // ---------------------------------------------------------------------------

  /// Opens the find panel (Ctrl+F).
  void _handleToggleFind() {
    final current = ref.read(scribeFindPanelVisibleProvider);
    ref.read(scribeFindPanelVisibleProvider.notifier).state = !current;
    if (current) {
      ref.read(scribeFindReplaceVisibleProvider.notifier).state = false;
    }
  }

  /// Opens the find and replace panel (Ctrl+H).
  void _handleToggleFindReplace() {
    ref.read(scribeFindPanelVisibleProvider.notifier).state = true;
    ref.read(scribeFindReplaceVisibleProvider.notifier).state = true;
  }

  /// Closes the find panel.
  void _handleCloseFind() {
    ref.read(scribeFindPanelVisibleProvider.notifier).state = false;
    ref.read(scribeFindReplaceVisibleProvider.notifier).state = false;
  }

  /// Toggles the replace row within the find panel.
  void _handleToggleFindReplaceRow() {
    final current = ref.read(scribeFindReplaceVisibleProvider);
    ref.read(scribeFindReplaceVisibleProvider.notifier).state = !current;
  }

  // ---------------------------------------------------------------------------
  // Go to Line (CS-009)
  // ---------------------------------------------------------------------------

  /// Opens the Go to Line dialog (Ctrl+G).
  Future<void> _handleGoToLine() async {
    final activeTab = ref.read(activeScribeTabProvider);
    if (activeTab == null) return;

    // Estimate line count from content.
    final lineCount = '\n'.allMatches(activeTab.content).length + 1;
    if (!mounted) return;

    final line = await ScribeGoToLineDialog.show(
      context,
      totalLines: lineCount,
      currentLine: _cursorLine + 1,
    );
    if (line != null) {
      setState(() {
        _cursorLine = line;
        _cursorColumn = 0;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Command Palette (CS-009)
  // ---------------------------------------------------------------------------

  /// Toggles the command palette (Ctrl+Shift+P).
  void _handleToggleCommandPalette() {
    final current = ref.read(scribeCommandPaletteVisibleProvider);
    ref.read(scribeCommandPaletteVisibleProvider.notifier).state = !current;
    // Close quick-open if opening command palette.
    if (!current) {
      ref.read(scribeQuickOpenVisibleProvider.notifier).state = false;
    }
  }

  /// Closes the command palette.
  void _handleCloseCommandPalette() {
    ref.read(scribeCommandPaletteVisibleProvider.notifier).state = false;
  }

  /// Handles a command selected from the command palette.
  void _handleCommandPaletteSelect(ScribeCommand command) {
    _handleCloseCommandPalette();

    final handlers = <String, VoidCallback>{
      'file.new': _handleNewTab,
      'file.open': _handleOpenFile,
      'file.newDialog': _handleNewFileDialog,
      'file.openUrl': _handleOpenUrlDialog,
      'file.save': _handleSave,
      'file.saveAs': _handleSaveAs,
      'file.saveAll': _handleSaveAll,
      'editor.find': _handleToggleFind,
      'editor.findReplace': _handleToggleFindReplace,
      'editor.goToLine': _handleGoToLine,
      'view.sidebar': _handleToggleSidebar,
      'view.preview': _handleTogglePreview,
      'view.recentFiles': _handleToggleRecentFiles,
      'view.quickOpen': _handleToggleQuickOpen,
      'view.commandPalette': _handleToggleCommandPalette,
      'view.settings': _handleToggleSettingsPanel,
      'view.shortcutsHelp': _handleToggleShortcutsHelp,
      'tabs.close': _handleCloseActiveTab,
      'tabs.next': _handleNextTab,
      'tabs.prev': _handlePrevTab,
      'tabs.reopen': _handleReopenLastClosed,
      'tabs.closeAll': _handleCloseAllTabs,
      'tabs.closeSaved': _handleCloseSavedTabs,
    };

    handlers[command.id]?.call();
  }

  // ---------------------------------------------------------------------------
  // Keyboard Shortcuts Help (CS-009)
  // ---------------------------------------------------------------------------

  /// Toggles the shortcuts help overlay (Ctrl+Shift+?).
  void _handleToggleShortcutsHelp() {
    final current = ref.read(scribeShortcutsHelpVisibleProvider);
    ref.read(scribeShortcutsHelpVisibleProvider.notifier).state = !current;
  }

  /// Closes the shortcuts help overlay.
  void _handleCloseShortcutsHelp() {
    ref.read(scribeShortcutsHelpVisibleProvider.notifier).state = false;
  }

  // ---------------------------------------------------------------------------
  // CS-004 Dialog wiring (CS-009)
  // ---------------------------------------------------------------------------

  /// Opens the New File dialog (Ctrl+Shift+N / long-press on "+").
  Future<void> _handleNewFileDialog() async {
    if (!mounted) return;
    final result = await ScribeNewFileDialog.show(context);
    if (result == null) return;

    ref.read(scribeTabsProvider.notifier).openTab(
          title: result.fileName,
          language: result.language,
        );
  }

  /// Opens the Open from URL dialog (long-press on "+").
  Future<void> _handleOpenUrlDialog() async {
    if (!mounted) return;
    final fileService = ref.read(scribeFileServiceProvider);
    final result = await ScribeUrlDialog.show(
      context,
      fetchContent: fileService.readFromUrl,
    );
    if (result == null) return;

    // Extract filename from URL.
    final uri = Uri.tryParse(result.url);
    final segments = uri?.pathSegments ?? [];
    final fileName = segments.isNotEmpty ? segments.last : 'untitled';
    final language = ScribeLanguage.fromFileName(fileName);

    ref.read(scribeTabsProvider.notifier).openTab(
          title: fileName,
          content: result.content,
          language: language,
        );
  }

  // ---------------------------------------------------------------------------
  // Editor callbacks
  // ---------------------------------------------------------------------------

  /// Handles content changes from the editor.
  void _handleContentChanged(ScribeTab tab, String newContent) {
    ref.read(scribeTabsProvider.notifier).updateContent(tab.id, newContent);
  }

  /// Handles cursor position changes from the editor.
  void _handleCursorChanged(int line, int column) {
    setState(() {
      _cursorLine = line;
      _cursorColumn = column;
      _selectedChars = 0;
      _selectedLines = 0;
    });
    // Persist cursor position (debounced via provider).
    final activeId = ref.read(activeScribeTabIdProvider);
    if (activeId != null) {
      ref
          .read(scribeTabsProvider.notifier)
          .updateCursorPosition(activeId, line, column);
    }
  }

  /// Handles selection changes from the editor.
  void _handleSelectionChanged(int chars, int lines) {
    setState(() {
      _selectedChars = chars;
      _selectedLines = lines;
    });
  }

  /// Handles language mode changes from the status bar.
  void _handleLanguageChanged(ScribeTab tab, String newLanguage) {
    ref.read(scribeTabsProvider.notifier).updateLanguage(tab.id, newLanguage);
  }

  // ---------------------------------------------------------------------------
  // Save helpers (CS-004)
  // ---------------------------------------------------------------------------

  /// Saves the tab content to its file path.
  ///
  /// If the tab has no file path, triggers Save As. On success, marks
  /// the tab clean and tracks the file in recent files.
  Future<void> _saveTab(ScribeTab tab) async {
    if (tab.filePath == null) {
      await _saveTabAs(tab);
      return;
    }

    final fileService = ref.read(scribeFileServiceProvider);
    final success = await fileService.saveFile(tab);
    if (success) {
      ref.read(scribeTabsProvider.notifier).markClean(tab.id);
      await _trackRecentFile(tab.filePath!);
    }
  }

  /// Opens a Save As dialog for [tab] and writes to the chosen path.
  ///
  /// Updates the tab's file path, title, and language on success.
  Future<void> _saveTabAs(ScribeTab tab) async {
    final fileService = ref.read(scribeFileServiceProvider);
    final newPath = await fileService.saveFileAs(tab);
    if (newPath == null) return;

    // Update tab with new file path and detected language.
    final language = ScribeLanguage.fromFileName(newPath);
    ref.read(scribeTabsProvider.notifier).updateTabFilePath(tab.id, newPath);
    ref.read(scribeTabsProvider.notifier).updateLanguage(tab.id, language);
    await _trackRecentFile(newPath);
  }

  /// Adds a file path to recent files and persists.
  Future<void> _trackRecentFile(String filePath) async {
    final fileService = ref.read(scribeFileServiceProvider);
    await fileService.addRecentFile(filePath);
    final updated = await fileService.loadRecentFiles();
    ref.read(scribeRecentFilesProvider.notifier).state = updated;
  }
}

/// Gear icon button to toggle the settings panel.
class _SettingsGearButton extends StatelessWidget {
  /// Whether the settings panel is currently open.
  final bool isActive;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  const _SettingsGearButton({
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(right: 8),
      color: CodeOpsColors.surface,
      child: IconButton(
        icon: Icon(
          Icons.settings,
          size: 16,
          color: isActive
              ? CodeOpsColors.primary
              : CodeOpsColors.textTertiary,
        ),
        onPressed: onPressed,
        splashRadius: 14,
        tooltip: 'Editor settings',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }
}

/// The editor area that renders a [ScribeEditor] for the active tab.
class _EditorArea extends StatefulWidget {
  final ScribeTab tab;
  final ScribeSettings settings;
  final ValueChanged<String> onChanged;
  final void Function(int line, int column) onCursorChanged;
  final void Function(int chars, int lines)? onSelectionChanged;

  const _EditorArea({
    super.key,
    required this.tab,
    required this.settings,
    required this.onChanged,
    required this.onCursorChanged,
    this.onSelectionChanged,
  });

  @override
  State<_EditorArea> createState() => _EditorAreaState();
}

class _EditorAreaState extends State<_EditorArea> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: CodeOpsColors.background,
      child: ScribeEditor(
        content: widget.tab.content,
        language: widget.tab.language,
        fontSize: widget.settings.fontSize,
        fontFamily: widget.settings.fontFamily,
        tabSize: widget.settings.tabSize,
        insertSpaces: widget.settings.insertSpaces,
        wordWrap: widget.settings.wordWrap,
        showLineNumbers: widget.settings.showLineNumbers,
        showMinimap: widget.settings.showMinimap,
        themeMode: widget.settings.themeMode,
        highlightActiveLine: widget.settings.highlightActiveLine,
        showBracketMatching: widget.settings.bracketMatching,
        autoCloseBrackets: widget.settings.autoCloseBrackets,
        onChanged: widget.onChanged,
        onCursorChanged: widget.onCursorChanged,
        onSelectionChanged: widget.onSelectionChanged,
      ),
    );
  }
}
