/// Auth tab content for the Courier request builder.
///
/// Displays a dropdown to select the [AuthType], renders the appropriate
/// configuration form for each type, and shows a read-only auth preview of
/// what will be applied to the request.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/courier_enums.dart';
import '../../providers/courier_ui_providers.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthTab
// ─────────────────────────────────────────────────────────────────────────────

/// The Auth sub-tab in the request builder.
///
/// Shows an auth type dropdown at the top, the appropriate configuration form
/// below, and an auth preview section at the bottom.
class AuthTab extends ConsumerWidget {
  /// Available variable names for `{{}}` autocomplete.
  final List<String> variableNames;

  /// Creates an [AuthTab].
  const AuthTab({super.key, this.variableNames = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authType = ref.watch(authTypeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Auth type selector.
        _AuthTypeSelector(
          selected: authType,
          onChanged: (type) {
            ref.read(authTypeProvider.notifier).state = type;
          },
        ),
        const Divider(height: 1, thickness: 1, color: CodeOpsColors.border),
        // Form content.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildForm(ref, authType),
                const SizedBox(height: 16),
                _AuthPreview(authType: authType),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(WidgetRef ref, AuthType authType) {
    switch (authType) {
      case AuthType.noAuth:
        return const _NoAuthForm();
      case AuthType.apiKey:
        return const _ApiKeyForm();
      case AuthType.bearerToken:
        return const _BearerTokenForm();
      case AuthType.basicAuth:
        return const _BasicAuthForm();
      case AuthType.oauth2AuthorizationCode:
        return const _OAuth2AuthCodeForm();
      case AuthType.oauth2ClientCredentials:
        return const _OAuth2ClientCredForm();
      case AuthType.oauth2Implicit:
        return const _OAuth2ImplicitForm();
      case AuthType.oauth2Password:
        return const _OAuth2PasswordForm();
      case AuthType.jwtBearer:
        return const _JwtBearerForm();
      case AuthType.inheritFromParent:
        return const _InheritForm();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthTypeSelector
// ─────────────────────────────────────────────────────────────────────────────

/// Dropdown for selecting the auth type.
class _AuthTypeSelector extends StatelessWidget {
  final AuthType selected;
  final ValueChanged<AuthType> onChanged;

  const _AuthTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('auth_type_selector'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          const Text(
            'Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: CodeOpsColors.background,
              border: Border.all(color: CodeOpsColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AuthType>(
                key: const Key('auth_type_dropdown'),
                value: selected,
                isDense: true,
                dropdownColor: CodeOpsColors.surfaceVariant,
                items: AuthType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CodeOpsColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// A labeled text field used in auth forms.
class _AuthField extends ConsumerWidget {
  final Key? fieldKey;
  final String label;
  final StateProvider<String> provider;
  final bool obscure;
  final String hint;
  final int maxLines;

  const _AuthField({
    this.fieldKey,
    required this.label,
    required this.provider,
    this.obscure = false,
    this.hint = '',
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ObscurableField(
              fieldKey: fieldKey,
              value: value,
              obscure: obscure,
              hint: hint,
              maxLines: maxLines,
              onChanged: (v) {
                ref.read(provider.notifier).state = v;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A text field with optional password toggle.
class _ObscurableField extends StatefulWidget {
  final Key? fieldKey;
  final String value;
  final bool obscure;
  final String hint;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _ObscurableField({
    this.fieldKey,
    required this.value,
    required this.obscure,
    required this.hint,
    required this.maxLines,
    required this.onChanged,
  });

  @override
  State<_ObscurableField> createState() => _ObscurableFieldState();
}

class _ObscurableFieldState extends State<_ObscurableField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.fieldKey,
      controller: TextEditingController(text: widget.value)
        ..selection = TextSelection.collapsed(offset: widget.value.length),
      style: const TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
        color: CodeOpsColors.textPrimary,
      ),
      obscureText: _hidden,
      maxLines: _hidden ? 1 : widget.maxLines,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: CodeOpsColors.textTertiary,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: CodeOpsColors.background,
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
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _hidden ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                  color: CodeOpsColors.textTertiary,
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(maxWidth: 32, maxHeight: 32),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No Auth
// ─────────────────────────────────────────────────────────────────────────────

class _NoAuthForm extends StatelessWidget {
  const _NoAuthForm();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('no_auth_message'),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_open, size: 32,
                color: CodeOpsColors.textTertiary),
            SizedBox(height: 8),
            Text(
              'This request does not use any authorization.',
              style: TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API Key
// ─────────────────────────────────────────────────────────────────────────────

class _ApiKeyForm extends ConsumerWidget {
  const _ApiKeyForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addTo = ref.watch(authApiKeyAddToProvider);

    return Column(
      key: const Key('api_key_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthField(
          fieldKey: Key('api_key_header_field'),
          label: 'Key',
          provider: authApiKeyHeaderProvider,
          hint: 'X-API-Key',
        ),
        _AuthField(
          fieldKey: Key('api_key_value_field'),
          label: 'Value',
          provider: authApiKeyValueProvider,
          hint: '{{api_key}}',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const SizedBox(
                width: 140,
                child: Text(
                  'Add to',
                  style: TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.background,
                  border: Border.all(color: CodeOpsColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('api_key_add_to_dropdown'),
                    value: addTo,
                    isDense: true,
                    dropdownColor: CodeOpsColors.surfaceVariant,
                    items: const [
                      DropdownMenuItem(
                        value: 'header',
                        child: Text('Header',
                            style: TextStyle(
                                fontSize: 12,
                                color: CodeOpsColors.textPrimary)),
                      ),
                      DropdownMenuItem(
                        value: 'query',
                        child: Text('Query Params',
                            style: TextStyle(
                                fontSize: 12,
                                color: CodeOpsColors.textPrimary)),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(authApiKeyAddToProvider.notifier).state = v;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bearer Token
// ─────────────────────────────────────────────────────────────────────────────

class _BearerTokenForm extends StatelessWidget {
  const _BearerTokenForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('bearer_token_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthField(
          fieldKey: const Key('bearer_token_field'),
          label: 'Token',
          provider: authBearerTokenProvider,
          obscure: true,
          hint: '{{access_token}}',
        ),
        _AuthField(
          fieldKey: const Key('bearer_prefix_field'),
          label: 'Prefix',
          provider: authBearerPrefixProvider,
          hint: 'Bearer',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Basic Auth
// ─────────────────────────────────────────────────────────────────────────────

class _BasicAuthForm extends ConsumerWidget {
  const _BasicAuthForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(authBasicUsernameProvider);
    final password = ref.watch(authBasicPasswordProvider);

    String headerPreview = '';
    if (username.isNotEmpty || password.isNotEmpty) {
      final encoded = base64Encode(utf8.encode('$username:$password'));
      headerPreview = 'Basic $encoded';
    }

    return Column(
      key: const Key('basic_auth_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthField(
          fieldKey: Key('basic_username_field'),
          label: 'Username',
          provider: authBasicUsernameProvider,
          hint: 'username',
        ),
        _AuthField(
          fieldKey: Key('basic_password_field'),
          label: 'Password',
          provider: authBasicPasswordProvider,
          obscure: true,
          hint: 'password',
        ),
        if (headerPreview.isNotEmpty)
          Container(
            key: const Key('basic_auth_preview'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CodeOpsColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CodeOpsColors.border),
            ),
            child: Text(
              'Authorization: $headerPreview',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CodeOpsColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OAuth 2.0 — Authorization Code
// ─────────────────────────────────────────────────────────────────────────────

class _OAuth2AuthCodeForm extends StatelessWidget {
  const _OAuth2AuthCodeForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('oauth2_auth_code_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthField(
          fieldKey: Key('oauth2_auth_url_field'),
          label: 'Auth URL',
          provider: authOAuth2AuthUrlProvider,
          hint: 'https://provider.com/authorize',
        ),
        _AuthField(
          fieldKey: Key('oauth2_token_url_field'),
          label: 'Access Token URL',
          provider: authOAuth2TokenUrlProvider,
          hint: 'https://provider.com/token',
        ),
        _AuthField(
          fieldKey: Key('oauth2_client_id_field'),
          label: 'Client ID',
          provider: authOAuth2ClientIdProvider,
          hint: 'client-id',
        ),
        _AuthField(
          fieldKey: Key('oauth2_client_secret_field'),
          label: 'Client Secret',
          provider: authOAuth2ClientSecretProvider,
          obscure: true,
          hint: 'client-secret',
        ),
        _AuthField(
          fieldKey: Key('oauth2_scope_field'),
          label: 'Scope',
          provider: authOAuth2ScopeProvider,
          hint: 'read write',
        ),
        _AuthField(
          fieldKey: Key('oauth2_callback_url_field'),
          label: 'Redirect URI',
          provider: authOAuth2CallbackUrlProvider,
          hint: 'https://localhost/callback',
        ),
        _OAuth2GetTokenButton(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OAuth 2.0 — Client Credentials
// ─────────────────────────────────────────────────────────────────────────────

class _OAuth2ClientCredForm extends StatelessWidget {
  const _OAuth2ClientCredForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('oauth2_client_cred_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthField(
          fieldKey: Key('oauth2_cc_token_url_field'),
          label: 'Access Token URL',
          provider: authOAuth2TokenUrlProvider,
          hint: 'https://provider.com/token',
        ),
        _AuthField(
          fieldKey: Key('oauth2_cc_client_id_field'),
          label: 'Client ID',
          provider: authOAuth2ClientIdProvider,
          hint: 'client-id',
        ),
        _AuthField(
          fieldKey: Key('oauth2_cc_client_secret_field'),
          label: 'Client Secret',
          provider: authOAuth2ClientSecretProvider,
          obscure: true,
          hint: 'client-secret',
        ),
        _AuthField(
          fieldKey: Key('oauth2_cc_scope_field'),
          label: 'Scope',
          provider: authOAuth2ScopeProvider,
          hint: 'read write',
        ),
        _OAuth2GetTokenButton(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OAuth 2.0 — Implicit
// ─────────────────────────────────────────────────────────────────────────────

class _OAuth2ImplicitForm extends StatelessWidget {
  const _OAuth2ImplicitForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('oauth2_implicit_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthField(
          fieldKey: Key('oauth2_imp_auth_url_field'),
          label: 'Auth URL',
          provider: authOAuth2AuthUrlProvider,
          hint: 'https://provider.com/authorize',
        ),
        _AuthField(
          fieldKey: Key('oauth2_imp_client_id_field'),
          label: 'Client ID',
          provider: authOAuth2ClientIdProvider,
          hint: 'client-id',
        ),
        _AuthField(
          fieldKey: Key('oauth2_imp_scope_field'),
          label: 'Scope',
          provider: authOAuth2ScopeProvider,
          hint: 'read write',
        ),
        _AuthField(
          fieldKey: Key('oauth2_imp_callback_url_field'),
          label: 'Redirect URI',
          provider: authOAuth2CallbackUrlProvider,
          hint: 'https://localhost/callback',
        ),
        _OAuth2GetTokenButton(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OAuth 2.0 — Password
// ─────────────────────────────────────────────────────────────────────────────

class _OAuth2PasswordForm extends StatelessWidget {
  const _OAuth2PasswordForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('oauth2_password_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthField(
          fieldKey: Key('oauth2_pw_token_url_field'),
          label: 'Access Token URL',
          provider: authOAuth2TokenUrlProvider,
          hint: 'https://provider.com/token',
        ),
        _AuthField(
          fieldKey: Key('oauth2_pw_username_field'),
          label: 'Username',
          provider: authBasicUsernameProvider,
          hint: 'username',
        ),
        _AuthField(
          fieldKey: Key('oauth2_pw_password_field'),
          label: 'Password',
          provider: authBasicPasswordProvider,
          obscure: true,
          hint: 'password',
        ),
        _AuthField(
          fieldKey: Key('oauth2_pw_client_id_field'),
          label: 'Client ID',
          provider: authOAuth2ClientIdProvider,
          hint: 'client-id',
        ),
        _AuthField(
          fieldKey: Key('oauth2_pw_client_secret_field'),
          label: 'Client Secret',
          provider: authOAuth2ClientSecretProvider,
          obscure: true,
          hint: 'client-secret',
        ),
        _AuthField(
          fieldKey: Key('oauth2_pw_scope_field'),
          label: 'Scope',
          provider: authOAuth2ScopeProvider,
          hint: 'read write',
        ),
        _OAuth2GetTokenButton(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OAuth 2.0 — Get Token Button
// ─────────────────────────────────────────────────────────────────────────────

class _OAuth2GetTokenButton extends StatelessWidget {
  const _OAuth2GetTokenButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ElevatedButton.icon(
        key: const Key('oauth2_get_token_button'),
        icon: const Icon(Icons.vpn_key, size: 14),
        label: const Text('Get New Access Token',
            style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: CodeOpsColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onPressed: () {
          // OAuth flow will be wired in execution phase.
          // Opens system browser for auth code flow, or POSTs to token URL
          // for client credentials / password flows.
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JWT Bearer
// ─────────────────────────────────────────────────────────────────────────────

class _JwtBearerForm extends ConsumerWidget {
  const _JwtBearerForm();

  static const _algorithms = [
    'HS256', 'HS384', 'HS512', 'RS256', 'RS384', 'RS512',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final algorithm = ref.watch(authJwtAlgorithmProvider);

    return Column(
      key: const Key('jwt_bearer_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Algorithm dropdown.
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const SizedBox(
                width: 140,
                child: Text(
                  'Algorithm',
                  style: TextStyle(
                    fontSize: 12,
                    color: CodeOpsColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.background,
                  border: Border.all(color: CodeOpsColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('jwt_algorithm_dropdown'),
                    value: algorithm,
                    isDense: true,
                    dropdownColor: CodeOpsColors.surfaceVariant,
                    items: _algorithms
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(
                              a,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CodeOpsColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(authJwtAlgorithmProvider.notifier).state = v;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        _AuthField(
          fieldKey: Key('jwt_secret_field'),
          label: 'Secret / Private Key',
          provider: authJwtSecretProvider,
          obscure: true,
          hint: 'your-256-bit-secret',
          maxLines: 3,
        ),
        _AuthField(
          fieldKey: Key('jwt_payload_field'),
          label: 'Payload',
          provider: authJwtPayloadProvider,
          hint: '{"sub": "1234567890", "iat": 1516239022}',
          maxLines: 4,
        ),
        // Generate button.
        ElevatedButton.icon(
          key: const Key('jwt_generate_button'),
          icon: const Icon(Icons.vpn_key, size: 14),
          label:
              const Text('Generate Token', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: () {
            // JWT generation will use dart_jsonwebtoken or similar.
            // For now, stub — the token manager display shows the result.
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inherit from Parent
// ─────────────────────────────────────────────────────────────────────────────

class _InheritForm extends StatelessWidget {
  const _InheritForm();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('inherit_auth_message'),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree, size: 32,
                color: CodeOpsColors.textTertiary),
            SizedBox(height: 8),
            Text(
              'This request inherits auth from its parent folder or collection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: CodeOpsColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The resolved auth will be applied at execution time.',
              style: TextStyle(
                fontSize: 11,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AuthPreview
// ─────────────────────────────────────────────────────────────────────────────

/// Read-only preview showing what auth will be added to the request.
class _AuthPreview extends ConsumerWidget {
  final AuthType authType;

  const _AuthPreview({required this.authType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = _buildPreviewText(ref, authType);
    if (preview == null) return const SizedBox.shrink();

    return Container(
      key: const Key('auth_preview'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CodeOpsColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.preview, size: 14,
                  color: CodeOpsColors.textTertiary),
              SizedBox(width: 6),
              Text(
                'Request Preview',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CodeOpsColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            preview,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: CodeOpsColors.textTertiary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String? _buildPreviewText(WidgetRef ref, AuthType type) {
    switch (type) {
      case AuthType.noAuth:
      case AuthType.inheritFromParent:
        return null;

      case AuthType.apiKey:
        final header = ref.watch(authApiKeyHeaderProvider);
        final value = ref.watch(authApiKeyValueProvider);
        final addTo = ref.watch(authApiKeyAddToProvider);
        if (header.isEmpty && value.isEmpty) return null;
        if (addTo == 'query') return '?$header=$value';
        return '$header: $value';

      case AuthType.bearerToken:
        final token = ref.watch(authBearerTokenProvider);
        final prefix = ref.watch(authBearerPrefixProvider);
        if (token.isEmpty) return null;
        final display = token.length > 30
            ? '${token.substring(0, 15)}...${token.substring(token.length - 10)}'
            : token;
        return 'Authorization: $prefix $display';

      case AuthType.basicAuth:
        final user = ref.watch(authBasicUsernameProvider);
        final pass = ref.watch(authBasicPasswordProvider);
        if (user.isEmpty && pass.isEmpty) return null;
        final encoded = base64Encode(utf8.encode('$user:$pass'));
        return 'Authorization: Basic $encoded';

      case AuthType.oauth2AuthorizationCode:
      case AuthType.oauth2ClientCredentials:
      case AuthType.oauth2Implicit:
      case AuthType.oauth2Password:
        final token = ref.watch(authOAuth2AccessTokenProvider);
        if (token.isEmpty) return 'Authorization: Bearer <token not yet obtained>';
        final display = token.length > 30
            ? '${token.substring(0, 15)}...${token.substring(token.length - 10)}'
            : token;
        return 'Authorization: Bearer $display';

      case AuthType.jwtBearer:
        final token = ref.watch(authJwtGeneratedTokenProvider);
        if (token.isEmpty) return 'Authorization: Bearer <token not yet generated>';
        final display = token.length > 30
            ? '${token.substring(0, 15)}...${token.substring(token.length - 10)}'
            : token;
        return 'Authorization: Bearer $display';
    }
  }
}
