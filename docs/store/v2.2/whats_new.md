# Card Wallet 2.2 — Sürüm notları

Konsola kopyalanacak "What's new" / "Bu sürümdeki yenilikler" metinleri.

- **Google Play** → Release › Release notes, dil başına `<tr-TR>…</tr-TR>` bloğu. Sınır 500 karakter.
- **App Store Connect** → 2.2 sürümü › What's New in This Version. Sınır 4000 karakter.

Notlar:
- Play metninde Apple Watch yok; sıralamanın Watch'a da yansıması yalnızca App Store metninde.
- IBAN tarama kodda hiç kilitli değildi, sadece paywall onu Premium gibi listeliyordu. Bu yüzden "artık ücretsiz" demiyoruz, "herkes için ücretsiz" diyoruz.
- Görsel paylaşım ücretsiz; görseldeki ödeme QR'ı Premium. Metinde ikisi ayrı yazıldı ki ücretsiz kullanıcı QR beklemesin.
- Ayar/ekran adları uygulamadaki etiketlerden alındı (`shareAsImage`, `sortMostUsed`, `globalSearchTooltip`).

Uzunlukları yeniden saymak için: `python3 tools/check_store_text.py --write docs/store/v2.2/whats_new.md`

<!-- lengths:start -->
| Dil | Alan | Uzunluk | Sınır | Durum |
|---|---|---:|---:|---|
| en-US | Google Play — What's new | 403 | 500 | ✅ |
| en-US | App Store — What's New | 943 | 4000 | ✅ |
| tr-TR | Google Play — What's new | 402 | 500 | ✅ |
| tr-TR | App Store — What's New | 950 | 4000 | ✅ |
| de-DE | Google Play — What's new | 469 | 500 | ✅ |
| de-DE | App Store — What's New | 1048 | 4000 | ✅ |
| fr-FR | Google Play — What's new | 448 | 500 | ✅ |
| fr-FR | App Store — What's New | 1093 | 4000 | ✅ |
| es-ES | Google Play — What's new | 430 | 500 | ✅ |
| es-ES | App Store — What's New | 1004 | 4000 | ✅ |
| pt-BR | Google Play — What's new | 431 | 500 | ✅ |
| pt-BR | App Store — What's New | 1014 | 4000 | ✅ |
| it-IT | Google Play — What's new | 430 | 500 | ✅ |
| it-IT | App Store — What's New | 969 | 4000 | ✅ |
| nl-NL | Google Play — What's new | 440 | 500 | ✅ |
| nl-NL | App Store — What's New | 963 | 4000 | ✅ |
| pl-PL | Google Play — What's new | 409 | 500 | ✅ |
| pl-PL | App Store — What's New | 1043 | 4000 | ✅ |
<!-- lengths:end -->

---

## en-US

#### Google Play — What's new (≤500)

```text
What's new in 2.2:
• Fingerprint and face unlock are now free for everyone
• Scanning an IBAN with the camera or from a QR code is free too
• Share an IBAN as a clean card image. Premium adds a payment QR code to it
• Search all your cards from the home screen by name, bank, tag or last 4 digits
• Your most-used loyalty cards now come first, right after your favorites
• Smaller fixes and improvements
```

#### App Store — What's New (≤4000)

```text
What's new in 2.2

• Face ID and Touch ID for everyone
Unlocking with Face ID or Touch ID is now free. Turn it on in Settings › Security. If you don't have a PIN yet, the app helps you create one first.

• Free IBAN scanning
Scanning an IBAN with the camera or from a QR code is free for everyone.

• Share an IBAN as an image
Send your IBAN as a clean card image with the account holder, bank and IBAN, ready for any chat. With Premium, the image also carries a payment QR code. Sharing as text is still there.

• Search all your cards
Tap the search button on the home screen to find any credit card, IBAN or loyalty card by name, bank, brand, tag or last 4 digits. Accents and capital letters don't matter.

• Most-used cards first
Loyalty cards you show at the checkout most often move to the top, right after your favorites. The same order is used on your Apple Watch. You can still sort by name or date.

• Smaller fixes and improvements
```

---

## tr-TR

#### Google Play — What's new (≤500)

```text
2.2'de yeni:
• Parmak izi ve yüz tanımayla açma artık herkese ücretsiz
• IBAN'ı kamerayla ya da QR koddan taramak da ücretsiz
• IBAN'ını şık bir kart görseli olarak paylaş; Premium'da görsele ödeme QR'ı eklenir
• Ana ekrandan tüm kartlarında ara: isim, banka, etiket veya son 4 hane
• En çok kullandığın sadakat kartları artık favorilerinin hemen ardından en üstte
• Küçük düzeltmeler ve iyileştirmeler
```

#### App Store — What's New (≤4000)

