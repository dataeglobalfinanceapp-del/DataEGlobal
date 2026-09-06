# Flutter to AWS/API Implementation Checklist

## How to use this checklist

Complete phases in order. Each phase must keep the app runnable and retain a reversible path to the local implementation until its acceptance checks pass.

Before feature migration begins, the backend and product owners must resolve these two blocking contracts:

- [ ] Define how the 69 stable Flutter category IDs and selected fixed/variable groupings map to the API's 13-value `ExpenseCategory` enum.
- [ ] Define a receipt/deposit-image workflow that stores Mindee-reviewed data without enabling or reconnecting backend OCR/Textract.

Do not silently collapse categories, discard receipt links, expose secrets, invent API routes, or make local and remote stores authoritative at the same time.

For every Flutter-code phase:

- [ ] Run `dart format .`.
- [ ] Run `flutter analyze` and resolve all errors and warnings introduced by the phase.
- [ ] Run `flutter test` and resolve failures.
- [ ] Add focused unit/widget tests for changed behavior.
- [ ] Verify logs contain no password, bearer token, Mindee key, presigned URL, or PII body.
- [ ] Record the rollback switch and the test evidence before enabling the phase by default.

## Phase 1 — Environment and configuration

- [ ] Introduce a validated, immutable `AppEnvironment` outside widget layout code.
- [ ] Read `APP_ENV`, `API_BASE_URL`, `AWS_REGION`, `COGNITO_USER_POOL_ID`, `COGNITO_USER_POOL_CLIENT_ID`, `COGNITO_ISSUER_URL`, and `TERMS_VERSION` from compile-time configuration.
- [ ] Retain the existing three Mindee values only for private debug builds.
- [ ] Reject a non-HTTPS API URL outside explicitly controlled local tests.
- [ ] Validate that Region, User Pool ID, and issuer all agree on `ap-southeast-1` for Singapore DEV.
- [ ] Build Amplify Auth configuration from the validated environment rather than importing the current hard-coded `us-west-2` output.
- [ ] Configure User Pool `ap-southeast-1_3ob6DVAln` and client `2dkdkbefs65ipd52egvfve23gu`; do not add an Identity Pool.
- [ ] Add an `AUTH_ENV=legacy|singapore-dev` or equivalent reversible selection until acceptance is complete.
- [ ] Add `.run/*.local.json` to `.gitignore`.
- [ ] Commit a safe `.run/dev.example.json` containing placeholders but no secrets.
- [ ] Confirm `.env` is never passed wholesale through `--dart-define-from-file`.
- [ ] Update the old Android/AWS testing guide so it cannot accidentally regenerate or advertise the `us-west-2` configuration as DEV.
- [ ] Add configuration parsing/validation unit tests, including Region mismatch, missing value, and invalid URL cases.
- [ ] Confirm both legacy and Singapore selections can start without changing or deleting AWS resources.

Exit gate: the app starts with Singapore DEV configuration, the old configuration remains selectable, and no credentials are compiled into the app.

## Phase 2 — Authentication and session lifecycle

- [ ] Keep Amplify Auth/Cognito as the sole device authentication mechanism.
- [ ] Change the sign-in field from email-only to username-or-email so `demo-owner` reaches Cognito.
- [ ] Keep email validation for sign-up and recovery flows where Cognito requires an email.
- [ ] Handle all Amplify sign-in next steps, including optional MFA and confirmation challenges.
- [ ] Restore sessions on application launch through Amplify.
- [ ] Fetch the Cognito session and expose the access token to the API layer without exposing it to widgets.
- [ ] Verify `token_use=access`; never authorize the REST API with the ID token.
- [ ] Keep token persistence and refresh owned by Amplify; do not copy tokens into LocalStore.
- [ ] Implement sign-out cleanup for profile, active-business, repository, paging, and feature caches.
- [ ] Handle expired/invalid sessions by returning to login with a recoverable message.
- [ ] Capture the exact terms version accepted during sign-up/onboarding for the first API request.
- [ ] Test username login, email-alias login, session restoration, MFA next steps, sign-out, global sign-out, expiry, and failed refresh.
- [ ] Manually verify sign-in using `demo-owner` with `<TEST_PASSWORD>` entered only in the UI.

Exit gate: a Singapore Cognito session survives restart, refreshes safely, and produces an access token for API requests.

## Phase 3 — Shared API client

