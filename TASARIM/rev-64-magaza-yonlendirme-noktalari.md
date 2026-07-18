# REV-64 · Mağaza Yönlendirme Noktaları Tasarımı

> **Durum:** Ekip kararı bekliyor (kilitli içerik kart tasarımları + yönlendirme noktaları
> haritası). Bu doküman repo koduna **dokunmaz** — yalnız tasarım + yönlendirme eşlemesi + gerekli
> rozet/etiket asset yönergesi üretir. Kod tarafı ("Uygulama içi mağaza yönlendirmeleri") ayrı bir
> **client** task'ında (**REV-71**) uygulanır.
>
> **Sahibi:** Enes (görsel tasarım) · **Task:** REV-64 · **Bağımlı:** REV-63 (mağaza görsel dili) ·
> **Bloklar:** REV-71 (uygulama içi yönlendirmeler — client) · **İlgili:** REV-70 (tema elemesi
> uygulaması + ayarlar sadeleştirme) · **Takım:** Reversi_Game

---

## 1. Özet karar

- **Mağaza tek merkez; her yönlendirme doğru kategori sekmesine iner.** Mağaza REV-63'te tek ekran
  + 4 kategori sekmesi (Çerçeveler / Tahtalar / Taş Renkleri / Coin Paketleri). REV-64 her temas
  noktasını **hangi tetikleyici → hangi sekme** olarak eşler (deep-link mantığı). → **§4**
- **Kilitli içerik iki yerde "mağaza kapısı"na döner.** (a) Ayarlar → Tahta Rengi'nde kilitli
  tahtalar (`mermer`, `cicek`), (b) Profil → çerçeve alanında kilitli/satılık çerçeveler. İkisi de
  bugün **yalnız `Opacity 0.28`** ile soluk (kod gerçeği §3) — REV-64 bunları **kilit + coin fiyat +
  "mağazada aç"** diliyle tıklanabilir kapıya çevirir. → **§5, §6**
- **Ana menüde tek görünür kapı: coin bakiye chip'i + mağaza ikonu.** Bugün menüde coin bakiyesi de
  mağaza girişi de **yok** (§3). Header'a REV-63 §4.2 coin chip'i + bir mağaza ikon-butonu eklenir;
  chip görünürlük + giriş görevini birlikte görür. → **§7**
- **Rozet dili REV-63 §6.2 + §10 ile birebir.** Kilitli = gri/`Opacity 0.28` + kilit rozeti; ücretli
  sahip-olunmayan = coin fiyat rozeti; kademe-şartı = "Kademe N gerekir". **Yeni mutlak fiyat
  uydurulmaz.** REV-64 neredeyse hiç yeni asset üretmez — REV-63 §10 rozet setini yeniden kullanır;
  tek istisna "mağazada aç" etiketi + mağaza giriş ikonu. → **§8, §9**
- **Sadeleştirilmiş ayarlar tabanı (REV-62 §4.4).** Ayarlardan app-teması seçici + disk-renk
  (`CoinColor`) seçici kalkar (REV-70). REV-64 bu **sadeleşmiş** ayarları baz alır: kaldırılan
  seçicilere yönlendirme **konmaz**; yalnız kalan kilitli tahta kartları mağaza kapısı olur. → **§5.1**

**Dayanak:** (a) REV-63 mağaza ekranı + kategori/durum/rozet dili, (b) REV-61 kilitli çerçeve +
REV-62 kilitli tahta envanteri, (c) kod gerçeği (§3: kilitli içerik yalnız Opacity, menüde coin/mağaza
girişi yok, profilde frame seçici yok) ile tutarlı kurgulandı.

---

## 2. Kapsam ve teslim

REV-64 tanımından:

1. **Ayarlar ekranı:** kilitli (ücretli, sahip olunmayan) tahta kartı görünümü + "mağazada aç"
   rozeti/etiketi → **§5**
2. **Profil ekranı:** kilitli çerçeve görünümü + mağaza çağrısı → **§6**
3. **Diğer temas noktaları:** ana menüde mağaza girişi (buton/ikon) dahil, gerekli görülen yerler →
   **§7 + §4.2 (tasarım gerektirmeyen karar noktaları)**

