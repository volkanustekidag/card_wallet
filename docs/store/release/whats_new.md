# Deckard 2.2.0 (45) — Sürüm notları

Konsola kopyalanacak "What's new" / "Bu sürümdeki yenilikler" metinleri. 2.1.0 ayrı yayınlanmıyor; bu metinler 2.0.0'dan sonraki her şeyi (2.1 + 2.2 değişiklikleri) tek sürüm olarak anlatıyor.

- **Google Play** → Release › Release notes, dil başına `<tr-TR>…</tr-TR>` bloğu. Sınır 500 karakter.
- **App Store Connect** → 2.2.0 sürümü › What's New in This Version. Sınır 4000 karakter.

Sıralama: kullanıcının ilk fark edeceği değişiklikler başta (ücretsiz biyometrik, arama, IBAN görseli, sıralama), ardından güvenlik ve kasada kullanım, en sonda dil ve düzeltmeler.

Neden iki ayrı metin var:
- Play metni Android'e göre yazıldı ve 500 karaktere sığması için kısaltıldı. iCloud, app switcher ve Apple Watch maddeleri iOS'a özel olduğu için çıkarıldı. Android zaten yedeğe kart verisi koymuyordu (`allowBackup=false`) ve son uygulamalarda kartları zaten gizliyordu (`FLAG_SECURE`). Pano önizlemesi ve IBAN tarama maddeleri yer olmadığı için yalnızca App Store metninde.
- "Telefon değiştirirken şifreli yedeği kullan" cümlesinin yanında **(Premium)** yazıyor, çünkü yedekleme/geri yükleme Premium'a bağlı (`openPremiumGate('backupRestore')`).
- IBAN görsel paylaşımı ücretsiz; görseldeki ödeme QR'ı Premium. Metinde ikisi ayrı yazıldı ki ücretsiz kullanıcı QR beklemesin.
- IBAN tarama kodda hiç kilitli değildi, sadece paywall onu Premium gibi listeliyordu. Bu yüzden "artık ücretsiz" demiyoruz, "herkes için ücretsiz" diyoruz.
- Ayar/ekran adları uygulamadaki etiketlerden alındı (`autoLock`, `sectionSecurity`, `barcodeBrightnessTitle`, `shareAsImage`, `sortMostUsed`, `globalSearchTooltip`).

- **v2 tasarım:** Play metni yeniden yazıldı (yeni tasarım, tek kamera, Sıradaki + widget, içe aktarma, 700+ marka başta). App Store metninin başına beş maddelik "yeni Deckard" bölümü eklendi; eski "en çok kullanılanlar önde / ada veya tarihe göre sırala" maddesi çıkarıldı, çünkü sıralamayı artık Sıradaki yapıyor ve liste sayfaları ana sayfadaki segmentlere katlandı.

Uzunlukları yeniden saymak için: `python3 tools/check_store_text.py --write docs/store/release/whats_new.md`

<!-- lengths:start -->
| Dil | Alan | Uzunluk | Sınır | Durum |
|---|---|---:|---:|---|
| en-US | Google Play — What's new | 439 | 500 | ✅ |
| en-US | App Store — What's New | 2961 | 4000 | ✅ |
| tr-TR | Google Play — What's new | 422 | 500 | ✅ |
| tr-TR | App Store — What's New | 2970 | 4000 | ✅ |
| de-DE | Google Play — What's new | 455 | 500 | ✅ |
| de-DE | App Store — What's New | 3316 | 4000 | ✅ |
| fr-FR | Google Play — What's new | 468 | 500 | ✅ |
| fr-FR | App Store — What's New | 3477 | 4000 | ✅ |
| es-ES | Google Play — What's new | 462 | 500 | ✅ |
| es-ES | App Store — What's New | 3158 | 4000 | ✅ |
| pt-BR | Google Play — What's new | 436 | 500 | ✅ |
| pt-BR | App Store — What's New | 3132 | 4000 | ✅ |
| it-IT | Google Play — What's new | 438 | 500 | ✅ |
| it-IT | App Store — What's New | 3107 | 4000 | ✅ |
| nl-NL | Google Play — What's new | 456 | 500 | ✅ |
| nl-NL | App Store — What's New | 3144 | 4000 | ✅ |
| pl-PL | Google Play — What's new | 444 | 500 | ✅ |
| pl-PL | App Store — What's New | 3159 | 4000 | ✅ |
<!-- lengths:end -->

---

## en-US

#### Google Play — What's new (≤500)

```text
• All-new design: your wallet as a stack of real-looking cards
• One camera adds anything: loyalty barcodes, bank cards, IBANs
• Up Next shows the card you usually need at this hour
• Up Next widget on your home screen
• Bring your cards over from your old app in one go
• 700+ brands recognized with logo and colors
• Fingerprint and face unlock free for everyone
• Search all cards, share an IBAN as an image
• 9 languages and many fixes
```

#### App Store — What's New (≤4000)

