# Android AWS Cognito + Mindee Local Testing Guide

This is the current source of truth for private local Android testing:

- AWS Amplify Gen 2 and Cognito handle authentication in `us-east-1`.
- Mindee V2 handles expense and deposit OCR directly from Flutter.
- AWS Textract is no longer used.
- No local OCR backend or service on port `3000` is required.
- Direct Mindee credentials are for private local testing only. Never commit
  them or distribute a build that contains them.

The legacy files `E:\DataEglobal\ANDROID_MINDEE_TESTING_GUIDE.md` and
`E:\DataEglobal\SaveTep_AWS_Testing_Shutdown_Startup_Procedure.md` are
obsolete. Do not follow their older Region or OCR instructions.

## Prerequisites

- Project: `E:\DataEglobal\Save_Tep`
- AWS CLI profile: `savetep-amplify`
- AWS Region: `us-east-1`
- Flutter SDK, Android Studio, Android SDK, Node.js, and the AWS CLI installed
- A private Mindee V2 API key plus the current expense and deposit model IDs

Never save a real password, API key, model ID, or User Pool ID in Git.

## 1. Configure and verify AWS

Open PowerShell and set the profile's default Region to `us-east-1`:

```powershell
Set-Location 'E:\DataEglobal\Save_Tep'

aws configure set region us-east-1 `
  --profile savetep-amplify
```

Verify the identity and Region:

```powershell
aws sts get-caller-identity `
  --profile savetep-amplify

aws configure get region `
  --profile savetep-amplify
```

The Region command must print `us-east-1`.

If Amplify warns that both `AWS_PROFILE` and static AWS credential environment
variables are set, keep the named profile and clear only the current
PowerShell process variables before deployment:

```powershell
Remove-Item Env:AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
```

Run `aws sts get-caller-identity --profile savetep-amplify` again afterward.

## 2. Create or update the Amplify sandbox

Restore the Node dependencies, deploy to the profile's `us-east-1` Region, and
regenerate `lib\amplify_outputs.dart`:

```powershell
npm.cmd ci
```

Wait for `npm.cmd ci` to finish successfully before running the next command.
Do not copy PowerShell's `>>` continuation prompts; they are not command text.

```powershell
npx.cmd ampx sandbox `
  --identifier mercu `
  --profile savetep-amplify `
  --once `
  --outputs-format dart `
  --outputs-out-dir lib
```

Do not edit `lib\amplify_outputs.dart` by hand. If the sandbox was previously
deployed in a different Region, this command creates or updates the sandbox in
`us-east-1` and writes the current Cognito configuration.

## 3. Load and verify the current Cognito pool

Parse the JSON object inside the generated Dart raw string, then load both the
pool ID and its Region:

```powershell
$amplifyOutput = Get-Content `
  -Path '.\lib\amplify_outputs.dart' `
  -Raw

$jsonStart = $amplifyOutput.IndexOf('{')
$jsonEnd = $amplifyOutput.LastIndexOf('}')

if ($jsonStart -lt 0 -or $jsonEnd -le $jsonStart) {
  throw 'No Amplify JSON object was found in amplify_outputs.dart.'
}

$amplifyConfig = $amplifyOutput.Substring(
  $jsonStart,
  $jsonEnd - $jsonStart + 1
) | ConvertFrom-Json

$userPoolId = $amplifyConfig.auth.user_pool_id
$awsRegion = $amplifyConfig.auth.aws_region

if ([string]::IsNullOrWhiteSpace($userPoolId)) {
  throw 'No Cognito User Pool ID was found in amplify_outputs.dart.'
}

if ([string]::IsNullOrWhiteSpace($awsRegion)) {
  throw 'No Cognito Region was found in amplify_outputs.dart.'
}

Write-Host "Current Cognito User Pool ID: $userPoolId"
Write-Host "Current Cognito Region: $awsRegion"

if ($awsRegion -ne 'us-east-1') {
  throw "Expected us-east-1 but amplify_outputs.dart uses $awsRegion."
}
```

