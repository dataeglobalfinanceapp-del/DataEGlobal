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

For the complete Cognito, Mindee, validation, Android launch, scan verification,
and shutdown procedure, use
[ANDROID_AWS_COGNITO_MINDEE_TESTING_GUIDE.md](ANDROID_AWS_COGNITO_MINDEE_TESTING_GUIDE.md).
It is the single source of truth for local Android testing.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
