/// GoRouter configuration with all 64 application routes.
///
/// Uses an [AuthNotifier] listenable connected to [AuthService] for
/// reactive auth state. Unauthenticated users are redirected to `/login`.
/// Authenticated routes are wrapped in a [ShellRoute] with [NavigationShell].
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/audit_wizard_page.dart';
import 'pages/compliance_wizard_page.dart';
import 'pages/directives_page.dart';
import 'pages/findings_explorer_page.dart';
import 'pages/github_browser_page.dart';
import 'pages/home_page.dart';
import 'pages/job_history_page.dart';
import 'pages/job_progress_page.dart';
import 'pages/job_report_page.dart';
import 'pages/health_dashboard_page.dart';
import 'pages/login_page.dart';
import 'pages/jira_browser_page.dart';
import 'pages/admin_hub_page.dart';
import 'pages/bug_investigator_page.dart';
import 'pages/persona_editor_page.dart';
import 'pages/personas_page.dart';
import 'pages/dependency_scan_page.dart';
import 'pages/placeholder_page.dart';
import 'pages/registry/api_routes_page.dart';
import 'pages/registry/dependency_graph_page.dart';
import 'pages/registry/impact_analysis_page.dart';
import 'pages/registry/config_generator_page.dart';
import 'pages/registry/infra_resources_page.dart';
import 'pages/registry/topology_page.dart';
import 'pages/registry/service_detail_page.dart';
import 'pages/registry/port_allocation_page.dart';
import 'pages/registry/service_form_page.dart';
import 'pages/registry/solution_detail_page.dart';
import 'pages/registry/solution_list_page.dart';
import 'pages/registry/service_list_page.dart';
import 'pages/registry/api_docs_page.dart';
import 'pages/registry/workstation_detail_page.dart';
import 'pages/registry/workstation_list_page.dart';
import 'pages/vault_dashboard_page.dart';
import 'pages/vault_dynamic_page.dart';
import 'pages/vault_policies_page.dart';
import 'pages/vault_policy_detail_page.dart';
import 'pages/vault_rotation_page.dart';
import 'pages/vault_transit_page.dart';
import 'pages/vault_secret_detail_page.dart';
import 'pages/vault_audit_page.dart';
import 'pages/vault_seal_page.dart';
import 'pages/vault_secrets_page.dart';
import 'pages/tech_debt_page.dart';
import 'pages/project_detail_page.dart';
import 'pages/task_list_page.dart';
import 'pages/task_manager_page.dart';
import 'pages/projects_page.dart';
import 'pages/fleet/container_list_page.dart';
import 'pages/fleet/fleet_dashboard_page.dart';
import 'pages/relay/relay_page.dart';
import 'pages/scribe_page.dart';
import 'pages/settings_page.dart';
import 'services/auth/auth_service.dart';
import 'widgets/shell/navigation_shell.dart';

/// Listenable adapter that bridges [AuthService] state to GoRouter.
///
/// Updates [GoRouter.refreshListenable] whenever the auth state changes.
class AuthNotifier extends ChangeNotifier {
  AuthState _state = AuthState.unknown;

  /// The current authentication state.
  AuthState get state => _state;

  /// Updates the auth state and notifies the router.
  set state(AuthState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }
}

/// Global auth notifier instance used by the router.
///
/// [AuthService] updates this when auth state changes.
final AuthNotifier authNotifier = AuthNotifier();

