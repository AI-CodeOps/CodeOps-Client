// Tests for GoRouter configuration.
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:codeops/router.dart';
import 'package:codeops/services/auth/auth_service.dart';

void main() {
  group('Router', () {
    test('has 105 routes', () {
      int countRoutes(List<RouteBase> routes) {
        var count = 0;
        for (final route in routes) {
          if (route is GoRoute) {
            count++;
            count += countRoutes(route.routes);
          } else if (route is ShellRoute) {
            count += countRoutes(route.routes);
          }
        }
        return count;
      }

      expect(countRoutes(router.configuration.routes), 105);
    });

    test('initial location is /login', () {
      expect(router.routeInformationProvider.value.uri.path, '/login');
    });

    test('all expected route paths are registered', () {
      final expectedPaths = [
        '/login',
        '/setup',
        '/',
        '/projects',
        '/projects/:id',
        '/repos',
        '/scribe',
        '/audit',
        '/compliance',
        '/dependencies',
        '/bugs',
        '/bugs/jira',
        '/tasks',
        '/tech-debt',
        '/health',
        '/history',
        '/jobs/:id',
        '/jobs/:id/report',
        '/jobs/:id/findings',
        '/jobs/:id/tasks',
        '/personas',
        '/personas/:id/edit',
        '/directives',
        '/settings',
        '/admin',
        '/vault',
        '/vault/secrets',
        '/vault/secrets/:id',
        '/vault/policies',
        '/vault/policies/:id',
        '/vault/transit',
        '/vault/dynamic',
        '/vault/rotation',
        '/vault/seal',
        '/registry',
        '/registry/services/new',
        '/registry/services/:id',
        '/registry/services/:id/edit',
        '/registry/ports',
        '/registry/solutions',
        '/registry/solutions/:solutionId',
        '/registry/dependencies',
        '/registry/dependencies/impact',
        '/registry/topology',
        '/registry/infra',
        '/registry/routes',
        '/registry/config',
        '/registry/workstations',
        '/registry/workstations/:profileId',
        '/registry/api-docs',
        '/registry/api-docs/:serviceId',
        '/logger',
        '/logger/viewer',
        '/logger/search',
        '/logger/traps',
        '/logger/traps/:id/edit',
        '/logger/alerts',
        '/logger/alerts/channels',
        '/logger/dashboards',
        '/logger/dashboards/:id',
        '/logger/metrics',
        '/logger/traces',
        '/logger/traces/:correlationId',
        '/logger/retention',
        '/courier',
        '/courier/request/:requestId',
        '/courier/collection/:collectionId',
        '/courier/environments',
        '/courier/runner',
        '/courier/runner/:runId/results',
        '/courier/history',
        '/courier/codegen',
        '/courier/import',
        '/mcp',
        '/mcp/sessions',
        '/mcp/sessions/:sessionId',
        '/mcp/activity',
        '/mcp/documents',
        '/mcp/documents/:documentId',
        '/mcp/documents/:documentId/versions',
        '/mcp/context',
        '/mcp/profiles',
        '/mcp/profiles/:profileId',
        '/mcp/profiles/:profileId/tokens',
        '/mcp/conventions',
        '/mcp/audit-log',
        '/mcp/status',
      ];

      final registeredPaths = <String>[];
      void collectPaths(List<RouteBase> routes) {
        for (final route in routes) {
          if (route is GoRoute) {
            registeredPaths.add(route.path);
            collectPaths(route.routes);
          } else if (route is ShellRoute) {
            collectPaths(route.routes);
          }
        }
      }

      collectPaths(router.configuration.routes);

      for (final path in expectedPaths) {
        expect(registeredPaths, contains(path),
            reason: 'Missing route: $path');
      }
    });

    test('authNotifier defaults to unknown', () {
      expect(authNotifier.state, AuthState.unknown);
    });
  });
}
