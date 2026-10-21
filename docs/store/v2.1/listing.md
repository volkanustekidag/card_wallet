# Card Wallet 2.1 — Mağaza sayfası metinleri

Başlangıç noktası Mayıs taslakları (`toronto/app_store_metadata_2026-05-26.md`, `google_play_metadata_by_language_2026-05-28.md`, `aso_country_strategy_2026-05-28.md`, `store_metadata_plan_2026-05-26.md`). Bu sürümde yapılan değişiklikler:

| Konu | Mayıs taslağı | 2.1 |
|---|---|---|
| Konumlandırma (TR) | Banka kartları başta | Kart + IBAN + sadakat kartı tek güvenli cüzdanda; IBAN QR, hatırlatıcılar, PIN + Face ID |
| Konumlandırma (EN ve AB dilleri) | "Bank cards" başta | Sadakat kartı önce: hesap yok, internet gerekmez, reklam yok, şifreli. Ardından Apple Watch + widget ve Wallet'a ekleme. Kredi kartı ve IBAN ikinci planda |
| Premium | "Premium sınırsız kart + gelişmiş özellikler" | Ücretsiz sınırlar (5 sadakat / 2 kredi / 2 IBAN) ve Premium'a bağlı özellikler açıkça yazıldı. Face ID, yedekleme, Wallet'a ekleme ve IBAN QR kodda Premium'a bağlı |
| Play metinleri | Apple Watch ve Apple Wallet geçiyordu | Android'de olanlar yazıldı: Google Wallet, widget, Hızlı Ayarlar kutucuğu, parmak izi / yüz tanıma |
| App Store dilleri | TR, EN, FR, DE, IT, PT-PT, ES | 9 dil. **nl-NL, pl-PL ve pt-BR App Store Connect'te yeni dil olarak eklenmeli** (bkz. release_checklist) |
| Veri cümlesi | "Kart verileri cihazdan çıkmaz" | "Wallet'a eklerken yalnızca o sadakat kartının adı, numarası ve notu imzalama servisine gider." Kod tam olarak bunu gönderiyor (`wallet_pass_export_service.dart` `_payload`) |

Kurallar:
- Rakip uygulama adı yok (App Store 2.3.7, Play Metadata politikası). "Ücretsiz deneme" ifadesi yok, çünkü trial yok. "Ücretsiz sürüm" ifadesi geçiyor ve doğru.
- App Store anahtar kelimelerinde isim/alt başlıktaki kelimeler tekrarlanmıyor (Apple bunları zaten indeksliyor). Virgülden sonra boşluk yok. Sınır **bayt** cinsinden ölçülüyor: ü, ş, ı, ł gibi harfler 2 bayt sayılıyor.
- Abonelik paragrafı (otomatik yenileme, 24 saat, iptal yeri) App Store açıklamasında duruyor; Apple 3.1.2 inceleme notu bunu bekliyor.
- **Bilerek yazılmayanlar:** IBAN'ı görsel olarak paylaşma özelliği yok. Kodda IBAN için yalnızca metin paylaşımı ve QR var; görsel paylaşımı sadece sadakat kartlarında. Bu yüzden metinlerde "QR ile paylaş" yazıyor, "görselle paylaş" yazmıyor. IBAN tarama da hiçbir yerde vaat edilmedi.

Uzunlukları yeniden saymak için: `python3 tools/check_store_text.py --write docs/store/v2.1/listing.md`

<!-- lengths:start -->
| Dil | Alan | Uzunluk | Sınır | Durum |
|---|---|---:|---:|---|
| en-US | App Store — Name | 25 | 30 | ✅ |
| en-US | App Store — Subtitle | 28 | 30 | ✅ |
| en-US | App Store — Keywords | 96 bayt | 100 bayt | ✅ |
| en-US | App Store — Promotional Text | 155 | 170 | ✅ |
| en-US | App Store — Description | 2077 | 4000 | ✅ |
| en-US | Google Play — Title | 25 | 30 | ✅ |
| en-US | Google Play — Short description | 76 | 80 | ✅ |
| en-US | Google Play — Full description | 1984 | 4000 | ✅ |
| tr-TR | App Store — Name | 24 | 30 | ✅ |
| tr-TR | App Store — Subtitle | 30 | 30 | ✅ |
| tr-TR | App Store — Keywords | 86 bayt | 100 bayt | ✅ |
| tr-TR | App Store — Promotional Text | 143 | 170 | ✅ |
| tr-TR | App Store — Description | 2277 | 4000 | ✅ |
| tr-TR | Google Play — Title | 24 | 30 | ✅ |
| tr-TR | Google Play — Short description | 75 | 80 | ✅ |
| tr-TR | Google Play — Full description | 2212 | 4000 | ✅ |
| de-DE | App Store — Name | 24 | 30 | ✅ |
| de-DE | App Store — Subtitle | 30 | 30 | ✅ |
| de-DE | App Store — Keywords | 100 bayt | 100 bayt | ✅ |
| de-DE | App Store — Promotional Text | 150 | 170 | ✅ |
| de-DE | App Store — Description | 2387 | 4000 | ✅ |
| de-DE | Google Play — Title | 24 | 30 | ✅ |
| de-DE | Google Play — Short description | 77 | 80 | ✅ |
| de-DE | Google Play — Full description | 2289 | 4000 | ✅ |
| fr-FR | App Store — Name | 28 | 30 | ✅ |
| fr-FR | App Store — Subtitle | 30 | 30 | ✅ |
| fr-FR | App Store — Keywords | 99 bayt | 100 bayt | ✅ |
| fr-FR | App Store — Promotional Text | 156 | 170 | ✅ |
| fr-FR | App Store — Description | 2463 | 4000 | ✅ |
| fr-FR | Google Play — Title | 28 | 30 | ✅ |
| fr-FR | Google Play — Short description | 72 | 80 | ✅ |
| fr-FR | Google Play — Full description | 2409 | 4000 | ✅ |
| es-ES | App Store — Name | 30 | 30 | ✅ |
| es-ES | App Store — Subtitle | 29 | 30 | ✅ |
| es-ES | App Store — Keywords | 95 bayt | 100 bayt | ✅ |
| es-ES | App Store — Promotional Text | 159 | 170 | ✅ |
| es-ES | App Store — Description | 2314 | 4000 | ✅ |
| es-ES | Google Play — Title | 30 | 30 | ✅ |
| es-ES | Google Play — Short description | 77 | 80 | ✅ |
| es-ES | Google Play — Full description | 2220 | 4000 | ✅ |
| pt-BR | App Store — Name | 29 | 30 | ✅ |
| pt-BR | App Store — Subtitle | 30 | 30 | ✅ |
| pt-BR | App Store — Keywords | 99 bayt | 100 bayt | ✅ |
| pt-BR | App Store — Promotional Text | 161 | 170 | ✅ |
| pt-BR | App Store — Description | 2279 | 4000 | ✅ |
| pt-BR | Google Play — Title | 29 | 30 | ✅ |
| pt-BR | Google Play — Short description | 74 | 80 | ✅ |
| pt-BR | Google Play — Full description | 2200 | 4000 | ✅ |
| it-IT | App Store — Name | 25 | 30 | ✅ |
| it-IT | App Store — Subtitle | 27 | 30 | ✅ |
| it-IT | App Store — Keywords | 99 bayt | 100 bayt | ✅ |
| it-IT | App Store — Promotional Text | 153 | 170 | ✅ |
| it-IT | App Store — Description | 2330 | 4000 | ✅ |
| it-IT | Google Play — Title | 25 | 30 | ✅ |
| it-IT | Google Play — Short description | 70 | 80 | ✅ |
| it-IT | Google Play — Full description | 2257 | 4000 | ✅ |
| nl-NL | App Store — Name | 26 | 30 | ✅ |
| nl-NL | App Store — Subtitle | 30 | 30 | ✅ |
| nl-NL | App Store — Keywords | 100 bayt | 100 bayt | ✅ |
| nl-NL | App Store — Promotional Text | 158 | 170 | ✅ |
| nl-NL | App Store — Description | 2247 | 4000 | ✅ |
| nl-NL | Google Play — Title | 26 | 30 | ✅ |
| nl-NL | Google Play — Short description | 79 | 80 | ✅ |
| nl-NL | Google Play — Full description | 2153 | 4000 | ✅ |
| pl-PL | App Store — Name | 28 | 30 | ✅ |
| pl-PL | App Store — Subtitle | 27 | 30 | ✅ |
| pl-PL | App Store — Keywords | 95 bayt | 100 bayt | ✅ |
| pl-PL | App Store — Promotional Text | 143 | 170 | ✅ |
| pl-PL | App Store — Description | 2304 | 4000 | ✅ |
| pl-PL | Google Play — Title | 28 | 30 | ✅ |
| pl-PL | Google Play — Short description | 77 | 80 | ✅ |
| pl-PL | Google Play — Full description | 2234 | 4000 | ✅ |
<!-- lengths:end -->

