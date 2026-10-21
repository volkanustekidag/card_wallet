# Card Wallet 2.2 — Mağaza sayfası düzeltmeleri

`docs/store/v2.1/listing.md` metinleri 2.2 ile iki noktada yanlış oldu, bir noktada eksik kaldı. Bu dosya yalnızca değişen satırları veriyor; geri kalan metin (anahtar kelimeler, alt başlık, abonelik paragrafı, ücretsiz sınırlar) aynen kalıyor.

## Ne bulundu

| # | Ne | Nerede | Durum |
|---|---|---|---|
| 1 | Face ID / Touch ID / parmak izi Premium listesinde | 9 dil × App Store + Play açıklaması, "PREMIUM" bloğu | **Yanlış.** Biyometrik artık herkese ücretsiz. Satır silinir. |
| 2 | "PIN ile kilit, Premium'da Face ID veya Touch ID" | tr-TR App Store + Play, "GÜVENLİK" bloğu | **Yanlış.** Satır düzeltilir. |
| 3 | Güvenlik bloğunda biyometrik hiç geçmiyor | Diğer 8 dil, App Store + Play | Premium'dan çıkan özellik ücretsiz tarafta yazılmazsa kaybolur. PIN satırına eklendi. |
| 4 | "IBAN tarama Premium" | — | **Mağaza metninde bulunamadı.** 2.1 notu "IBAN tarama hiçbir yerde vaat edilmedi" diyor, doğrulandı. Yanlış iddia yalnızca uygulamadaki paywall listesindeydi ve 2.2'de oradan kaldırıldı. Değişiklik gerekmiyor. |
| 5 | "IBAN'ı görsel olarak paylaşma özelliği yok" | v2.1 listing.md, iç not ("Bilerek yazılmayanlar") | Artık yanlış. IBAN satırına görsel paylaşım eklendi (önerilen). Ödeme QR'ı Premium listesinde "IBAN QR kodu" olarak zaten duruyor. |
| 6 | "Face ID, yedekleme, Wallet'a ekleme ve IBAN QR kodda Premium'a bağlı" | v2.1 listing.md, iç not tablosu ("Premium" satırı) | Artık yanlış. Doğrusu: "Yedekleme, Wallet'a ekleme ve IBAN QR kod Premium'a bağlı; Face ID / parmak izi ve IBAN tarama ücretsiz." |
| 7 | Promotional Text "New in 2.1: …" | 9 dil, App Store | Güncel değil. 2.2 metni aşağıda (≤170, kontrol aracıyla sayıldı). |

Uygulama notları:
- "Eski" sütunundaki her satır v2.1 listing'de ilgili mağaza bölümünde **tam olarak bir kez** geçiyor (script ile kontrol edildi), yani konsolda bul-değiştir ile güvenle uygulanabilir.
- Satır silmek ve PIN satırını uzatmak açıklamaları en fazla ~40 karakter değiştiriyor; en uzun açıklama 2463 karakter, sınır 4000.
- Anahtar kelimelere dokunulmadı: tr-TR'de `face id` zaten var ve hâlâ doğru.
- Aramayı ve kullanım sıralamasını açıklamaya eklemek isteğe bağlı; "Ara, etiketle filtrele" satırı 2.1'de de doğruydu, şimdi tüm kart türlerini kapsıyor.

Promotional Text uzunluklarını yeniden saymak için: `python3 tools/check_store_text.py --write docs/store/v2.2/listing_changes.md`

<!-- lengths:start -->
| Dil | Alan | Uzunluk | Sınır | Durum |
|---|---|---:|---:|---|
| en-US | App Store — Promotional Text | 137 | 170 | ✅ |
| tr-TR | App Store — Promotional Text | 139 | 170 | ✅ |
| de-DE | App Store — Promotional Text | 130 | 170 | ✅ |
| fr-FR | App Store — Promotional Text | 147 | 170 | ✅ |
| es-ES | App Store — Promotional Text | 142 | 170 | ✅ |
| pt-BR | App Store — Promotional Text | 136 | 170 | ✅ |
| it-IT | App Store — Promotional Text | 127 | 170 | ✅ |
| nl-NL | App Store — Promotional Text | 140 | 170 | ✅ |
| pl-PL | App Store — Promotional Text | 149 | 170 | ✅ |
<!-- lengths:end -->

---

