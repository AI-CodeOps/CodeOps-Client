// Widget tests for DashboardWidgetCard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/logger_enums.dart';
import 'package:codeops/models/logger_models.dart';
import 'package:codeops/widgets/logger/dashboard_widget_card.dart';

void main() {
  final counterWidget = DashboardWidgetResponse(
    id: 'w-1',
    dashboardId: 'dash-1',
    title: 'Total Errors',
    widgetType: WidgetType.counter,
    configJson: '{"value":1234,"label":"errors"}',
    gridX: 0,
    gridY: 0,
    gridWidth: 4,
    gridHeight: 2,
    sortOrder: 0,
  );

  Widget createWidget({
    DashboardWidgetResponse? widget,
    bool isEditMode = false,
    VoidCallback? onRefresh,
    VoidCallback? onConfigure,
    VoidCallback? onRemove,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: DashboardWidgetCard(
            widget: widget ?? counterWidget,
            isEditMode: isEditMode,
            onRefresh: onRefresh,
            onConfigure: onConfigure,
            onRemove: onRemove,
          ),
        ),
      ),
    );
  }

  group('DashboardWidgetCard', () {
    testWidgets('renders widget title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Total Errors'), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(createWidget(onRefresh: () {}));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows configure button', (tester) async {
      await tester.pumpWidget(createWidget(onConfigure: () {}));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('shows remove button in edit mode', (tester) async {
      await tester.pumpWidget(
        createWidget(isEditMode: true, onRemove: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides remove button outside edit mode', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
