# REV-63 · Mağaza Ekranı Görsel Tasarımı

> **Durum:** Ekip kararı bekliyor (ekran tasarımı + akış + asset/rozet üretim yönergesi).
> Konseptler onaylanınca rozet/kart assetleri Gemini'de üretilir; kod tarafı (ekran + katalog +
> satın alma akışı) ayrı bir **client** task'ında (**REV-69**) uygulanır. Bu doküman repo koduna
> **dokunmaz** — yalnız tasarım + akış + yönerge üretir.
>
> **Sahibi:** Enes (görsel tasarım) · **Task:** REV-63 · **Bağımlı:** REV-61 (çerçeveler),
> REV-62 (tahta/tema kararı) · **Bloklar:** REV-69 (mağaza kodlaması), REV-64 (yönlendirme
> noktaları) · **İlgili:** REV-66 (coin/cüzdan/envanter) · **Takım:** Reversi_Game

---

## 1. Özet karar

- **Tek ekran, dört kategori, sekmeli vitrin.** Parchment/ahşap shell (REV-62 tek-görünüm kararı)
  üstüne clipper header + kalıcı coin bakiyesi + 4 kategori sekmesi + ürün kartı grid'i. → **§4**
- **Envanter REV-61 + REV-62'den birebir gelir.** Çerçeveler (REV-61: 6 kademe + 5 satılık),
  tahtalar (REV-62: 3 ücretsiz + 2 ücretli), taş renkleri (yeni küçük set), coin paketleri (IAP).
  → **§5**
- **Tek ürün kartı anatomisi, dört durum.** satın alınabilir / satın alındı (sahip) / kuşanıldı /
  kilitli (kademe şartı). Yetersiz-bakiye alt-durumu ayrıca ele alınır. → **§6**
- **İki satın alma yolu net ayrık.** Coin ile alım = `purchaseItem` + onay diyaloğu (§7). Coin
  paketleri = gerçek para (Play Billing), görsel olarak **₺ rozetiyle** coin-fiyatlı ürünlerden
  ayrılır (§8). Ödeme modeli coin + IAP birlikte (2026-07-14 kararı).
- **Fiyat rampası REV-61/62 ile birebir aynı:** Standart ~500 · Nadir ~1.500 · Epik ~3.500 (coin);
  mutlak değerler coin ekonomisi netleşince **tek katsayıyla** ölçeklenir. → **§5.5**

**Dayanak:** Tasarım (a) REV-62 tek ahşap/parchment shell + korunan turkuaz accent (`#13A99C`),
(b) REV-61 çerçeve aileleri + fiyat sınıfları, (c) kod gerçeği (§3: boş `catalog.ts`, hazır
`purchaseItem`, mevcut ekran/dialog/coin desenleri) ile tutarlı kurgulandı.

---

## 2. Kapsam ve teslim

REV-63 tanımından beş başlık:

1. **Kategoriler:** profil çerçeveleri, tahtalar, taş renkleri, coin paketleri → **§4.3 + §5**
2. **Ürün kartları:** görsel + ad + coin fiyatı; durumlar satın alınabilir / satın alındı /
   kuşanıldı / kilitli (kademe şartı) → **§6**
3. **Coin bakiyesi göstergesi** (ekran üstü, kalıcı) → **§4.2**
4. **Satın alma akışı:** onay diyaloğu + başarı animasyonu/durumu → **§7**
5. **Boş / yükleniyor / hata durumları** → **§9**

**Teslim:** ekran tasarımı (tüm durumlarıyla, bu doküman) + kart/rozet asset üretim yönergesi
(§10, Gemini) → ekip kararı → **REV-69** (client) ekranı ve katalog verisini kodlar. Bu doküman
**koda/pubspec/`catalog.ts`'e dokunmaz.**

> **Bu dokümanın ürettiği:** ekran mimarisi + kategori/durum/akış spec'i + rozet asset standardı +
> REV-69 için katalog şeması notları. **Somut rozet/kart PNG'leri** onay sonrası Gemini'de üretilir
> (REV-61 çerçeve iş akışıyla aynı); ürün önizlemeleri REV-61 çerçeve PNG'leri + REV-62 tahta
> thumbnail'leri + taş render'larını yeniden kullanır.

