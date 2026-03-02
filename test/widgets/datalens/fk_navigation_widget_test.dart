// Widget tests for FkNavigationWidget components.
//
// Verifies FkCellIndicator rendering and navigation callback,
// FkBreadcrumbTrail rendering with breadcrumb taps and home button.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_models.dart';
import 'package:codeops/widgets/datalens/fk_navigation_widget.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // FkCellIndicator
  // ─────────────────────────────────────────────────────────────────────────
  group('FkCellIndicator', () {
    testWidgets('renders link icon for non-null FK value', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FkCellIndicator(
            cellValue: 42,
            foreignKey: const ForeignKeyInfo(
              columns: ['user_id'],
              referencedSchema: 'public',
              referencedTable: 'users',
              referencedColumns: ['id'],
            ),
            sourceColumn: 'user_id',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('renders nothing for null FK value', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FkCellIndicator(
            cellValue: null,
            foreignKey: const ForeignKeyInfo(
              columns: ['user_id'],
              referencedTable: 'users',
              referencedColumns: ['id'],
            ),
            sourceColumn: 'user_id',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.link), findsNothing);
    });

    testWidgets('fires onNavigate callback on tap', (tester) async {
      String? navSchema;
      String? navTable;
      String? navColumn;
      dynamic navValue;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FkCellIndicator(
            cellValue: 42,
            foreignKey: const ForeignKeyInfo(
              columns: ['user_id'],
              referencedSchema: 'public',
              referencedTable: 'users',
              referencedColumns: ['id'],
            ),
            sourceColumn: 'user_id',
            onNavigate: (schema, table, column, value) {
              navSchema = schema;
              navTable = table;
              navColumn = column;
              navValue = value;
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.link));

      expect(navSchema, 'public');
      expect(navTable, 'users');
      expect(navColumn, 'id');
      expect(navValue, 42);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FkBreadcrumbTrail
  // ─────────────────────────────────────────────────────────────────────────
  group('FkBreadcrumbTrail', () {
    testWidgets('renders nothing when no breadcrumbs', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: FkBreadcrumbTrail(
            breadcrumbs: [],
            currentTable: 'users',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsNothing);
    });

    testWidgets('renders breadcrumbs with home icon and current table',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FkBreadcrumbTrail(
            breadcrumbs: const [
              FkBreadcrumb(
                schemaName: 'public',
                tableName: 'orders',
                label: 'orders',
              ),
            ],
            currentTable: 'users',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.text('orders'), findsOneWidget);
      expect(find.text('users'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('fires onBreadcrumbTap callback', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FkBreadcrumbTrail(
            breadcrumbs: const [
              FkBreadcrumb(
                schemaName: 'public',
                tableName: 'orders',
                label: 'orders',
              ),
            ],
            currentTable: 'users',
            onBreadcrumbTap: (idx) => tappedIndex = idx,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('orders'));

      expect(tappedIndex, 0);
    });

    testWidgets('fires onHome callback', (tester) async {
      var homePressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FkBreadcrumbTrail(
            breadcrumbs: const [
              FkBreadcrumb(
                schemaName: 'public',
                tableName: 'orders',
                label: 'orders',
              ),
            ],
            currentTable: 'users',
            onHome: () => homePressed = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.home_outlined));

      expect(homePressed, isTrue);
    });
  });
}
