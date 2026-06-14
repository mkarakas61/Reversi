import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The one-shot sound effects.
enum Sfx { place, flip, invalid, button, tick, timeup, win, lose, draw }

/// The two looping background tracks.
enum Music { menu, game }

/// Plays the game's sound effects and background music. A tiny round-robin
/// pool lets a few effects overlap; music plays on a dedicated looping player.
/// Honors the user's sound/music toggles ([applySettings]). All calls are
/// best-effort and never throw into the UI.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _sfxAsset = {
    Sfx.place: 'audio/place.wav',
    Sfx.flip: 'audio/flip.wav',
    Sfx.invalid: 'audio/invalid.wav',
    Sfx.button: 'audio/button.wav',
    Sfx.tick: 'audio/tick.wav',
    Sfx.timeup: 'audio/timeup.wav',
    Sfx.win: 'audio/win.wav',
    Sfx.lose: 'audio/lose.wav',
    Sfx.draw: 'audio/draw.wav',
  };

  static const _musicAsset = {
    Music.menu: 'audio/menu_music.wav',
    Music.game: 'audio/game_music.wav',
  };

  static const double _musicVolume = 0.45;

  final List<AudioPlayer> _pool = List.generate(
    4,
    (i) => AudioPlayer(playerId: 'sfx_$i')..setReleaseMode(ReleaseMode.stop),
  );
  int _next = 0;

  final AudioPlayer _music = AudioPlayer(playerId: 'music')
    ..setReleaseMode(ReleaseMode.loop);

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  Music? _currentMusic;

  /// Pushes the latest user preferences; starts/stops music as needed.
  void applySettings({required bool soundEnabled, required bool musicEnabled}) {
    _soundEnabled = soundEnabled;
    if (_musicEnabled != musicEnabled) {
      _musicEnabled = musicEnabled;
      if (musicEnabled) {
        final current = _currentMusic;
        if (current != null) _resumeMusic(current);
      } else {
        _music.pause();
      }
    }
  }

  Future<void> playSfx(Sfx sfx) async {
    if (!_soundEnabled) return;
    final asset = _sfxAsset[sfx];
    if (asset == null) return;
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('SFX play failed ($sfx): $e');
    }
  }

  /// Switches the looping background track. No-op if already on [music].
  Future<void> playMusic(Music music) async {
    if (_currentMusic == music) return;
    _currentMusic = music;
    if (!_musicEnabled) return;
    await _resumeMusic(music);
  }

  Future<void> _resumeMusic(Music music) async {
    final asset = _musicAsset[music];
    if (asset == null) return;
    try {
      await _music.stop();
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource(asset), volume: _musicVolume);
    } catch (e) {
      debugPrint('Music play failed ($music): $e');
    }
  }

  /// Pause/resume the current track for app lifecycle changes.
  Future<void> pauseMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    if (!_musicEnabled || _currentMusic == null) return;
    try {
      await _music.resume();
    } catch (_) {}
  }
}
