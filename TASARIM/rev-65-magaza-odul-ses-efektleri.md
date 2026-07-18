# REV-65 · Mağaza & Ödül Ses Efektleri

> **Durum:** Ekip kararı bekliyor + **ses üretimi bekliyor** (seslendirme — Enes). Bu doküman
> repo koduna **dokunmaz** — her olay için ses karakteri + üretim/format yönergesi + uygulanmaya-hazır
> `Sfx` entegrasyon bloğu üretir. Ses dosyaları kaydedilip mağaza/kademe akışları (REV-67/REV-69)
> koda geçince §7'deki blok birebir uygulanır.
>
> **Sahibi:** Enes (seslendirme) · **Task:** REV-65 · **Bağımlı/İlgili:** REV-60 (kademeler),
> REV-63 (mağaza + satın alma akışı), REV-66 (coin ekonomisi), REV-64 (yönlendirme) ·
> **Bloklar (tetik noktaları):** REV-67 (kademe modeli — kademe atlama anı), REV-69 (mağaza kodu —
> satın alma + kuşanma) · **Takım:** Reversi_Game

> **📌 Neden şimdi yalnız yönerge (koda dokunmuyor):** İki teslim kalemi de bu task'ta **fiilen
> uygulanamaz**: (1) ses dosyaları insan üretimi (seslendirme — Enes), AI kaydedemez; (2) tetik
> noktaları (satın alma, coin ödülü, kademe atlama, kuşanma) client kodunda **henüz yok** — mağaza
> ekranı/kademe modeli ayrı client task'larında (REV-69/REV-67) kurulacak (§3.4). Bu yüzden REV-65,
> REV-60→64 zinciriyle aynı desende bir **öneri + yönerge** üretir; §7 blok, ses + tetik noktası
> hazır olduğunda tek adımda uygulanır.

---

## 1. Özet karar

- **Ses dili = mevcut ahşap/tahta paletinin devamı.** Proje sesleri (`place`, `flip`, `button`,
  `win`…) sıcak, tahta-dokunuşlu, **ölçülü**; yeni sesler bu dünyada durur — arcade/kumarhane
  "ka-ching" YOK. Marka animasyon zevki (rijit, hacimli, yavaş tempo) + REV-63 §7.3 kutlama disiplini
  (konfeti/patlama yok) ses tarafına birebir taşınır. → **§4**
- **Dört olay + bir yeniden-kullanım.** (1) Satın alma başarılı, (2) Coin kazanma (maç sonu),
  (3) Kademe atlama (ünvan değişimi — REV-60 6 kademe), (4) Kuşanma (çerçeve/tahta/taş değiştirme).
  **Yetersiz bakiye** için yeni ses YOK → mevcut `invalid.wav` yeniden kullanılır. → **§5**
- **Yoğunluk = olayın ağırlığıyla orantılı.** En hafif kuşanma (tek tık-oturma) → en dolu kademe
  atlama (kısa, asil yükseliş). Coin kazanma sonuç sesinin (`win/lose/draw`) **altında** kalacak
  kadar kısık; onu bastırmaz. → **§5 + §6.3**
- **Format mevcutla birebir: `.wav`, kısa, önceden ses-dengeli.** `assets/audio/` dizin olarak
  pubspec'e kayıtlı → yeni dosya otomatik dahil (yeni pubspec satırı gerekmez). → **§6**
- **Sessiz/zil modu davranışı bedava gelir.** `playSfx` zaten `_soundEnabled` + Android sessiz modu
  (`_ringerSilent`) muhafızıyla korunuyor → yeni sesler otomatik uyumlu. → **§8**

**Dayanak:** (a) kod gerçeği (§3: `Sfx` enum + `_sfxAsset` map + `.wav` palet + `playSfx` muhafızı +
tetik noktalarının henüz yokluğu), (b) REV-63 §7.3 ölçülü kutlama + proje animasyon zevki,
(c) REV-60 kademe rampası (kademe atlama = ünvan değişimi anı), (d) REV-66 coin ekonomisi
(maç sonu ödülü).

