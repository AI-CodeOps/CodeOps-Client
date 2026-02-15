/// Personas list page with search, filters, import, and create actions.
///
/// Displays persona cards in a responsive grid. Supports filtering
/// by scope and agent type, importing from .md files, and creating new.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/persona_providers.dart';
import '../providers/team_providers.dart';
import '../theme/colors.dart';
import '../widgets/personas/persona_list.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/error_panel.dart';
import '../widgets/shared/loading_overlay.dart';
import '../widgets/shared/notification_toast.dart';
import '../widgets/shared/search_bar.dart';

/// The personas list page replacing the `/personas` placeholder.
class PersonasPage extends ConsumerWidget {
  /// Creates a [PersonasPage].
  const PersonasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personasAsync = ref.watch(filteredPersonasProvider);
    final scopeFilter = ref.watch(personaScopeFilterProvider);
    final agentTypeFilter = ref.watch(personaAgentTypeFilterProvider);

    return Column(
      children: [
        // Top bar.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CodeOpsColors.border),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Personas',
                style: TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 280,
                child: CodeOpsSearchBar(
                  hint: 'Search personas...',
                  onChanged: (value) {
                    ref.read(personaSearchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Scope filter.
              DropdownButton<Scope?>(
                value: scopeFilter,
                dropdownColor: CodeOpsColors.surface,
                underline: const SizedBox.shrink(),
                hint: const Text(
                  'All Scopes',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 13,
                ),
                items: [
                  const DropdownMenuItem<Scope?>(
                    value: null,
                    child: Text('All Scopes'),
                  ),
                  ...Scope.values.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.displayName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  ref.read(personaScopeFilterProvider.notifier).state = value;
                },
              ),
              const SizedBox(width: 12),
              // Agent type filter.
              DropdownButton<AgentType?>(
                value: agentTypeFilter,
                dropdownColor: CodeOpsColors.surface,
                underline: const SizedBox.shrink(),
                hint: const Text(
                  'All Types',
                  style: TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                style: const TextStyle(
                  color: CodeOpsColors.textSecondary,
                  fontSize: 13,
                ),
                items: [
                  const DropdownMenuItem<AgentType?>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ...AgentType.values.map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.displayName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  ref.read(personaAgentTypeFilterProvider.notifier).state =
                      value;
                },
              ),
              const Spacer(),
              // Refresh.
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.invalidate(teamPersonasProvider);
                  ref.invalidate(systemPersonasProvider);
                },
              ),
              const SizedBox(width: 8),
              // Import.
              OutlinedButton.icon(
                onPressed: () => _importPersona(context, ref),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import'),
              ),
              const SizedBox(width: 8),
              // New persona.
              FilledButton.icon(
                onPressed: () => context.go('/personas/new/edit'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Persona'),
              ),
            ],
          ),
        ),
        // Body.
        Expanded(
          child: personasAsync.when(
            loading: () =>
                const LoadingOverlay(message: 'Loading personas...'),
            error: (error, _) => ErrorPanel.fromException(
              error,
              onRetry: () {
                ref.invalidate(teamPersonasProvider);
                ref.invalidate(systemPersonasProvider);
              },
            ),
            data: (personas) {
              if (personas.isEmpty) {
                return EmptyState(
                  icon: Icons.person_outline,
                  title: 'No personas yet',
                  subtitle:
                      'Create or import a persona to customize agent behavior.',
                  actionLabel: 'New Persona',
                  onAction: () => context.go('/personas/new/edit'),
                );
              }
              return PersonaList(personas: personas);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _importPersona(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final content = String.fromCharCodes(bytes);
      final name = file.name.replaceAll('.md', '');
      final teamId = ref.read(selectedTeamIdProvider);

      final api = ref.read(personaApiProvider);
      final persona = await api.createPersona(
        name: name,
        contentMd: content,
        scope: Scope.team,
        teamId: teamId,
      );

      ref.invalidate(teamPersonasProvider);

      if (context.mounted) {
        showToast(context,
            message: 'Imported "${persona.name}"', type: ToastType.success);
        context.go('/personas/${persona.id}/edit');
      }
    } catch (e) {
      if (context.mounted) {
        showToast(context,
            message: 'Import failed: $e', type: ToastType.error);
      }
    }
  }
}
