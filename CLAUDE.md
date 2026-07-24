# Reversi (Flutter)

## Platform paritesi (Android ↔ iOS)
Geliştirme genelde Android için yapılır. `lib/` ortaktır → kopyalama YOK.
Native bir dosya (manifest / Info.plist / gradle / pbxproj / channel) değişirse
iOS karşılığını **soru sormadan otomatik uygula**, sonra sade dille onayla
("Android+iOS'a uygulandı" / "iOS'ta karşılığı yok: sebep"). Dosya yolu yazma.

Projeye özel (bunları bil):
- `ringer_mode_service.dart` zil modu = Android-özel, iOS'ta karşılığı YOK.
- Bundle ID bilerek farklı (`com.mustafakarakas.reversi` ≠ `tr.sidre.reversi`) — dokunma.
- Versiyon + ikon zaten otomatik (pubspec) — elle senkron gerekmez.

## Board mimari kuralı (taş-kare hizası — pazarlıksız)
Tahta yüzeyi (kareler/grid/asset) ile taşlar **AYNI `Transform`'un TEK child
ağacında** olmalı; ikisini ayrı koordinat sisteminde (biri Transform içi, diğeri
`project()` ile ekran-space Positioned) konumlama YASAK — perspektif eğimi altında
taşlar karelere oturmaz. Doğru referans: `online_board.dart` (board görseli +
taşlar tek `Transform` child'ı; "share a single RenderObject"). Board/tahta/pul
**asset veya perspektif/grid/taş kodu her değiştiğinde**, analyze+test yeşil olsa
bile, `board-visual` skill'i ile emulator'da hizayı gözle doğrula — bitmiş saymadan önce.