---

## 2. Kapsam ve teslim

REV-65 tanımından dört ses + (bu task'ta) yönerge:

1. **Satın alma** (başarılı alım) → **§5.1**
2. **Coin kazanma** (maç sonu coin ödülü) → **§5.2**
3. **Kademe atlama** (seviye ünvanı değişimi — REV-60 kademeleri) → **§5.3**
4. **Kuşanma** (çerçeve/tema/taş değiştirme) → **§5.4**

**Nihai teslim (bu task + sonrası):**
- **Bu doküman:** olay → ses karakteri briefi + üretim/format yönergesi (§6) + uygulanmaya-hazır
  `Sfx` entegrasyon bloğu (§7) + tetik noktası haritası.
- **Ses dosyaları** (`assets/audio/*.wav`) → **seslendirme (Enes)** üretir; §6 yönergesine göre.
- **Kod entegrasyonu** → §7 bloğu; ses dosyaları + tetik noktaları (REV-67/REV-69) hazır olunca
  uygulanır. Bu doküman **koda/pubspec'e dokunmaz.**

> **Bu dokümanın ürettiği:** ses tasarım briefi + format standardı + `Sfx` enum/asset/tetik haritası.
> **Somut `.wav` dosyaları** seslendirmeyle üretilir; **kod bağlanması** mağaza (REV-69) + kademe
> modeli (REV-67) client task'larıyla aynı anda ya da hemen sonrasında yapılır.

---

## 3. Mevcut kod gerçeği (karar buna dayanır)

Kaynak: `lib/core/services/sound_service.dart` (read-only doğrulandı).

### 3.1 Ses altyapısı — hazır ve yeterli, yeni altyapı GEREKMEZ

- **Paket:** `audioplayers: ^6.1.0` (pubspec). Tek servis: `SoundService.instance` (singleton).
- **Efekt enum'u:** `enum Sfx { place, flip, invalid, button, tick, timeup, win, lose, draw }`.
- **Asset eşlemesi:** `_sfxAsset` map (`Sfx → 'audio/<ad>.wav'`). **Tüm sesler `.wav`.**
- **Çalma:** `playSfx(Sfx)` — önceden yüklenmiş round-robin oyuncu havuzundan (efekt başına 2 oyuncu)
  `seek(0) + resume`. Efekt başına `setVolume(1.0)` **tekdüze** → dosyalar önceden ses-dengeli olmalı
  (§6.3). Hepsi best-effort, UI'ya asla throw etmez.
- **Preload:** `init()` → `_preloadSfx()` her efektin asset'ini önceden yükler. **Eksik/bozuk asset
  sessizce yutulur** (`try/catch` + `debugPrint`) → çalma no-op olur, çökme YOK.

### 3.2 Ayar + sessiz mod muhafızası (yeni sesler bedava miras alır)

- `playSfx` gövdesi: `if (!_soundEnabled || _ringerSilent) return;` → **ses toggle kapalıysa veya
  cihaz sessizdeyse hiçbir efekt çalmaz.** Yeni efektler bu muhafızayı otomatik alır (§8).
- `_ringerSilent`, `RingerModeService` (Android-özel) ile beslenir; iOS'ta karşılığı yok → iOS'ta
  sesler yalnız uygulama-içi ses toggle'ına uyar (§8, proje kuralı).

### 3.3 Mevcut ses paleti (yeni sesler bunun dünyasında durmalı)

| Sfx | Kullanım | Karakter |
|---|---|---|
| `place` / `flip` | Taş koyma / çevirme | Sıcak, tahta-dokunuşlu, kısa |
| `button` | UI dokunuşu | Nötr, çok kısa tık |
| `tick` / `timeup` | Sayaç / süre bitti | İnce tık / uyarı |
| `win` / `lose` / `draw` | Maç sonucu | Ölçülü sonuç imzası (fanfar değil) |

> **Sonuç:** dünya **tahta + ölçülü**. Yeni sesler (satın alma, coin, kademe, kuşanma) aynı sıcak,
> abartısız dilde olmalı — parlak sentetik/kumarhane tınısı bu palete yabancı düşer.

### 3.4 Tetik noktaları — **henüz yok** (bu task'ın kod dokunmama sebebi)

Read-only recon ile doğrulandı:

- **Mağaza / satın alma / kuşanma:** `lib/features/` altında shop/store yok → REV-69 sıfırdan
  `lib/features/shop/` açacak (REV-63 §3.3 / §11). Satın alma başarı anı = REV-63 §7.3; kuşanma =
  REV-63 §7.4. **Şu an bağlanacak yer yok.**
- **Coin kazanma:** client'ta cüzdan/`earnedCoins` gösterimi yok (koddaki "coin" = `CoinColor` pul
  rengi, para değil). Maç sonu coin ödülü REV-66'da **sunucuda** açıldı (galibiyet 10 / beraberlik 5 /
  mağlubiyet 2); client gösterimi ayrı iş. Maç sonu SFX'i bugün `game_screen.dart`'ta çalıyor (win/
  lose/draw) — coin sesi buraya iliştirilecek (§7.2).
