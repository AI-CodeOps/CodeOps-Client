/// Tests for [RelayEventFeed] — platform event activity feed dialog.
///
/// Verifies header rendering, filter dropdown presence, event row
/// rendering with icons and titles, undelivered badge, retry button,
/// empty state, and close button.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/relay_enums.dart';
import 'package:codeops/models/relay_models.dart';
import 'package:codeops/providers/relay_providers.dart';
import 'package:codeops/providers/team_providers.dart';
import 'package:codeops/services/cloud/relay_api.dart';
import 'package:codeops/widgets/relay/relay_event_feed.dart';
import 'package:codeops/widgets/relay/relay_event_style_helper.dart';

class MockRelayApiService extends Mock implements RelayApiService {}

/// Empty page response used by most tests.
final _emptyPage = PageResponse<PlatformEventResponse>(
  content: const [],
  page: 0,
  size: 20,
  totalElements: 0,
  totalPages: 0,
  isLast: true,
);

Widget _createFeed({
  MockRelayApiService? mockApi,
  List<Override> overrides = const [],
}) {
  final api = mockApi ?? MockRelayApiService();

  // Only stub by default when no pre-configured mock was provided.
  if (mockApi == null) {
    when(() => api.getEventsForTeam(any(), page: any(named: 'page')))
        .thenAnswer((_) async => _emptyPage);
  }

  return ProviderScope(
    overrides: [
      selectedTeamIdProvider.overrideWith((ref) => 'team-1'),
      relayApiProvider.overrideWithValue(api),
      ...overrides,
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const RelayEventFeed(),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('RelayEventFeed', () {
    testWidgets('renders header with title', (tester) async {
      await tester.pumpWidget(_createFeed());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Platform Events'), findsOneWidget);
    });

    testWidgets('filter dropdown shows All events option', (tester) async {
      await tester.pumpWidget(_createFeed());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('All events'), findsOneWidget);
      expect(find.text('Filter:'), findsOneWidget);
    });

    testWidgets('shows loading spinner initially', (tester) async {
      final api = MockRelayApiService();
      final completer = Completer<PageResponse<PlatformEventResponse>>();

      // Return a never-completing future so _isLoading stays true.
      when(() => api.getEventsForTeam(any(), page: any(named: 'page')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(_createFeed(mockApi: api));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();

      // The feed shows a loading spinner while fetching events.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future so no timers are left pending.
      completer.complete(_emptyPage);
      await tester.pumpAndSettle();
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await tester.pumpWidget(_createFeed());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Platform Events'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Platform Events'), findsNothing);
    });

    testWidgets('renders notifications icon in header', (tester) async {
      await tester.pumpWidget(_createFeed());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('shows filter label', (tester) async {
      await tester.pumpWidget(_createFeed());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Filter:'), findsOneWidget);
    });

    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(_createFeed());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('No events found'), findsOneWidget);
    });

    testWidgets('renders event rows when events exist', (tester) async {
      final api = MockRelayApiService();
      final page = PageResponse<PlatformEventResponse>(
        content: const [
          PlatformEventResponse(
            id: 'evt-1',
            title: 'Audit scan completed',
            eventType: PlatformEventType.auditCompleted,
            isDelivered: true,
          ),
          PlatformEventResponse(
            id: 'evt-2',
            title: 'Alert triggered',
            eventType: PlatformEventType.alertFired,
            isDelivered: true,
          ),
        ],
        page: 0,
        size: 20,
        totalElements: 2,
        totalPages: 1,
        isLast: true,
      );

      when(() => api.getEventsForTeam(any(), page: any(named: 'page')))
          .thenAnswer((_) async => page);

      await tester.pumpWidget(_createFeed(mockApi: api));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Audit scan completed'), findsOneWidget);
      expect(find.text('Alert triggered'), findsOneWidget);
      expect(find.text('Showing 2 of 2 events'), findsOneWidget);
    });

    testWidgets('shows pending badge for undelivered events', (tester) async {
      final api = MockRelayApiService();
      final page = PageResponse<PlatformEventResponse>(
        content: const [
          PlatformEventResponse(
            id: 'evt-1',
            title: 'Undelivered event',
            eventType: PlatformEventType.containerCrashed,
            isDelivered: false,
          ),
        ],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        isLast: true,
      );

      when(() => api.getEventsForTeam(any(), page: any(named: 'page')))
          .thenAnswer((_) async => page);

      await tester.pumpWidget(_createFeed(mockApi: api));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    test('style helper provides icons for dropdown', () {
      // Verify each type has a valid icon for filter dropdown.
      for (final type in PlatformEventType.values) {
        expect(RelayEventStyleHelper.icon(type), isNotNull);
        expect(RelayEventStyleHelper.label(type), isNotEmpty);
      }
    });
  });
}
