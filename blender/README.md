# Blender MCP — Reversi 3B çalışma dizini

Bu klasör **git'e dahildir** (GitHub'a pushlanır). Amaç: Reversi oyun taşlarını ve
(sonraki adımda) tahtasını Claude Code + Blender MCP üzerinden programatik
modelleyip animasyon/render üretmek.

## Yapı
- `addon/addon.py` — Blender MCP eklentisi (ahujasid/blender-mcp)
- `models/`  — `.blend` dosyaları
- `renders/` — render çıktıları (png/mp4/gif)

## Tek seferlik kurulum (Blender tarafı — manuel)
Blender 5.1.2 kurulu (`/Applications/Blender.app`). MCP sunucusu Claude Code'a
`user` scope ile eklendi (`claude mcp add blender -- uvx blender-mcp`).

Çizim yapabilmek için Blender'ı Claude'a bağlaman gerekiyor:

1. **Blender'ı aç.**
2. `Edit > Preferences > Add-ons > Install from Disk…` → bu dosyayı seç:
   `blender/addon/addon.py` → listede **"Interface: Blender MCP"**'yi işaretle (etkinleştir).
3. 3D viewport'ta **N** tuşuna bas → sağ panelde **"BlenderMCP"** sekmesi →
   **"Connect to Claude"** butonuna bas (port 9876'da socket sunucusu başlar).
4. **Claude Code oturumunu yeniden başlat** (veya bu worktree'de yeni oturum aç) —
   böylece `mcp__blender__*` araçları yüklenir.

> Not: Addon 3.x/4.x için yazıldı; Blender 5.1'de etkinleştirme hata verirse
> `addon.py`'deki `bl_info`/API uyumsuzluğunu birlikte yamalarız.

## Bağlantı doğrulama
Yeni oturumda Claude'a "Blender sahnesindeki nesneleri listele" de — MCP çalışıyorsa
sahne bilgisi döner. Sonra aşağıdaki prompt'u yapıştır.

Kullanılacak prompt: `blender/PROMPT-tas-animasyon.md`