**Teslim:** kilitli içerik kart tasarımları (§5, §6) + yönlendirme noktaları listesi (§4). Tasarım
gerektirmeyen noktalar için sadece "**buradan mağazanın X kategorisine yönlendirilir**" kararı yazılır
(§4.2). Bu doküman **koda dokunmaz**; kilitli görünümleri + deep-link'leri **REV-71** (client) uygular.

> **Bu dokümanın ürettiği:** yönlendirme haritası (tetikleyici → hedef sekme) + kilitli tahta/çerçeve
> kart spec'i + ana menü mağaza kapısı + "mağazada aç" etiketi & mağaza ikonu asset yönergesi + REV-71
> için kod notları. Somut PNG/etiket assetleri onay sonrası Gemini'de üretilir (REV-61/63 iş akışı).

---

## 3. Mevcut kod gerçeği (karar buna dayanır)

Explorer recon'u (read-only) ile doğrulandı. Yönlendirme, mevcut ekran desenlerine yaslanır.

### 3.1 Ayarlar ekranı (`settings_screen.dart`, `board_theme_grid.dart`)

- **İskelet:** `Scaffold` gradient `DecoratedBox` → clipper header (**150 px**, diagonal kesim) →
  `SafeArea` → `ListView` (padding 16,6,16,24) → `_Section` kartları (radius **20**, padding 16;
  wood: cardTop bg + gold 1 px border + shadow).
- **Bölümler (bugün):** Tema (`AppThemeRow`) · Dil (`LanguageRow`) · **Tahta Rengi**
  (`BoardThemeGrid`) · **Disk Rengi** (`CoinRow`, yalnız cream tema) · Ses (`ToggleRow`).
- **`BoardThemeGrid` tile:** **88×88**, radius 16 (iç preview ClipRRect 11), aktif kenarlık
  **3 px accent `#13A99C`** (AnimatedContainer 150 ms), `Wrap(spacing 12, runSpacing 12)`.
  İsim: alt yazı (Nunito 11.5, aktif onAccent / pasif inkSoft).
- **⚠️ Kilitli tahta gösterimi bugün YALNIZCA `Opacity(0.28)`** — kilit ikonu, coin rozeti, "mağazada
  aç" etiketi **YOK**. Tıklanamaz görünür. **REV-64'ün ana işi tam da bu boşluğu doldurmak.**

### 3.2 Profil ekranı (`profile_screen.dart`)

- **İskelet:** `Scaffold` + clipper header (**150 px**, oval kesim) → içerik.
- **Avatar:** `CircleAvatar(radius 48)` + beyaz 4 px halka (padding + circle decoration + shadow).
  **Frame/avatar özelleştirme UI'ı YOK** — sadece düz avatar.
- **İçerik:** displayName · `_LevelCard` (kademe rozeti + XP) · `_OnlineRecordCard` · çıkış.
  Kart deseni `_Card` radius **20**, padding 16.
- **⚠️ Çerçeve seçici / satılık çerçeve görünümü kodda YOK** — REV-61 §6.2'nin çerçeve seçicisi
  (BoardThemeGrid deseni) henüz uygulanmadı. REV-64 kilitli çerçeve kartını + mağaza çağrısını tasarlar.

### 3.3 Ana menü (`main_menu_screen.dart`, `menu_button.dart`, `profile_chip.dart`)

- **Butonlar:** `MenuButton` (**260×58**, ikon 22 + metin Baloo2/Marcellus 18); Devam Et · 1 Oyuncu ·
  2 Oyuncu · Online Oyna (primary) · Leaderboard.
- **`showModalBottomSheet`** emsali var (`_OnlineSignInSheet`, backgroundColor transparent, Container
  radius 24).
- **`ProfileChip`** (üst) yalnız oturum/avatar gösterir. **⚠️ Coin bakiyesi göstergesi YOK, mağaza
  girişi YOK.** REV-64 buraya coin chip + mağaza kapısı ekler.

### 3.4 Coin gösterimi + tema token'ları

- **`CoinView(palette, width, faceSquash, thicknessFactor)`** — CustomPaint 3B madeni para.
  `CoinPalette` = black / white / turquoise / orange (`coin_palette.dart`). `CoinRow` swatch 38×38,
  3 px aktif accent, disabled `Opacity 0.28`. **Kalıcı coin bakiye chip'i hiçbir ekranda YOK.**
