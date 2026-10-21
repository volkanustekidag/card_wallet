# Card Wallet 2.1.0 (44) — Yayın checklist'i

Sıra: **1. Build → 2. Cihaz testleri → 3. Konsol → 4. Kademeli yayın → 5. 7 günlük izleme.** Bir adımda sorun çıkarsa sonraki adıma geçme.

İlgili dosyalar: [whats_new.md](whats_new.md) · [listing.md](listing.md) · [privacy_declarations.md](privacy_declarations.md)

---

## 1. Build

Ana checkout'ta (`~/card_wallet`), `main` güncel ve bu PR merge edilmiş olmalı.

- [ ] `git pull` → `grep '^version' pubspec.yaml` çıktısı `2.1.0+44` olmalı.
- [ ] `lib/core/constants/keys.dart` gerçek anahtarlarla duruyor (gitignored).
- [ ] `.dart_defines/wallet.local.env` içinde **yalnızca** `WALLET_EXPORT_BASE_URL=https://cardwallet-wallet-export-134457105597.europe-west1.run.app` var. `WALLET_EXPORT_API_KEY` **olmamalı** (production yetkilendirmesi App Check ile yapılıyor).
- [ ] `flutter clean && flutter pub get && (cd ios && pod install)`
- [ ] Android:
  ```sh
  DART_DEFINES="--dart-define-from-file=.dart_defines/wallet.local.env" tools/release_build.sh android
  ```
- [ ] iOS (script `sync_ios_versions.rb`'yi kendisi çalıştırıyor; pbxproj'da diff çıkmamalı, çünkü bu PR'da zaten 44'e eşitlendi):
  ```sh
  DART_DEFINES="--dart-define-from-file=.dart_defines/wallet.local.env" tools/release_build.sh ios
  ```
- [ ] **Sembolleri yedekle:** `symbols/2.1.0+44/android` ve `symbols/2.1.0+44/ios` → özel depolama (`symbols-2.1.0+44/`). Bunlar olmadan obfuscated Crashlytics stack trace'leri çözülemez.
- [ ] Crashlytics'e sembolleri yükle:
  - Android: `firebase crashlytics:symbols:upload --app=<android app id> symbols/2.1.0+44/android`
  - iOS: Xcode Organizer'daki dSYM'i yükle (ya da `upload-symbols`) ve `symbols/2.1.0+44/ios` için de aynı komutu çalıştır.
- [ ] Dart-define'ın binary'ye girdiğini kontrol et (0 çıkarsa Wallet export "yapılandırılmamış" hatası verir):
  ```sh
  unzip -p build/app/outputs/bundle/release/app-release.aab base/lib/arm64-v8a/libapp.so | strings | grep -c 'europe-west1.run.app'   # ≥1 olmalı
  ```
- [ ] Reklam kimliği izinlerinin AAB'de olmadığını kontrol et: Play Console › App bundle explorer › 44 › **Permissions**. `com.google.android.gms.permission.AD_ID`, `ACCESS_ADSERVICES_AD_ID` ve `ACCESS_ADSERVICES_ATTRIBUTION` listede olmamalı. (Bu PR'da `:app:processReleaseMainManifest` ile doğrulandı: üçü de REJECTED.)

## 2. Yayın öncesi cihaz testleri

PR #6 ve #7'deki "Cihazda doğrulanacak" listeleri tek listede birleştirildi, tekrar edenler çıkarıldı. Bu PR'a ait maddeler **(2.1)** ile işaretli. Test için mümkünse release build kullan (TestFlight / Play internal testing). Kilit, App Check ve parlaklık davranışı debug build'de farklı olabilir.

