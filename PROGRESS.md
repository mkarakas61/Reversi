# REVERSI — PROJE İLERLEME DOSYASI

> **BU DOSYA PROJENİN TEK GERÇEK KAYNAĞIDIR.**
> Her yeni oturumda (session) yapılacak İLK İŞ bu dosyayı okumaktır.
> Her değişiklik, karar, fikir ve iptal buraya işlenir — sormadan, onay beklemeden.
> Dosyayı güncellemek Claude'un sorumluluğudur; her anlamlı adımdan sonra güncellenir.

Son güncelleme: **2026-07-24** · Son commit: `826d7fd` · Sürüm: `0.1.0+1`

---

## 1. PROJE ÖZETİ

- **Ne:** Flutter ile Reversi (Othello) oyunu. Android-öncelikli, Play Store hedefli.
- **Repo:** `git@github.com:mkarakas61/Reversi.git` (SSH ile push, anahtar kayıtlı)
- **Paket adı:** `com.mustafakarakas.reversi` — **DEĞİŞTİRİLEMEZ** (Play Store + IAP + Firebase buna bağlı). iOS bundle id bilerek farklı: `tr.sidre.reversi` — dokunma.
- **Modlar:** Tek oyuncu (3 zorluk, AI), iki oyuncu (süreli/süresiz), **online** (Firebase, Google girişi).
- **Ekip:** Mustafa (ürün sahibi, kararlar, cihaz testi, Done'a çekme) · Enes Yasin Gedik (**görsel tasarımlar + seslendirme geliştirmeleri** — Linear task'ları bu alanlardan atanır) · Claude (tek kod yazan, board yönetimi). Ana yapı/kodlama task'ları Linear'da Mustafa'ya atanır, kodu Claude yazar.

## 2. EKİP ÇALIŞMA KURALLARI (KESİN)

1. **Kod akışı:** Claude kodu yazar → `flutter analyze` temiz + `flutter test` yeşil (şu an **72 test**) → `main`'e direkt push → Linear issue'yu Türkçe yorumla **In Review**'a taşır. **Done'a ASLA Claude çekmez** — yalnız Mustafa, cihaz testinden sonra.
2. **Onay düzeni:** Mustafa approve-then-implement çalışır — önce öner/planla, onay gelince uygula. Dışa dönük işlerde (prod deploy, functions/rules) mutlaka önce ONAY al.
3. **Linear:** Workspace `reversi-game`, takım **Reversi_Game** (REV). Kolonlar: Todo → In Progress → **In AI** → In Review (Test) → Done. Mustafa/ekip yalnız yorum yazar ve issue'yu In Progress'e sürükler; board hareketleri ve kod Claude'da (interaktif oturum ya da `reversi-build-agent` rutini).
   - **"In AI" koordinasyon kilidi (2026-07-15 eklendi):** interaktif Claude oturumu ile otonom rutin AYNI ANDA çalışabildiği için, bir işe gerçekten başlarken (kod yazmadan hemen önce) issue **In Progress → In AI**'a çekilir — tek tek, toplu değil. Bu, işi diğer ajanın "alınacaklar" listesinden çıkarır. **In AI'da olan bir issue'ya asla dokunulmaz** (başka bir ajan üzerinde çalışıyordur). Bitince **In AI → In Review**. Karar bekleyen iş In Progress'e değil **Todo'ya** geri döner (yorumla).
4. **Türkçe iletişim:** Mustafa ile her şey Türkçe. Linear yorumları Türkçe.
5. **⚠️ GIT DİSİPLİNİ (23 Haziran kazasından ders):** PR açmadan önce **mutlaka güncel main'den dallan** (`git pull`). Enes'in PR #4'ü 11 gün eski koddan dallandığı için online/ses/istatistik tamamen silindi (bkz. §5). Merge'lerden önce silinen dosya var mı diye diff kontrol et.
6. **Platform paritesi (CLAUDE.md):** `lib/` ortak; native dosya (manifest/Info.plist/gradle/pbxproj/channel) değişirse iOS karşılığı sorulmadan uygulanır, sade dille raporlanır. `ringer_mode_service.dart` Android-özel, iOS karşılığı YOK.

## 3. MEVCUT DURUM (2026-07-08)