- **Token teyidi:** accent `#13A99C` · coral `#F4552C` · cream `#FFF6E9→#FFEDD6` ·
  bannerGradient (`#2FD4C2→#14B3A6→#0E9C91`) · gold `#B8860B` · parchment/surface `#EFE5D5` ·
  card `#F5EAD4→#EBDBBE` · button `#56391F→#3E2A1E` · Marcellus (başlık) / Lora (metin).
- **Mağaza ekranı / route:** **YOK** (`lib/features/` altında shop/store/market yok). Mağaza REV-69'da
  açılır; REV-64'ün "hedef"i bu yüzden **kavramsaldır** — yönlendirmenin varış noktası REV-63 §4.3
  kategori sekmeleridir, kodu REV-71 (giriş) + REV-69 (ekran) uygular.

---

## 4. Yönlendirme haritası (TESLİM — yönlendirme noktaları listesi)

### 4.1 Görsel gerektiren yönlendirme noktaları

Mağazanın hedefleri REV-63 §4.3 dört sekmesidir: **Çerçeveler** (`frame`) · **Tahtalar** (`board`) ·
**Taş Renkleri** (`coinSkin`) · **Coin Paketleri** (IAP). Her tetikleyici bir sekmeye "deep-link" iner.

| # | Kaynak / Tetikleyici | Hedef sekme | Görsel | Ref |
|---|---|---|---|---|
| 1 | **Ana menü** — coin bakiye chip + mağaza ikon-butonu | Mağaza (varsayılan **Çerçeveler**) | Coin chip + mağaza ikonu | §7 |
| 2 | **Ana menü** — coin chip'in **"+"** ucu | Mağaza / **Coin Paketleri** | "+" (chip parçası) | §7.2 |
| 3 | **Ayarlar → Tahta Rengi** — kilitli tahta kartı (`mermer`/`cicek`) | Mağaza / **Tahtalar** | Kilitli tahta kartı | §5 |
| 4 | **Profil → çerçeve alanı** — kilitli çerçeve kartı / "Çerçeveni özelleştir" CTA | Mağaza / **Çerçeveler** | Kilitli çerçeve kartı + CTA | §6 |
| 5 | **Satın alma diyaloğu** — "Yetersiz bakiye" (herhangi coin alımı) | Mağaza / **Coin Paketleri** | (REV-63 §7.2 diyaloğu — mevcut) | §4.3 |

> Hedef sekme "deep-link" mantığı: mağaza ekranı bir `initialCategory` parametresiyle açılır (REV-71
> kod notu §10). Kilitli tahtadan gelen mağazayı **Tahtalar** sekmesinde, kilitli çerçeveden gelen
> **Çerçeveler** sekmesinde açar → kullanıcı doğrudan aradığı kategoride başlar.

### 4.2 Tasarım gerektirmeyen noktalar (yalnız karar)

Devir kuralı: "her yere görsel şart değil." Aşağıdaki noktalar için **görsel üretilmez**, yalnız
yönlendirme kararı yazılır:

- **Oyun sonu / maç bitişi ekranı:** coin ödülü gösterimi zaten REV-66 kapsamında. **Karar:** ayrı
  "mağazada harca" CTA **konmaz** (marka ölçülü; §7.3 REV-63 kutlama disiplini). Kullanıcı coinini
  menüdeki chip üzerinden mağazaya taşır (madde 1). Zorlamasız akış.
- **Leaderboard satırı:** çerçeveler burada görünür (REV-61 §6.3, ∅32) ama liste kalabalık → **karar:**
  mağaza CTA / kilit rozeti **konmaz**. Sadece kazanılmış/kuşanılmış çerçeve gösterilir; satılık
  çerçeve tanıtımı buraya taşınmaz.
- **Menü chip (∅22) çerçevesi:** REV-61 §6.3'e göre yalnız kademe renk halkası; **karar:** mağaza
  yönlendirmesi taşımaz (çok küçük yüzey).
- **Kademe atlama / seviye-yükseldi bildirimi (varsa):** **karar (opsiyonel, ekip):** yeni açılan
  kademe çerçevesini kutlayan bildirim, "profilinde gör" ile **profile** yönlendirir — mağazaya değil
  (kademe çerçevesi satılık değil, otomatik kazanım). Çapraz-satış zorlanmaz.

> **İlke:** yönlendirme **çekme** (pull) modeli — kullanıcı içeriği kilitli görünce kendi tıklar;
> ekranlar arası **itme** (push/interstitial) reklam paneli konmaz. Marka ölçülü kalır.