---

## en-US

### App Store

#### App Store — Name (≤30)

```text
CardWallet: Loyalty Cards
```

#### App Store — Subtitle (≤30)

```text
Private, offline card wallet
```

#### App Store — Keywords (≤100 bytes)

```text
rewards,barcode,qr,membership,points,store,iban,credit,debit,scanner,pass,widget,watch,encrypted
```

#### App Store — Promotional Text (≤170)

```text
New in 2.1: auto-lock, American Express and Diners Club support, and brighter barcodes. Your cards stay encrypted on this iPhone and out of iCloud backups.
```

#### App Store — Description (≤4000)

```text
CardWallet keeps your loyalty and membership cards in one private wallet on your iPhone. There's no account to create, no ads, and it works without an internet connection.

At the checkout, open a card and the screen brightens automatically so the scanner reads your barcode on the first try. Your cards are also on your Apple Watch and in a home screen widget.

PRIVATE BY DESIGN
• No sign-up, no account
• No ads
• Works offline
• Cards are stored encrypted on your device and aren't included in iCloud backups
• PIN lock with auto-lock, and your cards are hidden in the app switcher

LOYALTY CARDS
• Scan a barcode or QR code with the camera, pick it from a photo, or type it in
• Full screen brightness while a barcode is open
• Search, filter by tag and mark favorites
• Share a card as an image
• Apple Watch app and home screen widget for quick access

CREDIT CARDS AND IBANS TOO
• Keep credit cards and IBANs next to your loyalty cards
• Copy or share an IBAN in one tap
• Payment and expiry reminders for credit cards
• American Express and Diners Club supported
• Available in 9 languages

PREMIUM
The free version includes 5 loyalty cards, 2 credit cards and 2 IBANs. Premium adds:
• Unlimited cards
• Add loyalty cards to Apple Wallet
• Unlock with Face ID or Touch ID
• Encrypted backup and restore, for example when you move to a new phone
• IBAN QR codes
• Extra card colors

Premium is offered as a weekly, monthly or yearly subscription. Payment is charged to your Apple ID. A subscription renews automatically unless it's cancelled at least 24 hours before the end of the current period. You can manage or cancel it in your App Store account settings.

CardWallet is not a banking app. It doesn't make payments, move money or connect to your bank.

When you add a loyalty card to Apple Wallet, that card's name, number and note are sent to our pass-signing service to create the pass. No other card details leave your device.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet: Loyalty Cards
```

#### Google Play — Short description (≤80)

```text
Loyalty cards and barcodes in a private wallet. No account, no ads, offline.
```

#### Google Play — Full description (≤4000)

```text
CardWallet keeps your loyalty and membership cards in one private wallet on your phone. There's no account to create, no ads, and it works without an internet connection.

At the checkout, open a card and the screen brightens automatically so the scanner reads your barcode on the first try. Put your favorite card on the home screen with a widget or open it from a Quick Settings tile.

Private by design
• No sign-up, no account
• No ads
• Works offline
• Cards are stored encrypted on your device and aren't included in cloud backups
• PIN lock with auto-lock, and card screens are hidden from screenshots and the recent apps view

Loyalty cards
• Scan a barcode or QR code with the camera, pick it from a photo, or type it in
• Full screen brightness while a barcode is open
• Search, filter by tag and mark favorites
• Share a card as an image
• Home screen widget and Quick Settings tile for quick access

Credit cards and IBANs too
• Keep credit cards and IBANs next to your loyalty cards
• Copy or share an IBAN in one tap
• Payment and expiry reminders for credit cards
• American Express and Diners Club supported
• Available in 9 languages

Premium
The free version includes 5 loyalty cards, 2 credit cards and 2 IBANs. Premium adds:
• Unlimited cards
• Save loyalty cards to Google Wallet
• Unlock with your fingerprint or face
• Encrypted backup and restore, for example when you move to a new phone
• IBAN QR codes
• Extra card colors

Premium is offered as a weekly, monthly or yearly subscription that renews automatically. You can cancel anytime in Google Play › Payments & subscriptions.

CardWallet is not a banking app. It doesn't make payments, move money or connect to your bank.

When you save a loyalty card to Google Wallet, that card's name, number and note are sent to our pass-signing service to create the pass. No other card details leave your device.

Privacy Policy: https://olkan.dev/privacy/cardwallet
Terms of Use: https://olkan.dev/terms/cardwallet
```

## tr-TR

### App Store

#### App Store — Name (≤30)

```text
CardWallet: Kart ve IBAN
```

#### App Store — Subtitle (≤30)

```text
Sadakat Kartı, QR, Hatırlatıcı
```

#### App Store — Keywords (≤100 bytes)

```text
cüzdan,banka,kredi,barkod,üyelik,puan,market,şifreli,yedek,face id,pin,widget,watch
```

#### App Store — Promotional Text (≤170)

```text
2.1'de yeni: otomatik kilit, Amex ve Diners Club desteği, barkodda tam parlaklık. Kartların bu iPhone'da şifreli kalır, iCloud yedeğine girmez.
```

#### App Store — Description (≤4000)

```text
CardWallet; kredi kartlarını, IBAN'larını ve sadakat kartlarını tek bir güvenli cüzdanda toplar. Hesap açman gerekmez, reklam yoktur, internet olmadan da çalışır.

IBAN'ını tek dokunuşla kopyala ya da paylaş, karşındakine QR kodla okut. Kasada sadakat kartını aç, ekran kendiliğinden parlasın. Kredi kartının ödeme ve son kullanma tarihini hatırlatıcılar senin yerine takip etsin.

GÜVENLİK
• PIN ile kilit, Premium'da Face ID veya Touch ID
• Otomatik kilit: uygulamadan çıktığında cüzdan kendini kilitler
• Uygulama geçişinde kartların görünmez
• Kartların cihazında şifreli saklanır, iCloud yedeğine girmez
• Hesap yok, reklam yok

KREDİ KARTLARI
• Kartlarını şık kart tasarımlarıyla kaydet
• Ödeme günü ve son kullanma tarihi hatırlatıcıları
• Visa, Mastercard, Troy, American Express ve Diners Club
• Kart numarasını kamerayla tara
• Paylaşırken numarayı maskeli gönder (•••• 1234)

IBAN
• IBAN'larını isim ve bankayla birlikte sakla
• Tek dokunuşla kopyala, mesajla paylaş
• QR kod oluştur, karşı taraf telefonuyla okutsun (Premium)

SADAKAT KARTLARI
• Barkodu veya QR kodu kamerayla tara, fotoğraftan seç ya da elle gir
• Barkod açıkken ekran tam parlaklığa çıkar
• Etiketle, filtrele, favorilerini işaretle
• Apple Watch ve ana ekran widget'ıyla saniyeler içinde aç
• Kartı görsel olarak paylaş

PREMIUM
Ücretsiz sürümde 2 kredi kartı, 2 IBAN ve 5 sadakat kartı saklayabilirsin. Premium ile:
• Sınırsız kart
• Face ID / Touch ID ile açma
• Şifreli yedekleme ve geri yükleme (yeni telefona geçerken de)
• Sadakat kartlarını Apple Cüzdan'a ekleme
• IBAN QR kodu
• Ek kart renkleri

Premium; haftalık, aylık veya yıllık abonelik olarak sunulur. Ödeme Apple kimliğinden alınır. Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik olarak yenilenir. Aboneliğini App Store hesap ayarlarından yönetebilir ya da iptal edebilirsin.

CardWallet bir banka uygulaması değildir; ödeme yapmaz, para göndermez, bankana bağlanmaz.

Bir sadakat kartını Apple Cüzdan'a eklediğinde, kartın oluşturulabilmesi için yalnızca o kartın adı, numarası ve notu imzalama servisimize gönderilir. Diğer kart bilgilerin cihazından çıkmaz.

Kullanım Koşulları: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Gizlilik Politikası: https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet: Kart ve IBAN
```

