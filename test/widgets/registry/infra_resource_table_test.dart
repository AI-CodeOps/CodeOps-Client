// Tests for InfraResourceTable widget.
//
// Verifies column rendering, type icons, orphan warning,
// sort callback, and service name tap navigation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/registry_enums.dart';
import 'package:codeops/models/registry_models.dart';
import 'package:codeops/widgets/registry/infra_resource_table.dart';

const _resource1 = InfraResourceResponse(
  id: 'r-1',
  teamId: 'team-1',
  serviceId: 'svc-1',
  serviceName: 'CodeOps Server',
  resourceType: InfraResourceType.s3Bucket,
  resourceName: 'codeops-assets',
  environment: 'dev',
  region: 'us-east-1',
  arnOrUrl: 'arn:aws:s3:::codeops-assets',
);

const _resource2 = InfraResourceResponse(
  id: 'r-2',
  teamId: 'team-1',
  serviceId: null,
  serviceName: null,
  resourceType: InfraResourceType.sqsQueue,
  resourceName: 'dead-letter-q',
  environment: 'dev',
);

const _resource3 = InfraResourceResponse(
  id: 'r-3',
  teamId: 'team-1',
  serviceId: 'svc-2',
  serviceName: 'Registry',
  resourceType: InfraResourceType.cloudwatchLogGroup,
  resourceName: 'codeops-registry',
  environment: 'dev',
  region: 'us-east-1',
);

void _setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildTable({
  List<InfraResourceResponse> resources = const [
    _resource1,
    _resource2,
    _resource3,
  ],
  String sortField = 'name',
  bool sortAscending = true,
  void Function(String)? onSort,
  ValueChanged<InfraResourceResponse>? onEdit,
  ValueChanged<InfraResourceResponse>? onDelete,
  void Function(String)? onServiceTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: InfraResourceTable(
          resources: resources,
          sortField: sortField,
          sortAscending: sortAscending,
          onSort: onSort ?? (_) {},
          onEdit: onEdit,
          onDelete: onDelete,
          onServiceTap: onServiceTap,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InfraResourceTable', () {
    testWidgets('renders all columns', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildTable());
      await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Env'), findsOneWidget);
      expect(find.text('Region'), findsOneWidget);
      expect(find.text('ARN / URL'), findsOneWidget);
    });

    testWidgets('renders resource type icon', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildTable());
      await tester.pumpAndSettle();

      // S3 Bucket type display
      expect(find.text('S3 Bucket'), findsOneWidget);
      expect(find.text('SQS Queue'), findsOneWidget);
      expect(find.text('CloudWatch Log Group'), findsOneWidget);
    });

    testWidgets('renders orphan warning', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_buildTable());
      await tester.pumpAndSettle();

      // Orphan row should show "None" text
      expect(find.text('None'), findsOneWidget);
      // Warning icon for orphan
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('sort callback fires on header tap', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? sortedField;
      await tester.pumpWidget(_buildTable(
        onSort: (field) => sortedField = field,
      ));
      await tester.pumpAndSettle();

      // Tap the Name header
      await tester.tap(find.text('Name'));
      expect(sortedField, 'name');
    });

    testWidgets('service name clickable', (tester) async {
      _setWideViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? tappedServiceId;
      await tester.pumpWidget(_buildTable(
        onServiceTap: (id) => tappedServiceId = id,
      ));
      await tester.pumpAndSettle();

      // Tap the first service name
      await tester.tap(find.text('CodeOps Server'));
      expect(tappedServiceId, 'svc-1');
    });
  });
}