### Açılış ve veri (PR #7)
- [ ] iOS simülatör: kart ekle → `xcrun simctl keychain <device> reset` (Hive dosyaları kalsın) → app splash'te donmadan açılıyor. "Kartların bu cihazda güvende" mesajı **bir kez** çıkıyor, cüzdan boş, yeni kart eklenebiliyor. PIN varsa PIN ekranı gelmiyor.
- [ ] Bu mesajdaki "Yedekten geri yükle": premium değilse paywall, premiumsa restore akışı açılıyor.
- [ ] Gerçek iCloud restore (mümkünse): eski yedekte Hive dosyaları olduğu için yetim kutu yolu çalışıyor.
- [ ] Ayarlar › [ad] › iCloud › Depolamayı Yönet › Yedekler › bu cihaz: Card Wallet boyutu Hive dosyalarını içermiyor. Ya da `xattr -l` çıktısında `com.apple.metadata:com_apple_backup_excludeItem` görünüyor.
- [ ] Cihaz kilitliyken (ilk unlock öncesi) arka planda başlatma: BootErrorPage açılıyor, kilit açılıp app öne gelince kendiliğinden toparlanıyor.
- [ ] Android: normal açılış ve kart listesi (regresyon). Keystore hatası simüle edilebiliyorsa BootErrorPage ve home retry.
- [ ] `AppDelegate.swift` değişikliği iOS release build'de derleniyor (backup exclusion kanalı).

### Kilit ve gizlilik (PR #6)
- [ ] PIN açık, 30 sn'den uzun arka plan → kilit açılıyor ve aynı ekrana dönülüyor. "Hemen" seçeneği çalışıyor. PIN kapalıyken kilit yok.
- [ ] Face ID istemi, kamera/galeri, paylaşım sheet'i, satın alma, Wallet'a ekleme, ayarlar/tarayıcı: 1 dk içinde dönünce yanlış kilit yok, 1 dk'dan uzun kalınca kilit açılıyor.
- [ ] Widget'tan kilitliyken açılan sadakat kartı salt-okunur (yalnızca barkod + isim + "Uygulamayı aç").
- [ ] iOS app switcher'da kart içeriği görünmüyor (UIScene overlay).
- [ ] Pano: iOS'ta 60 sn sonra (uygulama suspend olsa bile) pano boş ve Universal Clipboard'a gitmiyor. Android 13+'ta önizlemede gizli (`EXTRA_IS_SENSITIVE`).
- [ ] Biyometrik hata durumları (kilitlenme, iptal, bilinmeyen): yalnızca çevrilmiş mesaj, ham exception yok.

### Kart girişi ve barkod (PR #6)
- [ ] Parlaklık: barkod sayfası/sheet açılınca parlaklık tam ve ekran açık. Kapanınca ve ayar kapalıyken eski hâlinde.
- [ ] Amex / Diners / 19 haneli kart OCR'ı gerçek kartla.
- [ ] Camera paketi kaldırıldıktan sonra IBAN (metin + QR), kredi kartı ve sadakat kartı kamera taramaları çalışıyor. Android'de kamera izni istemi çıkıyor.

### Dil (PR #6)
- [ ] 9 dilde kamera, Face ID ve fotoğraf izin pop-up'ları doğru dilde.
- [ ] iOS widget ve Watch metinleri her dilde doğru. Android widget ve Quick Settings tile metinleri doğru.
- [ ] Bildirimler: TR/DE vb. dilde açılışta ve dil değişiminden sonra `pendingNotificationRequests` başlık/gövdeleri doğru dilde, ham anahtar yok, tarih formatı yerel.

### Premium, yedek, Wallet (PR #6)
- [ ] Ücretli kullanıcı cold start'ta kilit (paywall) görmüyor. Uçak modunda premium korunuyor.
- [ ] Android'de plan değişimi tek abonelik bırakıyor. Ask to Buy → "Onay bekleniyor".
- [ ] Yedek: Android'de `.json` seçilebiliyor, v1.0 yedekte uyarı çıkıyor, büyük yedekte UI donmuyor.
- [ ] Android widget, Quick Settings tile ve `EXTRA_IS_SENSITIVE` pano davranışı cihazda.
- [ ] **(2.1)** Release build'de Apple Wallet ve Google Wallet'a ekleme çalışıyor. Bu, App Check'in (App Attest / Play Integrity) production'da token ürettiğini ve backend'in kabul ettiğini gösterir.