```text
2.2'de yeni

• Face ID ve Touch ID herkese açık
Face ID veya Touch ID ile açma artık ücretsiz. Ayarlar › Güvenlik'ten aç. Henüz PIN'in yoksa uygulama önce PIN oluşturmana yardım eder.

• Ücretsiz IBAN tarama
IBAN'ı kamerayla ya da QR koddan taramak herkes için ücretsiz.

• IBAN'ı görsel olarak paylaş
IBAN'ını hesap sahibi, banka ve IBAN'ın yer aldığı şık bir kart görseli olarak gönder. Premium'da görsele ödeme QR kodu da eklenir. Metin olarak paylaşım da yerinde duruyor.

• Tüm kartlarında ara
Ana ekrandaki arama düğmesine dokun; kredi kartı, IBAN ya da sadakat kartını isim, banka, marka, etiket veya son 4 haneyle bul. "ı" ile "i", "ş" ile "s" fark etmez; büyük küçük harf de önemli değil.

• En çok kullanılanlar önde
Kasada en sık açtığın sadakat kartları, favorilerinin hemen ardından en üste çıkar. Apple Watch'ta da aynı sıra kullanılır. İstersen isme veya tarihe göre sıralamaya devam edebilirsin.

• Küçük düzeltmeler ve iyileştirmeler
```

---

## de-DE

#### Google Play — What's new (≤500)

```text
Neu in 2.2:
• Entsperren per Fingerabdruck oder Gesichtserkennung ist jetzt für alle kostenlos
• Auch das Scannen einer IBAN mit der Kamera oder per QR-Code ist kostenlos
• Teile deine IBAN als schönes Kartenbild. Mit Premium kommt ein Zahlungs-QR-Code dazu
• Durchsuche alle Karten vom Startbildschirm: Name, Bank, Tag oder letzte 4 Ziffern
• Deine meistgenutzten Kundenkarten stehen jetzt oben, direkt nach den Favoriten
• Kleinere Fehlerbehebungen und Verbesserungen
```

#### App Store — What's New (≤4000)

```text
Neu in 2.2

• Face ID und Touch ID für alle
Entsperren mit Face ID oder Touch ID ist jetzt kostenlos. Aktiviere es unter Einstellungen › Sicherheit. Hast du noch keine PIN, hilft dir die App zuerst beim Anlegen.

• IBAN-Scan kostenlos
Eine IBAN mit der Kamera oder per QR-Code zu scannen ist für alle kostenlos.

• IBAN als Bild teilen
Schick deine IBAN als schönes Kartenbild mit Kontoinhaber, Bank und IBAN – passend für jeden Chat. Mit Premium enthält das Bild zusätzlich einen Zahlungs-QR-Code. Teilen als Text gibt es weiterhin.

• Alle Karten durchsuchen
Tippe auf dem Startbildschirm auf die Suche und finde jede Kreditkarte, IBAN oder Kundenkarte nach Name, Bank, Marke, Tag oder den letzten 4 Ziffern. Akzente und Groß-/Kleinschreibung spielen keine Rolle.

• Meistgenutzte Karten zuerst
Kundenkarten, die du an der Kasse am häufigsten zeigst, rücken nach oben – direkt nach deinen Favoriten. Auf der Apple Watch gilt dieselbe Reihenfolge. Nach Name oder Datum sortieren kannst du weiterhin.

• Kleinere Fehlerbehebungen und Verbesserungen
```

---

## fr-FR

#### Google Play — What's new (≤500)

```text
Nouveautés de la 2.2 :
• Le déverrouillage par empreinte ou visage est désormais gratuit pour tous
• Scanner un IBAN avec l'appareil photo ou un QR code est gratuit aussi
• Partagez un IBAN sous forme de jolie carte. Avec Premium, un QR code de paiement s'y ajoute
• Cherchez dans toutes vos cartes depuis l'accueil : nom, banque, étiquette ou 4 derniers chiffres
• Vos cartes de fidélité les plus utilisées passent en tête, juste après vos favoris
```

#### App Store — What's New (≤4000)

```text
Nouveautés de la 2.2

• Face ID et Touch ID pour tous
Le déverrouillage par Face ID ou Touch ID est désormais gratuit. Activez-le dans Paramètres › Sécurité. Si vous n'avez pas encore de code PIN, l'app vous aide d'abord à en créer un.

• Scan d'IBAN gratuit
Scanner un IBAN avec l'appareil photo ou depuis un QR code est gratuit pour tous.

• Partager un IBAN en image
Envoyez votre IBAN sous forme de jolie carte avec le titulaire, la banque et l'IBAN, prête pour n'importe quelle messagerie. Avec Premium, l'image contient aussi un QR code de paiement. Le partage en texte est toujours là.

• Recherche dans toutes vos cartes
Touchez la recherche sur l'écran d'accueil pour retrouver une carte bancaire, un IBAN ou une carte de fidélité par nom, banque, marque, étiquette ou 4 derniers chiffres. Accents et majuscules ne comptent pas.

• Les plus utilisées d'abord
Les cartes de fidélité que vous présentez le plus souvent en caisse remontent en tête, juste après vos favoris. L'Apple Watch suit le même ordre. Vous pouvez toujours trier par nom ou par date.

• Corrections et améliorations
```

