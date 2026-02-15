/// Dialog for authenticating with GitHub.
///
/// Supports Personal Access Token input with a test & save flow.
/// Stores the token in [SecureStorageService] and authenticates
/// the [VcsProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/vcs_models.dart';
import '../../providers/auth_providers.dart';
import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// Dialog for connecting to GitHub via Personal Access Token.
class GitHubAuthDialog extends ConsumerStatefulWidget {
  /// Creates a [GitHubAuthDialog].
  const GitHubAuthDialog({super.key});

  @override
  ConsumerState<GitHubAuthDialog> createState() => _GitHubAuthDialogState();
}

class _GitHubAuthDialogState extends ConsumerState<GitHubAuthDialog> {
  final _tokenController = TextEditingController();
  bool _testing = false;
  bool _obscure = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Please enter a token');
      return;
    }

    setState(() {
      _testing = true;
      _error = null;
      _success = null;
    });

    final credentials = VcsCredentials(
      authType: GitHubAuthType.pat,
      token: token,
    );

    try {
      final provider = ref.read(vcsProviderProvider);
      final ok = await provider.authenticate(credentials);
      if (!mounted) return;

      if (ok) {
        // Store token securely.
        final storage = ref.read(secureStorageProvider);
        await storage.write(AppConstants.keyGitHubPat, token);

        ref.read(vcsCredentialsProvider.notifier).state = credentials;
        ref.read(vcsAuthenticatedProvider.notifier).state = true;

        setState(() => _success = 'Connected to GitHub');
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'Authentication failed — check your token');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Connection error: $e');
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: const Text('Connect GitHub'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a Personal Access Token with repo and read:org scopes.',
              style: TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              obscureText: _obscure,
              style: const TextStyle(
                color: CodeOpsColors.textPrimary,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: 'Personal Access Token',
                hintText: 'ghp_...',
                filled: true,
                fillColor: CodeOpsColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: CodeOpsColors.primary),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: CodeOpsColors.textTertiary,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: CodeOpsColors.error,
                  fontSize: 13,
                ),
              ),
            ],
            if (_success != null) ...[
              const SizedBox(height: 12),
              Text(
                _success!,
                style: const TextStyle(
                  color: CodeOpsColors.success,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _testing ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: CodeOpsColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _testing ? null : _testAndSave,
          child: _testing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Test & Save'),
        ),
      ],
    );
  }
}
