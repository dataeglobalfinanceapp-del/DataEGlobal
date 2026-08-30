import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/widgets/bottom_nav_bar.dart';

void main() {
  test('Profit and Loss route uses the report navigation item', () {
    expect(bottomNavItemForRouteName('/profit-loss'), AppBottomNavItem.report);
  });

  testWidgets('AppBottomNavigationBar routes to selected destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/home',
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => const Scaffold(
            body: Text('Home destination'),
            bottomNavigationBar: AppBottomNavigationBar(
              currentItem: AppBottomNavItem.home,
            ),
          ),
          '/reminders': (BuildContext context) =>
              const Scaffold(body: Text('Reminder destination')),
        },
      ),
    );

    expect(find.text('Home destination'), findsOneWidget);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('Reminder destination'), findsOneWidget);
    expect(find.text('Home destination'), findsNothing);
  });
}
