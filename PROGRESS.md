# REVERSI — PROJE İLERLEME DOSYASI

> **BU DOSYA PROJENİN TEK GERÇEK KAYNAĞIDIR.**
> Her yeni oturumda (session) yapılacak İLK İŞ bu dosyayı okumaktır.
> Her değişiklik, karar, fikir ve iptal buraya işlenir — sormadan, onay beklemeden.
> Dosyayı güncellemek Claude'un sorumluluğudur; her anlamlı adımdan sonra güncellenir.

Son güncelleme: **2026-08-20** · Son commit: `a42a6dc` · **Oturum kapandı** (GitHub main'e push edildi) · Sürüm: `0.1.0+1`

> **🔚 2026-08-20 OTURUM KAPANIŞI — üç iş bitti, ikisi yayın engeliydi:**
>
> **Canlı durum:** yerel `main` = `origin/main` (`a42a6dc`), çalışma ağacı temiz.
> **157 Flutter + 49 functions testi yeşil**, analyze temiz (bilinen 2 info lint).
> Release APK telefona kuruldu (SM-G780G). **Tablet müsait değildi → iki cihazlı online testler
> (REV-98 rövanş dahil) bu oturumda da yapılamadı, hâlâ bekliyor.**
>
> **⚠️ Bu oturumda SUNUCU DEĞİŞTİ:** `onGameFinished` prod'a deploy edildi (REV-102, history
> dokümanına `coinDelta` + `coins`). Kural/index değişikliği yok.
>
> | # | İş | Durum |
> |---|---|---|
> | REV-102 | Coin bakiyesi görünür oldu (menü + profil + maç sonu) | In Review · ✅ telefonda görüldü · ❌ maç sonu satırı iki cihaz bekliyor |
> | REV-91 | Yasal sayfalar (web) + Uygulama & Hesap ekranı | In Review · ✅ uçtan uca doğrulandı |
> | REV-92 | AD_ID kararı + Data Safety cevap kağıdı | In Review · form Play Console'da doldurulacak |
>
> **Yeni canlı adres:** `https://mkarakas61.github.io/Reversi/` (GitHub Pages, `main` → `/docs`).
> **Yeni gerçek adres:** `reversi.destek@gmail.com` (Mustafa açtı).
>
> **⚠️ SIRADAKİ OTURUMUN İLK İŞİ — REV-90 hesap silme (son yayın engeli).** Bu oturumda
> **başlanmadı**, yalnız ticket + sunucu yapısı okundu, kod değişikliği yok. Planlanan yapı:
> callable `deleteAccount` (Admin SDK ile silme → `requires-recent-login` sorunu hiç doğmuyor) ·
> profil dokümanı + `history` alt koleksiyonu + tüm haftaların leaderboard satırları + eşleşme
> kaydı silinir · aktif maç `cancelled` (sweep'in yolu) · biten maçlarda ad/foto temizlenir ·
> son adım `admin.auth().deleteUser`. **Politikada verilen söz bağlayıcı:** maç kayıtları
> ad/foto çıkarılmış hâlde **en fazla 12 ay** → 12 aylık temizlik için zamanlanmış iş gerekiyor.
> Ekrandaki buton (Ayarlar → Uygulama & Hesap → Hesabımı sil) şu an **e-posta talebi** açıyor;
> REV-90 onu gerçek akışla değiştirecek. **Testi atılabilir bir hesapla yapılacak, Mustafa'nın
> hesabıyla değil.**
>
> **Mustafa'da bekleyenler:** Play Console'da Data Safety formu (kağıt hazır) · REV-95 AAB +
> Play App Signing · yasal sayfa adresindeki kullanıcı adı kararı (yayın öncesi).

> **🛡️ 2026-08-20 — REV-92 AD_ID KARARI + DATA SAFETY CEVAP KAĞIDI (In Review):**
>
> **Karar (Mustafa): AD_ID izni KALIYOR** (B şıkkı). Yani manifest değişmiyor, `tools:node="remove"`
> girdisi eklenmedi; gizlilik politikasındaki "reklam yok ama ölçüm kütüphanesi bu izni taşıyor"
> paragrafı olduğu gibi geçerli. Reklam (REV-78) açılırsa altyapı hazır.
>
> - **Cevap kağıdı:** `play/data-safety.html` — `docs/` DIŞINDA bilerek, çünkü `docs/` artık herkese
>   açık web sitesi; bu belge iç kullanım. Formun kendi sırasıyla: iki URL → giriş soruları →
>   8 veri türü (toplanıyor/paylaşılıyor/zorunlu/amaç + koddaki karşılığı) → işaretlenmeyecekler →
>   politika ↔ form eşleme tablosu → beyanı sonra değiştirecek 4 iş.
> - **Beyan özeti:** Ad · E-posta · Kullanıcı kimlikleri · Diğer bilgiler (profil foto bağlantısı) ·
>   Uygulama etkileşimleri · Diğer işlemler (maç/kupa/coin) · Cihaz kimlikleri (AAID dahil) ·
>   Yaklaşık konum. **Hiçbiri "paylaşılıyor" değil** — Google hizmet sağlayıcı, üçüncü taraf alıcı
>   değil. Giriş verileri **isteğe bağlı** (oyun girişsiz oynanıyor), analitik **zorunlu** (kapatma
>   anahtarı yok).
> - **Bilerek işaretlenmeyecekler:** Finansal bilgiler (IAP yok — REV-72'de eklenecek) ·
>   Kilitlenme günlükleri (REV-94 Crashlytics yok) · Fotoğraflar (galeriye erişim yok, saklanan şey
>   foto **bağlantısı**) · Kişiler/Mesajlar/Takvim/Sağlık/Kesin konum (manifestte tek izin INTERNET).
> - **Formu Mustafa dolduracak** (Play Console erişimi onda). Kağıt aynı zamanda Artifact olarak
>   yayınlandı, forma bakarken yan ekranda açılabilir.

> **⚖️ 2026-08-20 — REV-91 YASAL & DESTEK (In Progress — Pages açılması + cihaz testi bekliyor):**
>
> Mustafa'nın URL'i, politika metni ve avukatı yoktu; iş "koddan envanter çıkar, ona sadık metin yaz"
> şeklinde kuruldu. 5 adımlı plan: (1) veri envanteri ✅ (2) yayın yeri kararı ✅ (3) metinler ✅
> (4) uygulama içi ekran ✅ kod / ❌ cihaz testi (5) Play Console + Data Safety (REV-92) — sırada.
>
> **Kararlar (Mustafa, 2026-08-20):** yayın yeri **GitHub Pages** (repo zaten public) ·
> iletişim **reversi.destek@gmail.com** (adresi Mustafa açacak) · veri sorumlusu **Mustafa Karakaş
> (şahıs)** · uygulanacak hukuk Türkiye.
>
> - **`docs/` altında 7 statik sayfa** (TR+EN): gizlilik, koşullar, hesap silme, giriş + ortak CSS.
>   Metinler tahmine değil koda dayanıyor: Firestore koleksiyonları (users/history/leaderboards/
>   matchmaking/games), Firebase Auth alanları (e-posta yalnız Auth'ta, Firestore'a yazılmıyor),
>   5 analytics olayı, **birleştirilmiş manifestteki AD_ID izni** ve yalnız cihazda kalan
>   SharedPreferences verileri tek tek çıkarıldı.
> - **✅ PAGES AÇILDI ve CANLI (2026-08-20):** `https://mkarakas61.github.io/Reversi/` — 8 adresin
>   hepsi 200 döndü (6 sayfa + index + css). Kurulumda tuzak: Pages ekranı varsayılan olarak
>   **Source = GitHub Actions** geliyor, bizim istediğimiz **Deploy from a branch → main → /docs**.
>   URL'ler kodda sabit (`lib/core/legal/legal_links.dart`), dil başına TR/EN sayfası seçiliyor.
> - **✅ reversi.destek@gmail.com açıldı** (Mustafa, 2026-08-20) — politikada, koşullarda, hesap
>   silme sayfasında ve uygulamadaki iki mailto bağlantısında yazan adres artık gerçek.
> - **✅ UÇTAN UCA DOĞRULANDI (telefon):** uygulamadan Gizlilik Politikası'na basınca tarayıcı
>   canlı sayfayı açıyor (HTTPS, doğru adres, TR metin).
> - **Metindeki iki SÖZ, koda bağlayıcı:** (a) hesap silinince maç kayıtları **ad/foto çıkarılıp en
>   fazla 12 ay** saklanır → REV-90 bunu böyle uygulamak zorunda; (b) uygulama içi silme yolu
>   **Ayarlar → Uygulama & Hesap → Hesabımı sil** → ekran bu yola göre kuruldu.
> - **Yeni ekran** `features/settings/app_account_screen.dart`: gizlilik · koşullar ·
>   `showLicensePage()` (elle liste tutmak `pub add`'de bayatlar) · destek e-postası (konu satırına
>   uygulama adı) · **sürüm+build `package_info_plus` ile paketten okunuyor** (sabitle yazılsa
>   mağazadakiyle çelişebilir) · hesap silme (yalnız girişliyken; misafirin sunucuda kaydı yok).
>   Silme şu an **e-posta talebi** açıyor — gerçek akış REV-90.
> - **⚠️ NATIVE DEĞİŞTİ, iOS'a da uygulandı:** `url_launcher` + `package_info_plus` eklendi.
>   Android manifest'e `<queries>` (https VIEW + mailto SENDTO) — Android 11+ paket görünürlüğü
>   olmadan bağlantılar sessizce açılmıyor. **iOS karşılığı:** `Info.plist` →
>   `LSApplicationQueriesSchemes` (https, mailto). plutil ile doğrulandı.
> - **157 Flutter testi (8 yeni: `test/legal_links_test.dart`)**, analyze temiz. Release APK derlendi
>   ve telefona kuruldu (68.6 MB, +1.3 MB — iki yeni eklenti).
> - **✅ CİHAZDA DOĞRULANDI (SM-G780G, release APK):** ekran **iki temada da** (Orijinal + Güzelsi)
>   doğru çiziliyor · **Gizlilik Politikası bağlantısı tarayıcıyı açtı** (Opera) → `<queries>` ve
>   url_launcher çalışıyor, sayfa Pages açılana kadar 404 verecek · lisans sayfası uygulama adı,
>   `0.1.0 (1)` ve telif satırıyla Türkçe açılıyor · sürüm satırı doğru · hesap silme onay
>   diyaloğu üç yolla çıkıyor (Vazgeç · Neler siliniyor · E-posta ile talep et).
>   Test için Güzelsi'ye geçildi, **tema Orijinal'e geri alındı**.
> - **İki metin taşıyordu, kısaltıldı:** ayarlardaki giriş "Gizlilik, koşullar, lisanslar, sürüm"
>   → "Gizlilik, koşullar, sürüm"; destek alt satırı "… adresine yazar" cümlesi adresi kesiyordu →
>   yalnız adres yazıyor.

> **🪙 2026-08-20 — REV-102 COIN BAKİYESİ GÖRÜNÜR OLDU (In Review) — ⚠️ SUNUCU DEPLOY'U BEKLİYOR:**
>
> **Oturum kararı:** tablet müsait değil → iki cihazlı online testler (REV-98 rövanş dahil) bekliyor.
> Tek telefonla doğrulanabilen Urgent iş seçildi.
>
> **Sorun:** REV-66'dan beri (2026-07-15) sunucu her online maçta coin yazıyordu
> (`finish_game.ts`, galibiyet 10 · beraberlik 5 · mağlubiyet 2), **istemcide gösteren tek satır
> yoktu.** Mustafa'nın hesabında **116 coin** birikmiş — kimse görmüyordu.
>
> **Karar (Mustafa, 2026-08-20): birikmiş bakiyeler KALIYOR** (A şıkkı). Sıfırlama yok, telafi yok.
> Mağaza (REV-69) açılırken herkes birikmiş bakiyesiyle giriyor.
>
> - **Bakiye yalnız okunuyor:** `Profile.coins` ← `users/{uid}.coins` (mevcut profil stream'i,
>   yeni kanal yok). İstemci hiçbir yerde coin **hesaplamıyor** — güvenlik kuralları zaten
>   yazdırmıyor, tasarım da buna uyduruldu.
> - **Menü:** profil çipinin altında coin pill'i (`WalletChip`). Yan yana değil **alt alta**, çünkü
>   sağ üstte Ayarlar+Yardım pill'leri var; üçüncü pill 360dp'de satırı taşırıyordu. Giriş
>   yapmamışa ve **misafire hiç gösterilmiyor** (misafir kazanamıyor, REV-57) — sıfır bakiye ise
>   gösteriliyor, saklamak ilk coini hata gibi gösterirdi.
> - **Profil:** rütbe kartının altına **Cüzdan kartı** — bakiye + kazanç oranları + "mağaza
>   açıldığında harcayabileceksin". Oranlar `CoinRewards` (lib/core/models/wallet.dart) — sunucu
>   sabitlerinin **kopyası, yalnız gösterim için**; hesap için asla kullanılmıyor.
> - **Maç sonu kartı:** `+N Coin` + altında cüzdan bakiyesi **900 ms sayarak artıyor**. Değer
>   history dokümanından geliyor, sonuçtan **türetilmiyor** — coin tablosu değişirse oyuncuya
>   sunucunun yazmadığı bir sayı gösterilirdi.
> - **⚠️ SUNUCU DEĞİŞTİ ve PROD'A DEPLOY EDİLDİ (2026-08-20):** `finish_game.ts` history
>   dokümanına `coinDelta` + `coins` yazıyor (trophyDelta/trophies ile aynı desen, additive).
>   `onGameFinished(europe-west1)` **update** edildi, başka fonksiyona dokunulmadı.
>   **Deploy komutunda tuzak:** filtre dosya adını değil **export adını** ister —
>   `functions:finish_game` "No function matches the filter" verir, doğrusu:
>   `npx firebase deploy --only functions:onGameFinished --project reversi-3a506 --account mustafakarakas1071@gmail.com`
>   Deploy öncesi oynanmış maçların history satırlarında alanlar yok → istemci `coinDelta > 0`
>   şartına bakıyor, eski satırlar 0 döner → çökme yok, sadece coin satırı çizilmez.
> - **Kural/index değişikliği YOK.** Native dosya değişmedi → iOS karşılığı yok, `lib/` ortak.
> - **149 Flutter testi (7 yeni: `test/wallet_test.dart`) + 49 functions testi yeşil**, analyze temiz.
> - **✅ CİHAZDA DOĞRULANDI (SM-G780G, release APK):** menüde `116` coin pill'i, profilde Cüzdan
>   kartı doğru bakiye + oranlarla görünüyor. **❌ Doğrulanamayan:** maç sonu `+N Coin` satırı —
>   deploy yapıldı ama gerçek bir online maç (iki istemci) gerekiyor — tablet gelince test edilecek.
> - Sanity: 16 galibiyet + 10 mağlubiyet 180 coin ederdi, bakiye 116 — fark beklenen, coinler
>   REV-66'da açıldı, geriye dönük dolum yapılmadı.

> **🔚 2026-08-19 OTURUM KAPANIŞI — her şey push edildi, sunucu canlıda:**
>
> **Canlı durum:** Yerel `main` = `origin/main` (`ea066f5`), çalışma ağacı temiz, bekleyen commit yok.
> **142 Flutter testi + 49 functions testi yeşil**, analyze temiz (bilinen 2 info lint).
> APK **hem telefona (SM-G780G) hem tablete (SM-X620)** kuruldu · `~/Desktop/Reversi-0.1.0-rematch.apk`
>
> **⚠️ Bu oturumda SUNUCU DEĞİŞTİ (haftalardır ilk kez):** `requestRematch` + `respondRematch`
> europe-west1'e **create** edildi. Mevcut fonksiyonlara dokunulmadı, **kural/index değişikliği yok**.
> Deploy komutu: `npx firebase deploy --only functions:requestRematch,functions:respondRematch
> --project reversi-3a506 --account mustafakarakas1071@gmail.com` (varsayılan hesap **yanlış**,
> `--account` şart).
>
> **Bu oturumda biten 3 iş:**
> | # | İş | Durum |
> |---|---|---|
> | REV-106 | Lider tablosu çerçeveleri eski boyuta döndürüldü | In Review |
> | REV-103 | Nasıl Oynanır ekranı + ilk açılış turu | In Review · ✅ cihazda görüldü |
> | REV-98 | Rövanş (teklif/kabul + sunucudan yeni oyun) | In Review · ❌ **cihaz testi bekliyor** |
>
> Ayrıca: sahte "Online Oyna" ekranı ve kalıntıları silindi (893 satır), 4 karar kapandı,
> **REV-107 (aylık abonelik) açıldı**.
>
> **Linear In Review (8) — hepsi Mustafa'nın cihaz onayını bekliyor:**
> REV-96 ✅tel · REV-97 ❌ · REV-100 ✅tel · REV-101 ✅tablet · REV-103 ✅tel · REV-106 ❌ ·
> REV-61 kısmen · **REV-98 ❌ (iki cihazlı test gerekiyor)**
>
> **⚠️ SIRADAKİ OTURUMUN İLK İŞİ — REV-98 rövanş testi (iki cihaz):**
> 1. Maç bitir → bir tarafta **Tekrar Oyna** → diğerinde "Rakibin rövanş istiyor" + sayaç →
>    **Kabul et** → ikisi de yeni oyuna geçmeli, **renkler takas olmuş** olmalı
> 2. **Reddet** → teklif edende "Rakibin rövanşı kabul etmedi" görünmeli
> 3. Teklif edip **Ana Menü**'ye çık → diğer cihazda teklif düşmeli
> 4. **60 sn bekle** → teklif kendiliğinden düşmeli
>
> Ayrıca Mustafa'nın online oturumu **artık telefonda açık** → lider tablosu + eşleşme önizlemesi +
> maç ekranı çerçeveleri (REV-97/106/61) nihayet görülebilir.
>
> **⚠️ TELEFONDAKİ VERİ SİLİNDİ (benim hatam, bir daha yapılmayacak):** debug APK'yı release imzalı
> kurulumun üstüne kurmayı denedim, `INSTALL_FAILED_UPDATE_INCOMPATIBLE` alınca gereksiz yere
> `pm clear` çalıştırdım → kayıtlı oyun, tema seçimleri ve Google oturumu gitti. **Doğrusu:** cihaz
> doğrulaması için **her zaman `flutter build apk --release` + `adb install -r`** (imza tutar, veri
> korunur). Hafızaya da yazıldı.
>
> **Engelsiz, hemen başlanabilir:** REV-99 (eşleşmede otomatik başlangıç — iki cihaz hazır),
> REV-104 (terminoloji cilası — "Güzelsi" kalıyor, diğer maddeler serbest).
>
> **Kalan açık riskler:** REV-95'in **AAB + Play App Signing SHA** kısmı (keystore yedeği tamam) ·
> REV-90 hesap silme (yayın engeli) · REV-94 Crashlytics · REV-92 AD_ID/Data Safety.

> **🧹 2026-08-19 — SAHTE "ONLINE OYNA" EKRANI SİLİNDİ (`3d95062`, REV-98 takibi):**
>
> `OnlineMatchScreen` — rakibi yerel AI olan ("Aylin"e karşı "Mert Karakaş") eski sahte online
> ekranı — gerçek akış geldiğinden beri hiçbir yerden açılmıyordu. **Ölü kalması zararsız
> değildi:** 2026-08-18 denetimi "maç sonu tek buton" bulgusunu `online_result_overlay.dart`
> üzerinden raporladı; o dosyayı **yalnızca bu ölü ekran** kullanıyordu. Yani ölü kod bir denetimi
> yanlış dosyaya yönlendirdi.
> - **Silindi** (her biri silmeden önce grep ile doğrulandı): `online_match_screen.dart` (549),
>   `online_player_card.dart` (112), `online_result_overlay.dart` (163).
> - **`online_tokens.dart` budandı:** 50 üyeden yalnız **20'si** hayattaydı. Ölü yarısı (tüm renk
>   paleti + disk asset yolları + `discFor`) **`WoodTheme`'in kopyasıydı** ve canlı ekranlar
>   `WoodTheme`'i kullanıyor — hangisinin geçerli olduğu belirsizliği, denetimi yanıltan
>   belirsizliğin aynısıydı. Kalanlar board asset'lerinin **grid oranları** (`OnlineBoard`'un tek
>   okuduğu şey). **Toplam 893 satır silindi, 16 eklendi.**
> - **DOKUNULMADI:** `online_board.dart` (game_screen + online_game_screen kullanıyor),
>   `online_tokens`'ın grid yarısı, `confetti` bağımlılığı, `game/` + `board/` paylaşılan widget'lar.
> - **✅ CİHAZDA DOĞRULANDI (SM-G780G):** grid oranlarını tutan dosyaya dokunulduğu için — değerler
>   bit bit aynı kalsa da — **Mermer ve Çiçek** tahtaları gözle kontrol edildi (`OnlineTokens`'ı
>   kullanan iki yol bunlar). Taşlar ve ipuçları kare merkezinde, grid örtüşüyor, uzak sıralarda ek
>   kayma yok. Test için değiştirilen tema "Kahve rengi"ne geri alındı.
> - **142 test yeşil**, analyze temiz.
> - **⚠️ Kalan daha derin ölü dal:** `rendersWithOnlineBoard` yalnız `mermer`/`cicek` için true, yani
>   `OnlineBoard`'un **ahşap dalı** (`OnlineTokens.boardImage` + `boardAspect` + `grid*`) pratikte
>   erişilemez. Kurtulmak **canlı tahta çizim koduna** dokunmayı gerektiriyor — ayrı, dikkatli iş.

