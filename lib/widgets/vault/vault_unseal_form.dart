/// Unseal form for submitting Shamir key shares.
///
/// Provides a text field for entering Base64-encoded key shares, a submit
/// button, a share submission log, and inline error display. When the
/// threshold is reached the vault transitions to UNSEALED and a success
/// message is shown.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vault_enums.dart';
import '../../models/vault_models.dart';
import '../../providers/vault_providers.dart';
import '../../theme/colors.dart';

/// A form for submitting key shares to unseal the Vault.
///
/// Tracks submitted share count locally, displays inline errors for
/// invalid/duplicate shares, and shows a success message when unsealing
/// completes.
class VaultUnsealForm extends ConsumerStatefulWidget {
  /// The current seal status.
  final SealStatusResponse sealStatus;

  /// Creates a [VaultUnsealForm].
  const VaultUnsealForm({super.key, required this.sealStatus});

  @override
  ConsumerState<VaultUnsealForm> createState() => _VaultUnsealFormState();
}

class _VaultUnsealFormState extends ConsumerState<VaultUnsealForm> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _justUnsealed = false;

  /// Local log of submitted share indices.
  final List<int> _submittedShares = [];

  @override
  void didUpdateWidget(covariant VaultUnsealForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect transition from sealed/unsealing → unsealed.
    if (widget.sealStatus.status == SealStatus.unsealed &&
        oldWidget.sealStatus.status != SealStatus.unsealed) {
      setState(() => _justUnsealed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Success state
    if (_justUnsealed) {
      return _buildSuccessMessage();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unseal Progress',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          _buildProgressBar(),
          const SizedBox(height: 16),

          // Share input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Key Share',
                    hintText: 'Base64-encoded key share',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    errorText: _error,
                    errorMaxLines: 2,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submitting ? null : _submitShare,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Submitted shares log
          if (_submittedShares.isNotEmpty) ...[
            const Text(
              'Shares entered:',
              style: TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _submittedShares
                  .map(
                    (i) => Chip(
                      avatar: const Icon(Icons.check_circle,
                          size: 14, color: CodeOpsColors.success),
                      label: Text(
                        'Share $i',
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final status = widget.sealStatus;
    final progress =
        status.threshold > 0 ? status.sharesProvided / status.threshold : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: CodeOpsColors.surfaceVariant,
            color: CodeOpsColors.warning,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${status.sharesProvided} of ${status.threshold} shares provided',
          style: const TextStyle(
            fontSize: 12,
            color: CodeOpsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, size: 24, color: CodeOpsColors.success),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vault successfully unsealed!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CodeOpsColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitShare() async {
    final share = _controller.text.trim();
    if (share.isEmpty) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final api = ref.read(vaultApiProvider);
      final result = await api.unsealVault(action: 'UNSEAL', keyShare: share);
      ref.invalidate(sealStatusProvider);
      _controller.clear();

      if (mounted) {
        setState(() {
          _submittedShares.add(result.sharesProvided);
        });
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        setState(() {
          if (message.contains('already been submitted') ||
              message.contains('duplicate')) {
            _error = 'This share has already been submitted';
          } else if (message.contains('invalid') ||
              message.contains('format') ||
              message.contains('decode')) {
            _error = 'Invalid key share format';
          } else if (message.contains('mismatch') ||
              message.contains('reconstruction')) {
            _error =
                'Key shares do not match. Vault reset to SEALED. '
                'Please try again.';
          } else {
            _error = 'Failed to submit share: $e';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
