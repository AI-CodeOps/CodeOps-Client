/// Request builder center pane for the Courier module.
///
/// Renders the URL bar (method dropdown + URL field + Send/Cancel button +
/// Save dropdown), the request sub-tab bar (Params | Headers | Body | Auth |
/// Scripts | Tests | Settings), and the tab content area.
///
/// Sub-tab content panels: Params, Headers, Body, Auth, Scripts, Tests, and
/// Settings are all fully implemented.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/courier_enums.dart';
import '../../models/courier_models.dart';
import '../../models/registry_enums.dart';
import '../../providers/courier_providers.dart';
import '../../providers/courier_ui_providers.dart';
import '../../providers/team_providers.dart';
import '../../services/courier/curl_parser_service.dart';
import '../../services/courier/http_execution_service.dart';
import '../../theme/colors.dart';
import 'key_value_editor.dart';
import 'auth_tab.dart';
import 'body_tab.dart';
import 'headers_tab.dart';
import 'params_tab.dart';
import 'request_settings_panel.dart';
import 'scripts_tab.dart';
import 'tests_tab.dart';

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
              ParamsTab(),
              HeadersTab(),
              BodyTab(),
              AuthTab(),
              ScriptsTab(),
              TestsTab(),
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
  bool _showSuggestions = false;
  final _urlFocusNode = FocusNode();

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
    _urlFocusNode.dispose();
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

    // Refresh history list so the sidebar stays current.
    // History entries are created server-side when the proxy is used;
    // this invalidation ensures the UI picks up new entries promptly.
    ref.invalidate(courierHistoryProvider);
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

  // ── cURL paste detection ───────────────────────────────────────────────

  void _detectAndImportCurl(String text) {
    const parser = CurlParserService();
    if (!parser.isCurlCommand(text)) return;

    try {
      final parsed = parser.parse(text);

      // Set method.
      final method = CourierHttpMethod.values.firstWhere(
        (m) => m.toJson() == parsed.method.toUpperCase(),
        orElse: () => CourierHttpMethod.get,
      );
      ref.read(activeRequestStateProvider.notifier).setMethod(method);
      _syncMethodToTab(method);

      // Set URL.
      ref.read(activeRequestStateProvider.notifier).setUrl(parsed.url);
      _urlController.text = parsed.url;
      _syncUrlToTab(parsed.url);

      // Set headers.
      if (parsed.headers.isNotEmpty) {
        final pairs = parsed.headers.entries
            .map((e) => KeyValuePair(
                  id: UniqueKey().toString(),
                  key: e.key,
                  value: e.value,
                  enabled: true,
                ))
            .toList();
        ref.read(requestHeadersProvider.notifier).state = pairs;
      }

      // Set body.
      if (parsed.body != null && parsed.body!.isNotEmpty) {
        ref.read(bodyRawContentProvider.notifier).state = parsed.body!;
        if (parsed.bodyType == 'json') {
          ref.read(bodyTypeProvider.notifier).state = BodyType.rawJson;
        } else if (parsed.bodyType == 'xml') {
          ref.read(bodyTypeProvider.notifier).state = BodyType.rawXml;
        } else if (parsed.bodyType == 'urlencoded') {
          ref.read(bodyTypeProvider.notifier).state =
              BodyType.xWwwFormUrlEncoded;
        } else {
          ref.read(bodyTypeProvider.notifier).state = BodyType.rawText;
        }
      }

      // Set basic auth.
      if (parsed.username != null) {
        ref.read(authTypeProvider.notifier).state = AuthType.basicAuth;
        ref.read(authBasicUsernameProvider.notifier).state =
            parsed.username!;
        ref.read(authBasicPasswordProvider.notifier).state =
            parsed.password ?? '';
      }

      // Show toast.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: Key('curl_imported_toast'),
            content: Text('cURL imported \u2014 request populated'),
            duration: Duration(seconds: 2),
            backgroundColor: CodeOpsColors.surface,
          ),
        );
      }
    } catch (_) {
      // Not a valid cURL — ignore silently.
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(activeRequestStateProvider);
    final execStatus =
        ref.watch(executionStateProvider.select((s) => s.status));
    final isRunning = execStatus == ExecutionStatus.running;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
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
                      setState(() => _showSuggestions = false);
                      if (!isRunning) _send();
                    },
                  },
                  child: TextField(
                    key: const Key('url_field'),
                    controller: _urlController,
                    focusNode: _urlFocusNode,
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
                        borderSide:
                            const BorderSide(color: CodeOpsColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: CodeOpsColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            const BorderSide(color: CodeOpsColors.primary),
                      ),
                    ),
                    onChanged: (v) {
                      // Detect pasted cURL commands.
                      if (v.trimLeft().startsWith('curl ')) {
                        _detectAndImportCurl(v);
                        return;
                      }
                      ref.read(activeRequestStateProvider.notifier).setUrl(v);
                      _syncUrlToTab(v);
                      _scheduleAutoSave();
                      // Show suggestions when typing a URL prefix.
                      setState(() => _showSuggestions =
                          v.startsWith('http') && v.length >= 4);
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
        ),

        // ── Registry URL suggestions ─────────────────────────────────
        if (_showSuggestions)
          _RegistryUrlSuggestions(
            key: const Key('url_suggestions'),
            currentUrl: editState.url,
            onSelect: (url) {
              _urlController.text = url;
              _urlController.selection =
                  TextSelection.collapsed(offset: url.length);
              ref.read(activeRequestStateProvider.notifier).setUrl(url);
              _syncUrlToTab(url);
              setState(() => _showSuggestions = false);
            },
            onDismiss: () => setState(() => _showSuggestions = false),
          ),
      ],
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
    // Badge counts derived from request sub-resources (CCF-004).
    final paramCount = ref
        .watch(requestParamsProvider)
        .where((p) => p.enabled && p.key.isNotEmpty)
        .length;
    final headerCount = ref
        .watch(requestHeadersProvider)
        .where((p) => p.enabled && p.key.isNotEmpty)
        .length;
    final hasBody = ref.watch(bodyTypeProvider) != BodyType.none;
    final hasAuth = ref.watch(authTypeProvider) != AuthType.noAuth;
    final hasScripts =
        ref.watch(scriptPreRequestProvider).isNotEmpty ||
            ref.watch(scriptPostResponseProvider).isNotEmpty;
    final hasTests = ref.watch(scriptTestsProvider).isNotEmpty;

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
          _subTab('Body', dot: hasBody),
          _subTab('Auth', dot: hasAuth),
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
// Registry URL suggestions overlay (CCF-014)
// ─────────────────────────────────────────────────────────────────────────────

