/// Riverpod providers for admin and system management data.
///
/// Exposes the [AdminApi] service, user management, system settings,
/// usage statistics, audit logs, and admin UI state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_snapshot.dart';
import '../models/user.dart';
import '../services/cloud/admin_api.dart';
import '../utils/constants.dart';
import 'auth_providers.dart';
import 'team_providers.dart';

// ---------------------------------------------------------------------------
// API provider
// ---------------------------------------------------------------------------

/// Provides [AdminApi] for admin endpoints.
final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(apiClientProvider)),
);

// ---------------------------------------------------------------------------
// UI state providers
// ---------------------------------------------------------------------------

/// Currently selected admin tab index.
final adminTabIndexProvider = StateProvider<int>((ref) => 0);

/// Search query for the admin users list.
final adminUserSearchProvider = StateProvider<String>((ref) => '');

/// Current page index for the admin users list.
final adminUserPageProvider = StateProvider<int>((ref) => 0);

/// Current page index for the audit log.
final auditLogPageProvider = StateProvider<int>((ref) => 0);

/// Action filter for the audit log.
final auditLogActionFilterProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

/// Fetches paginated user list for admin view.
final adminUsersProvider = FutureProvider<PageResponse<User>>((ref) async {
  final adminApi = ref.watch(adminApiProvider);
  final page = ref.watch(adminUserPageProvider);
  return adminApi.getAllUsers(page: page, size: AppConstants.defaultPageSize);
});

/// Fetches a single user by ID for admin detail view.
final adminUserDetailProvider =
    FutureProvider.family<User, String>((ref, userId) async {
  final adminApi = ref.watch(adminApiProvider);
  return adminApi.getUserById(userId);
});

/// Fetches all system settings.
final systemSettingsProvider =
    FutureProvider<List<SystemSetting>>((ref) async {
  final adminApi = ref.watch(adminApiProvider);
  return adminApi.getAllSettings();
});

/// Fetches team usage statistics.
final usageStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final adminApi = ref.watch(adminApiProvider);
  return adminApi.getUsageStats();
});

/// Fetches the team audit log (paginated).
final teamAuditLogProvider =
    FutureProvider<PageResponse<AuditLogEntry>>((ref) async {
  final adminApi = ref.watch(adminApiProvider);
  final teamId = ref.watch(selectedTeamIdProvider);
  if (teamId == null) return PageResponse.empty();
  final page = ref.watch(auditLogPageProvider);
  return adminApi.getTeamAuditLog(
    teamId,
    page: page,
    size: AppConstants.defaultPageSize,
  );
});

/// Fetches a user's audit log (paginated).
final userAuditLogProvider =
    FutureProvider.family<PageResponse<AuditLogEntry>, String>(
  (ref, userId) async {
    final adminApi = ref.watch(adminApiProvider);
    final page = ref.watch(auditLogPageProvider);
    return adminApi.getUserAuditLog(
      userId,
      page: page,
      size: AppConstants.defaultPageSize,
    );
  },
);
