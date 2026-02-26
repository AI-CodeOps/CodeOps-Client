/// Style mapping utilities for platform event rendering.
///
/// Provides static methods that map [PlatformEventType] values to
/// display colors, Material icons, human-readable labels, and
/// navigation routes for source entities.
library;

import 'package:flutter/material.dart';

import '../../models/relay_enums.dart';
import '../../models/relay_models.dart';

/// Maps [PlatformEventType] values to visual styling and navigation routes.
///
/// Used by [RelayMessageBubble] for event cards and [RelayEventFeed]
/// for the activity feed. All methods are static and side-effect-free.
class RelayEventStyleHelper {
  RelayEventStyleHelper._();

  /// Returns the accent/border color for the given [type].
  static Color borderColor(PlatformEventType type) {
    return switch (type) {
      PlatformEventType.auditCompleted => Colors.blue,
      PlatformEventType.alertFired => Colors.red,
      PlatformEventType.sessionCompleted => Colors.green,
      PlatformEventType.secretRotated => Colors.amber,
      PlatformEventType.containerCrashed => Colors.red,
      PlatformEventType.serviceRegistered => Colors.purple,
      PlatformEventType.deploymentCompleted => Colors.teal,
      PlatformEventType.buildCompleted => Colors.indigo,
      PlatformEventType.findingCritical => Colors.orange,
      PlatformEventType.mergeRequestCreated => Colors.cyan,
    };
  }

  /// Returns the Material icon for the given [type].
  static IconData icon(PlatformEventType type) {
    return switch (type) {
      PlatformEventType.auditCompleted => Icons.search,
      PlatformEventType.alertFired => Icons.warning_amber,
      PlatformEventType.sessionCompleted => Icons.check_circle,
      PlatformEventType.secretRotated => Icons.key,
      PlatformEventType.containerCrashed => Icons.error,
      PlatformEventType.serviceRegistered => Icons.inventory_2,
      PlatformEventType.deploymentCompleted => Icons.rocket_launch,
      PlatformEventType.buildCompleted => Icons.build,
      PlatformEventType.findingCritical => Icons.report_problem,
      PlatformEventType.mergeRequestCreated => Icons.merge,
    };
  }

  /// Returns the short display label for the given [type].
  static String label(PlatformEventType type) {
    return switch (type) {
      PlatformEventType.auditCompleted => 'Audit Complete',
      PlatformEventType.alertFired => 'Alert',
      PlatformEventType.sessionCompleted => 'Session Complete',
      PlatformEventType.secretRotated => 'Secret Rotated',
      PlatformEventType.containerCrashed => 'Container Crash',
      PlatformEventType.serviceRegistered => 'Service Registered',
      PlatformEventType.deploymentCompleted => 'Deployed',
      PlatformEventType.buildCompleted => 'Build Complete',
      PlatformEventType.findingCritical => 'Critical Finding',
      PlatformEventType.mergeRequestCreated => 'Merge Request',
    };
  }

  /// Returns the GoRouter path for navigating to the event's source entity.
  ///
  /// Returns `null` if the event has no navigable source (missing module,
  /// missing entity ID, or no matching route exists in the router).
  static String? routeForEvent(PlatformEventResponse event) {
    final module = event.sourceModule;
    final entityId = event.sourceEntityId;
    if (module == null || entityId == null) return null;

    return switch (module.toLowerCase()) {
      'registry' => '/registry/services/$entityId',
      'vault' => '/vault/secrets/$entityId',
      _ => null,
    };
  }
}
