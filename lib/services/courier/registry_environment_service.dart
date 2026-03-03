/// Service for generating Courier environments from Registry service data.
///
/// Creates environment variables mapping each registered service's slug to
/// its base URL (e.g., `codeops_server_url = http://localhost:8090`).
/// Supports both initial generation and sync-on-change.
library;

import '../../models/registry_enums.dart';
import '../../models/registry_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Generated environment data
// ─────────────────────────────────────────────────────────────────────────────

/// A variable entry for a generated environment.
class GeneratedVariable {
  /// Variable name (e.g., `codeops_server_url`).
  final String name;

  /// Variable value (e.g., `http://localhost:8090`).
  final String value;

  /// Service name this variable was derived from.
  final String serviceName;

  /// Creates a [GeneratedVariable].
  const GeneratedVariable({
    required this.name,
    required this.value,
    required this.serviceName,
  });
}

/// Result of generating an environment from Registry data.
class GeneratedEnvironment {
  /// Human-readable environment name.
  final String name;

  /// Variables mapping service slugs to base URLs.
  final List<GeneratedVariable> variables;

  /// Creates a [GeneratedEnvironment].
  const GeneratedEnvironment({
    required this.name,
    required this.variables,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Generates Courier environments from Registry service registrations.
///
/// Each service with an HTTP_API port allocation produces a variable
/// named `{slug}_url` with value `http://localhost:{port}`.
class RegistryEnvironmentService {
  /// Creates a [RegistryEnvironmentService].
  const RegistryEnvironmentService();

  /// Generates environment variables for the given services and ports.
  ///
  /// Only services that have at least one [PortType.httpApi] port in the
  /// provided [ports] map will produce a variable. The variable name is
  /// derived from the service slug with hyphens replaced by underscores
  /// (e.g., `codeops-server` → `codeops_server_url`).
  GeneratedEnvironment generateEnvironment({
    required List<ServiceRegistrationResponse> services,
    required Map<String, List<PortAllocationResponse>> portsByServiceId,
    String environmentName = 'Local Services',
  }) {
    final variables = <GeneratedVariable>[];

    for (final service in services) {
      final ports = portsByServiceId[service.id] ?? [];
      final httpPort = ports.firstWhereOrNull(
        (p) => p.portType == PortType.httpApi,
      );
      if (httpPort == null) continue;

      final slug = service.slug
          .replaceAll('-', '_')
          .toLowerCase();

      variables.add(GeneratedVariable(
        name: '${slug}_url',
        value: 'http://localhost:${httpPort.portNumber}',
        serviceName: service.name,
      ));
    }

    // Sort alphabetically by variable name.
    variables.sort((a, b) => a.name.compareTo(b.name));

    return GeneratedEnvironment(
      name: environmentName,
      variables: variables,
    );
  }
}

/// Extension to provide `firstWhereOrNull` on [Iterable].
extension _IterableExtension<T> on Iterable<T> {
  /// Returns the first element matching [test], or null.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