### Yayında / main'de çalışır durumda
- **Offline oyun:** tek oyuncu (kolay/normal/zor AI), iki oyuncu (30sn/1dk/3dk/süresiz), geri alma, devam etme, oyun hızı.
- **Online oyun (REV-31..51, tamamı Done):** Google girişi, profil/XP/seviye, eşleşme (matchmaking), gerçek zamanlı oyun, kopma tespiti (~10-15sn'de rakip kazanır), hızlı reconnect, sunucu-doğrulamalı XP ödülü, güvenlik kuralları prod'da.
- **Temalar (Enes):** Uygulama teması `original`/`wood`; tahta temaları wood/turkuaz/gece/antrasit/petrol + wood temasında mermer/**Çiçek** (çiçek kutlamalı). Disk çevirme "flip wave" animasyonu.
- **Ses:** efektler + menü/oyun müziği, ayarlardan aç/kapa, Android zil modu takibi.
- **İstatistikler:** Tek oyuncu istatistikleri (REV-52 yerleşimi: zorluk seçiminde Geri'nin altında), online istatistik ekranı (profil üzerinden).

### Test durumu
- 84/84 Flutter testi + 25/25 functions testi yeşil. Release APK derleniyor.
- Restorasyon sonrası (452b102) **telefona kuruldu, açılış + otomatik Google oturumu doğrulandı**. ✅ **2 hesaplı tam online smoke test YAPILDI (2026-07-24, `9721dbf` build, telefon+emülatör):** misafir↔misafir ve misafir↔imzalı eşleşme/oyun sorunsuz bitti, istatistikler işliyor. Misafir online giriş fix'i (`c2269a3`) + prod deploy doğrulandı.
- Ekip test APK'sı: `~/Desktop/Reversi-0.1.0-81e9dd5.apk` (2026-07-23, release-imzalı, universal, GitHub main ile aynı — `81e9dd5`).

## 4. MİMARİ

### Klasör yapısı (feature-first, Enes'in refactor'u + restorasyon)
```
lib/
  main.dart                    # Firebase init + scope'lar + runApp
  firebase_options.dart
  app/reversi_app.dart         # MaterialApp, routeObserver, rotalar
  core/
    game/                      # reversi_game, ai_player, game_settings
    l10n/app_strings.dart      # elle yazılmış TR/EN (gen-l10n bilerek YOK)
    models/                    # online_game, online_stats, xp_level, game_stats
    services/                  # auth, profile, matchmaking, online_game,
                               # online_stats, sound, ringer_mode, stats_storage,
                               # game_storage, settings_storage, analytics
    auth/auth_scope.dart  ·  profile/profile_scope.dart
    settings/app_settings.dart # SettingsController/Scope
    theme/                     # game_colors, game_text, board_palette,
                               # coin_palette, wood_theme
  features/
    board/                     # wood_board (+flip animasyonu), board_move
    game/game_screen.dart      # tek/iki oyuncu ekranı (SFX+istatistik bağlı)
    menu/main_menu_screen.dart # + profile_chip (giriş), online butonu girişliyken
    online/screens/            # matchmaking, opponent_preview, online_game,
                               # online_stats
    online/online_match_screen.dart  # Enes'in mock ekranı — KULLANILMIYOR ama
                               # silinmedi (wood online tasarımı kaynak olarak durur)
    profile/  ·  settings/  ·  stats/
  shared/widgets/              # coin_view, info_popup
functions/                     # TypeScript Cloud Functions (Node 22, europe-west1)
firestore.rules  ·  firestore.indexes.json
```

### Firebase (proje `reversi-3a506`, hesap mustafakarakas1071@gmail.com, Blaze)
- **Firestore:** `users/{uid}` (kimlik client-yazılır; xp/level/online SADECE Functions), `users/{uid}/history/{gameId}` (REV-54, maç geçmişi, owner-read/Functions-write), `leaderboards/{weekId}/players/{uid}` (REV-55, haftalık sayaçlar, signedIn-read/Functions-write), `matchmaking/{uid}` bilet, `games/{id}` (64 karakterlik "b/w/-" board string'i, heartbeat `lastSeen` 3sn, kopma eşiği 10sn).
- **Functions:** `onMatchmakingTicketWritten` (eşleştirme, self-heal), `onGameFinished` (moves[] replay doğrulaması + XP/level/coin/istatistik/history/leaderboard ödülü, idempotent, misafiri atlar — REV-57), `sweepAbandonedGames` (5dk'da bir, iki taraf da kopmuşsa iptal), `purchaseItem` (callable, coin ile mağaza satın alma — REV-66, katalog şu an boş), `ping`. Saf yardımcılar: `guest.ts` (`isGuestUser`/`isGuest`), `leaderboard.ts` (`weekId`), `catalog.ts` (`catalogItem`, boş katalog — REV-61/62/63 tasarımları gelince doldurulacak).
- **Deploy:** `cd functions && npm test` (24 test) → `firebase deploy --only functions --force --project reversi-3a506 --account mustafakarakas1071@gmail.com`. Rules/index: `--only firestore:rules` / `firestore:indexes`. **Firebase'de HER ZAMAN `--account` ver** (CLI varsayılanı yanlış hesap: mustafamihmandar). ✅ REV-54/55/56/57 + REV-66 **prod'a deploy edildi (2026-07-24)** — `onGameFinished` güncellendi (history/leaderboard/misafir istisnası/coin canlı), `purchaseItem` oluşturuldu, kurallar+index yayında.
- **google_sign_in v7:** `serverClientId` = web OAuth client id, `auth_service.dart` içinde hardcoded (public, güvenli).
- `google-services.json` gitignored — gerekirse `flutterfire configure` ile yeniden üret (flutterfire: `~/.pub-cache/bin`).
- npm cache bozuk (EACCES) → `npm install --cache /tmp/reversi-npm-cache`. Emulator için Java: Android Studio JBR (`/Applications/Android Studio.app/Contents/jbr/Contents/Home`).

### AI parametreleri (onaylı — Mustafa'ya sormadan DEĞİŞTİRME)
- Kolay: tamamen rastgele geçerli hamle. Normal: 1-ply pozisyon+mobilite, ~%30 rastgele sapma. Zor: alpha-beta derinlik 5 + frontier/faz değerlendirme + ≤12 boşlukta kesin endgame. AI düşünme gecikmesi oyun hızı ayarına bağlı.

## 5. GEÇMİŞ / ÖNEMLİ OLAYLAR

| Tarih | Olay |
|---|---|
| Haz başı 2026 | Proje Codex'ten devralındı; AI dengeleme, ahşap 3D tasarım, ayarlar, süreli mod, ses, istatistik ekranları. |
| 2026-06-14..18 | **Online epic (REV-31..51)** uçtan uca yazıldı, prod'a deploy edildi, 2 cihazla doğrulandı. REV-48 kopma + composite index düzeltmesi (`6fac56a`), süpürme fonksiyonu (`498dddf`), REV-51 kuralları canlı. Functions test runner düzeltildi: 0→18 test (`49145ed`). |
| 2026-06-18 | REV-52: tek oyuncu istatistikleri ana menüden zorluk seçimi altına taşındı (`860ca5d`). |
| 2026-06-19 | Faz 2 planlandı (REV-53..59, §7). Fantastik Mod + Mağaza fikri ekip kararıyla İPTAL (§8). |
| 2026-06-23 | ⚠️ **KAZA:** Enes'in PR #4'ü (12 Haziran'dan dallanmış) feature-first refactor yaparken **online + ses + istatistik + profili sildi**. Üstüne PR #5–#9 ile temalar/animasyonlar geldi (bunlar değerli ve korundu). |
| 2026-07-08 | **RESTORASYON (`452b102`):** silinen her şey yeni feature-first yapıya taşınarak geri getirildi; Enes'in tüm işleri korundu. 72 test yeşil, release APK OK, telefona kuruldu. Ekip APK'sı masaüstünde. |
| 2026-07-14 | **Epic 12 planlandı** (proje "12 · Profil, Tasarım & Mağaza", REV-60..72): profil ünvan/çerçeveleri, tema elemesi, coin+IAP mağazası. Görev dağılımı Enes/Mustafa olarak yapıldı; kararlar §7'de. |
| 2026-07-15 | Enes'in workspace'te zaten kayıtlı olduğu görüldü (argedikas@gmail.com, 21 Haziran'dan beri). REV-60..65 ona atandı; Faz 2'de atanmamış kalan REV-54..59 da REV-53 düzeniyle Mustafa'ya atandı. Artık Todo/In Progress/In Review'da atanmamış hiçbir task yok. |
| 2026-07-15 | `reversi-build-agent` rutini güncellendi: artık her çalıştırmada önce PROGRESS.md'yi okuyor, işini bitirince güncelliyor; ve yalnız Mustafa'ya atanmış In Progress issue'ları işliyor (Enes'inkilere/atanmamışlara dokunmuyor). |
| 2026-07-15 | Board'a **"In AI"** koordinasyon durumu eklendi (In Progress ile In Review arası). İnteraktif Claude oturumu ve otonom rutin aynı anda çalışabildiği için, işe başlarken issue hemen In AI'a çekilir (kilit) — böylece ikisi aynı task'a çakışmaz. Rutin bunu uygulayacak şekilde güncellendi; interaktif oturumlar da aynı kurala uyacak (bkz. §2.3). Rutin çalışma saatleri de günde 4'e çıkarıldı: `0 0,6,12,18 * * *`. |
| 2026-07-15 | Mustafa'nın tüm Todo task'ları (Faz 2 + Epic 12, 14 issue) toplu olarak In Progress'e çekildi; Enes'in çıktısına bağımlı 6 Epic 12 task'ı (REV-67..72) yorumla bloklu bırakıldı, çalışılabilir 8 tanesi (REV-53..59, REV-66) sırayla ele alınmaya başlandı. |
| 2026-07-15 | **REV-53 (misafir online oyun, client) tamamlandı, In Review'a taşındı.** Firebase Anonymous Auth (`AuthService.signInAnonymously`), `Profile.isGuest` + local-only misafir profili (Firestore doc YOK), `GuestIdentityService` (Misafir-XXXX adı, SharedPreferences), ana menüde "Online Oyna" artık her zaman görünür → girişsizken Google/Misafir seçim sheet'i, matchmaking biletine `isGuest` alanı, profil çipi + profil ekranında misafir upsell'i. 74 test yeşil (2 yeni). |
| 2026-07-15 | **REV-54/55/56/57 (server: maç geçmişi, haftalık leaderboard, misafir istisnası, kurallar) tamamlandı, In Review'a taşındı.** `finish_game.ts`: `admin.auth().getUser` ile otoriter misafir kontrolü (`guest.ts`, client bayrağı asla güvenilmez) — misafire `users/{uid}` doc'u hiç açılmıyor; imzalı oyuncuya `users/{uid}/history/{gameId}` (REV-54) ve `leaderboards/{weekId}/players/{uid}` (REV-55, ISO hafta `leaderboard.ts`) yazımı eklendi. `firestore.rules`'a history (owner-read) + leaderboards (signedIn-read) kuralları eklendi; ek index gerekmedi (tekil-alan sıralama otomatik). 24/24 functions testi yeşil (6 yeni). **Henüz prod'a deploy edilmedi — Mustafa onayı bekliyor.** |
| 2026-07-15 | **REV-58 (gelişim grafikleri, client) tamamlandı, In Review'a taşındı.** Online istatistik ekranına `ProgressHistoryService` (`users/{uid}/history` stream) ile beslenen iki yeni bölüm: galibiyet oranı trendi (LineChart, son-20 hareketli pencere) ve haftalık aktivite (BarChart, galibiyet/kayıp/beraberlik yığılı renk kırılımı, son 8 hafta). Misafirde bu ekran artık paylaşılan `GuestUpsellCard` widget'ını gösteriyor (profil ekranındaki özel sınıf ortak widget'a taşındı — DRY). 77 test yeşil (3 yeni). XP/seviye eğrisi kararlı şekilde eklenmedi (§8). |
| 2026-07-15 | **REV-59 (lider tablosu ekranı, client) tamamlandı, In Review'a taşındı — Faz 2'nin (proje 11) 7 issue'sunun de son'u.** `LeaderboardService`: Tüm Zamanlar (`users` `orderBy('xp')`/`orderBy('online.wins')`) + Haftalık (`leaderboards/{weekId}/players` `orderBy('xpGained')`/`orderBy('wins')`, weekly'de "Seviye" sekmesi o haftaki XP kazancını gösterir — haftalık seviye kavramı olmadığı için en yakın karşılık). `weekId(DateTime)` Dart tarafı `functions/src/leaderboard.ts` ile birebir mirror (4 unit test). Yeni `leaderboard_screen.dart`: Periyot×Metrik `SegmentedButton` seçimi, ilk 50 satır + "senin sıran" kartı (rank = kendi değerinden büyük kayıt sayısı + 1, Firestore `count()` aggregate sorgusu; eşitlik/tie-break v1'de basitleştirildi). Ana menüde profil varsa (misafir dahil) "Lider Tablosu" girişi; misafir tıklarsa `GuestUpsellCard`. 84 test yeşil (7 yeni: weekId 4 + LeaderboardEntry 3). |
| 2026-07-15 | **REV-66 (sunucu: coin açılışı + cüzdan/mağaza altyapısı) tamamlandı, In Review'a taşındı — Epic 12 kod sırasının ilk halkası.** `finish_game.ts`: coin ödülü açıldı (`earnedCoins`, galibiyet 10/beraberlik 5/mağlubiyet 2), **back-fill YAPILMADI** (bugünden itibaren sayılır — bu bir ürün kararıdır, Mustafa isterse ayrı bir migration ile geriye dönük eklenebilir). Yeni `purchaseItem` callable Function: transaction ile bakiye kontrolü + düşme + `ownedItems`'a ekleme, zaten-sahip/yetersiz-bakiye hataları. Yeni `catalog.ts` — **katalog şu an bilerek BOŞ**, REV-61 (çerçeveler)/REV-62 (tahtalar)/REV-63 (mağaza tasarımı) teslim edilince REV-68/70'te doldurulacak; o ana kadar her satın alma "not-found" döner. `coins`/`ownedItems`/`equipped` alanları zaten mevcut kural mimarisiyle Functions-only (client update kuralı yalnız `displayName`/`photoUrl`/`updatedAt`'e izin veriyor) — kural değişikliği gerekmedi. 25/25 functions testi yeşil (1 yeni). **Henüz prod'a deploy edilmedi.** |
| 2026-07-15 | **Düzeltme:** REV-67..72 yanlışlıkla In Progress'te bırakılmıştı (bloklu olduklarını sadece yorumla belirtmiştim, board'da taşımamıştım) — rutin her 6 saatte bunları yeniden keşfedip gereksiz yorum üretirdi. Kuralımıza uygun şekilde hepsini **Todo'ya** geri çektim. Enes REV-60..65'ten birini teslim edince ilgili REV-6x In Progress'e çekilir. |
| 2026-07-17..18 | **Enes'in ajanı REV-60..65'i teslim etti** (zincirleme PR'lar #10→#15, GitHub'da), Linear'da **In Review**'a taşıdı. Hepsi **yalnız tasarım dokümanı** (`TASARIM/rev-6x-*.md`) — kod/pubspec/asset PNG'lerine dokunulmadı; somut görsel/ses assetleri "ekip kararı sonrası Gemini'de / kayıt yapılarak üretilecek" notuyla erteli. |
| 2026-07-23 | **Aile toplantısı** (Family Business). Reversi için kararlar: yayıncı firmayla görüşme; varsayılan tema turkuaz-krem + Ayşe'nin "Güzelsi" alternatifi; tema/tahta/taş tam bağımsız; 3 ücretsiz+3 ücretli tahta; rütbe seti onayı; kupa mantığı + mağlubiyet puan düşüşü; iç ekonomi/coin+reklam+IAP; görev dağılımı (Ayşe/Enes tasarım+ses aynı hesap, Sena yardımcı, Enes test). Tüm kararlar **§7C**'de kanonik. |
| 2026-07-24 | **Toplantı kararları Claude ile task'lara işlendi.** Rütbe sistemi Mustafa ile çalışıldı → tek "kupa" merdiveni (skor farkına bağlı kazanç, rütbeye göre artan mağlubiyet cezası, öz-dengeli). Mevcut Epic 12 task'ları (REV-60/62/63/65/67/70) toplantı kararlarına göre güncellendi; yeni task'lar açıldı (rütbe/kupa sunucu motoru, maç sonu sonuç ekranı, maç ekranı rütbe+rakip istatistik, online kendi teması, offline undo satışı, reklamla coin). Ayrıntı §7C. |
| 2026-07-24 | **Rütbe sistemi + bağımsızlık CİHAZDA test edildi (Mustafa).** REV-73 prod'a deploy edildi (kupa motoru canlı), yeni APK telefon+emülatöre kuruldu. **Bulgular → 3 yeni task:** (1) app teması (Güzelsi/Orijinal) yalnız menü/ayarlara uygulanmış, oyun/profil/online/bekleme ekranlarına değil → **REV-79**. (2) çiçek/mermer tahtaları Orijinal temada bozuk (çiçek→kahverengi): kök neden, oyun tahta widget'ını **app temasına göre** seçiyor (Güzelsi→`OnlineBoard` asset render, Orijinal→`WoodBoard` gradyan); REV-70 kuplajı kaldırınca `WoodBoard` asset tahtaları çizemiyor + online hep `WoodBoard`. Ayrıca "Özel" tahtaların özel taşları (walnut/maple, mermer, çiçek diskleri) seçilebilir coin değil → **REV-80** (tam bağımsızlık: tahta render'ı tahtaya göre + 6 özel disk coin seçiciye, her taş her tahtada — Mustafa kararı). (3) XP/seviye her yerden kaldırılıp rütbe/kupaya geçilecek (leaderboard+matchmaking+sunucu dahil — Mustafa kararı) → **REV-81**. |
| 2026-07-24 | **REV-80 render kısmı kodlandı (In Review) + coin kısmı REV-82'ye bölündü.** Kök neden: `OnlineBoard` gradyan tahtaları, `WoodBoard` mermer/çiçek asset tahtalarını çizemiyor; oyun app temasına göre seçiyordu (REV-70 sonrası çiçek→kahverengi kırıldı). Çözüm: yeni `rendersWithOnlineBoard(board)` (= mermer/çiçek) ile tahta widget'ı **tahtaya göre** seçiliyor — mermer/çiçek → OnlineBoard (asset+kendi diskleri), wood+gradyanlar → WoodBoard; **hem offline hem online**. `wood` app-teması kuplajı board seçiminden kaldırıldı. 92/92 test yeşil. **Kalan (REV-82):** 6 özel diski (walnut/maple, mermer, çiçek) seçilebilir coin yapmak + her taş her tahtada — iki 3D board widget'ının hem prosedürel hem asset disk çizmesini gerektiren büyük render birleştirmesi; görsel doğrulama gerektiği için ertelendi. |
| 2026-07-24 | **REV-81 (XP/seviye kaldırma → rütbe/kupa) kodlandı, In Review.** Client: `Profile.level/xp` kaldırıldı; profil `_LevelCard`→`_RankCard` (rütbe rozeti + kupa + `rankProgress` çubuğu); online istatistik `_XpProgressRow` kaldırıldı (rütbe bölümü kaldı); rakip önizleme/rakip istatistik sheet "Seviye N"→rütbe; leaderboard "Seviye" metriği→**Kupa** (`online.trophies`/`trophyGained`, 🏆). Matchmaking bileti `level`→`trophies`. Server: `finish_game.ts` XP/level yazımı durdu (kupa zaten yazılıyor), haftalık leaderboard `xpGained`/`level`→`trophyGained`/`trophies`, history'den `oppLevel` çıktı; `matchmaking.ts` playerInfo `level`→`trophies`. `xp_level.(dart\|ts)` ölü kod olarak duruyor (testleri geçiyor). 92/92 flutter + 36/36 functions yeşil. **Prod deploy gerekli** (leaderboard/matchmaking için). |
| 2026-07-24 | **REV-79 (app teması tüm ekranlara) — 6 ekran kodlandı, In Review.** `wood_theme.dart`'a tema-duyarlı yardımcılar (`pageSurfaceColor`/`pageBackgroundGradient`/`headerGradient`): Güzelsi→parşömen gövde + koyu-ahşap header, Orijinal→cream + turkuaz. Uygulandı: profil, online istatistik, leaderboard, matchmaking/bekleme, rakip önizleme, online oyun. 92/92 test yeşil. **Ertelendi:** offline oyun ekranı bespoke `CreamShell` (3D) kullanıyor — wood karşılığı (WoodShell) ayrı tasarım işi; kullanıcının şikayeti online+profildeydi, onlar çözüldü. |
| 2026-07-24 | **REV-70 (tema/tahta/taş bağımsızlığı + Güzelsi) kodlandı, In Review.** `setAppTheme` kuplajı kaldırıldı (tema artık tahtayı zorla değiştirmiyor); ayarlarda **7 tahtanın hepsi** + **taş seçici her zaman** görünür (temadan bağımsız). App teması "Özel" → **"Güzelsi"** (görsel adlandırma; `AppThemeId.wood` enum'u korundu → kayıtlı ayarlar bozulmaz). Kritik bulgu: taşlar zaten `CoinView(coinPalettes[...])` ile tüm tahtalarda CoinColor'dan render ediliyordu → bağımsızlık UI-only, render değişikliği gerekmedi. Widget testi taş bölümüne kaydıracak şekilde güncellendi (7 tahta ekranı uzattı). 92/92 flutter testi yeşil. **Ertelenen:** ücretli tahta **kilitleme** (şeffaf+kilit) + final tahta seti (şu an 7; meeting 3 ücretsiz+3 ücretli dedi ama hangileri REV-62 tasarım + REV-69 store'da netleşecek). |
| 2026-07-24 | **REV-75 (maç ekranı rütbe etiketi + rakip istatistik) kodlandı, In Review.** `_PlayerStrip`'e kompakt rütbe etiketi (isim üstünde, REV-60 rengi/madalya) + tıklanabilirlik eklendi. Kendi rütbem profilden (canlı); rakibin rütbesi+istatistiği yeni `PlayerProfileService.fetch(uid)` ile `users/{oppUid}`'den **tek sefer** okunuyor (matchmaking/deploy değişikliği gerektirmez; misafir rakip → doc yok → etiket/tap yok). Rakibe basınca `_OpponentStatsSheet` (galibiyet/mağlubiyet/beraberlik/oran, kupa/rütbe, seri, en iyi skor farkı). 92/92 flutter testi yeşil. |
| 2026-07-24 | **REV-74 (maç sonu sonuç ekranı) kodlandı, In Review.** `online_game_screen.dart` `_ResultOverlay` genişletildi: imzalı oyuncu için server history doc'u (`ProgressHistoryService.watchReward(uid, gameId)`) izlenir; ödül düşünce animasyonlu **±kupa** (yeşil/kırmızı), **rütbe rozeti + ilerleme çubuğu** (sonraki rütbeye), **rütbe atladıysa** kutlama (`rankUp`), ve maç istatistikleri (çevrilen/fark/seri) gösterilir. `HistoryEntry`'ye `trophyDelta`+`trophies` alanları eklendi. Misafir ödül bölümünü görmez (sadece skor). 92/92 flutter testi yeşil. **Rütbe atlama SESİ REV-65'e bağlı** (asset yok; görsel kutlama var, ses gelince bağlanacak). Canlı ±kupa REV-73 deploy'una bağlı (deploy'suz 0 görünür). |
| 2026-07-24 | **REV-67 (Kupa/Rütbe client modeli + gösterim) kodlandı, In Review.** Yeni `lib/core/models/rank.dart` — `trophy.ts`'in birebir Dart aynası (`RankId` enum, `kRanks` eşikleri, `rankFor`/`trophiesToNext`/`rankProgress`); `test/rank_test.dart` parite testi (8, TS ikizini yansıtır). `OnlineStats`'a `trophies` alanı + `rank` getter (Firestore `online.trophies`'ten). Rütbe ünvanları l10n (`rankTitle`, TR/EN — REV-60 Set A) + `rankLabel`/`trophies`. Yeni `RankBadge` widget'ı (madalya ikonu + REV-60 renk rampası; REV-61 çerçeveleri gelince ikon değişir), online istatistik ekranı + profil ekranına bağlandı (yalnız imzalı; misafir görmez). 92/92 flutter testi yeşil (8 yeni). Rakip rütbe gösterimi REV-75'e bırakıldı (matchmaking bileti trophies taşımalı). |
| 2026-07-24 | **REV-73 (Kupa/Rütbe sunucu motoru) kodlandı, In Review.** Yeni saf modül `functions/src/trophy.ts`: `rankFor(trophies)` (Çaylak 0 / Acemi 30 / Kalfa 100 / Usta 250 / B.Usta 550 / Efsane 1000) + `trophyDelta(outcome, scoreDiff, preTrophies)` (galibiyet +3 + `round(fark/8)` bonus ≤+3 → +3..+6; beraberlik +1; mağlubiyet maç-öncesi rütbeye göre 0/0/−1/−2/−4/−6). `finish_game.ts` applyReward'a bağlandı: `online.trophies` (max(0,...)) + denormalize `online.rank`; history doc'una `trophyDelta`/`trophies`/`rank` (REV-74 için). 36/36 functions testi yeşil (11 yeni). **Prod'a deploy edilmedi — Mustafa onayı bekliyor.** Client mirror (rütbe eşikleri) REV-67'de yazılacak. |
| 2026-07-24 | **Smoke test GEÇTI.** `9721dbf` build telefona kuruldu (kablosuz adb) + emülatör (Android Studio). Misafir↔misafir ve misafir↔imzalı 2 hesaplı online: eşleşme→oyun→bitiş sorunsuz, istatistikler işliyor. Misafir giriş fix'i + prod deploy doğrulandı. In Review'daki 8 iş (REV-53/54/55/56/57/58/59/66) cihazda onaylandı; Mustafa Done'a çekebilir. **Emülatör dersi:** aynı AVD'yi Bash'ten başlatmak quick-boot snapshot'ını bozup sonraki Android Studio açılışında "offline" wedge yaratıyor → AVD'yi HEP Android Studio'dan aç, gerekirse "Cold Boot Now". (Ayrıca bu macOS'ta `timeout` komutu yok — gtimeout/arka-plan kalıbı kullan.) |
| 2026-07-24 | **In Review temizliği + prod deploy.** In Review'daki 8 iş (REV-53/54/55/56/57/58/59/66) kod sağlığı doğrulandı (flutter 84/84, functions 25/25 yeşil). Misafir online'a girememe sorunu teşhis edildi: (1) Firebase'de anonim giriş kapalıydı → Mustafa açtı; (2) menüde misafir giriş yolu try/catch dışındaydı, sessizce düşüyordu → düzeltildi (`c2269a3`). **Sunucu (REV-54/55/56/57 + REV-66) prod'a deploy edildi** (`onGameFinished` güncel, `purchaseItem` oluşturuldu, kurallar+index yayında). 8 iş artık cihaz smoke testine hazır; test geçince Mustafa Done'a çeker. |
| 2026-07-24 | **Enes'in REV-60..65 teslimleri Claude ile kontrol edildi.** Teknik doğruluk kontrolü (XP eğrisi, `AppThemeId`/`BoardTheme` kuplajı, `catalog.ts`/`purchase.ts` şeması, `coin_palette.dart`, ekran iskeletleri kaynak kodla karşılaştırıldı) → **hata bulunmadı**, dokümanlar kod gerçeğiyle birebir tutarlı. Ama: (a) **PR #10-#15'ten hiçbiri merge edilmedi** (main'de değil, şimdilik bilerek merge edilmiyor), (b) **her task'ta ekip kararı bekleyen açık noktalar var** (ünvan seti, kademe eşikleri, fiyat mutlak değerleri, shell tercihi vb.), (c) **REV-62 ile REV-63 arasında çelişki:** REV-62 disk-renk seçicisinin (`CoinColor`) tamamen kaldırılmasını önerirken REV-63 mağazada "Taş Renkleri" diye ücretli kategori öneriyor — Enes'in kendi dokümanında da flaglenmiş, karara bağlanmalı. (d) **REV-65'te gerçek ses dosyası yok**, yalnız yönerge (seslendirme insan işi + tetik noktaları henüz kodda yok). Bu yüzden **REV-60..65 hepsi tekrar Todo'ya çekildi**, her birine Linear'da bu bulguları özetleyen teknik yorum eklendi (Enes'in ajanı okuyup devam edebilsin diye). Mustafa'nın 2026-07-23 ekip toplantısı notları geldiğinde kararlar + olası yeni task'lar buraya işlenecek. |

## 6. TEST ORTAMI

- **Hesaplar:** telefon = mustafakarakas1071@gmail.com · emülatör = mustafamihmandar@gmail.com. Faz 2'de ayrıca misafir (girişsiz) oturum test edilecek.
- **Telefon (SM-G780G):** USB bozuk → kablosuz adb. Uyuyunca düşer; port her seferinde değişir. Akış: Mustafa'dan eşleştirme IP:port+kod iste → `adb pair` → ana ekrandaki bağlantı IP:port ile `adb connect`. adb PATH'te DEĞİL: `/Users/f/Library/Android/sdk/platform-tools/adb`.
- **Emülatör `reversi_test`:** MUTLAKA Android Studio'dan başlatılır (Bash'ten = siyah ekran). Not (2026-07-08): `adb exec-out screencap` emülatörde takılabiliyor; adb sunucusunu yeniden başlatmak gerekebilir.
- **Kurulum:** `adb -s <id> install -r build/app/outputs/flutter-apk/app-release.apk` → `am force-stop` → `monkey ... 1` ile başlat.
- Release imza: `~/reversi-release.jks` + `android/key.properties` (gitignored). Play Store için `flutter build appbundle --release`.

## 7. SIRADAKİ İŞLER

### 7A. Epic 12 — "Profil, Tasarım & Mağaza" (REV-60..72, planlandı 2026-07-14)

Linear projesi: `12 · Profil, Tasarım & Mağaza` (id `bb9af353-dafb-4cfe-a87b-4cadb10eb2a0`). 13 issue Todo'da. Plan: `/Users/f/.claude/plans/imdi-g-ncel-duruma-eklenecekleri-cozy-kahan.md`.

**Kararlar (2026-07-14, Mustafa ile):**
- **Ödeme modeli: Coin + IAP birlikte.** Maçlardan coin kazanılır (`earnedCoins`: galibiyet 10/beraberlik 5/mağlubiyet 2, **açıldı REV-66'da 2026-07-15**), mağazada içerik coin ile alınır; gerçek parayla coin paketi satılır (Play Billing). §9'daki monetizasyon planı bu epic'e taşındı.
- **Original/wood tema ayrımı kararı, tahta elemesiyle birlikte** verilecek (REV-62 önerisi → ekip kararı).
- **Öncelik: Faz 2 ile paralel.** Faz 2 bitti (§7B). Kod sırası: ✅ REV-66 tamam → REV-67..72 hâlâ Enes'in REV-60..65 teslimlerine bloklu. **Bu 6 issue Todo'da bekliyor.**
- **2026-07-17..18:** Enes'in ajanı REV-60..65'i tasarım dokümanı olarak teslim etti (PR #10-#15, `TASARIM/*.md`, kod yok), Linear'da In Review'a çekti.
- **2026-07-24:** Claude ile kontrol edildi — teknik olarak doğru ama (a) PR'lar merge edilmedi, (b) her task'ta ekip kararı bekleyen açık noktalar var, (c) REV-62/REV-63 arasında disk-renk seçici konusunda çelişki var, (d) REV-65'te gerçek ses dosyası yok. **Hepsi tekrar Todo'ya çekildi**, Linear yorumlarında detaylandırıldı (bkz. §5). Mustafa'nın 2026-07-23 toplantı notları + kararları + olası yeni task'lar geldiğinde bu bölüm güncellenecek. Enes bir tasarımı nihai onaydan geçirip PR'ı merge'e hazır hale getirince ilgili REV-6x In Progress'e çekilir, kod devam eder.

**Enes (görsel tasarım + ses; workspace'te zaten kayıtlı — argedikas@gmail.com, atandı 2026-07-15):**
- REV-60 Seviye ünvanları/kademe kimliği önerisi (taban: 1-4 Çaylak · 5-9 Acemi · 10-19 Kalfa · 20-34 Usta · 35-49 Büyükusta · 50+ Efsane)
- REV-61 Seviye çerçeveleri tasarımı (kademe başına 1 + satılık 3-5 özel)
- REV-62 Tahta & tema elemesi önerisi (7 tahta + original/wood ayrımı; ücretli/ücretsiz ayrımı)
- REV-63 Mağaza ekranı görsel tasarımı · REV-64 Mağaza yönlendirme noktaları tasarımı · REV-65 Mağaza & ödül SFX'leri

**Mustafa (kodlama — Claude uygular):**
- ✅ REV-66 Sunucu: coin açılışı + cüzdan/mağaza altyapısı — **tamamlandı 2026-07-15** (aşağıda detay)
- REV-67 Seviye ünvanları modeli · REV-68 Çerçeveli avatar + profil detayları · REV-69 Mağaza ekranı kodu (`features/store/`)
- REV-70 Tema elemesi uygulaması + ayarlar sadeleştirme · REV-71 Mağaza yönlendirmeleri · REV-72 Play Billing IAP (son halka; Play Console ürün tanımı Mustafa'da)

**Bekleyen karar toplantıları:** ✅ İkisi de 2026-07-23 aile toplantısında karara bağlandı → bkz. **§7C**.

### 7C. AİLE TOPLANTISI KARARLARI (2026-07-23) — kanonik

Kaynak: `~/Downloads/-FAMİLY BUSİNESS- ...pdf` (toplantı notları). Katılım: Süleyman, Cahide, Enes, Mustafa, Ayşe, Sena, Betül, Hamza. Bu bölüm toplantıda kesinleşen kararların **tek kanonik kaydıdır**; task içerikleri buna göre güncellendi/açıldı (2026-07-24, Mustafa'nın Claude oturumu).

**1. Görev dağılımı (netleşti):**
- **Ayşe + Enes aynı bilgisayarı/Linear hesabını (argedikas@gmail.com) paylaşıyor** → tüm **görsel tasarım + ses** task'ları tek kimlik olarak **Enes**'e atanır. **Sena** ses/müzikte yardımcı — **ona ayrı task açılmaz.**
- Enes ayrıca oyun testi/bug tespiti yapacak (toplantı görev dağılımı), ama Linear'da tasarım/ses task'ları onda kalıyor.
- Mustafa: Reversi kodlaması + iç ekonomi/puanlama hesaplama + TASK açımı. Yayıncı (dağıtımcı) firmayla anlaşma sürecinde.

**2. Tema / tahta / taş — tam bağımsızlık:**
- **Varsayılan tema = Turkuaz-Krem klasik** (mevcut `original`). Ayşe'nin **"Güzelsi"** tasarımı (bugünkü **"Özel"** temasının yeni adı) **alternatif tema**.
- **"Güzelsi" yalnız menü görünümü + genel renk düzenine (shell) etki eder** — tahtaya/taşa DOKUNMAZ.
- Bugün "Özel" seçilince gelen **3 tahta + 6 taş rengi**, temaya bağlı olmaktan çıkıp **tahta/taş seçimi bölümünde** diğerleriyle birlikte **serbestçe** seçilebilir olur. Tema + tahta + taş = **üç bağımsız eksen**, hiçbir kuplaj yok (mevcut `setAppTheme` board'u zorlama davranışı kalkar; **temalar SİLİNMEZ**).
- **3 ücretsiz + 3 ücretli/kilitli tahta.** Kilitli ürünler mağazada **hafif şeffaf + kilit simgesi** ile.
- **Online'da her oyuncu KENDİ seçtiği tema/tahtayı görür** (rakibinkini değil).

**3. Rütbe / Kupa sistemi — tek merdiven (kanonik model):**
- Tek para birimi **"Kupa"** (trophy), iniş-çıkışlı. **Rütbe = kupa eşiği:** Çaylak · Acemi · Kalfa · Usta · Büyük Usta · Efsane. Eşikler **geometrik** artar (örn. 0 → 30 → 100 → 250 → 550 → 1000; nihai sayılar REV-67/sunucu motorunda oturur).
- **Kazanç skor FARKINA bağlı:** galibiyet **+3 taban + fark bonusu** (ezici galibiyet ~+6'ya kadar). Beraberlik **+1**.
- **Mağlubiyet cezası rütbeye göre artar** (Kalfa'dan itibaren başlar): Çaylak/Acemi **0** · Kalfa **−1** · Usta **−2** · Büyük Usta **−4** · Efsane **−6**.
- **Öz-denge:** bir rütbede tutunmak için gereken galibiyet oranı = `ceza / (kazanç + ceza)` → Kalfa %25, Usta %40, B.Usta %57, Efsane %67. Ceza yükseldikçe tutunmak otomatik zorlaşır (elle dengeleme yok). Erken kademede (0 ceza) düşmeden orta seviyeye çıkılır.
- **Çevrilen taş sayısı vb.** merdiven tabanı DEĞİL — istatistik olarak kaydedilmeye devam eder (`OnlineStats.totalFlipped` mevcut). Kupa/rütbe alanları `OnlineStats`'a + Firestore'a eklenecek.

**4. Maç deneyimi UX:**
- **Maç sonu ekranı** (bugün yalnız "Kazandın/Kaybettin + skor"): kazanılan/kaybedilen **kupa**, **rütbe ilerlemesi** ve maç istatistikleri (çevrilen taş, skor farkı, seri) gösterilecek.
- **Maç ekranında** her iki oyuncunun **adının üstünde küçük rütbe etiketi**.
- **Maç sırasında rakibin adına/ikonuna basınca** onun tüm online istatistikleri görünecek.

**5. Ses & müzik — komple yenileme:**
- **Tüm mevcut sesler değişecek:** 9 efekt (`place, flip, invalid, button, tick, timeup, win, lose, draw`) + 2 müzik (`menu_music, game_music`). Ek yeni sesler: mağaza satın alma, coin kazanma, rütbe/kademe atlama, (ops.) kuşanma. + **telifsiz müzik** seçimi. Sena yardımcı.

**6. İç ekonomi / mağaza:**
- Coin: online galibiyet + (araştırma sonrası) **reklam izleme** + doğrudan satın alma (IAP). Reklam **caiz mi** araştırması + uygun reklam türü **dağıtımcı firma** ile görüşülecek → reklam task'ı **bloklu**.
- Mağazada kozmetik (tahta/taş/çerçeve) + **offline "hamle geri alma"** satışı (bkz. §8 — offline için iptal kararı gevşetildi; online'a DOKUNULMAZ).

**Task eşlemesi (2026-07-24 uygulandı):** güncellenen mevcut → REV-60 (Set A onaylandı), REV-62 (Güzelsi + bağımsızlık + 3/3), REV-63 (taş bağımsız + undo ürünü), REV-65 (tüm sesler + müzik), REV-67 (kupa/rütbe client modeli), REV-70 (bağımsızlık uygulaması, silme yok). Yeni açılanlar: REV-73 rütbe/kupa **sunucu motoru**, REV-74 maç sonu **sonuç ekranı**, REV-75 maç ekranı **rütbe etiketi + rakip istatistik**, REV-76 **online kendi teması**, REV-77 **offline undo satışı**, REV-78 **reklamla coin (bloklu)**.

**Proje bölünmesi (2026-07-24):** Epic 12 ikiye ayrıldı (toplantı yeni bir gövde doğurdu).
- **Proje 12 · "Profil, Tasarım & Mağaza"** (`bb9af353-...`): tasarım + mağaza + profil + tema/tahta/taş + ses + ekonomi. Kalan: REV-60/61/62/63/64/65/66/68/69/70/71/72 + REV-77 (offline undo) + REV-78 (reklam, bloklu).
- **Proje 13 · "Rütbe, Kupa & Maç Deneyimi"** (`0f5344ce-0ce4-4feb-967b-ea2387a5fa42`): rütbe mekaniği + online maç deneyimi. İçindekiler: **REV-67** (kupa/rütbe client modeli), **REV-73** (kupa sunucu motoru), **REV-74** (maç sonu ekranı), **REV-75** (maç ekranı rütbe+rakip istatistik), **REV-76** (online kendi teması). Kanonik model §7C-3/4. Kupa eşikleri şimdilik önerilen değerlerde (0/30/100/250/550/1000), canlı veriyle ileride tune edilecek.

### 7B. FAZ 2 (Linear proje "11 · Online Geliştirme: Misafir, İstatistik & Lider Tablosu") — ✅ 7/7 kod tarafı tamam (2026-07-15)

Onaylı plan: `/Users/f/.claude/plans/imdi-yeni-bir-a-amaya-ethereal-map.md`. Mustafa'nın "tüm task'larını In Progress'e çek, yapabildiklerini yap" talimatıyla REV-53..59 tek oturumda uygulandı ve **In Review'a** taşındı. ✅ **Sunucu tarafı (REV-54/55/56/57 + REV-66) 2026-07-24 prod'a deploy edildi.** ✅ **2 hesaplı smoke test geçti (2026-07-24):** misafir↔misafir + misafir↔imzalı eşleşme/oyun/istatistik sorunsuz. ✅ **8 iş (REV-53/54/55/56/57/58/59/66) Done'a çekildi (2026-07-24, Mustafa'nın açık talimatıyla, cihaz testi sonrası).** **Faz 2 (proje 11) tamamen kapandı; REV-66 (Epic 12 ilk halkası) da Done.**

- **Faz A — Misafir oyun:** REV-53 (client: Firebase Anonymous Auth, `Profile.isGuest`, "Misafir devam et" menü akışı) + REV-57 (server: finish_game'de `admin.auth` ile anonim kontrolü → misafire ödül/history/leaderboard YAZMA).
- **Faz B — Gelişim istatistikleri:** REV-54 (server: maç başına `users/{uid}/history/{gameId}` time-series) + REV-58 (client: online istatistik ekranına galibiyet oranı trendi + aktivite&seri grafikleri; fl_chart mevcut).
- **Faz C — Lider tablosu:** REV-55 (server: `leaderboards/{weekId}/players` haftalık sayaçlar + weekId yardımcısı) + REV-56 (kurallar+index) + REV-59 (client: leaderboard ekranı — Haftalık/TümZamanlar × Seviye/Galibiyet + "senin sıran").

**Kilitli kararlar:** Lider tablosu Seviye+Galibiyet (Elo YOK ama genişletilebilir). Haftalık + TümZamanlar ayrı. Misafir maçı imzalı rakibe SAYILIR (yalnız misafir kazanmaz; farm riski kabul edildi, gerekirse sonra önlem). İstatistik+leaderboard Google girişine kapalı, misafire upsell. 3. istatistik sayfası AÇILMAZ — grafikler mevcut online istatistik ekranına girer. REV-54/55/57 aynı `finish_game` dosyasını değiştirir — birlikte ele al.

### Küçük takip işleri (ticket'sız, engel değil)
- [x] 2 hesaplı online smoke testi tamamlandı (2026-07-24, telefon+emülatör; misafir + imzalı, istatistikler işliyor)
- [ ] `turnDeadline` ölü kodu temizliği (yazılıyor, okunmuyor)
- [ ] REV-51 emülatör kural testleri (`functions/scripts/test_{rules,finish_game}.js`) — Java kurulunca; canlı test geçtiği için düşük öncelik
- [ ] `ai_player.dart:179` iki curly-braces lint bilgisi (Enes'in kodu, kozmetik)
- [ ] Online oyun ekranının wood temasına uyarlanması (Enes'in `online_match_screen.dart` tasarımı kaynak alınabilir) — ayrı iş
- [ ] Enes'le git disiplini konuşması (güncel main'den dallanma)

## 8. İPTAL EDİLENLER (TEKRAR ÖNERME)

- **Fantastik Mod + Mağaza (2026-06-19, ekip kararı):** flip-any/delete-any/freeze/ekstra-hamle güçleri + coin/reklam/IAP ile güç-kozmetik-undo satan mağaza. **Oyunun özünü bozduğu için iptal.** Online güçler ayrıca ağır altyapı isterdi (TS engine aksiyon tipleri, move-log şeması, sunucu-doğrulamalı envanter, ayrı eşleşme havuzu). Bir daha gündeme getirme. **⚠️ Kısmi güncelleme (2026-07-23 toplantı):** yalnız **offline "hamle geri alma"** satışı bu iptalden istisna tutuldu (offline oyun zaten adil-rekabet dışı). **Online'da undo/güç satışı hâlâ kesin İPTAL** — online adilliği korunur.
- **Elo puanı:** şimdilik yok; leaderboard metrikleri genişletilebilir bırakıldı.
- **XP/seviye eğrisi grafiği (REV-58 kapsamında):** monotonik olduğu için anlamsız — Mustafa'nın kararı, eklenmeyecek.
- **Test botu fikri:** yerine emülatör 2. client oldu.
- **Flutter gen-l10n:** bilerek kaldırıldı; elle yazılmış `AppStrings` kullanılıyor.

## 9. İLERİYE DÖNÜK FİKİRLER (v1.1+)

- **Monetizasyon → EPIC 12'YE TAŞINDI (2026-07-14, bkz. §7A).** Model kararlaştırıldı: coin + IAP birlikte. Teknik hazırlık notları: cüzdan sunucu-doğrulamalı (client `users/{uid}` içinde yalnız kimlik alanlarını yazabilir); satın almalar uid'e bağlı; `earnedCoins` + testleri `functions/src/xp_level.ts` içinde hazır, REV-66'da ödüle bağlanacak; back-fill kararı REV-66'da; Play Billing REV-72'de.
- XP miktarlarının ayarlanması (tuning) — canlı veriye göre.
- iOS/Apple girişi (tasarım iOS-ready tutuluyor; Android-first).
- Misafir→Google hesap yükseltme akışı (Faz A sonrası doğal devam).

## 10. OTOMASYON

- **`reversi-build-agent` (LOKAL scheduled task, çalışan):** cron `0 0,6,12,18 * * *` (günde 4 kez, 6 saatte bir — güncellendi 2026-07-15, önceki: `0 1,7,13 * * *`); her çalıştırmada ÖNCE bu PROGRESS.md'yi okur, sonra In Progress'teki **yalnız Mustafa'ya atanmış ve henüz In AI'da olmayan** issue'ları alır (Enes'inkilere, atanmamışlara veya zaten In AI'da olanlara dokunmaz), her birini işe başlamadan hemen önce **In AI**'a çeker (kilit), uygular, test eder, PROGRESS.md'yi güncelleyip aynı commit'e dahil eder, push'lar, **In AI → In Review**'a taşır. Opus 4.8 + Bypass permissions (masaüstü "Edit routine" penceresinden ayarlı; SKILL.md/MCP'de değil). Mac uyanık + Claude app açık olmalı. Bkz. §2.3 (In AI kilidi).
- **Cloud routine "Reversi Flutter build agent" (BLOKE, yedek):** GitHub yazma izni yok (403) + cloud'da Flutter SDK yok. İkisi çözülmeden kullanma.

## 11. BU DOSYANIN BAKIM KURALLARI

1. Her anlamlı değişiklikten sonra bu dosya güncellenir ve commit'e dahil edilir — **onay beklemeden**.
2. "Son güncelleme / son commit" satırı her güncellemede yenilenir.
3. Yeni kararlar §2 veya §7'ye, iptaller §8'e, fikirler §9'a işlenir; geçmişe §5'e satır eklenir.
4. Bir bilgi güncelliğini yitirirse silinmez, düzeltilir (kazalar tarihçede kalır).
5. Dosya Türkçedir; teknik terimler ve komutlar olduğu gibi bırakılır.