### 4.3 "Yetersiz bakiye" köprüsü (REV-63 §7.2 ile hizalı)

Herhangi bir coin ürününde bakiye yetmezse (§6.2 REV-63 `failed-precondition`) açılan "Yetersiz bakiye"
diyaloğu **Coin Paketleri** sekmesine yönlendirir. Bu diyalog REV-63'te tanımlı — REV-64 yalnız
**hedefini** sabitler (madde 5). Yeni görsel gerekmez.

---

## 5. Ayarlar ekranı — kilitli tahta kartı (TESLİM 1)

### 5.1 Sadeleştirilmiş ayarlar tabanı (REV-62 §4.4 / REV-70)

REV-70 uygulanınca ayarlar **sadeleşir**: **Tema seçici (`AppThemeRow`) kalkar** (tek ahşap/parchment
shell) + **Disk Rengi seçici (`CoinRow`) kalkar** (her tahta kendi diskini belirler; taş renkleri
mağaza kozmetiğine taşınır — REV-63 §5.3). REV-64 bu sonrası hâli baz alır:

```
Ayarlar (REV-70 sonrası)
 ├─ Dil
 ├─ Tahta Rengi   → BoardThemeGrid (5 tahta: wood/turkuaz/gece açık · mermer/cicek KİLİTLİ)
 └─ Ses
```

> **Kural (devir):** kaldırılan seçicilere (app teması, disk rengi) **yönlendirme konmaz** — o
> özellikler mağazaya taşınmadı/silindi. Tek mağaza kapısı **Tahta Rengi bölümündeki kilitli
> tahta kartları**dır.

### 5.2 Kilitli tahta kartı anatomisi (mevcut tile'a minimal ekleme)

Kilitli tahta = REV-62'den `mermer` (Nadir ~1.500) + `cicek` (Epik ~3.500). Bugün yalnız `Opacity
0.28`. REV-64 eki (mevcut 88×88 tile deseni korunur — REV-63 §6.2 durum diliyle birebir):

```
_BoardTile (88×88, radius 16)  — KİLİTLİ VARYANT
 ├─ Board preview (mevcut _BoardPreview)   → Opacity 0.28 (mevcut, KORUNUR)
 ├─ Kilit rozeti (sağ üst köşe overlay)    → REV-63 §10 "kilit rozeti" (∅~18–20)
 ├─ Coin fiyat rozeti (alt-orta overlay)   → REV-63 §10 "coin rozeti" + tutar (mini)
 └─ İsim (alt yazı, mevcut)                → "Mermer" / "Çiçek" (Nunito 11.5, tam opak kalır)
```

- **Kilit rozeti** kartın soluk olduğunu **anlamlandırır** (bugün Opacity "neden soluk?" belirsiz →
  kullanıcı kilitli mi bilmiyor). Sağ üst köşe, REV-63 §10 rozet seti, ahşap-gri ince stil.
- **Coin fiyat rozeti** (∅16–18 coin ikonu + `1.500` / `3.500`, gold vurgulu) → kartın **satılabilir**
  olduğunu ve fiyatını gösterir. Mutlak değer REV-62 §6.3 sınıflarından (Nadir/Epik), **yeni sayı yok**.
- **"Mağazada aç" etiketi:** dar 88 px tile'da ayrı pill sıkışık → **öneri:** etiket tile içine
  gömülmez; bunun yerine tile'a **dokununca** açılır (davranış §5.3). İsteğe bağlı: bölüm başlığının
  yanında küçük "🛈 Kilitli tahtalar mağazada" alt-metni (bir kez, bölüm düzeyinde) — tile başına
  tekrar etmez (§9 açık nokta).

### 5.3 Etkileşim

- **Kilitli tahta tile'ına dokunuş → seçim DEĞİL, mağaza kapısı.** Mağaza **Tahtalar** sekmesinde
  açılır (§4.1 madde 3), ilgili tahta kartı öne kaydırılır/vurgulanır (REV-71 kod notu).
- Sahip olunan (satın alınmış) tahta artık kilitli değil → normal tile (kilit/coin rozeti düşer),
  dokunuş seçim yapar (mevcut davranış). Yani rozetler yalnız **sahip-olunmayan ücretli** tahtada.
- Ücretsiz tahtalar (`wood`/`turkuaz`/`gece`) rozetsiz, doğrudan seçilir (bugünkü davranış).

> **Tutarlılık:** bu, REV-63 §6.2'deki "kilitli" durumunun **ayarlar içindeki izdüşümü** — aynı gri +
> kilit + coin dili. Mağaza kartı ile ayarlar tile'ı **aynı rozet setini** kullanır (§8).

---

## 6. Profil ekranı — kilitli çerçeve kartı + mağaza çağrısı (TESLİM 1)

### 6.1 Bağlam

Profilde bugün yalnız `CircleAvatar(radius 48)` + beyaz halka var; çerçeve seçici yok (§3.2). REV-61
§6.2 çerçeve seçici (BoardThemeGrid deseni) henüz uygulanmadı (REV-67/kod). REV-64 iki katmanlı
teslim verir: **(a) minimum — kesin**, **(b) genişletilmiş — çerçeve seçici gelince**.

### 6.2 (a) Minimum: avatar altı çerçeve CTA (kesin, seçiciden bağımsız)

Çerçeve seçici henüz olmasa da profil bir **mağaza çağrısı** taşır:

```
Profil
 ├─ Avatar (CircleAvatar r48 + kademe çerçevesi otomatik takılı — REV-61 §4)
 ├─ displayName
 └─ [ Çerçeveni özelleştir → ]   ← CTA satırı (Lora, gold vurgu + ikon)
        dokun → Mağaza / Çerçeveler sekmesi (§4.1 madde 4)
