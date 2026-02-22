/// Icon widget representing the technology type of a registered service.
///
/// Maps each [ServiceType] enum value to a Material icon with a
/// technology-appropriate color and tooltip showing the display name.
library;

import 'package:flutter/material.dart';

import '../../models/registry_enums.dart';
import '../../theme/colors.dart';

/// Icon representing the service technology type.
///
/// Wraps the icon in a [Tooltip] showing the full [ServiceType.displayName].
class ServiceTypeIcon extends StatelessWidget {
  /// The service type to display.
  final ServiceType type;

  /// Icon size.
  final double size;

  /// Creates a [ServiceTypeIcon].
  const ServiceTypeIcon({super.key, required this.type, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final (:icon, :color) = _iconData(type);

    return Tooltip(
      message: type.displayName,
      child: Icon(icon, size: size, color: color),
    );
  }

  /// Returns the icon and color for a [ServiceType].
  static ({IconData icon, Color color}) _iconData(ServiceType type) =>
      switch (type) {
        ServiceType.springBootApi => (
            icon: Icons.api,
            color: CodeOpsColors.primary,
          ),
        ServiceType.flutterWeb => (
            icon: Icons.web,
            color: const Color(0xFF3B82F6),
          ),
        ServiceType.flutterDesktop => (
            icon: Icons.desktop_windows,
            color: const Color(0xFF3B82F6),
          ),
        ServiceType.flutterMobile => (
            icon: Icons.phone_android,
            color: const Color(0xFF3B82F6),
          ),
        ServiceType.reactSpa => (
            icon: Icons.web,
            color: const Color(0xFF06B6D4),
          ),
        ServiceType.vueSpa => (
            icon: Icons.web,
            color: CodeOpsColors.success,
          ),
        ServiceType.nextJs => (
            icon: Icons.web,
            color: CodeOpsColors.textPrimary,
          ),
        ServiceType.expressApi => (
            icon: Icons.api,
            color: CodeOpsColors.success,
          ),
        ServiceType.fastapi => (
            icon: Icons.api,
            color: const Color(0xFF14B8A6),
          ),
        ServiceType.dotnetApi => (
            icon: Icons.api,
            color: const Color(0xFFA855F7),
          ),
        ServiceType.goApi => (
            icon: Icons.api,
            color: const Color(0xFF06B6D4),
          ),
        ServiceType.library_ => (
            icon: Icons.library_books,
            color: const Color(0xFF14B8A6),
          ),
        ServiceType.worker => (
            icon: Icons.settings,
            color: CodeOpsColors.warning,
          ),
        ServiceType.gateway => (
            icon: Icons.router,
            color: CodeOpsColors.primary,
          ),
        ServiceType.databaseService => (
            icon: Icons.storage,
            color: CodeOpsColors.success,
          ),
        ServiceType.messageBroker => (
            icon: Icons.message,
            color: const Color(0xFFF97316),
          ),
        ServiceType.cacheService => (
            icon: Icons.memory,
            color: CodeOpsColors.error,
          ),
        ServiceType.mcpServer => (
            icon: Icons.smart_toy,
            color: const Color(0xFF6366F1),
          ),
        ServiceType.cliTool => (
            icon: Icons.terminal,
            color: CodeOpsColors.textSecondary,
          ),
        ServiceType.other => (
            icon: Icons.extension,
            color: CodeOpsColors.textTertiary,
          ),
      };
}
