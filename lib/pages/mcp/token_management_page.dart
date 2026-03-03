/// MCP token management page.
///
/// Displays at `/mcp/profiles/:profileId/tokens`. Shows a table of API
/// tokens with status badges, supports revoking tokens, and creating new
/// tokens with a dialog that shows the raw token value once.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/mcp_enums.dart';
import '../../models/mcp_models.dart';
import '../../providers/mcp_profile_providers.dart';
import '../../providers/mcp_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/error_panel.dart';

/// The MCP token management page.
class TokenManagementPage extends ConsumerWidget {
  /// Profile ID from the route parameter.
  final String profileId;

  /// Creates a [TokenManagementPage].
  const TokenManagementPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync = ref.watch(profileTokensProvider(profileId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(profileId: profileId),
          const SizedBox(height: 20),
          // Action bar
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateTokenDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Token'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Token table
          tokensAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child:
                    CircularProgressIndicator(color: CodeOpsColors.primary),
              ),
            ),
            error: (e, _) => ErrorPanel.fromException(e, onRetry: () {
              ref.invalidate(profileTokensProvider(profileId));
            }),
            data: (tokens) {
              if (tokens.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  decoration: BoxDecoration(
                    color: CodeOpsColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CodeOpsColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.key_off,
                          size: 40, color: CodeOpsColors.textTertiary),
                      SizedBox(height: 12),
                      Text(
                        'No tokens yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: CodeOpsColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create a token to connect Claude Code to CodeOps via MCP.',
                        style: TextStyle(
                            fontSize: 12,
                            color: CodeOpsColors.textTertiary),
                      ),
                    ],
                  ),
                );
              }
              return _TokenTable(
                tokens: tokens,
                profileId: profileId,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateTokenDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _CreateTokenDialog(profileId: profileId, ref: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String profileId;

  const _Header({required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/mcp/profiles'),
              child: const Text(
                'Profiles',
                style:
                    TextStyle(fontSize: 12, color: CodeOpsColors.primary),
              ),
            ),
            const Text(' / ',
                style: TextStyle(
                    fontSize: 12, color: CodeOpsColors.textTertiary)),
            GestureDetector(
              onTap: () => context.go('/mcp/profiles/$profileId'),
              child: const Text(
                'Profile',
                style:
                    TextStyle(fontSize: 12, color: CodeOpsColors.primary),
              ),
            ),
            const Text(' / ',
                style: TextStyle(
                    fontSize: 12, color: CodeOpsColors.textTertiary)),
            const Text(
              'Tokens',
              style: TextStyle(
                  fontSize: 12, color: CodeOpsColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Token Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'API tokens for MCP AI agent authentication',
          style: TextStyle(
            fontSize: 13,
            color: CodeOpsColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Token Table
// ─────────────────────────────────────────────────────────────────────────────

class _TokenTable extends ConsumerWidget {
  final List<McpApiToken> tokens;
  final String profileId;

  const _TokenTable({required this.tokens, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CodeOpsColors.border),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Name',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CodeOpsColors.textTertiary))),
                Expanded(
                    flex: 2,
                    child: Text('Prefix',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CodeOpsColors.textTertiary))),
                Expanded(
                    flex: 2,
                    child: Text('Status',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CodeOpsColors.textTertiary))),
                Expanded(
                    flex: 2,
                    child: Text('Created',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CodeOpsColors.textTertiary))),
                Expanded(
                    flex: 2,
                    child: Text('Expires',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CodeOpsColors.textTertiary))),
                Expanded(
                    flex: 2,
                    child: Text('Last Used',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CodeOpsColors.textTertiary))),
                Expanded(
                    flex: 2,
                    child: Text('Actions',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: CodeOpsColors.textTertiary))),
              ],
            ),
          ),
          for (final token in tokens)
            _TokenRow(token: token, profileId: profileId),
        ],
      ),
    );
  }
}

class _TokenRow extends ConsumerWidget {
  final McpApiToken token;
  final String profileId;

