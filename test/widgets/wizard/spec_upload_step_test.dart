import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/providers/wizard_providers.dart';
import 'package:codeops/widgets/wizard/spec_upload_step.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 800, child: child),
        ),
      );

  group('SpecUploadStep', () {
    testWidgets('shows title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SpecUploadStep(
          files: const [],
          onFilesAdded: (_) {},
          onFileRemoved: (_) {},
        ),
      ));

      expect(find.text('Upload Specifications'), findsOneWidget);
    });

    testWidgets('shows drop zone text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SpecUploadStep(
          files: const [],
          onFilesAdded: (_) {},
          onFileRemoved: (_) {},
        ),
      ));

      expect(find.text('Drag & drop files here'), findsOneWidget);
      expect(find.text('or browse files'), findsOneWidget);
    });

    testWidgets('shows empty state when no files', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(
        SpecUploadStep(
          files: const [],
          onFilesAdded: (_) {},
          onFileRemoved: (_) {},
        ),
      ));

      expect(find.text('No files uploaded yet'), findsOneWidget);
    });

    testWidgets('shows file count and file names when files present',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final files = [
        const SpecFile(
          name: 'spec.md',
          path: '/tmp/spec.md',
          sizeBytes: 1024,
          contentType: 'text/markdown',
        ),
        const SpecFile(
          name: 'schema.json',
          path: '/tmp/schema.json',
          sizeBytes: 2048,
          contentType: 'application/json',
        ),
      ];

      await tester.pumpWidget(wrap(
        SpecUploadStep(
          files: files,
          onFilesAdded: (_) {},
          onFileRemoved: (_) {},
        ),
      ));

      expect(find.text('2 file(s) attached'), findsOneWidget);
      expect(find.text('spec.md'), findsOneWidget);
      expect(find.text('schema.json'), findsOneWidget);
    });

    testWidgets('fires onFileRemoved when close icon tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int? removedIndex;
      final files = [
        const SpecFile(
          name: 'spec.md',
          path: '/tmp/spec.md',
          sizeBytes: 1024,
          contentType: 'text/markdown',
        ),
      ];

      await tester.pumpWidget(wrap(
        SpecUploadStep(
          files: files,
          onFilesAdded: (_) {},
          onFileRemoved: (i) => removedIndex = i,
        ),
      ));

      await tester.tap(find.byIcon(Icons.close));
      expect(removedIndex, 0);
    });
  });
}
