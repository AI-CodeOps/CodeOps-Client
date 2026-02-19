/// Standalone Vault secret detail page for deep-link access.
///
/// Accessed via `/vault/secrets/:id`. Fetches the secret by ID from
/// [vaultSecretDetailProvider] and renders the full [SecretDetailPanel]
/// in a full-width layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/vault_providers.dart';
import '../theme/colors.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/vault/secret_detail_panel.dart';

/// Full-page version of the secret detail for deep-link access.
class VaultSecretDetailPage extends ConsumerWidget {
  /// The secret UUID extracted from route parameters.
  final String secretId;

  /// Creates a [VaultSecretDetailPage].
  const VaultSecretDetailPage({super.key, required this.secretId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secretAsync = ref.watch(vaultSecretDetailProvider(secretId));

    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.divider),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    size: 18, color: CodeOpsColors.textSecondary),
                onPressed: () => context.go('/vault/secrets'),
                tooltip: 'Back to secrets',
              ),
              const SizedBox(width: 8),
              secretAsync.when(
                loading: () => const Text(
                  'Secret Detail',
                  style: TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                error: (_, __) => const Text(
                  'Secret Detail',
                  style: TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                data: (secret) => Text(
                  'Secret: ${secret.name}',
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: secretAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => ErrorPanel.fromException(
              e,
              onRetry: () =>
                  ref.invalidate(vaultSecretDetailProvider(secretId)),
            ),
            data: (secret) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SecretDetailPanel(
                  secret: secret,
                  onMutated: () {
                    ref.invalidate(vaultSecretDetailProvider(secretId));
                    ref.invalidate(vaultSecretsProvider);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
