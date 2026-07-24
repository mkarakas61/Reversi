# REV-61 · Seviye Çerçeveleri Görsel Tasarımı

> **Durum:** Ekip kararı bekliyor (öneri + asset üretim yönergesi). Konseptler onaylanınca
> görseller Gemini'de üretilir, kod tarafı (asset entegrasyonu + çerçeve seçici + kademe
> otomatik kazanımı) ayrı bir **client** task'ında uygulanır. Bu doküman repo koduna dokunmaz.
>
> **Sahibi:** Enes (görsel tasarım) · **Task:** REV-61 · **Bağımlı:** REV-60 (kademe kimlikleri) · **Takım:** Reversi_Game

---

## 1. Özet karar

- **İki çerçeve ailesi:** (A) **Kademe çerçeveleri** — seviye kademesine göre otomatik kazanılan,
  kademe başına 1 adet (6 çerçeve, REV-60 kademeleriyle birebir). (B) **Satılık özel çerçeveler** —
  mağazada coin ile alınan, ilk set **5 adet**, üç fiyat sınıfında.
- **Kimlik dayanağı:** Kademe çerçeveleri REV-60'taki 6 kademelik renk/rozet rampasını
  (§4, REV-60) birebir kullanır → ünvan, renk ve rozet dili tutarlı. Satılık çerçeveler bundan
  bilinçle **ayrışır**: mevcut board temalarına (ahşap / çiçek / mermer / turkuaz) yaslanır ki
  "kazanılan prestij" ile "satın alınan stil" görsel olarak karışmasın.
- **Tek boyut standardı:** Tüm çerçeveler **512×512 px şeffaf PNG**, ortada sabit dairesel açıklık
  (§3). Böylece her çerçeve aynı avatar bileşenine takılıp çıkarılabilir; kod tarafı tek bir
  overlay mimarisiyle hepsini render eder.
- **Ahşap tema uyumu:** Onaylı ahşap (ceviz + akçaağaç / krem) yönüyle uyumlu; light (krem) ve
  dark (gece/antrasit) board'larda okunurluk her çerçeve için garanti (§3.4).

---

## 2. Kapsam ve teslim

REV-61 tanımından:

1. **Kademe çerçeveleri:** seviye kademesine göre otomatik kazanılan çerçeveler — REV-60'taki
   kademelerle uyumlu, kademe başına 1 çerçeve. → **§4 (6 adet)**
2. **Satılık özel çerçeveler:** mağazada coin ile satılacak özel tasarımlar — ilk set 3-5 adet.
   → **§5 (5 adet)**

**Teslim:** her çerçeve için asset (şeffaf PNG, dairesel avatar üzerine bindirilecek format) +
hangi kademeye ya da fiyat sınıfına ait olduğu listesi. Assetler `assets/` altına, tek boyut
standardında girecek. → asset üretimi **§7 (Gemini yönergesi)**, yerleştirme **§6**.

> **Bu dokümanın ürettiği:** tasarım spec'i (konsept + renk + motif + kazanım/fiyat listesi),
> asset format standardı ve Design'a yerleştirme yönergesi. **Somut PNG assetleri** onay sonrası
> Gemini'de üretilir (mevcut ahşap doku iş akışıyla aynı — bkz. proje hafızası "ahşap tema görsel
> yönü").

---

## 3. Asset format standardı (Gemini üretimi + kod için ortak sözleşme)

Çerçevenin gerçek yerleştirme bağlamı **profil ekranı avatarı**: `CircleAvatar(radius: 48)` →
çap **96 px @1x** (`lib/features/profile/profile_screen.dart`). Ayrıca leaderboard'da çap 32 px
(`radius: 16`) ve menü chip'inde çap 22 px (`radius: 11`) küçük gösterimler var (§6.3).

### 3.1 Canvas ve açıklık (değişmez sözleşme)

| Parametre | Değer | Gerekçe |
|---|---|---|
| Canvas | **512 × 512 px**, kare, şeffaf (RGBA) PNG | 96 px avatarın ~5.3×'ine kadar ölçeklenmeden net; retina/tablet güvenli |
| İç şeffaf açıklık (avatarın göründüğü daire) | Merkezde, çap = **canvas'ın %76'sı ≈ 389 px** | Avatar bu dairenin içinden görünür; oran tüm çerçevelerde SABİT |
| Çerçeve bandı | Açıklık kenarı (∅389) ile ~∅460 arası (~35 px band) | Ana halka; renk/motif buraya işlenir |
| Taşma alanı | ∅460 ile 512 kenar arası (~26 px) | Taç, defne, ışıltı gibi süsler dışa taşabilir; kalıcı görünür kalır |