- [ ] Replace the placeholder key/value `AwsApiClient.read/write` contract with an HTTP-oriented interface.
- [ ] Keep HTTP, token access, serialization, retry policy, and error normalization outside widgets.
- [ ] Add `Authorization: Bearer <access-token>` to protected calls.
- [ ] Add `Content-Type` and `Accept` headers only where appropriate.
- [ ] Support `X-Terms-Version` only when the current provisioning contract requires it.
- [ ] Add a bounded timeout and cancellation/disposal behavior.
- [ ] On `401`, force one session refresh and retry the request once; prevent loops.
- [ ] Do not retry validation failures, authorization failures, or non-idempotent writes automatically.
- [ ] Normalize network, timeout, `400`, `401`, `403`, `404`, `409`, `422`, `429`, and `5xx` failures into typed application errors.
- [ ] Preserve safe backend request/correlation IDs in errors when supplied.
- [ ] Log only method, route template, status, duration, and safe request ID; redact query values and sensitive headers/bodies.
- [ ] Add reusable cents, basis-points, date, enum, and cursor codecs with boundary tests.
- [ ] Add contract fixtures generated or transcribed from the reviewed Swagger schema; do not infer undocumented list envelopes.
- [ ] Add client tests for header injection, one-refresh retry, concurrent `401` handling, timeouts, malformed JSON, and error mapping.

Exit gate: the shared client can make a mocked authenticated request and has deterministic refresh/error behavior.

## Phase 4 — User and active-business context

- [ ] Add typed `/me` DTOs, mapper, service/repository, and controller/provider.
- [ ] Call `GET /me` after sign-in and handle first-request `X-Terms-Version` behavior.
- [ ] Map server `id`, `email`, `name`, `phone`, and `locale` without discarding local-only onboarding data.
- [ ] Move supported edits to `PATCH /me`, including rollback of optimistic UI on failure.
- [ ] Add a typed active-business repository for `GET` and `PUT /me/active-business`.
- [ ] Add typed business list/create/read/update/deactivate operations.
- [ ] During onboarding, select an existing business or create one and store the returned server ID as active.
- [ ] Pass the active server `businessId` into feature repositories; never derive it from email, name, or local IDs.
- [ ] Decide backend ownership for DBA, address, EIN, business contact details, and setup-completed state, which current Business DTOs do not support.
- [ ] Keep unsupported local fields recoverable until their migration contract exists.
- [ ] Test no-business, one-business, multi-business, switch, deactivation, forbidden, and stale-cache flows.

Exit gate: authenticated screens have one authoritative API user and active business context, while unsupported profile fields remain preserved.

## Phase 5 — Categories

- [ ] Stop this phase until the category contract blocker at the top is resolved.
- [ ] Obtain a backend catalog with immutable category IDs, display names, fixed/variable/payroll type, active state, and ordering—or an approved lossless equivalent.
- [ ] Obtain per-user or per-business selected-category endpoints.
- [ ] Write and review an explicit mapping for every existing stable Flutter category ID.
- [ ] Define how custom/future categories behave and how removed categories remain renderable historically.
- [ ] Define whether Profit & Loss group/type metadata comes from the category catalog or the P&L response.
- [ ] Implement typed category repository and local cache after the contract is published.
- [ ] Migrate selections idempotently; keep a journal of local ID to server ID results.
- [ ] Do not send display labels as API relationship identifiers.
- [ ] Test all 69 existing categories, selection persistence, type grouping, renamed/disabled categories, and migration reruns.

Exit gate: every current category and selection round-trips without loss, including fixed/variable grouping.

## Phase 6 — Expenses

- [ ] Obtain the documented `GET /businesses/{businessId}/expenses` success envelope before implementing paging.
- [ ] Add feature-local Expense API DTOs, mapper, remote data source, repository, and state/controller.
- [ ] Convert decimal amounts to integer cents with tested rounding rules.
- [ ] Map transaction date, vendor/payee, description, source, category, type, deduction, tax, and supported subamount fields explicitly.
- [ ] Resolve how tip, expense time, card last four, reference/check number, and receipt link are stored; direct Expense DTOs do not expose all current fields.
- [ ] Resolve whether recurring expenses are linked to Reminder records or owned by another server resource.
- [ ] Keep Mindee extraction in the current private Flutter debug flow.
- [ ] Upload/link a receipt only through the approved non-Textract workflow.
- [ ] Implement create/read/update/delete with server-returned IDs.
- [ ] Move delete out of direct `LiabilityService` calls and behind the repository.
- [ ] Add cursor paging, date/category filters, loading, empty, offline, validation, and retry states.
- [ ] Invalidate transaction, dashboard, P&L, savings, and relevant reminder caches after mutations.
- [ ] Test manual and Mindee-reviewed entries, all money boundaries, CRUD failures, duplicate submission protection, paging, filters, and receipt cleanup.

