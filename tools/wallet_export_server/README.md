# Wallet Export Server

Small signing server for Card Wallet loyalty-card exports.

The Flutter app calls:

- `POST /v1/wallet/loyalty/apple`
- `POST /v1/wallet/loyalty/google`

The server returns `{ "launchUrl": "..." }`. iOS downloads the signed
`.pkpass` URL and presents it in-app with `apple_passkit`; Android opens
Google's Save to Wallet URL.

Production Cloud Run endpoint:

```text
https://cardwallet-wallet-export-134457105597.europe-west1.run.app
```

## Run

```sh
export WALLET_EXPORT_HOST=127.0.0.1
export WALLET_EXPORT_PORT=8080
export WALLET_PUBLIC_BASE_URL=https://wallet-api.example.com

# Production default is App Check hard enforcement. For local legacy curl
# testing only, set APP_CHECK_REQUIRED=false and provide WALLET_EXPORT_API_KEY.
export APP_CHECK_REQUIRED=true
export FIREBASE_PROJECT_ID=cardwallet-495118

# Optional tuning:
export WALLET_RATE_LIMIT_MAX=30           # requests per IP per window
export WALLET_RATE_LIMIT_WINDOW=60        # window in seconds
export WALLET_PASS_TTL_SEC=86400          # delete generated .pkpass after this
export WALLET_PASS_CLEANUP_INTERVAL_SEC=600

python3 tools/wallet_export_server/server.py
```

Build the app with the same base URL:

```sh
flutter run \
  --dart-define=WALLET_EXPORT_BASE_URL=https://wallet-api.example.com
```

The app also supports:

```sh
flutter run --dart-define-from-file=.dart_defines/wallet.local.env
```

## Apple Wallet

Required environment:

```sh
export APPLE_PASS_TYPE_ID=pass.com.example.cardwallet.loyalty
export APPLE_TEAM_ID=ABCDE12345
export APPLE_ORG_NAME="Card Wallet"
export APPLE_SIGNER_CERT_PATH=/secure/pass-cert.pem
export APPLE_SIGNER_KEY_PATH=/secure/pass-key.pem
export APPLE_SIGNER_KEY_PASSPHRASE=optional
export APPLE_WWDR_CERT_PATH=/secure/wwdr.pem
export APPLE_ICON_PATH=/secure/icon.png
export APPLE_LOGO_PATH=/secure/logo.png
```

Current production values:

```sh
export APPLE_PASS_TYPE_ID=pass.com.volkan.cardwallet.loyalty
export APPLE_TEAM_ID=FXWKZB775S
export APPLE_ORG_NAME="Card Wallet"
```

Supported Apple barcode formats are `QR_CODE` and `CODE_128`. Other retail
barcode formats are rejected instead of being silently converted, because a
visual conversion can fail at checkout scanners.

## Google Wallet

Required environment:

```sh
export GOOGLE_SERVICE_ACCOUNT_PATH=/secure/google-service-account.json
export GOOGLE_WALLET_ISSUER_ID=3388000000020000000
export GOOGLE_WALLET_CLASS_SUFFIX=cardwallet_loyalty
export GOOGLE_WALLET_ORIGINS=https://wallet-api.example.com
```

Optional environment:

```sh
export GOOGLE_WALLET_ISSUER_NAME="Card Wallet"
export GOOGLE_WALLET_PROGRAM_NAME="Card Wallet Loyalty"
export GOOGLE_WALLET_HOMEPAGE_URL=https://example.com
export GOOGLE_WALLET_LOGO_URL=https://wallet-api.example.com/assets/google-logo.png
export GOOGLE_LOGO_PATH=/secure/google-logo.png
export GOOGLE_WALLET_AUTO_CREATE_CLASS=false
```

Current production values:

```sh
export GOOGLE_WALLET_ISSUER_ID=3388000000023114775
export GOOGLE_WALLET_CLASS_SUFFIX=cardwallet_loyalty
export GOOGLE_WALLET_ISSUER_NAME="Card Wallet"
export GOOGLE_WALLET_PROGRAM_NAME="Card Wallet Loyalty"
export GOOGLE_WALLET_LOGO_URL=https://www.olkan.dev/apps/cardwallet-icon.png
```

By default, the server expects the loyalty class to exist in Google Pay &
Wallet Console. Set `GOOGLE_WALLET_AUTO_CREATE_CLASS=true` only when the
service account is already authorized for REST class management. The class ID is:

```text
${GOOGLE_WALLET_ISSUER_ID}.${GOOGLE_WALLET_CLASS_SUFFIX}
```

The service account must be authorized in Google Wallet Business Console and
the Wallet Objects API must be enabled in the Google Cloud project.

Supported Google barcode formats are `QR_CODE`, `CODE_128`, `CODE_39`,
`EAN_13`, `EAN_8`, `UPC_A`, and `ITF` only when the value is 14 digits.

## Cloud Run

The repository root `Dockerfile` builds this server, not the Flutter app.

Project:

```text
cardwallet-495118
```

Region:

```text
europe-west1
```

Required secrets:

```text
apple-pass-key
apple-pass-cert
apple-wwdr
apple-icon
apple-logo
google-wallet-service-account
```

Deploy/update:

```sh
SERVICE_URL="https://cardwallet-wallet-export-134457105597.europe-west1.run.app"

gcloud run deploy cardwallet-wallet-export \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --min-instances 0 \
  --max-instances 1 \
  --memory 256Mi \
  --cpu 1 \
  --set-env-vars "APP_CHECK_REQUIRED=true,FIREBASE_PROJECT_ID=cardwallet-495118,WALLET_PUBLIC_BASE_URL=${SERVICE_URL},APPLE_PASS_TYPE_ID=pass.com.volkan.cardwallet.loyalty,APPLE_TEAM_ID=FXWKZB775S,APPLE_ORG_NAME=Card Wallet,APPLE_SIGNER_KEY_PATH=/secrets/apple-pass-key/pass-key.pem,APPLE_SIGNER_CERT_PATH=/secrets/apple-pass-cert/pass-cert.pem,APPLE_WWDR_CERT_PATH=/secrets/apple-wwdr/wwdr.pem,APPLE_ICON_PATH=/secrets/apple-icon/icon.png,APPLE_LOGO_PATH=/secrets/apple-logo/logo.png,GOOGLE_SERVICE_ACCOUNT_PATH=/secrets/google-wallet-service-account/google-service-account.json,GOOGLE_WALLET_ISSUER_ID=3388000000023114775,GOOGLE_WALLET_CLASS_SUFFIX=cardwallet_loyalty,GOOGLE_WALLET_ISSUER_NAME=Card Wallet,GOOGLE_WALLET_PROGRAM_NAME=Card Wallet Loyalty,GOOGLE_WALLET_LOGO_URL=https://www.olkan.dev/apps/cardwallet-icon.png,GOOGLE_WALLET_ORIGINS=${SERVICE_URL}" \
  --update-secrets "/secrets/apple-pass-key/pass-key.pem=apple-pass-key:latest,/secrets/apple-pass-cert/pass-cert.pem=apple-pass-cert:latest,/secrets/apple-wwdr/wwdr.pem=apple-wwdr:latest,/secrets/apple-icon/icon.png=apple-icon:latest,/secrets/apple-logo/logo.png=apple-logo:latest,/secrets/google-wallet-service-account/google-service-account.json=google-wallet-service-account:latest" \
  --quiet
```

Smoke test:

In production, POST endpoints require a valid Firebase App Check token from the
mobile app. Test the full flow from an installed release or debug build
(debug token whitelisted in Firebase Console). The legacy API-key curl path is
only for local/staging runs with `APP_CHECK_REQUIRED=false`.

Legacy local/staging curl example:

```sh
API_KEY="$(gcloud secrets versions access latest --secret=wallet-export-api-key)"
SERVICE_URL="https://cardwallet-wallet-export-134457105597.europe-west1.run.app"

curl -X POST "$SERVICE_URL/v1/wallet/loyalty/apple" \
  -H "Content-Type: application/json" \
  -H "X-CardWallet-Api-Key: $API_KEY" \
  -d '{"id":"smoke-apple","name":"Smoke Loyalty","brand":"Card Wallet","barcode":"123456789012","barcodeFormat":"CODE_128"}'

curl -X POST "$SERVICE_URL/v1/wallet/loyalty/google" \
  -H "Content-Type: application/json" \
  -H "X-CardWallet-Api-Key: $API_KEY" \
  -d '{"id":"smoke-google","name":"Smoke Loyalty","brand":"Card Wallet","barcode":"123456789012","barcodeFormat":"CODE_128"}'
```

Security controls:

- `APP_CHECK_REQUIRED=true` is the production default; POST endpoints accept
  only requests carrying a Firebase App Check token verified by Firebase Admin.
- `WALLET_EXPORT_API_KEY` is a legacy local/staging fallback only when
  `APP_CHECK_REQUIRED=false`. API key comparison uses `hmac.compare_digest`.
- Per-IP rate limit: 30 POSTs per 60 seconds, sliding window. The client IP
  is taken from `X-Forwarded-For` (Cloud Run injects it) and falls back to
  the socket peer in dev. Defaults are tunable via env.
- Request body is hard-capped at 10KB before reading from the socket, so a
  spoofed `Content-Length: 1000000000` can't exhaust memory.
- Generated `.pkpass` files are TTL'd (24h default) by a daemon thread so
  `/tmp/cardwallet-passes/` doesn't grow without bound.
- Error logs print exception **type only** — payloads contain loyalty
  barcodes and must not land in stdout/stderr or Cloud Logging.
- Client (`wallet_pass_export_service.dart`) refuses to launch any URL that
  isn't `https://pay.google.com/...` (Google) or the configured
  `WALLET_EXPORT_BASE_URL` host (Apple `.pkpass`).
- Secrets are mounted from Secret Manager and are not copied into the image.
- Cloud Run is limited to `min-instances=0` and `max-instances=1`.
- Keep `.dart_defines/` and all certificate/key material out of git.