**Kritik kural:** İç açıklığın **çapı ve merkezi tüm çerçevelerde birebir aynı** olmalı — aksi
halde çerçeve değiştirildiğinde avatar kayar. Süsleme çeşitliliği yalnız **band + taşma alanında**
yaşanır.

### 3.2 Güvenli alan

Metin/rozet çakışmasını önlemek için çerçevenin **alt-orta 20°'lik yayı** görsel olarak sakin
tutulmalı (profil kartında avatarın altına seviye rozeti/ünvan gelebilir). Ağır süsler üst ve
yan yaylara yerleştirilir.

### 3.3 Dosya adı ve klasör

```
assets/frames/
  tier/                      # kademe çerçeveleri (otomatik)
    frame-tier-1-caylak.png
    frame-tier-2-acemi.png
    frame-tier-3-kalfa.png
    frame-tier-4-usta.png
    frame-tier-5-buyukusta.png
    frame-tier-6-efsane.png
  shop/                      # satılık çerçeveler (coin)
    frame-shop-carved-walnut.png
    frame-shop-floral-vine.png
    frame-shop-marble-gold.png
    frame-shop-neon-glow.png
    frame-shop-champion-laurel.png
```

> **@2x/@3x gerekmez:** 512 px kaynak, en büyük gösterim olan 96 px avatarın 5×'inden fazlası →
> tek dosya tüm yoğunluklara yeter. (İstenirse ileride 256 px "small" varyantı üretilebilir; şart değil.)

### 3.4 Okunurluk (light + dark board)

REV-60 §4 kuralı burada da geçerli: her çerçevenin **light zeminde (ahşap/original krem)** ince
koyu kontur, **dark board'da (gece/antrasit)** açık tint tarafı öne çıkar. Metalik/ışıltı geçişi
yalnız en üst prestij katmanlarında (Efsane kademe çerçevesi + Neon/Champion satılık çerçeveler).
PNG bu iki zeminde de test edilerek üretilir; gerekiyorsa çerçevenin dış kenarına 1 px yarı-saydam
koyu hat eklenir (krem üstünde erimesin).

---

## 4. Kademe çerçeveleri (otomatik kazanım — 6 adet)

REV-60'ın **Set A "Zanaat/Lonca"** ünvanları ve **6 kademelik renk rampası** birebir taban.
Her çerçeve, ilgili kademeye ulaşıldığında **otomatik** kazanılır (satın alınmaz). Renkler REV-60
§4 rampasından; motifler o rampadaki rozet konseptlerinin **halka diline** uyarlanmışıdır.

| # | Kademe (Seviye) | Ünvan (TR / EN) | Ana renk | Light kontur / Dark tint | Halka motifi | Kazanım |
|---|---|---|---|---|---|---|
| 1 | Kademe 1 (1–4) | Çaylak / Rookie | Bronz-bakır `#A9744F` | `#6E4626` / `#C79A78` | İnce, sade ahşap-bakır halka; alt-orta dışında düz. Küçük filizlenen tohum/palamut aksanı üstte tek nokta. | Seviye 1 (başlangıç — herkeste açık) |
| 2 | Kademe 2 (5–9) | Acemi / Novice | Çelik-gümüş `#8E9AAB` | `#4C5566` / `#C2CBD6` | Nötr gümüş halka; yanlarda tek şevron/çentik (çırak damgası). Hâlâ sade. | Seviye 5 |
| 3 | Kademe 3 (10–19) | Kalfa / Journeyman | Sıcak altın-pirinç `#C89331` | `#7A5514` / `#E7C271` | Altın-pirinç halka; üstte çapraz zanaat aletleri / küçük lonca mührü kabartması. | Seviye 10 |
| 4 | Kademe 4 (20–34) | Usta / Master | Marka turkuaz-zümrüt `#0E8C7E` | `#064E45` / `#3FC7B6` | Turkuaz-zümrüt halka; yan yaylarda defne yaprağı örgüsü (usta mührü). Markaya bağlanır. | Seviye 20 |
| 5 | Kademe 5 (35–49) | Büyükusta / Grandmaster | Asil mor `#7A4FB5` | `#452A6E` / `#B091E0` | Zengin mor halka; üst-orta taçlı yıldız + köşe arma süsleri. Yüksek prestij. | Seviye 35 |
| 6 | Kademe 6 (50+) | Efsane / Legend | Efsanevi altın-kızıl `#F0A81E` + kızıl gloss `#E0452B` | `#8A4A08` / `#FFD37A` | Alev/anka kanadı + taç; **metalik ışıltı geçişi** (tek ışıltılı kademe çerçevesi). En zengin. | Seviye 50 |

**Tasarım ilkeleri:**

