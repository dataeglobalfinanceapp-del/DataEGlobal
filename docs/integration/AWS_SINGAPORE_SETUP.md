# AWS Singapore Developer Setup

## Scope

This is the planned developer setup for connecting the Flutter app to the existing SaveTep DEV environment in Singapore. It separates one-time configuration from normal daily startup.

Do not run AWS creation/deletion commands from this guide. The target resources already exist.

## Verified DEV values

| Setting | Value |
|---|---|
| AWS Region | `ap-southeast-1` |
| API base URL | `https://api-dev.save-tep.us` |
| API deployment | Singapore Application Load Balancer; health reports database and Redis up |
| Cognito User Pool name | `save-tep-dev` |
| Cognito User Pool ID | `ap-southeast-1_3ob6DVAln` |
| Cognito mobile app client | `save-tep-dev-mobile` |
| Cognito app client ID | `2dkdkbefs65ipd52egvfve23gu` |
| Cognito issuer | `https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_3ob6DVAln` |
| API token type | Cognito access token (`token_use=access`) |
| Access/ID token lifetime | 15 minutes |
| Refresh token lifetime | 30 days |
| Cognito Identity Pool | None; not required for the REST API |
| Development username | `demo-owner` |
| Development password | `<TEST_PASSWORD>`; enter interactively only |

The User Pool and app client identifiers are configuration, not credentials. The password, Mindee key, AWS access keys, session tokens, and presigned URLs are secrets.

## Important current-state warning

The Flutter app currently imports `lib/amplify_outputs.dart`, which points to `us-west-2`. A separate root `amplify_outputs.json` also points to `us-west-2` but contains different pool/client IDs. Running the old `ampx generate outputs` command in `ANDROID_AWS_COGNITO_MINDEE_TESTING_GUIDE.md` will continue to regenerate the old-region configuration.

Until Phase 1 of the integration is implemented, the short Singapore startup below is a target procedure, not a claim that the current code already consumes the new settings.

Do not overwrite the current working configuration or delete the old pool during planning.

## Normal daily startup

Use this after Phase 1 adds `AppEnvironment` and runtime Amplify Auth configuration.

```powershell
Set-Location 'E:\DataEglobal\Save_Tep'

flutter devices
$androidDeviceId = Read-Host 'Android device ID'

flutter run -d $androidDeviceId `
  --dart-define-from-file='.run/dev.local.json'
```

At login, use `demo-owner` and enter `<TEST_PASSWORD>` manually. Never add the password to the launch command, shell history, a JSON file, source code, Markdown, logs, tests, or Git.

Normal Flutter startup must not require an AWS CLI profile or AWS access keys. The mobile app authenticates with Cognito and calls the API with an access token.

## One-time AWS and local configuration

### 1. Preserve the current configuration

Before changing Flutter code:

- record which ignored `lib/amplify_outputs.dart` is currently used;
- keep the old `us-west-2` User Pool running;
- do not run `ampx sandbox`, `ampx sandbox delete`, `create-user-pool`, or `delete-user-pool`;
- do not deploy `amplify/backend.ts` to try to adopt the Singapore pool;
- plan rollback through an environment/repository switch, not resource deletion.

The Singapore pool is tagged as OpenTofu-managed. Infrastructure changes belong in its owning infrastructure repository and review process.

### 2. Verify the existing target resources with read-only commands

Use an approved AWS CLI profile or SSO session. Do not load long-lived AWS keys into the Flutter runtime.

```powershell
$env:AWS_PROFILE = '<APPROVED_AWS_PROFILE>'
$env:AWS_REGION = 'ap-southeast-1'

aws sts get-caller-identity

aws cognito-idp describe-user-pool `
  --region ap-southeast-1 `
  --user-pool-id ap-southeast-1_3ob6DVAln

aws cognito-idp describe-user-pool-client `
  --region ap-southeast-1 `
  --user-pool-id ap-southeast-1_3ob6DVAln `
  --client-id 2dkdkbefs65ipd52egvfve23gu

aws cognito-idp admin-get-user `
  --region ap-southeast-1 `
  --user-pool-id ap-southeast-1_3ob6DVAln `
  --username demo-owner `
  --query '{Username:Username,Enabled:Enabled,UserStatus:UserStatus}'
```

Expected test-user status: enabled and `CONFIRMED`. These commands never require or reveal the user's password.

Verify the API separately:

```powershell
$health = Invoke-RestMethod 'https://api-dev.save-tep.us/health'
$health.status
```

Expected value: `ok`.

### 3. Add the planned runtime environment layer

Implement a validated `AppEnvironment` with these inputs:

- `APP_ENV`
- `API_BASE_URL`
- `AWS_REGION`
- `COGNITO_USER_POOL_ID`
- `COGNITO_USER_POOL_CLIENT_ID`
- `COGNITO_ISSUER_URL`
- `TERMS_VERSION`
- the three existing Mindee local-test values

For DEV, validate that the API URL uses HTTPS, the Region is `ap-southeast-1`, and the pool/issuer Region matches. Fail startup with a safe configuration message when values are missing or inconsistent.

Build the Amplify Auth JSON from the validated configuration. The target auth portion is equivalent to:

```json
{
  "auth": {
    "user_pool_id": "ap-southeast-1_3ob6DVAln",
    "aws_region": "ap-southeast-1",
    "user_pool_client_id": "2dkdkbefs65ipd52egvfve23gu"
  },
  "version": "1.4"
}
```

