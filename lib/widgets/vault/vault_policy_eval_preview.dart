/// Deny-override visualization and impact preview for a policy (CVF-004).
///
/// Shows which secrets a policy's path pattern would match (client-side glob
/// simulation), and provides a path evaluator that shows how all policies
/// interact with deny-overrides-allow semantics for a given path.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/health_snapshot.dart';
import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';
import 'permission_badge.dart';

/// Impact preview and deny-override visualization for a single policy.
///
/// Two sections:
/// 1. **Matching Secrets** — Fetches all secrets and filters client-side
///    by the policy's path pattern.
/// 2. **Path Evaluator** — Enter any path to see which policies match
///    and whether access is allowed or denied (deny overrides allow).
class VaultPolicyEvalPreview extends ConsumerStatefulWidget {
  /// The policy ID for impact preview.
  final String policyId;

  /// Creates a [VaultPolicyEvalPreview].
  const VaultPolicyEvalPreview({super.key, required this.policyId});

  @override
  ConsumerState<VaultPolicyEvalPreview> createState() =>
      _VaultPolicyEvalPreviewState();
}

class _VaultPolicyEvalPreviewState
    extends ConsumerState<VaultPolicyEvalPreview> {
  final _pathController = TextEditingController();
  bool _evaluating = false;
  _EvalResult? _evalResult;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final policyAsync = ref.watch(vaultPolicyDetailProvider(widget.policyId));
    final secretsAsync = ref.watch(vaultSecretsProvider);
    final policiesAsync = ref.watch(vaultPoliciesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section 1: Matching Secrets
        const Text(
          'Matching Secrets',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Secrets whose path matches this policy\'s pattern.',
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
        const SizedBox(height: 8),
        policyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Text(
            'Error loading policy: $e',
            style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
          ),
          data: (policy) => secretsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Text(
              'Error loading secrets: $e',
              style: const TextStyle(color: CodeOpsColors.error, fontSize: 12),
            ),
            data: (secretsPage) =>
                _buildMatchingSecrets(policy, secretsPage),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: CodeOpsColors.border),
        const SizedBox(height: 16),
        // Section 2: Path Evaluator
        const Text(
          'Deny-Override Evaluator',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CodeOpsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'See how all policies interact for a given path. '
          'Deny policies override allow policies.',
          style: TextStyle(fontSize: 12, color: CodeOpsColors.textTertiary),
        ),
        const SizedBox(height: 12),
        _buildEvaluatorForm(),
        const SizedBox(height: 12),
        if (_evalResult != null)
          policiesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (_) => _buildEvalResult(_evalResult!),
          ),
      ],
    );
  }

  // ─── Matching Secrets ──────────────────────────────────────────────────

  Widget _buildMatchingSecrets(
    AccessPolicyResponse policy,
    PageResponse<SecretResponse> secretsPage,
  ) {
    final matched = secretsPage.content
        .where((s) => _matchesPattern(policy.pathPattern, s.path))
        .toList();

    if (matched.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CodeOpsColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CodeOpsColors.border),
        ),
        child: const Center(
          child: Text(
            'No secrets match this pattern',
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textTertiary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CodeOpsColors.border),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${matched.length} matching secrets',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Access indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (policy.isDenyPolicy
                            ? CodeOpsColors.error
                            : CodeOpsColors.success)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    policy.isDenyPolicy ? 'DENIED' : 'ALLOWED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: policy.isDenyPolicy
                          ? CodeOpsColors.error
                          : CodeOpsColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Secret list
          ...matched.map((s) => _MatchedSecretRow(
                secret: s,
                isDeny: policy.isDenyPolicy,
              )),
        ],
      ),
    );
  }

  // ─── Evaluator Form ────────────────────────────────────────────────────

  Widget _buildEvaluatorForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                hintText: '/services/my-app/db-password',
                labelText: 'Secret Path',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.folder_outlined, size: 18),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: _evaluating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow, size: 16),
            label: const Text('Evaluate'),
            onPressed: _evaluating ? null : _evaluate,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvalResult(_EvalResult result) {
    final color = result.allowed ? CodeOpsColors.success : CodeOpsColors.error;
    final icon = result.allowed ? Icons.check_circle : Icons.cancel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Final result
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.allowed ? 'ACCESS ALLOWED' : 'ACCESS DENIED',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      result.reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Matching policies
        if (result.matchingPolicies.isNotEmpty) ...[
          const Text(
            'Matching Policies',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ...result.matchingPolicies.map((mp) => _MatchingPolicyRow(
                policy: mp.policy,
                isDeciding: mp.policy.id == result.decidingPolicyId,
              )),
        ],
        if (result.matchingPolicies.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CodeOpsColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: const Text(
              'No policies match this path.',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  void _evaluate() {
    final path = _pathController.text.trim();
    if (path.isEmpty || !path.startsWith('/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid path starting with /')),
      );
      return;
    }

    setState(() => _evaluating = true);

    final policiesAsync = ref.read(vaultPoliciesProvider);
    policiesAsync.when(
      loading: () {
        setState(() => _evaluating = false);
      },
      error: (e, _) {
        setState(() => _evaluating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load policies: $e')),
        );
      },
      data: (policiesPage) {
        final matching = policiesPage.content
            .where(
                (p) => p.isActive && _matchesPattern(p.pathPattern, path))
            .toList();

        final result = _computeAccess(matching, path);
        setState(() {
          _evalResult = result;
          _evaluating = false;
        });
      },
    );
  }
}

// ─── Client-side glob matching ─────────────────────────────────────────────

/// Matches a glob [pattern] against a [path] using `*` for single-segment
/// wildcards. Each segment is separated by `/`.
bool _matchesPattern(String pattern, String path) {
  final patternSegments =
      pattern.split('/').where((s) => s.isNotEmpty).toList();
  final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();

  if (patternSegments.length != pathSegments.length) return false;

  for (var i = 0; i < patternSegments.length; i++) {
    final ps = patternSegments[i];
    final ts = pathSegments[i];

    if (ps == '*') continue;

    // Support prefix wildcards like "db-*"
    if (ps.contains('*')) {
      final regex = RegExp(
        '^${ps.replaceAll('*', '.*')}\$',
      );
      if (!regex.hasMatch(ts)) return false;
    } else if (ps != ts) {
      return false;
    }
  }
  return true;
}

// ─── Deny-overrides-allow logic ────────────────────────────────────────────

_EvalResult _computeAccess(
  List<AccessPolicyResponse> matchingPolicies,
  String path,
) {
  if (matchingPolicies.isEmpty) {
    return _EvalResult(
      allowed: false,
      reason: 'Default DENIED (no matching policy)',
      matchingPolicies:
          matchingPolicies.map((p) => _MatchedPolicy(policy: p)).toList(),
      decidingPolicyId: null,
    );
  }

  // Deny overrides allow: check deny policies first
  final denyPolicies = matchingPolicies.where((p) => p.isDenyPolicy).toList();
  if (denyPolicies.isNotEmpty) {
    return _EvalResult(
      allowed: false,
      reason: 'Access DENIED by "${denyPolicies.first.name}"',
      matchingPolicies:
          matchingPolicies.map((p) => _MatchedPolicy(policy: p)).toList(),
      decidingPolicyId: denyPolicies.first.id,
    );
  }

  // No deny policies — allow policies grant access
  final allowPolicies =
      matchingPolicies.where((p) => !p.isDenyPolicy).toList();
  if (allowPolicies.isNotEmpty) {
    return _EvalResult(
      allowed: true,
      reason: 'Access ALLOWED by "${allowPolicies.first.name}"',
      matchingPolicies:
          matchingPolicies.map((p) => _MatchedPolicy(policy: p)).toList(),
      decidingPolicyId: allowPolicies.first.id,
    );
  }

  return _EvalResult(
    allowed: false,
    reason: 'Default DENIED (no matching policy)',
    matchingPolicies:
        matchingPolicies.map((p) => _MatchedPolicy(policy: p)).toList(),
    decidingPolicyId: null,
  );
}

// ─── Result Models ─────────────────────────────────────────────────────────

class _EvalResult {
  final bool allowed;
  final String reason;
  final List<_MatchedPolicy> matchingPolicies;
  final String? decidingPolicyId;

  const _EvalResult({
    required this.allowed,
    required this.reason,
    required this.matchingPolicies,
    this.decidingPolicyId,
  });
}

class _MatchedPolicy {
  final AccessPolicyResponse policy;

  const _MatchedPolicy({required this.policy});
}

// ─── Widget: Matched Secret Row ────────────────────────────────────────────

class _MatchedSecretRow extends StatelessWidget {
  final SecretResponse secret;
  final bool isDeny;

  const _MatchedSecretRow({required this.secret, required this.isDeny});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CodeOpsColors.divider),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.key,
            size: 14,
            color: isDeny ? CodeOpsColors.error : CodeOpsColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  secret.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.textPrimary,
                  ),
                ),
                Text(
                  secret.path,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isDeny ? CodeOpsColors.error : CodeOpsColors.success)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isDeny ? 'DENIED' : 'ALLOWED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color:
                    isDeny ? CodeOpsColors.error : CodeOpsColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Matching Policy Row ───────────────────────────────────────────

class _MatchingPolicyRow extends StatelessWidget {
  final AccessPolicyResponse policy;
  final bool isDeciding;

  const _MatchingPolicyRow({
    required this.policy,
    required this.isDeciding,
  });

  @override
  Widget build(BuildContext context) {
    final isDeny = policy.isDenyPolicy;
    final color = isDeny ? CodeOpsColors.error : CodeOpsColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDeciding
            ? color.withValues(alpha: 0.05)
            : CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDeciding
              ? color.withValues(alpha: 0.3)
              : CodeOpsColors.border,
        ),
      ),
      child: Row(
        children: [
          // Policy icon
          Icon(
            isDeny ? Icons.block : Icons.check_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          // Name + path pattern
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        policy.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CodeOpsColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDeciding) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'DECIDING',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  policy.pathPattern,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Permission chips
          Wrap(
            spacing: 3,
            children: policy.permissions
                .map((p) => PermissionBadge(permission: p))
                .toList(),
          ),
          const SizedBox(width: 8),
          // Allow/Deny
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isDeny ? 'DENY' : 'ALLOW',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