#### Google Play — Short description (≤80)

```text
Kart, IBAN ve sadakat kartların tek güvenli cüzdanda. IBAN'ı QR ile paylaş.
```

#### Google Play — Full description (≤4000)

```text
CardWallet; kredi kartlarını, IBAN'larını ve sadakat kartlarını tek bir güvenli cüzdanda toplar. Hesap açman gerekmez, reklam yoktur, internet olmadan da çalışır.

IBAN'ını tek dokunuşla kopyala ya da paylaş, karşındakine QR kodla okut. Kasada sadakat kartını aç, ekran kendiliğinden parlasın. Kredi kartının ödeme ve son kullanma tarihini hatırlatıcılar senin yerine takip etsin.

Güvenlik
• PIN ile kilit, Premium'da parmak izi veya yüz tanıma
• Otomatik kilit: uygulamadan çıktığında cüzdan kendini kilitler
• Kart ekranları ekran görüntüsünde ve son uygulamalar listesinde gizlenir
• Kartların cihazında şifreli saklanır, bulut yedeğine girmez
• Hesap yok, reklam yok

Kredi kartları
• Kartlarını şık kart tasarımlarıyla kaydet
• Ödeme günü ve son kullanma tarihi hatırlatıcıları
• Visa, Mastercard, Troy, American Express ve Diners Club
• Kart numarasını kamerayla tara
• Paylaşırken numarayı maskeli gönder (•••• 1234)

IBAN
• IBAN'larını isim ve bankayla birlikte sakla
• Tek dokunuşla kopyala, mesajla paylaş
• QR kod oluştur, karşı taraf telefonuyla okutsun (Premium)

Sadakat kartları
• Barkodu veya QR kodu kamerayla tara, fotoğraftan seç ya da elle gir
• Barkod açıkken ekran tam parlaklığa çıkar
• Etiketle, filtrele, favorilerini işaretle
• Ana ekran widget'ı ve Hızlı Ayarlar kutucuğuyla saniyeler içinde aç
• Kartı görsel olarak paylaş

Premium
Ücretsiz sürümde 2 kredi kartı, 2 IBAN ve 5 sadakat kartı saklayabilirsin. Premium ile:
• Sınırsız kart
• Parmak izi veya yüz tanımayla açma
• Şifreli yedekleme ve geri yükleme (yeni telefona geçerken de)
• Sadakat kartlarını Google Cüzdan'a ekleme
• IBAN QR kodu
• Ek kart renkleri

Premium; haftalık, aylık veya yıllık abonelik olarak sunulur ve otomatik yenilenir. İstediğin zaman Google Play › Ödemeler ve abonelikler bölümünden iptal edebilirsin.

CardWallet bir banka uygulaması değildir; ödeme yapmaz, para göndermez, bankana bağlanmaz.

Bir sadakat kartını Google Cüzdan'a eklediğinde, kartın oluşturulabilmesi için yalnızca o kartın adı, numarası ve notu imzalama servisimize gönderilir. Diğer kart bilgilerin cihazından çıkmaz.

Gizlilik Politikası: https://olkan.dev/privacy/cardwallet
Kullanım Koşulları: https://olkan.dev/terms/cardwallet
```

## de-DE

### App Store

#### App Store — Name (≤30)

```text
CardWallet: Kundenkarten
```

#### App Store — Subtitle (≤30)

```text
Ohne Konto, offline, werbefrei
```

#### App Store — Keywords (≤100 bytes)

```text
treuekarte,bonuskarte,barcode,qr,wallet,punkte,mitglied,iban,kreditkarte,verschlüsselt,widget,watch
```

#### App Store — Promotional Text (≤170)

```text
Neu in 2.1: automatische Sperre, Amex und Diners Club, hellere Barcodes. Deine Karten bleiben verschlüsselt auf dem iPhone und nicht im iCloud-Backup.
```

#### App Store — Description (≤4000)

```text
CardWallet bewahrt deine Kunden- und Treuekarten in einer privaten Wallet auf deinem iPhone auf. Du brauchst kein Konto, es gibt keine Werbung, und die App funktioniert auch ohne Internet.

An der Kasse öffnest du die Karte, der Bildschirm wird automatisch hell und der Scanner liest den Barcode beim ersten Versuch. Deine Karten hast du außerdem auf der Apple Watch und im Widget auf dem Home-Bildschirm.

PRIVAT VON ANFANG AN
• Keine Registrierung, kein Konto
• Keine Werbung
• Funktioniert offline
• Karten werden verschlüsselt auf deinem Gerät gespeichert und landen nicht im iCloud-Backup
• PIN-Sperre mit automatischer Sperre; im App-Umschalter sind deine Karten verdeckt

KUNDENKARTEN
• Barcode oder QR-Code mit der Kamera scannen, aus einem Foto übernehmen oder eintippen
• Volle Bildschirmhelligkeit, solange ein Barcode offen ist
• Suchen, nach Tags filtern, Favoriten markieren
• Karte als Bild teilen
• Apple-Watch-App und Widget für den schnellen Zugriff

AUCH FÜR KREDITKARTEN UND IBANS
• Kreditkarten und IBANs neben deinen Kundenkarten aufbewahren
• IBAN mit einem Tippen kopieren oder teilen
• Erinnerungen an Zahlungs- und Ablaufdaten von Kreditkarten
• American Express und Diners Club werden unterstützt
• In 9 Sprachen verfügbar

PREMIUM
Die kostenlose Version umfasst 5 Kundenkarten, 2 Kreditkarten und 2 IBANs. Mit Premium bekommst du:
• Unbegrenzt viele Karten
• Kundenkarten zu Apple Wallet hinzufügen
• Entsperren mit Face ID oder Touch ID
• Verschlüsselte Sicherung und Wiederherstellung, zum Beispiel beim Umzug auf ein neues Telefon
• IBAN-QR-Codes
• Zusätzliche Kartenfarben

Premium gibt es als Wochen-, Monats- oder Jahresabo. Die Zahlung wird über deine Apple-ID abgerechnet. Das Abo verlängert sich automatisch, wenn es nicht mindestens 24 Stunden vor Ende des laufenden Zeitraums gekündigt wird. Verwalten oder kündigen kannst du es in den Einstellungen deines App-Store-Accounts.

CardWallet ist keine Banking-App. Sie führt keine Zahlungen aus, überweist kein Geld und verbindet sich nicht mit deiner Bank.

Wenn du eine Kundenkarte zu Apple Wallet hinzufügst, werden Name, Nummer und Notiz dieser Karte an unseren Signaturdienst gesendet, um den Pass zu erstellen. Andere Kartendaten verlassen dein Gerät nicht.

Nutzungsbedingungen: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Datenschutz: https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet: Kundenkarten
```

