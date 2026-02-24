// Widget tests for VaultSecretDetailPage (CVF-003).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/models/vault_enums.dart';
import 'package:codeops/models/vault_models.dart';
import 'package:codeops/pages/vault_secret_detail_page.dart';
import 'package:codeops/providers/vault_providers.dart';
import 'package:codeops/theme/app_theme.dart';

void main() {
  final testSecret = SecretResponse(
    id: 's1',
    teamId: 't1',
    path: '/services/app/db-password',
    name: 'db-password',
    description: 'Database password for prod',
    secretType: SecretType.static_,
    currentVersion: 3,
    maxVersions: 10,
    retentionDays: 90,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    lastAccessedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  final testVersions = PageResponse<SecretVersionResponse>(
    content: [
      SecretVersionResponse(
        id: 'v3',
        secretId: 's1',
        versionNumber: 3,
        changeDescription: 'Updated password',
        isDestroyed: false,
        createdAt: DateTime(2026, 2, 20),
      ),
      SecretVersionResponse(
        id: 'v2',
        secretId: 's1',
        versionNumber: 2,
        changeDescription: 'Rotated',
        isDestroyed: false,
        createdAt: DateTime(2026, 2, 10),
      ),
      SecretVersionResponse(
        id: 'v1',
        secretId: 's1',
        versionNumber: 1,
        changeDescription: 'Initial version',
        isDestroyed: true,
        createdAt: DateTime(2026, 1, 1),
      ),
    ],
    page: 0,
    size: 20,
    totalElements: 3,
    totalPages: 1,
    isLast: true,
  );

  final testMetadata = <String, String>{
    'environment': 'production',
    'owner': 'team-alpha',
  };

  Widget createWidget({
    SecretResponse? secret,
    PageResponse<SecretVersionResponse>? versions,
    Map<String, String>? metadata,
  }) {
    return ProviderScope(
      overrides: [
        vaultSecretDetailProvider('s1').overrideWith(
          (ref) => Future.value(secret ?? testSecret),
        ),
        vaultSecretVersionsProvider('s1').overrideWith(
          (ref) => Future.value(versions ?? testVersions),
        ),
        vaultSecretMetadataProvider('s1').overrideWith(
          (ref) => Future.value(metadata ?? testMetadata),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: VaultSecretDetailPage(secretId: 's1'),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Page-level tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultSecretDetailPage', () {
    testWidgets('shows secret name in header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('db-password'), findsOneWidget);
    });

    testWidgets('shows secret path in header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('/services/app/db-password'), findsOneWidget);
    });

    testWidgets('shows version number in header', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('v3'), findsOneWidget);
    });

    testWidgets('shows type badge', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Static'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows four tabs', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Versions'), findsOneWidget);
      expect(find.text('Metadata'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows actions dropdown', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      final completer = Completer<SecretResponse>();
      final widget = ProviderScope(
        overrides: [
          vaultSecretDetailProvider('s1').overrideWith(
            (ref) => completer.future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: VaultSecretDetailPage(secretId: 's1'),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(testSecret);
      await tester.pumpAndSettle();
    });

    testWidgets('actions dropdown shows menu items on tap', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit Secret'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Copy Path'), findsOneWidget);
      expect(find.text('Copy Secret Value'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Value tab tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultSecretDetailPage — Value tab', () {
    testWidgets('shows hidden state by default', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Secret value is hidden'), findsOneWidget);
      expect(find.text('Reveal Secret'), findsOneWidget);
    });

    testWidgets('shows auto-hide message', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Value will auto-hide after 30 seconds'),
        findsOneWidget,
      );
    });

    testWidgets('shows visibility off icon when hidden', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Versions tab tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultSecretDetailPage — Versions tab', () {
    testWidgets('shows version list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to Versions tab.
      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      // v3 appears in header and version list; v2 and v1 are list-only.
      expect(find.text('v3'), findsWidgets);
      expect(find.text('v2'), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
    });

    testWidgets('shows version descriptions', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      expect(find.text('Updated password'), findsOneWidget);
      expect(find.text('Rotated'), findsOneWidget);
      expect(find.text('Initial version'), findsOneWidget);
    });

    testWidgets('shows destroyed badge for destroyed version', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      expect(find.text('Destroyed'), findsOneWidget);
    });

    testWidgets('shows checkboxes for non-destroyed versions', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      // v3 and v2 are not destroyed, so they have checkboxes; v1 is destroyed.
      expect(find.byType(Checkbox), findsNWidgets(2));
    });

    testWidgets('shows restore icon for non-destroyed versions',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.restore), findsNWidgets(2));
    });

    testWidgets('shows empty state when no versions', (tester) async {
      await tester.pumpWidget(createWidget(
        versions: PageResponse<SecretVersionResponse>.empty(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      expect(find.text('No versions'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Metadata tab tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultSecretDetailPage — Metadata tab', () {
    testWidgets('shows metadata entries', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Metadata'));
      await tester.pumpAndSettle();

      expect(find.text('environment'), findsOneWidget);
      expect(find.text('production'), findsOneWidget);
      expect(find.text('owner'), findsOneWidget);
      expect(find.text('team-alpha'), findsOneWidget);
    });

    testWidgets('shows add entry fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Metadata'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Key'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Value'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows edit and delete icons for each entry', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Metadata'));
      await tester.pumpAndSettle();

      // 2 entries, each with edit and close icons.
      expect(find.byIcon(Icons.edit), findsNWidgets(2));
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets('shows Remove All button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Metadata'));
      await tester.pumpAndSettle();

      expect(find.text('Remove All'), findsOneWidget);
    });

    testWidgets('shows empty state when no metadata', (tester) async {
      await tester.pumpWidget(createWidget(metadata: {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Metadata'));
      await tester.pumpAndSettle();

      expect(find.text('No metadata entries'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Settings tab tests
  // ─────────────────────────────────────────────────────────────────────────

  group('VaultSecretDetailPage — Settings tab', () {
    testWidgets('shows read-only fields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('db-password'), findsWidgets);
      expect(find.text('/services/app/db-password'), findsWidgets);
    });

    testWidgets('shows description field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Database password for prod'), findsOneWidget);
    });

    testWidgets('shows max versions field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Max Versions'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows retention field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Retention (days)'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);
    });

    testWidgets('shows expiry date picker', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Expiry Date'), findsOneWidget);
      expect(find.text('No expiry set'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Save Settings'), findsOneWidget);
    });
  });
}
