# Card Wallet 2.1.0 (44) — Sürüm notları

Konsola kopyalanacak "What's new" / "Bu sürümdeki yenilikler" metinleri.

- **Google Play** → Release › Release notes, dil başına `<tr-TR>…</tr-TR>` bloğu. Sınır 500 karakter.
- **App Store Connect** → 2.1.0 sürümü › What's New in This Version. Sınır 4000 karakter.

Neden iki ayrı metin var:
- Play metni Android'e göre yazıldı. iCloud ve app switcher maddeleri iOS'a özel olduğu için çıkarıldı. Android zaten yedeğe kart verisi koymuyordu (`allowBackup=false`) ve app switcher'da kartları zaten gizliyordu (`FLAG_SECURE`), yani orada değişen bir şey yok.
- "Telefon değiştirirken şifreli yedeği kullan" cümlesinin yanında **(Premium)** yazıyor, çünkü yedekleme/geri yükleme Premium'a bağlı (`openPremiumGate('backupRestore')`). Bunu yazmazsak ücretsiz kullanıcıya yanlış beklenti vermiş oluruz.
- Ayar adları uygulamadaki gerçek etiketlerden alındı (`autoLock`, `sectionSecurity`, `barcodeBrightnessTitle`).

Uzunlukları yeniden saymak için: `python3 tools/check_store_text.py --write docs/store/v2.1/whats_new.md`

<!-- lengths:start -->
| Dil | Alan | Uzunluk | Sınır | Durum |
|---|---|---:|---:|---|
| en-US | Google Play — What's new | 445 | 500 | ✅ |
| en-US | App Store — What's New | 1406 | 4000 | ✅ |
| tr-TR | Google Play — What's new | 430 | 500 | ✅ |
| tr-TR | App Store — What's New | 1433 | 4000 | ✅ |
| de-DE | Google Play — What's new | 457 | 500 | ✅ |
| de-DE | App Store — What's New | 1594 | 4000 | ✅ |
| fr-FR | Google Play — What's new | 493 | 500 | ✅ |
| fr-FR | App Store — What's New | 1628 | 4000 | ✅ |
| es-ES | Google Play — What's new | 488 | 500 | ✅ |
| es-ES | App Store — What's New | 1501 | 4000 | ✅ |
| pt-BR | Google Play — What's new | 484 | 500 | ✅ |
| pt-BR | App Store — What's New | 1476 | 4000 | ✅ |
| it-IT | Google Play — What's new | 465 | 500 | ✅ |
| it-IT | App Store — What's New | 1494 | 4000 | ✅ |
| nl-NL | Google Play — What's new | 470 | 500 | ✅ |
| nl-NL | App Store — What's New | 1525 | 4000 | ✅ |
| pl-PL | Google Play — What's new | 474 | 500 | ✅ |
| pl-PL | App Store — What's New | 1514 | 4000 | ✅ |
<!-- lengths:end -->

---

## en-US

#### Google Play — What's new (≤500)

```text
What's new in 2.1:
• Auto-lock: if you use a PIN, the app locks itself after you leave it
• American Express and Diners Club cards are recognized and shown correctly
• Your screen brightens automatically when you show a barcode
• Fully translated into 9 languages, widgets included
• Copied card numbers are hidden from clipboard previews
• Fixed an issue that could leave the app stuck on the launch screen
• Many smaller fixes and improvements
```

#### App Store — What's New (≤4000)

```text
What's new in 2.1

• Auto-lock
If you use a PIN, CardWallet now locks itself when you leave the app. Choose the timing in Settings › Security › Auto-lock: immediately, after 30 seconds, or after 1, 5 or 15 minutes.

• Hidden in the app switcher
Your cards are covered when you switch between apps, so nobody can glance at them.

• Your cards stay on this iPhone
Card data is no longer included in iCloud backups. It stays encrypted on this device only. When you move to a new phone, take your cards with you using the encrypted backup in Settings (Premium).

• American Express and Diners Club
Amex and Diners Club numbers are now recognized when you type or scan them, and they're shown in the format printed on your card.

• Brighter barcodes
When you open a barcode, the screen goes to full brightness and stays on, then returns to normal when you close it. You can turn this off in Settings › Bright barcode screen.

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
2.1'de neler var:
• Otomatik kilit: PIN kullanıyorsan uygulamadan çıktığında cüzdan kendini kilitler
• American Express ve Diners Club kartları tanınır ve doğru gösterilir
• Barkodu açtığında ekran parlaklığı kendiliğinden artar
• Widget'lar dahil 9 dilde tam çeviri
• Kopyaladığın kart numaraları pano önizlemesinde görünmez
• Uygulamanın açılış ekranında takılı kalabildiği sorun giderildi
• Birçok küçük düzeltme ve iyileştirme
```