```

- Kademe çerçevesi (otomatik kazanım) avatarda zaten görünür — CTA "**daha fazla çerçeve**" vaadi verir.
- CTA metni ölçülü: "Çerçeveni özelleştir" / "Mağazada daha fazla çerçeve". Zorlamasız, tek satır.
- **Görsel:** ayrı asset gerekmez — mevcut satır/link stili + REV-63 §10 mağaza ikonu (küçük).

### 6.3 (b) Genişletilmiş: profil çerçeve şeridi + kilitli çerçeve kartı

REV-67 çerçeve seçici geldiğinde profilde **mini çerçeve şeridi** olur (yatay, BoardThemeGrid deseni,
REV-61 §6.2). Kilitli (satılık, sahip-olunmayan) çerçeve kartı bu şeritte:

```
Çerçeve kartı (BoardThemeGrid tile deseni, ∅ önizleme + isim)  — KİLİTLİ VARYANT
 ├─ Çerçeve önizleme (REV-61 512×512 PNG, mock avatar üstünde)  → Opacity 0.28
 ├─ Kilit rozeti (sağ üst)             → REV-63 §10 kilit rozeti
 └─ Alt satır:
      • Satılık çerçeve  → coin fiyat rozeti (~500 / 1.500 / 3.500, REV-61 §5.1 sınıfı)
      • Kademe çerçevesi → "Kademe N gerekir" (kademe rozeti; SATILMAZ, mağazaya gitmez)
```

- **İki kilit türü ayrışır (kritik):**
  - **Satılık kilitli** (REV-61 §5, 5 adet coin çerçeve) → coin fiyat rozeti → dokun → **Mağaza /
    Çerçeveler** (§4.1 madde 4).
  - **Kademe-şartı kilitli** (REV-61 §4, 6 otomatik çerçeve) → "Kademe N gerekir" → dokun → **bilgi
    ipucu** (kademe nasıl açılır), **mağazaya gitmez** (satın alınamaz — REV-63 §6.2 durum 4 + §11
    "purchaseItem bunları reddeder"). Bu ayrım REV-64'ün en kritik yönlendirme kuralı: **her kilit
    mağaza kapısı değildir.**
- **Kuşanılan** çerçeve = 3 px turkuaz kenarlık (REV-63 §6.2 kuşanıldı deseni). **Sahip** ama
  kuşanılmamış = normal + "Kuşan". Bu durumlar REV-63 §6.2 tablosuyla birebir aynı (mağaza dışı izdüşüm).

> **Teslim netliği:** (a) minimum CTA REV-71 ile **hemen** uygulanabilir (seçici gerektirmez);
> (b) genişletilmiş kilitli çerçeve kartı, çerçeve seçici (REV-67) gelince aynı rozet diliyle devreye
> girer. İkisi de aynı Mağaza/Çerçeveler hedefine iner.

---

## 7. Ana menü — mağaza kapısı + coin bakiye göstergesi (TESLİM — diğer temas noktası)

### 7.1 Karar: header'da coin chip + mağaza ikon-butonu

Menüde bugün coin bakiyesi de mağaza girişi de yok (§3.3). İkisini **tek yerde** çözmek en ölçülü
çözüm: üst şerit (ProfileChip hizası) —

```
Ana menü üst şeridi
 ├─ (sol) ProfileChip (mevcut — avatar/oturum)
 └─ (sağ) Coin bakiye chip'i  +  Mağaza ikon-butonu
          └─ Coin chip = REV-63 §4.2 chip'in AYNISI (tutarlılık):
               CoinView (∅~22) + binlik ayraçlı bakiye ("1.250") + "+" ucu