- **Kademe atlama:** kademe modeli (`tier(level)`) client'ta yok → REV-67 kuracak (REV-60 §7).
  Kademe atlama = seviye atlarken kademe sınırı geçildiği an (§7.2).

> Bu yüzden §7 bloğu **uygulanmaya-hazır** ama **bu task'ta uygulanmaz**: bağlanacak akışlar
> (REV-69/REV-67) kurulunca + ses dosyaları kaydedilince tek adımda devreye alınır.

---

## 4. Ses dili / tasarım ilkeleri

> Proje animasyon zevki: **rijit, hacimli, yavaş tempo, ölçülü** (proje hafızası). REV-63 §7.3:
> kutlama minimal, **konfeti/patlama YOK**. Bu disiplin ses tarafına birebir taşınır.

1. **Tahta-organik, sentetik değil.** Tınılar ahşap/madeni-para-tahta-kutu dünyasından; parlak
   8-bit/arcade "coin" ya da kumarhane "ka-ching" **kullanılmaz**. Mevcut `place/flip` sıcaklığıyla
   akraba.
2. **Kısa ve tek-vuruşlu.** Kutlamalar tek, net bir onay; uzun jingle/melodi yok. En uzun olan
   kademe atlaması bile < 1 sn (§6.2).
3. **Yoğunluk olayla orantılı.** Kuşanma (sık, küçük) en hafif; kademe atlama (nadir, prestijli) en
   dolu. Coin kazanma sonucun altında kalır. → §5 yoğunluk sütunu.
4. **Katman değil, tek imza.** Her olay tek kısa cue; çakışan/üst üste binen katmanlardan kaçınılır
   (maç sonu coin + sonuç sesi hariç — o da sıralı/kısık, §6.3).
5. **Marka tonu.** Sıcak orta frekanslar (ahşap gövde); en üst kademe (Efsane) için tek ince ışıltı
   dokunuşu opsiyonel (REV-60 §6.2 "yalnız Efsane ışıldar" ilkesiyle hizalı — §5.3 açık nokta).

---

## 5. Olay → ses karakteri briefi

| # | Olay | Sfx (öneri) | Süre | Yoğunluk | Karakter |
|---|---|---|---|---|---|
| 1 | Satın alma başarılı | `purchase` | ~300–500 ms | Orta | Sıcak "onay + mühür": madeni paranın ahşap kutuya düşüşü + kısa tatmin edici alçak ton. |
| 2 | Coin kazanma (maç sonu) | `coinReward` | ~250–400 ms | **Düşük** (kısık) | Hafif coin sayımı/şıngırtısı; sonuç sesinin altında, nazik. |
| 3 | Kademe atlama | `tierUp` | ~600–900 ms | **Yüksek** (ama ölçülü) | Sıcak, asil yükseliş + tek çan/rezonans kapanışı. "Yükseldin." Fanfar değil. |
| 4 | Kuşanma (equip) | `equip` | ~150–250 ms | En düşük | Yumuşak tık-oturma; parçanın yerine kilitlenmesi. `place`'ten daha yumuşak/kısa. |
| — | Yetersiz bakiye | *(yeni yok)* | — | — | Mevcut `invalid.wav` yeniden kullanılır (REV-63 §7.2). |