## en-US

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Unlock with Face ID or Touch ID` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Unlock with your fingerprint or face` | *satırı sil* |
| App Store — Description | Güvenlik | `• PIN lock with auto-lock, and your cards are hidden in the app switcher` | `• PIN, Face ID or Touch ID lock with auto-lock, and your cards are hidden in the app switcher` |
| Google Play — Full description | Güvenlik | `• PIN lock with auto-lock, and card screens are hidden from screenshots and the recent apps view` | `• PIN, fingerprint or face lock with auto-lock, and card screens are hidden from screenshots and the recent apps view` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• Copy or share an IBAN in one tap` | `• Copy an IBAN in one tap, or share it as text or as a card image` |

#### App Store — Promotional Text (≤170)

```text
New in 2.2: Face ID and Touch ID free for everyone, search across all your cards, IBANs shared as images, and your most-used cards first.
```

---

## tr-TR

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Face ID / Touch ID ile açma` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Parmak izi veya yüz tanımayla açma` | *satırı sil* |
| App Store — Description | Güvenlik | `• PIN ile kilit, Premium'da Face ID veya Touch ID` | `• PIN, Face ID veya Touch ID ile kilit` |
| Google Play — Full description | Güvenlik | `• PIN ile kilit, Premium'da parmak izi veya yüz tanıma` | `• PIN, parmak izi veya yüz tanımayla kilit` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• Tek dokunuşla kopyala, mesajla paylaş` | `• Tek dokunuşla kopyala; metin ya da kart görseli olarak paylaş` |

#### App Store — Promotional Text (≤170)

```text
2.2'de yeni: Face ID ve Touch ID herkese ücretsiz, tüm kartlarında arama, IBAN'ı görsel olarak paylaşma ve en çok kullandığın kartlar önde.
```

---

## de-DE

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Entsperren mit Face ID oder Touch ID` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Entsperren per Fingerabdruck oder Gesichtserkennung` | *satırı sil* |
| App Store — Description | Güvenlik | `• PIN-Sperre mit automatischer Sperre; im App-Umschalter sind deine Karten verdeckt` | `• Sperre per PIN, Face ID oder Touch ID mit automatischer Sperre; im App-Umschalter sind deine Karten verdeckt` |
| Google Play — Full description | Güvenlik | `• PIN-Sperre mit automatischer Sperre; Kartenansichten sind in Screenshots und in der Übersicht der letzten Apps verborgen` | `• Sperre per PIN, Fingerabdruck oder Gesichtserkennung mit automatischer Sperre; Kartenansichten sind in Screenshots und in der Übersicht der letzten Apps verborgen` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• IBAN mit einem Tippen kopieren oder teilen` | `• IBAN mit einem Tippen kopieren oder als Text bzw. Kartenbild teilen` |

#### App Store — Promotional Text (≤170)

```text
Neu in 2.2: Face ID und Touch ID für alle kostenlos, Suche über alle Karten, IBAN als Bild teilen und meistgenutzte Karten zuerst.
```

---

## fr-FR

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Déverrouillage par Face ID ou Touch ID` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Déverrouillage par empreinte digitale ou reconnaissance faciale` | *satırı sil* |
| App Store — Description | Güvenlik | `• Verrouillage par code PIN avec verrouillage auto ; vos cartes sont masquées dans le sélecteur d'apps` | `• Verrouillage par code PIN, Face ID ou Touch ID avec verrouillage auto ; vos cartes sont masquées dans le sélecteur d'apps` |
| Google Play — Full description | Güvenlik | `• Verrouillage par code PIN avec verrouillage auto ; les écrans de carte sont masqués dans les captures et les apps récentes` | `• Verrouillage par code PIN, empreinte ou visage avec verrouillage auto ; les écrans de carte sont masqués dans les captures et les apps récentes` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• Copiez ou partagez un IBAN d'un geste` | `• Copiez un IBAN d'un geste, ou partagez-le en texte ou en image` |

#### App Store — Promotional Text (≤170)

```text
Nouveau dans la 2.2 : Face ID et Touch ID gratuits pour tous, recherche dans toutes vos cartes, IBAN en image et cartes les plus utilisées en tête.
```

---

## es-ES

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Desbloqueo con Face ID o Touch ID` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Desbloqueo con huella o reconocimiento facial` | *satırı sil* |
| App Store — Description | Güvenlik | `• Bloqueo con PIN y bloqueo automático; tus tarjetas se ocultan al cambiar de app` | `• Bloqueo con PIN, Face ID o Touch ID y bloqueo automático; tus tarjetas se ocultan al cambiar de app` |
| Google Play — Full description | Güvenlik | `• Bloqueo con PIN y bloqueo automático; las pantallas de tarjetas no salen en capturas ni en apps recientes` | `• Bloqueo con PIN, huella o cara y bloqueo automático; las pantallas de tarjetas no salen en capturas ni en apps recientes` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• Copia o comparte un IBAN con un toque` | `• Copia un IBAN con un toque o compártelo como texto o imagen` |

#### App Store — Promotional Text (≤170)

```text
Novedades de la 2.2: Face ID y Touch ID gratis para todos, búsqueda en todas tus tarjetas, IBAN como imagen y tus tarjetas más usadas primero.
```

---

