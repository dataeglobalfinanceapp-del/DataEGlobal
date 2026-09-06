# SaveTep Demo Scope Audit and Remaining-Cost Estimate

Audit date: 2026-09-06

## Executive conclusion

The repository contains a meaningful Flutter demo foundation, but none of the six requested demo areas is ready to demonstrate exactly as specified. Scan Expense and Profit & Loss are partially implemented. Personal (Employee and Owner), the requested Asset & Liability allocation plan, and the Retirement calculator are missing as end-to-end features.

The most important architectural gap is that financial records remain in local device/browser storage and are not consistently owned by both the authenticated user and an active business. The repository contains new API DTOs and repository contracts for `/me`, `/businesses`, and `/me/active-business`, but there is no concrete API-client adapter, feature wiring, transaction API implementation, or corresponding backend data model in this repository. The current Amplify data schema contains only the starter `Todo` model.

The separate management/admin web scope is also not implemented. The `web/` directory is the host shell for the same Flutter application, not the management portal described in `06-MANAGEMENT-WEB.md`.

## Demo readiness summary

| Demo Feature | Status | Demo Ready? | Main Gap |
| --- | --- | --- | --- |
| Scan Expense | Partial | No | The review UI and Mindee mapping exist, but release-mode analysis is disabled, saving is local rather than through the backend, physical phone/iPad behavior is unverified, and handwriting support is unproven. |
| Profit & Loss | Partial | No | The local report calculation works, including a tax-reserve calculation, but records/categories are not active-business scoped or API-persisted and the tax logic is not an IRS-complete or versioned tax system. |
| Personal - Employee | Missing | No | No Personal/Employee screen, paycheck-income ledger, personal history, authenticated personal storage, or IRS-based personal tax calculation exists. |
| Personal - Owner | Missing | No | Multi-business API contracts exist only as unwired scaffolding; there is no working owner-to-business aggregation or personal tax result. |
| Asset & Liability Planning | Missing | No | Savings, budget summaries, and liabilities provide reusable parts, but the six-bucket 100% allocation calculator and display do not exist. |
| Retirement Calculator | Missing | No | The Investments tile has no route and there is no retirement screen, compound-interest domain calculation, or test. Contribution frequency also needs confirmation. |

## Scope and audit method

This is a code audit, not an implementation. No missing product feature was added.

The following documents were treated as product-scope references, not as executable instructions:

- `E:\DataEglobal\project-scope\01-PRODUCT-SUMMARY.md`
- `E:\DataEglobal\project-scope\02-PROJECT-SCOPE.md`
- `E:\DataEglobal\project-scope\03-WORK-TREE.md`
- `E:\DataEglobal\project-scope\04-END-TO-END-FLOWS.md`
- `E:\DataEglobal\project-scope\05-USE-CASES.md`
- `E:\DataEglobal\project-scope\06-MANAGEMENT-WEB.md`

Where a reference document describes Textract as a future OCR design, the owner's current request controls: **Mindee remains the scan provider and Textract must not be reconnected.**

Status meanings used in this audit:

- **Complete:** the required behavior, data flow, and relevant persistence are implemented and supported by code/test evidence.
- **Partial:** useful implementation exists, but one or more required links in the end-to-end flow are absent or unverified.
- **Missing:** the requested user-facing capability or its essential domain logic does not exist.
- **Present but not ready for demo:** a screen, button, contract, mock, seed, or local implementation exists but cannot substantiate the requested behavior.
- **Needs confirmation:** the repository and supplied scope do not define a required business rule, so this audit does not invent one.

## Cross-cutting architecture evidence

These findings affect several demo features:

- `lib/features/auth/services/business_profile_service.dart` stores one `business_profile_<userId>` locally. It does not provide an active-business list or server-persisted membership model.
- `lib/features/auth/data/remote/business_api_models.dart` and `lib/features/auth/data/remote/user_business_remote_repositories.dart` define useful multi-business DTOs and REST repository contracts. They are not called by application screens/controllers.
- `lib/features/auth/data/remote/user_business_api_client.dart` is an abstract boundary. Its own comment says an adapter still needs to forward calls to `AwsApiClient`.
- `lib/core/api/aws_api_client.dart`, `lib/data/remote/aws_transaction_repository.dart`, and `lib/data/repositories/aws_transaction_query_repository.dart` are unimplemented or placeholder remote paths.
- `lib/data/local/local_transaction_repository.dart` saves transactions under the single local key `savetep_local_data_v1`. Expense/deposit records do not carry authenticated-user and business ownership through the current save requests.
- `amplify/data/resource.ts` defines only a guest-accessible starter `Todo`; it does not define SaveTep business, transaction, personal-finance, hierarchy, consent, audit, payroll, or management data.
- `lib/services/liability_service.dart` automatically seeds a sample ledger when local storage is empty. `lib/features/auth/models/budget_data.dart` contains the sample deposits and expenses. This is useful for UI development, but populated sample values must not be presented as proof of an authenticated user's stored records.