#### Google Play — Short description (≤80)

```text
Kundenkarten und Barcodes in einer privaten Wallet. Ohne Konto, ohne Werbung.
```

#### Google Play — Full description (≤4000)

```text
CardWallet bewahrt deine Kunden- und Treuekarten in einer privaten Wallet auf deinem Handy auf. Du brauchst kein Konto, es gibt keine Werbung, und die App funktioniert auch ohne Internet.

An der Kasse öffnest du die Karte, der Bildschirm wird automatisch hell und der Scanner liest den Barcode beim ersten Versuch. Deine Lieblingskarte legst du als Widget auf den Startbildschirm oder öffnest sie über eine Schnelleinstellungs-Kachel.

Privat von Anfang an
• Keine Registrierung, kein Konto
• Keine Werbung
• Funktioniert offline
• Karten werden verschlüsselt auf deinem Gerät gespeichert und landen nicht im Cloud-Backup
• PIN-Sperre mit automatischer Sperre; Kartenansichten sind in Screenshots und in der Übersicht der letzten Apps verborgen

Kundenkarten
• Barcode oder QR-Code mit der Kamera scannen, aus einem Foto übernehmen oder eintippen
• Volle Bildschirmhelligkeit, solange ein Barcode offen ist
• Suchen, nach Tags filtern, Favoriten markieren
• Karte als Bild teilen
• Widget und Schnelleinstellungs-Kachel für den schnellen Zugriff

Auch für Kreditkarten und IBANs
• Kreditkarten und IBANs neben deinen Kundenkarten aufbewahren
• IBAN mit einem Tippen kopieren oder teilen
• Erinnerungen an Zahlungs- und Ablaufdaten von Kreditkarten
• American Express und Diners Club werden unterstützt
• In 9 Sprachen verfügbar

Premium
Die kostenlose Version umfasst 5 Kundenkarten, 2 Kreditkarten und 2 IBANs. Mit Premium bekommst du:
• Unbegrenzt viele Karten
• Kundenkarten in Google Wallet speichern
• Entsperren per Fingerabdruck oder Gesichtserkennung
• Verschlüsselte Sicherung und Wiederherstellung, zum Beispiel beim Umzug auf ein neues Telefon
• IBAN-QR-Codes
• Zusätzliche Kartenfarben

Premium gibt es als Wochen-, Monats- oder Jahresabo mit automatischer Verlängerung. Kündigen kannst du jederzeit in Google Play › Zahlungen & Abos.

CardWallet ist keine Banking-App. Sie führt keine Zahlungen aus, überweist kein Geld und verbindet sich nicht mit deiner Bank.

Wenn du eine Kundenkarte in Google Wallet speicherst, werden Name, Nummer und Notiz dieser Karte an unseren Signaturdienst gesendet, um den Pass zu erstellen. Andere Kartendaten verlassen dein Gerät nicht.

Datenschutz: https://olkan.dev/privacy/cardwallet
Nutzungsbedingungen: https://olkan.dev/terms/cardwallet
```

## fr-FR

### App Store

#### App Store — Name (≤30)

```text
CardWallet : Cartes fidélité
```

#### App Store — Subtitle (≤30)

```text
Hors ligne, sans compte ni pub
```

#### App Store — Keywords (≤100 bytes)

```text
carte de fidélité,code-barres,qr,portefeuille,points,magasin,membre,iban,bancaire,chiffré,widget
```

#### App Store — Promotional Text (≤170)

```text
Nouveau dans la 2.1 : verrouillage auto, Amex et Diners Club, codes-barres plus lumineux. Vos cartes restent chiffrées sur l'iPhone, hors sauvegarde iCloud.
```

#### App Store — Description (≤4000)

```text
CardWallet range vos cartes de fidélité et d'adhérent dans un portefeuille privé, sur votre iPhone. Pas de compte à créer, pas de publicité, et l'app fonctionne sans connexion Internet.

En caisse, ouvrez la carte : l'écran s'éclaircit tout seul et le lecteur lit le code-barres du premier coup. Vos cartes sont aussi sur votre Apple Watch et dans un widget de l'écran d'accueil.

PRIVÉE PAR CONCEPTION
• Pas d'inscription, pas de compte
• Pas de publicité
• Fonctionne hors ligne
• Les cartes sont chiffrées sur votre appareil et ne sont pas incluses dans la sauvegarde iCloud
• Verrouillage par code PIN avec verrouillage auto ; vos cartes sont masquées dans le sélecteur d'apps

CARTES DE FIDÉLITÉ
• Scannez un code-barres ou un QR code avec l'appareil photo, depuis une photo, ou saisissez-le
• Luminosité maximale tant qu'un code-barres est affiché
• Recherche, filtres par étiquette et favoris
• Partage d'une carte sous forme d'image
• App Apple Watch et widget pour un accès rapide

AUSSI POUR LES CARTES BANCAIRES ET LES IBAN
• Gardez cartes bancaires et IBAN à côté de vos cartes de fidélité
• Copiez ou partagez un IBAN d'un geste
• Rappels d'échéance de paiement et d'expiration
• American Express et Diners Club pris en charge
• Disponible en 9 langues

PREMIUM
La version gratuite comprend 5 cartes de fidélité, 2 cartes bancaires et 2 IBAN. Premium ajoute :
• Cartes illimitées
• Ajout des cartes de fidélité à Apple Wallet
• Déverrouillage par Face ID ou Touch ID
• Sauvegarde et restauration chiffrées, par exemple pour passer à un nouveau téléphone
• QR codes pour vos IBAN
• Couleurs de carte supplémentaires

Premium est proposé en abonnement hebdomadaire, mensuel ou annuel. Le paiement est débité sur votre identifiant Apple. L'abonnement se renouvelle automatiquement s'il n'est pas résilié au moins 24 heures avant la fin de la période en cours. Vous pouvez le gérer ou le résilier dans les réglages de votre compte App Store.

CardWallet n'est pas une application bancaire. Elle n'effectue pas de paiement, ne transfère pas d'argent et ne se connecte pas à votre banque.

Quand vous ajoutez une carte de fidélité à Apple Wallet, son nom, son numéro et sa note sont envoyés à notre service de signature pour créer le pass. Aucune autre donnée de carte ne quitte votre appareil.

Conditions d'utilisation : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Politique de confidentialité : https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet : Cartes fidélité
```

#### Google Play — Short description (≤80)

```text
Cartes de fidélité et codes-barres, sans compte ni pub, même hors ligne.
```

#### Google Play — Full description (≤4000)

