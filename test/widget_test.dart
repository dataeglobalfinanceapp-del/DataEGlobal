// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/main.dart';

void main() {
  testWidgets('App builds a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const SaveTepApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App delays startup focus until after first layout', (
    WidgetTester tester,
  ) async {
    const Key gateKey = Key('startup-focus-gate');

    await tester.pumpWidget(const SaveTepApp());

    FocusScope gate = tester.widget<FocusScope>(find.byKey(gateKey));
    expect(gate.canRequestFocus, isFalse);
    expect(gate.descendantsAreFocusable, isFalse);
    expect(gate.descendantsAreTraversable, isFalse);

    await tester.pump();

    gate = tester.widget<FocusScope>(find.byKey(gateKey));
    expect(gate.canRequestFocus, isTrue);
    expect(gate.descendantsAreFocusable, isTrue);
    expect(gate.descendantsAreTraversable, isTrue);

    final traversal = tester.widget<FocusTraversalGroup>(
      find
          .descendant(
            of: find.byKey(gateKey),
            matching: find.byType(FocusTraversalGroup),
          )
          .first,
    );

    expect(traversal.policy, isA<WidgetOrderTraversalPolicy>());
  });
}
