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

## Validation

Run these before handing off a Flutter change:

```powershell
dart format .
flutter analyze
flutter test
```
