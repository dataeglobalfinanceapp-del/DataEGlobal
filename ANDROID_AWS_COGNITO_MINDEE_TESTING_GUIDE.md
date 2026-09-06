# Android Singapore Cognito/API + Mindee Testing Guide

## Normal daily startup

The app now selects its existing Cognito environment from compile-time values. Singapore DEV is the API-connected development target; the legacy `us-west-2` pool remains available only as a rollback option.

Do not run `ampx generate outputs`, `ampx sandbox`, or any AWS create/delete command during normal startup.

```powershell
Set-Location 'E:\DataEglobal\Save_Tep'

flutter devices
$androidDeviceId = Read-Host 'Android device ID'

flutter run -d $androidDeviceId `
  --dart-define-from-file='.run/dev.local.json'
```

At login, use a Cognito username or email. For the existing DEV account, enter `demo-owner` and type `<TEST_PASSWORD>` only in the app. Never put a password in the JSON file, command line, shell history, tests, documentation, or Git.

Normal Flutter startup does not require an AWS CLI profile, AWS access key, or local backend process.

## One-time local configuration

Create the ignored launch file from the committed example:

```powershell
Copy-Item '.run\dev.example.json' '.run\dev.local.json'
```

Edit `.run/dev.local.json` and replace these placeholders:

- `<DISPLAYED_TERMS_VERSION>` with the exact terms version shown to users;
- `<PRIVATE_LOCAL_TEST_API_KEY>` with the private debug-only Mindee key;
- `<EXPENSE_MODEL_ID>` and `<DEPOSIT_MODEL_ID>` with the current private Mindee model IDs.

The committed Singapore configuration already identifies:

- Region `ap-southeast-1`;
- API `https://api-dev.save-tep.us`;
- User Pool `ap-southeast-1_3ob6DVAln`;
- mobile app client `2dkdkbefs65ipd52egvfve23gu`.

These identifiers are public configuration, not credentials. Never add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, a Cognito password, or a bearer token to the launch file. Dart defines are compiled into the application.

Do not pass the repository's complete `.env` file to Flutter. It may contain developer-only AWS variables that must never enter a mobile build.

## Validate before device testing

```powershell
dart format .
flutter analyze
flutter test
```

Check the deployed API without authentication:

```powershell
$health = Invoke-RestMethod 'https://api-dev.save-tep.us/health'
$health.status
```

Expected value: `ok`.

## Authentication smoke test

1. Launch the app with `.run/dev.local.json`.
2. Enter `demo-owner` and `<TEST_PASSWORD>` in the UI.
3. If Cognito requests an SMS, email, or TOTP code, enter it in the additional sign-in field.
4. Confirm the app resolves `/me` and `/me/active-business` before entering authenticated screens.
5. If no active business exists and the account has exactly one business, confirm the app selects it automatically.
6. Leave the app open beyond the 15-minute access-token lifetime and confirm a later API read succeeds after session refresh.
7. Sign out and confirm returning to the login screen does not show data from the prior account.

Request logs may contain only method, route template, status, duration, and a safe request ID. They must not contain passwords, access/ID tokens, query values, PII bodies, Mindee keys, or presigned URLs.

## Mindee expense test

Mindee continues to run directly from the Flutter debug build. This integration does not enable Textract.

1. Open the automatic Expense scan flow and allow camera access.
2. Capture a clear, complete receipt.
3. Confirm the image remains visible while extraction runs.
4. Confirm Mindee fills the supported supplier, date/time, total, tip, category, and card-last-four fields.
5. Correct uncertain values and verify the reviewed values remain in the form.

Do not use the SaveTep scan-job persistence route until the backend publishes a Mindee-client/attachment flow that does not start backend OCR. Expense and receipt migration remains contract-gated.

## Mindee deposit test

1. Open Deposit and choose automatic extraction.
2. Capture or select a clear deposit image.
3. Confirm the amount/payment fields are populated and remain editable.
4. Confirm the order number stays owned by the current Flutter form; the API does not document automatic sequencing.
5. Correct uncertain values and verify the reviewed values remain in the form.

Do not distribute an APK containing the Mindee key. Direct Mindee credentials are permitted only for private local debug testing.

## Legacy rollback test

The old pool is not deleted or regenerated. Copy `.run/legacy.example.json` to the ignored `.run/legacy.local.json`, replace only the Mindee placeholders, and run:

```powershell
flutter run -d '<ANDROID_DEVICE_ID>' `
  --dart-define-from-file='.run/legacy.local.json'
```

Legacy mode keeps the current local repositories and does not construct the REST client. Switching pools signs users out and does not migrate Cognito passwords or subject IDs.

## Safe shutdown

1. Stop `flutter run` with `q` or `Ctrl+C`.
2. Close the emulator if desired.
3. Remove any temporary AWS profile variables from the shell if they were used for separate read-only inspection.

Do not delete Cognito, ECS, the load balancer, database, Redis, S3, Amplify, or API data as part of shutdown.

For architecture, mapping, migration, and contract gates, see `docs/integration/`.