Do not add an `identity_pool_id`; the target environment has no Identity Pool and the REST API does not require AWS credentials from the device.

Keep a reversible `AUTH_ENV=legacy|singapore-dev` switch until end-to-end acceptance. The default must not change to Singapore until the new flow passes tests.

### 4. Create an ignored local launch file

During Phase 1:

1. Add `.run/*.local.json` to `.gitignore`.
2. Commit only a safe `.run/dev.example.json` with placeholders.
3. Create `.run/dev.local.json` locally and never commit it.

The local file shape should be:

```json
{
  "APP_ENV": "dev",
  "API_BASE_URL": "https://api-dev.save-tep.us",
  "AWS_REGION": "ap-southeast-1",
  "COGNITO_USER_POOL_ID": "ap-southeast-1_3ob6DVAln",
  "COGNITO_USER_POOL_CLIENT_ID": "2dkdkbefs65ipd52egvfve23gu",
  "COGNITO_ISSUER_URL": "https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_3ob6DVAln",
  "TERMS_VERSION": "<DISPLAYED_TERMS_VERSION>",
  "MINDEE_V2_API_KEY": "<PRIVATE_LOCAL_TEST_API_KEY>",
  "MINDEE_EXPENSE_MODEL_ID": "<EXPENSE_MODEL_ID>",
  "MINDEE_DEPOSIT_MODEL_ID": "<DEPOSIT_MODEL_ID>"
}
```

Never put `<TEST_PASSWORD>` or a real password in this file. Also never include `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, or `AWS_SESSION_TOKEN`; passing them through `--dart-define-from-file` would compile them into the app.

The repository's current `.env` contains AWS and Mindee variable names. Do not pass the whole file to Flutter. Move AWS developer authentication to a named profile/SSO and use only the ignored, narrowly scoped Flutter launch file.

### 5. Update the login/session behavior

The Singapore pool uses a Cognito username and an email alias. The current UI label and validator require an email, which prevents `demo-owner` from reaching Cognito.

Implement:

- a `USERNAME OR EMAIL` field;
- non-empty username/email validation rather than email-only validation on sign-in;
- existing email validation on sign-up;
- multi-step sign-in handling for optional MFA;
- session restoration through Amplify;
- access-token retrieval through the Cognito plugin;
- one forced refresh and retry on API `401`;
- cache clearing and return to login when refresh fails.

The API request header must be:

```http
Authorization: Bearer <COGNITO_ACCESS_TOKEN>
```

Do not send the Cognito ID token. Do not store tokens in LocalStore; Amplify owns secure token storage and refresh.

### 6. Provision the API user and active business

After sign-in:

1. `GET /me` using the access token.
2. On the first authenticated request after registration, send `X-Terms-Version` with the version the user actually accepted.
3. `GET /me/active-business`.
4. If no active business exists, `GET /businesses`, create one if onboarding requires it, then `PUT /me/active-business` with the selected server ID.
5. Store only the active business ID in a short-lived authenticated cache and invalidate it on sign-out/business switch.

Do not use email, business name, or a local generated ID as the API `businessId`.

## Android testing

### Existing platform prerequisites

The main Android manifest already declares:

- `android.permission.INTERNET`
- `android.permission.CAMERA`
- camera hardware as optional

Both Cognito and the API use HTTPS, so no cleartext traffic exception is required. The app currently uses application ID `com.example.savetep`; changing that is a separate release task.

### DEV smoke test

1. Run `dart format .`, `flutter analyze`, and `flutter test`.
2. Start an emulator or connect a physical Android device with USB debugging.
3. Launch with the normal daily startup command.
4. Sign in as `demo-owner` using `<TEST_PASSWORD>` entered in the UI.
5. Confirm `GET /me` and active-business resolution succeed.
6. Confirm request logs show only method, route, status, duration, and safe request ID. They must not show tokens, passwords, PII bodies, Mindee keys, or presigned URLs.
7. Leave the app open past the 15-minute access-token lifetime and verify Amplify refreshes the session.
8. Verify a controlled `401` does not create a retry loop.
9. Test airplane/offline mode and confirm user input remains recoverable.
10. Test one disposable API record only after the relevant contract gate is complete; delete it by its returned server ID.

### Mindee test

Mindee remains direct from Flutter for private debug testing. The SaveTep API must persist the reviewed values and receipt relationship.

- Do not enable Textract.
- Do not distribute an APK containing the Mindee key.
- Do not call the SaveTep OCR callback route from Flutter.
- Do not use the SaveTep scan job flow until the backend confirms how a Mindee-client extraction avoids the backend OCR pipeline.

## Cognito migration and rollback

Switching User Pools changes the issuer and Cognito `sub`, signs out existing sessions, and does not transfer passwords.

Before changing the default:

- confirm account/business ownership mapping for legacy users;
- decide how local profiles and category selections keyed by the old Cognito user ID will migrate;
- validate sign-up, confirmation, password recovery, optional MFA, sign-out, global sign-out, and token refresh;
- verify the API rejects the ID token and accepts the access token;
- keep the old configuration selectable for rollback.

Rollback means selecting the legacy auth/data environment and preserving both datasets for reconciliation. It does not mean deleting the Singapore pool, the old pool, or API data.

## Safe shutdown

Normal shutdown is only:

1. stop `flutter run` with `q` or `Ctrl+C`;
2. close the emulator if desired;
3. remove temporary AWS environment variables from the shell if they were used for one-time inspection.

Do not delete Cognito, ECS, load-balancer, database, Redis, S3, or Amplify resources as part of daily shutdown.