---

## es-ES

#### Google Play — What's new (≤500)

```text
Novedades de la 2.2:
• Desbloquear con huella o reconocimiento facial ya es gratis para todos
• Escanear un IBAN con la cámara o desde un código QR también es gratis
• Comparte un IBAN como una imagen de tarjeta. Con Premium lleva un código QR de pago
• Busca en todas tus tarjetas desde el inicio: nombre, banco, etiqueta o últimos 4 dígitos
• Tus tarjetas de fidelidad más usadas aparecen primero, justo después de tus favoritas
```

#### App Store — What's New (≤4000)

```text
Novedades de la 2.2

• Face ID y Touch ID para todos
Desbloquear con Face ID o Touch ID ya es gratis. Actívalo en Ajustes › Seguridad. Si aún no tienes PIN, la app te ayuda a crearlo primero.

• Escaneo de IBAN gratis
Escanear un IBAN con la cámara o desde un código QR es gratis para todos.

• Comparte un IBAN como imagen
Envía tu IBAN como una imagen de tarjeta con el titular, el banco y el IBAN, lista para cualquier chat. Con Premium, la imagen incluye además un código QR de pago. Compartir como texto sigue disponible.

• Busca en todas tus tarjetas
Toca la búsqueda en la pantalla de inicio para encontrar cualquier tarjeta de crédito, IBAN o tarjeta de fidelidad por nombre, banco, marca, etiqueta o últimos 4 dígitos. Las tildes y las mayúsculas dan igual.

• Las más usadas, primero
Las tarjetas de fidelidad que más enseñas en caja suben arriba, justo después de tus favoritas. El Apple Watch usa el mismo orden. Puedes seguir ordenando por nombre o fecha.

• Pequeñas correcciones y mejoras
```

---

## pt-BR

#### Google Play — What's new (≤500)

```text
Novidades da 2.2:
• Desbloquear com impressão digital ou reconhecimento facial agora é grátis para todos
• Escanear um IBAN com a câmera ou por QR code também é grátis
• Compartilhe um IBAN como imagem de cartão. Com Premium, ela ganha um QR code de pagamento
• Busque em todos os seus cartões na tela inicial: nome, banco, etiqueta ou últimos 4 dígitos
• Seus cartões fidelidade mais usados vêm primeiro, logo depois dos favoritos
```

#### App Store — What's New (≤4000)

```text
Novidades da 2.2

• Face ID e Touch ID para todos
Desbloquear com Face ID ou Touch ID agora é grátis. Ative em Configurações › Segurança. Se você ainda não tem PIN, o app ajuda a criar um primeiro.

• Leitura de IBAN grátis
Escanear um IBAN com a câmera ou por QR code é grátis para todos.

• Compartilhe um IBAN como imagem
Envie seu IBAN como uma imagem de cartão com o titular, o banco e o IBAN, pronta para qualquer conversa. Com Premium, a imagem também traz um QR code de pagamento. Compartilhar como texto continua disponível.

• Busque em todos os seus cartões
Toque na busca da tela inicial para encontrar qualquer cartão de crédito, IBAN ou cartão fidelidade por nome, banco, marca, etiqueta ou últimos 4 dígitos. Acentos e maiúsculas não fazem diferença.

• Os mais usados primeiro
Os cartões fidelidade que você mostra no caixa com mais frequência sobem para o topo, logo depois dos favoritos. O Apple Watch usa a mesma ordem. Você ainda pode ordenar por nome ou data.

• Pequenas correções e melhorias
```

---

## it-IT

#### Google Play — What's new (≤500)

```text
Novità della 2.2:
• Lo sblocco con impronta digitale o volto ora è gratis per tutti
• Anche scansionare un IBAN con la fotocamera o da un QR code è gratis
• Condividi un IBAN come immagine della carta. Con Premium include un QR code di pagamento
• Cerca in tutte le carte dalla home: nome, banca, tag o ultime 4 cifre
• Le carte fedeltà che usi di più ora sono in cima, subito dopo i preferiti
• Piccole correzioni e miglioramenti
```

#### App Store — What's New (≤4000)

