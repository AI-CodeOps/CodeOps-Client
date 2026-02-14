/// API service for admin and system management endpoints.
///
/// Restricted to users with ADMIN or OWNER roles.
library;

import '../../models/health_snapshot.dart';
import '../../models/user.dart';
import 'api_client.dart';

/// API service for admin and system management endpoints.
///
/// Provides typed methods for user management, system settings,
/// audit logs, and usage statistics. Restricted to admin/owner roles.
class AdminApi {
  final ApiClient _client;

  /// Creates an [AdminApi] backed by the given [client].
  AdminApi(this._client);

  /// Fetches all users (admin view, paginated).
  ///
  /// Returns a [PageResponse] of [User] objects.
  Future<PageResponse<User>> getAllUsers({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches a user by [userId] (admin view).
  Future<User> getUserById(String userId) async {
    final response =
        await _client.get<Map<String, dynamic>>('/admin/users/$userId');
    return User.fromJson(response.data!);
  }

  /// Updates a user's active status.
  Future<User> updateUserStatus(
    String userId, {
    required bool isActive,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/admin/users/$userId',
      data: {'isActive': isActive},
    );
    return User.fromJson(response.data!);
  }

  /// Fetches all system settings.
  Future<List<SystemSetting>> getAllSettings() async {
    final response = await _client.get<List<dynamic>>('/admin/settings');
    return response.data!
        .map((e) => SystemSetting.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a system setting by [key].
  Future<SystemSetting> getSetting(String key) async {
    final response =
        await _client.get<Map<String, dynamic>>('/admin/settings/$key');
    return SystemSetting.fromJson(response.data!);
  }

  /// Updates a system setting.
  Future<SystemSetting> updateSetting({
    required String key,
    required String value,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/admin/settings',
      data: {'key': key, 'value': value},
    );
    return SystemSetting.fromJson(response.data!);
  }

  /// Fetches team usage statistics.
  ///
  /// Returns a raw map as the response schema varies.
  Future<Map<String, dynamic>> getUsageStats() async {
    final response =
        await _client.get<Map<String, dynamic>>('/admin/usage');
    return response.data!;
  }

  /// Fetches the audit log for a team (paginated).
  Future<PageResponse<AuditLogEntry>> getTeamAuditLog(
    String teamId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/admin/audit-log/team/$teamId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => AuditLogEntry.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches the audit log for a specific user (paginated).
  Future<PageResponse<AuditLogEntry>> getUserAuditLog(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/admin/audit-log/user/$userId',
      queryParameters: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(
      response.data!,
      (json) => AuditLogEntry.fromJson(json as Map<String, dynamic>),
    );
  }
}
