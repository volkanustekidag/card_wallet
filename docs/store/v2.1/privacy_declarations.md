# Card Wallet 2.1 — Gizlilik beyanları

Bu doküman kodu okuyarak hazırlandı (`origin/main` 0d92076 + bu PR). Her cevabın yanında hangi dosyadan çıkarıldığı yazıyor. SDK davranışı için Google'ın resmi açıklama sayfaları kullanıldı (en altta). Konsolda cevap verirken bu tabloları kullan. Kod değişirse burayı da güncelle.

## 0. Uygulamadan dışarı çıkan veri (envanter)

| Akış | Ne gidiyor | Nereye | Ne zaman | Kaynak |
|---|---|---|---|---|
| Firebase Analytics | Olaylar: `app_open`, `card_added {card_type}`, `barcode_shown {source}`, `scan_* {type, method}`, `paywall_*`, `purchase_* {product_id, value, currency}`, `wallet_export_* {provider, error_key}`, `backup_*`, `card_copied/shared {card_type, masked}`, `reminder_enabled {kind}`, `premium_gate_tapped {feature}`, ekran görüntülemeleri (route adı). Kullanıcı özellikleri: `is_premium`, kart sayıları, `has_pin`, `app_locale`, `days_since_install`. SDK otomatik olarak app instance ID, oturum/ekran olayları, in-app purchase olayları (ürün ID, fiyat) ve maskelenmiş IP'den türetilen kaba konum ekliyor | Google (Firebase) | Release build'de her zaman açık, uygulamada kapatma seçeneği yok | `lib/core/services/analytics_service.dart`, `lib/main.dart:130` |
| Firebase Crashlytics | Crash/non-fatal stack trace, uygulama durumu, cihaz modeli/OS, Crashlytics installation UUID. `reason` alanında yalnızca sabit etiketler var (ör. `initFirebase`, `orphan_box_<kutu>`) | Google (Firebase) | Release build'de açık | `lib/core/services/error_reporter.dart`, `lib/main.dart:111-129` |
| Firebase App Check | App Attest (iOS) / Play Integrity (Android) attestation token'ı, Firebase user agent | Google (Firebase) | Uygulama açılışında aktive ediliyor, token Wallet export isteğine ekleniyor | `lib/main.dart:104`, `wallet_pass_export_service.dart:_fetchAppCheckToken` |
| Firebase Installations | Firebase installation ID (FID), user agent | Google (Firebase) | Analytics/Crashlytics/App Check'in bağımlılığı | — |
| Google ML Kit (barkod + metin tanıma, bundled) | Cihaz modeli/OS, paket adı/sürüm, kurulum başına ID, gecikme metrikleri, olay türü. **Görüntü cihazdan çıkmıyor** (on-device model) | Google | Tarama yapıldığında | `google_mlkit_*` |
| Wallet export (Android → Google Wallet) | Seçilen **tek sadakat kartının** `id` (UUID), `name`, `brand`, `barcode`, `barcodeFormat`, `notes`, `logoAsset`, `createdAt`, `locale` ve renkleri. İstekle birlikte IP adresi de gidiyor (Cloud Run request log + bellekteki rate-limit tablosu) | Kendi backend'imiz (Cloud Run, `europe-west1`). Sunucu imzalı JWT'yi bellekte üretip geri döndürüyor, **diske yazmıyor**. Kullanıcı "Google Cüzdan'a ekle"ye bastığında veri Google Wallet'a geçiyor | Yalnızca kullanıcı "Google Cüzdan'a ekle"ye bastığında (Premium) | `wallet_pass_export_service.dart:_payload`, `server.py:create_google_save_url` |
| Wallet export (iOS → Apple Wallet) | Aynı alanlar | Kendi backend'imiz. İmzalı `.pkpass` `/tmp` altına (Cloud Run'da bellek içi dosya sistemi) yazılıyor, tahmin edilemez bir URL'den servis ediliyor ve **24 saate kadar** saklanıyor (`WALLET_PASS_TTL_SEC=86400`; instance kapanırsa daha erken siliniyor) | Yalnızca kullanıcı "Apple Cüzdan'a ekle"ye bastığında (Premium) | `server.py:create_apple_pass`, `PASS_TTL_SEC` |
| Satın alma | Satın alma işlemi App Store / Google Play üzerinden yapılıyor. Uygulama yalnızca mağazadan yetki durumunu soruyor; makbuz kendi sunucumuza **gitmiyor** | Apple / Google | Paywall, geri yükleme | `premium_service.dart` |
| Kredi kartı, IBAN, kart sahibi, CVV, PIN | **Hiçbir yere gitmiyor.** Bunlar Hive AES kutularında tutuluyor, anahtarlar Keychain/Keystore'da. iOS'ta iCloud yedeğine girmiyor (`hive_backup_exclusion.dart`), Android'de `allowBackup=false` | — | — | `encrypted_box_opener.dart`, `AndroidManifest.xml` |
| Yedek dosyası | PBKDF2 + AES ile şifrelenmiş, kullanıcının seçtiği yere (Dosyalar/paylaşım) kaydediliyor. Bize gelmiyor | Kullanıcının seçtiği yer | Kullanıcı yedek aldığında (Premium) | `backup_service.dart` |
| Hatırlatıcılar | Yerel bildirim. Push/FCM yok | — | — | `card_reminder_service.dart`, pubspec'te `firebase_messaging` yok |

