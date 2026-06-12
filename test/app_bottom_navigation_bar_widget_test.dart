import 'package:biztrack/features/auth/widgets/app_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
