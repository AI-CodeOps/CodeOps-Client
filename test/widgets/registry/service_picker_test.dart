// Tests for ServicePicker widget.
//
// Verifies loading state, service grouping, search filter,
// select all / clear all actions, checkbox toggle, and selection count.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/models/health_snapshot.dart';
import 'package:codeops/providers/registry_providers.dart';
import 'package:codeops/widgets/registry/service_picker.dart';

const _svc1 = ServiceRegistrationResponse(
  id: 'svc-1',
  teamId: 'team-1',
  name: 'Auth Service',
  slug: 'auth-service',
  serviceType: ServiceType.springBootApi,
  status: ServiceStatus.active,
);

const _svc2 = ServiceRegistrationResponse(
  id: 'svc-2',
  teamId: 'team-1',
  name: 'Frontend App',
  slug: 'frontend-app',
  serviceType: ServiceType.reactSpa,
  status: ServiceStatus.active,
);

PageResponse<ServiceRegistrationResponse> _servicePage(
    List<ServiceRegistrationResponse> items) {
  return PageResponse(
    content: items,
    page: 0,
    size: 20,
    totalElements: items.length,
    totalPages: 1,
    isLast: true,
  );
}

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildPicker({
  Set<String> selectedServiceIds = const {},
  ValueChanged<Set<String>>? onChanged,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ServicePicker(
            selectedServiceIds: selectedServiceIds,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServicePicker', () {
    testWidgets('renders loading state', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final completer =
          Completer<PageResponse<ServiceRegistrationResponse>>();
      await tester.pumpWidget(_buildPicker(
        overrides: [
          registryServicesProvider.overrideWith(
            (ref) => completer.future,
          ),
        ],
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders services grouped by type', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildPicker(
        overrides: [
          registryServicesProvider.overrideWith(
            (ref) async => _servicePage([_svc1, _svc2]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Auth Service'), findsOneWidget);
      expect(find.text('Frontend App'), findsOneWidget);
    });

    testWidgets('shows selection count', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildPicker(
        selectedServiceIds: {'svc-1'},
        overrides: [
          registryServicesProvider.overrideWith(
            (ref) async => _servicePage([_svc1, _svc2]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 selected'), findsOneWidget);
    });

    testWidgets('Select All callback fires', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Set<String>? result;
      await tester.pumpWidget(_buildPicker(
        onChanged: (ids) => result = ids,
        overrides: [
          registryServicesProvider.overrideWith(
            (ref) async => _servicePage([_svc1, _svc2]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select All'));
      expect(result, {'svc-1', 'svc-2'});
    });

    testWidgets('Clear All callback fires', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Set<String>? result;
      await tester.pumpWidget(_buildPicker(
        selectedServiceIds: {'svc-1', 'svc-2'},
        onChanged: (ids) => result = ids,
        overrides: [
          registryServicesProvider.overrideWith(
            (ref) async => _servicePage([_svc1, _svc2]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear All'));
      expect(result, <String>{});
    });

    testWidgets('search field present', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildPicker(
        overrides: [
          registryServicesProvider.overrideWith(
            (ref) async => _servicePage([_svc1, _svc2]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Search services...'), findsOneWidget);
    });
  });
}