Reklam yok: pubspec'te reklam SDK'sı yok. Bu PR'dan sonra:
- **Android:** `AD_ID`, `ACCESS_ADSERVICES_AD_ID` ve `ACCESS_ADSERVICES_ATTRIBUTION` merged manifest'ten çıkarıldı (`manifest-merger-release-report.txt` hepsini REJECTED gösteriyor), `google_analytics_adid_collection_enabled=false`.
- **iOS:** AdSupport linklenmiyor (Pods xcconfig'de ve Google binary'lerinin `LC_LINKER_OPTION` kayıtlarında yok; `GoogleAppMeasurement` yalnızca **AdServices**'i autolink ediyor), `NSUserTrackingUsageDescription` yok, yani ATT istemi hiç çıkmıyor, IDFA hiç okunamıyor. Bu PR ile IDFV toplama da kapatıldı, ad personalization sinyalleri de kapalı.

---

## 1. Google Play — Data safety

Play Console › App content › Data safety. Sorular formdaki sırayla.

### 1.1 Data collection and security

| Soru | Cevap | Neden |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | Analytics, Crashlytics, ML Kit ve Wallet export veriyi cihazdan dışarı gönderiyor |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | Firebase ve ML Kit TLS kullanıyor. Backend `https://…run.app`. Release build'de `WALLET_EXPORT_BASE_URL`'in `https://` olduğunu kontrol et (checklist) |
| Which of the following methods of account creation does your app support? | **My app does not allow users to create an account** | Hesap yok |
| Do you provide a way for users to request that their data is deleted? | **Yes** + gizlilik politikasındaki e-posta adresi | Kart verisi zaten cihazda (Ayarlar › Tüm verileri sil). Analytics/Crashlytics verisi için e-posta ile talep alınabilir, Firebase'de app instance ID ile silinebilir. Politikaya bu madde eklenmeli (bkz. §4) |

> "Independent security review" ve "UPI / Families" rozetleri: hayır / uygulanmaz.

### 1.2 Data types

Burada listelenmeyen her tür **Not collected** olarak işaretlenmeli.

| Kategori › Tür | Collected | Shared | Ephemeral | Required / Optional | Purposes | Kaynak |
|---|---|---|---|---|---|---|
| Location › **Approximate location** | Yes | No | No | Required | Analytics | GA, maskelenmiş IP'den şehir düzeyinde konum türetiyor. Konum izni yok |
| Financial info › **Purchase history** | Yes | No | No | Required | Analytics | `purchase_success {product_id, value, currency}` + GA'nın otomatik in-app purchase olayları |
| Financial info › **Other financial info** | Yes | No | **Yes** | **Optional** | App functionality | Wallet export (Android): sadakat kartı adı, üyelik/barkod numarası, notu. Sunucu bellekte işleyip saklamıyor. *Alternatif:* "App activity › Other user-generated content". Sadakat numarası finansal veri sayılmayabilir, ama muhafazakâr seçenek bu |
| App activity › **App interactions** | Yes | No | No | Required | Analytics | Olaylar, ekran görüntülemeleri, ML Kit olay türleri |
| App info and performance › **Crash logs** | Yes | No | No | Required | Analytics, App functionality | Crashlytics |
| App info and performance › **Diagnostics** | Yes | No | No | Required | Analytics, App functionality | Crashlytics cihaz/OS bilgisi, Firebase Sessions, ML Kit gecikme metrikleri |
| Device or other IDs › **Device or other IDs** | Yes | No | No | Required | Analytics, Fraud prevention, security, and compliance | App instance ID, FID, Crashlytics UUID, ML Kit kurulum ID'si. App Check güvenlik amaçlı. **Advertising ID değil**, o artık manifest'te yok |

**Not collected:**
- Personal info: ad, e-posta, telefon vb. Kart sahibi adı cihazdan çıkmıyor.
- Financial info › User payment info: kart numarası/CVV cihazdan çıkmıyor.
- Photos and videos: OCR on-device çalışıyor, fotoğraf `finally` bloğunda siliniyor.
- Audio, Contacts, Calendar, Messages, Health, Web browsing, Files and docs: yedek dosyası bize gelmiyor.

**Shared = No gerekçesi:** Firebase ve ML Kit, Google'ın service provider (veri işleyen) olarak çalıştığı servisler; Play tanımına göre bu "sharing" sayılmıyor. Google Wallet'a aktarım kullanıcının bilinçli olarak başlattığı bir işlem ("user-initiated transfer"), o da sharing sayılmıyor. **Koşul:** GA mülkünde *Admin › Data sharing settings* altında **"Google products & services"** ve **"Modeling contributions & business insights"** kapalı olmalı (bunlar açıkken Google veriyi kendi amaçları için kullanır, yani sharing sayılır). "Technical support" açık kalabilir. **Google signals** kapalı olmalı, Google Ads bağlantısı da olmamalı. Bunlardan biri açıksa "Shared" cevabı Yes olur (checklist'te kontrol adımı var).

### 1.3 Diğer App content formları

| Form | Cevap |
|---|---|
| **Ads** | **No, my app does not contain ads** (mevcut "Contains ads" etiketi bununla kalkar) |
| **Advertising ID** | **No** — uygulama reklam kimliği kullanmıyor; `AD_ID` izni bu sürümde merged manifest'ten çıkarıldı |
| Target audience and content | Hedef yaş: **18 ve üzeri** (kart/IBAN uygulaması, çocuklara yönelik değil, Families politikası dışında kalır) |
| Financial features | "My app doesn't provide any of these financial features" — ödeme, kredi, banka hesabı, kripto yok. Yalnızca kullanıcının girdiği kart bilgisini cihazda saklıyor |
| Health apps / Government apps / News | Hayır |

---

## 2. App Store — App Privacy

App Store Connect › App Privacy. `ios/Runner/PrivacyInfo.xcprivacy`'de `NSPrivacyTracking=false`; SDK'lar (Firebase, ML Kit) kendi privacy manifest'leriyle geliyor.

### 2.1 Tracking

**"Do you or your third-party partners use data for tracking purposes?" → No**

Doğrulama:
- [x] AdSupport linklenmiyor (bu PR'da kontrol edildi); `NSUserTrackingUsageDescription` yok, yani ATT istemi hiç gösterilmiyor ve IDFA her zaman sıfır.
- [x] `GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED=false`, `GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS=false` (bu PR).
- [x] Reklam SDK'sı yok, veri broker'ı yok, `setUserId` çağrısı yok.
- [ ] GA mülkünde Google signals **kapalı**, Google Ads bağlantısı **yok** (konsolda kontrol et).

### 2.2 Data types

Tümü: **Used for tracking: No**.

| Kategori › Tür | Linked to you | Purposes | Kaynak |
|---|---|---|---|
| Purchases › **Purchase History** | No | Analytics | Ürün ID + fiyat olayları |
| Location › **Coarse Location** | No | Analytics | GA, IP'den türetiyor. Konum izni yok |
| Identifiers › **Device ID** | No | Analytics, App Functionality | App instance ID / FID. IDFA ve IDFV yok |
| Usage Data › **Product Interaction** | No | Analytics | Olaylar, ekran görüntülemeleri |
| Diagnostics › **Crash Data** | No | App Functionality, Analytics | Crashlytics |
| Diagnostics › **Performance Data** | No | App Functionality, Analytics | Firebase Sessions, ML Kit gecikme |
| Diagnostics › **Other Diagnostic Data** | No | App Functionality, Analytics | Cihaz/OS meta verisi |
| User Content › **Other User Content** | No | App Functionality | Apple Wallet export: sadakat kartı adı, numarası, notu. İsteğe bağlı ve kullanıcı başlatıyor. Apple'ın "optional disclosure" istisnasına girebilir, ama mağaza metninde de anlattığımız için beyan etmek daha tutarlı |

**"Linked to you: No" gerekçesi:** Hesap yok, `setUserId` yok, IDFA/IDFV yok. Analytics yalnızca rastgele bir app instance ID ile ilişkilendiriyor (Google: "only associated with the app instance id" by default). *Muhafazakâr alternatif:* Device ID'yi "Linked" işaretlemek. Bu etiketi daha kötü gösterir ama yanlış da sayılmaz. Önerim "No".

**Not collected:** Contact Info, Health & Fitness, **Financial Info** (kart numaraları cihazdan çıkmıyor), Precise Location, Sensitive Info, Contacts, Emails or Text Messages, Photos or Videos, Audio Data, Gameplay Content, Customer Support, Browsing/Search History, Other Data.

---

## 3. Yaş derecelendirmesi

Şu an App Store'da 16+ görünüyor. Uygulamada bunu gerektiren bir şey yok, hedef **4+ / PEGI 3**.

### 3.1 App Store Connect › App Information › Age Rating

| Bölüm / Soru | Cevap | Neden |
|---|---|---|
| Parental Controls / Age Assurance | No / No | — |
| **Unrestricted Web Access** | **No** | Uygulama içinde WebView yok. Tüm bağlantılar `LaunchMode.externalApplication` ile Safari'de açılıyor (`settings_body.dart`, `premium_page.dart`, `boot_error_page.dart`, `rate_app_service.dart`, `loyalty_wallet_action.dart`) |
| **User-Generated Content** | **No** | Kullanıcılar arasında uygulama içi içerik paylaşımı yok. Paylaşım sistem share sheet'iyle yapılıyor |
| Messaging and Chat | No | — |
| **Advertising** | **No** | — |
| Mature/Suggestive Themes, Violence (cartoon/realistic/prolonged), Horror/Fear, Profanity/Crude Humor, Sexual Content/Nudity, Alcohol/Tobacco/Drugs, Medical/Treatment info, Health or Wellness topics | None | — |
| Simulated Gambling, Contests, Loot boxes / chance-based purchases | None / No | Abonelik var, şans unsuru yok |
| Made for Kids | No | — |
| **Beklenen sonuç** | **4+** | 16+ büyük olasılıkla eski ankette verilen "Unrestricted Web Access" ya da "User-Generated Content" cevabından geliyor. Anketi baştan doldur ve sonuç ekranında 4+ çıktığını doğrula |

### 3.2 Google Play › App content › Content rating (IARC)

| Soru | Cevap |
|---|---|
| Category | **All Other App Types** (Utility, Productivity, Communication or Other) |
| Violence, Fear, Sexuality, Language, Controlled substances, Crude humor, Gambling | No |
| Does the app natively allow users to interact or exchange content with other users? | **No** (sistem share sheet'i "native interaction" sayılmıyor) |
| Does the app share the user's current physical location with other users? | No |
| Does the app allow users to purchase digital goods? | **Yes** (abonelik). Sonuçta "In-App Purchases" etiketi çıkar |
| Is the app a web browser or search engine? | No |
| Does the app contain NFTs / blockchain-based rewards? | No |
| **Beklenen sonuç** | PEGI 3 · USK 0 · ESRB Everyone · IARC 3+, ek etiket "In-App Purchases" |

---

## 4. olkan.dev/privacy/cardwallet — gereken düzeltmeler

Mevcut metin (Last updated: April 5, 2026, 2026-10-21'de okundu) şunu söylüyor: *"CardWallet does not collect, store, or share any personal information"*, *"never transmitted to our servers or any third parties"*, *"does not use any third-party services that collect information used to identify you"*. Bu cümleler Analytics, Crashlytics ve Wallet export ile **çelişiyor**. Play Data safety ile App Privacy etiketini güncelledikten sonra bu metin olduğu gibi kalırsa inceleme ekipleri tutarsızlık görür (Play User Data politikası, App Store 5.1.1/5.1.2). Değişiklikler:

```diff
- Last updated: April 5, 2026
+ Last updated: <yayın tarihi>

  ## Information Collection and Use
- CardWallet does not collect, store, or share any personal information. The app
- is designed to respect your privacy and operates entirely on your device.
+ CardWallet has no accounts and shows no ads. The cards you add (credit cards,
+ IBANs, loyalty cards, card holder names, CVVs, notes) and your PIN are stored
+ only on your device. We never receive them, with one exception you trigger
+ yourself: Wallet export (see below).
+
+ To keep the app working and to understand how it is used, the app sends the
+ following to Google Firebase. None of it contains card numbers, IBANs,
+ barcodes or names:
+ - Usage events (for example "card added: loyalty", "barcode shown",
+   "paywall viewed", "purchase completed: product, price, currency"), screen
+   views, and settings such as the number of cards per type, whether a PIN is
+   set, Premium status and app language
+ - A random app-instance identifier and a Firebase installation identifier
+ - Approximate location (city level) that Google derives from a masked IP
+   address. The app never asks for location permission
+ - Crash reports: stack trace, device model, OS version and app version
+ - App integrity checks (Apple App Attest / Google Play Integrity) used to
+   protect the Wallet export service
+ Card scanning uses Google ML Kit on your device. Images never leave the
+ device. ML Kit sends anonymous performance and diagnostic data to Google.

  ## Data Storage
- All data created or managed within CardWallet is stored locally on your device
- in encrypted form. We do not have access to this data, and it is never
- transmitted to our servers or any third parties.
+ Card data is stored on your device and encrypted with AES-256. The keys are
+ kept in the iOS Keychain / Android Keystore. Card data is excluded from iCloud
+ and Android cloud backups, so it does not leave the device through a backup.
+ If you create a backup in the app (Premium), it is encrypted with your
+ password and saved wherever you choose. We never receive it.

+ ## Apple Wallet / Google Wallet export (loyalty cards only)
+ When you tap "Add to Apple Wallet" or "Add to Google Wallet" on a loyalty
+ card, the app sends that card's name, brand, barcode/membership number,
+ barcode format, note, color, language and an internal card ID to our
+ pass-signing service (Google Cloud Run, europe-west1, Belgium). Your IP
+ address is also visible to the service and to Google Cloud request logs.
+ - Google Wallet: the signed pass is created in memory and not stored by us.
+   After you save it, Google stores the pass under Google's privacy policy.
+ - Apple Wallet: the signed .pkpass file is kept on the service at an
+   unguessable link for up to 24 hours so your device can download it, then
+   deleted.
+ Credit cards, IBANs, card holder names and CVVs are never sent. If you don't
+ use Wallet export, nothing is sent to this service.

  ## Third-Party Services
- CardWallet does not use any third-party services that collect information
- used to identify you.
+ - Google Firebase Analytics, Crashlytics, App Check, Installations
+   (Google LLC): https://firebase.google.com/support/privacy
+ - Google ML Kit (on-device text and barcode recognition)
+ - Apple App Store / Google Play Billing for subscriptions. We receive only
+   your subscription status, never your payment details
+ - Apple Wallet / Google Wallet, only when you use Wallet export
+ We do not sell your data, use it for advertising, or track you across other
+ companies' apps or websites. The app does not use the advertising
+ identifier (IDFA / Android Advertising ID).

+ ## Retention
+ - Analytics events: <GA mülkündeki retention ayarı, ör. 2 ay> then deleted
+ - Crash reports: 90 days (Crashlytics)
+ - Wallet export: Google path not stored. Apple .pkpass up to 24 hours.
+   Cloud Run request logs 30 days
+ - Card data on your device: until you delete it (Settings > Delete all data)
+   or uninstall the app

+ ## Your rights (GDPR / KVKK)
+ You can ask us to access or delete the analytics and crash data linked to
+ your app installation, or object to its processing, by emailing
+ volkanustekidg@gmail.com. Data controller: <ad soyad / ticari unvan, adres>.
+ Legal basis: legitimate interest (keeping the app stable and improving it),
+ and performance of the service you request (Wallet export). Google
+ processes the data as our processor and may transfer it outside the EEA
+ under the EU–US Data Privacy Framework and Standard Contractual Clauses. You
+ can also complain to your local data protection authority (in Turkey: KVKK).

+ ## Permissions
+ Camera: scanning cards and barcodes on the device. Photos: choosing an image
+ to scan. Face ID / fingerprint: handled by the OS. We never see biometric
+ data. Notifications: local reminders, no push service.

  ## Children's Privacy
- CardWallet does not knowingly collect any personal information from children under 13.
+ CardWallet is not directed to children under 13 and does not knowingly
+ collect personal information from them.

  ## Contact Us
  volkanustekidg@gmail.com
```

**Karar gerektirenler (metni yayınlamadan önce):**
1. GA veri saklama süresi (Admin › Data collection › Data retention). Öneri: 2 ay.
2. "Data controller" satırına ad/unvan ve adres. GDPR madde 13 bunu zorunlu tutuyor.
3. Hukuki dayanak: AB'de analitik için "meşru menfaat" tartışmalı (ePrivacy, cihazda ID saklama). Daha güvenli yol, Ayarlar'a bir **"Kullanım verilerini paylaş"** anahtarı eklemek (`AnalyticsService.setEnabled` zaten var). Bu PR'ın kapsamında değil, backlog'a yazıldı.

**Aynı tutarsızlık olkan.dev/terms/cardwallet'ta da var:** Madde 4 "the company doesn't collect external information" diyor, bunun gizlilik politikasına yönlendirmesi gerekiyor. Metinde abonelik maddesi de yok (otomatik yenileme, iptal, iade için mağazaya yönlendirme). App Store'da Apple'ın standart EULA'sı kullanıldığı için zorunlu değil, ama Play açıklamasında bu sayfaya link verdiğimiz için eklenmesi iyi olur.

---

## Kaynaklar

- Firebase Android SDK'ları — Play data disclosure: https://firebase.google.com/docs/android/play-data-disclosure
- Firebase iOS — App Store data collection: https://firebase.google.com/docs/ios/app-store-data-collection
- Google Analytics for Firebase — Play Data safety: https://support.google.com/analytics/answer/11582702
- Google Analytics for Firebase — App Store privacy: https://support.google.com/analytics/answer/10285841
- ML Kit data disclosure: https://developers.google.com/ml-kit/android-data-disclosure
- Mevcut politika: https://olkan.dev/privacy/cardwallet · koşullar: https://olkan.dev/terms/cardwallet (2026-10-21'de okundu)
