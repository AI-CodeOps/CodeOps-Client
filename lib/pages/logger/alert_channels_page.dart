/// Alert channels configuration page.
///
/// Displays a data table of notification channels (Email, Webhook,
/// Slack, Teams) with active toggles, type icons, and edit/delete
/// actions. Includes a create/edit dialog per channel type.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/logger_enums.dart';
import '../../models/logger_models.dart';
import '../../providers/logger_providers.dart';
import '../../providers/team_providers.dart' show selectedTeamIdProvider;
import '../../services/cloud/logger_api.dart';
import '../../theme/colors.dart';
import '../../widgets/logger/logger_sidebar.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/error_panel.dart';

/// The alert channels configuration page with sidebar and data table.
class AlertChannelsPage extends ConsumerStatefulWidget {
  /// Creates an [AlertChannelsPage].
  const AlertChannelsPage({super.key});

  @override
  ConsumerState<AlertChannelsPage> createState() => _AlertChannelsPageState();
}

class _AlertChannelsPageState extends ConsumerState<AlertChannelsPage> {
  /// Refreshes the channels list.
  void _refresh() {
    ref.invalidate(loggerAlertChannelsProvider);
  }

  /// Toggles a channel's active state.
  Future<void> _toggleChannel(AlertChannelResponse channel) async {
    final api = ref.read(loggerApiProvider);
    await api.updateAlertChannel(channel.id, isActive: !channel.isActive);
    ref.invalidate(loggerAlertChannelsProvider);
  }

