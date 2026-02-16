/// Provides key-value storage backed by SharedPreferences (UserDefaults on macOS).
///
/// Replaces flutter_secure_storage (Keychain-backed) to avoid macOS password
/// dialogs when the App Sandbox is disabled. This is a local dev tool —
/// OS-level encryption is unnecessary.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';
import '../logging/log_service.dart';

/// Provides key-value storage backed by SharedPreferences.
///
/// On macOS, uses UserDefaults. On Windows, uses the Registry.
/// On Linux, uses XDG config files.
///
/// Used primarily for storing authentication tokens, but also available
/// for any data like API keys or connection credentials.
class SecureStorageService {
  SharedPreferences? _prefs;

  /// Creates a [SecureStorageService] with optional [prefs] for test injection.
  SecureStorageService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Lazily initializes and returns the [SharedPreferences] instance.
  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Reads the JWT access token, or null if not stored.
  Future<String?> getAuthToken() async =>
      (await _storage).getString(AppConstants.keyAuthToken);

  /// Persists the JWT access token to storage.
  Future<void> setAuthToken(String token) async =>
      (await _storage).setString(AppConstants.keyAuthToken, token);

  /// Reads the refresh token, or null if not stored.
  Future<String?> getRefreshToken() async =>
      (await _storage).getString(AppConstants.keyRefreshToken);

  /// Persists the refresh token to storage.
  Future<void> setRefreshToken(String token) async =>
      (await _storage).setString(AppConstants.keyRefreshToken, token);

  /// Reads the current user's ID, or null if not logged in.
  Future<String?> getCurrentUserId() async =>
      (await _storage).getString(AppConstants.keyCurrentUserId);

  /// Stores the current user's ID.
  Future<void> setCurrentUserId(String userId) async =>
      (await _storage).setString(AppConstants.keyCurrentUserId, userId);

  /// Reads the currently selected team ID.
  Future<String?> getSelectedTeamId() async =>
      (await _storage).getString(AppConstants.keySelectedTeamId);

  /// Stores the currently selected team ID.
  Future<void> setSelectedTeamId(String teamId) async =>
      (await _storage).setString(AppConstants.keySelectedTeamId, teamId);

  /// Reads an arbitrary key from storage.
  Future<String?> read(String key) async => (await _storage).getString(key);

  /// Writes an arbitrary key-value pair to storage.
  Future<void> write(String key, String value) async {
    log.d('SecureStorage', 'Write key=$key');
    await (await _storage).setString(key, value);
  }

  /// Deletes a specific key from storage.
  Future<void> delete(String key) async {
    log.d('SecureStorage', 'Delete key=$key');
    await (await _storage).remove(key);
  }

  /// Reads the Anthropic API key, or null if not stored.
  Future<String?> getAnthropicApiKey() async =>
      (await _storage).getString(AppConstants.keyAnthropicApiKey);

  /// Persists the Anthropic API key to storage.
  Future<void> setAnthropicApiKey(String apiKey) async =>
      (await _storage).setString(AppConstants.keyAnthropicApiKey, apiKey);

  /// Deletes the Anthropic API key from storage.
  Future<void> deleteAnthropicApiKey() async =>
      (await _storage).remove(AppConstants.keyAnthropicApiKey);

  /// Clears session data on logout, preserving "Remember Me" credentials
  /// and the Anthropic API key.
  Future<void> clearAll() async {
    log.d('SecureStorage', 'Clear all (preserving remember-me + API key)');
    final prefs = await _storage;

    // Preserve remember-me data across logout.
    final rememberMe = prefs.getString(AppConstants.keyRememberMe);
    final email = prefs.getString(AppConstants.keyRememberedEmail);
    final password = prefs.getString(AppConstants.keyRememberedPassword);

    // Preserve Anthropic API key across logout.
    final anthropicKey = prefs.getString(AppConstants.keyAnthropicApiKey);

    await prefs.clear();

    // Restore remembered credentials.
    if (rememberMe != null) {
      await prefs.setString(AppConstants.keyRememberMe, rememberMe);
    }
    if (email != null) {
      await prefs.setString(AppConstants.keyRememberedEmail, email);
    }
    if (password != null) {
      await prefs.setString(AppConstants.keyRememberedPassword, password);
    }

    // Restore Anthropic API key.
    if (anthropicKey != null) {
      await prefs.setString(AppConstants.keyAnthropicApiKey, anthropicKey);
    }
  }
}
