# Flutter to SaveTep AWS/API Integration Plan

## Purpose and planning boundary

This document plans the migration of SaveTep's Flutter data layer to the deployed SaveTep DEV API. It does not authorize a broad implementation or an AWS resource change.

Contract and infrastructure inspection was performed on September 5, 2026 against:

- [SaveTep DEV Swagger](https://api-dev.save-tep.us/docs)
- API base URL: `https://api-dev.save-tep.us`
- AWS Region: `ap-southeast-1` (Singapore)
- OpenAPI version `3.0.0`, API version `1`
- 187 paths and 250 HTTP operations

The deployed API, its load balancer, its Cognito User Pool, and its application client are all in Singapore. The Flutter application is not yet configured to use them.

## Executive recommendation

Implement the integration behind the repository interfaces already present in the project, one feature at a time. Start with environment configuration, Singapore Cognito, `GET /me`, active-business resolution, and one shared authenticated HTTP client. Do not migrate transaction features until the category contract, list response schemas, and Mindee image-linking flow are resolved.

The intended request flow is:

```text
Flutter widget
  -> Riverpod provider or feature controller
  -> feature repository interface
  -> feature API repository
  -> shared ApiClient
  -> SaveTep DEV API
  -> AWS backend/database
```

Receipt extraction remains separate:

```text
Flutter -> Mindee V2 -> user review/edit
Flutter -> SaveTep API -> persisted record and image relationship
```

Do not add Textract to the Flutter application and do not treat Mindee as the system of record.

## Current frontend architecture

### Application and state

- `lib/main.dart` initializes `AmplifyAuthCognito`, configures Amplify from `lib/amplify_outputs.dart`, and creates the root `ProviderScope`.
- Authentication, account profile, business profile, expense categories, and Mindee clients use Riverpod providers.
- Several mature features use feature-local `ChangeNotifier` controllers instead of Riverpod notifiers. Preserve those boundaries during the first migration rather than rewriting state management at the same time.
- Screens generally delegate data work to controllers, repositories, or services. The main exceptions are compatibility calls into static services such as `LiabilityService`, `ReminderService`, and `PayrollService`.

### Persistence in use today

`LocalStore` writes JSON files under the application-support directory on native platforms and uses browser `localStorage` on web.

| Area | Current source of truth | Current implementation |
|---|---|---|
| Cognito session | Cognito in `us-west-2` | Amplify Auth; secure token storage/refresh handled by Amplify |
| Account display profile | LocalStore, keyed by Cognito user ID | `AccountProfileService` |
| Business profile/onboarding | LocalStore, keyed by Cognito user ID | `BusinessProfileService` |
| Selected expense categories | LocalStore, keyed by Cognito user ID | `ExpenseCategoryService` |
| Deposits, expenses, liabilities | LocalStore snapshot `savetep_local_data_v1` | `LocalTransactionRepository` through `LiabilityService` |
| Transaction queries/exports | In-memory filtering of the local snapshot | `LocalTransactionQueryRepository` |
| Home/budget calculations | Local transactions plus local target percentages | `LiabilityService`, `BudgetTargetService` |
| Saving target | Local deposits plus controller state | Saving rate and saved amounts are not persisted; `_dailySavedAmounts` is memory-only |
| Employees | LocalStore snapshot `savetep_employee_data_v1` | `LocalEmployeeRepository` |
| Payroll | Static in-memory cache backed by LocalStore `savetep_payroll_data_v1` | `PayrollService` |
| Reminders | Static in-memory cache backed by LocalStore `savetep_reminders_v1` | `ReminderService` |
| Profit & Loss | Recalculated from local deposits, expenses, and selected categories | `LiabilityProfitLossRepository` and `ProfitLossReportService` |
| Mindee extraction | Direct HTTPS calls in debug builds | `MindeeDocumentAnalysisService` |

### Existing migration seams

- `TransactionRepository`, `TransactionQueryRepository`, `EmployeeRepository`, `ReminderRepository`, and `BudgetTargetRepository` already isolate persistence.
- `AwsTransactionRepository`, `AwsTransactionQueryRepository`, `AwsEmployeeRepository`, and `AwsReminderRepository` are placeholders, not working API integrations.
- `AwsApiClient` only exposes unimplemented key/value `read` and `write` methods. Its contract must become HTTP-oriented; the SaveTep API is resource-oriented and is not a remote key/value store.
- `TransactionScreen` explicitly constructs `LocalTransactionQueryRepository` and deletes through `LiabilityService`, so repository replacement alone will not fully migrate that screen.
- `amplify_api` is installed but the app only registers the Cognito Auth plugin. The target is a REST API, so a small shared client using the existing `http` package is sufficient; adding Amplify API is not required.

## Target architecture

### Shared infrastructure

Add these small, intentionally shared contracts under `lib/core`:

- `AppEnvironment`: validated non-secret values for environment name, API URL, AWS Region, Cognito pool/client, and terms version.
- `AccessTokenProvider`: obtains the current Cognito access token through the Amplify Cognito plugin. It must not cache or persist tokens independently of Amplify.
- `ApiClient`: owns URI construction, JSON encoding/decoding, timeouts, the `Authorization` header, safe logging, and HTTP error translation.
- `ApiException`: typed transport/HTTP failures with status, safe message, optional error code, and retry metadata.
- `BusinessContextRepository`: resolves and caches only the current active `businessId`; it invalidates on sign-out or active-business change.

Keep resource DTOs feature-local. For example, expense request/response DTOs belong with the expense data layer, not in a generic global models directory.

### Repository ownership

Implement feature repositories that map verified API DTOs to the existing UI/domain models. Avoid direct HTTP calls in widgets, controllers, `LiabilityService`, or report calculators.

Recommended structure:

```text
lib/
  core/
    config/
    api/
      api_client.dart
      api_exception.dart
      access_token_provider.dart
  features/
    business/
      data/dto/
      data/business_api_repository.dart
      domain/business_repository.dart
    transactions/
      data/dto/
      data/income_api_repository.dart
      data/expense_api_repository.dart
    ...
```

Do not move every existing file before integration. New API code can initially sit beside the existing feature contracts, and stable boundaries can be consolidated after the cutover.

## AWS Singapore and Cognito

### Verified target configuration

The existing Singapore resources are:

- User Pool: `save-tep-dev`
- User Pool ID: `ap-southeast-1_3ob6DVAln`
- Mobile app client ID: `2dkdkbefs65ipd52egvfve23gu`
- Issuer: `https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_3ob6DVAln`
- API token requirement: Cognito access token (`token_use=access`)
- Access/ID token lifetime: 15 minutes
- Refresh token lifetime: 30 days
- Identity Pool: none in `ap-southeast-1`
- Named development user: `demo-owner` exists, is enabled, and is confirmed

The pool is managed by OpenTofu, not by the `amplify/` backend definition in this repository. Do not run an Amplify sandbox deployment as a way to switch the mobile client.

### Current configuration mismatch

- `lib/amplify_outputs.dart`, which the app actually imports, points to `us-west-2`.
- The root `amplify_outputs.json` also points to `us-west-2`, but to a different User Pool and client than the Dart file.
- `amplify/backend.ts` currently defines another Amplify-managed auth resource and disables self-registration.
- The Singapore pool uses usernames with email as an alias, allows self-registration, and has optional MFA. The current login form accepts only email-shaped input, so it rejects `demo-owner` before Cognito is called.

### Migration rules

1. Preserve the working `us-west-2` configuration and pool until Singapore sign-in and API calls pass end-to-end tests.
2. Configure Amplify Auth against the existing Singapore User Pool and mobile client; do not create a replacement pool.
3. Do not add an Identity Pool merely to call the SaveTep API. The REST API uses a User Pool access token, and file uploads use API-issued presigned URLs.
4. Change login terminology and validation to accept username or email. Keep sign-up email-based unless product/backend owners decide otherwise.
5. Handle optional MFA and other multi-step `AuthSignInStep` results instead of assuming `result.isSignedIn` is the only successful next state.
6. Expect all users to be signed out when the app changes pools. Cognito passwords and `sub` values do not migrate automatically.
7. Plan explicit account/business/category data reconciliation for old Cognito subjects. Never key server data by a display email.
8. Keep both pool configurations available through a reversible environment switch until acceptance is complete. Do not delete either pool as part of this Flutter task.

## API authentication

The deployed API task explicitly validates:

- issuer: the Singapore User Pool issuer above
- client ID: the Singapore mobile app client above
- `token_use`: `access`

Every authenticated Flutter request must send exactly:

```http
Authorization: Bearer <COGNITO_ACCESS_TOKEN>
```

Use Amplify's Cognito plugin to fetch a current session and access its User Pool tokens. Amplify remains responsible for secure storage and refresh. Do not log a token, decode it for authorization decisions, save it to LocalStore, or send the ID token. AWS documents the Flutter session flow in [Manage user sessions](https://docs.amplify.aws/flutter/frontend/auth/manage-user-sessions/) and the intended access-token role in [Tokens and credentials](https://docs.amplify.aws/flutter/build-a-backend/auth/concepts/tokens-and-credentials/).

On `401`:

1. Ask Amplify for one forced session refresh.
2. Retry the original request once only when its replay is safe.
3. If refresh fails or the retry is also `401`, clear feature caches, sign out locally, and route to login.

Do not create a refresh loop. A `403` is an authorization/business-membership problem, not a refresh signal.

### User provisioning and terms

Call `GET /me` immediately after the first successful Singapore sign-in. On the first authenticated request after registration, include the exact terms version the user accepted:

```http
X-Terms-Version: <DISPLAYED_TERMS_VERSION>
```

The current sign-up UI records only a Boolean checkbox locally and has no version. Add a stable terms-version configuration and retain pending acceptance until `/me` succeeds. Never send a version the user did not see.

## Shared API client plan

### Responsibilities

The shared client should:

- accept a single validated base URL, `https://api-dev.save-tep.us` for DEV;
- build paths without string concatenation in screens;
- obtain the current access token per request through `AccessTokenProvider`;
- attach `Accept: application/json` and `Content-Type: application/json` when a JSON body is present;
- encode request DTOs and require the documented response shape;
- support empty `204` responses;
- use injected `http.Client`, clock, and logger dependencies for tests;
- close the underlying client through provider disposal;
- impose explicit connect/request timeouts;
- expose cancellation where long upload/poll flows need it;
- log method, route template, status, duration, and a safe request ID in development;
- redact authorization headers, passwords, presigned URLs, request/response bodies containing PII, and Mindee credentials.

### Retry policy

- Retry idempotent reads at most twice for transient network failures, `408`, `429`, and selected `5xx` responses, using bounded exponential backoff and `Retry-After` when present.
- Do not automatically retry `POST`, `PATCH`, `PUT`, or `DELETE` unless the endpoint has a verified idempotency contract or the failure occurred before any request bytes were sent.
- Treat `409` duplicate/conflict responses as domain outcomes that the feature repository resolves with the user.

### Error mapping

| API result | Client behavior |
|---|---|
| Network/timeout | Typed connectivity error; preserve user input and offer retry |
| `400` | Map validation details to feature fields when the documented body supports it |
| `401` | One refresh/replay attempt, then sign out |
| `403` | Permission or wrong-active-business message; do not retry |
| `404` | Feature-specific not-found handling and stale-cache invalidation |
| `409` | Duplicate/state conflict flow; do not silently overwrite |
| `412` | Show missing prerequisite, such as payroll setup or scan confirmation state |
| `422` | Display safe domain validation/disclosure information |
| `429` | Respect `Retry-After`; no busy retry loop |
| `5xx` | Safe generic message plus request ID; limited retry for reads only |

## DTO and domain-model policy

- The API accepts monetary request values as integer cents and frequently returns cents as JSON strings. Parse response strings losslessly and convert at the UI boundary; do not use binary `double` for network money.
- Use a shared `MoneyCents` value object only after at least two features need it. Keep currency from the active business.
- Use API IDs for persisted relationships. UI labels are presentation data only.
- Keep API enums explicit and fail visibly on unknown values while retaining the raw value for forward compatibility.
- Treat dates documented as `YYYY-MM-DD` as date-only values. Do not introduce UTC day shifts when converting API `date-time` responses.
- Do not reuse local snapshot JSON as API DTOs. The verified API names and shapes differ materially.

Detailed endpoint and field mappings are in `API_ENDPOINT_MAPPING.md`.

## Feature integration notes

### User and business profile

Resolve the signed-in user through `/me`, list/create businesses through `/businesses`, then resolve `/me/active-business`. The existing `BusinessProfile` contains DBA, address, EIN, business email/phone, and `setupCompleted`, none of which are represented by `BusinessResponseDto`. Do not discard those values. Obtain a backend contract decision before replacing local storage for the unsupported fields.

### Business categories

This is a hard gate for Expense, Fixed/Variable grouping, Transactions, and Profit & Loss.

- Flutter exposes 69 onboarding categories with stable IDs such as `fixed.rents` and `variable.office`.
- The API exposes a fixed enum of 13 category strings.
- No endpoint persists a user's selected categories.
- The API enum has no user-category ID and cannot represent most Flutter selections.

Preferred backend change: add a category catalog/selection resource with stable IDs, labels, type (`FIXED`/`VARIABLE`/`PAYROLL`), active/selected state, and versioning. Expense/reminder/P&L records should reference the stable category ID. Do not compress 69 choices into `OTHER` without product approval.

### Expense and Mindee

Keep the current sequence: select image, send to Mindee, map fields, let the user correct them, then persist.

The direct Expense API does not accept tip, printed time, card last four, or receipt reference; `ConfirmScanDto` does. The scan flow also owns an S3 key and resulting expense/income relationship, but `POST /scans` starts the backend OCR job flow. Before implementation, the backend must confirm one of these safe patterns:

1. a client-extracted/Mindee scan mode that uploads and confirms without invoking Textract or another backend extractor; or
2. a direct attachment endpoint/field that links an uploaded object to `POST /expenses` or `POST /income`.

Do not reconnect Textract and do not upload a receipt without a persisted linkage and cleanup policy.

### Deposit/income

Map deposits to `/businesses/{businessId}/income`. `CreateIncomeDto` supports total, card/cash/gift-card/other portions, order number, source, date, and source total. It does not support card last four, and `source` is not explicitly documented as the Flutter Vendor field. The update DTO supports only amount, date, and source.

The current automatic value is owned by Flutter: `ScannedDepositData` defaults to `01`, and the Mindee mapper preserves the current UI order number instead of extracting or incrementing it. Continue sending the UI value as `orderNumber`; do not assume the API generates the next value. If true auto-increment is required across devices, add and document a server-side sequence endpoint before changing ownership.

### Transactions

There is no unified `/transactions` resource. The transaction screen must compose paginated income and expense repositories. Its existing aggregate contract can use the P&L endpoint for arbitrary date-range totals where semantics match, but the Swagger list response bodies for income and expense are currently undocumented. The transaction controller must also stop deleting through `LiabilityService` and delegate mutations to its repository.

### Profit & Loss

Use `GET /businesses/{businessId}/profit-loss` as the persisted source of truth and the category drill-down endpoint for details. Do not download all records to recompute the authoritative total.

The API response supplies category totals but not fixed/variable group metadata, and it uses the 13-value enum. The backend category decision must preserve the current fixed/variable sections, selected categories, category subtotals, total expenses, and profit/loss calculation before cutover.

### Saving

Use the Savings Plan endpoints for the current Saving screen. They directly model a yearly savings rate, target derived from deposits, saved entries, remaining amount, and day/week/month allocations. Migrate the memory-only saved amounts to `PUT /savings-plan/entries/upsert`. Evaluate the Reserves endpoints separately; do not merge reserves and the current saving plan merely because both concern saving.

### Liabilities

Map loans/debts to `/debts`, converting dollars to cents and whole percent to APR basis points. The API has richer payment, status, and projection behavior. Preserve local data until the currently untyped debt-list response is documented and migration has been reconciled.

### Payroll

The API supports staff, payroll settings, payroll entries, reports, PDFs, QuickBooks files, and W-4 document flows. Its resource model is not a direct match for the local `PayrollRecord`, which embeds multiple employees and local reminder/expense synchronization IDs. Plan staff migration first, then settings, then create one payroll entry per staff member/period. Several personal employee fields and the staff update request body are not represented in Swagger and require a contract decision.

### Reminders

The API supports create/list/calendar/update/delete/pay/postpone and series deletion. Map recurrence strings explicitly. The API lacks the local `alertEnabled` flag, and its category enum has the same taxonomy blocker as Expense. Once integrated, let the backend own recurrence expansion and status; do not materialize a second local series as authoritative state.

## Implementation phases

### Phase 0: contract decisions

- Resolve the stable business-category catalog and per-user selection contract.
- Document income, expense, debt, and payroll list response schemas and pagination envelopes.
- Confirm the Mindee-only image upload/linking flow and `POST /scans/{id}/confirm` response schema.
- Resolve unsupported business/employee fields and update semantics.
- Confirm account migration between old and Singapore Cognito subjects.

### Phase 1: environment and authentication

- Add validated environment configuration and a reversible old/Singapore auth switch.
- Point Amplify Auth to the existing Singapore pool/client without deploying AWS resources.
- Accept username or email, add multi-step/MFA handling, and test `demo-owner` with `<TEST_PASSWORD>` entered only in the UI.
- Fetch `/me` with the Cognito access token and implement terms-version recording.

### Phase 2: shared API client and business context

- Implement/test `AccessTokenProvider`, `ApiClient`, errors, safe logging, retry rules, and one-time unauthorized recovery.
- Implement `/me`, businesses, and active-business repositories.
- Add repository overrides/feature flags for controlled rollout.

### Phase 3: categories and core transactions

- Implement the approved category catalog/selection contract first.
- Implement Expense persistence and the approved Mindee image relationship.
- Implement Deposit/Income persistence while preserving order-number ownership.
- Implement transaction pagination, deletion, aggregate, and export paths.

### Phase 4: reports and secondary financial features

- Switch Profit & Loss to the server statement and drill-down endpoints.
- Switch Saving to Savings Plan endpoints.
- Switch Home/budget summaries only after their API semantics are reconciled with current calculations.
- Switch Liabilities to Debt endpoints.

### Phase 5: payroll, reminders, and remaining settings

- Migrate staff, W-4 documents, payroll settings/entries, and reports.
- Migrate reminders and recurring-series ownership.
- Integrate partner, notification, support, enterprise-code, and account-deactivation endpoints as their screens become functional.

### Phase 6: migration and cleanup

- Export/backup local data before cutover.
- Run an explicit, restartable, idempotent local-to-API migration; never silently dual-write indefinitely.
- Compare counts/totals and record a migration receipt per feature.
- Remove static service bypasses and dead AWS key/value placeholders only after API rollback is no longer needed.
- Remove old pool selection only after production approval; deleting AWS resources remains a separate infrastructure change.

## Testing strategy

### Unit tests

- DTO parsing, including numeric strings, unknown enums, optional fields, and malformed bodies.
- cents/dollars and percent/basis-point conversions.
- access-token retrieval, one refresh/retry, and no refresh loop.
- URI/query construction and date-only handling.
- status-to-domain error mapping and log redaction.
- category ID mapping and fixed/variable grouping.

### Repository tests

- Use an injected fake `http.Client` and fixture bodies captured from the approved OpenAPI contract.
- Verify every repository method sends the expected method, path, headers, and body.
- Verify pagination, empty pages, `204`, `401`, `403`, `409`, `412`, `422`, `429`, and `5xx` behavior.
- Verify sign-out/active-business changes invalidate cached business data.

### Widget tests

- Preserve existing login, onboarding, scan review, transaction, saving, P&L, liabilities, payroll, and reminder behavior.
- Add loading, retry, empty, unauthorized, forbidden, conflict, and offline states.
- Confirm user-edited Mindee values, not the raw extraction, are submitted.

### DEV integration tests

- Sign in as `demo-owner` with `<TEST_PASSWORD>` without storing or printing it.
- Assert access-token calls to `/me` succeed and ID-token calls are rejected in a controlled test harness.
- Test token refresh after the 15-minute access-token lifetime.
- Create/read/update/delete disposable DEV records per feature and clean them up by verified IDs.
- Verify records cannot cross business membership boundaries.
- Upload a disposable image only after the Mindee scan-flow contract is approved; verify S3 linkage and cleanup.

### Required local validation for every Flutter implementation phase

```powershell
dart format .
flutter analyze
flutter test
```

## Cutover and rollback

- Gate API repositories by environment/feature, not by ad hoc screen conditionals.
- Keep local records read-only during validation and present a clear migration status.
- Do not enable dual write until idempotency and conflict ownership are defined.
- Roll back by switching the repository binding/configuration, not by deleting server data.
- Record server IDs returned by migration so cleanup is exact and reviewable.

## Blocking decisions before broad coding

1. Backend category catalog and selected-category persistence.
2. Typed list/pagination response contracts for income, expense, debt, and payroll.
3. Mindee-only receipt image persistence without reconnecting Textract.
4. Deposit Vendor/card-last-four/update semantics.
5. Unsupported BusinessProfile fields and account migration ownership.
6. Payroll personal fields, staff update body, and local multi-employee-to-entry mapping.
7. Whether local reminder alerts map to push notification preferences or require a new field.