#### App Store — What's New (≤4000)

```text
2.1'de neler var

• Otomatik kilit
PIN kullanıyorsan CardWallet artık uygulamadan çıktığında kendini kilitliyor. Süreyi Ayarlar › Güvenlik › Otomatik kilit bölümünden seçebilirsin: hemen, 30 saniye, 1, 5 ya da 15 dakika sonra.

• Uygulama geçişinde gizli
Uygulamalar arasında geçiş yaparken kartların görünmez; kimse ekrana göz atıp kart bilgini göremez.

• Kartların bu iPhone'da kalır
Kart verilerin artık iCloud yedeğine dahil edilmiyor, yalnızca bu cihazda şifreli olarak duruyor. Yeni telefona geçerken kartlarını Ayarlar'daki şifreli yedekle taşıyabilirsin (Premium).

• American Express ve Diners Club
Amex ve Diners Club kart numaraları artık elle girerken de kamerayla tararken de tanınıyor ve kartın üzerindeki düzende gösteriliyor.

• Barkodda tam parlaklık
Bir barkodu açtığında ekran tam parlaklığa çıkar ve kapanmaz, kapattığında eski hâline döner. İstersen Ayarlar › Barkodda tam parlaklık bölümünden kapatabilirsin.

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
Neu in 2.1:
• Automatische Sperre: Mit PIN sperrt sich die App, sobald du sie verlässt
• American Express und Diners Club werden erkannt und richtig angezeigt
• Beim Barcode wird der Bildschirm automatisch heller
• Komplett in 9 Sprachen übersetzt, auch die Widgets
• Kopierte Kartennummern erscheinen nicht mehr in der Zwischenablage-Vorschau
• Problem behoben, bei dem die App beim Start hängen bleiben konnte
• Viele kleine Korrekturen und Verbesserungen
```

#### App Store — What's New (≤4000)

```text
Neu in 2.1

• Automatische Sperre
Wenn du eine PIN nutzt, sperrt sich CardWallet jetzt von selbst, sobald du die App verlässt. Den Zeitpunkt wählst du unter Einstellungen › Sicherheit › Automatische Sperre: sofort, nach 30 Sekunden oder nach 1, 5 oder 15 Minuten.

• Verborgen beim App-Wechsel
Beim Wechseln zwischen Apps sind deine Karten abgedeckt, so kann niemand einen Blick darauf werfen.

• Deine Karten bleiben auf diesem iPhone
Kartendaten sind nicht mehr Teil des iCloud-Backups. Sie bleiben verschlüsselt und nur auf diesem Gerät. Für den Umzug auf ein neues Telefon nimmst du sie mit der verschlüsselten Sicherung in den Einstellungen mit (Premium).

• American Express und Diners Club
Amex- und Diners-Club-Nummern werden jetzt beim Eintippen und Scannen erkannt und so angezeigt, wie sie auf der Karte stehen.

• Hellere Barcodes
Öffnest du einen Barcode, geht der Bildschirm auf volle Helligkeit und bleibt an. Beim Schließen ist alles wieder wie vorher. Abschalten kannst du das unter Einstellungen › Helle Barcode-Anzeige.

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
Nouveautés de la 2.1 :
• Verrouillage auto : avec un code PIN, l'app se verrouille dès que vous la quittez
• Les cartes American Express et Diners Club sont reconnues et bien affichées
• L'écran s'éclaircit automatiquement quand vous affichez un code-barres
• Entièrement traduite en 9 langues, widgets compris
• Les numéros copiés n'apparaissent plus dans l'aperçu du presse-papiers
• Correction d'un blocage possible sur l'écran de démarrage
• Nombreuses petites corrections et améliorations
```

#### App Store — What's New (≤4000)

```text
Nouveautés de la 2.1

• Verrouillage auto
Si vous utilisez un code PIN, CardWallet se verrouille désormais tout seul quand vous quittez l'app. Choisissez le délai dans Paramètres › Sécurité › Verrouillage auto : immédiatement, après 30 secondes, ou après 1, 5 ou 15 minutes.

• Masquée dans le sélecteur d'apps
Vos cartes sont cachées quand vous passez d'une app à l'autre : personne ne peut y jeter un œil.

• Vos cartes restent sur cet iPhone
Les données des cartes ne font plus partie de la sauvegarde iCloud. Elles restent chiffrées, uniquement sur cet appareil. Pour passer à un nouveau téléphone, emportez-les avec la sauvegarde chiffrée des Paramètres (Premium).

• American Express et Diners Club
Les numéros Amex et Diners Club sont maintenant reconnus, à la saisie comme au scan, et affichés comme sur votre carte.

• Codes-barres plus lumineux
Quand vous ouvrez un code-barres, l'écran passe en pleine luminosité et reste allumé, puis revient à la normale à la fermeture. Vous pouvez le désactiver dans Paramètres › Écran lumineux pour les codes-barres.

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
Novedades de la 2.1:
• Bloqueo automático: si usas PIN, la app se bloquea al salir de ella
• Las tarjetas American Express y Diners Club se reconocen y se muestran bien
• La pantalla sube el brillo sola cuando muestras un código de barras
• Traducida por completo a 9 idiomas, widgets incluidos
• Los números copiados ya no aparecen en la vista previa del portapapeles
• Corregido un fallo por el que la app podía quedarse en la pantalla de inicio
• Muchas pequeñas correcciones y mejoras
```

