// Widget tests for LogLevelBadge.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/theme/colors.dart';
import 'package:codeops/widgets/logger/log_level_badge.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('LogLevelBadge', () {
    testWidgets('renders full badge with level text', (tester) async {
      await tester.pumpWidget(wrap(
        const LogLevelBadge(level: LogLevel.error),
      ));

      expect(find.text('ERROR'), findsOneWidget);
    });

    testWidgets('renders compact dot without text', (tester) async {
      await tester.pumpWidget(wrap(
        const LogLevelBadge(level: LogLevel.info, compact: true),
      ));

      // No text should be present in compact mode.
      expect(find.text('INFO'), findsNothing);
      // Should have a Container with BoxDecoration circle.
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('colorForLevel returns correct colors', (tester) async {
      expect(LogLevelBadge.colorForLevel(LogLevel.fatal), CodeOpsColors.critical);
      expect(LogLevelBadge.colorForLevel(LogLevel.error), CodeOpsColors.error);
      expect(LogLevelBadge.colorForLevel(LogLevel.warn), CodeOpsColors.warning);
      expect(LogLevelBadge.colorForLevel(LogLevel.info), CodeOpsColors.secondary);
      expect(LogLevelBadge.colorForLevel(LogLevel.debug), CodeOpsColors.textSecondary);
      expect(LogLevelBadge.colorForLevel(LogLevel.trace), CodeOpsColors.textTertiary);
    });

    testWidgets('renders all six log levels', (tester) async {
      for (final level in LogLevel.values) {
        await tester.pumpWidget(wrap(LogLevelBadge(level: level)));
        expect(
          find.text(level.displayName.toUpperCase()),
          findsOneWidget,
          reason: 'Badge for ${level.name} should show text',
        );
      }
    });
  });
}