```text
Novità della 2.2

• Face ID e Touch ID per tutti
Lo sblocco con Face ID o Touch ID ora è gratis. Attivalo in Impostazioni › Sicurezza. Se non hai ancora un PIN, l'app ti aiuta prima a crearne uno.

• Scansione IBAN gratis
Scansionare un IBAN con la fotocamera o da un QR code è gratis per tutti.

• Condividi un IBAN come immagine
Invia il tuo IBAN come immagine della carta con intestatario, banca e IBAN, pronta per qualsiasi chat. Con Premium, l'immagine include anche un QR code di pagamento. La condivisione come testo resta disponibile.

• Cerca in tutte le carte
Tocca la ricerca nella home per trovare qualsiasi carta di credito, IBAN o carta fedeltà per nome, banca, marca, tag o ultime 4 cifre. Accenti e maiuscole non contano.

• Le più usate in cima
Le carte fedeltà che mostri più spesso alla cassa salgono in cima, subito dopo i preferiti. Sull'Apple Watch vale lo stesso ordine. Puoi sempre ordinare per nome o data.

• Piccole correzioni e miglioramenti
```

---

## nl-NL

#### Google Play — What's new (≤500)

```text
Nieuw in 2.2:
• Ontgrendelen met vingerafdruk of gezicht is nu gratis voor iedereen
• Een IBAN scannen met de camera of via een QR-code is ook gratis
• Deel een IBAN als strakke kaartafbeelding. Met Premium komt er een betaal-QR-code bij
• Zoek vanaf het beginscherm in al je kaarten: naam, bank, label of laatste 4 cijfers
• Je meest gebruikte klantenkaarten staan nu bovenaan, direct na je favorieten
• Kleine verbeteringen en oplossingen
```

#### App Store — What's New (≤4000)

```text
Nieuw in 2.2

• Face ID en Touch ID voor iedereen
Ontgrendelen met Face ID of Touch ID is nu gratis. Zet het aan via Instellingen › Beveiliging. Heb je nog geen pincode, dan helpt de app je eerst er een te maken.

• Gratis IBAN scannen
Een IBAN scannen met de camera of via een QR-code is gratis voor iedereen.

• Deel een IBAN als afbeelding
Stuur je IBAN als strakke kaartafbeelding met rekeninghouder, bank en IBAN, klaar voor elke chat. Met Premium staat er ook een betaal-QR-code op. Delen als tekst kan nog steeds.

• Zoek in al je kaarten
Tik op het beginscherm op zoeken en vind elke creditcard, IBAN of klantenkaart op naam, bank, merk, label of de laatste 4 cijfers. Accenten en hoofdletters maken niet uit.

• Meest gebruikt eerst
Klantenkaarten die je het vaakst bij de kassa laat zien, komen bovenaan, direct na je favorieten. Je Apple Watch gebruikt dezelfde volgorde. Sorteren op naam of datum kan nog steeds.

• Kleine verbeteringen en oplossingen
```

---

## pl-PL

#### Google Play — What's new (≤500)

```text
Nowości w 2.2:
• Odblokowywanie odciskiem palca lub twarzą jest teraz bezpłatne dla wszystkich
• Skanowanie IBAN aparatem lub z kodu QR też jest bezpłatne
• Udostępnij IBAN jako estetyczny obraz karty. W Premium dochodzi kod QR do płatności
• Szukaj we wszystkich kartach z ekranu głównego: nazwa, bank, tag lub ostatnie 4 cyfry
• Najczęściej używane karty lojalnościowe są teraz na górze, zaraz po ulubionych
```

#### App Store — What's New (≤4000)

```text
Nowości w 2.2

• Face ID i Touch ID dla wszystkich
Odblokowywanie przez Face ID lub Touch ID jest teraz bezpłatne. Włącz je w Ustawienia › Bezpieczeństwo. Jeśli nie masz jeszcze PIN-u, aplikacja najpierw pomoże go utworzyć.

• Bezpłatne skanowanie IBAN
Skanowanie IBAN aparatem lub z kodu QR jest bezpłatne dla wszystkich.

• Udostępnij IBAN jako obraz
Wyślij swój IBAN jako estetyczny obraz karty z właścicielem konta, bankiem i numerem IBAN, gotowy do każdego czatu. W Premium obraz zawiera też kod QR do płatności. Udostępnianie jako tekst nadal działa.

• Szukaj we wszystkich kartach
Stuknij wyszukiwanie na ekranie głównym i znajdź kartę kredytową, IBAN lub kartę lojalnościową po nazwie, banku, marce, tagu lub ostatnich 4 cyfrach. Polskie znaki i wielkie litery nie mają znaczenia.

• Najczęściej używane na górze
Karty lojalnościowe, które najczęściej pokazujesz przy kasie, przesuwają się na górę, zaraz po ulubionych. Apple Watch używa tej samej kolejności. Nadal możesz sortować po nazwie lub dacie.

• Drobne poprawki i ulepszenia
```
