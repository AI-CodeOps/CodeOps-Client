/// Riverpod providers for application settings.
///
/// Manages local settings state for Claude model selection,
/// agent configuration, and connectivity status.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/constants.dart';

/// Claude model selection.
final claudeModelProvider = StateProvider<String>(
  (ref) => AppConstants.defaultClaudeModel,
);

/// Max concurrent agents setting.
final maxConcurrentAgentsProvider = StateProvider<int>(
  (ref) => AppConstants.defaultMaxConcurrentAgents,
);

/// Agent timeout in minutes.
final agentTimeoutMinutesProvider = StateProvider<int>(
  (ref) => AppConstants.defaultAgentTimeoutMinutes,
);

/// Whether the app is in offline mode.
final offlineModeProvider = StateProvider<bool>((ref) => false);

/// Current connectivity status.
final connectivityProvider = StateProvider<bool>((ref) => true);