Verify that the generated pool actually exists in its generated Region:

```powershell
aws cognito-idp describe-user-pool `
  --user-pool-id $userPoolId `
  --profile savetep-amplify `
  --region $awsRegion `
  --query 'UserPool.{Name:Name,Status:Status}'
```

If this reports `ResourceNotFoundException` immediately after a successful
deployment, the sandbox's CloudFormation outputs may refer to a Cognito pool
that was deleted outside CloudFormation. Re-running the unchanged deployment
does not repair that drift. Delete and recreate this test sandbox:

```powershell
npx.cmd ampx sandbox delete `
  --identifier mercu `
  --profile savetep-amplify `
  --yes

npx.cmd ampx sandbox `
  --identifier mercu `
  --profile savetep-amplify `
  --once `
  --outputs-format dart `
  --outputs-out-dir lib
```

Then reload `$userPoolId` and `$awsRegion` from the new output and run
`describe-user-pool` again. Sandbox deletion removes all remaining resources in
that sandbox and cannot be undone; use it only for the disposable test sandbox.

## 4. Create or verify the Cognito test user

Set the test username locally:

```powershell
$testUsername = 'ace@gmail.com'
```

Check whether it exists:

```powershell
aws cognito-idp admin-get-user `
  --user-pool-id $userPoolId `
  --username $testUsername `
  --profile savetep-amplify `
  --region $awsRegion `
  --query '{Enabled:Enabled,Status:UserStatus}'
```

If AWS reports `UserNotFoundException`, create it using placeholders only:

```powershell
aws cognito-idp admin-create-user `
  --user-pool-id $userPoolId `
  --username $testUsername `
  --temporary-password 'Chuot299!' `
  --user-attributes `
    "Name=email,Value=ace@gmail.com" `
    "Name=email_verified,Value=true" `
  --message-action SUPPRESS `
  --profile savetep-amplify `
  --region $awsRegion
```

Set a permanent test-only password:

```powershell
aws cognito-idp admin-set-user-password `
  --user-pool-id $userPoolId `
  --username $testUsername `
  --password 'Chuot299!' `
  --permanent `
  --profile savetep-amplify `
  --region $awsRegion
```

Replace placeholders only in your local terminal. Never put a real password in
this file, source code, screenshots, or chat. If a password has been exposed,
do not reuse it; set a new permanent password.

Run `admin-get-user` again and confirm the user is enabled and `CONFIRMED`.

## 5. Load the local Mindee environment

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

## 6. Validate Flutter

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

## 7. Start Android and launch Flutter

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

## 8. Log in with Cognito

1. Open SaveTep on the Android device.
2. Log in with `<TEST_USER_EMAIL>` and the new permanent test password.
3. Confirm that the app reaches its authenticated home screen.

If login fails, verify that the app was built with the latest generated
`lib\amplify_outputs.dart`, then rerun `describe-user-pool` and
`admin-get-user` with `--region $awsRegion`.

## 9. Test expense Mindee scanning

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

## 10. Test deposit Mindee scanning

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

## 11. Verify there is no local OCR request

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

## 12. Shutdown and cleanup

1. Press `q` or `Ctrl+C` in the Flutter terminal.
2. Stop the emulator or disconnect the physical phone.
3. Clear local Mindee process variables:

```powershell
Remove-Item Env:MINDEE_V2_API_KEY -ErrorAction SilentlyContinue
Remove-Item Env:MINDEE_EXPENSE_MODEL_ID -ErrorAction SilentlyContinue
Remove-Item Env:MINDEE_DEPOSIT_MODEL_ID -ErrorAction SilentlyContinue
```

4. When the AWS test environment is no longer needed, delete the `us-east-1`
   Amplify sandbox:

```powershell
npx.cmd ampx sandbox delete `
  --profile savetep-amplify
```

Sandbox deletion removes its Cognito User Pool and test users. Do not delete
the shared `CDKToolkit` bootstrap stack during normal cleanup. Delete the local
`.env` file and revoke the private Mindee key when the machine should no longer
retain them.
