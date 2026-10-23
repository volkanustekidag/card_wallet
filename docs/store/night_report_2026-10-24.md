# Gece raporu — 24 Ekim 2026

Kapsam: uygulamayı emülatörde ekran ekran gezdim (açık/koyu tema; İngilizce,
Almanca, Türkçe, Lehçe), kodu taradım, trendleri ve ASO'yu araştırdım, ülkeye
özel mağaza görselleri için ön çalışma yaptım.

---

## 1. Bu gece düzelttiklerim (commit'li, push yok)

| Commit | Ne |
|---|---|
| `99e1a12` | **İlk açılış ipucu** sadece dokununca kapanıyordu; dokunulmazsa her açılışta geri geliyordu. Artık 8 saniye sonra ya da cüzdan kaydırılınca kendiliğinden kapanıyor ve bir daha çıkmıyor. |
| `0330776` | **Kasa ekranında "QR Code · doğrulandı" kesiliyordu** (Türkçe). Sebebi yerleşimdi: yazıya boş alanın sadece yarısı kalıyordu. Bütün dillerde düzeldi, testi var. Ayrıca "Sıradaki" kartının alt yazısı Türkçe ve Fransızcada sığmıyordu, kısalttım. |

Testler: 386/386 geçiyor.

## 2. Neler yolunda

- **Tasarım tutarlı.** Ana sayfa (deste + ızgara), kasa ekranı, banka kartı, IBAN paylaşımı, tarama onayı, ayarlar, paywall ve onboarding açık ve koyu temada düzgün. Almanca, Türkçe ve Lehçede taşma görmedim (yukarıdakiler hariç).
- **Boş cüzdan (ilk açılış) güçlü.** "Add your first card" kartı ve 4 hızlı başlangıç satırı var. Ücretsiz sınır ekleme ekranında baştan yazıyor ("0 of 3 free").
- **Gizlilik ve yayın ayarları:** hassas veri loglanmıyor, reklam kimliği ve mikrofon gibi gereksiz izinler kaldırılmış. Telefon uygulaması API 36 hedefliyor (Play'in Ağustos 2026 şartı karşılanıyor). Yayın sürümünde küçültme açık.
- **Animasyonlar:** banka kartı ve IBAN, desteden kahraman (hero) geçişiyle açılıyor. Üst bar kaydırınca küçülüyor. 60 yerde dokunsal geri bildirim var. Genel his akıcı.

## 3. En önemli bulgu: iOS 27 Apple Wallet artık her barkodlu kartı ekliyor

iOS 27 ile (Eylül 2026) Wallet, kamerayla, ekran görüntüsünden ya da elle her barkodlu
kartı pass'e çevirebiliyor. Bizim temel ücretsiz kullanım senaryomuzu iPhone'da
işletim sistemi bedavaya veriyor. Panik gerektirmez ama mesajı değiştirmeliyiz.
"Kartlarını telefonda tut" artık tek başına satış cümlesi değil.

Wallet'ın yapmadıkları (bizim farkımız):
- Sıradaki: saate göre doğru kartı öne çıkarmak, widget, saat
- Android: aynı cüzdan iki platformda, yedekle taşınır
- Banka kartında ödeme/son kullanma hatırlatıcısı; IBAN'ı görsel ya da QR ile paylaşmak
- Klasörler, kendi sıran, kart fotoğrafları (ön/arka), toplu içe aktarma
- Hesap yok, internet yok, şifreli yedek

Sonuç: mağaza metni ve görselleri "kartları sakla"dan **"kasada doğru kart, kendiliğinden"**
ve **"kartlar + banka + IBAN tek yerde"** çizgisine kaymalı. Apple Wallet'a rakip gibi
değil, "Wallet'a da gönderebilirsin" diye tamamlayıcı konumlanmalı. Wallet'a aktarma
özelliğimiz zaten var.

İkinci fırsat: Stocard kapandı, kartlar Klarna'ya taşındı. Klarna'da kart görmek için
hesap ve internet gerekiyor; kullanıcılar şikâyetçi. "Hesap yok, çevrimdışı çalışır,
içe aktar" mesajı tam bu kitleye oturuyor. Mağaza metninde rakip adı geçmemeli (kararımız
bu), ama yerel blog ya da landing sayfası ve forum cevapları bu kitleyi yakalar.

## 4. Uygulama için öneriler (sıralı, ilk 3)

