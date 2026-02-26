/// Tests for [RelayEventStyleHelper] — event type to style mapping.
///
/// Verifies correct color, icon, label, and route mapping for each
/// [PlatformEventType] value and edge cases for [routeForEvent].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/relay_enums.dart';
import 'package:codeops/models/relay_models.dart';
import 'package:codeops/widgets/relay/relay_event_style_helper.dart';

void main() {
  group('RelayEventStyleHelper', () {
    test('returns blue for AUDIT_COMPLETED', () {
      expect(
        RelayEventStyleHelper.borderColor(PlatformEventType.auditCompleted),
        Colors.blue,
      );
    });

    test('returns red for ALERT_FIRED', () {
      expect(
        RelayEventStyleHelper.borderColor(PlatformEventType.alertFired),
        Colors.red,
      );
    });

    test('returns green for SESSION_COMPLETED', () {
      expect(
        RelayEventStyleHelper.borderColor(PlatformEventType.sessionCompleted),
        Colors.green,
      );
    });

    test('returns correct icon for each event type', () {
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.auditCompleted),
        Icons.search,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.alertFired),
        Icons.warning_amber,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.sessionCompleted),
        Icons.check_circle,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.secretRotated),
        Icons.key,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.containerCrashed),
        Icons.error,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.serviceRegistered),
        Icons.inventory_2,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.deploymentCompleted),
        Icons.rocket_launch,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.buildCompleted),
        Icons.build,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.findingCritical),
        Icons.report_problem,
      );
      expect(
        RelayEventStyleHelper.icon(PlatformEventType.mergeRequestCreated),
        Icons.merge,
      );
    });

    test('returns correct label for each event type', () {
      expect(
        RelayEventStyleHelper.label(PlatformEventType.auditCompleted),
        'Audit Complete',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.alertFired),
        'Alert',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.sessionCompleted),
        'Session Complete',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.secretRotated),
        'Secret Rotated',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.containerCrashed),
        'Container Crash',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.serviceRegistered),
        'Service Registered',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.deploymentCompleted),
        'Deployed',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.buildCompleted),
        'Build Complete',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.findingCritical),
        'Critical Finding',
      );
      expect(
        RelayEventStyleHelper.label(PlatformEventType.mergeRequestCreated),
        'Merge Request',
      );
    });

    test('returns route for registry event', () {
      const event = PlatformEventResponse(
        id: 'evt-1',
        sourceModule: 'registry',
        sourceEntityId: 'svc-123',
      );
      expect(
        RelayEventStyleHelper.routeForEvent(event),
        '/registry/services/svc-123',
      );
    });

    test('returns route for vault event', () {
      const event = PlatformEventResponse(
        id: 'evt-2',
        sourceModule: 'vault',
        sourceEntityId: 'secret-456',
      );
      expect(
        RelayEventStyleHelper.routeForEvent(event),
        '/vault/secrets/secret-456',
      );
    });

    test('returns null route for unknown module', () {
      const event = PlatformEventResponse(
        id: 'evt-3',
        sourceModule: 'fleet',
        sourceEntityId: 'entity-789',
      );
      expect(RelayEventStyleHelper.routeForEvent(event), isNull);
    });

    test('returns null route when sourceModule is null', () {
      const event = PlatformEventResponse(
        id: 'evt-4',
        sourceEntityId: 'entity-789',
      );
      expect(RelayEventStyleHelper.routeForEvent(event), isNull);
    });

    test('returns null route when sourceEntityId is null', () {
      const event = PlatformEventResponse(
        id: 'evt-5',
        sourceModule: 'registry',
      );
      expect(RelayEventStyleHelper.routeForEvent(event), isNull);
    });

    test('all event types have a border color', () {
      for (final type in PlatformEventType.values) {
        expect(RelayEventStyleHelper.borderColor(type), isNotNull);
      }
    });
  });
}
