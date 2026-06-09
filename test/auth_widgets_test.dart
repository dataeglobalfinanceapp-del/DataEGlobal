import 'package:biztrack/features/auth/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthFocusTraversal uses widget order without a timing gate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AuthFocusTraversal(child: TextField())),
      ),
    );

    final authTraversal = find.descendant(
      of: find.byType(AuthFocusTraversal),
      matching: find.byType(FocusTraversalGroup),
    );

    var traversal = tester.widget<FocusTraversalGroup>(authTraversal);
    expect(traversal.policy, isA<WidgetOrderTraversalPolicy>());
    expect(traversal.descendantsAreFocusable, isTrue);
    expect(traversal.descendantsAreTraversable, isTrue);

    await tester.pump();

    traversal = tester.widget<FocusTraversalGroup>(authTraversal);
    expect(traversal.policy, isA<WidgetOrderTraversalPolicy>());
    expect(traversal.descendantsAreFocusable, isTrue);
    expect(traversal.descendantsAreTraversable, isTrue);
  });
}
