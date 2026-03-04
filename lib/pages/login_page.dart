/// Fully functional login and registration page.
///
/// Provides tabbed Sign In / Register forms with validation,
/// loading states, and error display. On success, stores tokens
/// and navigates to the home route.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../services/cloud/api_exceptions.dart';
import '../services/logging/log_service.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import '../utils/string_utils.dart';

/// Login and registration page.
///
/// Centered card with two tabs: Sign In and Register.
/// Handles validation, API calls, error display, and navigation.
class LoginPage extends ConsumerStatefulWidget {
  /// Creates a [LoginPage].
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Server URL
  final _serverUrlController = TextEditingController();

  // Sign-in form
  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  // Register form
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() => _errorMessage = null);
    });
    _serverUrlController.text = ref.read(serverUrlProvider);
    _restoreRememberedCredentials();
  }

  Future<void> _restoreRememberedCredentials() async {
    final storage = ref.read(secureStorageProvider);
    final remembered = await storage.read(AppConstants.keyRememberMe);
    if (remembered == 'true') {
      final email = await storage.read(AppConstants.keyRememberedEmail);
      final password = await storage.read(AppConstants.keyRememberedPassword);
      if (mounted) {
        setState(() {
          _rememberMe = true;
          if (email != null) _signInEmailController.text = email;
          if (password != null) _signInPasswordController.text = password;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serverUrlController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  void _applyServerUrl() {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null ||
        (!uri.isScheme('http') && !uri.isScheme('https')) ||
        uri.host.isEmpty) {
      setState(() => _errorMessage = 'Invalid server URL. Use http:// or https://');
      return;
    }

    // Strip trailing slash for consistency.
    final normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    ref.read(serverUrlProvider.notifier).state = normalized;
    ref.read(secureStorageProvider).setServerUrl(normalized);
    setState(() => _errorMessage = null);
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final email = _signInEmailController.text.trim();
      final password = _signInPasswordController.text;
      final user = await authService.login(email, password);

      // Save or clear remembered credentials.
      final storage = ref.read(secureStorageProvider);
      if (_rememberMe) {
        await storage.write(AppConstants.keyRememberMe, 'true');
        await storage.write(AppConstants.keyRememberedEmail, email);
        await storage.write(AppConstants.keyRememberedPassword, password);
      } else {
        await storage.delete(AppConstants.keyRememberMe);
        await storage.delete(AppConstants.keyRememberedEmail);
        await storage.delete(AppConstants.keyRememberedPassword);
      }

      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go('/');
    } catch (e, st) {
      log.e('LoginPage', 'Sign-in failed', e, st);
      setState(() => _errorMessage = _extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.register(
        _registerEmailController.text.trim(),
        _registerPasswordController.text,
        _registerNameController.text.trim(),
      );
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go('/');
    } catch (e, st) {
      log.e('LoginPage', 'Registration failed', e, st);
      setState(() => _errorMessage = _extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final apiError = error.error;
      if (apiError is ApiException) return apiError.message;
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to the server.';
      }
      return 'A network error occurred.';
    }
    return 'An unexpected error occurred.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CodeOpsColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo and title
                const Icon(
                  Icons.code_rounded,
                  size: 48,
                  color: CodeOpsColors.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'CodeOps',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CodeOpsColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI-Powered Software Maintenance',
                  style: TextStyle(
                    fontSize: 14,
                    color: CodeOpsColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),

                // Server URL field
                Row(
                  children: [
                    const Icon(
                      Icons.dns_outlined,
                      size: 16,
                      color: CodeOpsColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Server',
                      style: TextStyle(
                        fontSize: 12,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: TextField(
                          controller: _serverUrlController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: CodeOpsColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: CodeOpsColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        tooltip: 'Apply server URL',
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: CodeOpsColors.textTertiary,
                        ),
                        onPressed: _applyServerUrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card with tabs
                Container(
                  decoration: BoxDecoration(
                    color: CodeOpsColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CodeOpsColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tab bar
                      TabBar(
                        controller: _tabController,
                        indicatorColor: CodeOpsColors.primary,
                        labelColor: CodeOpsColors.textPrimary,
                        unselectedLabelColor: CodeOpsColors.textTertiary,
                        dividerColor: CodeOpsColors.border,
                        tabs: const [
                          Tab(text: 'Sign In'),
                          Tab(text: 'Register'),
                        ],
                      ),

                      // Error banner
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: CodeOpsColors.error.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: CodeOpsColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: CodeOpsColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Tab views
                      SizedBox(
                        height: 480,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSignInForm(),
                            SingleChildScrollView(
                              child: _buildRegisterForm(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _signInEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!isValidEmail(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signInPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignIn(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) =>
                        setState(() => _rememberMe = v ?? false),
                    activeColor: CodeOpsColors.primary,
                    side: const BorderSide(color: CodeOpsColors.textTertiary),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      setState(() => _rememberMe = !_rememberMe),
                  child: const Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 13,
                      color: CodeOpsColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignIn,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _registerNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person_outlined, size: 20),
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Display name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!isValidEmail(value.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined, size: 20),
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerConfirmController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _registerPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