- **Artan görsel yoğunluk = artan prestij.** Kademe 1–2 sade ve ince (yeni oyuncuyu boğmaz),
  3–4 orta detay, 5–6 zengin süs + ışıltı. Silüet uzaktan bile "hangi kademe" okunur.
- **Ortak DNA:** Hepsi aynı iç açıklık + aynı band kalınlığı + ahşap el-işi doku hissi → bir
  aileden geldikleri belli, ama renk + motif ayrışır.
- **Efsane ayrıcalığı:** Işıltı/animasyon (opsiyonel hafif parıltı) yalnız Kademe 6'da → nadirliği
  (REV-60: ~1.440+ maç) görsel ödülle taçlandırır.

---

## 5. Satılık özel çerçeveler (mağaza — coin, 5 adet)

Kademe çerçevelerinden bilinçle **ayrışır**: bunlar prestij değil **stil/kişiselleştirme**. Her biri
mevcut bir board temasına yaslanır → oyuncunun zaten sevdiği estetiği profiline taşır. Tema
karşılıkları koddaki `BoardTheme { wood, turkuaz, gece, antrasit, petrol, mermer, cicek }` ile hizalı.

| # | Ad (TR / EN) | Estetik / bağlı tema | Renk paleti | Fiyat sınıfı |
|---|---|---|---|---|
| 1 | Oyma Ceviz / Carved Walnut | Ahşap imza — `wood` teması; oyulmuş ceviz kabartma halka, akçaağaç fitil | Ceviz `#56391F`→`#3E2A1E`, altın hat `#B8860B` | **Standart** |
| 2 | Bahar Sarmaşığı / Floral Vine | `cicek` teması; iç içe geçmiş sarmaşık + çiçek örgüsü | Yeşil örgü + krem çiçek, sıcak altın aksan | **Standart** |
| 3 | Mermer & Altın / Marble & Gold | `mermer` teması; altın filetolu beyaz mermer halka, ince damar dokusu | Mermer beyaz `#EEF0F4`, altın file `#C89331` | **Nadir** |
| 4 | Neon Işıltı / Neon Glow | Original/marka; parlak turkuaz→turuncu gradyan, ışıltılı ince halka | `#13A99C`→`#F4552C` gloss | **Nadir** |
| 5 | Şampiyon Defnesi / Champion Laurel | Turnuva/başarı; altın defne çelengi, üstte küçük taç | Altın `#F0A81E`, koyu kontur `#8A4A08` | **Epik** |

### 5.1 Fiyat sınıfları (ÖNERİ — coin ekonomisi netleşince ayarlanır)

> ⚠️ **Codebase'de henüz mağaza item modeli / fiyat emsali YOK.** REV-66 coin ödüllerini ve
> `purchaseItem` transaction'ını açtı, ama satılık item fiyat kalıbı tanımlı değil. Aşağıdaki
> rakamlar **göreli oran önerisi**; kazanım oranları (maç başı coin) netleşince mutlak değerler
> tek katsayıyla ölçeklenmelidir. Önemli olan **sınıflar arası oran**, mutlak sayı değil.

| Fiyat sınıfı | Öneri fiyat (coin) | Konumlama |
|---|---|---|
| Standart | ~500 | Erişilebilir; birkaç günlük aktif oyunla alınır (1, 2) |
| Nadir | ~1.500 | Belirgin bir hedef; ~2 haftalık ödül birikimi (3, 4) |
| Epik | ~3.500 | Prestijli satın alım; uzun vadeli hedef (5) |

**Neden 3 sınıf:** kademe çerçeveleri zaten dikey prestij ekseni sağlıyor; mağaza yatay stil
çeşitliliği + net bir "biriktir & al" ekonomisi ekler. 5 item / 3 sınıf ilk sette dengeli bir
vitrin (2 giriş + 2 orta + 1 hedef).

---

## 6. Design'a yerleştirme yönergesi (kod tarafı için — ayrı client task'ı uygular)

### 6.1 Overlay mimarisi

Avatar bileşenleri bugün `CircleAvatar` (dairesel). Çerçeve, avatarın **üzerine** `Stack` ile
bindirilir; kod bugünkü avatar widget'larını değiştirmeden bir sarmalayıcı ekler:

```
Stack(alignment: center):
  ├─ CircleAvatar(radius: R)                       // mevcut avatar — dokunulmaz
  └─ Image.asset(frameAsset,                        // seçili çerçeve overlay
        width: 2*R * (512/389),  height: aynı)      // açıklık avatarla hizalanır
```

