/// Riverpod providers for user-related data.
///
/// Exposes the [UserApi] service, the current user profile,
/// and user search functionality.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/auth/auth_service.dart';
import '../services/cloud/user_api.dart';
import 'auth_providers.dart';

/// Provides [UserApi] for user endpoints.
final userApiProvider = Provider<UserApi>(
  (ref) => UserApi(ref.watch(apiClientProvider)),
);

/// Fetches the current user profile. Auto-refreshes on auth state change.
final currentUserProfileProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState != AuthState.authenticated) return null;
  final userApi = ref.watch(userApiProvider);
  return userApi.getCurrentUser();
});

/// Searches users by query string.
///
/// Returns an empty list when the query is shorter than 2 characters.
final userSearchProvider =
    FutureProvider.family<List<User>, String>((ref, query) async {
  if (query.length < 2) return [];
  final userApi = ref.watch(userApiProvider);
  return userApi.searchUsers(query);
});