```text
• A new Deckard
The whole app is redesigned. Your wallet is now a stack of cards that look like the real thing, with their brand colors and logos. Tap any card to open it.

• One camera for every card
Tap + and point at a loyalty card, a bank card or an IBAN. Barcodes are read instantly, card numbers and IBANs in a moment, and you confirm before anything is saved. Works from a photo too.

• Up Next
Deckard learns which card you use at which time of day, on your iPhone only, and puts it first on the home screen and in the new Up Next widget on your home and lock screen.

• Bring your cards over
Moving from another app? Import its export file, a spreadsheet or an Apple Wallet pass from Settings › Import from another app.

• 700+ brands from every country
Cards are matched with their logo and colors automatically, and you can always use your own name for any store.

• Face ID and Touch ID for everyone
Unlocking with Face ID or Touch ID is now free. Turn it on in Settings › Security. If you don't have a PIN yet, the app helps you create one first.

• Search all your cards
Tap the search button on the home screen to find any credit card, IBAN or loyalty card by name, bank, brand, tag or last 4 digits. Accents and capital letters don't matter.

• Share an IBAN as an image
Send your IBAN as a clean card image with the account holder, bank and IBAN, ready for any chat. With Premium, the image also carries a payment QR code. Sharing as text is still there.

• Auto-lock
If you use a PIN, Deckard now locks itself when you leave the app. Choose the timing in Settings › Security › Auto-lock: immediately, after 30 seconds, or after 1, 5 or 15 minutes.

• Hidden in the app switcher
Your cards are covered when you switch between apps, so nobody can glance at them.

• Your cards stay on this iPhone
Card data is no longer included in iCloud backups. It stays encrypted on this device only. When you move to a new phone, take your cards with you using the encrypted backup in Settings (Premium).

• Brighter barcodes
When you open a barcode, the screen goes to full brightness and stays on, then returns to normal when you close it. You can turn this off in Settings › Bright barcode screen.

• American Express and Diners Club
Amex and Diners Club numbers are now recognized when you type or scan them, and they're shown in the format printed on your card.

• Free IBAN scanning
Scanning an IBAN with the camera or from a QR code is free for everyone.

• 9 languages
The app, widgets, Apple Watch and permission messages are now fully available in English, Turkish, German, French, Spanish, Portuguese, Italian, Dutch and Polish.

• Opening on a new iPhone
Fixed an issue where the app could get stuck on the launch screen after moving to a new iPhone or restoring from a backup.

• And more
Copied card numbers clear themselves from the clipboard after a minute, your Premium status shows up right away, and we fixed many smaller issues.
```

## tr-TR

#### Google Play — What's new (≤500)

```text
• Baştan yeni tasarım: cüzdanın gerçek kartlardan bir deste
• Tek kamera her şeyi ekler: sadakat barkodu, banka kartı, IBAN
• Sıradaki, bu saatte genelde kullandığın kartı gösterir
• Ana ekranda Sıradaki widget'ı
• Eski uygulamandaki kartları tek seferde taşı
• 700+ marka, logosu ve rengiyle tanınır
• Parmak izi ve yüz tanıma herkese ücretsiz
• Tüm kartlarda arama, IBAN'ı görsel olarak paylaş
• 9 dil ve birçok düzeltme
```

#### App Store — What's New (≤4000)

```text
• Yepyeni Deckard
Uygulamanın tamamı yeniden tasarlandı. Cüzdanın artık marka renkleri ve logolarıyla gerçek kartlara benzeyen bir deste. Açmak için herhangi bir karta dokun.

• Her kart için tek kamera
+'ya dokun ve kameranı sadakat kartına, banka kartına ya da IBAN'a tut. Barkod anında, kart numarası ve IBAN saniyeler içinde okunur; kaydetmeden önce onaylarsın. Fotoğraftan da çalışır.

• Sıradaki
Deckard hangi kartı günün hangi saatinde kullandığını yalnızca iPhone'unda öğrenir ve onu ana ekranda ve ana/kilit ekranındaki yeni Sıradaki widget'ında öne alır.

• Kartlarını taşı
Başka bir uygulamadan mı geliyorsun? Dışa aktarma dosyasını, bir tabloyu ya da Apple Wallet kartını Ayarlar › Başka bir uygulamadan aktar'dan içe aktar.

• Her ülkeden 700+ marka
Kartlar logosu ve rengiyle otomatik eşleşir; istediğin mağaza için kendi adını da kullanabilirsin.

• Face ID ve Touch ID herkese açık
Face ID veya Touch ID ile açma artık ücretsiz. Ayarlar › Güvenlik'ten aç. Henüz PIN'in yoksa uygulama önce PIN oluşturmana yardım eder.

• Tüm kartlarında ara
Ana ekrandaki arama düğmesine dokun; kredi kartı, IBAN ya da sadakat kartını isim, banka, marka, etiket veya son 4 haneyle bul. "ı" ile "i", "ş" ile "s" fark etmez; büyük küçük harf de önemli değil.

• IBAN'ı görsel olarak paylaş
IBAN'ını hesap sahibi, banka ve IBAN'ın yer aldığı şık bir kart görseli olarak gönder. Premium'da görsele ödeme QR kodu da eklenir. Metin olarak paylaşım da yerinde duruyor.

• Otomatik kilit
PIN kullanıyorsan Deckard artık uygulamadan çıktığında kendini kilitliyor. Süreyi Ayarlar › Güvenlik › Otomatik kilit bölümünden seçebilirsin: hemen, 30 saniye, 1, 5 ya da 15 dakika sonra.

• Uygulama geçişinde gizli
Uygulamalar arasında geçiş yaparken kartların görünmez; kimse ekrana göz atıp kart bilgini göremez.

• Kartların bu iPhone'da kalır
Kart verilerin artık iCloud yedeğine dahil edilmiyor, yalnızca bu cihazda şifreli olarak duruyor. Yeni telefona geçerken kartlarını Ayarlar'daki şifreli yedekle taşıyabilirsin (Premium).

• Barkodda tam parlaklık
Bir barkodu açtığında ekran tam parlaklığa çıkar ve kapanmaz, kapattığında eski hâline döner. İstersen Ayarlar › Barkodda tam parlaklık bölümünden kapatabilirsin.

• American Express ve Diners Club
Amex ve Diners Club kart numaraları artık elle girerken de kamerayla tararken de tanınıyor ve kartın üzerindeki düzende gösteriliyor.

• Ücretsiz IBAN tarama
IBAN'ı kamerayla ya da QR koddan taramak herkes için ücretsiz.

• 9 dil
Uygulama, widget'lar, Apple Watch ve izin mesajları artık Türkçe, İngilizce, Almanca, Fransızca, İspanyolca, Portekizce, İtalyanca, Felemenkçe ve Lehçe olarak tamamen çevrildi.

• Yeni iPhone'da açılış
Yeni bir iPhone'a geçtikten ya da yedekten geri yükledikten sonra uygulamanın açılış ekranında takılı kalabildiği sorun giderildi.

• Ve daha fazlası
Kopyaladığın kart numaraları bir dakika sonra panodan kendiliğinden silinir, Premium durumun hemen görünür ve birçok küçük sorun düzeltildi.
```