1. **Kasa anına imza animasyon.** Sadakat kartına dokununca sayfa düz bir geçişle açılıyor; banka ve IBAN'daki "kart büyüyerek açılır" efekti burada yok. Önerim: kart desteden büyüyüp ekranı kendi rengiyle doldursun, barkod alttan yükselsin. Uygulamanın en sık kullanılan anı bu. Shorts'ta da en iyi görünecek an. Önce mockup.
2. **Kart eklerken önce marka.** Elle eklemede ilk alan "İsim", marka ikinci sırada. İnsanlar "Migros" diye düşünür. Önerim: ilk alan marka araması olsun; marka seçilince isim ve renk dolsun, "listede yok" seçeneği de yerinde dursun. Tarama yolu zaten markayı buluyor; bu sadece elle ekleme ekranı.
3. **Mesajı iOS 27'ye göre güncellemek.** Onboarding'in ilk ekranı ve mağaza metninin ilk cümlesi "Sıradaki + banka + IBAN" üzerine kurulsun (bkz. 3. bölüm). Kod değişikliği küçük, etkisi büyük.

Küçük işler (sırası önemsiz):
- Türkçede "QR Code" etiketi çevrilmemiş ("QR kod" olmalı). Diğer dillerde de barkod biçimi adları İngilizce.
- Katalogda Rossmann'ın Türkiye için alan adı `rossmann.de`; `rossmann.com.tr` olmalı. Bölge bazlı alan adı kontrolü bir tur yapılmalı.
- **Wear OS `targetSdk` 34.** Play'e yüklemeden önce 36'ya çıkmalı; yüklemeyi zaten sonraya almıştık.
- Android paketinin yaklaşık 16 MB'ı ML Kit (metin tanıma + barkod) modelleri. Play Services üzerinden indirilen modellere geçilirse indirme boyutu ciddi düşer. Acil değil.
- Kamera izni "+"ya basınca doğrudan soruluyor. Öncesinde tek cümlelik bir açıklama ekranı izin oranını artırır. Düşük öncelik.

## 5. Satın almayı artırmak için (fiyata dokunmadan)

- **Paywall'ı doğru anda göstermek.** Bağlam satırları zaten var ("3 kart sınırına geldin" gibi). Ek olarak ilk "değer anından" sonra, örneğin bir kartın 3. kez kasada açılmasından sonra, tek seferlik ve kapatılabilir bir Premium kartı gösterilebilir. Kullanıcı faydayı gördükten sonra sormak, sınırda sormaktan daha iyi çalışır.
- **Paylaşılan görseller reklam olsun.** IBAN ve kart paylaşım görsellerinde küçük "Deckard" işareti var. Yanına mağaza kısa linki ya da "deckard ile paylaşıldı" eklenirse her paylaşım bir indirme kaynağı olur.
- **Aile paylaşımı (Family Sharing).** App Store'da abonelik ve ömür boyu ürün için açılabilen bir ayar; "ailecek kullan" algısı yıllık ve ömür boyunu değerli gösterir. Bu bir mağaza ayarı, karar senin.
- Premium özelliklerinin ilk görüldüğü yerde (metal kart rengi, IBAN QR) önizleme gösterip kilidi orada açtırmak; bazıları bunu zaten yapıyor, bir tur gözden geçirilebilir.

## 6. Kullanıcı sayısını artırmak için