#### App Store — What's New (≤4000)

```text
Novedades de la 2.1

• Bloqueo automático
Si usas un PIN, CardWallet ahora se bloquea sola cuando sales de la app. Elige cuándo en Ajustes › Seguridad › Bloqueo automático: al instante, a los 30 segundos o a los 1, 5 o 15 minutos.

• Oculta al cambiar de app
Tus tarjetas quedan tapadas cuando pasas de una app a otra, así nadie puede echarles un vistazo.

• Tus tarjetas se quedan en este iPhone
Los datos de tus tarjetas ya no se incluyen en la copia de iCloud. Se quedan cifrados y solo en este dispositivo. Para pasarlas a un teléfono nuevo, usa la copia de seguridad cifrada de Ajustes (Premium).

• American Express y Diners Club
Los números de Amex y Diners Club ahora se reconocen al escribirlos y al escanearlos, y se muestran con el mismo formato que en la tarjeta.

• Códigos de barras más visibles
Al abrir un código de barras, la pantalla se pone al máximo brillo y no se apaga; al cerrarlo, vuelve a como estaba. Puedes desactivarlo en Ajustes › Pantalla brillante para códigos.

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
Novidades da 2.1:
• Bloqueio automático: se você usa PIN, o app se bloqueia quando você sai dele
• Cartões American Express e Diners Club são reconhecidos e exibidos certinho
• O brilho da tela aumenta sozinho quando você mostra um código de barras
• Totalmente traduzido para 9 idiomas, widgets incluídos
• Números copiados não aparecem mais na prévia da área de transferência
• Corrigido um problema que podia travar o app na tela de abertura
• Várias pequenas correções e melhorias
```

#### App Store — What's New (≤4000)

```text
Novidades da 2.1

• Bloqueio automático
Se você usa um PIN, o CardWallet agora se bloqueia sozinho quando você sai do app. Escolha o tempo em Configurações › Segurança › Bloqueio automático: na hora, depois de 30 segundos ou depois de 1, 5 ou 15 minutos.

• Escondido na troca de apps
Seus cartões ficam cobertos quando você alterna entre apps, então ninguém consegue espiar.

• Seus cartões ficam neste iPhone
Os dados dos cartões não entram mais no backup do iCloud. Eles ficam criptografados e só neste aparelho. Para levar tudo para um celular novo, use o backup criptografado em Configurações (Premium).

• American Express e Diners Club
Números Amex e Diners Club agora são reconhecidos ao digitar e ao escanear, e aparecem no mesmo formato impresso no cartão.

• Códigos de barras mais claros
Ao abrir um código de barras, a tela vai para o brilho máximo e fica acesa; quando você fecha, volta ao normal. Dá para desligar em Configurações › Tela clara para códigos de barras.

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
Novità della 2.1:
• Blocco automatico: se usi un PIN, l'app si blocca appena la lasci
• Le carte American Express e Diners Club vengono riconosciute e mostrate bene
• Quando mostri un codice a barre lo schermo si illumina da solo
• Tradotta completamente in 9 lingue, widget compresi
• I numeri copiati non compaiono più nell'anteprima degli appunti
• Risolto un problema che poteva bloccare l'app sulla schermata di avvio
• Tante piccole correzioni e miglioramenti
```

#### App Store — What's New (≤4000)

