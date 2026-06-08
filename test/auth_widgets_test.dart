import 'package:biztrack/features/auth/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthFocusTraversal enables focus after the first frame', (
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
    expect(traversal.descendantsAreFocusable, isFalse);
    expect(traversal.descendantsAreTraversable, isFalse);

    await tester.pump();

    traversal = tester.widget<FocusTraversalGroup>(authTraversal);
    expect(traversal.descendantsAreFocusable, isTrue);
    expect(traversal.descendantsAreTraversable, isTrue);
  });
}
