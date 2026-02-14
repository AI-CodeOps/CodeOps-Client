// Widget tests for ErrorPanel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/services/cloud/api_exceptions.dart';
import 'package:codeops/widgets/shared/error_panel.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ErrorPanel', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(wrap(
        const ErrorPanel(title: 'Oops', message: 'Something broke'),
      ));

      expect(find.text('Oops'), findsOneWidget);
      expect(find.text('Something broke'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(wrap(
        ErrorPanel(title: 'Error', message: 'msg', onRetry: () {}),
      ));

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(wrap(
        const ErrorPanel(title: 'Error', message: 'msg'),
      ));

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('retry button invokes callback', (tester) async {
      var called = false;
      await tester.pumpWidget(wrap(
        ErrorPanel(title: 'Error', message: 'msg', onRetry: () => called = true),
      ));

      await tester.tap(find.text('Retry'));
      expect(called, isTrue);
    });

    testWidgets('fromException maps NetworkException', (tester) async {
      await tester.pumpWidget(wrap(
        ErrorPanel.fromException(const NetworkException('offline')),
      ));

      expect(find.text('No Internet'), findsOneWidget);
    });

    testWidgets('fromException maps TimeoutException', (tester) async {
      await tester.pumpWidget(wrap(
        ErrorPanel.fromException(const TimeoutException('slow')),
      ));

      expect(find.text('Request Timed Out'), findsOneWidget);
    });

    testWidgets('fromException maps ServerException', (tester) async {
      await tester.pumpWidget(wrap(
        ErrorPanel.fromException(const ServerException('error', statusCode: 500)),
      ));

      expect(find.text('Server Error'), findsOneWidget);
    });

    testWidgets('fromException maps UnauthorizedException', (tester) async {
      await tester.pumpWidget(wrap(
        ErrorPanel.fromException(const UnauthorizedException('expired')),
      ));

      expect(find.text('Session Expired'), findsOneWidget);
    });

    testWidgets('fromException maps ForbiddenException', (tester) async {
      await tester.pumpWidget(wrap(
        ErrorPanel.fromException(const ForbiddenException('denied')),
      ));

      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('fromException maps unknown error', (tester) async {
      await tester.pumpWidget(wrap(
        ErrorPanel.fromException(Exception('unknown')),
      ));

      expect(find.text('Something Went Wrong'), findsOneWidget);
    });
  });
}
