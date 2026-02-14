/// Manages authentication lifecycle: login, registration, token refresh,
/// and logout.
///
/// Coordinates between the [ApiClient] for server communication and
/// [SecureStorageService] for token persistence. Exposes an [authStateStream]
/// that the router and providers listen to for reactive auth state changes.
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../../database/database.dart' hide User;
import '../../models/health_snapshot.dart';
import '../../models/user.dart';
import '../cloud/api_client.dart';
import '../cloud/api_exceptions.dart';
import 'secure_storage.dart';

/// Represents the current authentication state of the application.
enum AuthState {
  /// Initial state before auth check completes.
  unknown,

  /// User is authenticated with valid tokens.
  authenticated,

  /// User is not authenticated (no tokens or tokens expired).
  unauthenticated,
}

/// Manages authentication lifecycle: login, registration, token refresh,
/// and logout.
///
/// Coordinates between the [ApiClient] for server communication and
/// [SecureStorageService] for token persistence. Exposes an [authStateStream]
/// that the router and providers listen to for reactive auth state changes.
class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final CodeOpsDatabase _database;

  final _authStateController = StreamController<AuthState>.broadcast();

  /// Stream of authentication state changes.
  ///
  /// Emits [AuthState.authenticated] after successful login/register,
  /// [AuthState.unauthenticated] after logout or token expiry.
  Stream<AuthState> get authStateStream => _authStateController.stream;

  AuthState _currentState = AuthState.unknown;

  /// The current authentication state.
  AuthState get currentState => _currentState;

  /// The currently authenticated user, or null.
  User? _currentUser;

  /// The currently authenticated user, or null.
  User? get currentUser => _currentUser;

  /// Creates an [AuthService] configured with the given dependencies.
  AuthService({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
    required CodeOpsDatabase database,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage,
        _database = database {
    _apiClient.onAuthFailure = _handleAuthFailure;
  }

  /// Authenticates a user with [email] and [password].
  ///
  /// Stores the returned tokens and user ID in secure storage,
  /// emits [AuthState.authenticated], and returns the [User].
  Future<User> login(String email, String password) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final authResponse = AuthResponse.fromJson(response.data!);
    await _storeAuthData(authResponse);
    _setAuthState(AuthState.authenticated, authResponse.user);
    return authResponse.user;
  }

  /// Registers a new user account.
  ///
  /// Stores the returned tokens and user ID in secure storage,
  /// emits [AuthState.authenticated], and returns the [User].
  Future<User> register(
    String email,
    String password,
    String displayName,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data!);
    await _storeAuthData(authResponse);
    _setAuthState(AuthState.authenticated, authResponse.user);
    return authResponse.user;
  }

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Stores the new tokens in secure storage.
  Future<void> refreshToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) {
      _setAuthState(AuthState.unauthenticated, null);
      return;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final authResponse = AuthResponse.fromJson(response.data!);
    await _storeAuthData(authResponse);
    _currentUser = authResponse.user;
  }

  /// Changes the current user's password.
  ///
  /// Requires [currentPassword] for verification and sets [newPassword].
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _apiClient.post(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Logs out the current user.
  ///
  /// Clears all stored tokens, wipes the local database cache,
  /// and emits [AuthState.unauthenticated].
  Future<void> logout() async {
    await _secureStorage.clearAll();
    await _database.clearAllTables();
    _setAuthState(AuthState.unauthenticated, null);
  }

  /// Attempts to restore a previous session from stored tokens.
  ///
  /// Validates the stored access token by calling `GET /users/me`.
  /// On success, emits [AuthState.authenticated].
  /// On failure, clears stored data and emits [AuthState.unauthenticated].
  Future<void> tryAutoLogin() async {
    final token = await _secureStorage.getAuthToken();
    if (token == null) {
      _setAuthState(AuthState.unauthenticated, null);
      return;
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/users/me');
      final user = User.fromJson(response.data!);
      _setAuthState(AuthState.authenticated, user);
    } on DioException catch (e) {
      final error = e.error;
      if (error is UnauthorizedException) {
        await _secureStorage.clearAll();
      }
      _setAuthState(AuthState.unauthenticated, null);
    }
  }

  /// Releases resources held by this service.
  void dispose() {
    _authStateController.close();
  }

  /// Stores tokens and user ID from an [AuthResponse] in secure storage.
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    await _secureStorage.setAuthToken(authResponse.token);
    await _secureStorage.setRefreshToken(authResponse.refreshToken);
    await _secureStorage.setCurrentUserId(authResponse.user.id);
  }

  /// Updates the current auth state and notifies listeners.
  void _setAuthState(AuthState state, User? user) {
    _currentState = state;
    _currentUser = user;
    _authStateController.add(state);
  }

  /// Called by [ApiClient] when token refresh fails.
  void _handleAuthFailure() {
    _setAuthState(AuthState.unauthenticated, null);
  }
}