Ölçek katsayısı **512 / 389 ≈ 1.316** (canvas / iç açıklık, §3.1). Yani frame görseli, avatar
çapının ~1.316 katı boyutta ve ortalanmış çizilir → çerçevenin şeffaf açıklığı tam avatarın
üstüne oturur, süsler dışa taşar. Bu oran sabit olduğu için **tek bir `AvatarWithFrame` widget'ı**
hem profil (R=48), hem leaderboard (R=16), hem chip (R=11) için çalışır.

### 6.2 Seçim / kazanım modeli (client task'ına not)

- **Kademe çerçevesi:** seçili değil — oyuncunun mevcut kademesi otomatik belirler (REV-67 "Seviye
  ünvanları modeli" kademe eşiğini verecek; çerçeve o kademenin asset'ini gösterir). Oyuncu isterse
  daha düşük bir kademe çerçevesini de seçebilir (kazandıklarının hepsi açık kalır) — ürün kararı.
- **Satılık çerçeve:** `purchaseItem` (REV-66) ile alınır, envantere eklenir, seçiciden seçilir.
- **Seçici UI:** mevcut **`BoardThemeGrid`** deseni birebir emsal (`lib/features/settings/widgets/
  board_theme_grid.dart`): Wrap grid, tile ~88×88, aktif tile'da 3 px turkuaz (`GameColors.accent`)
  kenarlık. Çerçeve seçici de aynı desenle yapılır; kilitli (kazanılmamış/satın alınmamış) çerçeveler
  gri + küçük kilit/coin rozetiyle gösterilir.

### 6.3 Küçük gösterim davranışı

- **Profil ekranı (∅96):** tam çerçeve, tüm detay + Efsane ışıltısı görünür. Ana vitrin.
- **Leaderboard satırı (∅32):** çerçeve gösterilir ama detay küçük — 512 px asset burada da net
  ölçeklenir; ışıltı/animasyon **kapalı** (performans + kalabalık liste).
- **Menü chip (∅22):** çok küçük; öneri → çerçeve yerine yalnız **kademe renk halkası** (2 px, REV-60
  rampasından) göster, süsleri atla. Client task'ı bu eşiği belirler.

### 6.4 pubspec kaydı (client task'ında)

Assetler üretilip eklendiğinde `pubspec.yaml`'a `assets/frames/tier/` ve `assets/frames/shop/`
satırları eklenir (mevcut `assets/wood/` kalıbıyla aynı). **Bu doküman koda/pubspec'e dokunmaz.**

---

## 7. Gemini üretim yönergesi (asset üretimi)

Onay sonrası her çerçeve tek tek Gemini'de üretilir. Ortak prompt iskeleti:

> *"Circular avatar frame, PNG with fully transparent center and transparent background,
> 512×512, centered transparent circular opening of diameter ~389px (76% of canvas). Ornament
> only in the ring band and outer bleed. Style: [MOTİF §4/§5], color palette [HEX'ler]. Hand-crafted
> wooden-guild aesthetic consistent with a walnut+maple Reversi board game. Clean edges, readable on
> both cream-light and dark backgrounds, subtle 1px dark outer stroke."*

Üretim kontrol listesi (her asset için):
- [ ] İç açıklık çapı ve merkezi §3.1 ile birebir (çerçeveler arası kayma yok — üst üste bindirip doğrula)
- [ ] Merkez ve dış zemin **tam şeffaf** (RGBA, dolu beyaz değil)
- [ ] Alt-orta 20° yay sakin (§3.2)
- [ ] Krem + dark board üstünde ayrı ayrı test (§3.4)
- [ ] Işıltı/metalik yalnız Efsane / Neon / Champion'da
- [ ] Dosya adı §3.3 kalıbında, `assets/frames/{tier|shop}/` altına

---

## 8. Ekip kararı için açık noktalar

1. **Satılık set adedi:** 5 (önerilen) mi, 3-4'e mi indirilsin? İlk vitrin dengesine göre.
2. **Fiyat mutlak değerleri:** §5.1 oranları onaylanıyor mu? Mutlak coin rakamı, coin kazanım
   oranı (henüz tanımsız) netleşince belirlenmeli — hangi task o ekonomiyi tanımlayacak?
3. **Kademe çerçevesi seçilebilirliği:** oyuncu daha düşük kademe çerçevesini seçebilsin mi (§6.2),
   yoksa hep mevcut kademe mi zorunlu?
4. **Menü chip'te (∅22) davranış:** tam çerçeve mi, yalnız renk halkası mı (§6.3 önerisi)?
5. **Asset üretimi:** konseptler onaylanınca 11 çerçeve (6 kademe + 5 satılık) Gemini'de üretilip
   Design'da yerleştirilir; kod entegrasyonu ayrı client task'ında (REV-67 kademe modeline bağlı).
