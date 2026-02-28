/// Docker image list page for the Fleet module.
///
/// Displays all Docker images at `/fleet/images`. Features include
/// pull image, prune unused images, and per-row remove actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/fleet_models.dart';
import '../../providers/fleet_providers.dart' hide selectedTeamIdProvider;
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/date_utils.dart';
import '../../utils/file_utils.dart';
import '../../widgets/fleet/pull_image_dialog.dart';
import '../../widgets/shared/confirm_dialog.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The Docker image list page at `/fleet/images`.
class ImageListPage extends ConsumerStatefulWidget {
  /// Creates an [ImageListPage].
  const ImageListPage({super.key});

  @override
  ConsumerState<ImageListPage> createState() => _ImageListPageState();
}

class _ImageListPageState extends ConsumerState<ImageListPage> {
  bool _isBusy = false;

  /// Returns the currently selected team ID, or null.
  String? get _teamId => ref.read(selectedTeamIdProvider);

  /// Refreshes the image list.
  void _refresh() {
    final teamId = _teamId;
    if (teamId != null) {
      ref.invalidate(fleetImagesProvider);
    }
  }

  /// Opens the pull image dialog and pulls the image.
  Future<void> _pullImage() async {
    final teamId = _teamId;
    if (teamId == null) return;

    final result = await PullImageDialog.show(context);
    if (result == null) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.pullImage(teamId, result.imageName, tag: result.tag);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Image "${result.imageName}:${result.tag}" pulled'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pull image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Prunes unused images after confirmation.
  Future<void> _pruneImages() async {
    final teamId = _teamId;
    if (teamId == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Prune Images',
      message: 'Remove all unused Docker images? This cannot be undone.',
      confirmLabel: 'Prune',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.pruneImages(teamId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unused images pruned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to prune images: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Removes a Docker image after confirmation.
  Future<void> _removeImage(FleetDockerImage image) async {
    final teamId = _teamId;
    if (teamId == null || image.id == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Image',
      message:
          'Remove "${image.repoTags?.join(", ") ?? image.id}"?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final api = ref.read(fleetApiProvider);
      await api.removeImage(teamId, image.id!, force: true);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'No team selected',
        subtitle: 'Select a team to view Docker images.',
      );
    }

    final imagesAsync = ref.watch(fleetImagesProvider(teamId));

    return imagesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: _refresh,
      ),
      data: (images) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Docker Images',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${images.length})',
                    style: const TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toolbar
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _pullImage,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Pull Image'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _pruneImages,
                    icon: const Icon(Icons.cleaning_services, size: 18),
                    label: const Text('Prune'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CodeOpsColors.warning,
                      side: const BorderSide(color: CodeOpsColors.warning),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    color: CodeOpsColors.textSecondary,
                    onPressed: _isBusy ? null : _refresh,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Table or empty state
              if (images.isEmpty)
                const EmptyState(
                  icon: Icons.image_outlined,
                  title: 'No Docker images found',
                  subtitle: 'Pull an image to get started.',
                )
              else
                _buildTable(images),
            ],
          ),
        );
      },
    );
  }

  /// Builds the images data table.
  Widget _buildTable(List<FleetDockerImage> images) {
    return Container(
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3), // Tags
          1: FixedColumnWidth(100), // Size
          2: FixedColumnWidth(150), // Created
          3: FixedColumnWidth(60), // Actions
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: CodeOpsColors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            children: const [
              _HeaderCell('Repository Tags'),
              _HeaderCell('Size'),
              _HeaderCell('Created'),
              _HeaderCell(''),
            ],
          ),
          ...images.map(_buildRow),
        ],
      ),
    );
  }

  /// Builds a single image row.
  TableRow _buildRow(FleetDockerImage image) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: CodeOpsColors.border.withValues(alpha: 0.5)),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            image.repoTags?.join(', ') ?? '\u2014',
            style: CodeOpsTypography.code.copyWith(fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            image.sizeBytes != null
                ? formatFileSize(image.sizeBytes!)
                : '\u2014',
            style: CodeOpsTypography.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            formatDateTime(image.created),
            style: CodeOpsTypography.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: CodeOpsColors.error,
            onPressed: _isBusy ? null : () => _removeImage(image),
            tooltip: 'Remove',
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(label, style: CodeOpsTypography.labelMedium),
    );
  }
}
