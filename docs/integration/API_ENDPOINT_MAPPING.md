# SaveTep Flutter to API Endpoint Mapping

## Contract snapshot

Source: [SaveTep DEV Swagger](https://api-dev.save-tep.us/docs), inspected September 5, 2026.

- Base URL: `https://api-dev.save-tep.us`
- OpenAPI: `3.0.0`
- API version: `1`
- Paths reviewed: 187
- Operations reviewed: 250
- Operations declaring `security: [{ bearer: [] }]`: 238
- Operations with no OpenAPI security field: 12
- API runtime Cognito requirement: Singapore issuer/client and `token_use=access`

For every row marked `Bearer access`, the exact header is:

```http
Authorization: Bearer <COGNITO_ACCESS_TOKEN>
```

Status meanings:

- **supported**: the documented contract is sufficient for the stated core behavior.
- **unclear**: an endpoint exists, but a schema or semantic mismatch must be resolved before exact integration.
- **missing**: no endpoint/field exists for the required Flutter behavior.

An endpoint can be supported while the complete Flutter feature remains unclear because the feature spans multiple rows.

## Authentication audit

The 12 operations without an OpenAPI security declaration are:

| Operations | Swagger authentication conclusion | Flutter use |
|---|---|---|
| `GET /health` | Public | Optional connectivity/diagnostic check |
| `POST /auth/password-recovery`, `POST /auth/password-recovery/confirm`, `POST /auth/confirmation-code/resend` | No bearer security declared | Preserve current Amplify Cognito recovery/resend flows unless the backend explicitly directs a switch |
| `POST /auth/password`, `POST /auth/sign-out`, `POST /auth/sign-out-all` | No security declared, even though password change documents `401`/`403`; contract is internally unclear | Preserve current Amplify change-password/sign-out flows |
| `POST /webhooks/ocr-callback` | No bearer declaration; response includes `401` and the deployment has a separate callback secret | Backend-only; never call from Flutter |
| Four `/jobs/*` operations | No bearer declaration; deployment has a separate job-trigger secret | Backend-only; never call from Flutter |

All relevant `/me`, `/businesses`, `/organizations`, admin, moderator, and business-data operations declare bearer security. The deployed API configuration resolves Swagger's generic `JWT` label: it expects the Cognito **access token**, not the ID token.

## Primary Flutter feature mapping

| Flutter feature | Current frontend model/service | HTTP method | API endpoint | Authentication required | Request model | Response model | Flutter changes required | Status |
|---|---|---:|---|---|---|---|---|---|
| Cognito sign-in/session | `AuthService`, `ServiceAuthRepository`, `AuthController` | N/A | Cognito via Amplify | Cognito credentials; no API bearer yet | Amplify sign-in inputs | Amplify `AuthSignInResult` / Cognito session | Point Amplify to the existing Singapore pool/client; accept username or email; handle MFA/multi-step results | supported |
| Sign-up, confirm, reset, sign-out | `AuthService` | N/A | Cognito via Amplify | Flow-specific Cognito auth | Existing Amplify inputs | Existing Amplify results | Keep the working Amplify architecture; do not duplicate with `/auth/*` while Swagger security is unclear | supported |
| Local API user provisioning/profile | `AccountProfile`, `AccountProfileService` | GET | `/me` | Bearer access | Optional `X-Terms-Version` header on first authenticated request after registration | `MeResponseDto` | Replace local user-profile source with typed API mapping for `id`, `email`, `name`, `phone`, `locale`; retain unsupported local onboarding state until migrated | supported |
| User profile edit | `AccountProfileController` | PATCH | `/me` | Bearer access | `UpdateMeDto`: optional `name`, `phone`, `locale` | `MeResponseDto` | Move update out of LocalStore; optimistic update only with rollback | supported |
| Active business context | No dedicated server context; profile is local | GET / PUT | `/me/active-business` | Bearer access | `SetActiveBusinessDto` for PUT | `ActiveBusinessResponseDto` | Add `BusinessContextRepository`; cache/invalidate `businessId`; handle no active business | supported |
| Business list/create | `BusinessProfile`, `BusinessProfileService` | GET / POST | `/businesses` | Bearer access | `CreateBusinessDto`: `name`, `type`, optional `currency`, `timezone`, `state`, `referralCodeUsed` | GET: `BusinessResponseDto[]`; POST: `BusinessResponseDto` | Split user and business profiles; create/select the business during onboarding | supported |
| Business Management view/update | `BusinessManagementScreen`, `BusinessProfileFormController` | GET / PATCH | `/businesses/{businessId}` | Bearer access | `UpdateBusinessDto` | `BusinessResponseDto` | Map server `name/type/currency/timezone/state`; use active `businessId` | supported |
| Business deactivate | Deactivate UI is not wired to business persistence | GET / DELETE | `/businesses/{businessId}/deactivation-disclosure`, `/businesses/{businessId}` | Bearer access | `DeactivateBusinessDto` for DELETE | `DeactivationDisclosureResponseDto`; DELETE `204` | Show disclosure, require explicit confirmation, clear active-business caches after success | supported |
| Business DBA/address/EIN/business contact/setup flag | `BusinessProfile` | — | No matching fields in Business DTOs | — | — | — | Backend must add fields or define a separate business-profile resource; do not drop local values | missing |
| Business categories / onboarding selections | `ExpenseCategory` (69 selectable categories), `ExpenseCategoryService`, `BusinessCategoryController` | — | No catalog or selected-category endpoint | — | — | API only defines a 13-value `ExpenseCategory` enum | Add a backend stable-ID catalog and per-user/per-business selected-category resource before migration | missing |
| Deposit list | `DepositRecord`, `LocalTransactionQueryRepository` | GET | `/businesses/{businessId}/income` | Bearer access | Query: `cursor`, `limit`, `dateFrom`, `dateTo` | Swagger does not document the `200` response body | Add typed paging only after the response envelope is documented | unclear |
| Deposit create | `SaveDepositRequest`, `LiabilityService.saveDeposit` | POST | `/businesses/{businessId}/income` | Bearer access | `CreateIncomeDto` | `IncomeResponseDto` | Convert money to cents; map `transactionDate -> depositDate`, totals and payment portions; send current `orderNumber` | supported |
| Deposit read/update/delete | `DepositRecord`, transaction delete path | GET / PATCH / DELETE | `/businesses/{businessId}/income/{id}` | Bearer access | `UpdateIncomeDto` for PATCH | `IncomeResponseDto`; DELETE `204` | Move delete behind repository; note PATCH only supports amount/date/source, not payment breakdown/order number | unclear |
| Deposit Vendor | Requested UI behavior; not represented by current `DepositRecord` | POST / PATCH | `/businesses/{businessId}/income`; `/businesses/{businessId}/income/{id}` | Bearer access | `CreateIncomeDto.source` / `UpdateIncomeDto.source` | `IncomeResponseDto.source` | Backend/product must confirm whether `source` is the Vendor field | unclear |
| Deposit card last four | `DepositRecord.cardLastFour` | — | No field in `CreateIncomeDto` or `IncomeResponseDto` | — | — | — | Add a backend field or an approved credit-card relationship; do not silently discard it | missing |
| Deposit order-number behavior | `ScannedDepositData` defaults to `01`; Mindee mapper preserves current UI value | POST | `/businesses/{businessId}/income` | Bearer access | `CreateIncomeDto.orderNumber` | `IncomeResponseDto.orderNumber` | Keep Flutter ownership until a server sequencing contract exists; API docs do not claim generation | supported |
| Scanned deposit image relationship | `ScannedDepositData.receiptImage`, currently UI-only | POST / GET / POST | `/businesses/{businessId}/scans/presigned-upload`; `/businesses/{businessId}/scans/{scanJobId}`; `/businesses/{businessId}/scans/{scanJobId}/confirm` | Bearer access | `PresignedUploadDto`, `RegisterScanDto`, `ConfirmScanDto` | `PresignedUploadResponseDto`, `ScanJobResponseDto`; confirm `201` body undocumented | Define a Mindee-client-extraction mode or attachment flow that does not reconnect backend OCR/Textract | unclear |
| Expense list/filter | `ExpenseRecord`, `LocalTransactionQueryRepository` | GET | `/businesses/{businessId}/expenses` | Bearer access | Query: cursor/limit/category/creditCardId/date range | Swagger does not document the `200` response body | Add typed paging after envelope is documented; map stable category ID when backend supports it | unclear |
| Expense create | `SaveExpenseRequest`, `LiabilityService.saveExpense` | POST | `/businesses/{businessId}/expenses` | Bearer access | `CreateExpenseDto` | `ExpenseResponseDto` | Convert cents/date; map payee to vendor/description; map source; stop using UI labels as relationships | unclear |
| Expense update/delete/read | `ExpenseRecord`; transaction controller bypasses repository for delete | GET / PATCH / DELETE | `/businesses/{businessId}/expenses/{id}` | Bearer access | `UpdateExpenseDto` | `ExpenseResponseDto`; DELETE `204` | Extend repository for mutation and refresh affected P&L/saving/home caches | supported |
| Expense category and fixed/variable grouping | `categoryId`, `category`, `ExpenseType` | POST / PATCH | `/businesses/{businessId}/expenses`; `/businesses/{businessId}/expenses/{id}` | Bearer access | API requires 13-value `category` plus `type` (`FIXED`, `VARIABLE`, `PAYROLL`) | `ExpenseResponseDto` | Block until 69 stable Flutter IDs can be represented without lossy mapping | missing |
| Expense tip/time/card last four/reference | Mindee fields and `ScannedExpenseData`; card last four is currently not passed into `SaveExpenseRequest` | POST | `/businesses/{businessId}/scans/{scanJobId}/confirm` | Bearer access | `ConfirmScanDto.tipCents`, `expenseTime`, `cardLast4`, `referenceNumber` | Confirm `201` body undocumented; later `ScanJobResponseDto` has `expenseId` | Use only after approved Mindee scan flow; direct Expense DTOs do not support these fields | unclear |
| Expense receipt relationship | `receiptImage` is currently discarded after save | POST / GET | `/businesses/{businessId}/scans/presigned-upload`; `/businesses/{businessId}/scans`; `/businesses/{businessId}/scans/{scanJobId}`; `/businesses/{businessId}/scans/{scanJobId}/confirm` | Bearer access | Scan DTOs | `ScanJobResponseDto` contains `s3Key` and `expenseId` | Persist uploaded-image lifecycle and linkage; confirm cleanup on failed/cancelled records | unclear |
| Recurring Expense | `RecurringExpenseReminderService`, recurring fields on `ExpenseRecord` | POST | `/businesses/{businessId}/expenses`; `/businesses/{businessId}/reminders` | Bearer access | `CreateExpenseDto` plus `CreateReminderDto` | `ExpenseResponseDto`, `ReminderResponseDto` | Backend Expense DTO has no recurrence link; decide whether reminders alone own recurrence or add a relationship | unclear |
| Profit & Loss statement | `LiabilityProfitLossRepository`, `ProfitLossReportService` | GET | `/businesses/{businessId}/profit-loss` | Bearer access | Query: required `taxYear`, optional `startDate`, `endDate` | `ProfitLossResponseDto` | Replace local authoritative totals with server response; parse cents strings | supported |
| Profit & Loss drill-down | `ProfitLossExpenseLine` links to transaction screen | GET | `/businesses/{businessId}/profit-loss/categories/{category}` | Bearer access | Category path plus tax year/date range | `CategoryDrillDownResponseDto` | Map drill-down transactions to UI detail/navigation | supported |
| Profit & Loss fixed/variable selected sections | 69 selected `ExpenseCategory` records grouped by `ExpenseType` | GET | `/businesses/{businessId}/profit-loss` | Bearer access | — | Categories contain only API enum plus total; no selected state or type metadata | Extend category/P&L contract before claiming UI parity | missing |
| Saving plan read | `SavingScreenController`, `LiabilitySavingDepositRepository` | GET | `/businesses/{businessId}/savings-plan` | Bearer access | Query: `year`, `granularity=day|week|month` | `SavingsPlanResponseDto` | Replace local deposit scan and calculator as authoritative target source; retain presentation-only rollover if approved | supported |
| Saving rate | Memory-only `_savingRate` | PUT | `/businesses/{businessId}/savings-plan/{year}` | Bearer access | `UpsertSavingsPlanDto.savingsRateBps` | `SavingsPlanResponseDto` | Convert percent to basis points and persist | supported |
| Saved amount entry | Memory-only `_dailySavedAmounts` | PUT | `/businesses/{businessId}/savings-plan/entries/upsert` | Bearer access | `UpsertSavingsEntryDto` | `SavingsPlanResponseDto` | Replace memory-only distribution with server entry updates | supported |
| Reserves (separate from Saving screen) | No dedicated current repository | GET / PATCH | `/businesses/{businessId}/reserves`; `/businesses/{businessId}/reserves/settings` | Bearer access | `UpsertReservesSettingsDto` | `ReservesSummaryResponseDto`, `ReservesSettingsResponseDto` | Treat as a distinct future feature unless product explicitly merges it with Saving | supported |
| Transactions deposit/expense tabs | `_TransactionController`, `TransactionQueryRepository` | GET | `/businesses/{businessId}/income`; `/businesses/{businessId}/expenses` | Bearer access | Two query parameter sets | Both list bodies undocumented | Compose two typed repositories; no unified `/transactions` endpoint exists | unclear |
| Transaction aggregate cards | `TransactionAggregates` | GET | `/businesses/{businessId}/profit-loss`; possibly `/businesses/{businessId}/dashboard` | Bearer access | P&L date range / dashboard current business | `ProfitLossResponseDto`, `DashboardResponseDto` | Reconcile screen date-range semantics; do not use invented `/transactions/aggregates` TODO path | unclear |
| Transaction PDF/Excel exports | Client-side exporters load all matching local records | GET pages | Income and Expense list endpoints | Bearer access | Date filters plus cursor/limit | List bodies undocumented | Paginate all pages with bounds, then retain client exporters; no dedicated transaction export endpoint exists | unclear |
| Liabilities list | `LiabilityRecord`, `LiabilityService` | GET | `/businesses/{businessId}/debts` | Bearer access | Query: cursor/limit/status/groupBy | Swagger describes only an `object` with no properties | Document the paging envelope before integration | unclear |
| Liability create | `SaveLiabilityRequest` | POST | `/businesses/{businessId}/debts` | Bearer access | `CreateDebtDto` | `DebtResponseDto` | Map tab to `LOAN/DEBT`, starting to balance cents, percent to APR bps, minimum/date | supported |
| Liability read/update/delete | `LiabilityRecord` | GET / PATCH / DELETE | `/businesses/{businessId}/debts/{debtId}` | Bearer access | `UpdateDebtDto` | `DebtResponseDto`; DELETE `204` | Add remote repository and exact cents/bps conversion | supported |
| Debt payment/status/projection | Current UI calculates simple summaries locally | POST | `/businesses/{businessId}/debts/{debtId}/payments`; `/businesses/{businessId}/debts/{debtId}/mark-paid`; `/businesses/{businessId}/debts/{debtId}/payoff-projection` | Bearer access | `RecordPaymentDto`, `PayoffProjectionRequestDto` | `DebtResponseDto`, `PayoffProjectionResponseDto` | Prefer server balance/status/projection when UI exposes these actions | supported |
| Staff list/create | `EmployeeRecord`, `EmployeeService`, `LocalEmployeeRepository` | GET / POST | `/businesses/{businessId}/staff` | Bearer access | `CreateStaffDto` | `StaffResponseDto[]` / `StaffResponseDto` | Create server IDs first; map name/role/salary/pay type | supported |
| Staff update/deactivate | `SaveEmployeeRequest`, `deleteEmployee` | PATCH / DELETE | `/businesses/{businessId}/staff/{staffId}` | Bearer access | PATCH request body is not documented | `StaffResponseDto` | Do not implement update until request schema is published; DELETE deactivates rather than hard-deletes | unclear |
| Employee personal details | `EmployeeRecord`: birthday, phone, address, hire date, pay method, W-4 link/setup | — | Staff DTOs have no matching fields | — | — | — | Backend must add/locate an employee-detail resource; do not put sensitive fields in generic notes | missing |
| W-4 document capture/delivery | Temporary document capture and email services | GET / POST / DELETE | `/businesses/{businessId}/staff/{staffId}/w4-documents`; `/businesses/{businessId}/staff/{staffId}/w4-documents/upload-url`; `/businesses/{businessId}/w4-documents/{documentId}`; `/businesses/{businessId}/w4-documents/{documentId}/deliver` | Bearer access | `RequestW4UploadDto`, `CaptureW4Dto`, `DeliverW4Dto` | W-4 response/upload/delivery DTOs | Replace local link/email handoff with presigned upload and delivery workflow; follow sensitive-data retention rules | supported |
| Payroll settings | `PayrollRecord.schedule/processDaysBefore`, employee payroll setup | GET / PATCH | `/businesses/{businessId}/payroll/settings` | Bearer access | `UpsertPayrollSettingsDto` | GET is documented only as untyped `object`; `PayrollSettingsResponseDto` exists but is not linked | Map cadence/pay type/allocation/overtime after GET schema link is fixed | unclear |
| Payroll entries | `PayrollRecord` embeds a list of `PayrollEmployee` | GET / POST | `/businesses/{businessId}/payroll`; `/businesses/{businessId}/payroll/{entryId}` | Bearer access | `CreatePayrollEntryDto` for one `staffId` and period | POST/GET-one: `PayrollEntryResponseDto`; list body undocumented | Convert one local multi-employee period into one API entry per staff; define partial-failure behavior | unclear |
| Payroll reports/files | Local calculations/export plus W-4 handling | GET / POST | `/businesses/{businessId}/payroll/report`; `/businesses/{businessId}/payroll/{entryId}/print`; `/businesses/{businessId}/payroll/{entryId}/pdf-url`; `/businesses/{businessId}/payroll/{entryId}/quickbooks-upload-url`; `/businesses/{businessId}/payroll/{entryId}/quickbooks-upload-confirm` | Bearer access | `ConfirmQuickbooksUploadDto` where applicable | `PayrollReportResponseDto`; some file-operation bodies undocumented | Adopt server report/file lifecycle after core entries are stable | supported |
| Reminder list/calendar | `ReminderService`, `ReminderRecord`, `ReminderController` | GET | `/businesses/{businessId}/reminders`; `/businesses/{businessId}/reminders/calendar` | Bearer access | Calendar requires `month` | `ReminderResponseDto[]`, `ReminderCalendarDayDto[]` | Replace local occurrence materialization with server results/status | supported |
| Reminder create/update/delete | `ReminderDraft`, `ReminderSeries` | POST / PATCH / DELETE | `/businesses/{businessId}/reminders`; `/businesses/{businessId}/reminders/{id}` | Bearer access | `CreateReminderDto`, `UpdateReminderDto` | `ReminderResponseDto`; DELETE `204` | Map recurrence enum and `scope`; invalidate calendar and summary | supported |
| Reminder pay/postpone/delete series | `markFinished`, edit/delete scope logic | POST / DELETE | `/businesses/{businessId}/reminders/{id}/pay`; `/businesses/{businessId}/reminders/{id}/postpone`; `/businesses/{businessId}/reminders/series/{seriesId}` | Bearer access | `PostponeReminderDto` where applicable | `ReminderResponseDto`; series delete `204` | Use server status/series IDs instead of generated local occurrence keys | supported |
| Reminder alert toggle | `ReminderRecord.alertEnabled`, `ReminderService.updateAlert` | — | No reminder preference field/endpoint | — | — | — | Decide whether to add a reminder flag or map to notification preferences | missing |

## Supplemental existing feature mappings

| Flutter area | Verified backend support | Important note |
|---|---|---|
| Home/budget | `/businesses/{businessId}/dashboard`; budget caps, utilization, cash flow, deposit utilization, break-even | Current target percentages are local and shaped differently from category caps; reconcile semantics before replacement |
| Tax estimate | Tax profile and tax-estimate endpoints | Prefer the backend ruleset/disclaimer to the local static estimator after P&L integration |
| Manage partner | Partner list/invite/accept/tier/revoke/audit plus `/me/join-partner` | Existing UI can be connected after core business context |
| Notifications | List, unread count, mark read/all, delete | Separate notification inbox state from Reminder recurrence state |
| Institution support | Four `institution-support` operations exist | Map only after inspecting the screen's intended ticket/file flow during its implementation phase |
| Enterprise code | Two `enterprise-code` operations exist | Do not confuse enterprise codes with business referral codes |
| Account deactivation | `/me/access/deactivation-disclosure` and `/me/access/deactivate` | Use disclosure and step-up requirements exactly; keep separate from business deletion |
| Credit cards | Five `credit-cards` operations exist | Relevant to Expense `creditCardId`; card last four should come from this resource or a scan field, not an ad hoc label |
| Bank statements/imports | Bank-statement and import job resources exist | They are not replacements for the current direct Mindee receipt/deposit extraction flow |
| Assets/properties/retirement | Dedicated resources exist | No current first-phase Flutter persistence migration depends on them |

## Critical model mismatches

### Category taxonomy

Flutter's 69 onboarding selections cannot be mapped one-to-one to the API's 13 values:

`RENT`, `UTILITIES`, `SUPPLIES`, `PAYROLL`, `MARKETING`, `EQUIPMENT`, `INSURANCE`, `FOOD`, `OTHER`, `LOAN_OBLIGATION`, `COGS`, `CONSUMABLE_SUPPLIES`, `FUEL`.

Using `OTHER` for unmatched values would lose user intent and break fixed/variable P&L groupings. This is a backend contract gap, not a Flutter mapping task.

### Money and percentages

- Flutter models mostly store dollars as `double`; API requests use integer cents.
- Many API response cents are JSON strings.
- Savings rates and APRs use basis points (`1000 = 10%` or `1599 = 15.99%`).
- Current `LiabilityRecord.percent` is an integer percent, so decimal APR precision cannot round-trip.

### Dates

- Request DTOs commonly require date-only `YYYY-MM-DD` strings.
- Response DTOs often label the same logical dates as `date-time`.
- Preserve date-only semantics and the active business timezone; do not normalize a local date through UTC in a way that changes its day.

### Scan data

- Direct Expense CRUD omits tip/time/card-last-four/reference fields that are present in `ConfirmScanDto`.
- Direct Income CRUD omits card last four.
- `ScanJobResponseDto` carries `s3Key` and resulting record IDs, but the confirm operation's `201` response is not typed.
- `POST /scans` is an OCR job registration route; using it solely for persistence requires an explicit Mindee mode or backend confirmation.

## Swagger gaps to resolve

Do not infer these shapes from the placeholder TODO comments in Flutter:

1. `GET /businesses/{businessId}/income` response body.
2. `GET /businesses/{businessId}/expenses` response body.
3. `GET /businesses/{businessId}/debts` paging object properties.
4. `GET /businesses/{businessId}/payroll` response body.
5. `GET /businesses/{businessId}/payroll/settings` typed response link.
6. `PATCH /businesses/{businessId}/staff/{staffId}` request body.
7. `POST /businesses/{businessId}/scans/{scanJobId}/confirm` success body.
8. Bearer/security behavior of `/auth/password`, `/auth/sign-out`, and `/auth/sign-out-all` if Flutter is ever asked to use them.
