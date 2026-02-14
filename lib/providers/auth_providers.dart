/// Riverpod providers for authentication state and services.
///
/// Provides singletons for [SecureStorageService], [ApiClient],
/// [AuthService], and the local [CodeOpsDatabase]. Also exposes
/// the current auth state and authenticated user.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart' hide User;
import '../models/user.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/secure_storage.dart';
import '../services/cloud/api_client.dart';

/// Provides the [SecureStorageService] singleton.
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

/// Provides the [ApiClient] singleton, configured with secure storage.
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: secureStorage);
});

/// Provides the local Drift database singleton.
final databaseProvider = Provider<CodeOpsDatabase>(
  (ref) => CodeOpsDatabase.defaults(),
);

/// Provides the [AuthService] singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final database = ref.watch(databaseProvider);
  return AuthService(
    apiClient: apiClient,
    secureStorage: secureStorage,
    database: database,
  );
});

/// Provides the current [AuthState] as a stream.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateStream;
});

/// Provides the currently authenticated [User], or null.
final currentUserProvider = StateProvider<User?>((ref) => null);