---

## 3. Mevcut kod gerçeği (karar buna dayanır)

Explorer recon'u (read-only) ile doğrulandı.

### 3.1 Backend — satın alma hazır, katalog boş

- **`functions/src/catalog.ts`:** `CatalogItem { id: string; category: "frame" | "board" |
  "coinSkin"; price: number }` — `CATALOG` şu an **boş** (`{}`). "Epic 12 tasarımı gelince
  doldurulacak" notuyla bekliyor.
- **`functions/src/purchase.ts` → `purchaseItem` (onCall):** `itemId` alır; transaction'da (1)
  item katalogda var mı, (2) `coins >= price`, (3) `itemId` zaten `ownedItems[]`'de değil →
  atomik olarak coini düşer + `itemId`'yi `ownedItems[]`'e ekler. Hata kodları:
  `unauthenticated`, `invalid-argument`, `not-found`, `already-exists`, `failed-precondition`.
- **Boşluklar (REV-69 için, §11):** katalogda **kademe-şartı (tier-lock) alanı YOK**, **IAP/coin
  paketi türü YOK**, **"kuşanılan" (equipped) durum alanı YOK** (`ownedItems` yalnız sahiplik).

### 3.2 Tema token'ları

| Token | Değer | Kaynak |
|---|---|---|
| Accent turkuaz | `#13A99C` | `game_colors.dart` (marka etkileşim — REV-62'de korunuyor) |
| Coral/accent2 | `#F4552C` | `game_colors.dart` |
| Cream gradyan | `#FFF6E9` → `#FFEDD6` | `game_colors.dart` (original shell zemini) |
| Ink (metin) | `#20302E` / soft `#3A4A48` | `game_colors.dart` |
| **Gold (ahşap vurgu)** | `#B8860B` / text `#9A6B2F` | `wood_theme.dart` |
| **Parchment/surface** | `#EFE5D5` | `wood_theme.dart` (tek-görünüm zemini) |
| **Card gradyan** | `#F5EAD4` → `#EBDBBE` | `wood_theme.dart` |
| **Button gradyan** | `#56391F` → `#3E2A1E` | `wood_theme.dart` |
| Font | **Marcellus** (başlık), **Lora** (metin) | `wood_theme.dart` |

### 3.3 Emsal desenler (mağaza bunları taban alır)

- **Ekran iskeleti (Profile/Settings ortak):** `Scaffold` (gradient `DecoratedBox`) → `Positioned`
  clipper header (~150 px, `CustomClipper` diagonal cut, bannerGradient) → `SafeArea` → `ListView`
  (padding bottom 24) → `_Card` wrapper (radius **20**, white/parchment bg, shadow 0,8,20, padding 14–16).
- **Grid seçim tile (`board_theme_grid.dart`):** tile **88×88**, radius 16; aktif kenarlık
  `Border.all(GameColors.accent, width: 3)` (AnimatedContainer); `Wrap(spacing: 12, runSpacing: 12)`;
  kilitli durum `Opacity(0.28)`. **Kuşanıldı/aktif = 3 px turkuaz kenarlık** deseni birebir emsal.
- **Coin görünümü (`coin_view.dart` + `coin_palette.dart`):** `CoinView(palette, width, ...)`
  CustomPaint 3B madeni para; `CoinPalette` = **Black / White / Turquoise / Orange** (4 taban renk).
  `CoinRow` swatch **38×38**, 3 px aktif accent kenarlık, disabled opacity 0.28.
- **Dialog:** `showDialog<bool>` + `AlertDialog(title, content, actions:[TextButton(false),
  FilledButton(true)])`. Bottom sheet: `showModalBottomSheet(backgroundColor: transparent, ...)`.
- **Avatar:** `CircleAvatar(radius: 48)` (profil vitrini — çerçeve önizlemesi buraya oturur, REV-61 §6).
- **Mağaza ekranı / route:** **YOK** — `lib/features/` altında shop/store/market yok; REV-69
  sıfırdan `lib/features/shop/` açacak.

---

## 4. Ekran mimarisi

### 4.1 Genel iskelet (mevcut ekran deseniyle bire bir)

```
Scaffold (parchment gradient DecoratedBox)
 ├─ Positioned header (~150 px, CustomClipper diagonal)   → §4.2
 │    ├─ Başlık "Mağaza" (Marcellus, uppercase, white + shadow)
 │    └─ Kalıcı coin bakiyesi chip (sağ üst)               → §4.2
 └─ SafeArea → Column
      ├─ Kategori sekme çubuğu (4 sekme, yatay)            → §4.3
      └─ Aktif kategorinin ürün grid'i (ListView/Wrap)     → §5, §6
           └─ ProductCard × N  (radius 20, parchment card) → §6
```

Shell = **REV-62 tek ahşap/parchment görünüm**: zemin parchment `#EFE5D5`, kartlar card-gradyan
`#F5EAD4→#EBDBBE`, başlık Marcellus + gold `#B8860B` vurgu, gövde Lora. **Turkuaz accent `#13A99C`
korunur** → seçili/kuşanıldı kenarlığı, sekme altı çizgi, birincil buton dolgusu turkuaz kalır
(REV-62 §4.1: kaldırılan app-teması seçicisiydi, turkuaz kimliği değil).

### 4.2 Kalıcı coin bakiyesi göstergesi (ekran üstü)

- **Konum:** header sağ-üst, `SafeArea` içinde sabit — kategori değişse de scroll'da da **her zaman
  görünür** (header pinned; grid altında kayar).
- **Anatomi:** yuvarlak-köşeli chip (radius ~20, yarı-saydam koyu/parchment dolgu) → soldan
  `CoinView` madeni para ikonu (∅ ~22–24) + binlik ayraçlı bakiye (`1.250`, Marcellus/Lora tabular).
  Sağda küçük **"+" butonu** → coin paketleri kategorisine kısa yol (§8, REV-64 yönlendirme ile hizalı).
- **Davranış:** satın alma sonrası bakiye **aşağı sayarak** (tick-down) güncellenir (§7.3). Yetersiz
  bakiyede chip kısa turuncu (`#F4552C`) titreşimiyle dikkat çeker, "+" öne çıkar.
- **Kaynak:** bakiye REV-66 cüzdanından (Firestore `coins`) canlı okunur; offline'da son bilinen
  değer + soluk "çevrimdışı" ipucu.

### 4.3 Kategori navigasyonu — 4 sekme

Dört kategori az ve eşit ağırlıklı → **yatay sekme çubuğu** (tek scroll'da bölüm başlıkları yerine),
aktif sekmede turkuaz alt-çizgi + Marcellus. Kod tarafı `TabBar/TabBarView` ya da basit segmented
selector; öneri sekme çubuğu (mağazada gezinme daha net).

| # | Sekme (TR) | catalog `category` | İçerik kaynağı | Ödeme |
|---|---|---|---|---|
| 1 | **Çerçeveler** | `frame` | REV-61 (6 kademe + 5 satılık) | Coin + kademe-şartı |
| 2 | **Tahtalar** | `board` | REV-62 (3 ücretsiz + 2 ücretli) | Coin |
| 3 | **Taş Renkleri** | `coinSkin` | §5.3 (taban 4 + premium set) | Coin |
| 4 | **Coin Paketleri** | *(IAP — katalog dışı)* | §8 | **Gerçek para (₺)** |

> **Alternatif (ekip için):** 4 sekme yerine tek uzun scroll + bölüm başlıkları da olur; sekme
> öneriliyor çünkü coin paketleri (gerçek para) kategorisini görsel/zihinsel olarak coin-ürünlerden
> ayırmak daha kolay.

---

## 5. Vitrin envanteri (REV-61 + REV-62'den)

### 5.1 Çerçeveler — `frame` (REV-61)

**Kademe çerçeveleri (6, otomatik — satılmaz):** mağazada **"kilitli (kademe şartı)"** durumuyla
görünür; fiyat yerine kademe rozeti + "Kademe N gerekir" etiketi taşır (§6 durum 4). Ulaşılan
kademede otomatik açılır. REV-61 §4 tablosu: Çaylak / Acemi / Kalfa / Usta / Büyükusta / Efsane.

**Satılık çerçeveler (5, coin):**

| Ürün | itemId (öneri) | Fiyat sınıfı | Coin |
|---|---|---|---|
| Oyma Ceviz / Carved Walnut | `frame_carved_walnut` | Standart | ~500 |
| Bahar Sarmaşığı / Floral Vine | `frame_floral_vine` | Standart | ~500 |
| Mermer & Altın / Marble & Gold | `frame_marble_gold` | Nadir | ~1.500 |
| Neon Işıltı / Neon Glow | `frame_neon_glow` | Nadir | ~1.500 |
| Şampiyon Defnesi / Champion Laurel | `frame_champion_laurel` | Epik | ~3.500 |

### 5.2 Tahtalar — `board` (REV-62)

| Ürün | itemId (öneri) | Erişim | Fiyat |
|---|---|---|---|
| Ahşap (wood) | *(varsayılan — katalogsuz)* | 🆓 Ücretsiz | — |
| Turkuaz | *(ücretsiz — katalogsuz)* | 🆓 Ücretsiz | — |
| Gece | *(ücretsiz — katalogsuz)* | 🆓 Ücretsiz | — |
| Mermer | `board_mermer` | 💰 Nadir | ~1.500 |
| Çiçek | `board_cicek` | 💰 Epik | ~3.500 |

> Ücretsiz tahtalar mağazada **"Sahip" / "Kuşan"** durumuyla görünür (fiyatsız) — vitrin bütünlüğü
> için gösterilir ama satın alınmaz. Katalog yalnız ücretli item'ları taşır (REV-69 notu §11).

### 5.3 Taş Renkleri — `coinSkin` (yeni küçük set)

> ⚠️ **REV-62 §4.4 ile uzlaştırma (ekip onayı gerekir):** REV-62, ayarlardaki **ücretsiz disk-renk
> seçicisini** kaldırmayı önerdi ("her tahta kendi diskini belirler"). REV-63 kapsamı ise "taş
> renkleri"ni bir **mağaza kategorisi** olarak, `catalog.ts` de `coinSkin` türünü içeriyor. Önerilen
> uzlaşma: **taban renkler ücretsiz kalır**, taş renkleri artık ayrı bir ayar toggle'ı değil, mağazadan
> **sahip olunup kuşanılan kozmetik**tir. Böylece REV-62'nin "ayarları sadeleştir" amacı korunur
> (ayardan kalkar) ama monetizasyon + kişiselleştirme mağazaya taşınır. → **açık nokta §12.4**.

Taban seti kodda hazır (`CoinPalette`: Black / White / Turquoise / Orange). Öneri:

| Taş | itemId (öneri) | Erişim | Fiyat |
|---|---|---|---|
| Klasik (siyah/beyaz) | *(varsayılan)* | 🆓 Ücretsiz | — |
| Turkuaz taş | `coinSkin_turkuaz` | 🆓 Ücretsiz | — (marka, taban) |
| Mercan taş (turuncu) | `coinSkin_mercan` | 💰 Standart | ~500 |
| Altın mermer taş | `coinSkin_marble_gold` | 💰 Standart | ~500 |
| Gül-altın çiçek taş | `coinSkin_rose_gold` | 💰 Nadir | ~1.500 |

> Küçük başlangıç seti (2 ücretsiz + 3 ücretli). Adet/renk ekip kararı (§12.4). Premium taşlar
> ücretli tahtalarla (mermer/çiçek) görsel akraba → çapraz-satış hissi. **Yeni asset** gerektirir (§10).

### 5.4 Coin Paketleri — IAP (§8)

Gerçek para; katalog dışı (Play Billing). Ayrı bölümde detay → **§8**.

### 5.5 Fiyat rampası (REV-61 §5.1 / REV-62 §6.3 ile birebir)

> ⚠️ Kodda mağaza fiyat emsali **YOK** (boş katalog). Aşağısı **göreli oran**; mutlak coin değeri,
> maç-başı kazanım oranı netleşince **tek katsayıyla** ölçeklenir. Önemli olan sınıflar arası oran.

| Sınıf | Öneri (coin) | Bu task'ta |
|---|---|---|
| Standart | ~500 | Carved Walnut, Floral Vine · Mercan/Altın-mermer taş |
| Nadir | ~1.500 | Marble & Gold, Neon Glow · Mermer tahta · Gül-altın taş |
| Epik | ~3.500 | Champion Laurel · Çiçek tahta |

---

## 6. Ürün kartı anatomisi + durumlar

### 6.1 Kart anatomisi (tek şablon, tüm kategoriler)

```
ProductCard  (radius 20, card gradyan #F5EAD4→#EBDBBE, shadow 0,8,20)
 ├─ Önizleme (üst, ~1:1)          → frame PNG / board thumbnail / taş render / coin yığını
 │    └─ Durum rozeti (sağ üst köşe overlay)  → §6.2
 ├─ Ad (Marcellus, ink #20302E, 1–2 satır)
 └─ Alt satır (fiyat / aksiyon)   → §6.2 duruma göre
      └─ CoinView (∅16–18) + tutar   /   ₺ rozeti   /   "Kademe N"   /   ✓ Kuşanıldı
```

Grid: `Wrap(spacing 12, runSpacing 12)` — telefonda 2 sütun, geniş ekranda 3. Kart genişliği tile
mantığıyla esnek (board_theme_grid deseni ölçeklenmiş).

### 6.2 Dört durum + yetersiz-bakiye alt-durumu

| Durum | Görsel | Alt satır | Etkileşim |
|---|---|---|---|
| **Satın alınabilir** | Normal, canlı | `CoinView + tutar` (gold vurgulu) | Dokun → onay diyaloğu (§7) |
| **Satın alındı (sahip)** | Normal + köşe "✓ Sahip" rozeti | **"Kuşan"** butonu (turkuaz outline) | Dokun → kuşan (anında, §7.4) |
| **Kuşanıldı** | **3 px turkuaz kenarlık** (board_theme_grid aktif deseni) + köşe ✓ | "Kuşanıldı" etiketi (turkuaz) | Pasif (zaten aktif) |
| **Kilitli (kademe şartı)** | `Opacity 0.28` + kilit ikonu overlay | Kademe rozeti + "Kademe N gerekir" | Dokun → bilgi ipucu (kademe nasıl açılır) |

**Yetersiz bakiye (alt-durum, "satın alınabilir" varyantı):** fiyat turuncu (`#F4552C`) tint; dokunulunca
onay yerine **"Yetersiz bakiye"** + coin paketlerine yönlendiren kısa diyalog (§7.2). Kartın kendisi
tıklanabilir kalır (kullanıcı fiyatı görsün).

> **Rozet dili tutarlı:** kilit + coin + ✓ rozetleri tüm kategorilerde aynı (§10 asset seti). Coin
> paketleri (§8) bu durumlardan muaf — onlar hep "satın alınabilir (₺)" + tekrar alınabilir (tüketilir).

### 6.3 Kategoriye göre önizleme

- **Çerçeveler:** REV-61 512×512 PNG, kartta `CircleAvatar` mock avatar üstüne bindirilmiş (§6.1
  REV-61 overlay oranı 512/389). Önizleme = markanın profil vitrini hissini verir.
- **Tahtalar:** REV-62 tahta thumbnail'i (mini board grid önizleme, board_theme_grid tile görseli).
- **Taş renkleri:** `CoinView` ile tek taş render'ı (CustomPaint palette önizleme, büyütülmüş).
- **Coin paketleri:** coin yığını illüstrasyonu, boyut paket büyüklüğüne göre ölçeklenir (§8).

---

## 7. Satın alma akışı (coin ile — `purchaseItem`)

### 7.1 Onay diyaloğu (mevcut `showDialog<bool>` + `AlertDialog` deseni)

Dokun → onay diyaloğu:

```
AlertDialog (parchment surface, radius 20)
 ├─ Ürün mini önizleme + ad (Marcellus)
 ├─ "Bu ürünü {tutar} coin karşılığında al?"  (Lora)
 │    + satır: mevcut bakiye → alım sonrası bakiye (küçük, ikincil)
 └─ actions:
     ├─ TextButton  "Vazgeç"     → pop(false)
     └─ FilledButton "Satın Al"  → pop(true)  (turkuaz dolgu + CoinView + tutar)
```

Onay → `purchaseItem({itemId})` çağrılır (loading spinner buton içinde).

### 7.2 Hata eşlemesi (`purchaseItem` kodları → kullanıcı mesajı)

| Kod | Anlam | UI |
|---|---|---|
| `failed-precondition` | Bakiye yetersiz | "Yetersiz bakiye" + **coin paketlerine** yönlendir (§8) |
| `already-exists` | Zaten sahip | "Bu ürüne zaten sahipsin" → kartı "Sahip"e çevir |
| `not-found` | Katalogda yok | "Ürün şu an alınamıyor" (sessiz log; katalog eksikliği) |
| `unauthenticated` | Oturum yok | Girişe yönlendir |
| ağ/timeout | Bağlantı | "Bağlantı hatası, tekrar dene" (§9.3) |

### 7.3 Başarı durumu / animasyonu

> Proje animasyon zevki: **rijit, ölçülü, abartısız** (proje hafızası). Kutlama minimal tutulur.

- Diyalog kapanır → kart **"Satın alındı (sahip)"** durumuna geçer (köşe ✓ rozeti belirir).
- **Coin bakiyesi chip'i aşağı sayar** (tick-down, ~400 ms) → alım sonrası değere iner (§4.2).
- Kart üstünde **tek seferlik hafif ✓ vurgusu** (turkuaz halka kısa parlar, sönümlenir) — konfeti/
  patlama YOK (marka ölçülü). İsteğe bağlı tek bir küçük coin ikonu "uçup" bakiyeye gider (opsiyonel).
- Kullanıcıya **"Kuşan"** çağrısı öne çıkar (yeni aldığını hemen giyebilsin).

### 7.4 Kuşanma (equip) — anında, coinsiz

- "Kuşan" dokunuşu **satın alma değil**; yalnız aktif seçimi değiştirir (frame/board/coinSkin için
  ayrı equipped alanı — §11). Anında: eski kuşanılan kartın turkuaz kenarlığı söner, yenisininki yanar.
- Kategori başına tek kuşanılan (bir çerçeve, bir tahta, bir taş). Profil/oyun anında yansır.

---

## 8. Coin paketleri — IAP (gerçek para, Play Billing)

> **2026-07-14 kararı:** coin paketleri kategorisi **gerçek para** (Play Billing) ile satılır;
> diğer her şey coin ile. Paket adı `com.mustafakarakas.reversi` (Billing buna bağlı, değişmez).
> IAP item'ları **`catalog.ts` dışıdır** (`purchaseItem` bunları işlemez) — Play Console SKU'ları.

### 8.1 Görsel ayrım (kritik)

Coin paketleri coin-fiyatlı ürünlerden **net ayrılmalı**:

- Fiyat rozeti **coin ikonu değil, `₺` / gerçek-para etiketi** (yerelleştirilmiş fiyat Play'den gelir).
- Kart aksanı **gold `#B8860B`** ağırlıklı (coin ürünlerinde turkuaz aksan) → "burası gerçek para".
- Sekme başlığında küçük ayraç/ikon; başlıkta "Bakiyeni yükle" alt-metni.

### 8.2 Paket merdiveni (öneri — mutlak ₺ Play Console'da ayarlanır)

| Paket | Coin (öneri) | Rozet | Not |
|---|---|---|---|
| Küçük Kese | ~500 | — | Giriş |
| Torba | ~1.200 | — | +%20 bonus hissi |
| Sandık | ~3.000 | **"Popüler"** | En çok alınan konumu |
| Hazine | ~6.500 | **"En Avantajlı"** | coin/₺ en iyi |
| Servet | ~15.000 | — | Balina/tepe |

> Coin miktarları REV-61/62 fiyat rampasıyla uyumlu ölçeklenmeli: en küçük paket ~1 Standart ürün,
> orta paketler bir Nadir/Epik'e denk gelmeli ki mağaza ekonomisi anlamlı olsun. **Mutlak ₺ + coin
> miktarı** coin ekonomisi + fiyatlandırma kararıyla netleşir (§12.5). Yığın illüstrasyonu boyutla büyür.

### 8.3 IAP akışı

- Dokun → **native Play satın alma sayfası** (uygulama içi onay diyaloğu değil — platform akışı).
- Başarılı → backend doğrulama (REV-69 + billing) → coin bakiyesi yükselir (chip yukarı sayar).
- İptal/hata → sessiz geri dönüş; başarısız ödemede coin eklenmez. (Tüketilebilir ürün — tekrar alınır.)

---

## 9. Boş / yükleniyor / hata durumları

### 9.1 Yükleniyor

- Kategori grid'i yüklenirken **iskelet kartlar** (parchment placeholder, hafif shimmer) — kart
  boyutunda gri-bej bloklar. Coin bakiyesi chip'i ayrı yüklenir (bakiye gelene dek "…").

### 9.2 Boş vitrin

- Bir kategoride ürün yoksa (ör. katalog henüz dolmadıysa): merkezde sakin illüstrasyon (ahşap raf)
  + "Vitrin yakında dolacak" (Lora, ink-soft). Coin paketleri kategorisi boş kalmaz (IAP her zaman var).

### 9.3 Hata

- Katalog/bakiye çekilemezse: "Mağaza yüklenemedi" + **"Tekrar dene"** butonu (turkuaz). Ağ hatası
  ile sunucu hatası aynı ekranda, tek retry. Satın alma sırası hatası §7.2'de (diyalog içi).
- Offline: bakiye son bilinen değerle soluk gösterilir; satın alma butonları pasif + "Çevrimdışı" ipucu.

---

## 10. Rozet / kart asset üretim yönergesi (Gemini)

Ürün önizlemeleri **yeni asset gerektirmez** (REV-61 çerçeve PNG'leri + REV-62 tahta thumbnail'leri
+ taş render'ları yeniden kullanılır). Üretilecek olan **durum rozetleri + kategori/UI süsleri**:

**Rozet seti (küçük, şeffaf PNG @1x/@2x/@3x veya vektör — tek stil dili):**
- [ ] **Coin rozeti** — madeni para ikonu (mevcut `CoinView` dili ile tutarlı; statik ikon versiyonu)
- [ ] **₺ / gerçek-para rozeti** — coin paketlerini ayıran etiket (gold zemin)
- [ ] **Kilit rozeti** — kilitli (kademe şartı) çerçeveler için (ince, ahşap-gri)
- [ ] **✓ Sahip / Kuşanıldı rozeti** — turkuaz onay tiki
- [ ] **Kademe rozeti** — kilitli çerçevede "Kademe N" (REV-60 renk rampası tonu)
- [ ] **"Popüler" / "En Avantajlı" şerit** — coin paketleri (gold şerit)
- [ ] **Kategori sekme ikonları (4)** — çerçeve / tahta / taş / coin (opsiyonel; metin de yeter)

**Coin yığını illüstrasyonu (5 boyut, §8.2):** aynı ahşap/altın dilinde, paket büyüklüğüyle ölçeklenen
madeni para yığını; en büyükte sandık/hazine motifi.

**Ortak stil:** ahşap-lonca + gold `#B8860B` + turkuaz `#13A99C` aksan; parchment üstünde net kenar,
1 px koyu dış hat (krem/parchment'te erimesin — REV-61 §3.4 kuralı). Marcellus/Lora tipografiyle uyumlu.

**Kontrol listesi (her rozet):**
- [ ] Şeffaf zemin (RGBA); parchment + koyu kart üstünde ayrı ayrı test
- [ ] Küçük ölçekte (kart köşesi ~20–24 px) okunur
- [ ] Turkuaz = kuşanıldı/aktif; gold = premium/gerçek-para; gri = kilitli → renk kodu tutarlı

---

## 11. Kod tarafı notları (client task REV-69 için)

Bu doküman koda dokunmaz; aşağısı REV-69'un uygulayacağı değişikliklerin **haritası** + **katalog şeması
boşlukları**:

- **Yeni feature-slice:** `lib/features/shop/` (ekran + kart + kategori + diyalog widget'ları).
  Ekran iskeleti Profile/Settings deseninden (§3.3): clipper header + SafeArea + grid.
- **`catalog.ts` doldurulur** + **şema genişletilir** (§3.1 boşlukları):
  1. **Kademe-şartı (tier-lock):** kademe çerçeveleri satılmaz ama mağazada "kilitli" görünür →
     `CatalogItem`'a `unlockTier?: number` (fiyatsız, kademe ile açılır) alanı ya da ayrı bir
     "otomatik kazanım" listesi. `purchaseItem` bunları **reddetmeli** (coin ile alınamaz).
  2. **IAP/coin paketi:** `catalog.ts` **dışı** — Play Billing SKU'ları + backend doğrulama ayrı
     (REV-69 + billing). `purchaseItem` IAP işlemez.
  3. **Kuşanılan (equipped) durum:** `ownedItems` yalnız sahiplik → equip için ayrı alan gerekir
     (`equippedFrame` / `equippedBoard` / `equippedCoinSkin`). "Kuşan" = coinsiz seçim mutasyonu (§7.4).
  4. **Ücretsiz item'lar:** wood/turkuaz/gece tahta + klasik/turkuaz taş katalogsuz (varsayılan
     sahip) — mağazada gösterilir ama `purchaseItem` çağrısı yapılmaz.
- **itemId isim kalıbı (öneri, §5):** `frame_*`, `board_*`, `coinSkin_*` (kategori öneki + slug).
  Kademe çerçeveleri: `frame_tier_{1..6}_{slug}` (REV-61 §3.3 dosya adlarıyla hizalı).
- **Bakiye/envanter kaynağı:** REV-66 cüzdanı (`coins`, `ownedItems`); mağaza bunları canlı okur.
- **pubspec:** rozet/coin-yığını assetleri eklenince kaydedilir (REV-61 `assets/frames/` kalıbıyla).

---

## 12. Ekip kararı için açık noktalar

1. **Kategori navigasyonu:** 4 sekme (önerilen) mi, tek scroll + bölüm başlıkları mı? (§4.3)
2. **Ücretsiz item'lar vitrinde:** ücretsiz tahtalar/taşlar mağazada "Sahip/Kuşan" ile gösterilsin
   (önerilen) mi, yalnız ayarlar/profilden mi seçilsin? (§5.2, §5.3)
3. **Kademe çerçeveleri mağazada:** "kilitli (kademe şartı)" olarak mağaza vitrininde görünsün
   (önerilen — durum tanımı bunu gerektiriyor) mi, yalnız profil çerçeve seçicisinde mi kalsın? (§5.1, §6.2)
4. **Taş renkleri ↔ REV-62 §4.4 uzlaştırması:** taş renkleri mağaza kozmetiği olarak kalsın
   (önerilen — catalog `coinSkin` bunu destekliyor) mı, REV-62'deki gibi tamamen kaldırılıp her tahta
   kendi diskini mi belirlesin? Bu, REV-62 kararına dokunur — birlikte onaylanmalı. (§5.3)
5. **Coin paketi miktar/₺:** §8.2 coin merdiveni + mutlak ₺ — hangi task coin ekonomisi + IAP
   fiyatlandırmasını netleştirecek? (REV-66 kapsamı mı genişleyecek, ayrı bir fiyat task'ı mı?)
6. **Fiyat mutlak değerleri:** §5.5 oranları onay; mutlak coin, kazanım oranı netleşince tek
   katsayıyla ölçeklenir (REV-61/62 ile aynı disiplin).

**Karar sonrası:** onaylanan cevaplar `PROGRESS.md`'ye işlenir; **REV-69** ekranı + katalog verisini
kodlar, **REV-64** bu ekrana yönlendirme noktalarını tasarlar.
