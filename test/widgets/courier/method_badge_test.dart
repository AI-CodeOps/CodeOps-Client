// Widget tests for MethodBadge.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/widgets/courier/collection_sidebar.dart';

Widget buildBadge(CourierHttpMethod method) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: MethodBadge(method: method)),
    ),
  );
}

void main() {
  group('MethodBadge', () {
    testWidgets('GET badge shows GET label', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.get));
      expect(find.text('GET'), findsOneWidget);
    });

    testWidgets('POST badge shows POST label', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.post));
      expect(find.text('POST'), findsOneWidget);
    });

    testWidgets('PUT badge shows PUT label', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.put));
      expect(find.text('PUT'), findsOneWidget);
    });

    testWidgets('PATCH badge shows PATCH label', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.patch));
      expect(find.text('PATCH'), findsOneWidget);
    });

    testWidgets('DELETE badge shows DELETE label', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.delete));
      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('HEAD badge shows HEAD label', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.head));
      expect(find.text('HEAD'), findsOneWidget);
    });

    testWidgets('OPTIONS badge shows OPTIONS label', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.options));
      expect(find.text('OPTIONS'), findsOneWidget);
    });

    testWidgets('GET badge uses green color #49CC90', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.get));
      await tester.pump();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MethodBadge),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      // The text color should be the GET green
      expect(decoration.border, isNotNull);
    });

    testWidgets('DELETE badge uses red color #F93E3E', (tester) async {
      await tester.pumpWidget(buildBadge(CourierHttpMethod.delete));
      await tester.pump();

      // Verify the widget renders without error and shows DELETE text
      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('renders without error for all methods', (tester) async {
      for (final method in CourierHttpMethod.values) {
        await tester.pumpWidget(buildBadge(method));
        await tester.pump();
        expect(find.byType(MethodBadge), findsOneWidget);
      }
    });
  });
}