## 1. Scan Expense

### Demo requirement

Use a phone or iPad camera to scan a receipt or handwritten paper with Mindee; obtain business name, date, total, tips, and expense category; allow review/edit; use the user's selected categories; and persist the saved expense through the current backend/API architecture.

### Current implementation status

**Partial; present but not ready for the requested demo.**

### Existing screen/feature

- `ScanExpenseAutoScreen` captures from the camera, calls document analysis, maps results, displays editable values, and confirms a save.
- A separate expense review dialog is implemented.
- The app uses `image_picker` for camera capture and a direct Mindee V2 client in debug mode.

### Relevant files

- `lib/features/auth/screens/scan_screen/expense_screen/scan_expense_auto_screen.dart`
- `lib/features/auth/screens/scan_screen/expense_screen/scan_expense_screen.dart`
- `lib/features/auth/screens/scan_screen/expense_screen/expense_mindee_mapper.dart`
- `lib/features/auth/screens/scan_screen/services/document_analysis_service.dart`
- `lib/features/auth/screens/scan_screen/services/mindee_config.dart`
- `lib/features/auth/screens/scan_screen/services/mindee_expense_fields.dart`
- `lib/features/auth/services/expense_category_service.dart`
- `lib/data/local/local_transaction_repository.dart`
- `lib/data/remote/aws_transaction_repository.dart`
- `lib/data/dto/save_expense_request.dart`
- `lib/services/liability_service.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `pubspec.yaml`
- `README.md`
- `ANDROID_AWS_COGNITO_MINDEE_TESTING_GUIDE.md`
- `test/scan_expense_auto_screen_widget_test.dart`
- `test/mindee_document_analysis_service_test.dart`
- `test/mindee_mappers_test.dart`

### What currently works

- **Camera code exists:** the Expense auto-scan screen invokes `ImagePicker.pickImage` with `ImageSource.camera`.
- **Platform declarations exist:** Android declares camera permissions and iOS declares a camera usage string.
- **Mindee is the current provider:** `MindeeDocumentAnalysisService` selects the configured expense/deposit Mindee model and submits/polls the Mindee V2 API.
- **Textract is not used by the Flutter code:** no live Textract scan path was found. The testing guide explicitly describes the current direct Mindee flow as replacing Textract.
- **Required fields are mapped:** Mindee output is mapped to payee/business name, transaction date, total, tips, and category.
- **Review/edit exists:** total, tips, business/payee, date, card, and category can be changed before confirmation.
- **Selected category reuse exists locally:** `ExpenseCategoryService` loads the signed-in account's locally selected category IDs, and the scan screen offers those active categories.
- **Local save works:** the confirmed expense is converted to `SaveExpenseRequest` and saved through the default local `LiabilityService` path; category ID/name, date, tips, payee, and amount are retained locally.
- Relevant mapper, service, and widget tests pass with fakes/mocks.

### What is missing or unverified

- **Release scanning does not work:** `MindeeDocumentAnalysisService` deliberately throws in release mode because the client must not expose the Mindee API key. The README likewise says the direct flow is debug-only.
- **Backend/API persistence is missing:** the default transaction repository is local. The AWS transaction repository is unimplemented, and the save request has no business ID or user ID.
- **Ownership is incomplete:** categories are account-keyed local values rather than active-business records, while the saved transaction ledger uses a global local key.
- **Receipt end-to-end status is only code-tested:** a manual test guide exists, but the repository does not prove a successful physical-device capture -> live Mindee -> review -> backend-save run.
- **Handwriting is not proven:** the code accepts an image, but no handwriting-specific Mindee model contract, representative handwritten fixtures, accuracy threshold, integration test, or recorded acceptance result was found. Image acceptance alone is not handwriting support.
- **Phone/iPad behavior is unverified:** widget tests mock the capture/analysis boundary. There is no device-matrix evidence for Android phone, iPhone, or iPad camera permissions, capture orientation, memory, and review layout.
- The iOS camera message refers to W-4 documents instead of receipt/expense scanning, which is confusing for this flow.
- The captured image and OCR inference/linkage are not persisted with the transaction, limiting auditability and later correction.

### What must be completed before demo

1. Put Mindee behind an authenticated server-side endpoint or secure worker and keep Textract disconnected.
2. Persist the resulting expense to an implemented API with authenticated-user and active-business ownership, stable category ID, and an idempotent save contract.
3. Validate the selected Mindee model against agreed receipt and handwritten-paper samples. If the model cannot meet the agreed handwriting acceptance threshold, show an explicit unsupported/fallback state rather than claiming support.
4. Run and record the full flow on at least one supported phone and a physical iPad, including permission denial/retry and editable review.
5. Replace the unrelated iOS W-4 camera usage message.

### Recommended priority

**P0 - blocks the requested owner demo.**

## 2. Profit & Loss

### Demo requirement

The user's manually selected onboarding categories must be stored and reused by Expense and Profit & Loss. The report must separate fixed/variable expenses, group spending by category, include deposits, calculate profit/loss, and calculate estimated tax expense.

### Current implementation status

**Partial; the local calculation and UI are substantive, but the required owned end-to-end data flow is not complete.**

### Existing screen/feature

- Business-category onboarding with fixed and variable category selection.
- Expense category selection and local transaction retention.
- Year/date-filtered Profit & Loss statement with category sections, deposits, totals, net before tax, tax reserve, and net after tax.

### Relevant files

- `lib/features/auth/screens/login_screen/onboarding/business_category/business_category_screen.dart`
- `lib/features/auth/screens/login_screen/onboarding/business_category/business_category_controller.dart`
- `lib/features/auth/screens/login_screen/onboarding/business_category/business_category_onboarding_repository.dart`
- `lib/features/auth/services/expense_category_service.dart`
- `lib/features/auth/models/expense_category.dart`
- `lib/features/auth/screens/profit_loss_screen/profit_loss_screen.dart`
- `lib/features/auth/screens/profit_loss_screen/controllers/profit_loss_controller.dart`
- `lib/features/auth/screens/profit_loss_screen/models/profit_loss_models.dart`
- `lib/features/auth/screens/profit_loss_screen/repositories/profit_loss_repository.dart`
- `lib/features/auth/screens/profit_loss_screen/services/profit_loss_report_service.dart`
- `lib/features/auth/screens/profit_loss_screen/widgets/profit_loss_statement.dart`
- `lib/services/tax_estimator.dart`
- `lib/services/tax_estimate_service.dart`
- `lib/data/local/local_transaction_repository.dart`
- `lib/data/repositories/aws_transaction_query_repository.dart`
- `test/business_category_controller_test.dart`
- `test/business_category_screen_widget_test.dart`
- `test/profit_loss_report_service_test.dart`
- `test/profit_loss_screen_widget_test.dart`
- `test/tax_estimator_test.dart`

### End-to-end flow verdict

| Required link | Finding |
| --- | --- |
| Onboarding category selection | Implemented. The controller requires at least one category and saves selected IDs. |
| Categories saved to user/business account | Partial. They are saved under the authenticated account's local storage key, not to a business-owned backend record. |
| Expense uses those categories | Implemented for the local app path. |
| Expense retains category IDs | Implemented in `SaveExpenseRequest` and the local expense record. A label fallback remains for older/local data. |
| P&L groups expenses | Implemented. Stable category ID is preferred and name matching is a fallback. |
| Fixed/variable separation | Implemented from selected category definitions. |
| Deposits/income included | Implemented from the local deposit repository and selected date range. |
| Totals and profit/loss calculated | Implemented in domain/service code and displayed. |
| Estimated tax calculated | Real calculation code exists, but it is a simplified annualized reserve using one selected bracket rate, not a complete/versioned IRS tax engine. |

### What currently works

- Category onboarding distinguishes fixed and variable categories and saves selected IDs.
- The report uses the selected categories, filters records by range, groups expenses, prorates recurring fixed expenses, includes deposits, and calculates gross income, expenses, net before tax, estimated tax reserve, and net after tax.
- The statement renders the calculated figures; the tax value is not a static label.
- Unit and widget tests cover category onboarding, grouping, totals, date ranges, the statement, and the present tax estimator.

### What is missing

- Categories and financial records are not persisted as active-business-owned server records.
- The P&L repository reads all records from the local ledger; it cannot enforce authenticated user/business isolation.
- The statement uses a hard-coded `Save Tep` business name rather than the active business.
- Remote transaction queries return placeholders, so the report cannot be recreated on another device from backend data.
- The tax estimator is not enough to claim an intended IRS calculation system. It lacks a supported tax year/ruleset version, filing status, jurisdiction, progressive bracket calculation, deductions, credits, self-employment tax, and an effective-date/stale-rule policy.
- The exact meaning of “estimated tax expense” for the business demo needs confirmation: a simple reserve heuristic and an IRS-oriented estimated tax calculation are materially different products.

### What must be completed before demo

1. Complete the active-business context and backend persistence/query path for categories, deposits, and expenses.
2. Migrate or explicitly discard/separate existing unowned local seed/demo data so it cannot be mixed with authenticated records.
3. Use the active business's real name and enforce its category and transaction scope throughout the report.
4. Define the intended tax estimate inputs/rules, tax year, jurisdiction, assumptions, and disclaimer; implement a versioned deterministic calculation to that approved scope.
5. Add API integration tests proving the full category -> expense -> report -> tax flow.

### Recommended priority

**P0 for owned data integration and an agreed tax definition; P1 for report polish.**

## 3. Personal - Employee

### Demo requirement

Track paycheck deposits/income and history for the authenticated employee, handle year/date selection, store personal financial data, and calculate estimated personal tax using the intended IRS rules.

### Current implementation status

**Missing.**

### Existing screen/feature

There is no Personal/Employee screen or route. The existing Payroll screen is employer-side payroll planning/recording and is not an employee's Personal account.

### Relevant files

- `lib/main.dart`
- `lib/features/auth/screens/home_screen/home_screen.dart`
- `lib/features/auth/widgets/menu_grid.dart`
- `lib/features/auth/screens/payroll_screen/payroll_screen.dart`
- `lib/features/auth/screens/payroll_screen/payroll_models.dart`
- `lib/features/auth/screens/payroll_screen/payroll_service.dart`
- `lib/services/tax_estimator.dart`
- `lib/data/local/local_transaction_repository.dart`

### What currently works and may be reused

- Payroll models can calculate gross employee pay inputs and store employer payroll runs locally.
- Existing deposit, date-range, currency-input, and summary UI patterns can be reused through public feature interfaces.
- The current tax estimator demonstrates a small deterministic calculation service pattern, but not the required personal tax rules.

### What is missing

- No Personal navigation destination or employee Personal UI.
- No authenticated employee-to-paycheck link.
- No personal paycheck income ledger/history or annual view.
- No personal data ownership/persistence model.
- No IRS-based personal tax calculation or supporting inputs such as tax year, filing status, jurisdiction, wages, withholding, deductions, and other income.
- Employer payroll records contain gross amounts and do not establish that a corresponding employee received a personal deposit.

### What must be completed before demo

1. Confirm the personal-tax demo's supported tax year, filing status, jurisdiction, income/withholding inputs, and required IRS source/ruleset.
2. Add a Personal feature with an employee income ledger, paycheck history, date/year controls, and authenticated storage.
3. Define how an employer payroll confirmation creates or links to an employee paycheck without duplicating income; support manual income only if approved.
4. Implement and test the agreed versioned personal-tax estimate with clear assumptions and educational disclaimer.

### Recommended priority

**P0 - completely missing demo feature.**

## 4. Personal - Owner

### Demo requirement

Link every business belonging to the authenticated owner, read each business's income, aggregate it into Personal total income, and calculate an estimated personal tax using the intended IRS rules.

### Current implementation status

**Missing. Multi-business API contracts are present but not a working feature.**

### Existing screen/feature

There is no Personal/Owner screen or aggregation service. The current wired `BusinessProfileService` represents one local profile per authenticated user.

### Relevant files

- `lib/features/auth/models/business_profile.dart`
- `lib/features/auth/services/business_profile_service.dart`
- `lib/features/auth/data/remote/business_api_models.dart`
- `lib/features/auth/data/remote/user_business_remote_repositories.dart`
- `lib/features/auth/data/remote/user_business_api_client.dart`
- `lib/data/dto/save_deposit_request.dart`
- `lib/data/dto/save_expense_request.dart`
- `lib/data/local/local_transaction_repository.dart`
- `lib/data/remote/aws_transaction_repository.dart`
- `lib/services/tax_estimator.dart`

### What currently works and may be reused

- The newly added API DTOs/contracts model a list of businesses and an active business, including `GET /businesses` and `GET/PUT /me/active-business`.
- The local P&L service can calculate income and expenses for one supplied ledger/range.
- Existing summary and date-range presentation patterns are reusable.

### What is missing

- No concrete `UserBusinessApiClient` adapter and no feature wiring to the remote business repositories.
- No implemented backend/business membership data in this repository.
- The wired local business model has no business ID, list, membership, or owner aggregation.
- Deposit/expense saves do not carry business ownership through the active path.
- No service queries and combines income across all businesses belonging to one authenticated owner.
- No personal owner UI, year handling, duplicate-income policy, or personal tax system.

### What must be completed before demo

1. Complete and wire authenticated multi-business list/selection/membership APIs.
2. Attach every business financial record to an authorized business ID and make queries server-authoritative.
3. Define whether “business income” means deposits, net profit, owner draws/distributions, or another tax basis. These are not interchangeable and the code does not define the choice.
4. Build the owner aggregation and Personal presentation on the approved basis.
5. Apply the agreed versioned personal-tax rules without double-counting inter-business or payroll transfers.

### Recommended priority

**P0 - completely missing and dependent on the business/backend foundation.**

## 5. Asset & Liability Planning

### Demo requirement

Calculate a plan from available money using exactly these target allocations:

| Allocation | Target |
| --- | ---: |
| Daily Expense | 55% |
| Entertainment | 10% |
| Saving | 10% |
| Retirement | 10% |
| Long-Term Investment | 5% |
| Donation / Health Care | 10% |
| **Total** | **100%** |

The UI must show the available amount, each percentage and dollar amount, total allocation, and remaining/unallocated amount.

### Current implementation status

**Missing as a requested feature; supporting calculations/screens are partially reusable.**

### Existing screen/feature

- Liabilities supports locally stored loan/debt records.
- Saving calculates a 10% saving target and daily/weekly/monthly plan.
- Home/Budget calculates available money from deposits minus expenses and displays expense-composition charts.

### Relevant files

- `lib/features/auth/models/budget_data.dart`
- `lib/features/auth/models/liability_model.dart`
- `lib/features/auth/screens/home_screen/domain/home_budget_chart_calculator.dart`
- `lib/features/auth/screens/home_screen/widgets/budget_sum_chart.dart`
- `lib/features/auth/screens/home_screen/widgets/budget_donut_chart.dart`
- `lib/features/auth/screens/saving_screen/saving_screen.dart`
- `lib/features/auth/screens/saving_screen/saving_screen_controller.dart`
- `lib/features/auth/screens/saving_screen/saving_plan_calculator.dart`
- `lib/features/auth/screens/liabilities_screen/liabilities_screen.dart`
- `lib/data/local/local_budget_target_repository.dart`
- `lib/services/liability_service.dart`
- `test/saving_screen_widget_test.dart`
- `test/saving_rollover_calculator_test.dart`
- `test/budget_donut_chart_widget_test.dart`
- `test/liability_service_test.dart`

### What currently works and may be reused

- `BudgetData.available` and `LiabilityService` already establish a deposits-minus-expenses available amount.
- The Saving feature contains a reusable pure distribution-calculator pattern, currency formatting, period rows, and “remaining” presentation.
- Budget target storage and chart widgets contain percentage/dollar display patterns.
- Liabilities has forms, validation, local persistence, and debt/loan presentation.

### What is missing

- No Assets model or Assets screen was found; the liability type only represents loan/debt.
- No calculator encodes the six requested allocation targets or validates that they total 100%.
- No screen displays all six percentages and dollar allocations together.
- No total allocated and remaining/unallocated calculation for this plan.
- Current home charts show historical expense composition, not a forward allocation plan.
- Saving's 10% value is a separate saving target and does not integrate with the other five buckets.
- The available-money source remains local and unowned by active business/personal context.

### What must be completed before demo

1. Confirm whether the plan is based on current available cash, selected-period income, or another balance and whether it is Personal or business scoped.
2. Add a pure six-bucket allocation model/calculator with exact 100% validation and deterministic currency rounding.
3. Build the plan UI with the required amount, percentages, total, and remaining values.
4. Reuse the existing available calculation and visual components only after connecting them to the correct authenticated context.
5. Add calculation, rounding, zero/negative-balance, and responsive widget tests.

### Recommended priority

**P0 - completely missing demo calculation; implementation is relatively bounded after its balance/context rule is confirmed.**

## 6. Retirement Calculator

### Demo requirement

Allow manual entry of starting amount, investment length, return rate, annual compounding, and additional contribution, then show the estimated ending amount.

### Current implementation status

**Missing.**

### Existing screen/feature

The Home screen contains an `Investments` tile with no route. No Retirement screen, calculator, or compound-interest utility was found.

### Relevant files

- `lib/main.dart`
- `lib/features/auth/screens/home_screen/home_screen.dart`
- `lib/features/auth/widgets/menu_grid.dart`
- `lib/features/auth/screens/saving_screen/saving_plan_calculator.dart`
- `lib/services/money_formatter.dart`

### What currently works and may be reused

- Existing money/percentage input, formatting, validation, summary-card, and responsive-screen patterns can be reused.
- The Saving calculator provides an example of keeping financial calculation logic outside widgets.

### What is missing

- No route or enabled navigation action.
- No Retirement/Investment calculator screen.
- No annual compound-interest calculation accounting for principal, rate, years, and contributions.
- No calculation tests or boundary/error states.
- The repository does not define when the additional contribution is applied.

### Needs confirmation

The owner's prompt suggests that **Additional Contribution is intended to be annual**, but neither the existing code nor the supplied scope definitively establishes frequency or timing. Confirm both:

- contribution frequency: annual; and
- timing: beginning or end of each year.

This audit does not invent those rules because they produce different results.

### What must be completed before demo

1. Confirm annual contribution timing and input limits/rounding.
2. Add a pure annual-compounding calculator and unit tests.
3. Add the Retirement screen, validation, calculated result, and an enabled route/navigation action.
4. Add responsive tests for phone/tablet/web widths and clear educational assumptions.

### Recommended priority

**P0 - completely missing but small and independently deliverable once the contribution rule is confirmed.**

## Management/admin web audit

### Current implementation status

**Missing as an end-to-end portal.**

`06-MANAGEMENT-WEB.md` describes a substantial account-administration and consent-controlled finance-support product. No corresponding routes, screens, management API implementation, hierarchy data, authorization services, consent workflow, notification workflow, immutable audit stream, Cognito status synchronization, document service, or portal tests were found in this repository.

`web/index.html`, `web/manifest.json`, and the web icons are standard Flutter web-host files. `package.json` contains Amplify/CDK/OpenAPI development dependencies, not a management frontend. The presence of Flutter web support therefore does not count as the management portal.

### Pages/workspaces still to build

- Sign-in/recovery with inactive and unauthorized-role states.
- Role-specific dashboard.
- Lazy/virtualized hierarchy.
- Searchable, filterable, sortable, cursor-paginated Accounts page.
- Account detail/status history and activation/deactivation confirmation flow.
- Audit page.
- Admin workspace for moderators, assignments, permission grants, consent requests, authorized finance support, notifications, and audit logs.
- Moderator workspace restricted by server-side assignments, grants, consent, step-up, and resource authorization.
- User consent/revocation workspace with step-up authentication.
- Payroll workspace, including server-authoritative gross preview, duplicate prevention, corrections, PDFs, and reports.
- Investment and tax-saving planning workspace with versioned tax rules and failure-closed states.

### Backend/security still to build

- User status, retailer operator membership, status audit, Admin/Moderator identity, assignment, permission, consent, step-up, notification, finance-access audit, and document models.
- Management, security, consent, notification, document, and payroll endpoints described in the management scope.
- Server-enforced organization/retailer/agent scope; moderator assignment before consent disclosure; grant + consent + step-up + resource checks for finance operations.
- Idempotent account commands, Cognito enable/disable synchronization, retry/reconciliation, redacted errors, immutable audit records, pagination, stable sorting, and security/integration tests.

These are not ordinary “admin pages.” Much of the work is security-sensitive backend behavior; estimating only visible page construction would materially understate the remaining scope.

## Validation evidence and limits

The audit used source inspection and the current automated test suite.

- `flutter analyze`: passed with no issues.
- Focused suite for category onboarding, Scan Expense, Mindee, Profit & Loss, tax estimator, Saving, and liabilities: 90 tests passed when run serially.
- Full `flutter test`: 205 tests were discovered/run and 4 failed. The observed failures were in `test/deposit_account_balance_summary_test.dart` and three cases in `test/home_screen_widget_test.dart`; some failure output also included a `path_provider` `MissingPluginException` after static state crossed test cases.
- No live Mindee call, physical camera run, iPad run, deployed backend transaction, or management portal run was available as evidence. These items remain unverified even where widget/unit tests pass.

The four failures do not by themselves invalidate the focused calculation tests, but a fully green suite is a release/demo-readiness requirement.

## Recommended implementation priority

### P0 - required for owner demo

1. Freeze the unresolved business rules: personal/business tax scope and supported tax year/jurisdiction, owner's income basis, allocation balance context, and annual contribution timing.
2. Complete authenticated active-business context and business-owned backend storage/query for categories, deposits, and expenses. Separate real records from seed data.
3. Make Mindee scanning secure in release, persist scans through the API, prove receipt and handwriting behavior against agreed samples, and validate on a phone and iPad.
4. Finish the P&L owned-data chain and approved tax-estimate rule.
5. Build Personal Employee, then Personal Owner aggregation on the shared business/data foundation.
6. Build the six-bucket allocation planner and Retirement calculator.
7. Make the complete demo regression suite green and record scripted end-to-end acceptance evidence.

### P1 - important

1. Build the management backend's authorization/status/audit foundation before exposing account-management pages.
2. Deliver portal sign-in, dashboard, hierarchy, accounts, detail/status, and audit pages.
3. Add Admin/Moderator assignments, permissions, consent, step-up, notification, and finance-support workspaces.
4. Add portal Payroll and Investment/Tax-Saving workspaces after their shared domain rules are approved.

### P2 - polish

1. Improve camera copy, empty/error/retry states, accessibility semantics, large-screen/tablet layout, and visual consistency.
2. Add telemetry with redaction, demo reset/seed tooling that is explicitly labeled, and operational runbooks.
3. Expand device/browser matrices and performance testing for large transaction, account, hierarchy, audit, and payroll lists.

## Additional development estimate

### Estimating basis

All prices below are **additional USD labor only**. The approximately **$20,000 already paid is treated as payment for the implementation already present and is not included in, credited against, or re-estimated in any row below**.

The estimate uses a junior-level developer planning rate of **$25-$40/hour**, with a **$30/hour base case**. This is consistent with the current public market signal that Upwork lists typical Flutter hiring at $18-$39/hour, while the U.S. Bureau of Labor Statistics reports a much higher overall U.S. software-developer wage benchmark. The upper end is appropriate when a junior is expected to cover Flutter, web, AWS/backend, security, OCR integration, and financial calculations rather than Flutter UI alone.

Pricing references:

- [Upwork Flutter developer hiring guide](https://www.upwork.com/hire/flutter-freelancers/)
- [U.S. Bureau of Labor Statistics - Software Developers](https://www.bls.gov/ooh/computer-and-information-technology/software-developers.htm)

Ranges include junior-developer implementation time, code review fixes, automated tests, integration, and ordinary rework. They assume requirements are frozen, current source access remains available, an approved UI direction exists, and no major rewrite of already working screens is requested.

### A. Remaining owner-demo scope

Only missing work and integration gaps are priced here.

| Additional work | Junior hours | What the estimate adds (not existing work) |
| --- | ---: | --- |
| Authenticated data foundation | 120-180 | Concrete API adapter, active-business wiring, owned category/transaction models, migration/seed separation, remote persistence/query, and integration tests. |
| Scan Expense completion | 80-140 | Secure release Mindee path, backend save/linkage, failure states, receipt/handwriting acceptance, and phone/iPad testing. Existing capture/review/mapping UI is excluded. |
| P&L completion | 70-120 | Active-business data integration, real business identity, approved versioned tax estimate, disclosures, and API E2E tests. Existing statement UI/grouping is excluded. |
| Personal - Employee | 120-180 | New personal ledger/history, paycheck link, year/date UI, owned storage, and approved personal-tax calculation. |
| Personal - Owner | 80-130 | Working multi-business membership/list, income-basis aggregation, transfer/deduplication rules, Personal UI, and tax integration. |
| Asset & Liability allocation plan | 45-70 | Six-bucket calculator, 100%/rounding rules, required display, owned balance integration, and tests. Existing Saving/Liability screens are excluded. |
| Retirement calculator | 24-40 | Annual compound-interest domain logic, route/screen, validation, responsiveness, and tests. |
| Demo hardening and acceptance | 100-150 | Fix relevant regressions, full-suite/device/browser testing, end-to-end scripts, security/error checks, and release configuration. |
| **Owner-demo subtotal** | **639-1,010** | **About 16-25 full-time developer weeks.** |

Cost result:

- Optimistic: **639 hours x $25 = $15,975**
- Base planning case: **825 hours x $30 = $24,750**
- Conservative: **1,010 hours x $40 = $40,400**

### B. Management/admin portal, incremental after the demo foundation

This section is deliberately incremental after Section A, so shared identity/business/transaction foundation is not counted twice.

| Additional work | Junior hours | What the estimate adds |
| --- | ---: | --- |
| Portal shell, authentication, recovery, responsive/a11y framework | 80-130 | Management-specific web shell and role/inactive/unauthorized states. |
| Dashboard, hierarchy, accounts, detail/status, audit pages | 180-280 | Complete query/filter/pagination/URL/error behavior and status workflows. |
| Admin, Moderator, consent, step-up, and notification workspaces | 180-280 | Restricted workflows and client enforcement matching server decisions. |
| Payroll and Investment/Tax-Saving portal workspaces | 120-200 | Web adaptations and missing portal flows; existing mobile payroll code is not repriced. |
| Management-specific backend and security | 260-420 | Models/APIs, hierarchy authorization, assignments/grants/consent, audits, Cognito status sync/reconciliation, documents/PDFs, notifications, and idempotency. |
| Portal QA, security tests, accessibility, deployment | 160-260 | Cross-role/cross-organization attack tests, browser coverage, performance, operational checks, and deployment. |
| **Management/admin subtotal** | **980-1,570** | **About 25-39 full-time developer weeks after Section A.** |

Cost result:

- Optimistic: **980 hours x $25 = $24,500**
- Base planning case: **1,275 hours x $30 = $38,250**
- Conservative: **1,570 hours x $40 = $62,800**

### Combined additional cost

| Scenario | Additional hours | Additional junior labor | Approx. one-developer duration at 40 hours/week |
| --- | ---: | ---: | ---: |
| Optimistic | 1,619 | $40,475 | 41 weeks |
| Base planning case | 2,100 | **$63,000** | 53 weeks |
| Conservative | 2,580 | $103,200 | 65 weeks |

**Recommended planning figure: approximately $63,000 of new junior-developer labor**, released by milestones rather than as one fixed-price commitment. At the base case, total historical project spend would become approximately **$83,000** ($20,000 already paid + $63,000 new); the new request itself remains $63,000.

A prudent contract should re-estimate after the authenticated data foundation and tax-rule decisions. Those two milestones retire the largest uncertainty before the portal and Personal features consume it.

### Completed work explicitly excluded from the new estimate

The estimate does not charge again for the implementation already present, including:

- Existing Cognito authentication/onboarding UI and account-profile flows.
- Existing business profile and category-selection screens/local repositories.
- Existing expense/deposit entry, transaction, reminder, liabilities, savings, payroll, and home-budget screens.
- Existing Scan Expense camera/review UI, Mindee request/polling implementation, and field mapping.
- Existing local transaction CRUD, P&L statement/grouping/totals, current tax-reserve logic, report/export helpers, and related tests.
- Existing shared styling, navigation shell, responsive widgets, formatters, and test infrastructure.
- The new remote `/me` and business DTO/repository contract scaffolding already in the worktree.

Only the missing features, production/demo integrations, security/ownership corrections, management portal, and necessary validation are priced.

### Exclusions and risk note

The dollar ranges exclude Mindee/AWS usage charges, domains/certificates, App Store/Play fees, design/redesign, data entry, tax/legal advice, formal compliance certification, penetration testing vendors, and post-launch operations/support.

Although the requested costing uses junior labor, the tax, privacy, authorization, Cognito administration, and immutable-audit portions should receive senior security/architecture review and qualified tax-domain review before production use. Those reviewer fees are not included above. Assigning final tax or security authority solely to a junior developer would create avoidable product risk.

## Decisions required before implementation

1. What exact tax calculation is required for business P&L and Personal, for which tax year, jurisdiction, and filing statuses?
2. For Owner Personal, does business income mean deposits, P&L net profit, owner distributions/draws, or another approved tax basis?
3. Is the allocation plan Personal or business scoped, and what exact balance/date range supplies “available amount”?
4. Is the Retirement additional contribution annual, and is it applied at the beginning or end of each year?
5. What representative handwritten documents and minimum field accuracy constitute acceptance for Mindee?
6. Should the management portal use this Flutter web codebase or a separate frontend? This estimate assumes a responsive Flutter web portal to maximize reuse.

Implementation should not begin until these decisions and this audit are reviewed.
