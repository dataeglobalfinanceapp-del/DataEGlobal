# Android AWS Cognito + Mindee Local Testing Guide

## Quick startup - copy one block at a time

### 1. Open the project and configure this PowerShell process

```powershell
Set-Location 'E:\DataEglobal\Save_Tep'

$awsRegion = 'us-west-2'
$permanentBackendStackName = 'amplify-savetep-teres-sandbox-b788042c3d'

$env:AWS_PROFILE = 'savetep-amplify'
$env:AWS_REGION = $awsRegion

Remove-Item Env:AWS_DEFAULT_REGION -ErrorAction SilentlyContinue
Remove-Item Env:AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
```

### 2. Load the existing AWS backend configuration

```powershell
npx.cmd ampx generate outputs --stack $permanentBackendStackName --profile savetep-amplify --format dart --out-dir lib

if ($LASTEXITCODE -ne 0) {
  throw 'Output generation failed. Do not run ampx sandbox.'
}
```

### 3. Load Mindee credentials

```powershell
Get-Content '.env' | ForEach-Object {
  $line = $_.Trim()
  if ($line -and -not $line.StartsWith('#')) {
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2) {
      [Environment]::SetEnvironmentVariable(
        $parts[0].Trim(),
        $parts[1].Trim(),
        'Process'
      )
    }
  }
}
```

### 4. Select Android and start Flutter

```powershell
flutter devices
$androidDeviceId = Read-Host 'Android device ID'

flutter run -d $androidDeviceId `
  --dart-define=MINDEE_V2_API_KEY=$env:MINDEE_V2_API_KEY `
  --dart-define=MINDEE_EXPENSE_MODEL_ID=$env:MINDEE_EXPENSE_MODEL_ID `
  --dart-define=MINDEE_DEPOSIT_MODEL_ID=$env:MINDEE_DEPOSIT_MODEL_ID
```

This is the current source of truth for private local Android testing:

- AWS Amplify Auth uses the existing permanent Cognito User Pool in
  `us-west-2`.
- The permanent User Pool is shared infrastructure. Local testing must never
  create, recreate, or delete it.
- Mindee V2 handles expense and deposit OCR directly from Flutter.
- AWS Textract is no longer used.
- No local OCR backend or service on port `3000` is required.
- Direct Mindee credentials are for private local testing only. Never commit
  them or distribute a build that contains them.

The legacy files `E:\DataEglobal\ANDROID_MINDEE_TESTING_GUIDE.md` and
`E:\DataEglobal\SaveTep_AWS_Testing_Shutdown_Startup_Procedure.md` are
obsolete. Do not follow their older Region or OCR instructions.

## One-time prerequisites

- Project: `E:\DataEglobal\Save_Tep`
- Working AWS CLI profile: `savetep-amplify`
- Existing permanent Amplify backend stack:
  `amplify-savetep-teres-sandbox-b788042c3d` in `us-west-2`
- Flutter SDK, Android Studio, Android SDK, Node.js, and the AWS CLI installed
- Node dependencies already installed with `npm.cmd ci`
- A private Mindee V2 API key plus the current expense and deposit model IDs

Never save a real password, API key, or private model ID in Git. Keep Cognito
identifiers together only in the approved Amplify output files; do not copy
them into this guide or hard-code them elsewhere in the app.

## Startup behavior and AWS safety

The Quick startup blocks are the complete normal startup procedure for this
PC. The AWS profile, permanent pool, app client, test user, and stack mapping
are already configured and do not need to be verified again.

`ampx generate outputs` reads the existing deployed backend and writes only
`lib\amplify_outputs.dart`. It does not deploy AWS resources. Never substitute
`ampx sandbox`, `ampx sandbox delete`, `create-user-pool`, or
`delete-user-pool` during startup or cleanup.

## 1. Configure the local Mindee environment once

Create an ignored `.env` file in the project root:

```dotenv
MINDEE_V2_API_KEY=<PRIVATE_LOCAL_TEST_API_KEY>
MINDEE_EXPENSE_MODEL_ID=<EXPENSE_MODEL_ID>
MINDEE_DEPOSIT_MODEL_ID=<DEPOSIT_MODEL_ID>
```

Load it into the PowerShell process that will run Flutter:

```powershell
Get-Content '.env' | ForEach-Object {
  $line = $_.Trim()
  if ($line -and -not $line.StartsWith('#')) {
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2) {
      [Environment]::SetEnvironmentVariable(
        $parts[0].Trim(),
        $parts[1].Trim(),
        'Process'
      )
    }
  }
}
```

Verify presence without printing the values:

```powershell
[pscustomobject]@{
  MindeeApiKeySet = -not [string]::IsNullOrWhiteSpace(
    $env:MINDEE_V2_API_KEY
  )
  ExpenseModelIdSet = -not [string]::IsNullOrWhiteSpace(
    $env:MINDEE_EXPENSE_MODEL_ID
  )
  DepositModelIdSet = -not [string]::IsNullOrWhiteSpace(
    $env:MINDEE_DEPOSIT_MODEL_ID
  )
}
```

All three results must be `True`.

## 2. Optional Flutter validation

```powershell
flutter pub get
dart format .
flutter analyze

