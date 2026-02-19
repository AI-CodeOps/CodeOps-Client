/// GoRouter configuration with all 31 application routes.
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
import 'pages/vault_dashboard_page.dart';
import 'pages/vault_secret_detail_page.dart';
import 'pages/vault_secrets_page.dart';
import 'pages/tech_debt_page.dart';
import 'pages/project_detail_page.dart';
import 'pages/task_list_page.dart';
import 'pages/task_manager_page.dart';
import 'pages/projects_page.dart';
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

/// The application router with all 31 routes.
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
            child: PlaceholderPage(title: 'Policies'),
          ),
        ),
        // 29. Vault Transit
        GoRoute(
          path: '/vault/transit',
          name: 'vault-transit',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Transit'),
          ),
        ),
        // 30. Vault Dynamic Secrets
        GoRoute(
          path: '/vault/dynamic',
          name: 'vault-dynamic',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Dynamic Secrets'),
          ),
        ),
        // 31. Vault Seal
        GoRoute(
          path: '/vault/seal',
          name: 'vault-seal',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderPage(title: 'Seal'),
          ),
        ),
      ],
    ),
  ],
);