```

- **Coin chip** kullanıcıya bakiyesini **her açılışta** gösterir (bugün hiç görünmüyor) → mağaza
  ekonomisinin ilk teması. REV-63 §4.2 chip'i birebir yeniden kullanılır → mağazaya girince aynı chip
  header'da devam eder (görsel süreklilik).
- **Mağaza ikon-butonu** (chip'in yanında ya da chip'e gömülü) → Mağaza (varsayılan **Çerçeveler**
  sekmesi, §4.1 madde 1). İkon: ahşap/altın dilinde küçük vitrin/çanta motifi (§8 asset).
- **"+" ucu** → doğrudan **Coin Paketleri** sekmesi (§4.1 madde 2) — bakiye yükleme kısa yolu.

### 7.2 Alternatif (ekip için)

Buton listesine ayrı bir **"Mağaza" `MenuButton`** (260×58, ikincil stil) de eklenebilir. **Chip+ikon
öneriliyor** çünkü: (a) coin görünürlüğü + giriş tek bileşende toplanır, (b) buton listesi oyun
aksiyonlarına (Oyna/Online) odaklı kalır, mağaza onları gölgelemez, (c) REV-63 §4.2 chip'iyle görsel
süreklilik. İki yaklaşım birlikte de olur ama **öncelik chip+ikon** (§9 açık nokta).

### 7.3 Ölçü / marka

- Chip + ikon üst şeride oturur; ana logo/başlık ve oyun butonları **birincil** kalır (mağaza ikincil).
- Yeni içerik/kampanya varsa ikon üstünde küçük **nokta işareti** (dot badge) — sayısal "kırmızı bildirim"
  balonu değil (marka ölçülü, REV-63 §7.3 disiplini). Opsiyonel, ekip kararı.

---

## 8. Rozet / etiket asset yönergesi (Gemini — minimum yeni asset)

**İlke:** REV-64 neredeyse hiç yeni asset üretmez — **REV-63 §10 rozet setini yeniden kullanır**
(kilit rozeti · coin rozeti · ✓ sahip/kuşanıldı · kademe rozeti). Kilitli tahta/çerçeve kartları bu
mevcut rozetleri kullanır → çoğaltma yok, tek stil dili. **Yalnız iki yeni öğe gerekir:**

- [ ] **"Mağazada aç" etiketi / pill** — kilitli içerik kartlarında (opsiyonel, §5.2 bölüm-düzeyi
      alt-metin) + genel "mağaza kapısı" işareti. Gold zemin üstünde parchment/ink metin, küçük vitrin
      ikonu + "Mağazada" (Lora). Küçük ölçekte (bölüm başlığı yanı ~14–16 px) okunur.
- [ ] **Mağaza giriş ikonu** — ana menü header'ı (§7) + profil CTA'sı (§6.2). Ahşap-lonca + gold
      `#B8860B` dilinde küçük **vitrin/çanta/raf** motifi; turkuaz `#13A99C` aksan opsiyonel. 24 px
      hedef; @1x/@2x/@3x şeffaf PNG veya vektör. Menü ikon-butonu 22 px ikon boyutuyla hizalı (§3.3).
- [ ] **(opsiyonel) Yeni-içerik nokta işareti** — mağaza ikonu üstü dot badge (§7.3). Tek renk gold/
      turkuaz nokta; ayrı illüstrasyon değil, basit daire (kodda çizilebilir — asset şart değil).

