# REV-60 · Seviye Ünvanları ve Kademe Kimliği Önerisi

> **Durum:** Ekip kararı bekliyor (kademe eşikleri + TR/EN ünvan seti + renk/rozet kimliği). Bu
> doküman repo koduna **dokunmaz** — yalnız öneri + gerekçe üretir. Karar onaylanınca kod tarafı
> ("Seviye ünvanları modeli") ayrı bir **client** task'ında (**REV-67**) uygulanır.
>
> **Sahibi:** Enes (görsel tasarım) · **Task:** REV-60 · **Bloklar:** REV-67 (seviye ünvanları
> modeli — client), REV-61 (seviye çerçeveleri) · **İlgili:** REV-62, REV-63, REV-65, REV-68 ·
> **Takım:** Reversi_Game

> **📌 Kanonik kaynak notu:** Bu doküman, kademe **renk + ünvan rampasının kanonik kaynağıdır.**
> REV-61 §4 (seviye çerçeveleri) bu rampayı zaman sırası gereği **önden referansladı** ("REV-60'ın
> Set A Zanaat/Lonca ünvanları + 6 kademelik renk rampası birebir taban"); burada o rampa tek yerde,
> tam gerekçesiyle tanımlanır. **REV-61 §4 ile bu doküman §4–§6 birebir tutarlıdır** (aynı 6 renk,
> aynı ünvanlar, aynı eşikler) — çakışırsa bu doküman kanonik.

---

## 1. Özet karar (öneri)

- **6 kademe, seviye eğrisine dengeli eşiklerle.** Mevcut XP eğrisi `xpForLevel(L) = 50·L·(L−1)`
  (§3) üstüne 6 kademe: **1–4 · 5–9 · 10–19 · 20–34 · 35–49 · 50+**. Tartışma tabanı (Linear)
  korunur; XP/maç karşılıklarıyla dengelenir. → **§4**
- **Ünvan seti: "Zanaat/Lonca" (Set A) — önerilen.** Çaylak · Acemi · Kalfa · Usta · Büyükusta ·
  Efsane (TR) / Rookie · Novice · Journeyman · Master · Grandmaster · Legend (EN). Onaylı ahşap
  marka yönüyle (ceviz+akçaağaç lonca dili) birebir hizalı. İki alternatif set §5.3'te. → **§5**
- **Kademe başına ayrı renk + rozet kimliği.** Bronz-bakır → çelik-gümüş → altın-pirinç →
  turkuaz-zümrüt (marka) → asil mor → efsanevi altın-kızıl. Artan görsel yoğunluk = artan prestij;
  ışıltı yalnız en üstte (Efsane). → **§6**
- **Renk rampası tüm profil/çerçeve/rozet sistemin tek dili.** REV-61 çerçeveleri (§4 kademe
  çerçeveleri), REV-63/64 mağaza durumları (kademe rozeti) ve REV-68 profil detayları hep bu 6
  renkten türer. → **§6.3**

**Dayanak:** (a) kod gerçeği (§3: `xpForLevel` eğrisi + `earnedXp` maç-başı aralığı), (b) onaylı
ahşap-lonca marka yönü, (c) REV-61 §4'ün önden yasladığı rampa ile tutarlı gerekçelendirildi.

---

## 2. Kapsam ve teslim

REV-60 tanımından:

1. **Kademe eşikleri:** seviye aralıkları + XP/maç karşılıkları → **§4**
2. **TR/EN ünvan adları:** kademe başına ünvan seti (öneri + alternatifler) → **§5**
3. **Kademe renk/rozet kimliği:** her kademe için renk + rozet konsepti → **§6**

**Teslim:** kademe eşikleri + TR/EN ünvanlar + renk/rozet kimliği önerisi (bu doküman) → ekip kararı
→ karar `PROGRESS.md`'ye işlenir → **REV-67** (client) ünvan/kademe modelini kodlar, **REV-61**
çerçeveleri bu rampaya oturtur. Bu doküman **koda/pubspec'e dokunmaz.**

> **Bu dokümanın ürettiği:** kademe eşik tablosu + TR/EN ünvan seti + 6 kademelik renk/rozet
> rampası + REV-67 için model notları. Somut rozet PNG'leri (gerekirse) onay sonrası Gemini'de
> üretilir; çerçeve karşılıkları REV-61 §4'te.

---

## 3. Mevcut kod gerçeği (karar buna dayanır)

Kaynak: `functions/src/xp_level.ts` (Dart karşılığı `lib/models/xp_level.dart` ile senkron).

### 3.1 Seviye eğrisi

| Fonksiyon | Değer |
|---|---|
| Eşik | `xpForLevel(L) = 50 · L · (L − 1)` — Seviye 1 için 0 XP |
| Ters | `level(xp) = floor((1 + √(1 + 8·xp/100)) / 2)` |
| Seviye-içi XP | `xpIntoLevel(xp) = xp − xpForLevel(level(xp))` |

**Kilometre taşları:** L5 = **1.000** · L10 = **4.500** · L20 = **19.000** · L35 = **59.500** ·
L50 = **122.500** XP. Eğri karesel → üst seviyeler belirgin uzar (prestij korunur).

### 3.2 Maç başı XP (`earnedXp`)

- **Taban:** galibiyet **100** · beraberlik **40** · mağlubiyet **15**.
- **Bonuslar (yalnız galibiyette çoğu):** skor farkı (≤30), taş çevirme (`flipped/8`), rakip-seviye
  farkı (−32…+64), galibiyet serisi (≤25).
- **Pratik aralık:** ~**15** (kötü mağlubiyet) → ~**150** (güçlü galibiyet). Karışık oyunda
  (~%50 galibiyet) **ortalama ~75–90 XP/maç**.

> **Maç tahminleri için varsayım:** aşağıdaki "≈ maç" sütunları **~85 XP/maç ortalama** ile
> hesaplanan **kaba** değerlerdir (kesin değil; oyuncunun galibiyet oranına göre değişir). Amaç
> kademelerin **his olarak** ne kadar sürdüğünü göstermek.

### 3.3 Coin ilişkisi (bağlam)

`earnedCoins` (galibiyet 10 / beraberlik 5 / mağlubiyet 2) REV-66'da açıldı — kademe **XP ile**
ilerler, coin ayrı yumuşak para. Kademe eşikleri coin ekonomisinden bağımsızdır (bu doküman yalnız
XP/kademe).

---

## 4. Kademe eşikleri (öneri)

Linear tartışma tabanı korunur; XP/maç karşılıklarıyla dengelendi. 6 kademe:

| # | Kademe | Seviye aralığı | Alt-eşik XP | ≈ Maç (kümülatif, ~85 XP/maç) | His / konumlama |
|---|---|---|---|---|---|
| 1 | **Çaylak** | 1–4 | 0 | 0 (başlangıç) | Herkeste açık; ilk temas. |
| 2 | **Acemi** | 5–9 | 1.000 | ~12 maç | İlk birkaç oturum; "devam ediyorum". |
| 3 | **Kalfa** | 10–19 | 4.500 | ~53 maç | Düzenli oyuncu; zanaat oturuyor. |
| 4 | **Usta** | 20–34 | 19.000 | ~224 maç | Ciddi bağlılık; markaya (turkuaz) bağlanır. |
| 5 | **Büyükusta** | 35–49 | 59.500 | ~700 maç | Uzun vadeli prestij; nadir. |
| 6 | **Efsane** | 50+ | 122.500 | ~1.440 maç | Tepe; çok nadir (REV-61 §4 ışıltı ödülü). |

### 4.1 Neden bu eşikler

- **Erken kademeler sık, üst kademeler seyrek.** İlk iki geçiş (Çaylak→Acemi→Kalfa) birkaç oturumda
  gelir → yeni oyuncu erken ödül hisseder. Usta+ karesel eğriyle belirgin uzar → üst ünvanlar
  gerçekten kazanılmış hisseder (enflasyon yok).
- **Eğriyle hizalı, uydurma değil.** Eşikler mevcut `xpForLevel` kilometre taşlarına (§3.1)
  oturtuldu; yeni bir seviye formülü **önerilmez** (kod değişmez, yalnız kademe **etiketlemesi**).
- **6 kademe = REV-61 çerçeve ailesiyle 1:1.** Her kademe tam bir çerçeveye (REV-61 §4) ve bir renk
  kimliğine (§6) karşılık gelir → sistem simetrik.

> **Ayar kolaylığı:** eşikler seviye **aralığı** olarak tanımlı (XP değil) → `level(xp)` zaten var,
> REV-67 yalnız "seviye → kademe" eşlemesi tutar. Eşikler ileride tek tabloyla ayarlanabilir.

---

## 5. Ünvan seti (TR / EN)

### 5.1 Önerilen — Set A "Zanaat / Lonca"

| # | Kademe | TR | EN | Kısa çağrışım |
|---|---|---|---|---|
| 1 | 1–4 | **Çaylak** | **Rookie** | Yeni başlayan, çırak adayı |
| 2 | 5–9 | **Acemi** | **Novice** | Çıraklığa adım |
| 3 | 10–19 | **Kalfa** | **Journeyman** | Zanaatı öğrenmiş, yol kat eden |
| 4 | 20–34 | **Usta** | **Master** | Zanaat sahibi; saygın |
| 5 | 35–49 | **Büyükusta** | **Grandmaster** | Loncanın kıdemlisi |
| 6 | 50+ | **Efsane** | **Legend** | Anlatılan isim; tepe |

### 5.2 Neden Set A (gerekçe)

- **Marka yönüyle birebir.** Onaylı görsel yön ceviz+akçaağaç **ahşap-lonca**; REV-61 çerçeveleri
  (el-işi ahşap-lonca dili) ve REV-63/64 mağaza (ahşap/parchment shell) hep bu eksende. "Zanaat"
  ünvanları (Çaylak→Kalfa→Usta) bu dünyanın **doğal dili** → ünvan + görsel + rozet tek anlatı.
- **TR'de güçlü, tanıdık, kısa.** Çaylak/Kalfa/Usta Türkçede yerleşik zanaat basamakları — çeviri
  kokmaz, tek kelime, profil kartına sığar. EN karşılıkları (Rookie…Legend) satranç/oyun
  kültüründe de tanıdık (Grandmaster/Legend prestij taşır).
- **Doğal artış eğrisi.** Ünvanların çağrışım gücü kademeyle artıyor (Çaylak nötr → Efsane tepe) →
  ilerleme hissi ünvanın kendisinde.

### 5.3 Alternatif setler (ekip için)

| # | Set B "Strateji/Rütbe" | Set C "Reversi/Taş" |
|---|---|---|
| 1 | Er / Private | Piyon / Pawn |
| 2 | Onbaşı / Corporal | Taş Ustası / Stone Hand |
| 3 | Çavuş / Sergeant | Köşe Avcısı / Corner Hunter |
| 4 | Subay / Officer | Stratejist / Strategist |
| 5 | Komutan / Commander | Taktik Ustası / Tactician |
| 6 | Efsane / Legend | Reversi Efsanesi / Reversi Legend |

- **Set B (Rütbe):** net dikey hiyerarşi ama **marka ahşap-lonca yönüyle zıt** (askeri ton). Önerilmez.
- **Set C (Oyun-içi):** Reversi'ye özgü, eğlenceli; ama TR'de bazıları zorlama ("Taş Ustası"). Orta.
- **Set A önerilir** — marka tutarlılığı en yüksek. Nihai isim tercihi ekip kararı (§8).

---

## 6. Kademe renk / rozet kimliği

Her kademe **ana renk** + **light zemin kontur** / **dark zemin tint** + **rozet motifi** taşır.
Renkler REV-61 §4 kademe çerçeveleriyle **birebir aynı** (kanonik kaynak — §0 not).

### 6.1 Renk rampası (kanonik)

| # | Kademe | Ana renk | Light kontur / Dark tint | Rozet motifi (konsept) |
|---|---|---|---|---|
| 1 | **Çaylak** | Bronz-bakır `#A9744F` | `#6E4626` / `#C79A78` | Sade halka; filizlenen tohum/palamut tek aksan. Yeni başlangıç. |
| 2 | **Acemi** | Çelik-gümüş `#8E9AAB` | `#4C5566` / `#C2CBD6` | Nötr rozet; tek şevron/çentik (çırak damgası). |
| 3 | **Kalfa** | Sıcak altın-pirinç `#C89331` | `#7A5514` / `#E7C271` | Çapraz zanaat aletleri / küçük lonca mührü kabartması. |
| 4 | **Usta** | Marka turkuaz-zümrüt `#0E8C7E` | `#064E45` / `#3FC7B6` | Defne yaprağı örgüsü (usta mührü); **markaya bağlanır**. |
| 5 | **Büyükusta** | Asil mor `#7A4FB5` | `#452A6E` / `#B091E0` | Taçlı yıldız + köşe arma süsleri. Yüksek prestij. |
| 6 | **Efsane** | Efsanevi altın-kızıl `#F0A81E` + kızıl gloss `#E0452B` | `#8A4A08` / `#FFD37A` | Alev/anka kanadı + taç; **metalik ışıltı** (tek ışıltılı kademe). |

### 6.2 Tasarım ilkeleri

- **Artan görsel yoğunluk = artan prestij.** Kademe 1–2 sade/ince (yeni oyuncuyu boğmaz), 3–4 orta
  detay, 5–6 zengin süs + ışıltı. Renk sıcaklığı da yükselir (bakır → altın → mor → altın-kızıl).
- **Turkuaz = marka dönüm noktası.** Kademe 4 (Usta) markanın turkuaz-zümrüt rengine oturur → "artık
  markanın parçasısın" eşiği. Alt kademeler nötr metaller (bakır/gümüş), üst kademeler asalet
  (mor/altın-kızıl).
- **Okunurluk (light + dark board).** Her renk light zeminde (krem/ahşap) ince koyu kontur, dark
  board'da (gece) açık tint ile okunur (REV-61 §3.4 kuralı). Işıltı/metalik yalnız Efsane'de.
- **Ortak DNA.** Aynı rozet iskeleti (halka + motif) tüm kademelerde; yalnız renk + motif ayrışır →
  bir aileden geldikleri belli (REV-61 çerçeve ailesiyle aynı ruh).

### 6.3 Rampanın kapsamı (tek renk dili)

Bu 6 renk, profil/kademe sisteminin **tek görsel dili**dir; şu noktalar buradan türer:

- **REV-61 kademe çerçeveleri (§4):** her çerçevenin ana rengi = ilgili kademe rengi (birebir).
- **REV-63/64 mağaza "kademe rozeti":** kilitli kademe çerçevesinde "Kademe N gerekir" rozeti bu
  renk tonunu taşır (REV-63 §10, REV-64 §6.3).
- **REV-68 profil detayları:** kademe rozeti / ünvan etiketi profilde bu renk + ünvan (§5) ile.
- **Leaderboard / menü chip (REV-61 §6.3):** küçük gösterimde yalnız **kademe renk halkası** (2 px)
  bu rampadan.

---

## 7. Uygulama notları (client task REV-67 için)

Bu doküman koda dokunmaz; aşağısı REV-67'nin uygulayacağı modelin **haritası**:

- **Seviye → kademe eşlemesi:** `level(xp)` zaten var (§3.1). REV-67 yalnız **seviye → kademe**
  (`tier(level)`) saf fonksiyonu + kademe tablosu (eşik, TR/EN ünvan, renk) tutar. Yeni XP formülü
  **yok** (kod eğrisi değişmez).
- **Kademe modeli (öneri):** `TierId { caylak, acemi, kalfa, usta, buyukusta, efsane }` + her biri
  için `{ minLevel, titleTr, titleEn, color, contourLight, tintDark }`. TR/EN `titleFor(locale)`.
- **Lokalizasyon:** ünvanlar `.arb` dosyalarına (TR/EN) — mevcut i18n kalıbıyla. Kısa tutulur
  (profil kartı + leaderboard sığar).
- **Renk token'ları:** §6.1 hex'leri tema token'ı olarak (`tier_colors.dart` öneri) → REV-61
  çerçeve + REV-68 profil ortak kullanır (tek kaynak, kopyalama yok).
- **Sınır davranışı:** kademe **seviye aralığıyla** belirlenir (§4); seviye atlarken kademe değişimi
  otomatik. Kademe atlama kutlaması (varsa) REV-68/REV-65 (ses) kapsamı — bu doküman yalnız kimlik.
- **REV-61 bağı:** REV-61 çerçeveleri bu rampaya **zaten yaslandı** (§0) → REV-67 kademe modelini
  kurunca REV-61 asset entegrasyonu aynı `TierId` üstünden çalışır.

---

## 8. Ekip kararı için açık noktalar

1. **Ünvan seti:** Set A "Zanaat/Lonca" (önerilen) mi, Set B (Rütbe) / Set C (Oyun-içi) mi? Karışık
   (ör. Set A ama Kademe 6 "Reversi Efsanesi") de olabilir. (§5)
2. **Kademe eşikleri:** §4 aralıkları (1–4 / 5–9 / 10–19 / 20–34 / 35–49 / 50+) onaylanıyor mu, üst
   eşik (Efsane 50) daha erken/geç mi olsun? (~1.440 maç tepe makul mü?)
3. **Kademe sayısı:** 6 (önerilen — REV-61 çerçeve ailesiyle 1:1) mi, 5'e mi insin / 7'ye mi çıksın?
   Değişirse REV-61 çerçeve sayısı da değişir (birlikte onaylanmalı).
4. **Renk rampası:** §6.1 6 renk onayı (REV-61 §4 ile birebir). Turkuaz'ın Kademe 4'e (Usta)
   konumu = "marka eşiği" kararı — kabul mü?
5. **Efsane ışıltısı:** yalnız Kademe 6'da metalik ışıltı (önerilen, REV-61 §4 ile hizalı) mı, üst
   iki kademe (Büyükusta+Efsane) mi ışıldasın?

**Karar sonrası:** onaylanan cevaplar `PROGRESS.md`'ye işlenir; **REV-67** kademe/ünvan modelini
kodlar, **REV-61** çerçeveleri bu rampaya oturtur (asset entegrasyonu REV-67 modeline bağlı).
