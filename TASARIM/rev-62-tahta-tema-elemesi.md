# REV-62 · Tahta & Tema Elemesi Önerisi

> **Durum:** Ekip kararı bekliyor (gerekçeli eleme + tema önerisi). Karar onaylanınca
> `PROGRESS.md`'ye işlenir; kod tarafı (tahta elemesi + app teması kaldırma + ayarlar
> sadeleştirme) ayrı bir **client** task'ında (**REV-70**) uygulanır. Bu doküman repo koduna
> dokunmaz — yalnız öneri + gerekçe üretir.
>
> **Sahibi:** Enes (görsel tasarım) · **Task:** REV-62 · **Bloklar:** REV-70 (uygulama), REV-63
> (mağaza ekranı) · **İlgili:** REV-66 (coin/cüzdan) · **Takım:** Reversi_Game

---

## 1. Özet karar (öneri)

Üç sorunun tümü **birbirine bağlı** — bu yüzden birlikte karara bağlanmalı (2026-07-14 ekip kararı):

1. **Tema ayrımı kalksın → tek nihai görünüm.** `AppThemeId { original, wood }` katmanı
   kaldırılır; taban görünüm **ahşap/parchment shell** (onaylı marka yönü). Marka turkuaz
   accent'i (`#13A99C`) korunur. → **§4**
2. **7 → 5 tahta.** `wood, turkuaz, gece, mermer, cicek` **kalır**; `antrasit` ve `petrol`
   **elenir** (koyu tahta fazlalığı + zayıf/çakışan kimlik). → **§5**
3. **3 ücretsiz + 2 ücretli.** Ücretsiz: `wood` (imza/varsayılan), `turkuaz` (marka/açık),
   `gece` (koyu). Ücretli: `mermer` (Nadir ~1.500), `cicek` (Epik ~3.500). → **§6**

**Dayanak:** Kararlar (a) onaylı ahşap (ceviz+akçaağaç) marka yönü, (b) REV-60 kademe renk
rampası + REV-61 çerçeve aileleri, (c) kod gerçeği (§3: iki katmanlı tema kuplajı) ile
tutarlı gerekçelendirildi. Eleme = **sadeleştirme** (REV-70 başlığı "…+ ayarlar sadeleştirme").

---

## 2. Kapsam ve teslim

REV-62 tanımından üç soru:

1. Hangi tahtalar kalsın, hangileri elensin? → **§5**
2. Kalanlardan hangileri ücretsiz, hangileri mağazada ücretli (coin)? → **§6**
3. Original/wood app teması ayrımı kalksın mı — tek görünüm mü, iki tema mı? → **§4**

**Teslim:** gerekçeli öneri (bu doküman) → ekip kararı → karar `PROGRESS.md`'ye işlenir →
**REV-70** (client) kodu uygular, **REV-63** mağaza vitrinini bu envanterle kurar. Bu doküman
**koda/pubspec'e dokunmaz.**

---

## 3. Mevcut envanter (kod gerçeği — karar buna dayanır)

Kaynak: `lib/core/settings/app_settings.dart`, `lib/core/theme/board_palette.dart`,
`lib/features/settings/widgets/board_theme_grid.dart` + `app_theme_row.dart`.

### 3.1 İki katmanlı tema sistemi (bugün)

- **App teması katmanı** — `AppThemeId { original, wood }`. Uygulama-çapında shell: renk, font,
  arka plan. `original` = teal/cream (Nunito/Baloo2, accent `#13A99C`, coral `#F4552C`);
  `wood` = parchment/ahşap (Marcellus/Lora, gold `#B8860B`). Varsayılan `original`.
- **Tahta teması katmanı** — `BoardTheme { wood, turkuaz, gece, antrasit, petrol, mermer, cicek }`.
  Varsayılan `wood`.

**Kritik kuplaj (`board_theme_grid.dart` + `settings_screen.dart` + `app_settings.dart`):**

| App teması | Görünen tahtalar | Ekstra |
|---|---|---|
| `original` | wood, **turkuaz, gece, antrasit, petrol** | Disk rengi seçici (`CoinColor`) görünür |
| `wood` | wood(=“Ahşap”), **mermer, cicek** | Disk rengi seçici **gizli** |