- **Ülkeye özel mağaza görselleri** (bkz. 7. bölüm). Araştırmalarda yerel görsellerin dönüşümü belirgin artırdığı söyleniyor; çevrilmiş başlıktan çok yerel içerik fark yaratıyor. Rakamlar satıcı bloglarından, yön olarak doğru, kesin değil. Apple'ın Product Page Optimization'ıyla kendi pazarımızda test edebiliriz.
- **Apple "creative assets" (iOS 27).** Ürün sayfası başlığında ve arama sonuçlarında ekran görüntüleri yerine görünen görsel ve video. Ülke bazında yerelleştirilebiliyor. Kurallar (2.3.14): fiyat ya da indirim yok, URL yok, doğrulanamaz iddia ("1 numaralı" gibi) yok, başka platform logosu yok, 4+ uygun olmalı. Ekran görüntüleriyle birlikte hazırlayalım.
- **Shorts fikirleri** (her ülkede kendi markasıyla çekilir):
  - "POV: kasadasın, kart cüzdanda değil" → kilit ekranındaki widget'tan tek dokunuşla barkod.
  - "Telefonum hangi kartı istediğimi biliyor" → sabah kahvecide, akşam markette Sıradaki kartı.
  - "IBAN'ı yazdırmak yerine…" → IBAN görseli ya da QR paylaşımı (TR, DE ve NL'de çok güçlü).
  - "Stocard gitti, kartlarım nereye?" → içe aktarma. Rakip adı videoda geçebilir, mağaza metninde geçmez.
- Klarna/Stocard kitlesi için 9 dilde kısa bir "kartlarını taşı" sayfası, forum ve Reddit cevapları.

## 7. Ülkeye özel ekran görüntüleri — ön çalışma

Görsel: `docs/store/screenshots_prep/overview_us_de_tr.png` (ABD, Almanya, Türkiye — 6 kare).
Ekranlar gerçek uygulamadan, o ülkenin dilinde ve verisiyle çekildi:
- yerel markalar (ABD: Starbucks, Target, Ulta; DE: REWE, dm, Payback; TR: Migros, Kahve Dünyası, D&R)
- yerel isim (Alex Morgan / Lena Fischer / Ayşe Yılmaz)
- o ülkenin IBAN biçimi
- 9:41 durum çubuğu

**Pazara göre kare sırası farklı:** ABD'de IBAN yok, onun yerine "Sıradaki" ve ızgara var.
DE ve TR'de IBAN paylaşımı 3. karede. IBAN orada günlük ihtiyaç.

**Markalar konusunda dikkat:** karelerde marka adı ve rengi var, **logo yok**. Uygulama
da logo yerine harf gösteriyor. Apple başkasının markasını kullanmayı (5.2.1) sorabilir.
Sadakat uygulamalarında yaygın bir pratik, ama reddedilirsek yedek planımız hazır olmalı:
aynı kareler yerel ama hayalî adlarla ("Bäckerei Krume", "Köşe Fırın"). Önerim: ilk
gönderimde gerçek adlarla deneyelim, red gelirse 1 saatte değiştiririz (veri tek dosyada).

**Diğer pazarlar için seçtiğim markalar** (katalogdan, tier 1):

| Pazar | Markalar |
|---|---|
| UK | Tesco, Sainsbury's, Boots, Nectar, Costa Coffee |
| FR | Carrefour, E.Leclerc, Fnac, Leroy Merlin, Intermarché |
| ES | Carrefour, El Corte Inglés, Dia, MediaMarkt, Douglas |
| IT | Esselunga, Conad, Coop, MediaWorld, Douglas |
| NL | Albert Heijn, Jumbo, Kruidvat, NS, MediaMarkt |
| PL | Biedronka, Żabka, Rossmann, Empik, Orlen |
| BR | Pão de Açúcar, Drogasil, Livelo, Renner, Ipiranga |

Altyapı hazır: yeni pazar eklemek veri tablosuna 1 satır, çekimi tek komut.
Karar verdiğinde: (1) başlık metinlerini 9 dilde kesinleştiririz, (2) iPhone 6.9"
(1290×2796) ve Play boyutlarında tam çözünürlük çıkarırız, (3) creative asset
başlık görselleri ve feature graphic.

## 8. Sabah için kararların

1. Yukarıdaki 3 uygulama önerisinden hangileri? (animasyon / önce marka / mesaj)
2. Mağaza görselleri: başlık tonu ve kare sırası okey mi, gerçek marka adlarıyla mı gidelim?
3. Yeni TestFlight için build 46: bu geceki iki düzeltme dahil.

## Kaynaklar

- iOS 27 Wallet: [9to5Mac](https://9to5mac.com/2026/09/25/apple-wallet-in-ios-27-adds-feature-thats-been-on-my-wishlist-for-years/), [MacRumors](https://www.macrumors.com/guide/ios-27-wallet/), [Tom's Guide](https://www.tomsguide.com/phones/iphones/the-clever-ios-27-wallet-upgrade-that-means-you-will-never-have-to-carry-a-physical-loyalty-card-again)
- Stocard → Klarna: [Vamers](https://vamers.com/2026/03/20/klarna-stocard-barcodes-loyalty/), [Finextra](https://www.finextra.com/pressarticle/93089/klarna-adds-loyalty-card-feature), [ScanKeeper](https://scankeeper.app/klarna-stocard-loyalty-cards/)
- Creative assets / 2.3.14: [Apple Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [Apple Developer News](https://developer.apple.com/news/?id=92th7e5i), [Admiral Media](https://admiral.media/app-store-creative-assets/), [PPC Land](https://ppc.land/apples-rule-2-3-14-bans-discount-prices-in-app-store-creative-assets/)
- Yerelleştirme ve dönüşüm: [Screenhance](https://screenhance.com/blog/state-of-app-store-screenshots-2026), [AppScreenMagic](https://appscreenmagic.com/guides/how-to-localize-app-screenshots), [AppScreens](https://appscreens.com/blog/app-store-screenshot-optimization)
- Abonelik: [RevenueCat State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps), [Utilities](https://www.revenuecat.com/state-of-subscription-apps-2026-utilities)
- Play kuralları: [Appbot](https://appbot.co/blog/google-play-app-store-changes/), [12AppTester](https://www.12apptester.com/guides/what-is-google-changing-android-apps-2026)