  const _TokenRow({required this.token, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              token.name ?? 'Unnamed',
              style: const TextStyle(
                  fontSize: 12, color: CodeOpsColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              token.tokenPrefix ?? '—',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatusBadge(status: token.status),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(token.createdAt),
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textTertiary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              token.expiresAt != null
                  ? _formatDate(token.expiresAt)
                  : 'Never',
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textTertiary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              token.lastUsedAt != null
                  ? _formatDate(token.lastUsedAt)
                  : 'Never',
              style: const TextStyle(
                  fontSize: 11, color: CodeOpsColors.textTertiary),
            ),
          ),
          Expanded(
            flex: 2,
            child: token.status == TokenStatus.active
                ? TextButton(
                    onPressed: () => _revokeToken(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: CodeOpsColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Revoke', style: TextStyle(fontSize: 11)),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeToken(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Token'),
        content: Text(
            'Are you sure you want to revoke "${token.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final api = ref.read(mcpApiProvider);
      await api.revokeToken(token.id!);
      ref.invalidate(profileTokensProvider(profileId));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final d = date.toLocal();
    return '${d.month}/${d.day}/${d.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final TokenStatus? status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TokenStatus.active => CodeOpsColors.success,
      TokenStatus.revoked => CodeOpsColors.error,
      TokenStatus.expired => CodeOpsColors.warning,
      _ => CodeOpsColors.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status?.displayName ?? 'Unknown',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Token Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CreateTokenDialog extends StatefulWidget {
  final String profileId;
  final WidgetRef ref;

  const _CreateTokenDialog({
    required this.profileId,
    required this.ref,
  });

  @override
  State<_CreateTokenDialog> createState() => _CreateTokenDialogState();
}

class _CreateTokenDialogState extends State<_CreateTokenDialog> {
  final _nameController = TextEditingController();
  DateTime? _expiresAt;
  final _scopes = <String>{};
  bool _creating = false;
  McpApiTokenCreated? _createdToken;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createToken() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _creating = true);
    try {
      final api = widget.ref.read(mcpApiProvider);
      final token = await api.createApiToken(widget.profileId, {
        'name': _nameController.text,
        if (_expiresAt != null)
          'expiresAt': _expiresAt!.toUtc().toIso8601String(),
        if (_scopes.isNotEmpty) 'scopes': _scopes.toList(),
      });
      widget.ref.invalidate(profileTokensProvider(widget.profileId));
      if (mounted) {
        setState(() {
          _createdToken = token;
          _creating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create token: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdToken != null) {
      return _TokenCreatedView(
        token: _createdToken!,
        onDone: () => Navigator.pop(context),
      );
    }

    return AlertDialog(
      title: const Text('Create Token'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Token Name',
                hintText: 'e.g., Claude Code Laptop',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Expiry picker
            Row(
              children: [
                const Text('Expires:',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _expiresAt = picked);
                    }
                  },
                  child: Text(
                    _expiresAt != null
                        ? '${_expiresAt!.month}/${_expiresAt!.day}/${_expiresAt!.year}'
                        : 'Never',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (_expiresAt != null)
                  IconButton(
                    onPressed: () => setState(() => _expiresAt = null),
                    icon: const Icon(Icons.clear, size: 14),
                    tooltip: 'Set to never expire',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Scopes
            const Text('Scopes:',
                style: TextStyle(
                    fontSize: 12, color: CodeOpsColors.textSecondary)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final scope in ['read', 'write', 'admin'])
                  FilterChip(
                    label: Text(scope,
                        style: const TextStyle(fontSize: 11)),
                    selected: _scopes.contains(scope),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _scopes.add(scope);
                        } else {
                          _scopes.remove(scope);
                        }
                      });
                    },
                    selectedColor:
                        CodeOpsColors.primary.withValues(alpha: 0.2),
                    showCheckmark: true,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _creating ? null : _createToken,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Token Created View (one-time display)
// ─────────────────────────────────────────────────────────────────────────────

class _TokenCreatedView extends StatelessWidget {
  final McpApiTokenCreated token;
  final VoidCallback onDone;

  const _TokenCreatedView({required this.token, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: CodeOpsColors.success),
          const SizedBox(width: 8),
          const Text('Token Created'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CodeOpsColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: CodeOpsColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber,
                      size: 18, color: CodeOpsColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This token will not be shown again. Copy it now.',
                      style: TextStyle(
                          fontSize: 12, color: CodeOpsColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Token Value:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textSecondary)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CodeOpsColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CodeOpsColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      token.rawToken ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: CodeOpsColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: token.rawToken ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Token copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy Token',
                    color: CodeOpsColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Name: ${token.name ?? "—"}',
              style: const TextStyle(
                  fontSize: 12, color: CodeOpsColors.textSecondary),
            ),
            Text(
              'Prefix: ${token.tokenPrefix ?? "—"}',
              style: const TextStyle(
                  fontSize: 12, color: CodeOpsColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