### Analytics ve reklam kimliği (2.1)
- [ ] **(2.1)** Firebase › DebugView (`-FIRDebugEnabled` / `adb shell setprop debug.firebase.analytics.app com.volkan.wallet_app`): `barcode_shown`, `card_added`, `paywall_viewed` geliyor. IDFV kapatıldıktan sonra da olaylar akıyor.
- [ ] **(2.1)** iOS'ta ilk açılışta ATT ("izlemeye izin ver") istemi **çıkmıyor**.

## 3. Konsol adımları

### Google Play Console
- [ ] **App content › Ads:** "No, my app does not contain ads". Mağazadaki "Contains ads" etiketi bu beyanla kalkar.
- [ ] **App content › Advertising ID:** "No". AD_ID izni artık yok, bu cevapla tutarlı.
- [ ] **App content › Data safety:** [privacy_declarations.md §1](privacy_declarations.md#1-google-play--data-safety). Şu an "No data collected" yazıyor, bu yanlış.
- [ ] **App content › Content rating:** anketi yeniden doldur ([§3.2](privacy_declarations.md#32-google-play--app-content--content-rating-iarc)). Hedef PEGI 3 / Everyone.
- [ ] **App content › Target audience:** 18+. **Financial features:** "none of these".
- [ ] **Main store listing › Manage translations:** 9 dil için title, short ve full description ([listing.md](listing.md)). Kategori aynı kalsın.
- [ ] **Release › Production › Create release:** AAB 44, release notes ([whats_new.md](whats_new.md), Play blokları).
- [ ] Privacy policy URL'i `https://olkan.dev/privacy/cardwallet` ve **güncellenmiş** metin yayında ([§4](privacy_declarations.md#4-olkandevprivacycardwallet--gereken-düzeltmeler)).

### App Store Connect
- [ ] **App Information › Localizations:** **Dutch, Polish, Portuguese (Brazil)** dillerini ekle (mevcut: TR primary, EN-US, FR, DE, IT, PT-PT, ES). PT-PT için iki seçenek var: pt-BR metnini kopyala ya da eski metni bırak.
- [ ] Her dil için Name, Subtitle (App Information) + Keywords, Promotional Text, Description, What's New (2.1.0 sürümü).
- [ ] **App Privacy:** [§2](privacy_declarations.md#2-app-store--app-privacy). Tracking: No.
- [ ] **Age Rating:** anketi yeniden doldur ([§3.1](privacy_declarations.md#31-app-store-connect--app-information--age-rating)). Hedef 4+ (şu an 16+).
- [ ] **Version Release:** "Release this version over a 7-day period using phased release" **açık**, "Automatically release" ya da "Manually release" (hangisini tercih edersen).
- [ ] Review notes: Premium özelliklerini test etmek için sandbox hesabı. Wallet export, App Attest nedeniyle reviewer cihazında çalışmalı; çalışmazsa notta bunu açıkla.

### Firebase / Google Analytics / Cloud
- [ ] **Cloud Run `cardwallet-wallet-export`:** `APP_CHECK_REQUIRED=true` olmalı.
  ```sh
  gcloud run services describe cardwallet-wallet-export --region europe-west1 \
    --format='value(spec.template.spec.containers[0].env)' | tr ';' '\n' | grep APP_CHECK_REQUIRED
  ```
  Ayrıca `WALLET_EXPORT_API_KEY` env'i **tanımlı olmamalı** ya da artık kullanılmamalı.
- [ ] **Firebase › App Check:** iOS (App Attest) ve Android (Play Integrity) uygulamaları kayıtlı. Play Integrity için Play Console'daki **app signing key SHA-256** Firebase'e eklenmiş. Debug token'lar production'a karışmamış.
- [ ] **GA › Admin › Data sharing settings:** "Google products & services" ve "Modeling contributions & business insights" kapalı. **Google signals** kapalı. Google Ads bağlantısı yok. (Data safety'deki "Shared: No" ve App Privacy'deki "Tracking: No" cevapları buna bağlı.)
- [ ] **GA › Admin › Data retention:** gizlilik politikasına yazılan süreyle aynı (öneri: 2 ay).

## 4. Kademeli yayın

| | Google Play | App Store |
|---|---|---|
| Başlangıç | **%20 staged rollout** | **Phased release** (Apple'ın 7 günlük planı: %1 → 2 → 5 → 10 → 20 → 50 → 100). Not: phased release yalnızca otomatik güncellemeleri etkiler; elle güncelleyen ve yeni indiren herkes hemen alır |
| 48 saat izleme | Aşağıdaki eşikler | Aynı eşikler |
| Sorun yoksa | %100'e çıkar | "Release to All Users" |
| Sorun varsa | **Halt rollout** → düzelt → 45 | **Pause phased release** (30 güne kadar) → düzelt → 2.1.1 (45) |

**48 saatlik durdurma eşikleri** (biri aşılırsa durdur, sonra incele):
- Crashlytics **crash-free users < %99.5** ya da 2.0.0'ın son 7 gün ortalamasının 0,5 puandan fazla altında.
- Play Vitals: **user-perceived crash rate ≥ %1,09** veya **user-perceived ANR rate ≥ %0,47** (Play'in "bad behavior" eşikleri).
- Crashlytics'te 2.1.0'a özgü yeni bir crash cluster, kullanıcıların %0,5'inden fazlasında.
- Non-fatal `boot_failed` / `boot_storage_unavailable` (BootErrorPage) yaşayan kullanıcı sayısı, 2.1.0 aktif kullanıcılarının %0,1'inden fazla.
- Non-fatal `orphan_box_*` görünmesi **beklenen** bir durum (2.1 öncesi iCloud yedeğinden restore). Sayı yüksekse bilgi amaçlıdır, durdurma sebebi değildir. Ama `orphan_box_*` Android'de görünüyorsa durdur (Android'de yedek yok, bu bir hata olur).
- `purchase_failed / paywall_plan_selected` oranı 2.0.0'ın iki katından fazla.
- `wallet_export_failed / wallet_export_attempt > %20` (App Check sorunu işareti).

## 5. Yayından sonraki 7 gün — metrikler (Firebase)

Her gün aynı saatte, **yalnızca app_version = 2.1.0** filtresiyle bak. 2.0.0'da da var olan metrikler için 2.0.0'ın yayın öncesi son 7 gününü baseline al. `barcode_shown` 2.1'de yeni bir olay; ilk 7 gün baseline olacak.

| Metrik | Tanım (GA4 / Crashlytics) | Hedef / yorum |
|---|---|---|
| **Barkod kullanımı** | `barcode_shown` event count ÷ active users (günlük). `source` parametresine göre böl (`detail_page`, `detail_sheet`, `widget`) | Baseline. Asıl değer ölçüsü bu: kasada kart gösteriliyor mu? Widget payı yükseliyorsa widget'ı öne çıkarmaya değer |
| **İlk kart oranı** | Exploration › Funnel (open, **1 gün içinde**): `first_open` → `card_added`. `card_type`'a göre böl | 2.0.0 baseline'ının altına düşmemeli. Düşerse onboarding/izin akışına bak |
| **Paywall → satın alma** | Funnel: `paywall_viewed` → `paywall_plan_selected` → `purchase_success`. `trigger` (`card_limit`, `feature_gate`, `direct`) ve `feature` parametresine göre böl | Baseline ile karşılaştır. `premium_gate_tapped {feature}` hangi özelliğin daha çok satın aldırdığını gösterir |
| **Crash-free users** | Crashlytics › 2.1.0 | ≥ %99,5 ve 2.0.0'dan kötü değil |
| ANR (Android) | Play Vitals › user-perceived ANR rate | < %0,47 |
| Destek sinyalleri | `boot_failed`, `boot_storage_unavailable`, `orphan_box_*` non-fatal sayıları. Mağaza yorumları (yeni dillerde) | Trend izle |

7. günün sonunda kısa bir not yaz: 4 ana metrik, baseline'a göre fark, bir sonraki sürüm için tek öncelik. Bir sonraki iş, bu sonuca göre seçilecek tek konu olsun.
