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
- Budget target persistence now goes through `BudgetTargetService`.
- UI code should not import `LocalStore`, JSON persistence, HTTP, AWS, API
  Gateway, DynamoDB, or Amplify directly.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
