/// Root widget for the CodeOps application.
///
/// Applies the dark theme and configures the [GoRouter] for navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// The root application widget.
class CodeOpsApp extends ConsumerWidget {
  /// Creates the [CodeOpsApp].
  const CodeOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bridge AuthService stream → GoRouter's authNotifier
    ref.listen(authStateProvider, (_, next) {
      next.whenData((state) => authNotifier.state = state);
    });

    return MaterialApp.router(
      title: 'CodeOps',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