**Ortak stil (REV-63 §10 ile aynı):** ahşap-lonca + gold `#B8860B` + turkuaz `#13A99C` aksan;
parchment üstünde net kenar, 1 px koyu dış hat (krem/parchment'te erimesin — REV-61 §3.4 kuralı).
Marcellus/Lora tipografiyle uyumlu.

**Kontrol listesi:**
- [ ] Şeffaf zemin (RGBA); parchment + koyu shell üstünde ayrı ayrı test
- [ ] Küçük ölçekte (kart köşesi/başlık yanı ~16–24 px) okunur
- [ ] Renk kodu tutarlı: **kilit = gri** (satılabilir değilse) · **coin = gold** (satılık) · **turkuaz
      = kuşanıldı/aktif** · **gold vitrin = mağaza kapısı** → REV-63 §10 kod tablosuyla birebir

---

## 9. Kod tarafı notları (client task REV-71 için)

Bu doküman koda dokunmaz; aşağısı REV-71'in uygulayacağı yönlendirmelerin **haritası**:

- **Deep-link / initialCategory:** mağaza ekranı (REV-69) bir **`initialCategory`** (frame / board /
  coinSkin / *coinPackages*) parametresiyle açılabilmeli. Her yönlendirme (§4.1) bu parametreyle
  doğru sekmeyi seçer. REV-69 ekranı + REV-71 girişleri bunu birlikte kurar (REV-64 → REV-71 blok).
- **Ayarlar kilitli tahta tile'ı (`board_theme_grid.dart`):** kilitli varyanta **kilit + coin rozeti
  overlay** eklenir (bugün yalnız `Opacity 0.28`). Kilitli tile `onTap` → seçim değil, mağaza
  (Tahtalar sekmesi). Sahiplik/kilit durumu REV-66 envanterinden (`ownedItems`) okunur; ücretsiz
  tahtalar rozetsiz. **REV-70 (ayarlar sadeleştirme) ile aynı dosyada çalışır → koordinasyon** (§5.1).
- **Profil çerçeve CTA + kilitli çerçeve kartı (`profile_screen.dart`):** (a) minimum CTA satırı hemen;
  (b) çerçeve seçici (REV-67) gelince kilitli çerçeve kartı aynı rozet diliyle. **Satılık kilit →
  mağaza; kademe-şartı kilit → bilgi ipucu (mağazaya GİTMEZ)** ayrımı kodda net olmalı (§6.3).
- **Ana menü (`main_menu_screen.dart`):** header'a coin bakiye chip (REV-63 §4.2 bileşeni) + mağaza
  ikon-butonu. Bakiye REV-66 cüzdanından (`coins`) canlı okunur. Mağaza ikonu → `initialCategory:
  frame`; "+" → `initialCategory: coinPackages`.
- **"Yetersiz bakiye" köprüsü:** REV-63 §7.2 diyaloğu → mağaza `initialCategory: coinPackages`.
- **Yeni asset kaydı:** "mağazada aç" etiketi + mağaza ikonu üretilince `pubspec.yaml`'a eklenir
  (REV-61 `assets/frames/` kalıbıyla). Rozetlerin çoğu REV-63 §10 setinden gelir (yeni kayıt yok).

---

## 10. Ekip kararı için açık noktalar

1. **Ana menü mağaza kapısı:** coin chip + mağaza ikonu (önerilen) mi, ayrı "Mağaza" `MenuButton` mı,
   ikisi birden mi? (§7.1, §7.2)
2. **Ayarlar kilitli tahta etiketi:** "mağazada aç" bilgisini tile başına mı (sıkışık, §5.2 önermez),
   bölüm başlığı yanında tek alt-metin olarak mı (önerilen) göstermeli? (§5.2)
3. **Profil çerçeve teslimi:** (a) minimum CTA hemen (önerilen) + (b) kilitli çerçeve kartı çerçeve
   seçici (REV-67) gelince mi? Yoksa profil çerçeve seçicisi bu task kapsamında mı beklensin? (§6)
4. **Yeni-içerik nokta işareti (dot badge):** mağaza ikonunda gösterilsin mi, yoksa V1'de es geçilsin
   mi? (§7.3) — kod basit, ürün kararı.
5. **Oyun sonu "mağazada harca" CTA:** kesinlikle konmasın (önerilen, §4.2) mı, yoksa hafif tek bir
   çapraz-satış denensin mi? (§4.2)

**Karar sonrası:** onaylanan cevaplar `PROGRESS.md`'ye işlenir; **REV-71** yönlendirmeleri + kilitli
görünümleri kodlar (mağaza ekranı REV-69, ayarlar sadeleştirme REV-70 ile koordineli).