## pt-BR

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Desbloqueio com Face ID ou Touch ID` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Desbloqueio com impressão digital ou reconhecimento facial` | *satırı sil* |
| App Store — Description | Güvenlik | `• Bloqueio por PIN com bloqueio automático; seus cartões ficam escondidos na troca de apps` | `• Bloqueio por PIN, Face ID ou Touch ID com bloqueio automático; seus cartões ficam escondidos na troca de apps` |
| Google Play — Full description | Güvenlik | `• Bloqueio por PIN com bloqueio automático; as telas dos cartões não aparecem em capturas nem em apps recentes` | `• Bloqueio por PIN, impressão digital ou rosto com bloqueio automático; as telas dos cartões não aparecem em capturas nem em apps recentes` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• Copie ou compartilhe um IBAN com um toque` | `• Copie um IBAN com um toque ou compartilhe como texto ou imagem` |

#### App Store — Promotional Text (≤170)

```text
Novidades da 2.2: Face ID e Touch ID grátis para todos, busca em todos os cartões, IBAN como imagem e seus cartões mais usados primeiro.
```

---

## it-IT

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Sblocco con Face ID o Touch ID` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Sblocco con impronta digitale o riconoscimento del volto` | *satırı sil* |
| App Store — Description | Güvenlik | `• Blocco con PIN e blocco automatico; le tue carte sono nascoste quando passi da un'app all'altra` | `• Blocco con PIN, Face ID o Touch ID e blocco automatico; le tue carte sono nascoste quando passi da un'app all'altra` |
| Google Play — Full description | Güvenlik | `• Blocco con PIN e blocco automatico; le schermate delle carte non compaiono negli screenshot né nelle app recenti` | `• Blocco con PIN, impronta o volto e blocco automatico; le schermate delle carte non compaiono negli screenshot né nelle app recenti` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• Copia o condividi un IBAN con un tocco` | `• Copia un IBAN con un tocco o condividilo come testo o immagine` |

#### App Store — Promotional Text (≤170)

```text
Novità della 2.2: Face ID e Touch ID gratis per tutti, ricerca in tutte le carte, IBAN come immagine e carte più usate in cima.
```

---

## nl-NL

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Ontgrendelen met Face ID of Touch ID` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Ontgrendelen met vingerafdruk of gezichtsherkenning` | *satırı sil* |
| App Store — Description | Güvenlik | `• Vergrendeling met pincode en automatisch vergrendelen; je kaarten zijn verborgen in de appkiezer` | `• Vergrendeling met pincode, Face ID of Touch ID en automatisch vergrendelen; je kaarten zijn verborgen in de appkiezer` |
| Google Play — Full description | Güvenlik | `• Vergrendeling met pincode en automatisch vergrendelen; kaartschermen zijn verborgen in screenshots en recente apps` | `• Vergrendeling met pincode, vingerafdruk of gezicht en automatisch vergrendelen; kaartschermen zijn verborgen in screenshots en recente apps` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• Kopieer of deel een IBAN met één tik` | `• Kopieer een IBAN met één tik of deel hem als tekst of afbeelding` |

#### App Store — Promotional Text (≤170)

```text
Nieuw in 2.2: Face ID en Touch ID gratis voor iedereen, zoeken in al je kaarten, IBAN delen als afbeelding en meest gebruikte kaarten eerst.
```

---

## pl-PL

**Zorunlu (artık yanlış):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store — Description | Premium listesi | `• Odblokowywanie przez Face ID lub Touch ID` | *satırı sil* |
| Google Play — Full description | Premium listesi | `• Odblokowywanie odciskiem palca lub rozpoznawaniem twarzy` | *satırı sil* |
| App Store — Description | Güvenlik | `• Blokada PIN-em i automatyczna blokada; przy przełączaniu aplikacji karty są zasłonięte` | `• Blokada PIN-em, Face ID lub Touch ID i automatyczna blokada; przy przełączaniu aplikacji karty są zasłonięte` |
| Google Play — Full description | Güvenlik | `• Blokada PIN-em i automatyczna blokada; ekrany kart są ukryte na zrzutach ekranu i w ostatnich aplikacjach` | `• Blokada PIN-em, odciskiem palca lub twarzą i automatyczna blokada; ekrany kart są ukryte na zrzutach ekranu i w ostatnich aplikacjach` |

**Önerilen (2.2 özellikleri):**

| Mağaza | Bölüm | Eski (2.1) | Yeni (2.2) |
|---|---|---|---|
| App Store + Google Play | IBAN | `• Kopiuj lub udostępniaj IBAN jednym dotknięciem` | `• Kopiuj IBAN jednym dotknięciem lub udostępniaj jako tekst albo obraz` |

#### App Store — Promotional Text (≤170)

```text
Nowość w 2.2: Face ID i Touch ID bezpłatnie dla wszystkich, wyszukiwanie we wszystkich kartach, IBAN jako obraz i najczęściej używane karty na górze.
```