## de-DE

#### Google Play — What's new (≤500)

```text
• Komplett neues Design: deine Wallet als Stapel echter Karten
• Eine Kamera für alles: Kundenkarten, Bankkarten, IBANs
• „Als Nächstes“ zeigt die Karte, die du jetzt meist brauchst
• „Als Nächstes“-Widget auf dem Homescreen
• Karten aus deiner alten App auf einmal mitnehmen
• Über 700 Marken mit Logo und Farben erkannt
• Fingerabdruck und Gesicht kostenlos für alle
• Suche über alle Karten, IBAN als Bild teilen
• 9 Sprachen und viele Fehlerbehebungen
```

#### App Store — What's New (≤4000)

```text
• Ein neues Deckard
Die ganze App ist neu gestaltet. Deine Wallet ist jetzt ein Stapel Karten, die mit Markenfarben und Logos wie die echten aussehen. Tippe auf eine Karte, um sie zu öffnen.

• Eine Kamera für jede Karte
Tippe auf + und richte die Kamera auf eine Kundenkarte, Bankkarte oder IBAN. Barcodes werden sofort erkannt, Kartennummern und IBANs in einem Moment, und du bestätigst, bevor etwas gespeichert wird. Klappt auch mit einem Foto.

• Als Nächstes
Deckard lernt nur auf deinem iPhone, welche Karte du zu welcher Tageszeit nutzt, und zeigt sie zuerst – auf dem Homescreen und im neuen „Als Nächstes“-Widget auf Home- und Sperrbildschirm.

• Karten mitnehmen
Du kommst von einer anderen App? Importiere ihre Exportdatei, eine Tabelle oder einen Apple-Wallet-Pass unter Einstellungen › Aus anderer App importieren.

• Über 700 Marken aus aller Welt
Karten bekommen automatisch Logo und Farben, und du kannst für jedes Geschäft deinen eigenen Namen verwenden.

• Face ID und Touch ID für alle
Entsperren mit Face ID oder Touch ID ist jetzt kostenlos. Aktiviere es unter Einstellungen › Sicherheit. Hast du noch keine PIN, hilft dir die App zuerst beim Anlegen.

• Alle Karten durchsuchen
Tippe auf dem Startbildschirm auf die Suche und finde jede Kreditkarte, IBAN oder Kundenkarte nach Name, Bank, Marke, Tag oder den letzten 4 Ziffern. Akzente und Groß-/Kleinschreibung spielen keine Rolle.

• IBAN als Bild teilen
Schick deine IBAN als schönes Kartenbild mit Kontoinhaber, Bank und IBAN – passend für jeden Chat. Mit Premium enthält das Bild zusätzlich einen Zahlungs-QR-Code. Teilen als Text gibt es weiterhin.

• Automatische Sperre
Wenn du eine PIN nutzt, sperrt sich Deckard jetzt von selbst, sobald du die App verlässt. Den Zeitpunkt wählst du unter Einstellungen › Sicherheit › Automatische Sperre: sofort, nach 30 Sekunden oder nach 1, 5 oder 15 Minuten.

• Verborgen beim App-Wechsel
Beim Wechseln zwischen Apps sind deine Karten abgedeckt, so kann niemand einen Blick darauf werfen.

• Deine Karten bleiben auf diesem iPhone
Kartendaten sind nicht mehr Teil des iCloud-Backups. Sie bleiben verschlüsselt und nur auf diesem Gerät. Für den Umzug auf ein neues Telefon nimmst du sie mit der verschlüsselten Sicherung in den Einstellungen mit (Premium).

• Hellere Barcodes
Öffnest du einen Barcode, geht der Bildschirm auf volle Helligkeit und bleibt an. Beim Schließen ist alles wieder wie vorher. Abschalten kannst du das unter Einstellungen › Helle Barcode-Anzeige.

• American Express und Diners Club
Amex- und Diners-Club-Nummern werden jetzt beim Eintippen und Scannen erkannt und so angezeigt, wie sie auf der Karte stehen.

• IBAN-Scan kostenlos
Eine IBAN mit der Kamera oder per QR-Code zu scannen ist für alle kostenlos.

• 9 Sprachen
App, Widgets, Apple Watch und Berechtigungshinweise gibt es jetzt vollständig auf Deutsch, Englisch, Türkisch, Französisch, Spanisch, Portugiesisch, Italienisch, Niederländisch und Polnisch.

• Start auf einem neuen iPhone
Behoben: Nach dem Wechsel auf ein neues iPhone oder nach einer Wiederherstellung konnte die App auf dem Startbildschirm hängen bleiben.

• Und außerdem
Kopierte Kartennummern verschwinden nach einer Minute von selbst aus der Zwischenablage, dein Premium-Status ist sofort da, und wir haben viele kleine Fehler behoben.
```