`setAppTheme()` app teması değişince tahtayı **zorla** uyumlu sete taşır (ör. wood→original
geçişinde mermer/cicek seçiliyse board `wood`'a düşer). Yani bugün **mermer/cicek yalnız wood
temasında, turkuaz/gece/antrasit/petrol yalnız original temasında** erişilebilir; `wood` tahtası
her iki tarafta ortak köprü.

### 3.2 Tahtaların görsel kimliği (kod paletinden)

| Tahta | Tip | Renk hissi | Açık/Koyu | Kimlik gücü |
|---|---|---|---|---|
| **wood** | Asset (`wood-frame/surface`, ceviz+akçaağaç disk) | Sıcak el-işi ahşap | Sıcak-orta | ★★★ imza |
| **turkuaz** | Gradient | Ferah teal (`#15A99C`→`#0C7D72`) | Açık | ★★★ marka rengi |
| **gece** | Gradient | İndigo/mavi-mor gece | Koyu | ★★ belirgin koyu |
| **antrasit** | Gradient | Teal-frame + **gri** surface (melez) | Koyu | ★ zayıf/melez |
| **petrol** | Gradient | Çok koyu teal-yeşil (~siyaha yakın) | Çok koyu | ★★ ama teal ailesi |
| **mermer** | Gradient + **vein overlay** (asset disk) | Cilalı açık gri, zarif | Açık | ★★★ premium |
| **cicek** | Tam asset (`flower-board`, mor/pembe disk) | Rose-gold, çiçek, kutlama | Renkli | ★★★ tam ayrışık |

**Fiyat/mağaza modeli:** Kodda **YOK** (yalnız `CoinColor` disk-renk enum'u; `purchaseItem`
transaction + boş katalog `catalog.ts`). Fiyat = **göreli oran önerisi**, REV-66 coin ekonomisi
netleşince mutlak değerler tek katsayıyla ölçeklenir (REV-61 §5.1 ile aynı disiplin).

---

## 4. Soru 3 — App teması ayrımı: **KALKSIN → tek görünüm** (öneri)

### 4.1 Karar

`AppThemeId { original, wood }` katmanı **kaldırılır**. Uygulama tek bir shell'de birleşir:
**ahşap/parchment görünüm** (bugünkü `wood` app teması taban alınır). Marka turkuaz accent'i
(`#13A99C`) buton/vurgu rengi olarak **korunur** — kaldırılan şey "app teması seçici", "turkuaz
kimliği" değil.

### 4.2 Neden kalksın (gerekçe)

- **Marka yönü net ahşap.** Onaylı görsel yön ceviz+akçaağaç ahşap; REV-60 kademe ünvanları
  ("Zanaat/Lonca") ve REV-61 çerçeveleri (el-işi ahşap-lonca dili) hep bu eksende kuruldu. İki app
  temasını korumak, markanın taban dilini ikiye böler.
- **Sadeleştirme = task'ın amacı.** REV-70 başlığı zaten "Tema elemesi uygulaması **+ ayarlar
  sadeleştirme**". İki katmanlı tema (app teması × tahta teması) kullanıcıya iki iç içe menü sunar;
  çoğu oyuncu "app teması" ile "tahta teması" farkını kavramaz → seçim yükü + kafa karışıklığı.
- **Bakım yükü.** Her ekran bugün iki kez temalanıyor (teal/cream ↔ parchment), iki font seti
  (Nunito/Baloo2 ↔ Marcellus/Lora), disk-renk seçici yalnız original'da → yüzey tutarsız. Tek shell
  bakımı yarıya indirir, yeni ekranlarda (REV-63 mağaza, profil) tek dil.
- **Kuplaj çözülür.** §3.1'deki "hangi tahta hangi app temasında" zorlama kuralı (`setAppTheme`
  board'u zorla değiştiriyor) tamamen kalkar → kalan tahtalar **tek galeride** yan yana, koşulsuz.

### 4.3 Alternatif (ekip için)

Tek görünüm **original (teal/cream) shell** de olabilir. **Ahşap öneriliyor** çünkü marka hafızası
+ REV-60/61 lonca dili ahşap yönünde; teal/cream shell seçilirse REV-60/61'in ahşap-lonca çerçeve
& ünvan dili shell'le zıtlaşır. **Karar ekipte** (bu, tüm uygulamanın taban görünümünü belirleyen
büyük görsel karar — öneri güçlü, onay ekibin).

### 4.4 Yan etki: disk rengi seçici (`CoinColor`)

