# FinApp

A new Flutter project.

## Architecture

The app is being refactored toward a layered structure so screens do not know
where data comes from.

- `lib/data/repositories`: abstract persistence contracts.
- `lib/data/local`: LocalStore-backed repository implementations used today.
- `lib/data/remote`: AWS repository placeholders for a later backend switch.
- `lib/domain/services`: business workflows that depend on repositories.
- `lib/features`: Flutter screens, widgets, and controllers.

Current refactor step:

- Transaction and reminder persistence now goes through repository contracts.
- Transaction local storage and cached transaction lists are owned by
  `LocalTransactionRepository`; `LiabilityService` keeps the old static API as
  compatibility wrappers.
- Budget target persistence now goes through `BudgetTargetService`.
- UI code should not import `LocalStore`, JSON persistence, HTTP, AWS, API
  Gateway, DynamoDB, or Amplify directly.

## Local Mindee OCR testing

Expense and deposit scans call the Mindee V2 API directly in debug builds.
This is only for private local testing: a `--dart-define` value is visible in a
compiled application and is not suitable for production or a distributed APK.
Never commit the key, print it in logs, or include it in screenshots. Revoke the
test key when it is no longer needed.

Create separate Mindee extraction models for expenses and deposits. The expense
model must use these exact machine keys:

```text
supplier_name
date
time
total_amount
tips_gratuity
purchase_category
card_last4
```

Configure `purchase_category` with exactly these classification values:

```text
Energy
Loan Obligation
Payroll
Business licenses and permits
Food
Restaurant supplies
Advertising and promotion
software
pest control
Internet
Maintenance
Insurance
Rent
Office Supplies
Meal, entertainment
Automobile, Fuel
```

Connect an Android phone with USB debugging enabled, accept the computer's RSA
prompt, and confirm that Flutter can see it:

```powershell
flutter devices
```

Then start the app with temporary environment variables, replacing
`<ANDROID_DEVICE_ID>` with the ID shown by `flutter devices`:

```powershell
$env:MINDEE_V2_API_KEY = '<LOCAL_TEST_API_KEY>'
$env:MINDEE_EXPENSE_MODEL_ID = '<EXPENSE_MODEL_ID>'
$env:MINDEE_DEPOSIT_MODEL_ID = '<DEPOSIT_MODEL_ID>'

flutter run -d <ANDROID_DEVICE_ID> `
  --dart-define=MINDEE_V2_API_KEY=$env:MINDEE_V2_API_KEY `
  --dart-define=MINDEE_EXPENSE_MODEL_ID=$env:MINDEE_EXPENSE_MODEL_ID `
  --dart-define=MINDEE_DEPOSIT_MODEL_ID=$env:MINDEE_DEPOSIT_MODEL_ID
```

Amplify sandbox and Cognito setup are unchanged. No local OCR backend is needed
for this startup flow.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