## fr-FR

#### Google Play — What's new (≤500)

```text
• Nouveau design : votre portefeuille en pile de vraies cartes
• Un seul scan pour tout : fidélité, cartes bancaires, IBAN
• « À suivre » affiche la carte qu'il vous faut à cette heure
• Widget « À suivre » sur l'écran d'accueil
• Récupérez les cartes de votre ancienne app d'un coup
• Plus de 700 enseignes reconnues avec logo et couleurs
• Empreinte et visage gratuits pour tous
• Recherche dans toutes les cartes, IBAN en image
• 9 langues et de nombreux correctifs
```

#### App Store — What's New (≤4000)

```text
• Un nouveau Deckard
Toute l'app a été repensée. Votre portefeuille est désormais une pile de cartes qui ressemblent aux vraies, avec leurs couleurs et logos. Touchez une carte pour l'ouvrir.

• Un seul scan pour toutes vos cartes
Touchez + et visez une carte de fidélité, une carte bancaire ou un IBAN. Les codes-barres sont lus aussitôt, les numéros et IBAN en un instant, et vous validez avant tout enregistrement. Fonctionne aussi depuis une photo.

• À suivre
Deckard apprend, uniquement sur votre iPhone, quelle carte vous utilisez à quel moment de la journée, et la place en premier sur l'accueil et dans le nouveau widget « À suivre » de l'écran d'accueil et de l'écran verrouillé.

• Récupérez vos cartes
Vous venez d'une autre app ? Importez son fichier d'export, un tableur ou une carte Apple Wallet depuis Réglages › Importer depuis une autre app.

• Plus de 700 enseignes de tous les pays
Les cartes reçoivent automatiquement leur logo et leurs couleurs, et vous pouvez toujours utiliser votre propre nom pour n'importe quel magasin.

• Face ID et Touch ID pour tous
Le déverrouillage par Face ID ou Touch ID est désormais gratuit. Activez-le dans Paramètres › Sécurité. Si vous n'avez pas encore de code PIN, l'app vous aide d'abord à en créer un.

• Recherche dans toutes vos cartes
Touchez la recherche sur l'écran d'accueil pour retrouver une carte bancaire, un IBAN ou une carte de fidélité par nom, banque, marque, étiquette ou 4 derniers chiffres. Accents et majuscules ne comptent pas.

• Partager un IBAN en image
Envoyez votre IBAN sous forme de jolie carte avec le titulaire, la banque et l'IBAN, prête pour n'importe quelle messagerie. Avec Premium, l'image contient aussi un QR code de paiement. Le partage en texte est toujours là.

• Verrouillage auto
Si vous utilisez un code PIN, Deckard se verrouille désormais tout seul quand vous quittez l'app. Choisissez le délai dans Paramètres › Sécurité › Verrouillage auto : immédiatement, après 30 secondes, ou après 1, 5 ou 15 minutes.

• Masquée dans le sélecteur d'apps
Vos cartes sont cachées quand vous passez d'une app à l'autre : personne ne peut y jeter un œil.

• Vos cartes restent sur cet iPhone
Les données des cartes ne font plus partie de la sauvegarde iCloud. Elles restent chiffrées, uniquement sur cet appareil. Pour passer à un nouveau téléphone, emportez-les avec la sauvegarde chiffrée des Paramètres (Premium).

• Codes-barres plus lumineux
Quand vous ouvrez un code-barres, l'écran passe en pleine luminosité et reste allumé, puis revient à la normale à la fermeture. Vous pouvez le désactiver dans Paramètres › Écran lumineux pour les codes-barres.

• American Express et Diners Club
Les numéros Amex et Diners Club sont maintenant reconnus, à la saisie comme au scan, et affichés comme sur votre carte.

• Scan d'IBAN gratuit
Scanner un IBAN avec l'appareil photo ou depuis un QR code est gratuit pour tous.

• 9 langues
L'app, les widgets, l'Apple Watch et les demandes d'autorisation sont désormais entièrement disponibles en français, anglais, turc, allemand, espagnol, portugais, italien, néerlandais et polonais.

• Ouverture sur un nouvel iPhone
Correction d'un problème qui pouvait bloquer l'app sur l'écran de démarrage après un passage à un nouvel iPhone ou une restauration.

• Et aussi
Les numéros de carte copiés s'effacent du presse-papiers au bout d'une minute, votre statut Premium s'affiche tout de suite, et de nombreux petits problèmes ont été corrigés.
```

