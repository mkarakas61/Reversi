# REVERSI — PROJE İLERLEME DOSYASI

> **BU DOSYA PROJENİN TEK GERÇEK KAYNAĞIDIR.**
> Her yeni oturumda (session) yapılacak İLK İŞ bu dosyayı okumaktır.
> Her değişiklik, karar, fikir ve iptal buraya işlenir — sormadan, onay beklemeden.
> Dosyayı güncellemek Claude'un sorumluluğudur; her anlamlı adımdan sonra güncellenir.

Son güncelleme: **2026-07-15** · Son commit: `c6d53ad` · Sürüm: `0.1.0+1`

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
- Restorasyon sonrası (452b102) **telefona kuruldu, açılış + otomatik Google oturumu doğrulandı**. ⏳ **2 hesaplı tam online smoke test HENÜZ YAPILMADI** (eşleşme→oyun→ödül) — emülatör ekran yakalama sorunu yüzünden yarım kaldı. İlk fırsatta tamamlanacak.
- Ekip test APK'sı: `~/Desktop/Reversi-0.1.0-452b102.apk` (release-imzalı, universal).

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
- **Deploy:** `cd functions && npm test` (24 test) → `firebase deploy --only functions --force --project reversi-3a506 --account mustafakarakas1071@gmail.com`. Rules/index: `--only firestore:rules` / `firestore:indexes`. **Firebase'de HER ZAMAN `--account` ver** (CLI varsayılanı yanlış hesap: mustafamihmandar). ⏳ REV-54/55/56/57 kuralları+kodu main'de ama **henüz prod'a deploy edilmedi** — Mustafa onayı bekliyor.
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
- **Öncelik: Faz 2 ile paralel.** Faz 2 bitti (§7B). Kod sırası: ✅ REV-66 tamam → REV-67..72 hâlâ Enes'in REV-60..65 teslimlerine bloklu (bkz. yorumlar, REV-60..65 üzerinde).

**Enes (görsel tasarım + ses; workspace'te zaten kayıtlı — argedikas@gmail.com, atandı 2026-07-15):**
- REV-60 Seviye ünvanları/kademe kimliği önerisi (taban: 1-4 Çaylak · 5-9 Acemi · 10-19 Kalfa · 20-34 Usta · 35-49 Büyükusta · 50+ Efsane)
- REV-61 Seviye çerçeveleri tasarımı (kademe başına 1 + satılık 3-5 özel)
- REV-62 Tahta & tema elemesi önerisi (7 tahta + original/wood ayrımı; ücretli/ücretsiz ayrımı)
- REV-63 Mağaza ekranı görsel tasarımı · REV-64 Mağaza yönlendirme noktaları tasarımı · REV-65 Mağaza & ödül SFX'leri

**Mustafa (kodlama — Claude uygular):**
- ✅ REV-66 Sunucu: coin açılışı + cüzdan/mağaza altyapısı — **tamamlandı 2026-07-15** (aşağıda detay)
- REV-67 Seviye ünvanları modeli · REV-68 Çerçeveli avatar + profil detayları · REV-69 Mağaza ekranı kodu (`features/store/`)
- REV-70 Tema elemesi uygulaması + ayarlar sadeleştirme · REV-71 Mağaza yönlendirmeleri · REV-72 Play Billing IAP (son halka; Play Console ürün tanımı Mustafa'da)

**Bekleyen karar toplantıları:** (1) REV-60 ünvan/kademe onayı, (2) REV-62 eleme + tema ayrımı. Sonuçlar bu dosyaya işlenecek.

### 7B. FAZ 2 (Linear proje "11 · Online Geliştirme: Misafir, İstatistik & Lider Tablosu") — ✅ 7/7 kod tarafı tamam (2026-07-15)

Onaylı plan: `/Users/f/.claude/plans/imdi-yeni-bir-a-amaya-ethereal-map.md`. Mustafa'nın "tüm task'larını In Progress'e çek, yapabildiklerini yap" talimatıyla REV-53..59 tek oturumda uygulandı ve **In Review'a** taşındı. **Sunucu tarafı (REV-54/55/56/57, `finish_game.ts`+rules) main'de ama henüz prod'a deploy edilmedi — deploy + cihaz testi için Mustafa onayı bekliyor.** Client tarafı (REV-53/58/59) tamamen kodlandı, testleri yeşil; canlı veri sunucu deploy'una bağlı.

- **Faz A — Misafir oyun:** REV-53 (client: Firebase Anonymous Auth, `Profile.isGuest`, "Misafir devam et" menü akışı) + REV-57 (server: finish_game'de `admin.auth` ile anonim kontrolü → misafire ödül/history/leaderboard YAZMA).
- **Faz B — Gelişim istatistikleri:** REV-54 (server: maç başına `users/{uid}/history/{gameId}` time-series) + REV-58 (client: online istatistik ekranına galibiyet oranı trendi + aktivite&seri grafikleri; fl_chart mevcut).
- **Faz C — Lider tablosu:** REV-55 (server: `leaderboards/{weekId}/players` haftalık sayaçlar + weekId yardımcısı) + REV-56 (kurallar+index) + REV-59 (client: leaderboard ekranı — Haftalık/TümZamanlar × Seviye/Galibiyet + "senin sıran").

**Kilitli kararlar:** Lider tablosu Seviye+Galibiyet (Elo YOK ama genişletilebilir). Haftalık + TümZamanlar ayrı. Misafir maçı imzalı rakibe SAYILIR (yalnız misafir kazanmaz; farm riski kabul edildi, gerekirse sonra önlem). İstatistik+leaderboard Google girişine kapalı, misafire upsell. 3. istatistik sayfası AÇILMAZ — grafikler mevcut online istatistik ekranına girer. REV-54/55/57 aynı `finish_game` dosyasını değiştirir — birlikte ele al.

### Küçük takip işleri (ticket'sız, engel değil)
- [ ] 2 hesaplı online smoke testinin tamamlanması (restorasyon doğrulaması)
- [ ] `turnDeadline` ölü kodu temizliği (yazılıyor, okunmuyor)
- [ ] REV-51 emülatör kural testleri (`functions/scripts/test_{rules,finish_game}.js`) — Java kurulunca; canlı test geçtiği için düşük öncelik
- [ ] `ai_player.dart:179` iki curly-braces lint bilgisi (Enes'in kodu, kozmetik)
- [ ] Online oyun ekranının wood temasına uyarlanması (Enes'in `online_match_screen.dart` tasarımı kaynak alınabilir) — ayrı iş
- [ ] Enes'le git disiplini konuşması (güncel main'den dallanma)

## 8. İPTAL EDİLENLER (TEKRAR ÖNERME)

- **Fantastik Mod + Mağaza (2026-06-19, ekip kararı):** flip-any/delete-any/freeze/ekstra-hamle güçleri + coin/reklam/IAP ile güç-kozmetik-undo satan mağaza. **Oyunun özünü bozduğu için iptal.** Online güçler ayrıca ağır altyapı isterdi (TS engine aksiyon tipleri, move-log şeması, sunucu-doğrulamalı envanter, ayrı eşleşme havuzu). Bir daha gündeme getirme.
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