```text
CardWallet range vos cartes de fidélité et d'adhérent dans un portefeuille privé, sur votre téléphone. Pas de compte à créer, pas de publicité, et l'app fonctionne sans connexion Internet.

En caisse, ouvrez la carte : l'écran s'éclaircit tout seul et le lecteur lit le code-barres du premier coup. Placez votre carte préférée sur l'écran d'accueil avec un widget ou ouvrez-la depuis une vignette des Réglages rapides.

Privée par conception
• Pas d'inscription, pas de compte
• Pas de publicité
• Fonctionne hors ligne
• Les cartes sont chiffrées sur votre appareil et ne sont pas incluses dans les sauvegardes cloud
• Verrouillage par code PIN avec verrouillage auto ; les écrans de carte sont masqués dans les captures et les apps récentes

Cartes de fidélité
• Scannez un code-barres ou un QR code avec l'appareil photo, depuis une photo, ou saisissez-le
• Luminosité maximale tant qu'un code-barres est affiché
• Recherche, filtres par étiquette et favoris
• Partage d'une carte sous forme d'image
• Widget et vignette des Réglages rapides pour un accès rapide

Aussi pour les cartes bancaires et les IBAN
• Gardez cartes bancaires et IBAN à côté de vos cartes de fidélité
• Copiez ou partagez un IBAN d'un geste
• Rappels d'échéance de paiement et d'expiration
• American Express et Diners Club pris en charge
• Disponible en 9 langues

Premium
La version gratuite comprend 5 cartes de fidélité, 2 cartes bancaires et 2 IBAN. Premium ajoute :
• Cartes illimitées
• Enregistrement des cartes de fidélité dans Google Wallet
• Déverrouillage par empreinte digitale ou reconnaissance faciale
• Sauvegarde et restauration chiffrées, par exemple pour passer à un nouveau téléphone
• QR codes pour vos IBAN
• Couleurs de carte supplémentaires

Premium est proposé en abonnement hebdomadaire, mensuel ou annuel, renouvelé automatiquement. Vous pouvez le résilier à tout moment dans Google Play › Paiements et abonnements.

CardWallet n'est pas une application bancaire. Elle n'effectue pas de paiement, ne transfère pas d'argent et ne se connecte pas à votre banque.

Quand vous enregistrez une carte de fidélité dans Google Wallet, son nom, son numéro et sa note sont envoyés à notre service de signature pour créer le pass. Aucune autre donnée de carte ne quitte votre appareil.

Politique de confidentialité : https://olkan.dev/privacy/cardwallet
Conditions d'utilisation : https://olkan.dev/terms/cardwallet
```

## es-ES

### App Store

#### App Store — Name (≤30)

```text
CardWallet: Tarjetas fidelidad
```

#### App Store — Subtitle (≤30)

```text
Cartera privada, sin anuncios
```

#### App Store — Keywords (≤100 bytes)

```text
puntos,codigo de barras,qr,socio,tienda,monedero,offline,sin cuenta,iban,credito,cifrado,widget
```

#### App Store — Promotional Text (≤170)

```text
Novedades de la 2.1: bloqueo automático, Amex y Diners Club, y códigos más brillantes. Tus tarjetas siguen cifradas en el iPhone y fuera de la copia de iCloud.
```

#### App Store — Description (≤4000)

```text
CardWallet guarda tus tarjetas de fidelidad y de socio en una cartera privada en tu iPhone. No tienes que crear ninguna cuenta, no hay anuncios y funciona sin conexión a internet.

En caja, abre la tarjeta: la pantalla sube el brillo sola y el lector lee el código de barras a la primera. Tus tarjetas también están en el Apple Watch y en un widget de la pantalla de inicio.

PRIVADA DESDE EL PRINCIPIO
• Sin registro y sin cuenta
• Sin anuncios
• Funciona sin conexión
• Las tarjetas se guardan cifradas en tu dispositivo y no se incluyen en la copia de iCloud
• Bloqueo con PIN y bloqueo automático; tus tarjetas se ocultan al cambiar de app

TARJETAS DE FIDELIDAD
• Escanea un código de barras o QR con la cámara, elígelo de una foto o escríbelo
• Brillo al máximo mientras el código de barras está abierto
• Busca, filtra por etiquetas y marca tus favoritas
• Comparte una tarjeta como imagen
• App para Apple Watch y widget para abrirlas al momento

TAMBIÉN TARJETAS BANCARIAS E IBAN
• Guarda tarjetas de crédito e IBAN junto a tus tarjetas de fidelidad
• Copia o comparte un IBAN con un toque
• Recordatorios de pago y de caducidad de tus tarjetas
• Compatible con American Express y Diners Club
• Disponible en 9 idiomas

PREMIUM
La versión gratuita incluye 5 tarjetas de fidelidad, 2 tarjetas de crédito y 2 IBAN. Premium añade:
• Tarjetas ilimitadas
• Añadir tarjetas de fidelidad a Apple Wallet
• Desbloqueo con Face ID o Touch ID
• Copia de seguridad cifrada y restauración, por ejemplo al cambiar de teléfono
• Códigos QR para tus IBAN
• Más colores de tarjeta

Premium se ofrece como suscripción semanal, mensual o anual. El pago se carga en tu ID de Apple. La suscripción se renueva automáticamente salvo que la canceles al menos 24 horas antes de que termine el periodo actual. Puedes gestionarla o cancelarla en los ajustes de tu cuenta del App Store.

CardWallet no es una app bancaria. No hace pagos, no mueve dinero y no se conecta con tu banco.

Cuando añades una tarjeta de fidelidad a Apple Wallet, su nombre, su número y su nota se envían a nuestro servicio de firma para crear el pase. Ningún otro dato de tus tarjetas sale de tu dispositivo.

Condiciones de uso: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidad: https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet: Tarjetas fidelidad
```

#### Google Play — Short description (≤80)

```text
Tarjetas de fidelidad y códigos de barras. Sin cuenta, sin anuncios, offline.
```

#### Google Play — Full description (≤4000)

```text
CardWallet guarda tus tarjetas de fidelidad y de socio en una cartera privada en tu móvil. No tienes que crear ninguna cuenta, no hay anuncios y funciona sin conexión a internet.

En caja, abre la tarjeta: la pantalla sube el brillo sola y el lector lee el código de barras a la primera. Pon tu tarjeta favorita en la pantalla de inicio con un widget o ábrela desde un icono de Ajustes rápidos.

Privada desde el principio
• Sin registro y sin cuenta
• Sin anuncios
• Funciona sin conexión
• Las tarjetas se guardan cifradas en tu dispositivo y no se incluyen en las copias en la nube
• Bloqueo con PIN y bloqueo automático; las pantallas de tarjetas no salen en capturas ni en apps recientes

Tarjetas de fidelidad
• Escanea un código de barras o QR con la cámara, elígelo de una foto o escríbelo
• Brillo al máximo mientras el código de barras está abierto
• Busca, filtra por etiquetas y marca tus favoritas
• Comparte una tarjeta como imagen
• Widget e icono de Ajustes rápidos para abrirlas al momento

También tarjetas bancarias e IBAN
• Guarda tarjetas de crédito e IBAN junto a tus tarjetas de fidelidad
• Copia o comparte un IBAN con un toque
• Recordatorios de pago y de caducidad de tus tarjetas
• Compatible con American Express y Diners Club
• Disponible en 9 idiomas

Premium
La versión gratuita incluye 5 tarjetas de fidelidad, 2 tarjetas de crédito y 2 IBAN. Premium añade:
• Tarjetas ilimitadas
• Guardar tarjetas de fidelidad en Google Wallet
• Desbloqueo con huella o reconocimiento facial
• Copia de seguridad cifrada y restauración, por ejemplo al cambiar de teléfono
• Códigos QR para tus IBAN
• Más colores de tarjeta

Premium se ofrece como suscripción semanal, mensual o anual con renovación automática. Puedes cancelarla cuando quieras en Google Play › Pagos y suscripciones.

CardWallet no es una app bancaria. No hace pagos, no mueve dinero y no se conecta con tu banco.

Cuando guardas una tarjeta de fidelidad en Google Wallet, su nombre, su número y su nota se envían a nuestro servicio de firma para crear el pase. Ningún otro dato de tus tarjetas sale de tu dispositivo.

Política de privacidad: https://olkan.dev/privacy/cardwallet
Condiciones de uso: https://olkan.dev/terms/cardwallet
```

## pt-BR

### App Store

#### App Store — Name (≤30)

```text
CardWallet: Cartão Fidelidade
```

#### App Store — Subtitle (≤30)

```text
Carteira offline, sem anúncios
```

#### App Store — Keywords (≤100 bytes)

```text
pontos,código de barras,qr,clube,loja,membro,sem conta,cartões,crédito,criptografia,widget,watch
```

#### App Store — Promotional Text (≤170)

