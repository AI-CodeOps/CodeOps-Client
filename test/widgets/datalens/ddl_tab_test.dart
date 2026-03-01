// Widget tests for DdlTab.
//
// Verifies DDL display rendering: toolbar, DDL content, copy button,
// empty state, and selectable text.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/datalens_providers.dart';
import 'package:codeops/widgets/datalens/ddl_tab.dart';

const _testDdl = '''CREATE TABLE public.users (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name character varying(255) NOT NULL DEFAULT ''::character varying,
    email character varying(255) NOT NULL,
    team_id uuid,
    created_at timestamp(6) without time zone,
    is_active boolean NOT NULL DEFAULT true,
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id)
);''';

Widget _createWidget({
  String? ddl,
  bool useNull = false,
}) {
  return ProviderScope(
    overrides: [
      datalensDdlProvider.overrideWith(
        (ref) => Future.value(useNull ? null : (ddl ?? _testDdl)),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: DdlTab()),
    ),
  );
}

void main() {
  group('DdlTab', () {
    testWidgets('renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DdlTab), findsOneWidget);
    });

    testWidgets('shows DDL toolbar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text('DDL'), findsOneWidget);
    });

    testWidgets('shows copy button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows DDL content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.text(_testDdl), findsOneWidget);
    });

    testWidgets('DDL content is selectable', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('shows empty state when no DDL', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_createWidget(useNull: true));
      await tester.pumpAndSettle();

      expect(find.text('No DDL available'), findsOneWidget);
    });

    testWidgets('copy button changes to check icon after tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Mock the clipboard platform channel.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') return null;
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(_createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);

      // Drain the 2-second timer that resets the icon back to copy.
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
