# Finance Feature Design

## Reminder Structure

- `reminder_screen.dart`: routes, dialogs, and screen-level event wiring.
- `reminder_controller.dart`: view state, loading, mutation orchestration, and data mapping.
- `reminder_models.dart`: feature view models, form data, date helpers, and design tokens.
- `reminder_widgets.dart`: presentational widgets only.
- `reminder_service.dart`: persistence, recurrence generation, edits, deletion, postponing, and serialization.

## Transaction Structure

- `transaction_screen.dart`: routes, dialogs, export prompts, and screen-level event wiring.
- `transaction_controller.dart`: loading, filtering, grouping, deletion, report payload orchestration, and view-state mapping.
- `transaction_models.dart`: feature view models, export range models, date helpers, and design tokens.
- `transaction_widgets.dart`: presentational widgets only.
- `liability_service.dart`: deposit and expense persistence used by the transaction controller.

## Reminder State Flow

1. `ReminderScreen` owns a `_ReminderController`.
2. `_ReminderController` calls `ReminderService` for async persistence work.
3. The controller maps records into `_ReminderViewState`.
4. Widgets render `_ReminderViewState` and emit typed callbacks.
5. Mutations reload reminders without exposing service details to widgets.

## Transaction State Flow

1. `TransactionScreen` owns a `_TransactionController`.
2. `_TransactionController` calls `LiabilityService` for async deposit and expense work.
3. The controller maps records into `_TransactionViewState`.
4. Widgets render `_TransactionViewState` and emit typed callbacks.
5. Delete and export actions stay in the controller/screen layer rather than widget layout code.

## Rendering

- The main reminder list uses `ListView.builder`.
- The create reminder form list uses `ListView.builder`.
- The transaction history list uses `ListView.builder`.
- Transaction rows use fixed table column widths and `FittedBox` for long amounts.
- Calendar cells use fixed dimensions to avoid layout shifts.
- `ListTile` cards are wrapped in `Material` so ink, background, and semantics render correctly above decorated containers.
- Expandable transaction group cards use their own `Material` layer so ink is visible above decorated surfaces.

## Testing

- Service tests reset `ReminderService` and `AppClock` for deterministic recurrence behavior.
- Tests cover monthly generation, single occurrence deletion, series amount edits, and postponing recurring reminders.
- Transaction widget tests reset `LiabilityService` and `AppClock` for deterministic screen behavior.
- Tests cover seeded transaction totals, export actions, group expansion, and deposit deletion.
