# Deckard 2.2.0 (46) — Mağaza görselleri, ASO ve API ile yükleme

24 Ekim 2026. Her şey 9 pazar için hazır: ABD, Almanya, Türkiye, Fransa, İspanya, İtalya, Hollanda, Polonya, Brezilya.

## Klasörler

| Ne | Nerede | Boyut / adet |
|---|---|---|
| App Store ekran görüntüleri | `fastlane/screenshots/<dil>/iPhone69_1..6.png` | 1290×2796 (6.9" yuvası), 6 kare |
| App Store creative assets (ürün sayfası başlığı) | `fastlane/creative_assets/<dil>/header_5244x2950.png` | 5244×2950 |
| App Store creative assets (arama sonucu) | `fastlane/creative_assets/<dil>/search_3840x2560.png` | 3840×2560 |
| App Store metinleri | `fastlane/metadata/ios/<dil>/` | isim, alt başlık, anahtar kelimeler, promosyon, açıklama, sürüm notu |
| Play ekran görüntüleri | `fastlane/metadata/android/<dil>/images/phoneScreenshots/1..6.png` | 1080×1920, 6 kare |
| Play öne çıkan görsel | `fastlane/metadata/android/<dil>/images/featureGraphic.png` | 1024×500 |
| Play metinleri | `fastlane/metadata/android/<dil>/` | başlık, kısa ve tam açıklama, `changelogs/46.txt` |
| Play 4. kare, Wear OS'suz | `fastlane/alt/android/<dil>/4_without_wear.png` | Wear OS yayına girene kadar bunu kullan |
| Wear OS ekran görüntüleri | `fastlane/later/wear/<dil>/1.png` | yuvarlak, Wear yüklenince |

App Store dil klasörleri: `en-US, de-DE, tr, fr-FR, es-ES, it, nl-NL, pl, pt-BR`. Play: `en-US, de-DE, tr-TR, fr-FR, es-ES, it-IT, nl-NL, pl-PL, pt-BR`.

Görseller git'e girmiyor (~120 MB, `.gitignore`'da). Metinler ve üretici betikler commit'li.

## 6 kare