Exit gate: a disposable expense can be created, retrieved, edited, filtered, and deleted without losing any approved field or invoking Textract.

## Phase 7 — Deposits/income

- [ ] Obtain the documented `GET /businesses/{businessId}/income` success envelope before implementing paging.
- [ ] Add feature-local Income API DTOs, mapper, remote data source, repository, and state/controller.
- [ ] Map `transactionDate` to `depositDate`, amount to cents, payment portions, source, source total, and order number.
- [ ] Confirm whether API `source` is the requested Vendor field before changing the UI label or semantics.
- [ ] Define server support for card last four or preserve it locally until supported.
- [ ] Keep Flutter order-number generation only until the backend publishes sequencing/uniqueness rules; the current default `01` is not a generator.
- [ ] Define collision behavior for offline/retried deposit creation and make writes idempotent if the API supports an idempotency key.
- [ ] Keep Mindee extraction in private Flutter debug builds and use only the approved image-link workflow.
- [ ] Implement create/read/update/delete, noting that PATCH cannot currently change the payment breakdown or order number.
- [ ] Add cursor paging, date filters, loading, empty, offline, validation, and retry states.
- [ ] Invalidate transaction, dashboard, P&L, and savings caches after mutations.
- [ ] Test manual and Mindee-reviewed deposits, payment-total reconciliation, order-number behavior, duplicate submission, CRUD, paging, and image cleanup.

Exit gate: a disposable deposit round-trips through the API with reconciled totals, a defined Vendor meaning, and a safe order-number rule.

## Phase 8 — Transactions

- [ ] Remove assumptions about a unified `/transactions` or `/transactions/aggregates` endpoint; neither exists in Swagger.
- [ ] Compose the transaction view from the remote Income and Expense repositories.
- [ ] Define a stable merged sort order and tie-breaker across the two paged sources.
- [ ] Define how filters and pagination behave when one source has more pages than the other.
- [ ] Map delete/edit actions back to the owning feature repository.
- [ ] Choose either Profit & Loss or Dashboard totals for each aggregate card and document its date-range semantics.
- [ ] Retain client-side PDF/Excel export only after loading all bounded pages; provide progress/cancel/error handling.
- [ ] Prevent stale results when active business or date filters change.
- [ ] Test mixed ordering, same timestamps, empty source, one failing source, paging boundaries, edit/delete refresh, business switch, and exports.

Exit gate: deposit and expense tabs plus aggregate cards match server data for the selected business/date range.

## Phase 9 — Profit & Loss

- [ ] Add typed mapping for `GET /businesses/{businessId}/profit-loss`.
- [ ] Send required `taxYear` and approved optional `startDate`/`endDate` semantics.
- [ ] Parse cents/string totals without floating-point loss.
- [ ] Add typed category drill-down for `GET /businesses/{businessId}/profit-loss/categories/{category}`.
- [ ] Replace local transaction-derived totals as authoritative only after comparison tests pass.
- [ ] Use the resolved category catalog/grouping contract for fixed, variable, payroll, selected, and historical categories.
- [ ] Define cache invalidation after expense, income, payroll, and category changes.
- [ ] Test full year, partial ranges, zero values, negative/net-loss values, large values, leap dates, category drill-down, and server/local parallel comparison.

Exit gate: server P&L and drill-down reproduce approved UI totals and category grouping for representative datasets.

## Phase 10 — Remaining features

### Saving and reserves

- [ ] Implement Savings Plan read/upsert/entry repositories using cents and basis points.
- [ ] Replace memory-only saving rate and daily saved amounts after migration acceptance.
- [ ] Decide whether Reserves remains a separate feature; do not merge it into Saving by assumption.
- [ ] Test year/granularity boundaries, distribution, rounding, and concurrent edits.

### Liabilities/debts

- [ ] Obtain the documented debt-list paging envelope.
- [ ] Implement debt CRUD plus payment, mark-paid, and payoff-projection operations.
- [ ] Map loan/debt type, starting/balance cents, minimum, due date, and APR basis points explicitly.
- [ ] Test status transitions, overpayment, payoff, rounding, paging, and deletion policy.

### Staff, payroll, and W-4

