# Project Agent Guide

Build this Flutter app with a feature-based structure and clear separation between UI, state, persistence, and business rules.

## Workflow

1. Plan the target feature or fix.
2. Code in small, scoped changes.
3. Validate with formatting, analyzer, and tests.
4. Iterate until errors and warnings are resolved.

## Flutter Standards

- Keep widgets small, reusable, responsive, and accessible.
- Keep async work, API calls, persistence, and business logic outside widget layout code.
- Prefer feature-local controllers, models, services, and widgets before adding shared abstractions.
- Use `ListView.builder` or other lazy builders for dynamic lists.
- Apply `const` to immutable widgets, styles, and values where possible.
- Use centralized styling tokens, app theme values, or shared component styles instead of scattering visual constants.
- Add tests for important business logic and widget behavior touched by a change.

## State Management: setState vs. Riverpod

**Use `setState`** for quick, transient UI state that does not impact other parts of the app or the network layer:
- Toggling a visibility switch or dark mode toggle on a single screen.
- Keeping track of the currently selected tab in a custom bottom navigation bar.
- Form validation, input handling, and active text selection fields.
- Custom animations controlled locally inside a `StatefulWidget`.

**Use Riverpod** when data needs to cross widget boundaries, scale across multiple pages, or sync with remote services:
- Authenticating users and sharing user profile data globally.
- Fetching API data with automated loading, error, and caching states.
- Managing cart inventories or user configurations shared across multiple screens.
- Combining multiple data models together through dependency injection.

## OOP & Architecture Rules

- Depend on interfaces/abstract classes (e.g. `TransactionQueryRepository`), not concrete implementations. Concrete classes (`LocalTransactionQueryRepository`, `AwsTransactionQueryRepository`) are injected, never hardcoded inside controllers or widgets.
- Each class has a single responsibility: controllers orchestrate state, repositories handle data access, services handle external calls (AWS, APIs), models are plain data holders.
- Favor composition over inheritance for widgets and controllers.
- No business logic inside widget `build()` methods — delegate to controllers/providers.

## Event-Driven Lifecycle Rules

- Every `initState` that subscribes, listens, or allocates must have a matching `dispose` that unsubscribes, cancels, or disposes (`AnimationController`, `StreamSubscription`, `TextEditingController`, `ScrollController`).
- Use scoped Riverpod providers with `autoDispose` for screen-local state; avoid global providers holding state no longer in use.
- Split `ListenableBuilder`/`Consumer` scopes tightly around the widget that actually needs to rebuild — never wrap large subtrees in a single listener (this caused the Payroll screen rebuild-storm bug).
- Avoid calling `notifyListeners()` or emitting state inside `build()` or synchronously during widget construction; only trigger from user events, lifecycle callbacks, or async completions.

## Critical Mobile Optimization Rules

- **Minimize allocation in hot paths**: never create new objects, closures, `TextStyle`s, `Decoration`s, or `List`s inside `build()`, `itemBuilder`, or any method called per-frame/per-item. Hoist to `static const` fields, class fields, or memoized values.
- **Cache & lazy-load**: cache API/repository responses (in-memory or local DB) to avoid redundant network calls; paginate list data with cursor-based fetching (as already used in `TransactionQueryRepository`); lazy-load images with `cached_network_image` or similar, not `Image.network` directly.
- **Flat, const widget trees**: use `const` constructors wherever possible; avoid deeply nested `Column`/`Row`/`Container` chains — extract to small const widgets instead. Use `RepaintBoundary` around widgets that repaint independently (charts, animations) to limit repaint scope.
- **Off-main-isolate work**: heavy JSON parsing, large local DB writes, or CPU-bound transforms go through `compute()`/isolates, not the UI isolate. Network and persistence calls are always `async` and awaited outside the widget tree.
- **Compress assets**: use WebP for raster images and appropriately sized/resolution-variant assets (`2.0x`, `3.0x`) instead of one oversized PNG for all densities.

## Validation

Run these before handing off a Flutter change:

```powershell
dart format .
flutter analyze
flutter test
```