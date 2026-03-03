/// Request builder center pane for the Courier module.
///
/// Renders the URL bar (method dropdown + URL field + Send/Cancel button +
/// Save dropdown), the request sub-tab bar (Params | Headers | Body | Auth |
/// Scripts | Tests | Settings), and the tab content area.
///
/// Sub-tab content panels for Params, Headers, Body, Auth, Scripts, and Tests
/// are stubs — CCF-004+ fills in each editor. The Settings panel is fully
/// implemented via [RequestSettingsPanel].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/courier_enums.dart';
import '../../models/courier_models.dart';
import '../../providers/courier_providers.dart';
import '../../providers/courier_ui_providers.dart';
import '../../providers/team_providers.dart';
import '../../services/courier/http_execution_service.dart';
import '../../theme/colors.dart';
import 'request_settings_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RequestBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Center pane of the Courier three-pane layout.
///
/// Shows an empty hint when no request tab is active, or the full builder UI
/// (URL bar + sub-tabs + content) when a tab is open.
class RequestBuilder extends ConsumerStatefulWidget {
  /// Creates a [RequestBuilder].
  const RequestBuilder({super.key});

  @override
  ConsumerState<RequestBuilder> createState() => _RequestBuilderState();
}

class _RequestBuilderState extends ConsumerState<RequestBuilder>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  static const _subTabs = [
    'Params',
    'Headers',
    'Body',
    'Auth',
    'Scripts',
    'Tests',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: _subTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTabId = ref.watch(activeRequestTabProvider);

    if (activeTabId == null) {
      return const _NoTabHint();
    }

    final tabs = ref.watch(openRequestTabsProvider);
    final activeTab =
        tabs.cast<RequestTab?>().firstWhere((t) => t?.id == activeTabId,
            orElse: () => null);

    if (activeTab == null) {
      return const _NoTabHint();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // URL bar.
        _UrlBar(activeTab: activeTab),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Sub-tab bar.
        _SubTabBar(controller: _subTabController),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Tab content.
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              _ParamsPanel(),
              _HeadersPanel(),
              _BodyPanel(),
              _AuthPanel(),
              _ScriptsPanel(),
              _TestsPanel(),
              RequestSettingsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NoTabHint
// ─────────────────────────────────────────────────────────────────────────────

class _NoTabHint extends StatelessWidget {
  const _NoTabHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.http, size: 48, color: CodeOpsColors.textTertiary),
          SizedBox(height: 12),
          Text(
            'No request open',
            style: TextStyle(
              fontSize: 15,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Click + in the tab bar to create a new request,\n'
            'or select one from the collection sidebar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UrlBar
// ─────────────────────────────────────────────────────────────────────────────

/// The top bar with method dropdown, URL field, Send/Cancel button, and
/// Save dropdown.
class _UrlBar extends ConsumerStatefulWidget {
  final RequestTab activeTab;

  const _UrlBar({required this.activeTab});

  @override
  ConsumerState<_UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends ConsumerState<_UrlBar> {
  late final TextEditingController _urlController;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    final editState = ref.read(activeRequestStateProvider);
    _urlController = TextEditingController(text: editState.url);
  }

  @override
  void didUpdateWidget(_UrlBar old) {
    super.didUpdateWidget(old);
    // When the active tab changes, sync the URL field from provider state.
    if (old.activeTab.id != widget.activeTab.id) {
      final editState = ref.read(activeRequestStateProvider);
      _urlController.text = editState.url;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // ── Send / Cancel ─────────────────────────────────────────────────────────

  Future<void> _send() async {
    final editState = ref.read(activeRequestStateProvider);
    final url = editState.url.trim();
    if (url.isEmpty) return;

    final execService = ref.read(httpExecutionServiceProvider);
    final execNotifier = ref.read(executionStateProvider.notifier);

    execNotifier.setRunning();

    final result = await execService.execute(HttpExecutionRequest(
      method: editState.method,
      url: url,
      followRedirects: editState.settings.followRedirects,
      timeoutMs: editState.settings.timeoutMs,
      sslVerify: editState.settings.sslVerify,
      proxyUrl: editState.settings.proxyUrl,
    ));

    ref.read(executionResultProvider.notifier).state = result;

    if (result.error != null) {
      execNotifier.setError(result.error!);
    } else {
      execNotifier.setDone();
    }
  }

  void _cancel() {
    ref.read(httpExecutionServiceProvider).cancel();
    ref.read(executionStateProvider.notifier).reset();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final tab = widget.activeTab;
    if (tab.requestId == null) {
      // New request — show save dialog.
      await _showSaveDialog();
    } else {
      // Existing request — auto-save via PUT.
      await _autoSave(tab.requestId!);
    }
  }

  Future<void> _showSaveDialog() async {
    final nameController =
        TextEditingController(text: widget.activeTab.name);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Save Request',
          style: TextStyle(color: CodeOpsColors.textPrimary),
        ),
        content: SizedBox(
          width: 360,
          child: TextField(
            key: const Key('save_request_name_field'),
            controller: nameController,
            autofocus: true,
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Request Name',
              labelStyle:
                  const TextStyle(color: CodeOpsColors.textSecondary),
              filled: true,
              fillColor: CodeOpsColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.primary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // CCF-004+ wires up the actual POST with folder selection.
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
  }

  Future<void> _autoSave(String requestId) async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;
    final api = ref.read(courierApiProvider);
    final editState = ref.read(activeRequestStateProvider);
    try {
      await api.updateRequest(
        teamId,
        requestId,
        UpdateRequestRequest(
          name: widget.activeTab.name,
          method: editState.method,
          url: editState.url,
        ),
      );
      ref.read(activeRequestStateProvider.notifier).markClean();
      // Sync dirty flag on the tab.
      final tabs = ref.read(openRequestTabsProvider);
      final updated = tabs.map((t) {
        return t.id == widget.activeTab.id ? t.copyWith(isDirty: false) : t;
      }).toList();
      ref.read(openRequestTabsProvider.notifier).state = updated;
    } catch (_) {
      // Silently ignore auto-save failures — user can retry via Save button.
    }
  }

  void _scheduleAutoSave() {
    if (widget.activeTab.requestId == null) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer =
        Timer(const Duration(milliseconds: 500), () => _autoSave(widget.activeTab.requestId!));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(activeRequestStateProvider);
    final execStatus =
        ref.watch(executionStateProvider.select((s) => s.status));
    final isRunning = execStatus == ExecutionStatus.running;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Method dropdown.
          _MethodDropdown(
            method: editState.method,
            onChanged: (m) {
              ref.read(activeRequestStateProvider.notifier).setMethod(m);
              _syncMethodToTab(m);
              _scheduleAutoSave();
            },
          ),
          const SizedBox(width: 8),
          // URL field.
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  if (!isRunning) _send();
                },
              },
              child: TextField(
                key: const Key('url_field'),
                controller: _urlController,
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textPrimary,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'Enter URL or paste cURL',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: CodeOpsColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: CodeOpsColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
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
                    borderSide:
                        const BorderSide(color: CodeOpsColors.primary),
                  ),
                ),
                onChanged: (v) {
                  ref.read(activeRequestStateProvider.notifier).setUrl(v);
                  _syncUrlToTab(v);
                  _scheduleAutoSave();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / Cancel button.
          isRunning
              ? OutlinedButton(
                  key: const Key('cancel_button'),
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CodeOpsColors.error,
                    side: const BorderSide(color: CodeOpsColors.error),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )
              : ElevatedButton(
                  key: const Key('send_button'),
                  onPressed:
                      editState.url.trim().isNotEmpty ? _send : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CodeOpsColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        CodeOpsColors.primary.withAlpha(76),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
          const SizedBox(width: 4),
          // Save dropdown.
          _SaveDropdown(onSave: _save),
        ],
      ),
    );
  }

  void _syncMethodToTab(CourierHttpMethod method) {
    final tabs = ref.read(openRequestTabsProvider);
    final updated = tabs.map((t) {
      return t.id == widget.activeTab.id
          ? t.copyWith(method: method, isDirty: true)
          : t;
    }).toList();
    ref.read(openRequestTabsProvider.notifier).state = updated;
  }

  void _syncUrlToTab(String url) {
    final tabs = ref.read(openRequestTabsProvider);
    final updated = tabs.map((t) {
      return t.id == widget.activeTab.id
          ? t.copyWith(url: url, isDirty: true)
          : t;
    }).toList();
    ref.read(openRequestTabsProvider.notifier).state = updated;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MethodDropdown
// ─────────────────────────────────────────────────────────────────────────────

class _MethodDropdown extends StatelessWidget {
  final CourierHttpMethod method;
  final ValueChanged<CourierHttpMethod> onChanged;

  const _MethodDropdown({required this.method, required this.onChanged});

  static Color _color(CourierHttpMethod m) => switch (m) {
        CourierHttpMethod.get => const Color(0xFF4ADE80),
        CourierHttpMethod.post => const Color(0xFFFBBF24),
        CourierHttpMethod.put => const Color(0xFF60A5FA),
        CourierHttpMethod.patch => const Color(0xFFA78BFA),
        CourierHttpMethod.delete => const Color(0xFFEF4444),
        CourierHttpMethod.head => const Color(0xFF34D399),
        CourierHttpMethod.options => const Color(0xFF94A3B8),
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(method);
    return Container(
      key: const Key('method_dropdown'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: CodeOpsColors.background,
        border: Border.all(color: CodeOpsColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CourierHttpMethod>(
          value: method,
          dropdownColor: CodeOpsColors.surfaceVariant,
          isDense: true,
          items: CourierHttpMethod.values
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    m.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _color(m),
                    ),
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (_) => CourierHttpMethod.values
              .map(
                (m) => Text(
                  m.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SaveDropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SaveDropdown extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveDropdown({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('save_dropdown'),
      tooltip: 'Save options',
      color: CodeOpsColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: CodeOpsColors.background,
          border: Border.all(color: CodeOpsColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: CodeOpsColors.textSecondary,
        ),
      ),
      onSelected: (v) {
        if (v == 'save') onSave();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'save',
          child: Text(
            'Save',
            style: TextStyle(fontSize: 13, color: CodeOpsColors.textPrimary),
          ),
        ),
        const PopupMenuItem(
          value: 'save_as',
          child: Text(
            'Save As…',
            style: TextStyle(fontSize: 13, color: CodeOpsColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubTabBar
// ─────────────────────────────────────────────────────────────────────────────

/// The request sub-tab bar (Params | Headers | Body | Auth | Scripts | Tests |
/// Settings) with optional badge counts and dot indicators.
class _SubTabBar extends ConsumerWidget {
  final TabController controller;

  const _SubTabBar({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Badge counts are stubs — CCF-004+ derives them from request sub-resources.
    const paramCount = 0;
    const headerCount = 0;
    const hasScripts = false;
    const hasTests = false;

    return Container(
      color: CodeOpsColors.surface,
      child: TabBar(
        key: const Key('sub_tab_bar'),
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: CodeOpsColors.primary,
        unselectedLabelColor: CodeOpsColors.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        indicatorColor: CodeOpsColors.primary,
        indicatorWeight: 2,
        tabs: [
          _subTab('Params', badge: paramCount > 0 ? paramCount : null),
          _subTab('Headers', badge: headerCount > 0 ? headerCount : null),
          _subTab('Body'),
          _subTab('Auth'),
          _subTab('Scripts', dot: hasScripts),
          _subTab('Tests', dot: hasTests),
          _subTab('Settings'),
        ],
      ),
    );
  }

  Tab _subTab(String label, {int? badge, bool dot = false}) {
    if (badge != null) {
      return Tab(
        height: 36,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: CodeOpsColors.primary.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
    if (dot) {
      return Tab(
        height: 36,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: CodeOpsColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    }
    return Tab(text: label, height: 36);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-tab content stubs (CCF-004+ implements each editor)
// ─────────────────────────────────────────────────────────────────────────────

class _ParamsPanel extends StatelessWidget {
  const _ParamsPanel();

  @override
  Widget build(BuildContext context) =>
      _StubPanel(key: const Key('params_panel'), label: 'Query Parameters');
}

class _HeadersPanel extends StatelessWidget {
  const _HeadersPanel();

  @override
  Widget build(BuildContext context) =>
      _StubPanel(key: const Key('headers_panel'), label: 'Headers');
}

class _BodyPanel extends StatelessWidget {
  const _BodyPanel();

  @override
  Widget build(BuildContext context) =>
      _StubPanel(key: const Key('body_panel'), label: 'Body');
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel();

  @override
  Widget build(BuildContext context) =>
      _StubPanel(key: const Key('auth_panel'), label: 'Authorization');
}

class _ScriptsPanel extends StatelessWidget {
  const _ScriptsPanel();

  @override
  Widget build(BuildContext context) =>
      _StubPanel(key: const Key('scripts_panel'), label: 'Scripts');
}

class _TestsPanel extends StatelessWidget {
  const _TestsPanel();

  @override
  Widget build(BuildContext context) =>
      _StubPanel(key: const Key('tests_panel'), label: 'Tests');
}

/// Placeholder shown for sub-tab panels not yet implemented.
class _StubPanel extends StatelessWidget {
  final String label;

  const _StubPanel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: CodeOpsColors.textTertiary,
        ),
      ),
    );
  }
}