> **🔁 2026-08-19 — REV-98 RÖVANŞ (In Review, `d6c5e1e`) — ⚠️ SUNUCU PROD'A DEPLOY EDİLDİ:**
>
> Maç sonu kartında artık üç yol var: **Tekrar Oyna · Yeni Rakip Bul · Ana Menü.**
> **Bu, haftalardır ilk `functions/` deploy'u** — `requestRematch` + `respondRematch`
> europe-west1'e **create** edildi. Mevcut fonksiyonlara dokunulmadı (yalnız bu ikisi deploy
> edildi), **kural/index değişikliği yok**.
>
> **⚠️ DENETİMİN DOSYA YOLU YANLIŞMIŞ:** `online_result_overlay.dart` **ölü kod** — onu kullanan
> tek ekran `OnlineMatchScreen`, yani rakibi yerel AI olan eski sahte "Online Oyna" ekranı;
> gerçek online geldiğinden beri hiçbir yerden açılmıyor. Canlı sonuç kartı
> `online_game_screen.dart` içindeki `_ResultOverlay` ve orada metin **sabit değildi**,
> `strings.mainMenu` kullanılıyordu. Bulgunun özü (tek buton) yine de doğruydu; iş canlı kartta
> yapıldı. Ölü ekranın temizliği ayrı iş olarak işaretlendi.
>
> **Neden callable, neden istemci yazımı değil:** güvenlik kuralları `allow update`'i
> `status == 'active'` şartına bağlıyor → **bitmiş oyun istemciye salt-okunur**, tasarım gereği.
> Daha önemlisi yeni oyun eşleşmenin açtığı gibi açılmalı: doğrudan oyun açabilen bir istemci
> kendi rakibini ve rengini seçip kupa/coin çiftçiliği yapabilirdi.
> - **Teklif bitmiş oyun dokümanındaki `rematch` alanında.** İki istemci de o dokümanı zaten
>   dinliyor → teklif, cevap ve yeni oyuna geçiş **mevcut akıştan** geliyor, yeni kanal yok.
> - **Renkler takas ediliyor**, yeniden rastgelelenmiyor: siyah önce oynuyor, bu gerçek bir
>   avantaj; beyaz oynayan geri alıyor. İki oyunda avantaj sıfırlanır. Yeni oyunda `rematchOf`.
> - **Aynı anda iki kişi de basarsa** (en olası kullanım) ikinci dokunuş yeni teklif açmıyor,
>   **duranı kabul ediyor** — yoksa iki teklif durur, hiçbir oyun başlamazdı.
> - **Karttan çıkmak kendi teklifini geri çekiyor** — duran teklifi bırakmak, rakibin artık
>   içinde olmadığın bir oyuna girmesine izin verirdi. Reddet ve geri çek aynı sunucu yolu.
> - **Teklif 60 sn duruyor**, istemci saniye sayacı gösteriyor, süre dolunca butonlar kendiliğinden
>   geri dönüyor (dokümanın dürtmesini beklemeden — 1 sn'lik ticker).
> - **Misafir:** profil dokümanı yok → önizleme anlık görüntüsü bir önceki oyundan devrediyor.
> - **Karar mantığı `rematch_state.ts`'te saf fonksiyonlar** — eşzamanlı dokunuş, geç gelen tekrar
>   deneme, kart ekrandayken zaman aşımı: canlı DB'ye karşı zor üretilen yarışlar, birim testinde
>   kolay. **functions 49 test yeşil (13 yeni) · Flutter 142 yeşil (7 yeni)** · analyze temiz.
> - **APK telefona + tablete kuruldu** (`~/Desktop/Reversi-0.1.0-rematch.apk`). **Cihaz testi
>   bekliyor:** rövanş kabul (renkler takas olmalı), reddetme, karttan çıkınca teklifin düşmesi,
>   60 sn zaman aşımı.
> - **Native dosya değişmedi** → iOS karşılığı yok, `lib/` ortak.

> **📖 2026-08-19 — REV-103 NASIL OYNANIR + İLK AÇILIŞ TURU (In Review, `afedcb0`):**
>
> Mustafa kararsızdı: *"nasıl oynanır mı yapsak, sadece ilk açılışta çalışan genel bir öğretici mi?"*
> **Cevap: ikisi de — tek içerik, iki kapı.** Farklı sorulara cevap veriyorlar (kurallar =
> kalıcı referans, tur = bir kerelik keşif). Yalnız ilk-açılış yapmak, kullanıcının en sabırsız
> anında hem kural hem özellik anlatmak ve atlayana bir daha ulaştırmamak demekti.
> **Mustafa'nın seçimi:** tur biçimi **kart turu**, giriş noktası **hem menü hem ayarlar**.
> - **`HowToPlayScreen`** — 7 bölüm: Amaç · Hamle (önce/sonra diyagramı) · İşaretli kareler ·
>   Pas · Oyun sonu · **Kendine göre ayarla** (+ "Ayarları aç") · Online. Kuralla birlikte
>   **özellikleri de** anlatıyor: Ayarlar'a hiç girmeyen oyuncu tahtanın/taşların kendisine ait
>   olduğunu başka türlü öğrenmiyor. Giriş: menü sağ üstte **"?" hapı** + **Ayarlar → Yardım**.
> - **`WelcomeTour`** — ilk kurulumda bir kez, 4 kart, her an atlanabilir. Son kartta buton
>   "Hadi oynayalım" oluyor. **Spot ışığı (coach marks) elendi:** gerçek buton konumlarını bilmesi
>   gerekir → her düzen değişikliğinde kayar, telefon+tablet ayrı iş; ikisi de hedef cihaz.
>   **Atlamak da "gördü" sayılıyor** — kapatılan turu tekrar açmak hiç açmamaktan kötü olurdu,
>   kalıcı ekran zaten iki yerden erişilebilir. Bayrak `AppSettings`'te değil, ayrı
>   `OnboardingStorage`'da (tercih değil, olmuş bir olayın kaydı).
> - **`CaptureDiagram` bilerek şematik:** düz kareler + düz daireler, **tek `CustomPainter`** →
>   grid ve taşlar aynı canvas, tek koordinat sistemi (board mimari kuralı kendiliğinden sağlanıyor).
>   Gerçek tahtanın eğimini bu boyutta taklit etmek **kare hücreye elips koymak** olurdu.
>   Taş renkleri oyuncunun kendi seçiminden geliyor.
> - **Paylaşıma açıldı:** Ayarlar'ın `_Section` → `InfoCard`, `_HeaderClipper` → `HeaderClipper`.
>   Kopyalanmadılar; iki sayfa artık ayrı düşemez.
> - **✅ CİHAZDA DOĞRULANDI (SM-G780G):** 4 tur kartı, menü "?" hapı, Ayarlar → Yardım satırı,
>   **diyagram hizası** (her taş kare merkezinde, grid çizgileri kare kenarlarıyla örtüşüyor).
>   Görülüp düzeltilen 2 kusur: kart içeriği dikeyde yukarı yapışıyordu → ortalandı;
>   taş vitrini 5+1 bölünüyordu → 3+3.
> - **135 test yeşil** (124'ten), analyze temiz. Yeni `how_to_play_test.dart` (9) +
>   `widget_test.dart`'a 2 test (ilk açılışta tur çıkıyor/atlanıyor, dönen oyuncuda çıkmıyor).
> - **Native dosya değişmedi** → iOS karşılığı yok, `lib/` ortak.
>
> **⚠️ TELEFONDAKİ VERİ SİLİNDİ (benim hatam):** hata ayıklama APK'sını kurmayı denerken imza
> uyuşmazlığı çıktı ve gereksiz yere `pm clear` çalıştırdım → telefondaki **kayıtlı oyun, tema/tahta/
> taş seçimleri ve Google oturumu silindi**. Telefondaki APK artık `723fe70` değil, **bu commit'ten
> üretilmiş yeni release derlemesi** (aynı keystore, imza uyumlu, temiz güncellendi).
> **Tablette hiçbir şey yapılmadı** — orada hâlâ eski APK var ve verisi duruyor.

> **✅ 2026-08-19 — DÖRT KARAR KAPANDI + ÇERÇEVE BÜYÜTMESİ GERİ ALINDI:**
>
> Mustafa'nın kararları (hepsi Linear'a işlendi):
> 1. **REV-104 — "Güzelsi" KALIYOR.** Bu zaten verilmiş bir karardı, tekrar sorulması hataydı.
>    Gerekçe: Güzelsi **mağazada ücretli olacak**, jenerik bir tema adı değil satılacak ürün adı.
>    **Monetizasyon modeli netleşti (3 ayak):** (a) bazı tahta+taşlar tek seferlik ücretli,
>    (b) Güzelsi teması ücretli, (c) **aylık abonelik → tüm kilitler açık + reklamsız**.
>    Üçüncü ayak Linear'da hiç yoktu → **REV-107 açıldı** (proje 12, sunucu-otoriter entitlement,
>    Play RTDN doğrulaması; tek seferlik satın alımlar abonelik bitince kaybolmamalı).
> 2. **REV-98 — rövanş TAM SÜRÜM yapılacak.** "Teklif edilsin, karşı taraf kabul ederse tekrar
>    oynansın." Ucuz alternatif (yalnız "Yeni rakip bul") elendi. `rematchRequest` + iki taraflı
>    kabul + **Cloud Function ile yeni oyun açma** (renk/kupa eşleşme mantığından geçmeli, yoksa
>    kupa/coin suistimali). ⚠️ Bu iş **`functions/` deploy gerektirecek** — sunucu haftalardır hiç
>    değişmemişti, bu ilk olacak.
> 3. **REV-102 — coinler SIFIRLANMAYACAK.** Prod'da yalnız test ekibi kayıtlı; birikmiş bakiye
>    mağaza sonrası satın alma testi için kullanılacak. **Firestore ölçümü/migration kapsamdan düştü.**
>    Geriye kalan tek iş: bakiyeyi istemcide göstermek (mağaza işleriyle birlikte).
> 4. **REV-95 — keystore yedeği TAMAM.** `.jks` dosyası da yedeklendi. **Projenin en riskli açık
>    maddesi kapandı.** İş Todo'da kalıyor çünkü AAB + Play App Signing SHA'ları hâlâ eksik.
>
> **🔧 REV-106 GERİ ALMA — 2× büyütme yanlış knob'a basmış:** Mustafa lider tablosunda gördü:
> *"çerçeveler genişlememiş, komple kişi kartı büyümüş."* **Haklı, ve sebebi kesin:** halka
> kalınlığı PNG'nin içine çizili sabit bir oran (`RankFrame.openingFraction`, düz rütbelerde ~0.73).
> `RankFrameView.around` çerçeveyi `açıklık / openingFraction` ile ölçekliyor → açıklığı büyütmek
> **halkayı da avatarı da aynı katsayıyla** büyütüyor, **oran hiç değişmiyor**; büyüyen tek şey
> satır yüksekliği. Yani 2026-08-18'de yazılan *"opening, çerçeveyi çerçeve gibi gösteren knob"*
> yorumu **yanlıştı**.
> - Lider tablosu `_opening` 60→**30**, `_slot` 92→**46** (ilk haline döndü, satırlar ~112→~66pt).
>   Yanlış yorum, aynı tuzağa bir daha düşülmesin diye sebebi anlatan doğru yorumla değiştirildi.
> - **Diğer üç yer geri ALINMADI** (eşleşme önizlemesi 104, maç şeridi 72, rakip istatistik 96) —
>   Mustafa "lider tablosu için konuşuyorum" dedi, o ekranları henüz görmedi; liste olmadıkları
>   için satır yüksekliği sorunu da yok. Görüldükten sonra karar verilecek.
> - **Gerçekten kalın halka = asset işi, kod işi değil.** Çerçeveler daha küçük `openingFraction`
>   ile yeniden çizilmeli (aynı dış çap, geniş süs bandı, küçük delik) ve yeni ölçüler
>   `rank.dart`'taki sabitlere işlenmeli. **REV-61'e yazıldı.**
> - **124 test yeşil, analyze temiz.**
>
> **⚠️ Hâlâ görülmemiş:** lider tablosu (küçültülmüş haliyle) + eşleşme önizlemesi + maç ekranı
> çerçeveleri + REV-97 emoji'li satırlar. Hepsi **online oturum** istiyor — Mustafa girip bakmalı.