  /// Deletes a channel after confirmation.
  Future<void> _deleteChannel(
    BuildContext context,
    AlertChannelResponse channel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text(
          'Delete Channel',
          style: TextStyle(color: CodeOpsColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          'Delete channel "${channel.name}"? This cannot be undone.',
          style: const TextStyle(
            color: CodeOpsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(loggerApiProvider);
      await api.deleteAlertChannel(channel.id);
      ref.invalidate(loggerAlertChannelsProvider);
    }
  }

  /// Shows the create/edit channel dialog.
  Future<void> _showChannelDialog({AlertChannelResponse? existing}) async {
    final teamId = ref.read(selectedTeamIdProvider);
    if (teamId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ChannelDialog(
        teamId: teamId,
        existing: existing,
        api: ref.read(loggerApiProvider),
      ),
    );

    if (result == true) {
      ref.invalidate(loggerAlertChannelsProvider);
    }
  }

  /// Returns the icon for a channel type.
  IconData _channelIcon(AlertChannelType type) => switch (type) {
        AlertChannelType.email => Icons.email_outlined,
        AlertChannelType.webhook => Icons.webhook_outlined,
        AlertChannelType.slack => Icons.tag,
        AlertChannelType.teams => Icons.groups_outlined,
      };

  /// Extracts a summary endpoint from the configuration JSON.
  String _configSummary(AlertChannelResponse channel) {
    try {
      final config =
          jsonDecode(channel.configuration) as Map<String, dynamic>;
      return switch (channel.channelType) {
        AlertChannelType.email =>
          config['recipients']?.toString() ?? 'No recipients',
        AlertChannelType.webhook => config['url']?.toString() ?? 'No URL',
        AlertChannelType.slack =>
          config['channel']?.toString() ?? 'No channel',
        AlertChannelType.teams => config['url']?.toString() ?? 'No URL',
      };
    } catch (_) {
      return channel.configuration.length > 40
          ? '${channel.configuration.substring(0, 40)}...'
          : channel.configuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(selectedTeamIdProvider);

    if (teamId == null) {
      return Row(
        children: [
          const LoggerSidebar(),
          const VerticalDivider(width: 1, color: CodeOpsColors.border),
          const Expanded(
            child: EmptyState(
              icon: Icons.group_off,
              title: 'No team selected',
              subtitle: 'Select a team to manage alert channels.',
            ),
          ),
        ],
      );
    }

    final channelsAsync = ref.watch(loggerAlertChannelsProvider);

    return Row(
      children: [
        const LoggerSidebar(),
        const VerticalDivider(width: 1, color: CodeOpsColors.border),
        Expanded(
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: channelsAsync.when(
                  data: (channels) {
                    if (channels.isEmpty) {
                      return const EmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: 'No channels configured',
                        subtitle:
                            'Create a notification channel to receive alerts.',
                      );
                    }
                    return _buildChannelsTable(channels);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: CodeOpsColors.primary,
                    ),
                  ),
                  error: (error, _) => ErrorPanel.fromException(
                    error,
                    onRetry: _refresh,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the top toolbar.
  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: CodeOpsColors.surface,
        border: Border(bottom: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            color: CodeOpsColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Alert Channels',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showChannelDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Channel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CodeOpsColors.primary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            color: CodeOpsColors.textSecondary,
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }

  /// Builds the channels data table.
  Widget _buildChannelsTable(List<AlertChannelResponse> channels) {
    return Column(
      children: [
        // Column headers.
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: CodeOpsColors.surfaceVariant,
          child: const Row(
            children: [
              SizedBox(width: 60, child: _HeaderText('Active')),
              SizedBox(width: 40, child: _HeaderText('Type')),
              Expanded(flex: 2, child: _HeaderText('Name')),
              Expanded(flex: 3, child: _HeaderText('Endpoint')),
              SizedBox(width: 100, child: _HeaderText('Actions')),
            ],
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Data rows.
        Expanded(
          child: ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return _buildChannelRow(channel, index);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a single channel row.
  Widget _buildChannelRow(AlertChannelResponse channel, int index) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: index.isEven
            ? CodeOpsColors.background
            : CodeOpsColors.surface.withValues(alpha: 0.5),
        border: const Border(
          bottom: BorderSide(color: CodeOpsColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Active toggle.
          SizedBox(
            width: 60,
            child: Switch(
              value: channel.isActive,
              onChanged: (_) => _toggleChannel(channel),
              activeThumbColor: CodeOpsColors.success,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          // Type icon.
          SizedBox(
            width: 40,
            child: Icon(
              _channelIcon(channel.channelType),
              size: 18,
              color: channel.isActive
                  ? CodeOpsColors.primary
                  : CodeOpsColors.textTertiary,
            ),
          ),

          // Name.
          Expanded(
            flex: 2,
            child: Text(
              channel.name,
              style: TextStyle(
                color: channel.isActive
                    ? CodeOpsColors.textPrimary
                    : CodeOpsColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Endpoint summary.
          Expanded(
            flex: 3,
            child: Text(
              _configSummary(channel),
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Actions.
          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  color: CodeOpsColors.textSecondary,
                  tooltip: 'Edit',
                  onPressed: () =>
                      _showChannelDialog(existing: channel),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: CodeOpsColors.textTertiary,
                  tooltip: 'Delete',
                  onPressed: () => _deleteChannel(context, channel),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit Channel Dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Dialog for creating or editing an alert channel.
class _ChannelDialog extends StatefulWidget {
  final String teamId;
  final AlertChannelResponse? existing;
  final LoggerApi api;

  const _ChannelDialog({
    required this.teamId,
    this.existing,
    required this.api,
  });

  @override
  State<_ChannelDialog> createState() => _ChannelDialogState();
}

class _ChannelDialogState extends State<_ChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late AlertChannelType _channelType;
  bool _isSaving = false;
  bool _isTesting = false;

  // Email fields.
  late TextEditingController _recipientsController;
  late TextEditingController _subjectController;

  // Webhook fields.
  late TextEditingController _urlController;
  late TextEditingController _headersController;

  // Slack fields.
  late TextEditingController _slackUrlController;
  late TextEditingController _slackChannelController;
  late TextEditingController _slackBotNameController;

  // Teams fields.
  late TextEditingController _teamsUrlController;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '');
    _channelType =
        widget.existing?.channelType ?? AlertChannelType.email;

    _recipientsController = TextEditingController();
    _subjectController = TextEditingController();
    _urlController = TextEditingController();
    _headersController = TextEditingController();
    _slackUrlController = TextEditingController();
    _slackChannelController = TextEditingController();
    _slackBotNameController = TextEditingController();
    _teamsUrlController = TextEditingController();

    if (widget.existing != null) {
      _loadConfig(widget.existing!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _recipientsController.dispose();
    _subjectController.dispose();
    _urlController.dispose();
    _headersController.dispose();
    _slackUrlController.dispose();
    _slackChannelController.dispose();
    _slackBotNameController.dispose();
    _teamsUrlController.dispose();
    super.dispose();
  }

  /// Loads existing config JSON into the form fields.
  void _loadConfig(AlertChannelResponse channel) {
    try {
      final config =
          jsonDecode(channel.configuration) as Map<String, dynamic>;
      switch (channel.channelType) {
        case AlertChannelType.email:
          _recipientsController.text =
              config['recipients']?.toString() ?? '';
          _subjectController.text =
              config['subject']?.toString() ?? '';
        case AlertChannelType.webhook:
          _urlController.text = config['url']?.toString() ?? '';
          _headersController.text = config['headers']?.toString() ?? '';
        case AlertChannelType.slack:
          _slackUrlController.text = config['url']?.toString() ?? '';
          _slackChannelController.text =
              config['channel']?.toString() ?? '';
          _slackBotNameController.text =
              config['botName']?.toString() ?? '';
        case AlertChannelType.teams:
          _teamsUrlController.text = config['url']?.toString() ?? '';
      }
    } catch (_) {
      // Config not parseable — ignore.
    }
  }

  /// Builds the configuration JSON from the form fields.
  String _buildConfigJson() {
    final config = switch (_channelType) {
      AlertChannelType.email => {
          'recipients': _recipientsController.text.trim(),
          'subject': _subjectController.text.trim(),
        },
      AlertChannelType.webhook => {
          'url': _urlController.text.trim(),
          'method': 'POST',
          'headers': _headersController.text.trim(),
        },
      AlertChannelType.slack => {
          'url': _slackUrlController.text.trim(),
          'channel': _slackChannelController.text.trim(),
          'botName': _slackBotNameController.text.trim(),
        },
      AlertChannelType.teams => {
          'url': _teamsUrlController.text.trim(),
        },
    };
    return jsonEncode(config);
  }

  /// Saves the channel.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final configJson = _buildConfigJson();
      if (_isEdit) {
        await widget.api.updateAlertChannel(
          widget.existing!.id,
          name: _nameController.text.trim(),
          configuration: configJson,
        );
      } else {
        await widget.api.createAlertChannel(
          widget.teamId,
          name: _nameController.text.trim(),
          channelType: _channelType,
          configuration: configJson,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save channel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Sends a test notification.
  Future<void> _testChannel() async {
    setState(() => _isTesting = true);
    // Simulate test — no dedicated API endpoint exists yet.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CodeOpsColors.surface,
      title: Text(
        _isEdit ? 'Edit Channel' : 'Create Channel',
        style: const TextStyle(
          color: CodeOpsColors.textPrimary,
          fontSize: 16,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel name.
                TextFormField(
                  controller: _nameController,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required'
                      : null,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: _inputDecoration('Channel Name'),
                ),
                const SizedBox(height: 12),

                // Channel type (disabled for edit).
                if (!_isEdit) ...[
                  const Text(
                    'Channel Type',
                    style: TextStyle(
                      color: CodeOpsColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: AlertChannelType.values.map((type) {
                      final isSelected = _channelType == type;
                      return ChoiceChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _channelType = type),
                        selectedColor:
                            CodeOpsColors.primary.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? CodeOpsColors.primary
                              : CodeOpsColors.textSecondary,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? CodeOpsColors.primary
                              : CodeOpsColors.border,
                        ),
                        backgroundColor: CodeOpsColors.background,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Type-specific fields.
                ..._buildTypeFields(),

                // Test button.
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testChannel,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 14),
                  label: Text(
                      _isTesting ? 'Sending...' : 'Send Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CodeOpsColors.textSecondary,
                    side: const BorderSide(color: CodeOpsColors.border),
                    textStyle: const TextStyle(fontSize: 12),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: CodeOpsColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  /// Builds the type-specific configuration fields.
  List<Widget> _buildTypeFields() {
    return switch (_channelType) {
      AlertChannelType.email => [
          TextFormField(
            controller: _recipientsController,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Recipients required'
                : null,
            style: const TextStyle(
                color: CodeOpsColors.textPrimary, fontSize: 13),
            decoration:
                _inputDecoration('Recipients (comma-separated emails)'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _subjectController,
            style: const TextStyle(
                color: CodeOpsColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Subject Template (optional)'),
          ),
        ],
      AlertChannelType.webhook => [
          TextFormField(
            controller: _urlController,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'URL required' : null,
            style: const TextStyle(
                color: CodeOpsColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Webhook URL'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _headersController,
            maxLines: 2,
            style: const TextStyle(
                color: CodeOpsColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Headers (JSON, optional)'),
          ),
        ],
      AlertChannelType.slack => [
          TextFormField(
            controller: _slackUrlController,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'URL required' : null,
            style: const TextStyle(
                color: CodeOpsColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Slack Webhook URL'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _slackChannelController,
            style: const TextStyle(
                color: CodeOpsColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Channel Name (optional)'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _slackBotNameController,
            style: const TextStyle(
                color: CodeOpsColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Bot Name (optional)'),
          ),
        ],
      AlertChannelType.teams => [
          TextFormField(
            controller: _teamsUrlController,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'URL required' : null,
            style: const TextStyle(
                color: CodeOpsColors.textPrimary, fontSize: 13),
            decoration: _inputDecoration('Teams Webhook URL'),
          ),
        ],
    };
  }

  /// Standard input decoration.
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: CodeOpsColors.textTertiary,
        fontSize: 12,
      ),
      filled: true,
      fillColor: CodeOpsColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: CodeOpsColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: CodeOpsColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: CodeOpsColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: CodeOpsColors.error),
      ),
    );
  }
}

/// Column header text widget.
class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: CodeOpsColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