Bugün disk rengi seçici (turkuaz/turuncu vs klasik) yalnız `original`'da; `wood`/`mermer`/`cicek`
kendi asset disklerini kullanır. Tek görünümde öneri: **her tahta kendi diskini belirler**, ayrı
disk-renk seçici **kaldırılır** (sadeleştirme). Renkli disk isteyen için `turkuaz` tahtası klasik
teal/turuncu diski taşımaya devam eder. → REV-70 uygulama detayı, §7'de not.

---

## 5. Soru 1 — Eleme: **7 → 5 tahta** (öneri)

### 5.1 Karar tablosu

| Tahta | Karar | Gerekçe |
|---|---|---|
| **wood** | ✅ **KAL** (varsayılan) | İmza; asset-tabanlı en zengin tahta; marka çekirdeği. |
| **turkuaz** | ✅ **KAL** | Marka accent rengi (`#13A99C`); tek "ferah açık" tahta; klasik kimlik. |
| **gece** | ✅ **KAL** | Koyu nişin en **belirgin** temsilcisi (indigo gece atmosferi, güçlü isim). |
| **mermer** | ✅ **KAL** | Premium/zarif (vein efekti + asset disk); ayrışık açık-gri kişilik. |
| **cicek** | ✅ **KAL** | Tam ayrışık (rengarenk, çiçek kutlaması); asset kalitesi yüksek. |
| **antrasit** | ❌ **ELEN** | En zayıf kimlik: teal-frame + gri-surface **melez**; `gece` ile koyu-niş çakışması; markaya katkısı yok. |
| **petrol** | ❌ **ELEN** | Çok koyu teal-yeşil; `turkuaz` (açık teal) + `gece` (koyu) zaten açık/koyu-soğuk nişini kapatıyor → marjinal tekrar. |

### 5.2 Neden bu eleme

- **Koyu tahta fazlalığı.** Bugün 3 koyu tahta yan yana: `gece` (mavi-mor), `antrasit` (gri-mavi),
  `petrol` (çok-koyu yeşil). Küçük 88×88 tile'da üçü ayırt edilmesi zor → seçim gürültüsü. Bir
  koyu tahta (`gece`) yeter.
- **Kalan 5'in her biri ayrı kişilik:** imza-ahşap (wood) · ferah-açık marka (turkuaz) · koyu
  (gece) · premium-açık (mermer) · renkli (cicek). Açık/koyu/sıcak/renkli dengesi tam; hiçbiri
  diğerine benzemez. REV-61'in "silüetten hangi çerçeve okunur" ayrışma ilkesiyle aynı ruh.
- **Üretim değeri korunur:** elenen ikisi de saf gradient (asset yatırımı yok); kalanların 3'ü
  asset-tabanlı (wood/mermer/cicek) + 2 güçlü gradient (turkuaz/gece).

### 5.3 Alternatif (ılımlı, 6 tahta)

`petrol` **korunmak** istenirse (turkuaz'ın koyu kardeşi olarak açık/koyu teal çifti):
`antrasit` **kesin elenir**, `petrol` ücretli-Standart (~500) girer. Görsel/ekonomik etki minimal.
**`antrasit`'in elenmesi her iki senaryoda da net** — tartışmalı olan yalnız `petrol`.

---

## 6. Soru 2 — Ücretsiz vs ücretli (coin)

### 6.1 Karar tablosu (5 tahta senaryosu)

| Tahta | Erişim | Fiyat sınıfı | Konumlama |
|---|---|---|---|
| **wood** | 🆓 Ücretsiz (varsayılan) | — | İmza/başlangıç; herkeste açık. |
| **turkuaz** | 🆓 Ücretsiz | — | Marka rengi + tek açık-ferah tahta; ilk alternatif. |
| **gece** | 🆓 Ücretsiz | — | Koyu-mod temel konfor tercihi → en az bir koyu tahta ücretsiz olmalı. |
| **mermer** | 💰 Ücretli | **Nadir ~1.500** | Zarif premium his; vein efekti → satın almaya değer. |
| **cicek** | 💰 Ücretli | **Epik ~3.500** | En zengin/ayrışık; çiçek kutlama animasyonu → premium tepe. |

### 6.2 Neden bu dağılım

- **3 ücretsiz = dengeli başlangıç seti:** imza (wood) + açık-marka (turkuaz) + koyu (gece). Yeni
  oyuncu hiç coin harcamadan sıcak/açık/koyu üç farklı ruh hâli bulur → erken tatmin.
- **2 ücretli = REV-63 mağazasının ilk tahta vitrini.** REV-61'in satılık çerçeveleriyle (Carved
  Walnut, Marble & Gold, Champion Laurel…) birlikte mağazaya somut envanter verir. Tahtalar tüm
  oyun boyunca görünür (çerçeveden büyük yüzey) → çerçevelerle **aynı ya da bir tık üstü** fiyat
  makul: `mermer` Nadir, `cicek` Epik.
