// Tests for ErDiagramToolbar widget.
//
// Verifies that toolbar buttons render, notation toggle fires callbacks,
// and export buttons are present.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/datalens_er_models.dart';
import 'package:codeops/widgets/datalens/er_diagram_toolbar.dart';

Widget _wrap({
  ErNotation notation = ErNotation.crowsFoot,
  double zoom = 1.0,
  ValueChanged<ErNotation>? onNotationChanged,
  VoidCallback? onAutoLayout,
  VoidCallback? onZoomToFit,
  VoidCallback? onZoomReset,
  VoidCallback? onExpandAll,
  VoidCallback? onCollapseAll,
  VoidCallback? onExportPng,
  VoidCallback? onExportSvg,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ErDiagramToolbar(
        notation: notation,
        zoom: zoom,
        onNotationChanged: onNotationChanged,
        onAutoLayout: onAutoLayout,
        onZoomToFit: onZoomToFit,
        onZoomReset: onZoomReset,
        onExpandAll: onExpandAll,
        onCollapseAll: onCollapseAll,
        onExportPng: onExportPng,
        onExportSvg: onExportSvg,
      ),
    ),
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------
  group('Rendering', () {
    testWidgets('renders toolbar with all controls', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.byType(ErDiagramToolbar), findsOneWidget);
      expect(find.text("Crow's Foot"), findsOneWidget);
      expect(find.text('IDEF1X'), findsOneWidget);
    });

    testWidgets('displays zoom percentage', (tester) async {
      await tester.pumpWidget(_wrap(zoom: 1.5));
      expect(find.text('150%'), findsOneWidget);
    });

    testWidgets('displays 100% for default zoom', (tester) async {
      await tester.pumpWidget(_wrap(zoom: 1.0));
      expect(find.text('100%'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Notation Toggle
  // ---------------------------------------------------------------------------
  group('Notation toggle', () {
    testWidgets('tapping IDEF1X fires callback', (tester) async {
      ErNotation? received;
      await tester.pumpWidget(_wrap(
        notation: ErNotation.crowsFoot,
        onNotationChanged: (n) => received = n,
      ));

      await tester.tap(find.text('IDEF1X'));
      await tester.pump();
      expect(received, ErNotation.idef1x);
    });

    testWidgets('tapping Crows Foot fires callback', (tester) async {
      ErNotation? received;
      await tester.pumpWidget(_wrap(
        notation: ErNotation.idef1x,
        onNotationChanged: (n) => received = n,
      ));

      await tester.tap(find.text("Crow's Foot"));
      await tester.pump();
      expect(received, ErNotation.crowsFoot);
    });
  });

  // ---------------------------------------------------------------------------
  // Button Callbacks
  // ---------------------------------------------------------------------------
  group('Button callbacks', () {
    testWidgets('auto-layout button fires callback', (tester) async {
      var fired = false;
      await tester.pumpWidget(_wrap(onAutoLayout: () => fired = true));

      await tester.tap(find.byTooltip('Auto Layout'));
      await tester.pump();
      expect(fired, true);
    });

    testWidgets('zoom-to-fit button fires callback', (tester) async {
      var fired = false;
      await tester.pumpWidget(_wrap(onZoomToFit: () => fired = true));

      await tester.tap(find.byTooltip('Zoom to Fit'));
      await tester.pump();
      expect(fired, true);
    });

    testWidgets('export PNG button fires callback', (tester) async {
      var fired = false;
      await tester.pumpWidget(_wrap(onExportPng: () => fired = true));

      await tester.tap(find.byTooltip('Export PNG'));
      await tester.pump();
      expect(fired, true);
    });

    testWidgets('export SVG button fires callback', (tester) async {
      var fired = false;
      await tester.pumpWidget(_wrap(onExportSvg: () => fired = true));

      await tester.tap(find.byTooltip('Export SVG'));
      await tester.pump();
      expect(fired, true);
    });
  });
}