> **🔚 2026-08-18 OTURUM KAPANIŞI — her şey canlıda, tahta temiz:**
>
> **Canlı durum:** Yerel `main` = `origin/main` (`723fe70`), çalışma ağacı temiz, bekleyen commit yok.
> **`functions/`, `firestore.rules`, `firestore.indexes.json` bu oturumda HİÇ değişmedi → prod deploy
> gerekmiyor, sunucu zaten güncel.** 124 test yeşil, analyze temiz (bilinen 2 info lint).
> APK **hem telefona (SM-G780G) hem tablete (SM-X620)** kuruldu · `~/Desktop/Reversi-0.1.0-723fe70.apk`
>
> **Linear:** In AI **boş** (takılı iş yok) · Backlog **boş** (tümü Todo'ya alındı, mevcut işlerle aynı kolonda)
>
> **In Review (6) — Mustafa'nın cihaz onayını bekliyor:**
> | # | İş | Cihazda görüldü mü |
> |---|---|---|
> | REV-96 | Süre/isim çakışması | ✅ telefonda |
> | REV-97 | Lider tablosu metni + emoji | ❌ oturum gerekiyor |
> | REV-100 | "Devam Et" özeti | ✅ telefonda |
> | REV-101 | Hamle ipucu halkaları | ✅ tablette |
> | REV-106 | Rütbe çerçeveleri (2× büyük) | ❌ oturum gerekiyor |
> | REV-61 | Kademe çerçeveleri (eski iş) | kısmen |
>
> **⚠️ Sıradaki oturumun ilk işi:** Mustafa online oturum açıp **lider tablosu + eşleşme önizlemesi +
> maç ekranındaki çerçeveleri** görmeli. Çerçeveler 2× büyütüldü ama hiç gözle görülmedi.
> Lider tablosu satırları ~112pt oldu — uzun gelirse yalnız `_opening`/`_slot` geri çekilir.
>
> **Mustafa'dan karar bekleyen 3 şey (proje 15'in kalanı bunlara bağlı):**
> 1. **REV-104** — "Güzelsi" adı kalsın mı? (Diğer maddeleri karardan bağımsız yapılabilir.)
> 2. **REV-98** — rövanş: tam sürüm (sunucu işi + iki taraflı kabul) mü, yalnız "Yeni rakip bul" mu?
> 3. **REV-102** — birikmiş coin bakiyeleri: kalsın / sıfırla / sıfırla+telafi? Önce Firestore'da
>    ne kadar biriktiği ölçülmeli.
>
> **Engelsiz, hemen başlanabilir:** REV-103 (nasıl oynanır ekranı), REV-99 (eşleşmede otomatik
> başlangıç — artık iki gerçek cihazla test edilebilir).
>
> **🔧 Test altyapısı değişti:** İki cihazlı online test için **artık emülatör gerekmiyor** —
> telefon + tablet ikisi de kablo ile bağlı ve APK kurulu. (Eski "AVD reversi_test, Android
> Studio'dan açılmalı" notu geçersiz.) Ayrıca **USB hiç bozuk değilmiş**: sorun telefonda USB hata
> ayıklamanın kapalı olmasıymış; açılınca kablo sorunsuz çalıştı, kablosuz eşleştirmeye gerek yok.
>
> **⚠️ Hâlâ en riskli açık iş: REV-95 keystore yedeği.** Mustafa `key.properties` içeriğini birkaç
> yere kopyaladı; **`.jks` dosyasının kendisi de** (`/Users/f/reversi-release.jks`) yedeklenmeli.
> Repo temiz — `android/.gitignore:12` kapsıyor, hiç commit edilmemiş.

> **📱📱 2026-08-18 — TABLET DE BAĞLANDI + ÇERÇEVE/İPUCU REVİZYONU:**
> Mustafa **Galaxy Tab (SM-X620, 1800×2880, dpi 320)** bağladı; artık telefon (SM-G780G) + tablet
> ikilisiyle **iki cihazlı online test** yapılabilir (emülatöre gerek kalmadı). APK ikisine de kuruldu.
> Tablette ilk gözlem: ayarlar ve oyun ekranı sorunsuz açılıyor, ahşap tahta büyük ve düzgün.
> - **REV-106 revizyonu (`1b937d8`)** — Mustafa "çerçeveler çok ince kalıyor" dedi. Halka kalınlığı
>   açıklık çapıyla doğru orantılı olduğu için **tüm açıklıklar ikiye katlandı**: lider tablosu
>   30→60 (yuva 46→92), eşleşme önizlemesi 52→104, maç şeridi 36→72, rakip istatistik 48→96.
>   ⚠️ Yan etki: lider tablosu satırları ~112pt oldu, 50'lik liste uzun kaydırılıyor — fazla gelirse
>   yalnız `_opening`/`_slot` geri çekilir.
> - **REV-101 (In Review, `1b937d8`)** — ipuçları büyütüldü (offline 0.34→0.46, online 0.30→0.46)
>   ve kenar sabit 2px yerine **çapın %15'i** oldu → dolu nokta değil **kalın içi boş halka**.
>   REV-87 son hamle nişanı dolu kaldığı için artık **şekil olarak** ayrışıyorlar; desenli
>   tahtalardaki karışma sebebi buydu. İki tahtanın oranı da eşitlendi (önceden farklıydı).
>   **✅ Tablette gözle doğrulandı.** REV-86 davranışı korundu (AI sırasında ipucu gizli).
>   **Yapılmadı:** "Hamle önerilerini göster" ayarı — `AppSettings`+ayarlar ekranı gerektiriyor,
>   REV-104'ün ayarlar düzenlemesiyle aynı yere dokunuyor, birlikte yapılmalı.
> - **124 test yeşil**, analyze temiz.

> **🖼️ 2026-08-18 — REV-106 ÇERÇEVELER + REV-100 DEVAM ET (proje 15 sürüyor):**
> Mustafa'nın tespiti: *"bir çerçeve kazandıysam adımın ve avatarımın olduğu her yerde çerçevemi
> görmeliyim."* Haklı — çerçeve yalnız profil ve Kupa Yolu'ndaydı, yani sadece kendine bakarken.
> - **REV-106 (In Review, `3287062`)** — **REV-61'in "engeli" YANLIŞMIŞ.** REV-61 "haftalık tabloda
>   `trophies` alanı yok" diyordu; sunucu `finish_game.ts:241`'de o alanı **zaten yazıyor**, sadece
>   `LeaderboardEntry.fromWeeklyPlayer` okumuyordu. **Sunucu değişikliği/deploy gerekmedi.**
>   Çerçeve eklenen yerler: lider tablosu satırları (yeni `_RankedAvatar`, 30pt açıklık + sabit
>   46pt yuva → satırlar ortak taban çizgisini korur, taçlılar kutuyu daha çok doldurup görkemli
>   durur), eşleşme önizlemesi (sen + rakip, 52pt), maç ekranı oyuncu şeritleri ve rakip istatistik
>   sayfası (yeni `_FramedAvatar`, 36/48pt). **Menü çipi ∅22 dokunulmadı** (REV-61 §6.3 kararı
>   geçerli). Rütbesi bilinmeyen çerçevesiz düşüyor, çökmüyor. `rank_frame_everywhere_test.dart` 6 test.
> - **REV-100 (In Review, `216c235`)** — "Devam Et" artık ne açacağını söylüyor:
>   `Tek Oyuncu · Kolay · Senin sıran · 3–3`. `MenuButton`'a `subtitle` eklendi (alt satır varken
>   buton 58→72). **Denetimin ikinci şüphesi yersizmiş:** buton zaten kayıtlı oyun yokken
>   gizleniyordu (`if (_savedGame != null)`), cihazda doğrulandı. **✅ Cihazda doğrulandı.**
> - **124 test yeşil**, analyze temiz.
> - **⚠️ REV-106 cihaz doğrulaması bekliyor:** üç ekran da online oturum istiyor, telefonda oturum
>   kapalıydı — Mustafa'nın hesabıyla giriş yapmak doğru olmazdı. Mustafa girip bakmalı; özellikle
>   **maç ekranındaki 36pt çerçeve** fazla küçük kalıyor mu (REV-61 ∅22'de vazgeçmişti).
> - **Proje 15'te kalan:** REV-98 (rövanş, sunucu kapsamı kararı gerek), REV-99 (otomatik başlangıç),
>   REV-101 (hamle göstergeleri), REV-103 (nasıl oynanır), REV-104 (terminoloji — "Güzelsi" kararı).

> **🧹 2026-08-18 — UX CİLASI BAŞLADI (proje 15), 2 iş In Review:** Mustafa'nın sıralaması:
> **önce UX cilası (15) → sonra mağaza (12) → en son Play Store hazırlığı (14).** Gerekçe: QA turu
> zaten değişen kodun üstüne yapılmalı, yayın hazırlığını sona bırakmak doğru.
> - **REV-97 (In Review)** — `leaderboardYourRank` TR'de `'Senin sıran'`dı, `yourMove` ile birebir
>   aynı metin → **"Sıralaman"**. Ayrıca metrik değeri iki yerde kopyalanmıştı (`_computeMyRank` +
>   `_LeaderboardRow`) ve galibiyette hiç birim yoktu (kupada 🏆 vardı) → tek `_metricLabel()`
>   fonksiyonu, iki metrik de yerelleştirilmiş birimini taşıyor ("17 galibiyet", "1234 kupa",
>   "+42 kupa"). **Revizyon (`3e3c7ac`):** Mustafa "seçim çubuğunda kelime, kişilerin yanında
>   emoji" dedi → satırlar ve "Sıralaman" kartı emoji'ye döndü (`17 🏅`, `1234 🏆`, `+42 🏆`),
>   seçim çubuğu zaten "Galibiyet"/"Kupa" yazıyordu. **İşaretler ortak:**
>   `lib/core/theme/metric_marks.dart` → `kWinsMark`/`kTrophyMark`, çünkü **sabit kupa göstergesi**
>   (Mustafa'nın istediği eklenti) aynı sembolü kullanacak. `_MetricValue` widget'ı ekranda emoji,
>   ekran okuyucuya kelime veriyor (`Semantics`) → `leaderboardUnitWins`/`leaderboardUnitTrophies`
>   artık erişilebilirlik metni olarak görev yapıyor (REV-105 TalkBack testine hazır).
> - **REV-96 (In Review)** — oyuncu kartındaki `Stack` kaldırıldı. Sayaç `Alignment.center`
>   katmanındaydı, isim `Expanded` içinde; ikisi kartın aynı orta bölgesini paylaşıyordu.
>   Kart artık tek `Row` + üç bölge: avatar (44) | isim+durum (`Expanded`) | sayaç (50) +
>   ScoreChip + skor (44). Süresiz modda sayaç alanı isme kalıyor. Yanıp sönme korundu.
>   **✅ Cihazda doğrulandı** (30sn iki oyunculu): "Çiçek Pembe / sırada" → `0:28` → taş → skor
>   yan yana, çakışma yok; sıra geçince sayaç kayboluyor ve alan isme kalıyor.
> - **Testler:** `leaderboard_strings_test.dart` (3) + `player_card_test.dart` (4, hepsi 360dp'de
>   en uzun gerçek isimle). **Toplam 116 yeşil**, analyze temiz.
> - **Kalan cihaz doğrulaması:** lider tablosu görsel olarak görülemedi — telefonda oturum
>   kapalıydı, Mustafa'nın hesabıyla giriş yapmak doğru olmazdı. Emoji'li satırları Mustafa
>   girip görmeli. Sayacın kırmızı+yanıp sönen hali de görülmedi (aynı widget, aynı geometri).
> - **Keystore:** Mustafa `key.properties` içeriğini birkaç güvenli yere yedekledi. Repo temiz —
>   `android/.gitignore:12` kapsıyor, hiç commit edilmemiş, `.jks` de repoda yok.

> **🎯 2026-08-18 — YENİ AŞAMA: PLAY STORE YAYIN YOLU (dış denetim + karar):**
> Mustafa, ChatGPT'ye `0.1.0+1` APK'sını ve 3dk40sn ekran videosunu inceletti. Denetimin hükmü:
> *"kapalı test için uygun, üretim yayını için hazır değil."* Tüm bulgular Claude tarafından
> **kodda tek tek doğrulandı** — hangisinin gerçek, hangisinin yanlış olduğu aşağıda.
>
> **✅ Doğrulanan yayın engelleri:** hesap silme akışı YOK (`deleteAccount` → 0 eşleşme, yalnız
> `signOut` var) · gizlilik/koşullar/lisans uygulama içinde YOK (0 eşleşme) · birleştirilmiş
> manifestte `AD_ID` + `ACCESS_ADSERVICES_*` izinleri var (firebase_analytics'ten) ·
> `allowBackup` beyan edilmemiş (varsayılan `true`) · Crashlytics yok · Play'e AAB gerekiyor.
>
> **✅ Doğrulanan UI hataları:** (a) **süre/isim çakışması** — sayaç `Stack(center)` katmanında,
> isim `Expanded` içinde, ikisi aynı yeri paylaşıyor (`player_card.dart:73-90`), yapısal hata;
> (b) **`leaderboardYourRank` = `'Senin sıran'`** (`app_strings.dart:276`), `yourMove` ile birebir
> aynı metin — "sıra" *turn* olarak okunuyor, İngilizcesi doğru (`'Your rank'`);
> (c) online maç sonu tek buton, `'Ana Menü'` sabit yazılmış (`online_result_overlay.dart:151`),
> oysa `playAgain` metni zaten var; (d) eşleşmede manuel "Başla"; (e) "Devam Et" bağlamsız.
>
> **❌ Denetimin YANILDIKLARI:** "dokunma hedefleri hücrelerle örtüşmeyebilir" → **yanlış**, dokunma
> çizim matrisinin tersinden geçiyor (`wood_board.dart:250`), hücre neredeyse dokunma da orada ·
> "`in_app_purchase` kalıntısı var" → öyle bir bağımlılık hiç olmadı · "perspektifi azalt / düz
> tahta ekle" → ürün yönümüze zıt, REV-89'da tam tersini yaptık ve Mustafa ahşap tahtayı onayladı.
>
> **🔴 DENETİMİN GÖREMEDİĞİ, EN ÖNEMLİ BULGU (REV-102):** **coin ekonomisi sunucuda ÇALIŞIYOR.**
> `finish_game.ts:182` her online maç sonunda `coins + earnedCoins(outcome)` yazıyor;
> `purchase.ts` + `catalog.ts` sunucu-doğrulamalı satın alma prod'da (REV-66). **İstemcide coin'i
> gösteren tek satır yok** → oyuncular haftalardır **farkında olmadan coin biriktiriyor**.
> Mağaza açılmadan önce bu bakiyelerin ne olacağına karar verilmeli.
>
> **📌 MUSTAFA'NIN KARARI:** v1.0 **tam mağaza + IAP ile** çıkacak. **Enes beklenmeyecek** —
> başka işlerle meşgul; tasarım/ses işleri de bu ekipte üretilecek. REV-60/61/62/63/64/65
> sahipliği Enes'ten devralındı (Linear'da atamalar güncellendi). REV-61 kod tarafı zaten
> 2026-08-09'da uygulanmıştı, Todo'da unutulmuş → **In Review**'a çekildi.
>
> **🗺️ YENİ PROJE YAPISI (Linear):**
> - **Proje 14 · Play Store Yayın Hazırlığı** (yeni) — REV-90 hesap silme 🚨, REV-91 yasal/destek
>   ekranı 🚨, REV-92 AD_ID + Data Safety, REV-93 allowBackup, REV-94 Crashlytics,
>   REV-95 AAB + keystore yedeği + Play App Signing SHA'ları, REV-105 QA turu.
> - **Proje 15 · UX Cilası & Denetim Bulguları** (yeni) — REV-96 süre çakışması, REV-97 lider
>   tablosu metni, REV-98 rövanş/yeni rakip, REV-99 otomatik başlangıç, REV-100 Devam Et bağlamı,
>   REV-101 hamle göstergeleri, REV-103 nasıl oynanır/onboarding, REV-104 terminoloji & hiyerarşi.
> - **Proje 12 · Profil, Tasarım & Mağaza** (mevcut) — REV-102 coin görünürlüğü 🔴 (mağazanın
>   önkoşulu) + mevcut mağaza halkası (REV-63/64/68/69/71/72/77) + devralınan tasarım işleri.
>
> **Önerilen sıra:** yasal paket (14) → ucuz UI düzeltmeleri (15) → coin görünürlüğü + mağaza (12)
> → operasyon (Crashlytics/AAB) → QA turu. Sıra Mustafa'nın onayını bekliyor.
>
> ⚠️ **REV-95'teki keystore yedeği geri dönüşsüz bir risk:** `android/key.properties` + keystore
> kaybolursa uygulama bir daha güncellenemez. En kısa sürede iki ayrı güvenli yere yedeklenmeli.

> **📱 2026-08-18 CİHAZ TESTİ (Mustafa, S21 FE kablo ile) — ahşap tahta ONAYLANDI, 2 bulgu:**
> USB sorunu kablo/port değilmiş, telefonda USB hata ayıklama kapalıymış; açılınca sorunsuz bağlandı
> (hafızadaki "USB bozuk, kablosuz kullan" notu bu yüzden yanlışmış). APK `582a9b3`'ten kuruldu,
> çalışma anı logu temiz, crash yok.
> 1. **Yeni Blender ahşap tahtası onaylandı** — "en iyi tahtalardan biri olmuş, hiçbir sorun yok".
>    Ceviz/akçaağaç satranç deseni ve taş-kare hizası cihazda doğrulandı. 08-10'dan beri bekleyen
>    cihaz onayı **kapandı**.
> 2. **Ahşap taşlar soluktu → DÜZELTİLDİ.** Sebep kodda filtre değil, `8ca330f` (Enes, 24 Tem)
>    "Refresh wood assets with Blender 3D renders" commit'inin ürettiği yeni PNG'lerin kendisiydi:
>    ceviz doygunluğu 0.498 → 0.214 (−%57), farklı renk sayısı 8362 → 3031 (−%64); akçaağaç
>    solmamış ama kararmış (parlaklık 0.891 → 0.758). **Eski PNG'ler `8ca330f~1`'den geri alındı**
>    (boyutlar birebir aynı — 530²/540² — hiza kodu etkilenmedi). Board/frame/surface assetleri
>    YENİ halde bırakıldı, yalnız iki disk geri alındı.
> 3. **Taş perspektifi tutarsızdı → DÜZELTİLDİ (REV-89, In Review).** Prosedürel taşlar kodla %74
>    dikey ezilip yan duvarla çiziliyordu → tahtanın açısına uyuyordu. **6 asset diskin hepsi**
>    (ceviz, akçaağaç, mermer×2, çiçek×2) tam tepeden render edilmişti (alfa kutusu en/boy 1.00) →
>    yukarıdan bakıyordu. Kodda tutarsızlık zaten vardı: asset disk **çevirme sırasında** eziliyor
>    (`BoxFit.fill`), durunca daire oluyordu.
>    **Mustafa'nın çözümü** ("dönme animasyonunda kalınlık veriyorsak, yarım dönmüş halini sabit taş
>    olarak kullanamaz mıyız?") uygulandı: `_restSquash()` kaldırıldı, **her taş türü aynı duruş
>    açısında** (0.74); yeni `_RestingAssetDisc` PNG'yi ezip altına `_FlipWallPainter` ile duvar
>    çiziyor. Duvar `0.25×cos(asin(0.74))=0.168` → prosedürelin `kCoinRestThickness`=0.17'siyle aynı,
>    iki tür taş tahtada aynı yükseklikte duruyor. `_wallColors` + `_kAssetWallInset` dosya seviyesine
>    çıktı; duruş ve animasyon aynı sabitleri paylaşıyor, kayamaz. `test/disc_view_test.dart` 4 test,
>    toplam 109 yeşil. Cihazda doğrulandı — taşlar tahtanın açısında, yan duvarları görünüyor.
>    **⚠️ Tam çözüm DEĞİL:** duvar gerçek render edilmiş ahşap değil, taşın renginden türetilmiş düz
>    bant. Mustafa "blender ile de aynı şeyi yapacağız" dedi → **asset diskler Blender'da tahtanın
>    açısıyla yeniden render edilecek**; o tur gelince buradaki ezme kaldırılır (PNG kendi
>    perspektifini taşır). Ceviz/akçaağacın yanı sıra **mermer ve çiçek setleri de** aynı durumda.

> **🔄 2026-08-18 — YEREL DEPO SENKRONLANDI, DURUM TESPİTİ:** Mustafa'nın makinesindeki yerel
> `main` 10 commit geride kalmıştı (08-09/08-10 turu Enes'in makinesinden `argedikas@gmail.com`
> kimliğiyle push edilmiş: REV-61 çerçeveleri + iOS pod fazı + Blender ahşap hattı merge'i).
> Fast-forward ile eşitlendi, çakışma/kayıp yok. Doğrulama: `flutter analyze` temiz
> (yalnız bilinen 2 `ai_player.dart:179` info lint'i), **105/105 test yeşil**.
> **Durum:** Linear'da In Progress/In Review/In AI **boş**; 12 iş Todo'da ve hepsi
> Enes'in tasarım/ses çıktısına ya da mağaza halkasına bağımlı. **Kodlanacak bağımsız iş yok.**
> **Bekleyen tek engel:** 08-10 ahşap tahta değişikliği **cihazda hiç görülmedi** — sıradaki
> iş bir cihaz testi turu. Ekip APK'sı Desktop'ta kalmamış, yeniden derlenmeli.
> Linear'da REV-61 hâlâ Todo görünüyor ama kod tarafı uygulandı — kolon düzeltmesi Mustafa'nın kararına bırakıldı.

> **🪵 2026-08-10 — BLENDER AHŞAP HATTI MAIN'E ALINDI (`worktree-blender-3d` → `main`):**
> Dal 10 gündür yerelde push'suz duruyordu; önce GitHub'a push edildi, sonra güncel main'e
> merge edildi (**çakışma çıkmadı** — REV-87 son hamle nişanı ve REV-84 taş animasyonu
> `wood_board.dart`'ta korundu, 105 test yeşil, analyze temiz).
> **Getirdikleri:** ahşap assetleri Blender render'larıyla yenilendi (`assets/wood/` — board-crop
> 1.1 → 2.9 MB, disk/çerçeve/yüzey dosyaları küçüldü, net ~+0.9 MB), offline ahşap tahtaya
> **ceviz/akçaağaç satranç deseni** (`lib/features/board/painters/checker_painter.dart`),
> taş-kare hizası `cellGeometry` üzerinden düzeltildi, `blender/` üretim hattı
> (addon + .blend modelleri + prompt notları) ve `board-visual` skill'i repoya girdi.
> **⚠️ Cihaz onayı YOK:** tahtanın görünümü değişti, Mustafa henüz cihazda görmedi (S21 FE
> kontrolü bekliyordu). İlk cihaz testinde tahtaya bakılmalı. Render kaynakları
> (`blender/renders/frames*`, ~159 MB) bilerek repoya alınmadı — REV-85 iptal edildiği için
> kare dizilerine gerek yok.

> **🖼️ 2026-08-09 — REV-61 KADEME ÇERÇEVELERİ UYGULANDI (kod tarafı):** Çalışma dizininde
> commit edilmemiş halde duran yarım iş bulundu ve tamamlandı. Enes'in ürettiği **6 kademe
> çerçevesi** (`assets/frames/tier/`, 512² şeffaf PNG) artık uygulamada:
> **profil avatarı** kendi rütbesinin çerçevesini takıyor (ana vitrin, ∅96),
> **Kupa Yolu** her durakta o rütbenin çerçevesini önizliyor (56pt kutu),
> **menü çipi** (∅22) çerçeve yerine rütbe renk halkası gösteriyor — süsler o boyutta okunmuyor
> (spec §6.3 önerisi uygulandı).
> **Spec'ten sapma:** REV-61 §3.1 "açıklık tüm çerçevelerde sabit %76" diyordu; üretilen assetler
> öyle çıkmadı (taçlı Büyük Usta/Efsane açıklığı ~%44-49 ve aşağı kaymış). Tek katsayı avatarı
> 6 çerçevenin 4'ünde kaydırırdı → her çerçeve alfa kanalından ölçülmüş kendi açıklığını taşıyor
> (`RankFrame` in `lib/core/models/rank.dart`). Assetleri yeniden ürettirirsen bu sayılar da
> güncellenmeli — `test/rank_frame_test.dart` (9 test) geometriyi kilitliyor.
> **Yapılmadı:** leaderboard satırında çerçeve (§6.3). Haftalık tabloda `trophies` alanı yok
> (`LeaderboardEntry.fromWeeklyPlayer` yalnız `trophyGained` taşıyor) → satırların yarısı
> çerçeveli yarısı çerçevesiz olurdu. Ürün kararı gerekiyor; spec §8'de zaten açık soru.
> **Satılık çerçeveler (§5, 5 adet)** de yok — assetleri üretilmedi, mağaza halkasına bağlı.
> Ayrıca iOS Runner hedefine "[CP] Copy Pods Resources" fazı + Podfile.lock eklendi (`501d098`).
> Test: **105 yeşil**, analyze temiz.

> **🔎 2026-07-30 CİHAZ TESTİ (Mustafa) — 3 maddede geri bildirim, 2'si düzeltildi:**
> 1. **Rütbe sistemi çalışıyor.** Tek sorun: "36 Kupa (+64)" gösterimi anlaşılmıyordu → **REV-83** ile kalan kupa gösterimi hem profilden hem maç sonu ekranından kaldırıldı, çubuğun uçlarına bandın kendi eşikleri yazıldı (30 … 100). Ayrıca profil rütbe kartı tıklanabilir oldu → yeni **Kupa Yolu** ekranı (dikey yol, rütbeler bir sağ bir sol, oyuncunun konumu çizgide işaretli, tema-duyarlı).
> 2. **Tema/tahta/taş bağımsızlığı çalışıyor**, ama taş animasyonu perspektifini kaybetmişti (REV-82 regresyonu) → **REV-84** ile hacimli devrilme geri getirildi (kenar kalınlığı + havada yay + yer gölgesi), bu kez **hem prosedürel hem resim-disk taşlar** için, karışık çift dahil. Mustafa onayladı ("animasyonlarda sorun yok") → **REV-85 (Blender 3D kare dizisi) İPTAL**, bkz. §8. Ardından iki küçük düzeltme (**REV-86**): koyulan taş dönmüyor, direkt konuyor (yalnız çevrilenler animasyon yaşıyor); tek oyunculuda AI sırasında ipuçları gizli, yalnız sıra oyuncudayken görünüyor. Bunun yan etkisi olarak son hamlenin izi kayboldu → **REV-87** son taşın üstüne amber nişan koydu (tüm modlar).
> 3. **Tema diğer ekranlarda sorunsuz.** Yeni Kupa Yolu ekranı da tema-duyarlı yazıldı.
>
> Emülatör notu: bir kez adb'ye cevap vermeyecek şekilde kilitlendi (CPU ~%300, `offline`), Android Studio'dan **Cold Boot** ile düzeldi.

> **✅ 15 İŞ DONE (2026-07-30, Mustafa cihazda test edip kapattı):** REV-67, 70, 73, 74, 75, 76, 79, 80, 81, 82, 83, 84, 86, 87, 88. Rütbe/kupa sistemi (XP tamamen kaldırıldı), tema tüm ekranlarda (Güzelsi/Orijinal), tema/tahta/taş **tam bağımsız — her taş her tahtada**, maç deneyimi (sonuç ekranı ±kupa, rütbe etiketi, rakip istatistik), Kupa Yolu ekranı, perspektifli taş animasyonu + son hamle nişanı. **In Review kuyruğu boş.** Kod GitHub `main`'de (`5310a70`); sunucu tarafı (`functions/`) bu turda değişmedi, prod zaten güncel. **Proje 13 (Rütbe, Kupa & Maç Deneyimi) tamamen kapandı.**
>
> **Kalan Todo:** REV-60 (Enes tasarım kararı), **REV-61 kademe çerçeveleri kod tarafı 2026-08-09'da uygulandı** (yukarı bak; satılık çerçeveler + leaderboard gösterimi hâlâ açık), REV-62/63/64/65 (Enes tasarım/ses — In Review'daki dokümanlar Todo'ya çekilmişti, karar bekliyor), REV-68/69/71/72/77 (mağaza — Enes asset'lerine bağlı), REV-78 (reklam — bloklu). **Sıradaki doğal adım:** mağaza halkası Enes'in asset'lerine bağlı; onlar gelmeden kodlanacak bağımsız iş kalmadı.

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
- Ekip test APK'sı: `~/Desktop/Reversi-0.1.0-8d77e95.apk` (2026-07-24, release-imzalı, universal, `8d77e95` — rütbe/kupa + XP kaldırma + tema + mermer/çiçek render dahil). Emülatöre kuruldu; **telefon kablosuz bağlantısı düştü → yeni eşleştirme kodu gerekli.**

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
| 2026-07-25 | **REV-82 (özel taşları seçilebilir yap — tam bağımsızlık) kodlandı + EMÜLATÖRDE GÖRSEL DOĞRULANDI, In Review.** `CoinColor` 4→10 (walnut/maple/marbleBlack/marbleWhite/flowerPurple/flowerPink asset diskler; `coinAssets` haritası, `coinAccentColor` yardımcısı). Yeni ortak `AnimatedDiscView`/`DiscView` (prosedürel `CoinView` veya asset `Image` + **tutarlı kart-çevirme** — Mustafa kararı). WoodBoard + OnlineBoard disk render'ı bu widget'a bağlandı; OnlineBoard'a `blackCoin`/`whiteCoin` eklendi (artık tahtaya değil oyuncu coin'ine göre) → **her taş her tahtada**. Ayarlar taş seçici 10 taş (Wrap) + asset swatch; `coinPalettes[coin]!` çökme kaynakları (player_card, game_over_card/overlay, online score rozeti) `coinAccentColor`/`DiscView` ile düzeltildi. **Görsel test:** turkuaz gradyan tahtada mermer-siyah + turuncu taşlar birlikte doğru render (emülatör ekran görüntüsü). Ayarlar da **kompaktlandı** (bölüm boşlukları, tahta tile 88→70). 92/92 test yeşil. **Küçük kozmetik kaldı:** Güzelsi temasında offline oyuncu-kartı avatarı hâlâ tahta-bazlı ahşap disk gösteriyor (seçilen coin'i değil) — bug değil, sonra iyileştirilebilir. |
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
- **Proje 13 · "Rütbe, Kupa & Maç Deneyimi"** (`0f5344ce-0ce4-4feb-967b-ea2387a5fa42`): rütbe mekaniği + online maç deneyimi. İçindekiler: **REV-67** (kupa/rütbe client modeli), **REV-73** (kupa sunucu motoru), **REV-74** (maç sonu ekranı), **REV-75** (maç ekranı rütbe+rakip istatistik), **REV-76** (online kendi teması), **REV-83** (eşik etiketleri + Kupa Yolu ekranı, 2026-07-30 cihaz testinden). Kanonik model §7C-3/4. Kupa eşikleri şimdilik önerilen değerlerde (0/30/100/250/550/1000), canlı veriyle ileride tune edilecek.

**2026-07-30 cihaz testinden açılan işler:**
- **REV-83** (proje 13, In Review) — "(+64)" kaldırıldı, çubuk uçlarına eşikler; yeni **Kupa Yolu** ekranı (`lib/features/profile/rank_road_screen.dart`), profil rütbe kartından açılıyor, tema-duyarlı. `rankBand()` + 3 test.
- **REV-84** (proje 12, In Review) — taş çevirme perspektifi geri geldi. REV-82'de kaybolmasının sebebi: eski `FlipCoinPainter` resim-diskleri çizemediği için ortak payda düz dikey ezme yapılmıştı. Yeni geometri taş türünden bağımsız (`phase` = duruş sıkışması → π kenar-üstü → yeni duruş), **her yarım tur kendi taşının çizicisiyle** çiziliyor → karışık çift (mermer ↔ turkuaz) çalışıyor. Yüz/kenar çizimi `paintCoinFace`/`paintCoinWall` olarak ortaklaştı; duran `CoinView` de aynı fonksiyonları kullanıyor, animasyon ile duruş **kayamaz**. Ayar düğmeleri `AnimatedDiscView` içinde: `_hover` 0.45, `_thickness` 0.25, `_hoverScale` 0.12. `flip_coin_painter.dart` silindi.
- **REV-85** — Blender 3D kare dizisi. **İPTAL EDİLDİ** aynı gün (Mustafa animasyonu onayladı), bkz. §8.
- **REV-86** (proje 12, In Review) — REV-84 sonrası iki düzeltme: (a) koyulan taş dönmüyor, direkt duran taş olarak çiziliyor; `appear` parametresi kaldırıldı. (b) tek oyunculuda AI düşünürken ipuçları gizli — `hintsVisible` yalnız sıra insandayken açık; iki oyunculu ve online etkilenmedi. Yeni widget testi bunu kilitliyor (test, AI'ın izolat hamlesini beklemek yerine ağacı kapatıp döngüyü `mounted`'a düşürüyor). Test yazarken çıkan yan bulgu: sıra rozetindeki en uzun metin ("Bilgisayar düşünüyor…") 360dp'de Row'u taşırıyordu → `Flexible` + ellipsis.
- **REV-88** (proje 12, In Review) — iki tema tutarsızlığı: (a) tek oyuncu istatistikleri ekranı REV-79 yardımcılarını kullanmıyordu (sabit cream/banner), eklendi. (b) Güzelsi'de offline oyuncu kartı seçilen taşı yok sayıp tahtaya göre sabit disk PNG'si gösteriyordu → artık iki temada da aynı ikon (taş renginden degrade kutu + baş harf); ölü `_avatarDisc` silindi. Kalan tek fark: `ScoreChip` Güzelsi'de hâlâ gizli (şikâyet ikonlaydı, dokunulmadı). `StatsScreen` artık ayar okuduğu için testi `SettingsScope` ile sarmalandı.
- **REV-87** (proje 12, In Review) — koyulan taş dönmeyince "en son nereye oynadım" kayboldu. Ortak `LastMoveMarker` (`lib/shared/widgets/last_move_marker.dart`) son taşın **üstüne** nişan koyuyor: amber gövde `#FFB300` + beyaz iç parlaklık + koyu kontur `#3B2200`. **Üç ton, çünkü** nişan taşın üstünde durduğundan siyah taştan beyaz mermere kadar okunmalı — tek düz renk yapamıyor. Prosedürel taşın yüz merkezi kutu merkezinin üstünde, asset diskin tam ortasında → nişan taş türüne göre kayıyor. **WoodBoard'da son hamle işareti hiç çizilmiyordu** (`lastMove` alınıp kullanılmıyordu), eklendi; OnlineBoard'daki nabız atan çevre halkası kaldırıldı (`OnlineTokens.lastMoveRing` silindi). Tek oyunculu + iki oyunculu + online aynı nişan. Ayar: `LastMoveMarker.amber`/`outline`/`_pipFactor`.

### 7B. FAZ 2 (Linear proje "11 · Online Geliştirme: Misafir, İstatistik & Lider Tablosu") — ✅ 7/7 kod tarafı tamam (2026-07-15)

Onaylı plan: `/Users/f/.claude/plans/imdi-yeni-bir-a-amaya-ethereal-map.md`. Mustafa'nın "tüm task'larını In Progress'e çek, yapabildiklerini yap" talimatıyla REV-53..59 tek oturumda uygulandı ve **In Review'a** taşındı. ✅ **Sunucu tarafı (REV-54/55/56/57 + REV-66) 2026-07-24 prod'a deploy edildi.** ✅ **2 hesaplı smoke test geçti (2026-07-24):** misafir↔misafir + misafir↔imzalı eşleşme/oyun/istatistik sorunsuz. ✅ **8 iş (REV-53/54/55/56/57/58/59/66) Done'a çekildi (2026-07-24, Mustafa'nın açık talimatıyla, cihaz testi sonrası).** **Faz 2 (proje 11) tamamen kapandı; REV-66 (Epic 12 ilk halkası) da Done.**

- **Faz A — Misafir oyun:** REV-53 (client: Firebase Anonymous Auth, `Profile.isGuest`, "Misafir devam et" menü akışı) + REV-57 (server: finish_game'de `admin.auth` ile anonim kontrolü → misafire ödül/history/leaderboard YAZMA).
- **Faz B — Gelişim istatistikleri:** REV-54 (server: maç başına `users/{uid}/history/{gameId}` time-series) + REV-58 (client: online istatistik ekranına galibiyet oranı trendi + aktivite&seri grafikleri; fl_chart mevcut).
- **Faz C — Lider tablosu:** REV-55 (server: `leaderboards/{weekId}/players` haftalık sayaçlar + weekId yardımcısı) + REV-56 (kurallar+index) + REV-59 (client: leaderboard ekranı — Haftalık/TümZamanlar × Seviye/Galibiyet + "senin sıran").

**Kilitli kararlar:** Lider tablosu Seviye+Galibiyet (Elo YOK ama genişletilebilir). Haftalık + TümZamanlar ayrı. Misafir maçı imzalı rakibe SAYILIR (yalnız misafir kazanmaz; farm riski kabul edildi, gerekirse sonra önlem). İstatistik+leaderboard Google girişine kapalı, misafire upsell. 3. istatistik sayfası AÇILMAZ — grafikler mevcut online istatistik ekranına girer. REV-54/55/57 aynı `finish_game` dosyasını değiştirir — birlikte ele al.

### Küçük takip işleri (ticket'sız, engel değil)
- [ ] **Yasal sayfaların adresinden `mkarakas61` kalksın — YAYIN ÖNCESİ karar (2026-08-20 ertelendi).**
      Mustafa kişisel kullanıcı adının görünmesini istemiyor; şimdilik kalmasına karar verdi.
      Seçenekler: ücretsiz GitHub organizasyonu (`<org>.github.io/Reversi/`) · kendi alan adı
      (~10-15 $/yıl) · Cloudflare Pages (`<proje>.pages.dev`). **Uygulama Play'e çıkmadan
      değiştirmek ucuz** — sonrası yayınlanmış sürümde ölü bağlantı demek. Değişirse güncellenecek
      yerler: `lib/core/legal/legal_links.dart`, `docs/` içindeki sayfalar arası bağlantılar,
      Play Console'daki iki URL. Ayrıca not: Play'de **geliştirici adı** şahıs hesabında herkese
      görünür — onu gizlemek ancak tüzel kişi hesabıyla olur (dağıtımcı anlaşmasına bağlı).
- [x] 2 hesaplı online smoke testi tamamlandı (2026-07-24, telefon+emülatör; misafir + imzalı, istatistikler işliyor)
- [ ] `turnDeadline` ölü kodu temizliği (yazılıyor, okunmuyor)
- [ ] REV-51 emülatör kural testleri (`functions/scripts/test_{rules,finish_game}.js`) — Java kurulunca; canlı test geçtiği için düşük öncelik
- [ ] `ai_player.dart:179` iki curly-braces lint bilgisi (Enes'in kodu, kozmetik)
- [ ] Online oyun ekranının wood temasına uyarlanması (Enes'in `online_match_screen.dart` tasarımı kaynak alınabilir) — ayrı iş
- [ ] Enes'le git disiplini konuşması (güncel main'den dallanma)

## 8. İPTAL EDİLENLER (TEKRAR ÖNERME)

- **Fantastik Mod + Mağaza (2026-06-19, ekip kararı):** flip-any/delete-any/freeze/ekstra-hamle güçleri + coin/reklam/IAP ile güç-kozmetik-undo satan mağaza. **Oyunun özünü bozduğu için iptal.** Online güçler ayrıca ağır altyapı isterdi (TS engine aksiyon tipleri, move-log şeması, sunucu-doğrulamalı envanter, ayrı eşleşme havuzu). Bir daha gündeme getirme. **⚠️ Kısmi güncelleme (2026-07-23 toplantı):** yalnız **offline "hamle geri alma"** satışı bu iptalden istisna tutuldu (offline oyun zaten adil-rekabet dışı). **Online'da undo/güç satışı hâlâ kesin İPTAL** — online adilliği korunur.
- **Taş çevirmede gerçek 3D (REV-85, 2026-07-30):** Blender'dan render edilmiş kare dizisi (sprite) ile 3D ışık/hacim. REV-84'ün kod tarafı perspektifi Mustafa'ya yeterli geldi ("animasyonlarda sorun yok"), asset üretimi + ~2 MB APK maliyeti gereksiz görüldü. **Ekip testinden sonra illa istenirse yeniden açılır** — teknik plan Linear'da REV-85 açıklamasında duruyor, Blender hattı `blender/` (dal `origin/worktree-blender-3d`). Canlı 3D motoru (flutter_scene/three_dart) ise kesin elendi: tahta 2B perspektif projeksiyonu, canlı 3D tahtayı+dokunmayı sıfırdan yazmak + 64 taş animasyonda kare düşürme riski demek.
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
