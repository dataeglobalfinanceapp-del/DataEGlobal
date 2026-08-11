import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/core/customer_service_contact.dart';
import 'package:savetep/features/auth/models/account_profile.dart';
import 'package:savetep/features/auth/screens/home_screen/home_screen.dart';
import 'package:savetep/features/auth/screens/user_setting/user_setting_screens.dart';
import 'package:savetep/features/auth/services/account_profile_service.dart';
import 'package:savetep/features/auth/widgets/business_name_prompt_dialog.dart';
import 'package:savetep/providers/account_profile_provider.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';

void main() {
  setUp(() {
    AppClock.set(DateTime(2026, 6, 15));
    LiabilityService.resetForTesting();
  });

  tearDown(() {
    AppClock.reset();
    LiabilityService.resetForTesting(disablePersistence: false);
  });

  testWidgets('HomeScreen uses a responsive iPhone action layout', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SaveTep'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Profit &\nLoss'), findsOneWidget);
    expect(find.text('Investments'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('TRANSACTION'), findsNothing);
    expect(_actionGridDelegate(tester).crossAxisCount, 4);
    _expectFeatureCardsHaveEqualSize(tester, <String>[
      'Deposit',
      'Expense',
      'Transactions',
      'Goal',
      'Shopping',
    ]);
    _expectBudgetCardsAlignedWithDateRange(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Home header shows profile, service, Account, and the app logo', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(
      tester,
      profile: const AccountProfile(
        fullName: 'Sunny Nguyen',
        businessName: 'Sunny Nails',
        businessNameOnboardingCompleted: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home.appLogo')), findsOneWidget);
    expect(find.text('Sunny Nails'), findsOneWidget);
    expect(find.byTooltip('Customer Service'), findsOneWidget);
    expect(find.byTooltip('Account'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsNothing);

    final customerServiceRect = tester.getRect(
      find.byTooltip('Customer Service'),
    );
    final accountRect = tester.getRect(find.byTooltip('Account'));
    expect(customerServiceRect.right, lessThanOrEqualTo(accountRect.left));

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('home.businessDisplayName')),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(
      tester
          .getCenter(find.byKey(const ValueKey('home.businessDisplayName')))
          .dx,
      moreOrLessEquals(tester.view.physicalSize.width / 2),
    );

    await tester.tap(find.byTooltip('Customer Service'));
    await tester.pumpAndSettle();
    expect(find.text(CustomerServiceContact.displayPhone), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Account Settings'), findsOneWidget);
  });

  testWidgets('Home immediately reflects a business name saved in Settings', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeAccountProfileRepository(
      const AccountProfile(
        fullName: 'Sunny Nguyen',
        businessNameOnboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/user-settings': (_) => const UserSettingsScreen(),
            '/user-settings/business-management': (_) =>
                const BusinessManagementScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sunny Nguyen'), findsOneWidget);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Business Management'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('accountSettings.businessNameField')),
      'Sunny Nails',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(repository.profile.businessName, 'Sunny Nails');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Sunny Nails'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('skipping fallback onboarding completes it once', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHomeScreen(
      tester,
      profile: const AccountProfile(
        fullName: 'Sunny Nguyen',
        businessNameOnboardingCompleted: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BusinessNamePromptDialog), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(BusinessNamePromptDialog), findsNothing);

    await tester.pump();
    expect(find.byType(BusinessNamePromptDialog), findsNothing);
    expect(find.text('Sunny Nguyen'), findsOneWidget);
  });

  testWidgets('HomeScreen lets an expanded budget editor grow in the page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(426.7, 796);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const categories = <String>[
      'Payroll',
      'Rent',
      'gas',
      'electric',
      'Insurance',
      'Shopping',
      'professional fees',
      'Other',
    ];
    for (var index = 0; index < categories.length; index++) {
      await LiabilityService.saveExpense(
        checkNumber: 'EDIT-$index',
        totalAmount: 10 + index.toDouble(),
        transactionDate: DateTime(2026, 6, 14),
        category: categories[index],
        payee: categories[index],
        isManual: true,
      );
    }

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Edit targets'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextFormField), findsNWidgets(categories.length));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('HomeScreen shows estimated tax at year end in balance summary', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LiabilityService.saveDeposit(
      orderNumber: 'A100',
      totalAmount: 125,
      creditDeposit: 100,
      cash: 25,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 6, 12),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'E200',
      totalAmount: 45,
      transactionDate: DateTime(2026, 6, 13),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final summaryCard = find.byKey(const ValueKey('home.totalBalanceCard'));
    expect(
      find.descendant(of: summaryCard, matching: find.text('TOTAL BALANCE')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: summaryCard,
        matching: find.text('ESTIMATED TAX AT YEAR END'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text(r'$80.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text(r'$8.00')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('HomeScreen month selector filters a selected month', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 7, 15));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LiabilityService.saveDeposit(
      orderNumber: 'MAY-1',
      totalAmount: 300,
      creditDeposit: 300,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 5, 7, 14),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'MAY-E',
      totalAmount: 70,
      transactionDate: DateTime(2026, 5, 8, 9),
      category: 'gas',
      payee: 'Gas Stop',
      isManual: true,
    );
    await LiabilityService.saveDeposit(
      orderNumber: 'JUL-1',
      totalAmount: 900,
      creditDeposit: 900,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 7, 5),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'JUL-E',
      totalAmount: 400,
      transactionDate: DateTime(2026, 7, 6),
      category: 'professional fees',
      payee: 'professional fees',
      isManual: true,
    );

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(find.text('January'), findsOneWidget);
    expect(find.text('July'), findsWidgets);
    expect(find.text('August'), findsNothing);

    await tester.tap(find.text('May'));
    await tester.pumpAndSettle();

    final dateRangeCard = find.byKey(const ValueKey('home.dateRangeCard'));
    final summaryCard = find.byKey(const ValueKey('home.totalBalanceCard'));
    expect(
      find.descendant(of: dateRangeCard, matching: find.text('05/01 - 05/31')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text(r'$230.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text(r'$300.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text(r'$70.00')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('HomeScreen quarter selector filters a selected quarter', (
    WidgetTester tester,
  ) async {
    AppClock.set(DateTime(2026, 7, 15));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LiabilityService.saveDeposit(
      orderNumber: 'Q2-1',
      totalAmount: 500,
      creditDeposit: 500,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 4, 10),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'Q2-E',
      totalAmount: 120,
      transactionDate: DateTime(2026, 6, 20, 18),
      category: 'Rent',
      payee: 'Studio Rent',
      isManual: true,
    );
    await LiabilityService.saveDeposit(
      orderNumber: 'Q3-1',
      totalAmount: 900,
      creditDeposit: 900,
      cash: 0,
      giftCard: 0,
      other: 0,
      transactionDate: DateTime(2026, 7, 10),
      isManual: true,
    );
    await LiabilityService.saveExpense(
      checkNumber: 'Q3-E',
      totalAmount: 300,
      transactionDate: DateTime(2026, 7, 11),
      category: 'electric',
      payee: 'Power Co',
      isManual: true,
    );

    await _pumpHomeScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('3 Months'));
    await tester.pumpAndSettle();

    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('Q2'), findsOneWidget);
    expect(find.text('Q3'), findsWidgets);
    expect(find.text('Q4'), findsNothing);

    await tester.tap(find.text('Q2'));
    await tester.pumpAndSettle();

    final dateRangeCard = find.byKey(const ValueKey('home.dateRangeCard'));
    final summaryCard = find.byKey(const ValueKey('home.totalBalanceCard'));
    expect(
      find.descendant(of: dateRangeCard, matching: find.text('04/01 - 06/30')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text(r'$380.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text(r'$500.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summaryCard, matching: find.text(r'$120.00')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('HomeScreen action grid follows responsive breakpoints', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const cases = <_GridBreakpointCase>[
      _GridBreakpointCase(Size(350, 780), 3),
      _GridBreakpointCase(Size(768, 1024), 5),
      _GridBreakpointCase(Size(920, 1024), 6),
    ];

    for (final testCase in cases) {
      tester.view.physicalSize = testCase.size;
      await _pumpHomeScreen(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '${testCase.size}');
      expect(_actionGridDelegate(tester).crossAxisCount, testCase.columns);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

Future<void> _pumpHomeScreen(
  WidgetTester tester, {
  AccountProfile profile = const AccountProfile(
    businessNameOnboardingCompleted: true,
  ),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountProfileRepositoryProvider.overrideWithValue(
          _FakeAccountProfileRepository(profile),
        ),
      ],
      child: MaterialApp(
        home: const HomeScreen(),
        routes: {
          '/user-settings': (_) =>
              const Scaffold(body: Center(child: Text('Account Settings'))),
        },
      ),
    ),
  );
}

class _FakeAccountProfileRepository implements AccountProfileRepository {
  AccountProfile profile;

  _FakeAccountProfileRepository(this.profile);

  @override
  Future<AccountProfile> load() async => profile;

  @override
  Future<void> save(AccountProfile profile) async {
    this.profile = profile;
  }
}

class _GridBreakpointCase {
  final Size size;
  final int columns;

  const _GridBreakpointCase(this.size, this.columns);
}

SliverGridDelegateWithFixedCrossAxisCount _actionGridDelegate(
  WidgetTester tester,
) {
  final GridView grid = tester.widget<GridView>(find.byType(GridView));
  return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
}

void _expectBudgetCardsAlignedWithDateRange(WidgetTester tester) {
  final dateRangeRect = tester.getRect(
    find.byKey(const ValueKey('home.dateRangeCard')),
  );
  final totalBalanceRect = tester.getRect(
    find.byKey(const ValueKey('home.totalBalanceCard')),
  );
  final overviewRect = tester.getRect(
    find.byKey(const ValueKey('home.overviewCard')),
  );

  for (final cardRect in <Rect>[totalBalanceRect, overviewRect]) {
    expect(cardRect.left, moreOrLessEquals(dateRangeRect.left));
    expect(cardRect.right, moreOrLessEquals(dateRangeRect.right));
    expect(cardRect.width, moreOrLessEquals(dateRangeRect.width));
  }
}

void _expectFeatureCardsHaveEqualSize(
  WidgetTester tester,
  List<String> labels,
) {
  final grid = find.byType(GridView);
  final cardSizes = labels.map((String label) {
    final card = find.descendant(
      of: grid,
      matching: find.ancestor(
        of: find.text(label),
        matching: find.byType(Container),
      ),
    );
    return tester.getSize(card.first);
  }).toList();

  for (final size in cardSizes.skip(1)) {
    expect(size, cardSizes.first);
  }
}
