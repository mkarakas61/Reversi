import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'ringer_mode_service.dart';

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

  /// How many players to keep per effect so a sound can overlap itself (e.g.
  /// rapid menu taps) without one cutting the previous one off.
  static const int _sfxPlayersPerSound = 2;

  /// Pre-loaded SFX players, grouped by effect. Each player already has its
  /// asset set (see [_preloadSfx]), so triggering a sound is a cheap
  /// seek + resume instead of a fresh asset load. Reloading on every play was
  /// the root cause of effects dropping or sounding quiet when fired in quick
  /// succession.
  final Map<Sfx, List<AudioPlayer>> _sfxPlayers = {};
  final Map<Sfx, int> _sfxNext = {};

  final AudioPlayer _music = AudioPlayer(playerId: 'music')
    ..setReleaseMode(ReleaseMode.loop);

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  Music? _currentMusic;

  /// Whether the device's ringer is currently in silent mode. While true,
  /// SFX are muted and music stays paused, mirroring the system's own sounds.
  bool _ringerSilent = false;

  /// Configures audio playback so it never grabs audio focus from (or
  /// interrupts) other apps' music, and respects the system's silent mode.
  /// Safe to call multiple times; failures are non-fatal.
  Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      ));
    } catch (e) {
      debugPrint('Audio context setup failed: $e');
    }
    await _preloadSfx();
    await refreshRingerMode();
  }

  /// Creates and pre-loads a small pool of players for every effect so the
  /// first (and every later) trigger plays instantly and at full volume.
  Future<void> _preloadSfx() async {
    for (final entry in _sfxAsset.entries) {
      final players = <AudioPlayer>[];
      for (var i = 0; i < _sfxPlayersPerSound; i++) {
        try {
          final player = AudioPlayer(playerId: 'sfx_${entry.key.name}_$i');
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setSource(AssetSource(entry.value));
          await player.setVolume(1.0);
          players.add(player);
        } catch (e) {
          debugPrint('SFX preload failed (${entry.key}): $e');
        }
      }
      _sfxPlayers[entry.key] = players;
      _sfxNext[entry.key] = 0;
    }
  }

  /// Re-checks the device's ringer mode (e.g. when the app resumes) and
  /// mutes/restores audio accordingly.
  Future<void> refreshRingerMode() async {
    final silent =
        await RingerModeService.instance.currentMode() == RingerMode.silent;
    if (silent == _ringerSilent) return;
    _ringerSilent = silent;
    if (silent) {
      await pauseMusic();
    } else {
      await resumeMusic();
    }
  }

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
    if (!_soundEnabled || _ringerSilent) return;
    final players = _sfxPlayers[sfx];
    if (players == null || players.isEmpty) return;
    final index = _sfxNext[sfx]!;
    _sfxNext[sfx] = (index + 1) % players.length;
    final player = players[index];
    try {
      // The source is already loaded; rewind and play so rapid retriggers
      // always start from the beginning at full volume.
      await player.seek(Duration.zero);
      await player.resume();
    } catch (e) {
      debugPrint('SFX play failed ($sfx): $e');
    }
  }

  /// Switches the looping background track. No-op if already on [music].
  Future<void> playMusic(Music music) async {
    if (_currentMusic == music) return;
    _currentMusic = music;
    if (!_musicEnabled || _ringerSilent) return;
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
    if (!_musicEnabled || _currentMusic == null || _ringerSilent) return;
    try {
      await _music.resume();
    } catch (_) {}
  }

  /// Stops any in-flight one-shot sound effects, e.g. when the app is sent
  /// to the background.
  Future<void> stopAllSfx() async {
    for (final players in _sfxPlayers.values) {
      for (final player in players) {
        try {
          await player.stop();
        } catch (_) {}
      }
    }
  }
}
