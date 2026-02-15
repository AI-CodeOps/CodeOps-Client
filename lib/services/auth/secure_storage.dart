/// Provides secure, encrypted key-value storage backed by the OS keychain.
///
/// On macOS, uses Keychain. On Windows, uses Windows Credential Locker.
/// On Linux, uses libsecret. All values are AES-encrypted at rest.
///
/// Used primarily for storing authentication tokens, but also available
/// for any sensitive data like API keys or connection credentials.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../utils/constants.dart';
import '../logging/log_service.dart';

/// Provides secure, encrypted key-value storage backed by the OS keychain.
///
/// On macOS, uses Keychain. On Windows, uses Windows Credential Locker.
/// On Linux, uses libsecret. All values are AES-encrypted at rest.
///
/// Used primarily for storing authentication tokens, but also available
/// for any sensitive data like API keys or connection credentials.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  /// Creates a [SecureStorageService] with optional custom [storage] instance.
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              lOptions: LinuxOptions(),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                useDataProtectionKeyChain: false,
              ),
            );

  /// Reads the JWT access token, or null if not stored.
  Future<String?> getAuthToken() async =>
      _storage.read(key: AppConstants.keyAuthToken);

  /// Persists the JWT access token to secure storage.
  Future<void> setAuthToken(String token) async =>
      _storage.write(key: AppConstants.keyAuthToken, value: token);

  /// Reads the refresh token, or null if not stored.
  Future<String?> getRefreshToken() async =>
      _storage.read(key: AppConstants.keyRefreshToken);

  /// Persists the refresh token to secure storage.
  Future<void> setRefreshToken(String token) async =>
      _storage.write(key: AppConstants.keyRefreshToken, value: token);

  /// Reads the current user's ID, or null if not logged in.
  Future<String?> getCurrentUserId() async =>
      _storage.read(key: AppConstants.keyCurrentUserId);

  /// Stores the current user's ID.
  Future<void> setCurrentUserId(String userId) async =>
      _storage.write(key: AppConstants.keyCurrentUserId, value: userId);

  /// Reads the currently selected team ID.
  Future<String?> getSelectedTeamId() async =>
      _storage.read(key: AppConstants.keySelectedTeamId);

  /// Stores the currently selected team ID.
  Future<void> setSelectedTeamId(String teamId) async =>
      _storage.write(key: AppConstants.keySelectedTeamId, value: teamId);

  /// Reads an arbitrary key from secure storage.
  Future<String?> read(String key) async => _storage.read(key: key);

  /// Writes an arbitrary key-value pair to secure storage.
  Future<void> write(String key, String value) async {
    log.d('SecureStorage', 'Write key=$key');
    return _storage.write(key: key, value: value);
  }

  /// Deletes a specific key from secure storage.
  Future<void> delete(String key) async {
    log.d('SecureStorage', 'Delete key=$key');
    return _storage.delete(key: key);
  }

  /// Clears ALL stored data. Called on logout.
  Future<void> clearAll() async {
    log.d('SecureStorage', 'Clear all');
    return _storage.deleteAll();
  }
}
