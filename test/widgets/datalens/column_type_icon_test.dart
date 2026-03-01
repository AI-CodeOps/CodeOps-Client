// Widget tests for ColumnTypeIcon.
//
// Verifies that the correct icon is displayed for each column data type
// and category (primary key, foreign key, text, number, timestamp, etc.).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_enums.dart';
import 'package:codeops/widgets/datalens/column_type_icon.dart';

Widget _createWidget({String? udtName, ColumnCategory? category}) {
  return MaterialApp(
    home: Scaffold(
      body: ColumnTypeIcon(udtName: udtName, category: category),
    ),
  );
}

void main() {
  group('ColumnTypeIcon', () {
    testWidgets('varchar shows sort_by_alpha icon', (tester) async {
      await tester.pumpWidget(_createWidget(udtName: 'varchar'));

      expect(find.byIcon(Icons.sort_by_alpha), findsOneWidget);
    });

    testWidgets('int4 shows tag icon', (tester) async {
      await tester.pumpWidget(_createWidget(udtName: 'int4'));

      expect(find.byIcon(Icons.tag), findsOneWidget);
    });

    testWidgets('timestamp shows access_time icon', (tester) async {
      await tester.pumpWidget(_createWidget(udtName: 'timestamp'));

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('bool shows check_box_outlined icon', (tester) async {
      await tester.pumpWidget(_createWidget(udtName: 'bool'));

      expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
    });

    testWidgets('jsonb shows data_object icon', (tester) async {
      await tester.pumpWidget(_createWidget(udtName: 'jsonb'));

      expect(find.byIcon(Icons.data_object), findsOneWidget);
    });

    testWidgets('uuid shows fingerprint icon', (tester) async {
      await tester.pumpWidget(_createWidget(udtName: 'uuid'));

      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    });

    testWidgets('primaryKey category shows vpn_key icon', (tester) async {
      await tester.pumpWidget(
        _createWidget(udtName: 'uuid', category: ColumnCategory.primaryKey),
      );

      // PK overrides data-type icon.
      expect(find.byIcon(Icons.vpn_key), findsOneWidget);
    });

    testWidgets('foreignKey category shows link icon', (tester) async {
      await tester.pumpWidget(
        _createWidget(udtName: 'uuid', category: ColumnCategory.foreignKey),
      );

      expect(find.byIcon(Icons.link), findsOneWidget);
    });
  });
}
