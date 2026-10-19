import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:final_project/ui/core/widgets.dart';

Future<Completer<bool?>> _openDialog(WidgetTester tester) async {
  final done = Completer<bool?>();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (c) => FilledButton(
          onPressed: () async {
            done.complete(
                await confirmCancelRegistration(c, eventName: 'Quiz'));
          },
          child: const Text('Go'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Go'));
  await tester.pumpAndSettle();
  expect(find.text('Cancel Registration?'), findsOneWidget);
  return done;
}

void main() {
  testWidgets('Keep returns false and dismisses', (tester) async {
    final done = await _openDialog(tester);
    await tester.tap(find.text('Keep Registration'));
    await tester.pumpAndSettle();
    expect(await done.future, isFalse);
  });

  testWidgets('Cancel Registration returns true', (tester) async {
    final done = await _openDialog(tester);
    await tester.tap(find.text('Cancel Registration'));
    await tester.pumpAndSettle();
    expect(await done.future, isTrue);
  });
}