/// Inline suggestion list showing registered service base URLs and API routes.
///
/// Appears below the URL field when the user types an `http` prefix. Reads
/// services from [registryServicesForCourierProvider] and filters by current
/// URL text.
class _RegistryUrlSuggestions extends ConsumerWidget {
  final String currentUrl;
  final void Function(String url) onSelect;
  final VoidCallback onDismiss;

  const _RegistryUrlSuggestions({
    super.key,
    required this.currentUrl,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(registryServicesForCourierProvider);
    final services = servicesAsync.valueOrNull ?? [];

    if (services.isEmpty) return const SizedBox.shrink();

    // Build suggestions: base URLs from registered services.
    final suggestions = <_UrlSuggestion>[];
    for (final service in services) {
      final portsAsync =
          ref.watch(servicePortsForCourierProvider(service.id));
      final ports = portsAsync.valueOrNull ?? [];
      for (final port in ports) {
        if (port.portType == PortType.httpApi) {
          final baseUrl = 'http://localhost:${port.portNumber}';
          if (baseUrl.contains(currentUrl) ||
              currentUrl.startsWith(baseUrl)) {
            suggestions.add(_UrlSuggestion(
              url: baseUrl,
              label: service.name,
              isRoute: false,
            ));

            // If user has typed past the base URL, suggest routes.
            if (currentUrl.startsWith(baseUrl)) {
              final routesAsync =
                  ref.watch(serviceApiRoutesProvider(service.id));
              final routes = routesAsync.valueOrNull ?? [];
              for (final route in routes) {
                final fullUrl = '$baseUrl${route.routePrefix}';
                if (fullUrl.startsWith(currentUrl)) {
                  suggestions.add(_UrlSuggestion(
                    url: fullUrl,
                    label: '${route.routePrefix} (${route.httpMethods ?? 'ANY'})',
                    isRoute: true,
                  ));
                }
              }
            }
          }
        }
      }
    }

    if (suggestions.isEmpty) return const SizedBox.shrink();

    // Limit to 8 suggestions.
    final limited = suggestions.take(8).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border.all(color: CodeOpsColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: limited.length,
        itemBuilder: (_, i) {
          final s = limited[i];
          return InkWell(
            onTap: () => onSelect(s.url),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    s.isRoute ? Icons.route : Icons.dns_outlined,
                    size: 12,
                    color: s.isRoute
                        ? CodeOpsColors.secondary
                        : CodeOpsColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.url,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: CodeOpsColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CodeOpsColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// URL suggestion entry.
class _UrlSuggestion {
  final String url;
  final String label;
  final bool isRoute;

  const _UrlSuggestion({
    required this.url,
    required this.label,
    required this.isRoute,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-tab content stubs (CCF-004+ implements each editor)
// ─────────────────────────────────────────────────────────────────────────────