## es-ES

#### Google Play — What's new (≤500)

```text
• Diseño totalmente nuevo: tu cartera como un mazo de tarjetas reales
• Una cámara lo añade todo: fidelidad, tarjetas bancarias, IBAN
• «Siguiente» muestra la tarjeta que sueles usar a esta hora
• Widget «Siguiente» en la pantalla de inicio
• Trae las tarjetas de tu app anterior de una vez
• Más de 700 marcas reconocidas con logo y colores
• Huella y rostro gratis para todos
• Búsqueda en todas las tarjetas, IBAN como imagen
• 9 idiomas y muchas correcciones
```

#### App Store — What's New (≤4000)

```text
• Un nuevo Deckard
Toda la app se ha rediseñado. Tu cartera es ahora un mazo de tarjetas que parecen reales, con los colores y logos de cada marca. Toca cualquiera para abrirla.

• Una cámara para todas tus tarjetas
Toca + y apunta a una tarjeta de fidelidad, una bancaria o un IBAN. Los códigos se leen al instante, los números e IBAN en un momento, y confirmas antes de guardar. También funciona desde una foto.

• Siguiente
Deckard aprende, solo en tu iPhone, qué tarjeta usas a cada hora del día y la pone primero en el inicio y en el nuevo widget «Siguiente» de la pantalla de inicio y de bloqueo.

• Trae tus tarjetas
¿Vienes de otra app? Importa su archivo de exportación, una hoja de cálculo o un pase de Apple Wallet desde Ajustes › Importar de otra app.

• Más de 700 marcas de todos los países
Las tarjetas reciben su logo y colores automáticamente, y siempre puedes usar tu propio nombre para cualquier tienda.

• Face ID y Touch ID para todos
Desbloquear con Face ID o Touch ID ya es gratis. Actívalo en Ajustes › Seguridad. Si aún no tienes PIN, la app te ayuda a crearlo primero.

• Busca en todas tus tarjetas
Toca la búsqueda en la pantalla de inicio para encontrar cualquier tarjeta de crédito, IBAN o tarjeta de fidelidad por nombre, banco, marca, etiqueta o últimos 4 dígitos. Las tildes y las mayúsculas dan igual.

• Comparte un IBAN como imagen
Envía tu IBAN como una imagen de tarjeta con el titular, el banco y el IBAN, lista para cualquier chat. Con Premium, la imagen incluye además un código QR de pago. Compartir como texto sigue disponible.

• Bloqueo automático
Si usas un PIN, Deckard ahora se bloquea sola cuando sales de la app. Elige cuándo en Ajustes › Seguridad › Bloqueo automático: al instante, a los 30 segundos o a los 1, 5 o 15 minutos.

• Oculta al cambiar de app
Tus tarjetas quedan tapadas cuando pasas de una app a otra, así nadie puede echarles un vistazo.

• Tus tarjetas se quedan en este iPhone
Los datos de tus tarjetas ya no se incluyen en la copia de iCloud. Se quedan cifrados y solo en este dispositivo. Para pasarlas a un teléfono nuevo, usa la copia de seguridad cifrada de Ajustes (Premium).

• Códigos de barras más visibles
Al abrir un código de barras, la pantalla se pone al máximo brillo y no se apaga; al cerrarlo, vuelve a como estaba. Puedes desactivarlo en Ajustes › Pantalla brillante para códigos.

• American Express y Diners Club
Los números de Amex y Diners Club ahora se reconocen al escribirlos y al escanearlos, y se muestran con el mismo formato que en la tarjeta.

• Escaneo de IBAN gratis
Escanear un IBAN con la cámara o desde un código QR es gratis para todos.

• 9 idiomas
La app, los widgets, el Apple Watch y los avisos de permisos ya están completos en español, inglés, turco, alemán, francés, portugués, italiano, neerlandés y polaco.

• Apertura en un iPhone nuevo
Corregido un problema por el que la app podía quedarse en la pantalla de inicio tras pasar a un iPhone nuevo o restaurar una copia.

• Y además
Los números de tarjeta copiados se borran solos del portapapeles al minuto, tu estado Premium aparece al momento y hemos corregido muchos fallos pequeños.
```

## pt-BR

#### Google Play — What's new (≤500)

```text
• Visual todo novo: sua carteira como um maço de cartões reais
• Uma câmera adiciona tudo: fidelidade, cartões bancários, IBAN
• “A seguir” mostra o cartão que você costuma usar nesta hora
• Widget “A seguir” na tela inicial
• Traga os cartões do seu app antigo de uma vez
• Mais de 700 marcas reconhecidas com logo e cores
• Digital e rosto grátis para todos
• Busca em todos os cartões, IBAN como imagem
• 9 idiomas e muitas correções
```

#### App Store — What's New (≤4000)

