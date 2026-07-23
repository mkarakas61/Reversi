# PROMPT — Reversi taşı (3B) + bozuk-para çevirme animasyonu

> Blender MCP bağlıyken (mcp__blender__* araçları yüklü) Claude Code'a aşağıdaki
> prompt'u yapıştır. Önce `get_scene_info` ile bağlantıyı doğrulayıp boş sahneden başla.

---

Blender'da (MCP üzerinden `execute_blender_code` ile) bir **Reversi / Othello oyun taşı**
modelle ve klasik "bozuk parayı baş parmakla fırlatıp havada döndürme" animasyonunu kur.
Önce mevcut sahneyi temizle (default cube/light/camera'yı sil), sonra yeniden kur.

## 1) Taş modeli (rijit, hacimli — deforme YOK)
- Disk formu: silindir tabanlı, **çap ≈ 2.0 birim, kalınlık ≈ 0.42 birim** (gerçek
  Othello pulu oranı — ince değil, elle tutulur hacimde).
- **Kenar bizotu (bevel):** dış kenar keskin değil, yumuşak pahlı; rim'de ~0.06 birim
  bevel, 3-4 segment.
- **Hafif kubbe:** her iki yüz düz değil, çok hafif dışbükey (subdivision + hafif
  şişirme). Abartma — hemen hemen düz ama ışığı yakalayan bir kavis.
- **İki yüz iki renk:** bir yüz **siyah**, diğer yüz **beyaz** (klasik Reversi pulu).
  Yüzeyleri ayrı material slotlarına ata (yüz seçimini normal yönüne göre yap).
- Shade smooth uygula, ama bevel kenarları için Weighted Normal / auto-smooth aç ki
  kenar çizgisi net kalsın (yumuşak ama tanımlı hacim).

### Materyaller (Principled BSDF)
- **Siyah yüz:** koyu, satin/mat — roughness ~0.35, hafif specular, tam siyah değil
  (base color ~#0a0a0a). Ucuz plastik parlaması olmasın.
- **Beyaz yüz:** kirli-beyaz fildişi (~#f2efe6), roughness ~0.4.
- **Rim (kenar):** nötr gri, iki yüz arasında ince bir geçiş şeridi.

## 2) Animasyon — "thumb-flick coin toss" (keyframe tabanlı, fizik sim değil)
Amaç: baş parmakla kenarına vurulup fırlatılan bir bozuk paranın **havada defalarca
takla atarak** dönüp yere düşmesi. Tempo genelde ağır/ağırbaşlı olsun ama havadaki
dönüş kendi içinde hızlı (paranın karakteri bu).

- **Süre:** ~2.5 sn, **30 fps** (≈ 75 frame). fps'i sahnede ayarla.
- **Yörünge (konum):** parabolik. Zeminde yatık başlar → ani yukarı impuls ile fırlar →
  tepe noktası → aşağı düşer → zemine iner. Yükseklik ~4-5 birim. Konum Z eğrisine
  yerçekimi hissi ver (çıkış hızlı, tepede yavaş, iniş hızlanan) — F-curve'lere
  ease uygula.
- **Dönüş (asıl efekt):** taş **kendi çapından geçen yatay bir eksende** takla atar
  (tepe-takla / end-over-end), tırtıl gibi değil. Uçuş boyunca **5-7 tam tur** (1800°–2520°).
  Dönüş sabit hızda (havada momentum korunur) — konumdan farklı olarak lineer interpolation
  eğilimli, girişte küçük bir hızlanma.
- **Hafif eksen sapması:** gerçek para gibi dursun diye çok küçük bir ikincil eğim/tumble
  ver (ana eksen dışında ~5-8° salınım) — mekanik/robotik görünmesin.
- **İniş + oturma (rigid, deforme yok):** yere değince küçük bir sekme (bir kısa zıplama,
  ~0.4 birim) + sönümlenen bir yalpalama (wobble) ile durur. Son karede yüzlerden biri
  yukarı bakacak şekilde tam düz otursun.

## 3) Sahne / kamera / ışık / render
- **Zemin:** sonsuz düzlem yerine geniş, hafif desenli nötr yüzey; yumuşak temas gölgesi.
- **Kamera:** 3/4 açı, taşı biraz alttan-yandan gören, taklaları iyi yakalayan konum;
  hafif tele (35-50mm) perspektif.
- **Işık:** studio 3-nokta VEYA yumuşak HDRI; siyah ve beyaz yüzü de okutan, sert olmayan
  gölge. Beyaz yüz patlamasın, siyah yüz de tıkanmasın.
- **Motion blur:** render'da aç (havadaki hızlı dönüş için) — ama tumble okunur kalsın.
- **Render motoru:** Cycles (kaliteyse) veya EEVEE (hızsa) — sen seç, gerekçesini yaz.

## 4) Çıktı
- `.blend` dosyasını **`blender/models/reversi_tas_coinflip.blend`** olarak kaydet.
- Bir **turntable değil**, tek bozuk-para atışı sekansı render et → PNG frame'leri
  `blender/renders/` altına, mümkünse mp4/gif olarak birleştir.
- Bitince: model boyutları, kaç tur döndüğü, süre, render motoru ve dosya yollarını özetle.

## Kısıtlar
- **Deformasyon YOK** — taş katı cisim, esneme/squash yok (rijit hacim isteği).
- Kararsız kaldığın estetik seçimde (renk tonu, tur sayısı, tempo) uydurma — **sor**.
- Adım adım ilerle: önce modeli kur ve tek frame render'la göster, onay al, sonra
  animasyonu ekle.