/// The application router with all 64 routes.
final GoRouter router = GoRouter(
  initialLocation: '/login',
  refreshListenable: authNotifier,
  redirect: (BuildContext context, GoRouterState state) {
    final authenticated = authNotifier.state == AuthState.authenticated;
    final onLogin = state.matchedLocation == '/login';
    final onSetup = state.matchedLocation == '/setup';

    if (!authenticated && !onLogin) return '/login';
    if (authenticated && onLogin) return '/';
    if (authenticated && onSetup) return null;
    return null;
  },
  routes: [
    // 1. Login (outside shell)
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    // 2. Setup Wizard (outside shell)
    GoRoute(
      path: '/setup',
      name: 'setup',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Setup Wizard'),
    ),
    // Authenticated routes wrapped in NavigationShell
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        // 3. Home
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
        ),
        // 4. Projects
        GoRoute(
          path: '/projects',
          name: 'projects',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProjectsPage(),
          ),
        ),
        // 5. Project Detail
        GoRoute(
          path: '/projects/:id',
          name: 'projectDetail',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProjectDetailPage(),
          ),
        ),
        // 6. GitHub Browser
        GoRoute(
          path: '/repos',
          name: 'repos',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GitHubBrowserPage(),
          ),
        ),
        // 7. Scribe
        GoRoute(
          path: '/scribe',
          name: 'scribe',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ScribePage(),
          ),
        ),
        // 8. Audit Wizard
        GoRoute(
          path: '/audit',
          name: 'audit',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AuditWizardPage(),
          ),
        ),
        // 8. Compliance Wizard
        GoRoute(
          path: '/compliance',
          name: 'compliance',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ComplianceWizardPage(),
          ),
        ),
        // 9. Dependency Scan
        GoRoute(
          path: '/dependencies',
          name: 'dependencies',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DependencyScanPage(),
          ),
        ),
        // 10. Bug Investigator
        GoRoute(
          path: '/bugs',
          name: 'bugs',
          pageBuilder: (context, state) => NoTransitionPage(
            child: BugInvestigatorPage(
              initialJiraKey: state.uri.queryParameters['jiraKey'],
            ),
          ),
        ),
        // 11. Jira Browser
        GoRoute(
          path: '/bugs/jira',
          name: 'jiraBrowser',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: JiraBrowserPage(),
          ),
        ),
        // 12. Task Manager
        GoRoute(
          path: '/tasks',
          name: 'tasks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TaskManagerPage(),
          ),
        ),
        // 13. Tech Debt
        GoRoute(
          path: '/tech-debt',
          name: 'techDebt',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TechDebtPage(),
          ),
        ),
        // 14. Health Dashboard
        GoRoute(
          path: '/health',
          name: 'health',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HealthDashboardPage(),
          ),
        ),
        // 15. Job History
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: JobHistoryPage(),
          ),
        ),
        // 16. Job Progress
        GoRoute(
          path: '/jobs/:id',
          name: 'jobProgress',
          pageBuilder: (context, state) => NoTransitionPage(
            child: JobProgressPage(
              jobId: state.pathParameters['id']!,
            ),
          ),
        ),
        // 17. Job Report
        GoRoute(
          path: '/jobs/:id/report',
          name: 'jobReport',
          pageBuilder: (context, state) => NoTransitionPage(
            child: JobReportPage(
              jobId: state.pathParameters['id']!,
            ),
          ),
        ),
        // 18. Findings Explorer
        GoRoute(
          path: '/jobs/:id/findings',
          name: 'findingsExplorer',
          pageBuilder: (context, state) => NoTransitionPage(
            child: FindingsExplorerPage(
              jobId: state.pathParameters['id']!,
            ),
          ),
        ),
        // 19. Task List
        GoRoute(
          path: '/jobs/:id/tasks',
          name: 'taskList',
          pageBuilder: (context, state) => NoTransitionPage(
            child: TaskListPage(
              jobId: state.pathParameters['id']!,
            ),
          ),
        ),
        // 20. Personas
        GoRoute(
          path: '/personas',
          name: 'personas',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PersonasPage(),
          ),
        ),
        // 21. Persona Editor
        GoRoute(
          path: '/personas/:id/edit',
          name: 'personaEditor',
          pageBuilder: (context, state) => NoTransitionPage(
            child: PersonaEditorPage(
              personaId: state.pathParameters['id']!,
            ),
          ),
        ),
        // 22. Directives
        GoRoute(
          path: '/directives',
          name: 'directives',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DirectivesPage(),
          ),
        ),
        // 23. Settings
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
        // 24. Admin Hub
        GoRoute(
          path: '/admin',
          name: 'admin',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminHubPage(),
          ),
        ),
        // 25. Vault Dashboard
        GoRoute(
          path: '/vault',
          name: 'vault',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VaultDashboardPage(),
          ),
        ),
        // 26. Vault Secrets
        GoRoute(
          path: '/vault/secrets',
          name: 'vault-secrets',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VaultSecretsPage(),
          ),
        ),
        // 27. Vault Secret Detail
        GoRoute(
          path: '/vault/secrets/:id',
          name: 'vault-secret-detail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
              child: VaultSecretDetailPage(secretId: id),
            );
          },
        ),
        // 28. Vault Policies
        GoRoute(
          path: '/vault/policies',
          name: 'vault-policies',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VaultPoliciesPage(),
          ),
        ),
        // 28a. Vault Policy Detail
        GoRoute(
          path: '/vault/policies/:id',
          name: 'vault-policy-detail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
              child: VaultPolicyDetailPage(policyId: id),
            );
          },
        ),
        // 29. Vault Transit
        GoRoute(
          path: '/vault/transit',
          name: 'vault-transit',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VaultTransitPage(),
          ),
        ),
        // 30. Vault Dynamic Secrets
        GoRoute(
          path: '/vault/dynamic',
          name: 'vault-dynamic',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VaultDynamicPage(),
          ),
        ),
        // 30a. Vault Rotation
        GoRoute(
          path: '/vault/rotation',
          name: 'vault-rotation',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VaultRotationPage(),
          ),
        ),
        // 31. Vault Seal
        GoRoute(
          path: '/vault/seal',
          name: 'vault-seal',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VaultSealPage(),
          ),
        ),
        // 31a. Vault Audit
        GoRoute(
          path: '/vault/audit',
          name: 'vault-audit',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VaultAuditPage(),
          ),
        ),
        // 32. Registry — Service List
        GoRoute(
          path: '/registry',
          name: 'registry',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ServiceListPage(),
          ),
        ),
        // 33. Registry — Register Service
        GoRoute(
          path: '/registry/services/new',
          name: 'registry-service-new',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ServiceFormPage(),
          ),
        ),
        // 34. Registry — Service Detail
        GoRoute(
          path: '/registry/services/:id',
          name: 'registry-service-detail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
              child: ServiceDetailPage(serviceId: id),
            );
          },
        ),
        // 35. Registry — Edit Service
        GoRoute(
          path: '/registry/services/:id/edit',
          name: 'registry-service-edit',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
              child: ServiceFormPage(serviceId: id),
            );
          },
        ),
        // 36. Registry — Port Allocations
        GoRoute(
          path: '/registry/ports',
          name: 'registry-ports',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PortAllocationPage(),
          ),
        ),
        // 37. Registry — Solutions List
        GoRoute(
          path: '/registry/solutions',
          name: 'registry-solutions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SolutionListPage(),
          ),
        ),
        // 38. Registry — Solution Detail
        GoRoute(
          path: '/registry/solutions/:solutionId',
          name: 'registry-solution-detail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['solutionId']!;
            return NoTransitionPage(
              child: SolutionDetailPage(solutionId: id),
            );
          },
        ),
        // 39. Registry — Dependency Graph
        GoRoute(
          path: '/registry/dependencies',
          name: 'registry-dependencies',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DependencyGraphPage(),
          ),
        ),
        // 40. Registry — Impact Analysis
        GoRoute(
          path: '/registry/dependencies/impact',
          name: 'registry-impact-analysis',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ImpactAnalysisPage(),
          ),
        ),
        // 41. Registry — Topology Viewer
        GoRoute(
          path: '/registry/topology',
          name: 'registry-topology',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TopologyPage(),
          ),
        ),
        // 42. Registry — Infrastructure Resources
        GoRoute(
          path: '/registry/infra',
          name: 'registry-infra',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InfraResourcesPage(),
          ),
        ),
        // 43. Registry — API Routes
        GoRoute(
          path: '/registry/routes',
          name: 'registry-routes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ApiRoutesPage(),
          ),
        ),
        // 44. Registry — Config Generator
        GoRoute(
          path: '/registry/config',
          name: 'registry-config',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ConfigGeneratorPage(),
          ),
        ),
        // 45. Registry — Workstation Profiles
        GoRoute(
          path: '/registry/workstations',
          name: 'registry-workstations',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WorkstationListPage(),
          ),
        ),
        // 46. Registry — Workstation Detail
        GoRoute(
          path: '/registry/workstations/:profileId',
          name: 'registry-workstation-detail',
          pageBuilder: (context, state) {
            final id = state.pathParameters['profileId']!;
            return NoTransitionPage(
              child: WorkstationDetailPage(profileId: id),
            );
          },
        ),
        // 47. Registry — API Docs Viewer
        GoRoute(
          path: '/registry/api-docs',
          name: 'registry-api-docs',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ApiDocsPage(),
          ),
        ),
        // 48. Registry — API Docs for Service
        GoRoute(
          path: '/registry/api-docs/:serviceId',
          name: 'registry-api-docs-service',
          pageBuilder: (context, state) {
            final id = state.pathParameters['serviceId']!;
            return NoTransitionPage(
              child: ApiDocsPage(serviceId: id),
            );
          },
        ),
        // 49. Fleet — Health Dashboard
        GoRoute(
          path: '/fleet',
          name: 'fleet',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FleetDashboardPage(),
          ),
        ),
        // 50. Fleet — Containers
        GoRoute(
          path: '/fleet/containers',
          name: 'fleet-containers',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ContainerListPage(),
          ),
        ),
        // 51. Fleet — Container Detail
        GoRoute(
          path: '/fleet/containers/:id',
          name: 'fleet-container-detail',
          pageBuilder: (context, state) => NoTransitionPage(
            child: PlaceholderPage(
              title: 'Container ${state.pathParameters['id']!}',
            ),
          ),
        ),
        // 52. Fleet — Service Profiles
        GoRoute(
          path: '/fleet/service-profiles',
          name: 'fleet-service-profiles',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Service Profiles'),
          ),
        ),
        // 53. Fleet — Service Profile Detail
        GoRoute(
          path: '/fleet/service-profiles/:id',
          name: 'fleet-service-profile-detail',
          pageBuilder: (context, state) => NoTransitionPage(
            child: PlaceholderPage(
              title: 'Service Profile ${state.pathParameters['id']!}',
            ),
          ),
        ),
        // 54. Fleet — Solution Profiles
        GoRoute(
          path: '/fleet/solution-profiles',
          name: 'fleet-solution-profiles',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Solution Profiles'),
          ),
        ),
        // 55. Fleet — Solution Profile Detail
        GoRoute(
          path: '/fleet/solution-profiles/:id',
          name: 'fleet-solution-profile-detail',
          pageBuilder: (context, state) => NoTransitionPage(
            child: PlaceholderPage(
              title: 'Solution Profile ${state.pathParameters['id']!}',
            ),
          ),
        ),
        // 56. Fleet — Workstation Profiles
        GoRoute(
          path: '/fleet/workstation-profiles',
          name: 'fleet-workstation-profiles',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Workstation Profiles'),
          ),
        ),
        // 57. Fleet — Workstation Profile Detail
        GoRoute(
          path: '/fleet/workstation-profiles/:id',
          name: 'fleet-workstation-profile-detail',
          pageBuilder: (context, state) => NoTransitionPage(
            child: PlaceholderPage(
              title: 'Workstation Profile ${state.pathParameters['id']!}',
            ),
          ),
        ),
        // 58. Fleet — Docker Images
        GoRoute(
          path: '/fleet/images',
          name: 'fleet-images',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Docker Images'),
          ),
        ),
        // 59. Fleet — Docker Volumes
        GoRoute(
          path: '/fleet/volumes',
          name: 'fleet-volumes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Docker Volumes'),
          ),
        ),
        // 60. Fleet — Docker Networks
        GoRoute(
          path: '/fleet/networks',
          name: 'fleet-networks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Docker Networks'),
          ),
        ),
        // 61. Relay — Messaging shell
        GoRoute(
          path: '/relay',
          name: 'relay',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RelayPage(),
          ),
          routes: [
            // 50. Relay — Channel selected
            GoRoute(
              path: 'channel/:channelId',
              name: 'relay-channel',
              pageBuilder: (context, state) {
                final channelId = state.pathParameters['channelId']!;
                return NoTransitionPage(
                  child: RelayPage(initialChannelId: channelId),
                );
              },
              routes: [
                // 51. Relay — Thread open
                GoRoute(
                  path: 'thread/:messageId',
                  name: 'relay-thread',
                  pageBuilder: (context, state) {
                    final channelId = state.pathParameters['channelId']!;
                    final messageId = state.pathParameters['messageId']!;
                    return NoTransitionPage(
                      child: RelayPage(
                        initialChannelId: channelId,
                        initialThreadMessageId: messageId,
                      ),
                    );
                  },
                ),
              ],
            ),
            // 52. Relay — DM selected
            GoRoute(
              path: 'dm/:conversationId',
              name: 'relay-dm',
              pageBuilder: (context, state) {
                final conversationId =
                    state.pathParameters['conversationId']!;
                return NoTransitionPage(
                  child: RelayPage(initialConversationId: conversationId),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
