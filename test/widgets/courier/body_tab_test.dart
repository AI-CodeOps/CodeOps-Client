// Widget tests for BodyTab.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/providers/courier_ui_providers.dart';
import 'package:codeops/widgets/courier/body_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget buildBodyTab({
  List<Override> overrides = const [],
  BodyType bodyType = BodyType.none,
}) {
  return ProviderScope(
    overrides: [
      bodyTypeProvider.overrideWith((ref) => bodyType),
      bodyRawContentProvider.overrideWith((ref) => ''),
      bodyFormDataProvider.overrideWith((ref) => []),
      bodyGraphqlQueryProvider.overrideWith((ref) => ''),
      bodyGraphqlVariablesProvider.overrideWith((ref) => ''),
      bodyBinaryFileNameProvider.overrideWith((ref) => ''),
      ...overrides,
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: BodyTab(),
        ),
      ),
    ),
  );
}

void setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BodyTab', () {
    testWidgets('renders body type selector', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBodyTab());
      await tester.pumpAndSettle();

      expect(find.byType(BodyTab), findsOneWidget);
      expect(find.byKey(const Key('body_type_selector')), findsOneWidget);
    });

    testWidgets('shows none hint when body type is none', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBodyTab(bodyType: BodyType.none));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_none_hint')), findsOneWidget);
      expect(
          find.text('This request does not have a body'), findsOneWidget);
    });

    testWidgets('shows radio buttons for top-level types', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBodyTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_type_none')), findsOneWidget);
      expect(find.byKey(const Key('body_type_formData')), findsOneWidget);
      expect(find.byKey(const Key('body_type_xWwwFormUrlEncoded')),
          findsOneWidget);
      expect(find.byKey(const Key('body_type_binary')), findsOneWidget);
      expect(find.byKey(const Key('body_type_graphql')), findsOneWidget);
    });

    testWidgets('shows raw dropdown menu button', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBodyTab());
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('body_type_raw_dropdown')), findsOneWidget);
    });

    testWidgets('shows form data editor when form-data selected',
        (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildBodyTab(bodyType: BodyType.formData));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_form_data_editor')), findsOneWidget);
    });

    testWidgets('shows urlencoded editor when url-encoded selected',
        (tester) async {
      setSize(tester);
      await tester
          .pumpWidget(buildBodyTab(bodyType: BodyType.xWwwFormUrlEncoded));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('body_urlencoded_editor')), findsOneWidget);
    });

    testWidgets('shows binary editor when binary selected', (tester) async {
      setSize(tester);
      await tester.pumpWidget(buildBodyTab(bodyType: BodyType.binary));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_binary_editor')), findsOneWidget);
    });

    testWidgets('contentTypeForBodyType has correct mappings', (_) async {
      expect(contentTypeForBodyType[BodyType.rawJson], 'application/json');
      expect(contentTypeForBodyType[BodyType.rawXml], 'application/xml');
      expect(contentTypeForBodyType[BodyType.rawHtml], 'text/html');
      expect(contentTypeForBodyType[BodyType.rawText], 'text/plain');
      expect(contentTypeForBodyType[BodyType.rawYaml], 'application/x-yaml');
      expect(contentTypeForBodyType[BodyType.formData],
          'multipart/form-data');
      expect(contentTypeForBodyType[BodyType.xWwwFormUrlEncoded],
          'application/x-www-form-urlencoded');
      expect(contentTypeForBodyType[BodyType.binary],
          'application/octet-stream');
      expect(contentTypeForBodyType[BodyType.graphql], 'application/json');
      expect(contentTypeForBodyType[BodyType.none], '');
    });
  });
}