```text
Novidades da 2.1: bloqueio automático, Amex e Diners Club e códigos de barras mais claros. Seus cartões ficam criptografados no iPhone, fora do backup do iCloud.
```

#### App Store — Description (≤4000)

```text
O CardWallet guarda seus cartões fidelidade e de sócio em uma carteira privada no seu iPhone. Não precisa criar conta, não tem anúncios e funciona sem internet.

No caixa, abra o cartão: a tela fica mais clara sozinha e o leitor pega o código de barras de primeira. Seus cartões também ficam no Apple Watch e em um widget da tela de início.

PRIVADO DESDE O INÍCIO
• Sem cadastro, sem conta
• Sem anúncios
• Funciona offline
• Os cartões ficam criptografados no seu aparelho e não entram no backup do iCloud
• Bloqueio por PIN com bloqueio automático; seus cartões ficam escondidos na troca de apps

CARTÕES FIDELIDADE
• Escaneie código de barras ou QR com a câmera, escolha de uma foto ou digite
• Brilho máximo enquanto o código de barras estiver aberto
• Busque, filtre por etiquetas e marque seus favoritos
• Compartilhe um cartão como imagem
• App para Apple Watch e widget para abrir na hora

TAMBÉM CARTÕES DE CRÉDITO E IBAN
• Guarde cartões de crédito e IBANs junto com seus cartões fidelidade
• Copie ou compartilhe um IBAN com um toque
• Lembretes de pagamento e de vencimento do cartão
• Suporte a American Express e Diners Club
• Disponível em 9 idiomas

PREMIUM
A versão gratuita inclui 5 cartões fidelidade, 2 cartões de crédito e 2 IBANs. O Premium adiciona:
• Cartões ilimitados
• Adicionar cartões fidelidade à Apple Wallet
• Desbloqueio com Face ID ou Touch ID
• Backup criptografado e restauração, por exemplo ao trocar de celular
• QR code para seus IBANs
• Mais cores de cartão

O Premium é oferecido como assinatura semanal, mensal ou anual. O pagamento é cobrado no seu ID Apple. A assinatura é renovada automaticamente, a menos que seja cancelada pelo menos 24 horas antes do fim do período atual. Você pode gerenciar ou cancelar nos ajustes da sua conta da App Store.

O CardWallet não é um app de banco. Ele não faz pagamentos, não transfere dinheiro e não se conecta ao seu banco.

Quando você adiciona um cartão fidelidade à Apple Wallet, o nome, o número e a observação desse cartão são enviados ao nosso serviço de assinatura digital para criar o passe. Nenhum outro dado dos seus cartões sai do aparelho.

Termos de uso: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidade: https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet: Cartão Fidelidade
```

#### Google Play — Short description (≤80)

```text
Cartões fidelidade e códigos de barras, sem conta, sem anúncios e offline.
```

#### Google Play — Full description (≤4000)

```text
O CardWallet guarda seus cartões fidelidade e de sócio em uma carteira privada no seu celular. Não precisa criar conta, não tem anúncios e funciona sem internet.

No caixa, abra o cartão: a tela fica mais clara sozinha e o leitor pega o código de barras de primeira. Coloque seu cartão favorito na tela inicial com um widget ou abra pelo bloco de Configurações rápidas.

Privado desde o início
• Sem cadastro, sem conta
• Sem anúncios
• Funciona offline
• Os cartões ficam criptografados no seu aparelho e não entram em backups na nuvem
• Bloqueio por PIN com bloqueio automático; as telas dos cartões não aparecem em capturas nem em apps recentes

Cartões fidelidade
• Escaneie código de barras ou QR com a câmera, escolha de uma foto ou digite
• Brilho máximo enquanto o código de barras estiver aberto
• Busque, filtre por etiquetas e marque seus favoritos
• Compartilhe um cartão como imagem
• Widget e bloco de Configurações rápidas para abrir na hora

Também cartões de crédito e IBAN
• Guarde cartões de crédito e IBANs junto com seus cartões fidelidade
• Copie ou compartilhe um IBAN com um toque
• Lembretes de pagamento e de vencimento do cartão
• Suporte a American Express e Diners Club
• Disponível em 9 idiomas

Premium
A versão gratuita inclui 5 cartões fidelidade, 2 cartões de crédito e 2 IBANs. O Premium adiciona:
• Cartões ilimitados
• Salvar cartões fidelidade na Google Wallet
• Desbloqueio com impressão digital ou reconhecimento facial
• Backup criptografado e restauração, por exemplo ao trocar de celular
• QR code para seus IBANs
• Mais cores de cartão

O Premium é oferecido como assinatura semanal, mensal ou anual com renovação automática. Você pode cancelar quando quiser em Google Play › Pagamentos e assinaturas.

O CardWallet não é um app de banco. Ele não faz pagamentos, não transfere dinheiro e não se conecta ao seu banco.

Quando você salva um cartão fidelidade na Google Wallet, o nome, o número e a observação desse cartão são enviados ao nosso serviço de assinatura digital para criar o passe. Nenhum outro dado dos seus cartões sai do aparelho.

Política de privacidade: https://olkan.dev/privacy/cardwallet
Termos de uso: https://olkan.dev/terms/cardwallet
```

## it-IT

### App Store

#### App Store — Name (≤30)

```text
CardWallet: Carte fedeltà
```

#### App Store — Subtitle (≤30)

```text
Senza account né pubblicità
```

#### App Store — Keywords (≤100 bytes)

```text
tessera,punti,codice a barre,qr,offline,portafoglio,negozio,socio,iban,credito,cifrato,widget,watch
```

#### App Store — Promotional Text (≤170)

```text
Novità della 2.1: blocco automatico, Amex e Diners Club, codici a barre più luminosi. Le tue carte restano cifrate sull'iPhone e fuori dal backup iCloud.
```

#### App Store — Description (≤4000)

```text
CardWallet tiene le tue carte fedeltà e le tessere in un portafoglio privato sul tuo iPhone. Non serve creare un account, non ci sono pubblicità e funziona anche senza connessione.

Alla cassa apri la carta: lo schermo si illumina da solo e il lettore legge il codice a barre al primo colpo. Le tue carte sono anche sull'Apple Watch e in un widget della schermata Home.

PRIVATA FIN DALL'INIZIO
• Nessuna registrazione, nessun account
• Nessuna pubblicità
• Funziona offline
• Le carte sono salvate cifrate sul tuo dispositivo e non finiscono nel backup iCloud
• Blocco con PIN e blocco automatico; le tue carte sono nascoste quando passi da un'app all'altra

CARTE FEDELTÀ
• Scansiona un codice a barre o un QR con la fotocamera, prendilo da una foto o digitalo
• Luminosità al massimo mentre il codice a barre è aperto
• Cerca, filtra per etichetta e segna le preferite
• Condividi una carta come immagine
• App per Apple Watch e widget per aprirle al volo

ANCHE CARTE DI CREDITO E IBAN
• Tieni carte di credito e IBAN accanto alle carte fedeltà
• Copia o condividi un IBAN con un tocco
• Promemoria per pagamenti e scadenze delle carte
• Supporto per American Express e Diners Club
• Disponibile in 9 lingue

PREMIUM
La versione gratuita include 5 carte fedeltà, 2 carte di credito e 2 IBAN. Premium aggiunge:
• Carte illimitate
• Aggiunta delle carte fedeltà ad Apple Wallet
• Sblocco con Face ID o Touch ID
• Backup cifrato e ripristino, per esempio quando cambi telefono
• Codici QR per i tuoi IBAN
• Colori aggiuntivi per le carte

Premium è disponibile come abbonamento settimanale, mensile o annuale. Il pagamento viene addebitato sul tuo ID Apple. L'abbonamento si rinnova automaticamente se non viene disdetto almeno 24 ore prima della fine del periodo in corso. Puoi gestirlo o disdirlo nelle impostazioni del tuo account App Store.

CardWallet non è un'app bancaria. Non effettua pagamenti, non trasferisce denaro e non si collega alla tua banca.

Quando aggiungi una carta fedeltà ad Apple Wallet, il nome, il numero e la nota di quella carta vengono inviati al nostro servizio di firma per creare il pass. Nessun altro dato delle carte lascia il tuo dispositivo.

Termini di utilizzo: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Informativa sulla privacy: https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet: Carte fedeltà
```

