/// Request settings panel for the Courier request builder.
///
/// Exposes per-request transport options: follow-redirects toggle, timeout
/// input, SSL verification toggle, and proxy URL field.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/courier_ui_providers.dart';
import '../../theme/colors.dart';

/// Displays and edits the transport settings for the currently active request.
///
/// Reads from and writes to [activeRequestStateProvider] so any change is
/// immediately reflected in the [RequestEditState.settings] field.
class RequestSettingsPanel extends ConsumerWidget {
  /// Creates a [RequestSettingsPanel].
  const RequestSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(activeRequestStateProvider.select((s) => s.settings));

    void updateSettings(RequestSettingsState updated) {
      ref.read(activeRequestStateProvider.notifier).setSettings(updated);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Request Behaviour'),
          const SizedBox(height: 8),
          // ── Follow Redirects ──────────────────────────────────────────────
          _SettingRow(
            label: 'Follow Redirects',
            description:
                'Automatically follow 3xx redirect responses.',
            trailing: Switch(
              key: const Key('follow_redirects_toggle'),
              value: settings.followRedirects,
              onChanged: (v) =>
                  updateSettings(settings.copyWith(followRedirects: v)),
              activeThumbColor: CodeOpsColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          // ── SSL Verification ──────────────────────────────────────────────
          _SettingRow(
            label: 'SSL Certificate Verification',
            description:
                'Verify SSL/TLS certificates. Disable only for '
                'self-signed certs during development.',
            trailing: Switch(
              key: const Key('ssl_verify_toggle'),
              value: settings.sslVerify,
              onChanged: (v) =>
                  updateSettings(settings.copyWith(sslVerify: v)),
              activeThumbColor: CodeOpsColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Timeout'),
          const SizedBox(height: 8),
          // ── Timeout ───────────────────────────────────────────────────────
          _TimeoutField(
            initialMs: settings.timeoutMs,
            onChanged: (ms) =>
                updateSettings(settings.copyWith(timeoutMs: ms)),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Proxy'),
          const SizedBox(height: 8),
          // ── Proxy URL ─────────────────────────────────────────────────────
          _ProxyField(
            initialValue: settings.proxyUrl ?? '',
            onChanged: (v) => updateSettings(
              settings.copyWith(proxyUrl: v.isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: CodeOpsColors.textTertiary,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String description;
  final Widget trailing;

  const _SettingRow({
    required this.label,
    required this.description,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: CodeOpsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: CodeOpsColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

/// Timeout input field that accepts a value in milliseconds.
class _TimeoutField extends StatefulWidget {
  final int initialMs;
  final ValueChanged<int> onChanged;

  const _TimeoutField({required this.initialMs, required this.onChanged});

  @override
  State<_TimeoutField> createState() => _TimeoutFieldState();
}

class _TimeoutFieldState extends State<_TimeoutField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMs.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: TextField(
            key: const Key('timeout_field'),
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 13,
              color: CodeOpsColors.textPrimary,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: CodeOpsColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            onChanged: (v) {
              final ms = int.tryParse(v);
              if (ms != null && ms > 0) widget.onChanged(ms);
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'ms',
          style: TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Proxy URL text field.
class _ProxyField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _ProxyField({required this.initialValue, required this.onChanged});

  @override
  State<_ProxyField> createState() => _ProxyFieldState();
}

class _ProxyFieldState extends State<_ProxyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('proxy_url_field'),
      controller: _controller,
      style: const TextStyle(
        fontSize: 13,
        color: CodeOpsColors.textPrimary,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: 'http://proxy.local:8080',
        hintStyle: const TextStyle(
          fontSize: 13,
          color: CodeOpsColors.textTertiary,
        ),
        filled: true,
        fillColor: CodeOpsColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      onChanged: widget.onChanged,
    );
  }
}