- [ ] Obtain the Staff PATCH request schema, Payroll list response schema, and linked Payroll Settings response schema.
- [ ] Decide backend ownership for birthday, phone, address, hire date, pay method, and W-4 setup fields missing from Staff DTOs.
- [ ] Implement staff list/create/update/deactivate after schemas are complete.
- [ ] Convert one local multi-employee payroll period into one server entry per staff member with defined partial-failure recovery.
- [ ] Implement settings, reports, printable/PDF artifacts, and QuickBooks upload only after core entries pass.
- [ ] Implement W-4 presigned upload/capture/delivery with strict sensitive-data logging and retention rules.
- [ ] Test permission errors, inactive staff, partial payroll batches, artifact expiry, and W-4 cleanup.

### Reminders

- [ ] Implement list/calendar/create/update/delete/pay/postpone/series-delete operations.
- [ ] Replace locally materialized recurrence occurrences with server IDs and recurrence state.
- [ ] Decide how `alertEnabled` maps to an API preference; do not discard it.
- [ ] Test recurrence scopes, timezone/date changes, paid/postponed state, series deletion, and calendar refresh.

### Other API-backed areas

- [ ] Review Dashboard, tax profile, integrations, subscription/billing, organizations, files, and notification preferences against actual product scope before enabling them.
- [ ] Keep admin, moderator, webhook, and job endpoints out of the mobile client unless a separate authorization design explicitly requires them.

Exit gate: each enabled feature has a typed contract, isolated repository, focused tests, cache policy, and rollback path.

## Phase 11 — Cleanup, reconciliation, and migration

- [ ] Inventory all local records before migration: account/business profile, category selections, expenses, deposits, liabilities, employees, payroll, reminders, saving targets, and generated files.
- [ ] Define an idempotent migration key and server-ID journal for every migrated entity.
- [ ] Define migration ordering for dependencies: user/business, categories, staff, transactions, reminders, payroll, then derived data.
- [ ] Back up the local snapshot and preserve it until reconciliation and the retention window are complete.
- [ ] Run a dry-run report showing record counts, skipped fields, contract blockers, and expected writes.
- [ ] Require explicit user confirmation before uploading local financial/employee data.
- [ ] Handle partial failures with resumable checkpoints; never duplicate completed writes on rerun.
- [ ] Compare local and server counts/totals by type, date range, and category.
- [ ] Keep unsupported fields in a recoverable local archive rather than dropping them.
- [ ] Remove static caches, direct service calls, placeholder AWS repositories, and invented endpoint TODOs only after remote acceptance.
- [ ] Remove dual-write/parallel-read flags feature by feature after the rollback window.
- [ ] Do not delete either Cognito pool or server data as part of cleanup.
- [ ] Document support recovery for issuer/user-ID changes and account/business ownership mismatches.

Exit gate: migration is resumable and reconciled, no supported data is lost, and legacy code is removed only where rollback is no longer required.

## Phase 12 — End-to-end acceptance

- [ ] Run the full formatter, analyzer, and test suite from a clean checkout.
- [ ] Build and install the Android DEV app using the documented Singapore launch configuration.
- [ ] Sign in with username and email alias; exercise optional MFA if available.
- [ ] Verify `/me`, terms-version handling, business creation/selection/switch, and sign-out cache clearing.
- [ ] Verify one complete manual and Mindee-reviewed Expense lifecycle.
- [ ] Verify one complete manual and Mindee-reviewed Deposit lifecycle.
- [ ] Verify transaction lists, aggregates, exports, and Profit & Loss/drill-down reconciliation.
- [ ] Verify categories and selections retain stable identity and fixed/variable grouping.
- [ ] Verify Saving, liabilities, staff/payroll/W-4, and reminders for every feature enabled in Phase 10.
- [ ] Keep the app open beyond the 15-minute access-token lifetime and verify transparent refresh.
- [ ] Test offline startup, connection loss during writes, timeout, `401`, `403`, `409`, `422`, `429`, and `5xx` recovery.
- [ ] Verify duplicate taps/retries do not create duplicate financial records.
- [ ] Switch businesses and confirm no data leaks across repository or image caches.
- [ ] Review logs, crash reports, analytics, exports, and screenshots for secrets and PII.
- [ ] Confirm the release build contains no Mindee key, test password, AWS access key, or debug endpoint.
- [ ] Run accessibility and responsive-layout checks on touched screens.
- [ ] Obtain product acceptance for model differences and backend acceptance for every previously unclear/missing contract.
- [ ] Exercise the documented rollback without deleting resources or corrupting local/server data.
- [ ] Record final Swagger version/hash, app commit, environment, test evidence, migration outcome, and approvers.

Final gate: make Singapore/API mode the default only when every in-scope acceptance item passes and the rollback procedure has been demonstrated.
