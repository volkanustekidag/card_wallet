# BANK & IBAN CARD WALLET

The application has been developed so that you can manage your bank and iban card information. Data is stored locally in encrypted form. At the same time, extra security is provided with pin input. You can add your bank card information and see the back and front sides of your cards with animation and specify the color. While adding your IBAN cards, you can scan them with your camera without having to write IBAN.

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

## Plugins

[flutter_bloc](https://pub.dev/packages/flutter_bloc) <br>
[hive](https://pub.dev/packages/hive) <br>
[equatable](https://pub.dev/packages/equatable) <br>
[easy_localization](https://pub.dev/packages/easy_localization) <br>
[sizer](https://pub.dev/packages/sizer) <br>
[flutter_iban_scanner](https://pub.dev/packages/flutter_iban_scanner) <br>
[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) <br>
[pin_code_fields](https://pub.dev/packages/pin_code_fields) <br>
[flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) <br>
[flip_card](https://pub.dev/packages/flip_card) <br>
[apple_passkit](https://pub.dev/packages/apple_passkit) <br>





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