- **Marka tutarlılığı:** ücretsiz set marka çekirdeğini (ahşap + turkuaz) taşır; ücretli set
  "ekstra stil" (mermer zarafeti, çiçek şenliği) → "sahip olunan taban" ile "satın alınan süs"
  ayrımı REV-61 çerçeve mantığıyla birebir hizalı (kazanılan prestij ≠ satın alınan stil).

### 6.3 Fiyat sınıfları (REV-61 §5.1 ile aynı — coin ekonomisi netleşince ölçeklenir)

> ⚠️ Kodda mağaza fiyat emsali **YOK** (REV-66 yalnız `purchaseItem` + boş katalog). Aşağısı
> **göreli oran**; mutlak coin değeri, maç-başı kazanım oranı netleşince **tek katsayıyla**
> ölçeklenir. Önemli olan sınıflar arası oran.

| Sınıf | Öneri (coin) | Bu task'ta |
|---|---|---|
| Standart | ~500 | (6-tahta senaryosunda `petrol`) |
| Nadir | ~1.500 | `mermer` |
| Epik | ~3.500 | `cicek` |

REV-61 çerçeve fiyat sınıflarıyla **birebir aynı** rampa → mağaza tek tutarlı fiyat dili.

---

## 7. Uygulama notları (client task REV-70 için)

Bu doküman koda dokunmaz; aşağısı REV-70'in uygulayacağı değişikliklerin **haritası**:

- **App teması kaldırma:** `AppThemeId` enum + `setAppTheme()` + `AppThemeRow` widget kaldırılır;
  tek shell (ahşap/parchment) sabitlenir. `board_theme_grid.dart`'taki koşullu tahta listesi
  (original 5 / wood 3) → **tek sabit galeri** olur.
- **Tahta elemesi:** `BoardTheme`'den `antrasit` + `petrol` çıkarılır (5 değer kalır). Kayıtlı
  ayarı elenen bir tahta olan kullanıcı → varsayılan `wood`'a **güvenli göç** (migration) gerekir.
- **Kilit/mağaza durumu:** `mermer` + `cicek` "kilitli" başlar; `purchaseItem` (REV-66) ile açılır.
  Seçici, REV-61 §6.2 deseniyle kilitli tahtaları gri + coin rozetiyle gösterir.
- **Disk rengi seçici:** ayrı `CoinColor` seçici kaldırılır; her tahta kendi diskini belirler (§4.4).
- **Ayarlar sadeleştirme:** app teması satırı + disk-renk satırı gittiği için ayarlar ekranı
  belirgin kısalır (REV-70 kapsamının "sadeleştirme" yarısı).
- **Mağaza vitrini (REV-63):** ilk tahta envanteri = `mermer` (Nadir), `cicek` (Epik); REV-61
  çerçeveleriyle aynı fiyat rampasında listelenir.

---

## 8. Ekip kararı için açık noktalar

1. **Tek görünüm shell'i:** ahşap/parchment (önerilen) mi, teal/cream (original) mi? Bu, tüm
   uygulamanın taban görünümünü belirler (§4.3).
2. **Eleme derinliği:** 5 tahta (antrasit+petrol eler — önerilen) mi, 6 tahta (yalnız antrasit
   eler, petrol Standart-ücretli kalır) mı? (§5.3)
3. **Ücretsiz/ücretli sınırı:** 3 ücretsiz + 2 ücretli (önerilen) onaylanıyor mu? `gece` yerine
   `mermer` ücretsiz olsun istenirse koyu-mod ücretli kalır (önerilmez — koyu konfor temel erişim).
4. **Fiyat mutlak değerleri:** §6.3 oranları onay; mutlak coin, kazanım oranı (henüz tanımsız)
   netleşince — hangi task coin ekonomisini tanımlayacak? (REV-66 kapsamı mı genişleyecek?)
5. **Disk rengi seçici:** kaldırılsın (önerilen, §4.4) mı, tek görünümde korunsun mu?

**Karar sonrası:** onaylanan cevaplar `PROGRESS.md`'ye işlenir; **REV-70** uygular, **REV-63**
mağaza vitrinini bu envanterle kurar.
