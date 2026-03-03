/// Response cookies tab for Courier.
///
/// Parses `Set-Cookie` headers and displays structured cookie attributes
/// in a table: Name, Value, Domain, Path, Expires, HttpOnly, Secure, SameSite.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ParsedCookie
// ─────────────────────────────────────────────────────────────────────────────

/// A parsed Set-Cookie header with structured attributes.
class ParsedCookie {
  /// Cookie name.
  final String name;

  /// Cookie value.
  final String value;

  /// Domain attribute, or empty.
  final String domain;

  /// Path attribute, or '/'.
  final String path;

  /// Expires attribute as raw string, or empty.
  final String expires;

  /// Whether the HttpOnly flag is set.
  final bool httpOnly;

  /// Whether the Secure flag is set.
  final bool secure;

  /// SameSite attribute (Strict, Lax, None), or empty.
  final String sameSite;

  /// Creates a [ParsedCookie].
  const ParsedCookie({
    required this.name,
    required this.value,
    this.domain = '',
    this.path = '/',
    this.expires = '',
    this.httpOnly = false,
    this.secure = false,
    this.sameSite = '',
  });

  /// Parses a raw `Set-Cookie` header value into a [ParsedCookie].
  factory ParsedCookie.parse(String raw) {
    final parts = raw.split(';').map((p) => p.trim()).toList();
    if (parts.isEmpty) {
      return const ParsedCookie(name: '', value: '');
    }

    // First part is name=value.
    final nameValue = parts[0];
    final eqIdx = nameValue.indexOf('=');
    final name = eqIdx > 0 ? nameValue.substring(0, eqIdx).trim() : nameValue;
    final value = eqIdx > 0 ? nameValue.substring(eqIdx + 1).trim() : '';

    var domain = '';
    var path = '/';
    var expires = '';
    var httpOnly = false;
    var secure = false;
    var sameSite = '';

    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];
      final lower = part.toLowerCase();

      if (lower.startsWith('domain=')) {
        domain = part.substring(7).trim();
      } else if (lower.startsWith('path=')) {
        path = part.substring(5).trim();
      } else if (lower.startsWith('expires=')) {
        expires = part.substring(8).trim();
      } else if (lower.startsWith('max-age=')) {
        if (expires.isEmpty) expires = 'max-age=${part.substring(8).trim()}';
      } else if (lower == 'httponly') {
        httpOnly = true;
      } else if (lower == 'secure') {
        secure = true;
      } else if (lower.startsWith('samesite=')) {
        sameSite = part.substring(9).trim();
      }
    }

    return ParsedCookie(
      name: name,
      value: value,
      domain: domain,
      path: path,
      expires: expires,
      httpOnly: httpOnly,
      secure: secure,
      sameSite: sameSite,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ResponseCookiesTab
// ─────────────────────────────────────────────────────────────────────────────

/// Displays parsed cookies from `Set-Cookie` response headers.
///
/// Shows a structured table with cookie attributes. Click a cookie name to
/// copy its value.
class ResponseCookiesTab extends StatelessWidget {
  /// Response headers map — cookies are extracted from `set-cookie` entries.
  final Map<String, String> headers;

  /// Creates a [ResponseCookiesTab].
  const ResponseCookiesTab({super.key, required this.headers});

  @override
  Widget build(BuildContext context) {
    final cookies = _parseCookies();

    if (cookies.isEmpty) {
      return const Center(
        child: Text(
          'No cookies in response',
          key: Key('cookies_empty'),
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
      );
    }

    return Column(
      key: const Key('response_cookies_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cookie count.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: CodeOpsColors.surface,
          child: Text(
            '${cookies.length} cookie${cookies.length == 1 ? '' : 's'}',
            key: const Key('cookie_count'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Table header.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: CodeOpsColors.background,
          child: const Row(
            children: [
              _ColHeader(width: 120, label: 'Name'),
              _ColHeader(width: 160, label: 'Value'),
              _ColHeader(width: 100, label: 'Domain'),
              _ColHeader(width: 60, label: 'Path'),
              _ColHeader(width: 60, label: 'Secure'),
              _ColHeader(width: 60, label: 'HttpOnly'),
              Expanded(child: _ColHeader(width: 80, label: 'SameSite')),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Rows.
        Expanded(
          child: ListView.separated(
            key: const Key('cookie_list'),
            padding: EdgeInsets.zero,
            itemCount: cookies.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, thickness: 1, color: CodeOpsColors.border),
            itemBuilder: (_, i) => _CookieRow(cookie: cookies[i]),
          ),
        ),
      ],
    );
  }

  List<ParsedCookie> _parseCookies() {
    final cookies = <ParsedCookie>[];
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'set-cookie') {
        // The value may be a single cookie or multiple joined by ", ".
        // Split carefully — commas inside Expires dates are tricky.
        // For MVP, treat the whole value as one cookie per header entry.
        for (final raw in entry.value.split(RegExp(r',(?=\s*\w+=)'))) {
          final cookie = ParsedCookie.parse(raw.trim());
          if (cookie.name.isNotEmpty) cookies.add(cookie);
        }
      }
    }
    return cookies;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ColHeader
// ─────────────────────────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final double width;
  final String label;

  const _ColHeader({required this.width, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: CodeOpsColors.textTertiary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CookieRow
// ─────────────────────────────────────────────────────────────────────────────

class _CookieRow extends StatelessWidget {
  final ParsedCookie cookie;

  const _CookieRow({required this.cookie});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Clipboard.setData(ClipboardData(text: cookie.value)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                cookie.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.secondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 160,
              child: Text(
                cookie.value,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: CodeOpsColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                cookie.domain.isEmpty ? '—' : cookie.domain,
                style: const TextStyle(
                    fontSize: 11, color: CodeOpsColors.textTertiary),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                cookie.path,
                style: const TextStyle(
                    fontSize: 11, color: CodeOpsColors.textTertiary),
              ),
            ),
            SizedBox(
              width: 60,
              child: _BoolBadge(value: cookie.secure),
            ),
            SizedBox(
              width: 60,
              child: _BoolBadge(value: cookie.httpOnly),
            ),
            Expanded(
              child: Text(
                cookie.sameSite.isEmpty ? '—' : cookie.sameSite,
                style: const TextStyle(
                    fontSize: 11, color: CodeOpsColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BoolBadge
// ─────────────────────────────────────────────────────────────────────────────

class _BoolBadge extends StatelessWidget {
  final bool value;

  const _BoolBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value ? 'Yes' : '—',
      style: TextStyle(
        fontSize: 11,
        fontWeight: value ? FontWeight.w600 : FontWeight.normal,
        color: value ? CodeOpsColors.success : CodeOpsColors.textTertiary,
      ),
    );
  }
}