#### Google Play — Short description (≤80)

```text
Carte fedeltà e codici a barre, offline e senza account né pubblicità.
```

#### Google Play — Full description (≤4000)

```text
CardWallet tiene le tue carte fedeltà e le tessere in un portafoglio privato sul tuo telefono. Non serve creare un account, non ci sono pubblicità e funziona anche senza connessione.

Alla cassa apri la carta: lo schermo si illumina da solo e il lettore legge il codice a barre al primo colpo. Metti la tua carta preferita nella schermata Home con un widget o aprila da un riquadro delle Impostazioni rapide.

Privata fin dall'inizio
• Nessuna registrazione, nessun account
• Nessuna pubblicità
• Funziona offline
• Le carte sono salvate cifrate sul tuo dispositivo e non finiscono nei backup sul cloud
• Blocco con PIN e blocco automatico; le schermate delle carte non compaiono negli screenshot né nelle app recenti

Carte fedeltà
• Scansiona un codice a barre o un QR con la fotocamera, prendilo da una foto o digitalo
• Luminosità al massimo mentre il codice a barre è aperto
• Cerca, filtra per etichetta e segna le preferite
• Condividi una carta come immagine
• Widget e riquadro delle Impostazioni rapide per aprirle al volo

Anche carte di credito e IBAN
• Tieni carte di credito e IBAN accanto alle carte fedeltà
• Copia o condividi un IBAN con un tocco
• Promemoria per pagamenti e scadenze delle carte
• Supporto per American Express e Diners Club
• Disponibile in 9 lingue

Premium
La versione gratuita include 5 carte fedeltà, 2 carte di credito e 2 IBAN. Premium aggiunge:
• Carte illimitate
• Salvataggio delle carte fedeltà in Google Wallet
• Sblocco con impronta digitale o riconoscimento del volto
• Backup cifrato e ripristino, per esempio quando cambi telefono
• Codici QR per i tuoi IBAN
• Colori aggiuntivi per le carte

Premium è disponibile come abbonamento settimanale, mensile o annuale con rinnovo automatico. Puoi disdirlo quando vuoi in Google Play › Pagamenti e abbonamenti.

CardWallet non è un'app bancaria. Non effettua pagamenti, non trasferisce denaro e non si collega alla tua banca.

Quando salvi una carta fedeltà in Google Wallet, il nome, il numero e la nota di quella carta vengono inviati al nostro servizio di firma per creare il pass. Nessun altro dato delle carte lascia il tuo dispositivo.

Informativa sulla privacy: https://olkan.dev/privacy/cardwallet
Termini di utilizzo: https://olkan.dev/terms/cardwallet
```

## nl-NL

### App Store

#### App Store — Name (≤30)

```text
CardWallet: Klantenkaarten
```

#### App Store — Subtitle (≤30)

```text
Offline, zonder account of ads
```

#### App Store — Keywords (≤100 bytes)

```text
klantenkaart,spaarkaart,pasjes,barcode,qr,punten,winkel,lid,iban,creditcard,versleuteld,widget,watch
```

#### App Store — Promotional Text (≤170)

```text
Nieuw in 2.1: automatisch vergrendelen, Amex en Diners Club en fellere barcodes. Je kaarten blijven versleuteld op je iPhone en buiten de iCloud-reservekopie.
```

#### App Store — Description (≤4000)

```text
CardWallet bewaart je klantenkaarten en ledenpassen in een privé wallet op je iPhone. Je hoeft geen account te maken, er is geen reclame en de app werkt ook zonder internet.

Open bij de kassa je kaart: het scherm wordt vanzelf fel en de scanner leest je barcode in één keer. Je kaarten staan ook op je Apple Watch en in een widget op je beginscherm.

PRIVÉ VANAF HET BEGIN
• Geen registratie, geen account
• Geen reclame
• Werkt offline
• Kaarten worden versleuteld op je apparaat bewaard en zitten niet in de iCloud-reservekopie
• Vergrendeling met pincode en automatisch vergrendelen; je kaarten zijn verborgen in de appkiezer

KLANTENKAARTEN
• Scan een barcode of QR-code met de camera, kies hem uit een foto of typ hem in
• Volle helderheid zolang een barcode open is
• Zoek, filter op labels en markeer favorieten
• Deel een kaart als afbeelding
• Apple Watch-app en widget om ze snel te openen

OOK VOOR CREDITCARDS EN IBAN'S
• Bewaar creditcards en IBAN's naast je klantenkaarten
• Kopieer of deel een IBAN met één tik
• Herinneringen voor betaal- en vervaldatums van je creditcards
• Ondersteunt American Express en Diners Club
• Beschikbaar in 9 talen

PREMIUM
De gratis versie bevat 5 klantenkaarten, 2 creditcards en 2 IBAN's. Premium voegt toe:
• Onbeperkt kaarten
• Klantenkaarten toevoegen aan Apple Wallet
• Ontgrendelen met Face ID of Touch ID
• Versleutelde back-up en herstel, bijvoorbeeld als je overstapt naar een nieuwe telefoon
• QR-codes voor je IBAN's
• Extra kaartkleuren

Premium is er als week-, maand- of jaarabonnement. De betaling loopt via je Apple ID. Het abonnement wordt automatisch verlengd, tenzij je het minstens 24 uur voor het einde van de lopende periode opzegt. Beheren of opzeggen doe je in de instellingen van je App Store-account.

CardWallet is geen bankapp. De app doet geen betalingen, maakt geen geld over en maakt geen verbinding met je bank.

Voeg je een klantenkaart toe aan Apple Wallet, dan worden de naam, het nummer en de notitie van die kaart naar onze ondertekeningsdienst gestuurd om de pas te maken. Geen andere kaartgegevens verlaten je apparaat.

Gebruiksvoorwaarden: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacybeleid: https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet: Klantenkaarten
```

#### Google Play — Short description (≤80)

```text
Klantenkaarten en barcodes in een privé wallet. Zonder account, zonder reclame.
```

#### Google Play — Full description (≤4000)

```text
CardWallet bewaart je klantenkaarten en ledenpassen in een privé wallet op je telefoon. Je hoeft geen account te maken, er is geen reclame en de app werkt ook zonder internet.

Open bij de kassa je kaart: het scherm wordt vanzelf fel en de scanner leest je barcode in één keer. Zet je favoriete kaart met een widget op je startscherm of open hem via een tegel in Snelle instellingen.

Privé vanaf het begin
• Geen registratie, geen account
• Geen reclame
• Werkt offline
• Kaarten worden versleuteld op je apparaat bewaard en zitten niet in cloudback-ups
• Vergrendeling met pincode en automatisch vergrendelen; kaartschermen zijn verborgen in screenshots en recente apps

Klantenkaarten
• Scan een barcode of QR-code met de camera, kies hem uit een foto of typ hem in
• Volle helderheid zolang een barcode open is
• Zoek, filter op labels en markeer favorieten
• Deel een kaart als afbeelding
• Widget en tegel in Snelle instellingen om ze snel te openen

Ook voor creditcards en IBAN's
• Bewaar creditcards en IBAN's naast je klantenkaarten
• Kopieer of deel een IBAN met één tik
• Herinneringen voor betaal- en vervaldatums van je creditcards
• Ondersteunt American Express en Diners Club
• Beschikbaar in 9 talen

Premium
De gratis versie bevat 5 klantenkaarten, 2 creditcards en 2 IBAN's. Premium voegt toe:
• Onbeperkt kaarten
• Klantenkaarten opslaan in Google Wallet
• Ontgrendelen met vingerafdruk of gezichtsherkenning
• Versleutelde back-up en herstel, bijvoorbeeld als je overstapt naar een nieuwe telefoon
• QR-codes voor je IBAN's
• Extra kaartkleuren

Premium is er als week-, maand- of jaarabonnement dat automatisch wordt verlengd. Opzeggen kan altijd via Google Play › Betalingen en abonnementen.

CardWallet is geen bankapp. De app doet geen betalingen, maakt geen geld over en maakt geen verbinding met je bank.

Sla je een klantenkaart op in Google Wallet, dan worden de naam, het nummer en de notitie van die kaart naar onze ondertekeningsdienst gestuurd om de pas te maken. Geen andere kaartgegevens verlaten je apparaat.

Privacybeleid: https://olkan.dev/privacy/cardwallet
Gebruiksvoorwaarden: https://olkan.dev/terms/cardwallet
```

