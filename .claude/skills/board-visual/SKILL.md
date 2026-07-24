---
name: board-visual
description: "Reversi tahtasında (board) taş-kare-grid görsel hiza doğrulaması ve perspektif/asset tuzakları. USE WHEN: (1) board yüzeyi, kare deseni, grid, taş (CoinView/disc), perspektif/tilt/Transform veya _squareToQuad kodu değişiyor, (2) Blender veya başka bir yerde üretilmiş board/tahta/pul asset'i (assets/wood/*.png, board görseli) oyuna entegre ediliyor veya değiştiriliyor, (3) kullanıcı 'taş kareye oturmuyor', 'hiza kaymış', 'denk gelmiyor', 'eğimden' gibi bir şey söylüyor, (4) yeni bir board teması/varyantı ekleniyor. Her board/asset/tasarım değişikliğinden SONRA çalıştırılır — analyze+test yeşil olsa bile hiza gözle doğrulanmadan iş bitmiş sayılmaz."
---

# Reversi — Board Görsel Hiza Doğrulaması

Amaç: Tahta yüzeyi (kareler + grid) ile taşların **gerçek cihazda gözle** hizalı
oturduğunu doğrulamak. `flutter analyze` + `flutter test` bunu YAKALAMAZ — hiza
bir render/perspektif sorunudur, ancak ekran görüntüsüyle görülür.

> Kök ders (2026-07-24): FAZ B'de offline board'a satranç deseni eklendi;
> analyze+test yeşildi ama taşlar karelere oturmadı. Sebep: kareler bir
> Transform içinde, taşlar Transform dışında ayrı bir koordinat sisteminde
> konumlanıyordu. Perspektif eğimi bu kaymayı büyüttü. İnce grid çizgileri
> döneminde görünmeyen hata, dolu kareler gelince ortaya çıktı.

## Altın kural (önce mimariyi doğrula)

**Board yüzeyi (kareler/grid/asset) ile taşlar AYNI `Transform`'un TEK child
ağacında olmalı** — böylece ikisi birlikte, aynı perspektiften geçer ve
otomatik hizalı kalır. Doğru desen `lib/features/online/widgets/online_board.dart`:
board görseli `Container`'ın `DecorationImage`'ı, taşlar aynı Container'ın
`Padding`+`Row/Column` child'ı; hepsi tek `Transform` child'ı. Kod yorumu:
*"share a single RenderObject — this keeps them aligned under the perspective transform."*

Eğer taşlar Transform DIŞINDA, sadece hücre merkez-noktası `project()`/matris ile
ekran koordinatına çevrilip oraya düz bir widget konuyorsa → **kayma kaçınılmaz**.
Bunu görürsen, hiza checklist'ine geçmeden mimariyi düzelt.

## Adımlar (sırayla)

1. **Uygulamayı çalıştır** (bir emulator/simulator açık olmalı)
   - Android: `flutter run -d <emulator-id>`  ·  iOS: simulator boot + `flutter run -d <sim-id>`
   - Değişikliğin ilgili olduğu board'u aç:
     - Offline / ahşap tema: **Tek Oyuncu** (ilgili tahta teması Ayarlar'dan seçili olmalı — satranç deseni yalnızca ahşap temada, `palette == null`, aktiftir).
     - Online: **Online Oyna**.
   - Kaydedilmiş bir oyun varsa dolu tahta hizayı daha iyi gösterir.

2. **Tam çözünürlük screenshot al ve board'u kırp** (küçük screenshot hizayı gizler)
   - iOS: `xcrun simctl io <sim-id> screenshot <path>.png`
   - Android: `adb -s <id> exec-out screencap -p > <path>.png`
   - `sips -c <h> <w> --cropOffset <y> <x> in.png --out crop.png` ile board bölgesini kırpıp Read ile yakından incele.

3. **Hiza checklist** (her maddeyi ekran görüntüsünde doğrula)
   - [ ] Taşlar karelerin **görsel (alan) merkezinde** mi — sağa/sola/yukarı/aşağı kayma yok mu?
   - [ ] Grid çizgileri kare kenarlarıyla örtüşüyor mu?
   - [ ] **Üst (uzak) sıralarda** kayma alt sıralardan fazla mı? (Fazlaysa perspektif/koordinat-sistemi hatası işareti.)
   - [ ] Taş boyutu hücreye göre doğru mu — komşu kareye taşmıyor mu (özellikle **dikey**)?
   - [ ] Köşe ve kenar hücreleri de hizalı mı?
   - [ ] Başlangıç 4 taşı + oynanan taşlar + hint noktaları hepsi aynı grid'de mi?

4. **Bilinen tuzaklar** (kayma görürsen sırayla kontrol et)
   - **Transform içi/dışı ayrımı** (en sık): yukarıdaki altın kural. Taşlar ve yüzey ayrı ağaçta mı?
   - **Nokta ≠ alan merkezi:** Projektif dönüşümde bir karenin merkez-noktasının izdüşümü, karenin görünen 4-köşe trapezinin görsel merkeziyle çakışmaz. Taşı merkez-noktaya koymak perspektifte kaydırır.
   - **Dikey perspektif sıkışması:** Taş boyutunu yalnızca yatay hücre genişliğinden türetip dikey sıkışmayı yok saymak → taş dikeyde büyük görünüp komşu kareye taşar.
   - **Asset aspect ≠ kare:** Baked-grid asset (ör. board-crop.png 754:713) kare bir alana `BoxFit.fill` ile konursa gerilir; grid ile taş hücresi kayar.
   - **Baked-grid fraction'ları:** board-crop / marble / flower gibi asset'lerde grid `online_tokens.dart`'taki `gridLeft/Top/Right/Bottom` fraction'larıyla hizalanır; yeni/değişen asset'te bu fraction'lar **cihazda fine-tune** edilir (yorumlar: "measured from the baked-in checkerboard squares … fine-tuned on-device").

5. **Rapor**: Kayma varsa yön + miktar + hangi sıralar/hücreler; ekran görüntüsünü göster; hangi tuzağa denk geldiğini belirt. Temizse "hiza doğrulandı" de ve hangi board/temayı kontrol ettiğini yaz.

## Notlar
- Bu skill düzeltme yapmaz; hizayı doğrular ve kök nedeni işaret eder. Kod düzeltmesi için önce `arch` skill'i (klasör kuralları), sonra `smoke` (analyze+test).
- Perspektif matematiği: `wood_board.dart` `_squareToQuad` (offline 4-köşe quad) ve `online_board.dart` `rotateX(-20°)+setEntry(3,2,...)` (online tilt).
- Doğru referans mimari her zaman `online_board.dart` — yeni board işlerinde onu örnek al.