### 5.1 Satın alma (başarılı) — `purchase`

- **Ne zaman:** `purchaseItem` başarıyla döndüğünde, diyalog kapanırken (REV-63 §7.3). Coin bakiyesi
  tick-down (~400 ms) + kart "Sahip" durumuna geçerken eşzamanlı.
- **His:** "aldım, mühürlendi" — tatmin edici ama abartısız. Tek sıcak onay; alçak-orta gövde,
  kısa rezonanslı kuyruk. Kumarhane ka-ching **değil**.
- **Not:** REV-63 §7.3'teki "tek seferlik hafif ✓ turkuaz halka" görsel vurgusuyla senkron.

### 5.2 Coin kazanma (maç sonu ödülü) — `coinReward`

- **Ne zaman:** maç bittiğinde, sonuç SFX'inden (`win/lose/draw`) **hemen sonra** ya da altında
  (§6.3). REV-66 `earnedCoins` (galibiyet 10 / beraberlik 5 / mağlubiyet 2) client'ta gösterildiğinde.
- **His:** küçük ödülün nazik bildirimi — 2–3 hızlı yumuşak coin şıngırtısı/sayımı, kısa. **Miktara
  göre değişmez** (tek kısa cue; 2 coin de 10 coin de aynı) — basit tutulur.
- **Kritik:** sonuç sesini **bastırmaz**; belirgin biçimde daha kısık mixlenir (§6.3). Mağlubiyette
  de çalar (2 coin) ama `lose` sesinin gölgesinde kalır — ezici olmasın.

### 5.3 Kademe atlama (ünvan değişimi) — `tierUp`

- **Ne zaman:** seviye atlarken **kademe sınırı geçildiğinde** (`tier(newLevel) != tier(oldLevel)` —
  REV-67 modeli; REV-60 §7). Kademeler: Çaylak→Acemi→Kalfa→Usta→Büyükusta→Efsane (REV-60 §4/§5).
  Her seviye atlamada DEĞİL, yalnız 6 kademe geçişinde (5 geçiş anı; nadir → özel his).
- **His:** sistemin en dolu anı ama yine ölçülü. Sıcak, asil bir yükseliş (ahşap/pirinç swell) +
  tek çan/rezonans kapanışı. Uzun fanfar/melodi **yok**.
- **Açık nokta (§9.1):** tek `tierUp` sesi tüm kademelere mi, yoksa **Efsane (kademe 6)** için ince
  ek ışıltı katmanı mı? REV-60 §6.2 "yalnız Efsane ışıldar" ilkesine paralel → öneri: **tek ortak
  ses + Efsane'ye opsiyonel ışıltı varyantı** (`tierUp` + gerekirse `tierUpLegend`). Sade başlamak
  için tek ses de yeterli; ekip kararı.

### 5.4 Kuşanma (equip) — `equip`

- **Ne zaman:** "Kuşan" dokunuşu — çerçeve/tahta/taş aktif seçimi değiştiğinde (REV-63 §7.4; coinsiz,
  anında). Eski kuşanılanın turkuaz kenarlığı söner, yeninin yanar → o anla senkron.
- **His:** en hafif, en kısa — parçanın yerine "oturması". Tahta-dokunuşlu yumuşak tık; `place`'in
  daha yumuşak/kısa akrabası. `button`'dan **ayrışmalı** (o genel dokunuş; bu "kuşanıldı/oturdu").
- **Not:** çok sık tetiklenebilir (kullanıcı kombinasyon dener) → kesinlikle kısa ve yorucu olmayan.

---

## 6. Üretim / format yönergesi (seslendirme — Enes)

### 6.1 Format

