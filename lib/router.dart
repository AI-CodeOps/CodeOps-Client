/// GoRouter configuration with all 24 application routes.
///
/// Uses a [ValueNotifier] for auth state (replaced by real auth in COC-002).
/// Unauthenticated users are redirected to `/login`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/placeholder_page.dart';

/// Temporary auth state notifier — replaced by real auth in COC-002.
final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);

/// The application router with all 24 routes.
final GoRouter router = GoRouter(
  initialLocation: '/login',
  refreshListenable: isAuthenticated,
  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = isAuthenticated.value;
    final loggingIn = state.matchedLocation == '/login';

    if (!loggedIn && !loggingIn) return '/login';
    if (loggedIn && loggingIn) return '/';
    return null;
  },
  routes: [
    // 1. Login
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const PlaceholderPage(title: 'Login'),
    ),
    // 2. Setup Wizard
    GoRoute(
      path: '/setup',
      name: 'setup',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Setup Wizard'),
    ),
    // 3. Home
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const PlaceholderPage(title: 'Home'),
    ),
    // 4. Projects
    GoRoute(
      path: '/projects',
      name: 'projects',
      builder: (context, state) => const PlaceholderPage(title: 'Projects'),
    ),
    // 5. Project Detail
    GoRoute(
      path: '/projects/:id',
      name: 'projectDetail',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Project Detail'),
    ),
    // 6. GitHub Browser
    GoRoute(
      path: '/repos',
      name: 'repos',
      builder: (context, state) =>
          const PlaceholderPage(title: 'GitHub Browser'),
    ),
    // 7. Audit Wizard
    GoRoute(
      path: '/audit',
      name: 'audit',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Audit Wizard'),
    ),
    // 8. Compliance Wizard
    GoRoute(
      path: '/compliance',
      name: 'compliance',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Compliance Wizard'),
    ),
    // 9. Dependency Scan
    GoRoute(
      path: '/dependencies',
      name: 'dependencies',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Dependency Scan'),
    ),
    // 10. Bug Investigator
    GoRoute(
      path: '/bugs',
      name: 'bugs',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Bug Investigator'),
    ),
    // 11. Jira Browser
    GoRoute(
      path: '/bugs/jira',
      name: 'jiraBrowser',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Jira Browser'),
    ),
    // 12. Task Manager
    GoRoute(
      path: '/tasks',
      name: 'tasks',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Task Manager'),
    ),
    // 13. Tech Debt
    GoRoute(
      path: '/tech-debt',
      name: 'techDebt',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Tech Debt'),
    ),
    // 14. Health Dashboard
    GoRoute(
      path: '/health',
      name: 'health',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Health Dashboard'),
    ),
    // 15. Job History
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Job History'),
    ),
    // 16. Job Progress
    GoRoute(
      path: '/jobs/:id',
      name: 'jobProgress',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Job Progress'),
    ),
    // 17. Job Report
    GoRoute(
      path: '/jobs/:id/report',
      name: 'jobReport',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Job Report'),
    ),
    // 18. Findings Explorer
    GoRoute(
      path: '/jobs/:id/findings',
      name: 'findingsExplorer',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Findings Explorer'),
    ),
    // 19. Task List
    GoRoute(
      path: '/jobs/:id/tasks',
      name: 'taskList',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Task List'),
    ),
    // 20. Personas
    GoRoute(
      path: '/personas',
      name: 'personas',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Personas'),
    ),
    // 21. Persona Editor
    GoRoute(
      path: '/personas/:id/edit',
      name: 'personaEditor',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Persona Editor'),
    ),
    // 22. Directives
    GoRoute(
      path: '/directives',
      name: 'directives',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Directives'),
    ),
    // 23. Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Settings'),
    ),
    // 24. Admin Hub
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) =>
          const PlaceholderPage(title: 'Admin Hub'),
    ),
  ],
);
