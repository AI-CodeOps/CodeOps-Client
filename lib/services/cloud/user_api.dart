/// API service for user-related endpoints.
///
/// Endpoints: GET /users/me, GET /users/{id}, PUT /users/{id},
/// GET /users/search, PUT /users/{id}/activate, PUT /users/{id}/deactivate.
library;

import '../../models/user.dart';
import 'api_client.dart';

/// API service for user-related endpoints.
///
/// Provides typed methods for fetching, updating, searching, and managing
/// user accounts via the CodeOps server.
class UserApi {
  final ApiClient _client;

  /// Creates a [UserApi] backed by the given [client].
  UserApi(this._client);

  /// Fetches the currently authenticated user's profile.
  Future<User> getCurrentUser() async {
    final response = await _client.get<Map<String, dynamic>>('/users/me');
    return User.fromJson(response.data!);
  }

  /// Fetches a user by their [id].
  Future<User> getUserById(String id) async {
    final response = await _client.get<Map<String, dynamic>>('/users/$id');
    return User.fromJson(response.data!);
  }

  /// Updates the current user's profile.
  ///
  /// Only non-null parameters are included in the request body.
  Future<User> updateUser(
    String id, {
    String? displayName,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await _client.put<Map<String, dynamic>>(
      '/users/$id',
      data: body,
    );
    return User.fromJson(response.data!);
  }

  /// Searches users by display name (partial, case-insensitive).
  Future<List<User>> searchUsers(String query) async {
    final response = await _client.get<List<dynamic>>(
      '/users/search',
      queryParameters: {'q': query},
    );
    return response.data!.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Deactivates a user account by [id].
  Future<void> deactivateUser(String id) async {
    await _client.put('/users/$id/deactivate');
  }

  /// Activates a user account by [id].
  Future<void> activateUser(String id) async {
    await _client.put('/users/$id/activate');
  }
}