- **Tip:** **`.wav`** (mevcut tüm SFX `.wav` — "mevcut format"). `audioplayers` `.mp3/.ogg` de
  destekler; boyut kritik olursa kullanılabilir ama **tutarlılık için `.wav` önerilir** (palet tek tip
  kalsın). Karar verilirse tek formatta tutulmalı.
- **Kanal / örnekleme:** mevcut SFX ile aynı (tipik SFX: mono, 44.1 kHz, 16-bit). Yeni dosyalar aynı
  örnekleme/bit derinliğinde üretilmeli → preload/çalma tekdüze.
- **Dizin:** `assets/audio/` — pubspec'te **dizin olarak** kayıtlı (`- assets/audio/`) → **yeni
  dosya için pubspec satırı GEREKMEZ**, dosyayı bırakmak yeter.

### 6.2 Süre (kısa tut)

| Sfx | Hedef süre |
|---|---|
| `equip` | ~150–250 ms (en kısa) |
| `coinReward` | ~250–400 ms |
| `purchase` | ~300–500 ms |
| `tierUp` | ~600–900 ms (en uzun; yine < 1 sn) |

### 6.3 Ses seviyesi dengesi (kritik — tekdüze `setVolume(1.0)`)

- Servis her efekte `setVolume(1.0)` uygular → **dosyalar önceden birbirine göre normalize edilmeli**
  (kodda per-efekt volume yok). Yeni sesler mevcut `place/button` ile aynı algısal yükseklikte
  olmalı — belirgin daha yüksek/alçak çıkmasın.
- **`coinReward` özel:** maç sonu `win/lose/draw` ile birlikte duyulacağı için **belirgin daha kısık**
  masterlanmalı (öneri: sonuç seslerinden ~6–10 dB düşük algısal seviye) → sonucu bastırmaz.
- Referans: mevcut `place.wav` / `button.wav` seviyesini hedef al; yeni sesleri onların yanında
  A/B dinleyerek dengele.

### 6.4 Kalite kontrol listesi (her ses)

- [ ] `.wav`, mevcut SFX ile aynı kanal/örnekleme/bit derinliği
- [ ] Hedef süre içinde (§6.2); baş/son sessizlik kırpılmış (tetikte anında başlasın)
- [ ] `place/button` ile ses seviyesi dengeli; `coinReward` belirgin kısık (§6.3)
- [ ] Tahta-organik ton; arcade/sentetik değil (§4)
- [ ] Cihaz hoparlöründe + kulaklıkta dinlendi; klip/bozulma yok
- [ ] Dosya adı §7 map'iyle birebir (`purchase.wav`, `coin_reward.wav`, `tier_up.wav`, `equip.wav`)

---

## 7. Kod entegrasyonu (uygulanmaya-hazır — REV-69/REV-67 ile)

> Bu blok bu task'ta **uygulanmaz** (§3.4: tetik noktaları + ses dosyaları henüz yok). Ses dosyaları
> kaydedilip mağaza (REV-69) / kademe modeli (REV-67) koda geçince **birebir** uygulanır.

### 7.1 `sound_service.dart` — enum + asset map (2 küçük ekleme)

```dart
// enum Sfx (mevcut 9 değere 4 ekleme):
enum Sfx {
  place, flip, invalid, button, tick, timeup, win, lose, draw,
  purchase, coinReward, tierUp, equip,
}

// _sfxAsset map (mevcut girişlere 4 ekleme):
Sfx.purchase:   'audio/purchase.wav',
Sfx.coinReward: 'audio/coin_reward.wav',
Sfx.tierUp:     'audio/tier_up.wav',
Sfx.equip:      'audio/equip.wav',
```

Başka değişiklik gerekmez: `_preloadSfx` map üstünden döner (yeni sesleri otomatik yükler),
`playSfx` muhafızı + round-robin havuzu yeni efektler için de çalışır.

### 7.2 Tetik noktaları (ilgili task uygular)