```text
• Um novo Deckard
O app inteiro foi redesenhado. Sua carteira agora é um maço de cartões que parecem os de verdade, com cores e logos de cada marca. Toque em qualquer um para abrir.

• Uma câmera para todos os cartões
Toque em + e aponte para um cartão fidelidade, um cartão bancário ou um IBAN. Códigos de barras são lidos na hora, números e IBAN num instante, e você confirma antes de salvar. Funciona também com uma foto.

• A seguir
O Deckard aprende, só no seu iPhone, qual cartão você usa em cada horário e coloca ele primeiro na tela inicial do app e no novo widget “A seguir” da tela inicial e de bloqueio.

• Traga seus cartões
Vindo de outro app? Importe o arquivo de exportação, uma planilha ou um passe do Apple Wallet em Ajustes › Importar de outro app.

• Mais de 700 marcas de todos os países
Os cartões recebem logo e cores automaticamente, e você sempre pode usar seu próprio nome para qualquer loja.

• Face ID e Touch ID para todos
Desbloquear com Face ID ou Touch ID agora é grátis. Ative em Configurações › Segurança. Se você ainda não tem PIN, o app ajuda a criar um primeiro.

• Busque em todos os seus cartões
Toque na busca da tela inicial para encontrar qualquer cartão de crédito, IBAN ou cartão fidelidade por nome, banco, marca, etiqueta ou últimos 4 dígitos. Acentos e maiúsculas não fazem diferença.

• Compartilhe um IBAN como imagem
Envie seu IBAN como uma imagem de cartão com o titular, o banco e o IBAN, pronta para qualquer conversa. Com Premium, a imagem também traz um QR code de pagamento. Compartilhar como texto continua disponível.

• Bloqueio automático
Se você usa um PIN, o Deckard agora se bloqueia sozinho quando você sai do app. Escolha o tempo em Configurações › Segurança › Bloqueio automático: na hora, depois de 30 segundos ou depois de 1, 5 ou 15 minutos.

• Escondido na troca de apps
Seus cartões ficam cobertos quando você alterna entre apps, então ninguém consegue espiar.

• Seus cartões ficam neste iPhone
Os dados dos cartões não entram mais no backup do iCloud. Eles ficam criptografados e só neste aparelho. Para levar tudo para um celular novo, use o backup criptografado em Configurações (Premium).

• Códigos de barras mais claros
Ao abrir um código de barras, a tela vai para o brilho máximo e fica acesa; quando você fecha, volta ao normal. Dá para desligar em Configurações › Tela clara para códigos de barras.

• American Express e Diners Club
Números Amex e Diners Club agora são reconhecidos ao digitar e ao escanear, e aparecem no mesmo formato impresso no cartão.

• Leitura de IBAN grátis
Escanear um IBAN com a câmera ou por QR code é grátis para todos.

• 9 idiomas
O app, os widgets, o Apple Watch e os pedidos de permissão agora estão totalmente em português, inglês, turco, alemão, francês, espanhol, italiano, holandês e polonês.

• Abertura em um iPhone novo
Corrigimos um problema que podia deixar o app travado na tela de abertura depois de trocar de iPhone ou restaurar um backup.

• E mais
Números de cartão copiados somem da área de transferência depois de um minuto, seu status Premium aparece na hora e corrigimos vários probleminhas.
```

## it-IT

#### Google Play — What's new (≤500)

```text
• Design tutto nuovo: il portafoglio come un mazzo di carte vere
• Una fotocamera aggiunge tutto: fedeltà, carte bancarie, IBAN
• «Prossima» mostra la carta che usi di solito a quest'ora
• Widget «Prossima» nella schermata Home
• Porta le carte dalla vecchia app in un colpo
• Oltre 700 marchi riconosciuti con logo e colori
• Impronta e volto gratis per tutti
• Ricerca in tutte le carte, IBAN come immagine
• 9 lingue e molte correzioni
```

#### App Store — What's New (≤4000)

```text
• Un nuovo Deckard
Tutta l'app è stata ridisegnata. Il tuo portafoglio ora è un mazzo di carte che sembrano vere, con colori e loghi dei marchi. Tocca una carta per aprirla.

• Una fotocamera per ogni carta
Tocca + e inquadra una carta fedeltà, una carta bancaria o un IBAN. I codici a barre vengono letti subito, numeri e IBAN in un attimo, e confermi prima di salvare. Funziona anche da una foto.

• Prossima
Deckard impara, solo sul tuo iPhone, quale carta usi in quale momento della giornata e la mette prima nella Home dell'app e nel nuovo widget «Prossima» su Home e schermata di blocco.

• Porta le tue carte
Arrivi da un'altra app? Importa il suo file di esportazione, un foglio di calcolo o un pass di Apple Wallet da Impostazioni › Importa da un'altra app.

• Oltre 700 marchi da ogni paese
Le carte ricevono logo e colori in automatico, e puoi sempre usare il tuo nome per qualsiasi negozio.

• Face ID e Touch ID per tutti
Lo sblocco con Face ID o Touch ID ora è gratis. Attivalo in Impostazioni › Sicurezza. Se non hai ancora un PIN, l'app ti aiuta prima a crearne uno.

• Cerca in tutte le carte
Tocca la ricerca nella home per trovare qualsiasi carta di credito, IBAN o carta fedeltà per nome, banca, marca, tag o ultime 4 cifre. Accenti e maiuscole non contano.

• Condividi un IBAN come immagine
Invia il tuo IBAN come immagine della carta con intestatario, banca e IBAN, pronta per qualsiasi chat. Con Premium, l'immagine include anche un QR code di pagamento. La condivisione come testo resta disponibile.

• Blocco automatico
Se usi un PIN, Deckard ora si blocca da sola quando esci dall'app. Scegli dopo quanto in Impostazioni › Sicurezza › Blocco automatico: subito, dopo 30 secondi oppure dopo 1, 5 o 15 minuti.

• Nascosta nel cambio app
Quando passi da un'app all'altra le tue carte sono coperte, così nessuno può sbirciare.

• Le tue carte restano su questo iPhone
I dati delle carte non fanno più parte del backup iCloud. Restano cifrati e solo su questo dispositivo. Per portarli su un nuovo telefono usa il backup cifrato nelle Impostazioni (Premium).

• Codici a barre più luminosi
Quando apri un codice a barre lo schermo va alla massima luminosità e resta acceso; quando lo chiudi torna com'era. Puoi disattivarlo in Impostazioni › Schermo luminoso per i codici.

• American Express e Diners Club
I numeri Amex e Diners Club ora vengono riconosciuti sia quando li digiti sia quando li scansioni, e appaiono nello stesso formato stampato sulla carta.

• Scansione IBAN gratis
Scansionare un IBAN con la fotocamera o da un QR code è gratis per tutti.

• 9 lingue
App, widget, Apple Watch e richieste di autorizzazione sono ora completamente disponibili in italiano, inglese, turco, tedesco, francese, spagnolo, portoghese, olandese e polacco.

• Apertura su un nuovo iPhone
Risolto un problema per cui l'app poteva restare ferma sulla schermata di avvio dopo il passaggio a un nuovo iPhone o un ripristino da backup.

• E poi
I numeri di carta copiati spariscono dagli appunti dopo un minuto, lo stato Premium compare subito e abbiamo sistemato tanti piccoli problemi.
```

