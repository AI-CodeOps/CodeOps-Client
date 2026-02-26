/// Event activity feed widget for the Relay module.
///
/// Displays a paginated, filterable list of platform events for the
/// team. Each row shows the event type icon, title, and relative
/// timestamp. Undelivered events are highlighted with a retry button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/health_snapshot.dart';
import '../../models/relay_enums.dart';
import '../../models/relay_models.dart';
import '../../providers/relay_providers.dart';
import '../../providers/team_providers.dart';
import '../../theme/colors.dart';
import '../../utils/date_utils.dart';
import 'relay_event_style_helper.dart';

/// A paginated, filterable activity feed of platform events.
///
/// Features:
/// - Filter dropdown: All types or a specific [PlatformEventType]
/// - Paginated list with "Load more" button
/// - Click event row to navigate to source entity
/// - Undelivered events highlighted with a retry button
/// - Shown in a dialog via a bell icon in the header
class RelayEventFeed extends ConsumerStatefulWidget {
  /// Creates a [RelayEventFeed].
  const RelayEventFeed({super.key});

  @override
  ConsumerState<RelayEventFeed> createState() => _RelayEventFeedState();
}

class _RelayEventFeedState extends ConsumerState<RelayEventFeed> {
  PlatformEventType? _filterType;
  int _currentPage = 0;
  List<PlatformEventResponse> _events = [];
  bool _hasMore = false;
  bool _isLoading = false;
  int _totalResults = 0;

  String? get _teamId => ref.read(selectedTeamIdProvider);

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  /// Loads events for the current page and filter.
  Future<void> _loadPage() async {
    final teamId = _teamId;
    if (teamId == null) return;

    setState(() => _isLoading = true);

    try {
      final api = ref.read(relayApiProvider);
      PageResponse<PlatformEventResponse> page;

      if (_filterType != null) {
        page = await api.getEventsForTeamByType(
          teamId,
          _filterType!,
          page: _currentPage,
        );
      } else {
        page = await api.getEventsForTeam(teamId, page: _currentPage);
      }

      setState(() {
        if (_currentPage == 0) {
          _events = page.content;
        } else {
          _events = [..._events, ...page.content];
        }
        _totalResults = page.totalElements;
        _hasMore = !page.isLast;
      });
    } catch (_) {
      // Silently handle errors — events list remains unchanged.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Loads the next page of results.
  void _loadMore() {
    _currentPage++;
    _loadPage();
  }

  /// Applies the selected filter and reloads.
  void _onFilterChanged(PlatformEventType? type) {
    setState(() {
      _filterType = type;
      _currentPage = 0;
      _events = [];
    });
    _loadPage();
  }

  /// Retries delivery of a single event.
  Future<void> _retryDelivery(PlatformEventResponse event) async {
    if (event.id == null) return;
    final teamId = _teamId;

    try {
      final api = ref.read(relayApiProvider);
      await api.retryDelivery(event.id!);
      // Reload to reflect updated delivery status.
      setState(() {
        _currentPage = 0;
        _events = [];
      });
      _loadPage();
      if (teamId != null) {
        ref.invalidate(undeliveredEventsProvider(teamId));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retry failed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Navigates to the source entity of an event.
  void _navigateToEvent(PlatformEventResponse event) {
    final route = RelayEventStyleHelper.routeForEvent(event);
    if (route == null) return;
    Navigator.of(context).pop();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final resultCount = _events.length;

    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildFilterRow(),
            const Divider(height: 1, color: CodeOpsColors.border),
            Flexible(child: _buildEventList(resultCount)),
            if (_totalResults > 0) _buildFooter(resultCount),
          ],
        ),
      ),
    );
  }

  /// Builds the dialog header.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined,
              size: 18, color: CodeOpsColors.textTertiary),
          const SizedBox(width: 8),
          const Text(
            'Platform Events',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CodeOpsColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: CodeOpsColors.textTertiary,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  /// Builds the event type filter dropdown row.
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Text(
            'Filter:',
            style: TextStyle(
              fontSize: 12,
              color: CodeOpsColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<PlatformEventType?>(
              value: _filterType,
              isExpanded: true,
              isDense: true,
              dropdownColor: CodeOpsColors.surfaceVariant,
              style: const TextStyle(
                fontSize: 12,
                color: CodeOpsColors.textPrimary,
              ),
              underline: const SizedBox.shrink(),
              onChanged: _onFilterChanged,
              items: [
                const DropdownMenuItem<PlatformEventType?>(
                  value: null,
                  child: Text('All events'),
                ),
                ...PlatformEventType.values.map((type) {
                  return DropdownMenuItem<PlatformEventType?>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          RelayEventStyleHelper.icon(type),
                          size: 14,
                          color: RelayEventStyleHelper.borderColor(type),
                        ),
                        const SizedBox(width: 6),
                        Text(RelayEventStyleHelper.label(type)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable event list.
  Widget _buildEventList(int resultCount) {
    if (_isLoading && resultCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (resultCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No events found',
            style: TextStyle(fontSize: 13, color: CodeOpsColors.textTertiary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: resultCount + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= resultCount) {
          return _buildLoadMoreButton();
        }
        return _buildEventRow(_events[index]);
      },
    );
  }

  /// Builds a single event row.
  Widget _buildEventRow(PlatformEventResponse event) {
    final eventType = event.eventType;
    final color = eventType != null
        ? RelayEventStyleHelper.borderColor(eventType)
        : CodeOpsColors.textTertiary;
    final iconData = eventType != null
        ? RelayEventStyleHelper.icon(eventType)
        : Icons.bolt;
    final isUndelivered = event.isDelivered != true;
    final hasRoute = RelayEventStyleHelper.routeForEvent(event) != null;

    return InkWell(
      onTap: hasRoute ? () => _navigateToEvent(event) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isUndelivered
            ? BoxDecoration(
                color: CodeOpsColors.warning.withValues(alpha: 0.05),
              )
            : null,
        child: Row(
          children: [
            Icon(iconData, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? 'Untitled event',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  if (event.detail != null && event.detail!.isNotEmpty)
                    Text(
                      event.detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CodeOpsColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUndelivered) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: CodeOpsColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: CodeOpsColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  icon: const Icon(Icons.refresh, size: 14),
                  color: CodeOpsColors.warning,
                  padding: EdgeInsets.zero,
                  onPressed: () => _retryDelivery(event),
                  tooltip: 'Retry delivery',
                ),
              ),
            ],
            Text(
              formatTimeAgo(event.createdAt),
              style: const TextStyle(
                fontSize: 10,
                color: CodeOpsColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "Load more" button.
  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _loadMore,
                child: const Text(
                  'Load more',
                  style:
                      TextStyle(fontSize: 12, color: CodeOpsColors.primary),
                ),
              ),
      ),
    );
  }

  /// Builds the footer showing result counts.
  Widget _buildFooter(int resultCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CodeOpsColors.border)),
      ),
      child: Text(
        'Showing $resultCount of $_totalResults events',
        style: const TextStyle(
          fontSize: 11,
          color: CodeOpsColors.textTertiary,
        ),
      ),
    );
  }
}
