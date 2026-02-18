/// Global configuration for the logging subsystem.
///
/// Call [LogConfig.initialize] once at startup (after
/// `WidgetsFlutterBinding.ensureInitialized()`) to apply environment-aware
/// defaults. All fields are mutable so tests or settings UI can override them.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'log_level.dart';

/// Centralized logging configuration.
///
/// * **Debug builds** — level=[LogLevel.debug], console colors on, file
///   logging off.
/// * **Release builds** — level=[LogLevel.info], console colors off, file
///   logging on (daily rotation, 7-day retention).
class LogConfig {
  LogConfig._();

  /// Minimum severity that will be emitted. Messages below this are silently
  /// discarded.
  static LogLevel minimumLevel = LogLevel.debug;

  /// Whether log messages are also written to daily log files.
  static bool enableFileLogging = false;

  /// Whether ANSI color codes are included in console output.
  static bool enableConsoleColors = true;

  /// Tags listed here are silently suppressed regardless of level.
  static final Set<String> mutedTags = {};

  /// Directory where log files are written when [enableFileLogging] is true.
  ///
  /// Defaults to `<appSupportDir>/logs` after [initialize] completes.
  static String? logDirectory;

  /// Applies environment-aware defaults.
  ///
  /// Must be called once during app startup, after
  /// `WidgetsFlutterBinding.ensureInitialized()`.
  static Future<void> initialize() async {
    if (kDebugMode) {
      minimumLevel = LogLevel.debug;
      enableFileLogging = false;
      enableConsoleColors = true;
    } else {
      minimumLevel = LogLevel.info;
      enableFileLogging = true;
      enableConsoleColors = false;
    }

    try {
      if (kDebugMode) {
        // In debug mode, write logs to the project directory for easy access.
        logDirectory = '${Directory.current.path}${Platform.pathSeparator}logs';
      } else {
        final appDir = await getApplicationSupportDirectory();
        logDirectory = '${appDir.path}${Platform.pathSeparator}logs';
      }
    } on Object {
      // path_provider may fail in test environments — leave null.
      logDirectory = null;
    }
  }
}