## nl-NL

#### Google Play — What's new (≤500)

```text
• Volledig nieuw ontwerp: je portemonnee als stapel echte kaarten
• Eén camera voegt alles toe: klantenkaarten, bankpassen, IBAN's
• ‘Volgende’ toont de kaart die je nu meestal nodig hebt
• ‘Volgende’-widget op je beginscherm
• Neem je kaarten uit je oude app in één keer mee
• Meer dan 700 merken herkend met logo en kleuren
• Vingerafdruk en gezicht gratis voor iedereen
• Zoeken in alle kaarten, IBAN delen als afbeelding
• 9 talen en veel verbeteringen
```

#### App Store — What's New (≤4000)

```text
• Een nieuw Deckard
De hele app is opnieuw ontworpen. Je portemonnee is nu een stapel kaarten die op de echte lijken, met de kleuren en logo's van elk merk. Tik op een kaart om hem te openen.

• Eén camera voor elke kaart
Tik op + en richt op een klantenkaart, bankpas of IBAN. Barcodes worden direct gelezen, kaartnummers en IBAN's in een oogwenk, en je bevestigt voordat er iets wordt bewaard. Werkt ook met een foto.

• Volgende
Deckard leert, alleen op je iPhone, welke kaart je op welk moment van de dag gebruikt en zet die vooraan, in de app en in de nieuwe ‘Volgende’-widget op begin- en toegangsscherm.

• Neem je kaarten mee
Kom je van een andere app? Importeer het exportbestand, een spreadsheet of een Apple Wallet-pas via Instellingen › Importeren uit andere app.

• Meer dan 700 merken uit elk land
Kaarten krijgen automatisch hun logo en kleuren, en je kunt altijd je eigen naam gebruiken voor elke winkel.

• Face ID en Touch ID voor iedereen
Ontgrendelen met Face ID of Touch ID is nu gratis. Zet het aan via Instellingen › Beveiliging. Heb je nog geen pincode, dan helpt de app je eerst er een te maken.

• Zoek in al je kaarten
Tik op het beginscherm op zoeken en vind elke creditcard, IBAN of klantenkaart op naam, bank, merk, label of de laatste 4 cijfers. Accenten en hoofdletters maken niet uit.

• Deel een IBAN als afbeelding
Stuur je IBAN als strakke kaartafbeelding met rekeninghouder, bank en IBAN, klaar voor elke chat. Met Premium staat er ook een betaal-QR-code op. Delen als tekst kan nog steeds.

• Automatisch vergrendelen
Gebruik je een pincode, dan vergrendelt Deckard zich nu vanzelf zodra je de app verlaat. Kies wanneer in Instellingen › Beveiliging › Automatisch vergrendelen: meteen, na 30 seconden of na 1, 5 of 15 minuten.

• Verborgen bij het wisselen van apps
Je kaarten zijn afgedekt als je tussen apps wisselt, zodat niemand kan meekijken.

• Je kaarten blijven op deze iPhone
Kaartgegevens zitten niet meer in de iCloud-reservekopie. Ze blijven versleuteld en alleen op dit apparaat. Ga je over naar een nieuwe telefoon, neem ze dan mee met de versleutelde back-up in Instellingen (Premium).

• Fellere barcodes
Open je een barcode, dan gaat het scherm naar volle helderheid en blijft het aan. Sluit je hem, dan is alles weer zoals het was. Uitzetten kan in Instellingen › Fel scherm bij barcodes.

• American Express en Diners Club
Amex- en Diners Club-nummers worden nu herkend als je ze intypt of scant, en worden getoond zoals ze op je kaart staan.

• Gratis IBAN scannen
Een IBAN scannen met de camera of via een QR-code is gratis voor iedereen.

• 9 talen
De app, widgets, Apple Watch en toestemmingsmeldingen zijn nu volledig beschikbaar in het Nederlands, Engels, Turks, Duits, Frans, Spaans, Portugees, Italiaans en Pools.

• Openen op een nieuwe iPhone
Probleem opgelost waardoor de app kon blijven hangen op het startscherm na de overstap naar een nieuwe iPhone of na het terugzetten van een reservekopie.

• En verder
Gekopieerde kaartnummers verdwijnen na een minuut vanzelf van het klembord, je Premium-status is meteen zichtbaar en we hebben veel kleine problemen opgelost.
```

