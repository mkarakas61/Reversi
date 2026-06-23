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
