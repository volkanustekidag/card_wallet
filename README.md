# Card Wallet

Flutter app for storing credit cards, IBANs and loyalty cards on the device.
Card data lives in AES-encrypted Hive boxes whose keys sit in the
Keychain / Android Keystore; there is no account and no cloud sync. An
optional PIN (plus Face ID / fingerprint for Premium) locks the app, and the
lock comes back after the app has been in the background (Settings ›
Security › Auto-lock).

Platforms: iOS 15.5+ (with a home/lock-screen widget and an Apple Watch app)
and Android 7+ (home-screen widget and a Quick Settings tile). UI in 9
languages: en, tr, de, fr, es, pt-BR, it, nl, pl.

## Architecture

- **State / DI / routing:** [GetX](https://pub.dev/packages/get) —
  controllers in `lib/feature/*/controller`, app-wide services registered in
  `lib/core/router/getx_bindings.dart` and `main.dart`.
- **Storage:** Hive (`lib/core/data/local_services`), keys in
  `flutter_secure_storage` (`SecureStorageProvider`).
- **Translations:** easy_localization, JSON files in `assets/docs/lang/`.
  Every key must exist in all 9 files (`test/translations_test.dart`).
- **Purchases:** `in_app_purchase` (`PremiumService`); the last verified
  entitlement is cached for 72 h.
- **Surfaces outside the app:** `WalletSurfacesSync` pushes loyalty cards to
  the widget / quick tile (`home_widget`) and the Watch (`WatchSyncService`).
- **Firebase:** Crashlytics, Analytics and App Check (for the wallet export
  backend only).

## Setup

1. Flutter stable (CI uses 3.41.5).
2. Create `lib/core/constants/keys.dart` (gitignored). For development you
   can start from the template:

   ```sh
   cp lib/core/constants/keys.example.dart lib/core/constants/keys.dart
   ```

   **Release builds must use the real `keys.dart`.** It names the encrypted
   Hive boxes and their secure-storage keys; different values make every
   existing user's wallet look empty.
3. Install dependencies: `flutter pub get`
4. Optional: wallet export settings in `.dart_defines/` (see below).
5. Run: `flutter run` (or `flutter run --dart-define-from-file=.dart_defines/wallet.local.env`).

## Tests

```sh
flutter analyze
flutter test
```

GitHub Actions (`.github/workflows/ci.yml`) runs the same steps on every
push to `main` and on pull requests, with `keys.example.dart` copied to
`keys.dart`.

## Release

```sh
tools/release_build.sh android   # AAB
tools/release_build.sh ios       # IPA
tools/release_build.sh both
```

- Builds are obfuscated; symbol files go to `symbols/<version>/` — back them
  up per release or Crashlytics stack traces can't be decoded.
- The version comes from `pubspec.yaml`. The iOS script first runs
  `tools/sync_ios_versions.rb` (needs the `xcodeproj` gem) so the widget and
  Watch targets carry the same version/build number as the app.
- Pass extra dart-defines with `DART_DEFINES="--dart-define=..."`.

## Wallet Export

Loyalty cards can be exported to Apple Wallet and Google Wallet.

- iOS uses a signed `.pkpass` from the Wallet Export API and presents it in-app with `apple_passkit`.
- Android opens the Google Wallet Save URL returned by the same API.
- Apple signing certificates and Google service account JSON are not stored in the mobile app. They live in Google Secret Manager and are mounted into the Cloud Run service.

Current Cloud Run endpoint:

```text
https://cardwallet-wallet-export-134457105597.europe-west1.run.app
```

Local Flutter runs should use a gitignored dart-define file:

```text
.dart_defines/wallet.local.env
```

Expected local file contents:

```env
WALLET_EXPORT_BASE_URL=https://cardwallet-wallet-export-134457105597.europe-west1.run.app
```

The production wallet export server is protected by Firebase App Check
(App Attest on iOS, Play Integrity on Android). Debug builds use the App Check
debug provider; whitelist the printed debug token in Firebase Console before
testing Wallet export locally. Do not ship `WALLET_EXPORT_API_KEY` in mobile
builds.

Create/update it with:

```sh
mkdir -p .dart_defines
printf 'WALLET_EXPORT_BASE_URL=https://cardwallet-wallet-export-134457105597.europe-west1.run.app\n' > .dart_defines/wallet.local.env
chmod 600 .dart_defines/wallet.local.env
```

Run from VS Code with:

```text
Card Wallet (Wallet API)
```

or from terminal:

```sh
flutter run --dart-define-from-file=.dart_defines/wallet.local.env
```

See [tools/wallet_export_server/README.md](tools/wallet_export_server/README.md) for Cloud Run deploy and secret configuration.

## Screenshots
| Splash             |  Auth | Home             |
:-------------------------:|:-------------------------:|:-------------------------:
![](https://i.hizliresim.com/e3dolsq.png)  |  ![](https://i.hizliresim.com/i94rrz2.png) |   ![](https://i.hizliresim.com/aaqk3hs.png) | 

| IBAN Cards             |  Credit Cards | Settings             |
:-------------------------:|:-------------------------:|:-------------------------:
![](https://i.hizliresim.com/hoth1ng.png)  |  ![](https://i.hizliresim.com/82646cg.png) |   ![](https://i.hizliresim.com/t319fcl.png) | 

| Add IBAN Cards             |  Add Credit Cards | Change PIN             |
:-------------------------:|:-------------------------:|:-------------------------:
![](https://i.hizliresim.com/jgxp7xl.png)  |  ![](https://i.hizliresim.com/p3lw8xk.png) |   ![](https://i.hizliresim.com/f3klygw.png) | 