## pl-PL

#### Google Play — What's new (≤500)

```text
• Zupełnie nowy wygląd: portfel jako stos prawdziwych kart
• Jeden aparat doda wszystko: karty lojalnościowe, bankowe, IBAN
• „Następna” pokazuje kartę, której zwykle używasz o tej porze
• Widżet „Następna” na ekranie głównym
• Przenieś karty ze starej aplikacji za jednym razem
• Ponad 700 marek z logo i kolorami
• Odcisk palca i twarz za darmo dla wszystkich
• Wyszukiwanie we wszystkich kartach, IBAN jako obraz
• 9 języków i wiele poprawek
```

#### App Store — What's New (≤4000)

```text
• Nowy Deckard
Cała aplikacja ma nowy wygląd. Portfel to teraz stos kart wyglądających jak prawdziwe, z kolorami i logo marek. Dotknij karty, by ją otworzyć.

• Jeden aparat do każdej karty
Dotknij + i skieruj aparat na kartę lojalnościową, bankową lub IBAN. Kody kreskowe są odczytywane od razu, numery kart i IBAN w chwilę, a przed zapisaniem wszystko potwierdzasz. Działa też ze zdjęcia.

• Następna
Deckard uczy się – tylko na Twoim iPhonie – której karty używasz o jakiej porze dnia, i pokazuje ją jako pierwszą w aplikacji oraz w nowym widżecie „Następna” na ekranie głównym i blokady.

• Przenieś swoje karty
Przechodzisz z innej aplikacji? Zaimportuj jej plik eksportu, arkusz lub kartę Apple Wallet w Ustawienia › Importuj z innej aplikacji.

• Ponad 700 marek z każdego kraju
Karty automatycznie dostają logo i kolory, a dla każdego sklepu możesz użyć własnej nazwy.

• Face ID i Touch ID dla wszystkich
Odblokowywanie przez Face ID lub Touch ID jest teraz bezpłatne. Włącz je w Ustawienia › Bezpieczeństwo. Jeśli nie masz jeszcze PIN-u, aplikacja najpierw pomoże go utworzyć.

• Szukaj we wszystkich kartach
Stuknij wyszukiwanie na ekranie głównym i znajdź kartę kredytową, IBAN lub kartę lojalnościową po nazwie, banku, marce, tagu lub ostatnich 4 cyfrach. Polskie znaki i wielkie litery nie mają znaczenia.

• Udostępnij IBAN jako obraz
Wyślij swój IBAN jako estetyczny obraz karty z właścicielem konta, bankiem i numerem IBAN, gotowy do każdego czatu. W Premium obraz zawiera też kod QR do płatności. Udostępnianie jako tekst nadal działa.

• Automatyczna blokada
Jeśli używasz PIN-u, Deckard blokuje się teraz sam, gdy wychodzisz z aplikacji. Czas wybierzesz w Ustawienia › Bezpieczeństwo › Automatyczna blokada: od razu, po 30 sekundach albo po 1, 5 lub 15 minutach.

• Ukryte przy przełączaniu aplikacji
Gdy przechodzisz między aplikacjami, Twoje karty są zasłonięte, więc nikt nie zerknie na ich dane.

• Twoje karty zostają na tym iPhonie
Dane kart nie trafiają już do kopii zapasowej iCloud. Zostają zaszyfrowane i tylko na tym urządzeniu. Przy przejściu na nowy telefon przeniesiesz je szyfrowaną kopią zapasową z Ustawień (Premium).

• Jaśniejsze kody kreskowe
Po otwarciu kodu kreskowego ekran przechodzi na pełną jasność i nie gaśnie, a po zamknięciu wraca do poprzednich ustawień. Możesz to wyłączyć w Ustawienia › Jasny ekran kodu kreskowego.

• American Express i Diners Club
Numery Amex i Diners Club są teraz rozpoznawane przy wpisywaniu i skanowaniu oraz wyświetlane w takim układzie jak na karcie.

• Bezpłatne skanowanie IBAN
Skanowanie IBAN aparatem lub z kodu QR jest bezpłatne dla wszystkich.

• 9 języków
Aplikacja, widżety, Apple Watch i komunikaty o uprawnieniach są teraz w pełni dostępne po polsku, angielsku, turecku, niemiecku, francusku, hiszpańsku, portugalsku, włosku i niderlandzku.

• Uruchamianie na nowym iPhonie
Naprawiono błąd, przez który aplikacja mogła zatrzymać się na ekranie startowym po przejściu na nowy iPhone lub przywróceniu kopii zapasowej.

• I więcej
Skopiowane numery kart same znikają ze schowka po minucie, status Premium widać od razu, a do tego poprawiliśmy wiele drobnych błędów.
```
