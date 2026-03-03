/// OAuth token manager for the Courier auth tab.
///
/// Stores obtained OAuth/JWT tokens in memory per request, displays token
/// metadata (type, expiry, scope), and provides use/delete/refresh actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OAuthToken
// ─────────────────────────────────────────────────────────────────────────────

/// An obtained OAuth/JWT token with metadata.
class OAuthToken {
  /// The access token string.
  final String accessToken;

  /// Token type (e.g. `Bearer`).
  final String tokenType;

  /// When the token expires, or null if no expiry.
  final DateTime? expiresAt;

  /// Granted scope, or empty.
  final String scope;

  /// Refresh token, or null if not available.
  final String? refreshToken;

  /// Creates an [OAuthToken].
  const OAuthToken({
    required this.accessToken,
    this.tokenType = 'Bearer',
    this.expiresAt,
    this.scope = '',
    this.refreshToken,
  });

  /// Whether this token has expired.
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Whether a refresh token is available.
  bool get canRefresh => refreshToken != null && refreshToken!.isNotEmpty;

  /// Returns a truncated display form of the access token.
  String get truncatedToken {
    if (accessToken.length <= 20) return accessToken;
    return '${accessToken.substring(0, 10)}...${accessToken.substring(accessToken.length - 10)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthTokenManager
// ─────────────────────────────────────────────────────────────────────────────

/// Displays and manages an obtained OAuth token.
///
/// Shows token metadata (type, truncated value, expiry, scope) with action
/// buttons: Use Token, Copy, Refresh, Delete.
class AuthTokenManager extends StatelessWidget {
  /// The current token to display, or null if no token obtained.
  final OAuthToken? token;

  /// Called when the user clicks "Use Token" to apply it to the request.
  final ValueChanged<String>? onUseToken;

  /// Called when the user clicks "Delete Token".
  final VoidCallback? onDelete;

  /// Called when the user clicks "Refresh Token".
  final VoidCallback? onRefresh;

  /// Creates an [AuthTokenManager].
  const AuthTokenManager({
    super.key,
    this.token,
    this.onUseToken,
    this.onDelete,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return const SizedBox.shrink();
    }

    final t = token!;

    return Container(
      key: const Key('token_manager'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Row(
            children: [
              Icon(
                t.isExpired ? Icons.warning_amber : Icons.vpn_key,
                size: 14,
                color: t.isExpired
                    ? CodeOpsColors.warning
                    : CodeOpsColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Access Token',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.isExpired
                      ? CodeOpsColors.warning
                      : CodeOpsColors.textPrimary,
                ),
              ),
              if (t.isExpired) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.warning.withAlpha(38),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Expired',
                    style: TextStyle(
                      fontSize: 10,
                      color: CodeOpsColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Token value.
          Row(
            children: [
              Expanded(
                child: Text(
                  t.truncatedToken,
                  key: const Key('token_display'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: CodeOpsColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                key: const Key('token_copy_button'),
                icon: const Icon(Icons.copy,
                    size: 14, color: CodeOpsColors.textTertiary),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(maxWidth: 28, maxHeight: 28),
                splashRadius: 14,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: t.accessToken));
                },
                tooltip: 'Copy token',
              ),
            ],
          ),
          // Metadata.
          if (t.tokenType.isNotEmpty || t.scope.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              children: [
                if (t.tokenType.isNotEmpty)
                  Text(
                    'Type: ${t.tokenType}',
                    style: const TextStyle(
                        fontSize: 11, color: CodeOpsColors.textTertiary),
                  ),
                if (t.scope.isNotEmpty)
                  Text(
                    'Scope: ${t.scope}',
                    style: const TextStyle(
                        fontSize: 11, color: CodeOpsColors.textTertiary),
                  ),
                if (t.expiresAt != null)
                  Text(
                    'Expires: ${_formatExpiry(t.expiresAt!)}',
                    key: const Key('token_expiry'),
                    style: TextStyle(
                      fontSize: 11,
                      color: t.isExpired
                          ? CodeOpsColors.warning
                          : CodeOpsColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          // Action buttons.
          Row(
            children: [
              _TokenActionButton(
                key: const Key('token_use_button'),
                label: 'Use Token',
                icon: Icons.check_circle_outline,
                color: CodeOpsColors.success,
                onPressed: onUseToken != null
                    ? () => onUseToken!(t.accessToken)
                    : null,
              ),
              const SizedBox(width: 8),
              if (t.canRefresh)
                _TokenActionButton(
                  key: const Key('token_refresh_button'),
                  label: 'Refresh',
                  icon: Icons.refresh,
                  color: CodeOpsColors.primary,
                  onPressed: onRefresh,
                ),
              if (t.canRefresh) const SizedBox(width: 8),
              _TokenActionButton(
                key: const Key('token_delete_button'),
                label: 'Delete',
                icon: Icons.delete_outline,
                color: CodeOpsColors.error,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m remaining';
    if (diff.inHours < 24) return '${diff.inHours}h remaining';
    return '${diff.inDays}d remaining';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TokenActionButton
// ─────────────────────────────────────────────────────────────────────────────

class _TokenActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _TokenActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(128)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }
}