| Sfx | Tetik yeri | Task | Not |
|---|---|---|---|
| `purchase` | `purchaseItem` başarı handler'ı (mağaza) | REV-69 | REV-63 §7.3; tick-down + ✓ vurgusuyla senkron |
| `coinReward` | Maç sonu, sonuç SFX'inden sonra (`game_screen.dart` end-of-match; online karşılığı) | REV-66/REV-69 | Sonuç sesinden **sonra/altında**; §6.3 kısık |
| `tierUp` | Seviye atlarken `tier(new) != tier(old)` anı | REV-67 | REV-60 §7; kademe atlama = ünvan değişimi |
| `equip` | "Kuşan" seçim mutasyonu (frame/board/coinSkin) | REV-69 | REV-63 §7.4; kenarlık geçişiyle senkron |

> **Maç sonu sırası (öneri):** önce mevcut `win/lose/draw` çalar; `coinReward` kısa bir gecikme/
> hemen ardından (bindirme değil, sıralı) → iki cue karışmaz. Uygulama detayı REV-69'a bırakılır.

### 7.3 Native / iOS paritesi + gate

- **Bu task:** yalnız `TASARIM/*.md` → Dart/native değişiklik yok → **iOS paritesi yok, analyze/test/
  format gate uygulanmaz** (diff `.md`).
- **§7 uygulandığında:** yalnız `lib/` (Dart) + `assets/audio/` → yine **native dosya değişmez**
  (Info.plist/manifest/gradle/pbxproj yok) → iOS'a ayrıca kopyalanacak native karşılık **yok**.
  O aşamada flutter analyze + test + format gate uygulanır.

---

## 8. Sessiz / zil modu + ayar davranışı

- **Ses toggle kapalı** (`_soundEnabled == false`): tüm yeni efektler dahil hiçbir SFX çalmaz —
  `playSfx` başındaki muhafız (§3.2). Ek kod gerekmez.
- **Android sessiz modu** (`_ringerSilent == true`): efektler susar (sistem sesleriyle uyumlu).
  Yeni sesler bunu otomatik alır.
- **iOS:** `RingerModeService` Android-özel, iOS'ta karşılığı **yok** (proje kuralı) → iOS'ta sesler
  yalnız uygulama-içi ses toggle'ına uyar; cihaz sessiz anahtarına REV-65 özel bir davranış eklemez.
- **Öneri:** kademe atlama gibi "önemli" bir olayda bile sessiz mod/ toggle'a saygı korunur — ses
  kararı kullanıcınındır; görsel kutlama (REV-68) sessizken de bilgi taşır.

---

## 9. Ekip kararı için açık noktalar

1. **Kademe atlama sesi kapsamı:** tek `tierUp` tüm kademelere mi, yoksa **Efsane (6)** için ek
   ışıltı varyantı (`tierUpLegend`) mı? Öneri: tek ses + Efsane'ye opsiyonel ışıltı (REV-60 §6.2
   "yalnız Efsane ışıldar" ile hizalı). (§5.3)
2. **Coin kazanma sesi her maçta mı:** mağlubiyette de (2 coin) çalsın (önerilen — tutarlı, ama
   kısık) mı, yalnız galibiyet/beraberlikte mi? (§5.2)
3. **Format:** `.wav` (önerilen — mevcut palet) mi, boyut için `.mp3/.ogg` mi? Tek formatta tutulmalı.
   (§6.1)
4. **Kuşanma sesi:** her kuşanmada mı çalsın, yoksa yalnız satın alma sonrası ilk kuşanmada mı
   (çok sık tetiklenmesin diye)? Öneri: her kuşanmada, ama çok kısa/yumuşak (§5.4).
5. **Yetersiz bakiye:** mevcut `invalid.wav` yeniden kullanımı (önerilen) yeterli mi, ayrı bir
   "yumuşak ret" sesi mi? (§5 tablo)

**Karar sonrası:** onaylanan cevaplar `PROGRESS.md`'ye işlenir; ses dosyaları seslendirmeyle üretilir;
§7 bloğu REV-69 (mağaza) + REV-67 (kademe) client task'larıyla birlikte uygulanır.