## pl-PL

### App Store

#### App Store — Name (≤30)

```text
CardWallet: Portfel na karty
```

#### App Store — Subtitle (≤30)

```text
Karty lojalnościowe offline
```

#### App Store — Keywords (≤100 bytes)

```text
kod kreskowy,qr,punkty,bez konta,bez reklam,sklep,klub,iban,kredytowa,szyfrowanie,widżet,watch
```

#### App Store — Promotional Text (≤170)

```text
Nowość w 2.1: automatyczna blokada, Amex i Diners Club oraz jaśniejsze kody kreskowe. Karty zostają zaszyfrowane na iPhonie, poza kopią iCloud.
```

#### App Store — Description (≤4000)

```text
CardWallet trzyma Twoje karty lojalnościowe i członkowskie w prywatnym portfelu na iPhonie. Nie musisz zakładać konta, nie ma reklam, a aplikacja działa też bez internetu.

Przy kasie otwierasz kartę, ekran sam się rozjaśnia, a czytnik odczytuje kod kreskowy za pierwszym razem. Karty masz też na Apple Watch i w widżecie na ekranie początkowym.

PRYWATNOŚĆ OD POCZĄTKU
• Bez rejestracji i bez konta
• Bez reklam
• Działa offline
• Karty są zapisywane w postaci zaszyfrowanej na urządzeniu i nie trafiają do kopii iCloud
• Blokada PIN-em i automatyczna blokada; przy przełączaniu aplikacji karty są zasłonięte

KARTY LOJALNOŚCIOWE
• Zeskanuj kod kreskowy lub QR aparatem, wybierz go ze zdjęcia albo wpisz ręcznie
• Pełna jasność ekranu, dopóki kod kreskowy jest otwarty
• Wyszukuj, filtruj po etykietach i oznaczaj ulubione
• Udostępnij kartę jako obraz
• Aplikacja na Apple Watch i widżet do szybkiego otwierania

TAKŻE KARTY PŁATNICZE I IBAN
• Trzymaj karty kredytowe i numery IBAN obok kart lojalnościowych
• Kopiuj lub udostępniaj IBAN jednym dotknięciem
• Przypomnienia o terminie płatności i ważności karty
• Obsługa American Express i Diners Club
• Dostępna w 9 językach

PREMIUM
Wersja bezpłatna obejmuje 5 kart lojalnościowych, 2 karty kredytowe i 2 numery IBAN. Premium dodaje:
• Nieograniczoną liczbę kart
• Dodawanie kart lojalnościowych do Apple Wallet
• Odblokowywanie przez Face ID lub Touch ID
• Szyfrowaną kopię zapasową i przywracanie, np. przy zmianie telefonu
• Kody QR dla numerów IBAN
• Dodatkowe kolory kart

Premium jest dostępne jako subskrypcja tygodniowa, miesięczna lub roczna. Opłata jest pobierana z Twojego Apple ID. Subskrypcja odnawia się automatycznie, jeśli nie zostanie anulowana co najmniej 24 godziny przed końcem bieżącego okresu. Możesz nią zarządzać lub ją anulować w ustawieniach konta App Store.

CardWallet nie jest aplikacją bankową. Nie wykonuje płatności, nie przelewa pieniędzy i nie łączy się z Twoim bankiem.

Gdy dodajesz kartę lojalnościową do Apple Wallet, jej nazwa, numer i notatka są wysyłane do naszej usługi podpisywania, żeby utworzyć kartę w Wallet. Żadne inne dane kart nie opuszczają urządzenia.

Warunki korzystania: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Polityka prywatności: https://olkan.dev/privacy/cardwallet
```

### Google Play

#### Google Play — Title (≤30)

```text
CardWallet: Portfel na karty
```

#### Google Play — Short description (≤80)

```text
Karty lojalnościowe i kody kreskowe w prywatnym portfelu. Bez konta i reklam.
```

#### Google Play — Full description (≤4000)

```text
CardWallet trzyma Twoje karty lojalnościowe i członkowskie w prywatnym portfelu na telefonie. Nie musisz zakładać konta, nie ma reklam, a aplikacja działa też bez internetu.

Przy kasie otwierasz kartę, ekran sam się rozjaśnia, a czytnik odczytuje kod kreskowy za pierwszym razem. Ulubioną kartę możesz przypiąć widżetem do ekranu głównego albo otworzyć kafelkiem w Szybkich ustawieniach.

Prywatność od początku
• Bez rejestracji i bez konta
• Bez reklam
• Działa offline
• Karty są zapisywane w postaci zaszyfrowanej na urządzeniu i nie trafiają do kopii w chmurze
• Blokada PIN-em i automatyczna blokada; ekrany kart są ukryte na zrzutach ekranu i w ostatnich aplikacjach

Karty lojalnościowe
• Zeskanuj kod kreskowy lub QR aparatem, wybierz go ze zdjęcia albo wpisz ręcznie
• Pełna jasność ekranu, dopóki kod kreskowy jest otwarty
• Wyszukuj, filtruj po etykietach i oznaczaj ulubione
• Udostępnij kartę jako obraz
• Widżet i kafelek w Szybkich ustawieniach do szybkiego otwierania

Także karty płatnicze i IBAN
• Trzymaj karty kredytowe i numery IBAN obok kart lojalnościowych
• Kopiuj lub udostępniaj IBAN jednym dotknięciem
• Przypomnienia o terminie płatności i ważności karty
• Obsługa American Express i Diners Club
• Dostępna w 9 językach

Premium
Wersja bezpłatna obejmuje 5 kart lojalnościowych, 2 karty kredytowe i 2 numery IBAN. Premium dodaje:
• Nieograniczoną liczbę kart
• Zapisywanie kart lojalnościowych w Google Wallet
• Odblokowywanie odciskiem palca lub rozpoznawaniem twarzy
• Szyfrowaną kopię zapasową i przywracanie, np. przy zmianie telefonu
• Kody QR dla numerów IBAN
• Dodatkowe kolory kart

Premium jest dostępne jako subskrypcja tygodniowa, miesięczna lub roczna, odnawiana automatycznie. Możesz ją anulować w dowolnej chwili w Google Play › Płatności i subskrypcje.

CardWallet nie jest aplikacją bankową. Nie wykonuje płatności, nie przelewa pieniędzy i nie łączy się z Twoim bankiem.

Gdy zapisujesz kartę lojalnościową w Google Wallet, jej nazwa, numer i notatka są wysyłane do naszej usługi podpisywania, żeby utworzyć kartę w Wallet. Żadne inne dane kart nie opuszczają urządzenia.

Polityka prywatności: https://olkan.dev/privacy/cardwallet
Warunki korzystania: https://olkan.dev/terms/cardwallet
```