```text
Novità della 2.1

• Blocco automatico
Se usi un PIN, CardWallet ora si blocca da sola quando esci dall'app. Scegli dopo quanto in Impostazioni › Sicurezza › Blocco automatico: subito, dopo 30 secondi oppure dopo 1, 5 o 15 minuti.

• Nascosta nel cambio app
Quando passi da un'app all'altra le tue carte sono coperte, così nessuno può sbirciare.

• Le tue carte restano su questo iPhone
I dati delle carte non fanno più parte del backup iCloud. Restano cifrati e solo su questo dispositivo. Per portarli su un nuovo telefono usa il backup cifrato nelle Impostazioni (Premium).

• American Express e Diners Club
I numeri Amex e Diners Club ora vengono riconosciuti sia quando li digiti sia quando li scansioni, e appaiono nello stesso formato stampato sulla carta.

• Codici a barre più luminosi
Quando apri un codice a barre lo schermo va alla massima luminosità e resta acceso; quando lo chiudi torna com'era. Puoi disattivarlo in Impostazioni › Schermo luminoso per i codici.

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
Nieuw in 2.1:
• Automatisch vergrendelen: met een pincode vergrendelt de app zich zodra je hem verlaat
• American Express en Diners Club worden herkend en goed weergegeven
• Je scherm wordt vanzelf feller als je een barcode laat zien
• Volledig vertaald in 9 talen, ook de widgets
• Gekopieerde kaartnummers verschijnen niet meer in het klembordvoorbeeld
• Probleem opgelost waardoor de app kon blijven hangen op het startscherm
• Veel kleine verbeteringen en reparaties
```

#### App Store — What's New (≤4000)

```text
Nieuw in 2.1

• Automatisch vergrendelen
Gebruik je een pincode, dan vergrendelt CardWallet zich nu vanzelf zodra je de app verlaat. Kies wanneer in Instellingen › Beveiliging › Automatisch vergrendelen: meteen, na 30 seconden of na 1, 5 of 15 minuten.

• Verborgen bij het wisselen van apps
Je kaarten zijn afgedekt als je tussen apps wisselt, zodat niemand kan meekijken.

• Je kaarten blijven op deze iPhone
Kaartgegevens zitten niet meer in de iCloud-reservekopie. Ze blijven versleuteld en alleen op dit apparaat. Ga je over naar een nieuwe telefoon, neem ze dan mee met de versleutelde back-up in Instellingen (Premium).

• American Express en Diners Club
Amex- en Diners Club-nummers worden nu herkend als je ze intypt of scant, en worden getoond zoals ze op je kaart staan.

• Fellere barcodes
Open je een barcode, dan gaat het scherm naar volle helderheid en blijft het aan. Sluit je hem, dan is alles weer zoals het was. Uitzetten kan in Instellingen › Fel scherm bij barcodes.

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
Nowości w 2.1:
• Automatyczna blokada: jeśli używasz PIN-u, aplikacja blokuje się po wyjściu z niej
• Karty American Express i Diners Club są rozpoznawane i poprawnie wyświetlane
• Jasność ekranu rośnie sama, gdy pokazujesz kod kreskowy
• Pełne tłumaczenie na 9 języków, łącznie z widżetami
• Skopiowane numery kart nie pojawiają się w podglądzie schowka
• Naprawiono błąd, przez który aplikacja mogła zawiesić się na ekranie startowym
• Wiele drobnych poprawek i usprawnień
```

#### App Store — What's New (≤4000)

```text
Nowości w 2.1

• Automatyczna blokada
Jeśli używasz PIN-u, CardWallet blokuje się teraz sam, gdy wychodzisz z aplikacji. Czas wybierzesz w Ustawienia › Bezpieczeństwo › Automatyczna blokada: od razu, po 30 sekundach albo po 1, 5 lub 15 minutach.

• Ukryte przy przełączaniu aplikacji
Gdy przechodzisz między aplikacjami, Twoje karty są zasłonięte, więc nikt nie zerknie na ich dane.

• Twoje karty zostają na tym iPhonie
Dane kart nie trafiają już do kopii zapasowej iCloud. Zostają zaszyfrowane i tylko na tym urządzeniu. Przy przejściu na nowy telefon przeniesiesz je szyfrowaną kopią zapasową z Ustawień (Premium).

• American Express i Diners Club
Numery Amex i Diners Club są teraz rozpoznawane przy wpisywaniu i skanowaniu oraz wyświetlane w takim układzie jak na karcie.

• Jaśniejsze kody kreskowe
Po otwarciu kodu kreskowego ekran przechodzi na pełną jasność i nie gaśnie, a po zamknięciu wraca do poprzednich ustawień. Możesz to wyłączyć w Ustawienia › Jasny ekran kodu kreskowego.

• 9 języków
Aplikacja, widżety, Apple Watch i komunikaty o uprawnieniach są teraz w pełni dostępne po polsku, angielsku, turecku, niemiecku, francusku, hiszpańsku, portugalsku, włosku i niderlandzku.

• Uruchamianie na nowym iPhonie
Naprawiono błąd, przez który aplikacja mogła zatrzymać się na ekranie startowym po przejściu na nowy iPhone lub przywróceniu kopii zapasowej.

• I więcej
Skopiowane numery kart same znikają ze schowka po minucie, status Premium widać od razu, a do tego poprawiliśmy wiele drobnych błędów.
```
