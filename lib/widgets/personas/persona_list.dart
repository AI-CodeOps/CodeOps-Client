/// Responsive grid of persona cards with badges and context menus.
///
/// Reads from [filteredPersonasProvider] and displays personas as
/// interactive cards with agent type, scope, and default indicators.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../models/persona.dart';
import '../../providers/persona_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import '../shared/confirm_dialog.dart';
import '../shared/notification_toast.dart';

/// A responsive grid of persona cards.
class PersonaList extends ConsumerWidget {
  /// The personas to display.
  final List<Persona> personas;

  /// Creates a [PersonaList].
  const PersonaList({super.key, required this.personas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: personas.length,
          itemBuilder: (context, index) {
            return _PersonaCard(persona: personas[index]);
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Persona card
// ---------------------------------------------------------------------------

class _PersonaCard extends ConsumerWidget {
  final Persona persona;

  const _PersonaCard({required this.persona});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentColor = persona.agentType != null
        ? CodeOpsColors.agentTypeColors[persona.agentType!] ??
            CodeOpsColors.textTertiary
        : CodeOpsColors.textTertiary;

    final scopeColor = switch (persona.scope) {
      Scope.system => CodeOpsColors.textTertiary,
      Scope.team => const Color(0xFF14B8A6),
      Scope.user => CodeOpsColors.warning,
    };

    final isSystem = persona.scope == Scope.system;

    return Material(
      color: CodeOpsColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/personas/${persona.id}/edit'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CodeOpsColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + context menu.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      persona.name,
                      style: const TextStyle(
                        color: CodeOpsColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (persona.isDefault == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: CodeOpsColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: CodeOpsColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  _ContextMenu(persona: persona, isSystem: isSystem),
                ],
              ),
              const SizedBox(height: 8),
              // Badges row.
              Row(
                children: [
                  if (persona.agentType != null)
                    _Badge(
                      label: persona.agentType!.displayName,
                      color: agentColor,
                    ),
                  const SizedBox(width: 6),
                  _Badge(
                    label: persona.scope.displayName,
                    color: scopeColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description.
              Expanded(
                child: Text(
                  persona.description ?? 'No description',
                  style: TextStyle(
                    color: persona.description != null
                        ? CodeOpsColors.textSecondary
                        : CodeOpsColors.textTertiary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Bottom row: version + author + time.
              Row(
                children: [
                  if (persona.version != null)
                    Text(
                      'v${persona.version}',
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  const Spacer(),
                  if (persona.createdByName != null)
                    Text(
                      persona.createdByName!,
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    formatTimeAgo(persona.updatedAt),
                    style: const TextStyle(
                      color: CodeOpsColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge widget
// ---------------------------------------------------------------------------

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Context menu
// ---------------------------------------------------------------------------

class _ContextMenu extends ConsumerWidget {
  final Persona persona;
  final bool isSystem;

  const _ContextMenu({required this.persona, required this.isSystem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: CodeOpsColors.textTertiary),
      color: CodeOpsColors.surface,
      onSelected: (value) => _handleAction(context, ref, value),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        PopupMenuItem(
          value: 'setDefault',
          enabled: !isSystem,
          child: Text(
            persona.isDefault == true ? 'Remove Default' : 'Set as Default',
          ),
        ),
        const PopupMenuItem(value: 'export', child: Text('Export')),
        PopupMenuItem(
          value: 'delete',
          enabled: !isSystem,
          child: const Text(
            'Delete',
            style: TextStyle(color: CodeOpsColors.error),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'edit':
        context.go('/personas/${persona.id}/edit');
      case 'duplicate':
        await _duplicate(context, ref);
      case 'setDefault':
        await _toggleDefault(context, ref);
      case 'export':
        await _export(context);
      case 'delete':
        await _delete(context, ref);
    }
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(personaApiProvider);
      final newPersona = await api.createPersona(
        name: '${persona.name} (Copy)',
        contentMd: persona.contentMd ?? '',
        scope: persona.scope == Scope.system ? Scope.team : persona.scope,
        agentType: persona.agentType,
        description: persona.description,
        teamId: persona.teamId,
      );
      ref.invalidate(teamPersonasProvider);
      ref.invalidate(systemPersonasProvider);
      if (context.mounted) {
        showToast(context,
            message: 'Persona duplicated as "${newPersona.name}"',
            type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Failed to duplicate: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _toggleDefault(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(personaApiProvider);
      if (persona.isDefault == true) {
        await api.removeDefault(persona.id);
      } else {
        await api.setAsDefault(persona.id);
      }
      ref.invalidate(teamPersonasProvider);
      if (context.mounted) {
        showToast(context,
            message: persona.isDefault == true
                ? 'Default removed'
                : 'Set as default',
            type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Failed to update default: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _export(BuildContext context) async {
    // Export handled by the editor page; navigate there.
    context.go('/personas/${persona.id}/edit');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Persona',
      message: 'Are you sure you want to delete "${persona.name}"? '
          'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      final api = ref.read(personaApiProvider);
      await api.deletePersona(persona.id);
      ref.invalidate(teamPersonasProvider);
      ref.invalidate(systemPersonasProvider);
      if (context.mounted) {
        showToast(context,
            message: 'Persona deleted', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Failed to delete: $e', type: ToastType.error);
      }
    }
  }
}
