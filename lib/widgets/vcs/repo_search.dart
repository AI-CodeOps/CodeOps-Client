/// Repository search widget.
///
/// Uses [CodeOpsSearchBar] with min 2-character threshold
/// and [repoSearchResultsProvider] for results.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/github_providers.dart';
import '../../theme/colors.dart';
import '../shared/error_panel.dart';
import '../shared/search_bar.dart';

/// Search bar + results list for searching GitHub repositories.
class RepoSearch extends ConsumerStatefulWidget {
  /// Creates a [RepoSearch].
  const RepoSearch({super.key});

  @override
  ConsumerState<RepoSearch> createState() => _RepoSearchState();
}

class _RepoSearchState extends ConsumerState<RepoSearch> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CodeOpsSearchBar(
          hint: 'Search repositories (min 2 chars)...',
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: 8),
        if (_query.length >= 2)
          Expanded(child: _SearchResults(query: _query))
        else
          const Expanded(
            child: Center(
              child: Text(
                'Type at least 2 characters to search',
                style: TextStyle(
                  color: CodeOpsColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;

  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(repoSearchResultsProvider(query));

    return resultsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CodeOpsColors.primary),
      ),
      error: (error, _) => ErrorPanel.fromException(
        error,
        onRetry: () => ref.invalidate(repoSearchResultsProvider(query)),
      ),
      data: (repos) {
        if (repos.isEmpty) {
          return Center(
            child: Text(
              'No repositories found for "$query"',
              style: const TextStyle(
                color: CodeOpsColors.textTertiary,
                fontSize: 13,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: repos.length,
          itemBuilder: (context, index) {
            final repo = repos[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.source, size: 18,
                  color: CodeOpsColors.textTertiary),
              title: Text(
                repo.fullName,
                style: const TextStyle(
                  color: CodeOpsColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              subtitle: repo.description != null
                  ? Text(
                      repo.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    )
                  : null,
              trailing: repo.language != null
                  ? Text(
                      repo.language!,
                      style: const TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 11,
                      ),
                    )
                  : null,
              onTap: () {
                ref.read(selectedRepoProvider.notifier).state =
                    repo.fullName;
              },
            );
          },
        );
      },
    );
  }
}
