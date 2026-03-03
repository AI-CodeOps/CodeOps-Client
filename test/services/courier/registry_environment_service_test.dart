// Unit tests for RegistryEnvironmentService.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/services/courier/registry_environment_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

final _services = [
  ServiceRegistrationResponse(
    id: 's1',
    teamId: 't1',
    name: 'CodeOps Server',
    slug: 'codeops-server',
    serviceType: ServiceType.springBootApi,
    status: ServiceStatus.active,
  ),
  ServiceRegistrationResponse(
    id: 's2',
    teamId: 't1',
    name: 'CodeOps Analytics',
    slug: 'codeops-analytics',
    serviceType: ServiceType.springBootApi,
    status: ServiceStatus.active,
  ),
  ServiceRegistrationResponse(
    id: 's3',
    teamId: 't1',
    name: 'Redis Cache',
    slug: 'redis-cache',
    serviceType: ServiceType.cacheService,
    status: ServiceStatus.active,
  ),
];

final _ports = <String, List<PortAllocationResponse>>{
  's1': [
    PortAllocationResponse(
      id: 'p1',
      serviceId: 's1',
      environment: 'dev',
      portType: PortType.httpApi,
      portNumber: 8090,
    ),
  ],
  's2': [
    PortAllocationResponse(
      id: 'p2',
      serviceId: 's2',
      environment: 'dev',
      portType: PortType.httpApi,
      portNumber: 8081,
    ),
  ],
  's3': [
    PortAllocationResponse(
      id: 'p3',
      serviceId: 's3',
      environment: 'dev',
      portType: PortType.redis,
      portNumber: 6379,
    ),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RegistryEnvironmentService', () {
    const service = RegistryEnvironmentService();

    test('generates environment with service URL variables', () {
      final result = service.generateEnvironment(
        services: _services,
        portsByServiceId: _ports,
      );

      expect(result.name, 'Local Services');
      expect(result.variables.length, 2); // Only HTTP_API ports
    });

    test('variable names use slug with underscores', () {
      final result = service.generateEnvironment(
        services: _services,
        portsByServiceId: _ports,
      );

      final names = result.variables.map((v) => v.name).toList();
      expect(names, contains('codeops_analytics_url'));
      expect(names, contains('codeops_server_url'));
    });

    test('variable values contain correct port numbers', () {
      final result = service.generateEnvironment(
        services: _services,
        portsByServiceId: _ports,
      );

      final serverVar =
          result.variables.firstWhere((v) => v.name == 'codeops_server_url');
      expect(serverVar.value, 'http://localhost:8090');

      final analyticsVar = result.variables
          .firstWhere((v) => v.name == 'codeops_analytics_url');
      expect(analyticsVar.value, 'http://localhost:8081');
    });

    test('skips services without HTTP_API port', () {
      final result = service.generateEnvironment(
        services: _services,
        portsByServiceId: _ports,
      );

      // Redis has no httpApi port → not included.
      final names = result.variables.map((v) => v.name).toList();
      expect(names, isNot(contains('redis_cache_url')));
    });

    test('uses custom environment name', () {
      final result = service.generateEnvironment(
        services: _services,
        portsByServiceId: _ports,
        environmentName: 'Dev Environment',
      );

      expect(result.name, 'Dev Environment');
    });

    test('sorts variables alphabetically', () {
      final result = service.generateEnvironment(
        services: _services,
        portsByServiceId: _ports,
      );

      final names = result.variables.map((v) => v.name).toList();
      expect(names, orderedEquals([...names]..sort()));
    });
  });
}