flutter test `
  test\mindee_document_analysis_service_test.dart `
  test\mindee_mappers_test.dart `
  test\scan_expense_auto_screen_widget_test.dart `
  test\scan_deposit_auto_screen_widget_test.dart

flutter test
```

Resolve relevant failures before device testing.

## 3. Android launch details

Start an Android emulator in Android Studio, or connect a physical phone with
USB debugging enabled. Then run:

```powershell
flutter devices

flutter run -d '<ANDROID_DEVICE_ID>' `
  --dart-define=MINDEE_V2_API_KEY=$env:MINDEE_V2_API_KEY `
  --dart-define=MINDEE_EXPENSE_MODEL_ID=$env:MINDEE_EXPENSE_MODEL_ID `
  --dart-define=MINDEE_DEPOSIT_MODEL_ID=$env:MINDEE_DEPOSIT_MODEL_ID
```

No backend URL or port argument is needed. Keep this build private because
compile-time Dart definitions can be recovered from an application binary.

## 4. Log in with Cognito

1. Open SaveTep on the Android device.
2. Log in with the existing test email and password.
3. Confirm that the app reaches its authenticated home screen.

If login unexpectedly fails, repeat Quick startup Steps 1 and 2 and rebuild the
app. Do not create, replace, or delete any Cognito resource while
troubleshooting.

## 5. Test expense Mindee scanning

1. Open the automatic expense scan flow and allow camera access.
2. Capture a clear, complete receipt.
3. Confirm the captured image remains visible during and after extraction.
4. Confirm Mindee fills supplier, date/time, total amount, tips/gratuity,
   purchase category, and card last four.
5. Correct any uncertain values, confirm the expense, and save it.
6. Confirm the Flutter console reports:

```text
[ScanExpense] Scan extraction completed successfully.
```

The expense model machine keys are:

```text
supplier_name
date
time
total_amount
tips_gratuity
purchase_category
card_last4
```

## 6. Test deposit Mindee scanning

1. Open the automatic deposit scan flow and note the generated order number.
2. Capture a clear, complete deposit image.
3. Confirm the captured image remains visible during and after extraction.
4. Confirm the generated order number is preserved; OCR must not replace it.
5. Confirm Mindee fills total amount, credit/debit amount, card last four, cash
   amount, gift-card amount, other amount, and transaction date.
6. Correct any uncertain values, confirm the deposit, and save it.
7. Confirm the Flutter console reports:

```text
[ScanDeposit] Scan extraction completed successfully.
```

The deposit model machine keys are:

```text
total_amount
credit_debit_amount
card_last4
cash_amount
gift_card_amount
other_amount
transaction_date
```

## 7. Verify there is no local OCR request

No process is required on port `3000`:

```powershell
Get-NetTCPConnection `
  -LocalPort 3000 `
  -State Listen `
  -ErrorAction SilentlyContinue
```

No output is expected. Android Studio's Network Inspector should show scan
requests going directly to Mindee HTTPS endpoints under `api-v2.mindee.net`,
with no request to a host-loopback address or port `3000`.

## 8. Shutdown and cleanup

1. Press `q` or `Ctrl+C` in the Flutter terminal.
2. Stop the emulator or disconnect the physical phone.
3. Clear local Mindee process variables:

```powershell
Remove-Item Env:MINDEE_V2_API_KEY -ErrorAction SilentlyContinue
Remove-Item Env:MINDEE_EXPENSE_MODEL_ID -ErrorAction SilentlyContinue
Remove-Item Env:MINDEE_DEPOSIT_MODEL_ID -ErrorAction SilentlyContinue
```

4. Clear the local startup variables without changing AWS resources:

```powershell
Remove-Variable awsRegion -ErrorAction SilentlyContinue
Remove-Variable permanentBackendStackName -ErrorAction SilentlyContinue
Remove-Variable androidDeviceId -ErrorAction SilentlyContinue
Remove-Item Env:AWS_PROFILE -ErrorAction SilentlyContinue
Remove-Item Env:AWS_REGION -ErrorAction SilentlyContinue
```

The permanent `us-west-2` Cognito User Pool remains running between test
sessions. Never run `ampx sandbox delete`, `delete-user-pool`, or a replacement
deployment during normal cleanup. Pool maintenance belongs to the backend
administrator and is not part of this guide.

Delete the local `.env` file and revoke the private Mindee key only when the
machine should no longer retain them.
