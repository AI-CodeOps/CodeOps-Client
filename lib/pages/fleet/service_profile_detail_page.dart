/// Service profile detail page for the Fleet module.
///
/// Displays a service profile at `/fleet/service-profiles/:profileId`
/// with three tabs: Configuration (read-only), Volumes, and Networks.
/// Provides edit and delete actions in the header.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/fleet_models.dart';
import '../../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/fleet/network_config_form_dialog.dart';
import '../../widgets/fleet/service_profile_config_tab.dart';
import '../../widgets/fleet/service_profile_form.dart';
import '../../widgets/fleet/service_profile_networks_tab.dart';
import '../../widgets/fleet/service_profile_volumes_tab.dart';
import '../../widgets/fleet/volume_mount_form_dialog.dart';
import '../../widgets/shared/confirm_dialog.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The service profile detail page at `/fleet/service-profiles/:profileId`.
class ServiceProfileDetailPage extends ConsumerStatefulWidget {
  /// The ID of the service profile to display.
  final String profileId;

  /// Creates a [ServiceProfileDetailPage].
  const ServiceProfileDetailPage({super.key, required this.profileId});

  @override
  ConsumerState<ServiceProfileDetailPage> createState() =>
      _ServiceProfileDetailPageState();
}

class _ServiceProfileDetailPageState
    extends ConsumerState<ServiceProfileDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Returns the currently selected team ID, or null.
  String? get _teamId => ref.read(selectedTeamIdProvider);

  /// Refreshes the profile detail.
  void _refresh() {
    final teamId = _teamId;
    if (teamId != null) {
      ref.invalidate(fleetServiceProfileDetailProvider);
    }
  }

  /// Opens the edit dialog for the current profile.
  Future<void> _editProfile(FleetServiceProfileDetail detail) async {
    final teamId = _teamId;
    if (teamId == null || detail.id == null) return;

    final result =
        await ServiceProfileFormDialog.show(context, existing: detail);
    if (result == null || result is! UpdateServiceProfileRequest) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.updateServiceProfile(teamId, detail.id!, result);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Deletes the current profile after confirmation.
  Future<void> _deleteProfile(FleetServiceProfileDetail detail) async {
    final teamId = _teamId;
    if (teamId == null || detail.id == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Service Profile',
      message:
          'Delete "${detail.displayName ?? detail.serviceName}"? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.deleteServiceProfile(teamId, detail.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service profile deleted')),
        );
        context.go('/fleet/service-profiles');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Opens the volume mount form dialog and handles the result.
  Future<void> _addVolume() async {
    final result = await VolumeMountFormDialog.show(context);
    if (result == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Volume mount saved locally. Server-side persistence requires API update.'),
        ),
      );
    }
  }

  /// Removes a volume mount after confirmation.
  Future<void> _removeVolume(FleetVolumeMount volume) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Volume Mount',
      message: 'Remove mount "${volume.containerPath}"?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Volume removal requires API update for server-side persistence.'),
        ),
      );
    }
  }

  /// Opens the network config form dialog and handles the result.
  Future<void> _addNetwork() async {
    final result = await NetworkConfigFormDialog.show(context);
    if (result == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Network config saved locally. Server-side persistence requires API update.'),
        ),
      );
    }
  }

  /// Removes a network config after confirmation.
  Future<void> _removeNetwork(FleetNetworkConfig network) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Network',
      message: 'Remove network "${network.networkName}"?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Network removal requires API update for server-side persistence.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to view service profiles.',
      );
    }

    final detailAsync = ref.watch(
      fleetServiceProfileDetailProvider(
        (teamId: teamId, profileId: widget.profileId),
      ),
    );

    return detailAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: _refresh,
      ),
      data: (detail) => _buildContent(detail),
    );
  }

  /// Builds the full page content with header and tabbed body.
  Widget _buildContent(FleetServiceProfileDetail detail) {
    return Column(
      children: [
        _buildHeader(detail),
        const Divider(height: 1, color: CodeOpsColors.border),
        TabBar(
          controller: _tabController,
          labelColor: CodeOpsColors.primary,
          unselectedLabelColor: CodeOpsColors.textSecondary,
          indicatorColor: CodeOpsColors.primary,
          tabs: const [
            Tab(text: 'Configuration'),
            Tab(text: 'Volumes'),
            Tab(text: 'Networks'),
          ],
        ),
        const Divider(height: 1, color: CodeOpsColors.border),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ServiceProfileConfigTab(detail: detail),
              ServiceProfileVolumesTab(
                volumes: detail.volumes ?? [],
                onAdd: _addVolume,
                onRemove: _removeVolume,
              ),
              ServiceProfileNetworksTab(
                networks: detail.networks ?? [],
                onAdd: _addNetwork,
                onRemove: _removeNetwork,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the page header with profile name and action buttons.
  Widget _buildHeader(FleetServiceProfileDetail detail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: CodeOpsColors.surface,
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            color: CodeOpsColors.textSecondary,
            onPressed: () => context.go('/fleet/service-profiles'),
            tooltip: 'Back to list',
          ),
          const SizedBox(width: 12),

          // Profile name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.displayName ?? detail.serviceName ?? 'Unnamed',
                  style: CodeOpsTypography.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${detail.imageName ?? ""}:${detail.imageTag ?? "latest"}',
                  style: CodeOpsTypography.bodySmall
                      .copyWith(color: CodeOpsColors.textSecondary),
                ),
              ],
            ),
          ),

          // Enabled badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (detail.isEnabled == true
                      ? CodeOpsColors.success
                      : CodeOpsColors.textTertiary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              detail.isEnabled == true ? 'Enabled' : 'Disabled',
              style: TextStyle(
                color: detail.isEnabled == true
                    ? CodeOpsColors.success
                    : CodeOpsColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Edit button
          OutlinedButton.icon(
            onPressed: _isBusy ? null : () => _editProfile(detail),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.primary,
              side: const BorderSide(color: CodeOpsColors.primary),
            ),
          ),
          const SizedBox(width: 8),

          // Delete button
          OutlinedButton.icon(
            onPressed: _isBusy ? null : () => _deleteProfile(detail),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: CodeOpsColors.error,
              side: const BorderSide(color: CodeOpsColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