| # | Konu | iOS | Android |
|---|---|---|---|
| 1 | Doğru kart, tam kasada | "Sıradaki" kutusu telefondan taşar | aynı |
| 2 | Parlak barkod | barkod paneli taşar, arka plan o pazarın ilk markasının rengi | aynı |
| 3 | IBAN paylaş (FR'de RIB) | IBAN kartı taşar. ABD ve Brezilya'da IBAN yok → ızgara görünümü | aynı |
| 4 | Kilit ekranında ve bileğinde | kilit ekranı widget'ı + ana ekran widget'ları + Apple Watch | gerçek ana ekranda widget + Wear OS saati |
| 5 | Kartı okut | kart okutma onayı, yerel marka | aynı |
| 6 | Ödeme günü | banka kartı + hatırlatıcılar | aynı |

Her pazarda gerçek yerel markalar (logo yok, ad ve renk), yerel kişi adı, o ülkenin IBAN biçimi, yerel banka kartı adları; ikinci kart Mastercard, Türkiye'de Troy. Bütün ekranlar uygulamanın kendisinden; widget'lar widget'ın kendi SwiftUI koduyla, saat görüntüleri Apple Watch ve Wear OS simülatörlerinden.

## ASO

Kurallar: rakip adı yok (Apple 2.3.7, Play politikası; `build.py` yakalıyor), anahtar kelimeler isim ve alt başlıktakileri tekrarlamıyor (Apple onları zaten indeksliyor; `build.py` yakalıyor), virgülden sonra boşluk yok, bayt sınırı (ğ, ü, ł 2 bayt).

| Dil | App Store adı | Alt başlık | Anahtar kelime fikri |
|---|---|---|---|
| en-US | Deckard: Loyalty Card Wallet | Rewards, barcodes & bank cards | "loyalty card" + "wallet" başlıkta; membership, points, gym, library, keyring |
| de-DE | Deckard: Kundenkarten App | Bonuskarten, Barcodes & IBAN | Almanya'da arama "Kundenkarten App"; treuekarte, mitgliedskarte, geldbörse |
| tr | Deckard: Sadakat Kartı Cüzdan | Barkod, IBAN ve kart saklama | IBAN Türkiye'de güçlü; puan, müşteri, market, indirim |
| fr-FR | Deckard : Cartes de fidélité | Codes-barres, RIB et cartes | Fransa'da IBAN yerine RIB aranır; adherent, enseigne |
| es-ES | Deckard: Tarjetas fidelidad | Códigos de barras, IBAN y más | socio, monedero, cliente |
| it | Deckard: Carte fedeltà | Tessere, codici a barre e IBAN | "tessere" İtalya'ya özgü; raccolta punti |
| nl-NL | Deckard: Klantenkaarten | Spaarkaarten, barcodes & IBAN | pasjes, spaarkaart |
| pl | Deckard: Karty lojalnościowe | Kody kreskowe, IBAN i karty | karta stałego klienta, rabat |
| pt-BR | Deckard: Cartão Fidelidade | Carteira de cartões e códigos | IBAN yok (Brezilya'da Pix); sócio, clube, programa |

Play başlığı App Store adıyla aynı; Play kısa açıklaması (≤80) anahtar kelimeyle başlıyor.

Açıklamalarda düzeltilenler:
- Premium paragrafı: "haftalık, aylık, yıllık" yerine "aylık veya yıllık abonelik ya da tek seferlik ömür boyu" (9 dil, iki mağaza). Fiyat yazılmadı; mağaza kendi gösteriyor.
- "700+ marka" → "500+" (katalogda 596 marka).

Sınır kontrolü: `python3 tools/store_listing/build.py` her alanı sayıyor, aşan ya da kuralı bozan olursa durur. Son çalıştırma: 9 dil, hepsi sınırın altında.

## API ile yükleme (fastlane)

Gerekenler (bir kerelik):
1. **App Store Connect API anahtarı:** Users and Access › Integrations › App Store Connect API › yeni anahtar (rol: App Manager). `.p8` dosyasını indir ve şu JSON'u oluştur (repo dışında):
   ```json
   {"key_id": "XXXXXXXXXX", "issuer_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----", "in_house": false}
   ```
2. **Google Play servis hesabı:** Play Console › Kullanıcılar ve izinler'den bir servis hesabına "Mağaza girişini yönet" izni ver, JSON anahtarını indir (repo dışında).
3. fastlane'i güncelle: `gem install fastlane` (kurulu 2.218 eski).
4. App Store Connect'te **nl-NL, pl, pt-BR dilleri yoksa ekle**; 2.2.0 sürümü oluşturulmuş olmalı.

Yükleme:
```sh
python3 tools/store_listing/build.py      # metinler
python3 tools/store_shots/compose.py      # görseller (ham çekimler .context/store_raw'da)
ASC_API_KEY_PATH=~/.deckard_keys/asc.json fastlane ios metadata
PLAY_JSON_KEY=~/.deckard_keys/play.json fastlane android metadata
```
- iOS: metin + ekran görüntüleri, 9 dil. Binary yüklemez, incelemeye göndermez.
- Android: metin + ekran görüntüleri + öne çıkan görsel, 9 dil. AAB yüklemez, sürüm notunu yüklemez (o, sürümle birlikte gider).
- **Wear OS yayına girmeden önce** Android'de `phoneScreenshots/4.png` yerine `fastlane/alt/android/<dil>/4_without_wear.png` kullan; olmayan bir cihazı göstermek politika riski.

Elle kalanlar:
- **Creative assets** (başlık ve arama görseli): fastlane bu yeni alanı henüz desteklemiyor. App Store Connect › sürüm › Creative Assets'e sürükle bırak; dil başına 1 başlık + 1 arama görseli. Görsellerde fiyat, URL, başka platform ya da "1 numara" gibi iddia yok (kural 2.3.14).
- Uygulama adı değişikliği mağazada benzersiz olmalı; "Deckard: Loyalty Card Wallet" alınmışsa App Store Connect uyarır.

## Görselleri yeniden üretmek

Ham çekimler `.context/store_raw/` altında (git dışı). Akış ve betikler `tools/store_shots/capture/`:
- Demo veri: `demo_seed_splash.patch`, yalnızca yerel çekim kopyasına (`.context/runapp`) uygulanır; mağaza sürümünde yok. 9 pazarın kartları, isimleri, IBAN'ları orada.
- Android: `android_all.sh` / `acap.sh` (emülatör `emulator-5556`, durum çubuğu 9:41 demo modu), `awidget.sh` (ana ekran widget'ı), `wear_cap.py` (Wear emülatörü `emulator-5558`).
- iOS: `ios_sync.sh` yerel bir iOS kopyası (`.context/iosrun`) hazırlar: ML Kit'in iOS parçası çıkarılır (Apple Silicon simülatöründe çalışmıyor), bildirim izni sorusu kapatılır, saat uygulaması ilk kartı açar. Bunların hiçbiri gerçek uygulamada değil. `ios_all.sh` 9 pazarı iPhone 17 Pro Max simülatöründe çeker.
- Widget'lar: `widgetshot/` küçük bir SwiftUI uygulaması; widget'ın kendi Swift dosyalarını (`ios/LoyaltyWidget/*.swift`) kopyalayıp görüntüye çevirir.
- Apple Watch: `watch_cap.py` saat simülatörüne kartları yazar ve çeker.
- Son olarak `compose.py` hepsini şablona yerleştirir; başlıklar `captions.json`'da.

## Wear OS'u Play'e yüklemek

Hazır: hedef API 36 (`0950bd4`), Wear Compose 1.5, yayın derlemesi küçültmeyle geçiyor, Wear OS ekran görüntüleri `fastlane/later/wear/<dil>/1.png` (454×454, yuvarlak, çerçevesiz; Play'in kuralına uygun).

1. Play Console › Test ve yayınla › Gelişmiş ayarlar › Form faktörleri › **Wear OS ekle**. Wear OS kalite kurallarını kabul et.
2. İmzalı AAB: `tools/release_build.sh android` (telefon ve Wear AAB'si birlikte; Wear sürüm kodu 100000000 + telefon).
3. `PLAY_JSON_KEY=~/keys/play.json fastlane android wear`. AAB'yi `wear:internal` kanalına **taslak** olarak yükler; yayınlamaz. Başka kanal için `track:wear:production`.
4. `fastlane android wear_screenshots`: Wear görüntülerini 9 dile yükler.
5. Wear yayına girdikten sonra Play'in 4. karesi Wear'li sürüme dönebilir (`phoneScreenshots/4.png` zaten öyle); o zamana kadar `fastlane/alt/android/<dil>/4_without_wear.png`.

## 24 Ekim yüklemesi (yapıldı)

- **App Store, 2.2.0:** 10 dilde (en-US, de-DE, tr, fr-FR, es-ES, it, nl-NL, pl, pt-BR, pt-PT) ad Deckard, alt başlık, anahtar kelimeler, açıklama, sürüm notu ve 6 ekran görüntüsü. nl-NL, pl, pt-BR yeni dil olarak eklendi; pt-PT'deki Lehçe metin pt-BR metniyle değişti. **Promosyon metni yüklenmedi** (hemen canlıya çıkıyor): sürüm günü `fastlane ios metadata promo:true`. İncelemeye gönderilmedi.
- **Google Play:** 10 dilde (yukarıdakiler + es-419, es-ES'in kopyası) başlık, kısa ve tam açıklama, 6 ekran görüntüsü (4. kare Wear OS'suz), öne çıkan görsel. **"İncelemeye gönderilmeyen değişiklikler"** olarak bekliyor: Play Console › Yayın özeti'nden bakıp gönder.
- **Elle:** App Store creative assets (`fastlane/creative_assets/<dil>/`).
- Anahtarlar `~/.deckard_keys/` altında (repo dışı, yalnız senin kullanıcın okuyabilir).

## 24 Ekim, ikinci tur

- App Store ana dili **en-US** (önce tr idi): yerelleştirmesi olmayan ülkelerde İngilizce sayfa çıkar.
- Yeni diller, iki mağazada: **en-GB** (Tesco, Boots, Nectar; İngiliz yazımı), **es-MX** / Play **es-419** (OXXO, Walmart México, Liverpool; ABD mağazası es-MX anahtar kelimelerini de indeksler), **pt-PT** (Continente, Pingo Doce, Worten; Avrupa Portekizcesiyle yazıldı, `tools/store_listing/texts/pt-PT.json`). pt-PT ve es-419 artık başka dilin kopyası değil.
- Toplam 12 dil. Creative assets bu üç dil için de `fastlane/creative_assets/{en-GB,es-MX,pt-PT}/`.
- Avustralya ve Kanada: **en-AU** (Woolworths, Coles, Flybuys), **en-CA** ve **fr-CA** (Tim Hortons, PC Optimum, Air Miles, Sobeys). fr-CA, fr-FR metninden; RIB yerine IBAN. Toplam 15 dil.
