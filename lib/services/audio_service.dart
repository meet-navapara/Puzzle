import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// PetalGrid audio facade.
///
/// Loads optional assets from assets/audio/. When a file is missing, falls
/// back to short SystemSound clicks so gameplay stays responsive.
class AudioService extends ChangeNotifier {
  AudioService() {
    _sfx = AudioPlayer(playerId: 'petal_sfx')
      ..setReleaseMode(ReleaseMode.stop)
      ..setPlayerMode(PlayerMode.lowLatency);
    _music = AudioPlayer(playerId: 'petal_music')
      ..setReleaseMode(ReleaseMode.loop);
  }

  late final AudioPlayer _sfx;
  late final AudioPlayer _music;

  bool soundEnabled = true;
  bool musicEnabled = true;
  double soundVolume = 0.8;
  double musicVolume = 0.5;

  bool _placeAsset = false;
  bool _clearAsset = false;
  bool _bloomAsset = false;
  bool _rejectAsset = false;
  bool _gameOverAsset = false;
  bool _musicAsset = false;
  String _musicPath = 'audio/music_loop.wav';
  bool _probed = false;
  bool _musicPlaying = false;

  bool get hasMusicAsset => _musicAsset;
  bool get isMusicPlaying => _musicPlaying;

  Future<void> warmUp() async {
    if (_probed) return;
    _probed = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Audio context setup failed: $e');
    }
    _placeAsset = await _assetExists('audio/place.wav');
    _clearAsset = await _assetExists('audio/clear.wav');
    _bloomAsset = await _assetExists('audio/bloom.wav');
    _rejectAsset = await _assetExists('audio/reject.wav');
    _gameOverAsset = await _assetExists('audio/game_over.wav');
    if (await _assetExists('audio/music_loop.wav')) {
      _musicAsset = true;
      _musicPath = 'audio/music_loop.wav';
    } else if (await _assetExists('audio/music_loop.ogg')) {
      _musicAsset = true;
      _musicPath = 'audio/music_loop.ogg';
    }
    debugPrint(
      'Audio assets: place=$_placeAsset clear=$_clearAsset bloom=$_bloomAsset '
      'reject=$_rejectAsset gameOver=$_gameOverAsset music=$_musicAsset',
    );
    await _applyVolumes();
    if (musicEnabled && _musicAsset) {
      await resumeMusic();
    }
    notifyListeners();
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load('assets/$assetPath');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyVolumes() async {
    await _sfx.setVolume(soundEnabled ? soundVolume.clamp(0.0, 1.0) : 0);
    await _music.setVolume(musicEnabled ? musicVolume.clamp(0.0, 1.0) : 0);
  }

  Future<void> _playSfx(String asset, {required bool hasAsset}) async {
    if (!soundEnabled) return;
    if (hasAsset) {
      try {
        await _sfx.stop();
        await _sfx.play(AssetSource(asset));
        return;
      } catch (e) {
        debugPrint('SFX asset failed ($asset): $e');
      }
    }
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playPlace() =>
      _playSfx('audio/place.wav', hasAsset: _placeAsset);

  Future<void> playClear() =>
      _playSfx('audio/clear.wav', hasAsset: _clearAsset);

  Future<void> playBloom() =>
      _playSfx('audio/bloom.wav', hasAsset: _bloomAsset);

  Future<void> playReject() =>
      _playSfx('audio/reject.wav', hasAsset: _rejectAsset);

  Future<void> playGameOver() =>
      _playSfx('audio/game_over.wav', hasAsset: _gameOverAsset);

  Future<void> resumeMusic() async {
    if (!musicEnabled || !_musicAsset) return;
    try {
      if (!_musicPlaying) {
        await _music.play(AssetSource(_musicPath));
        _musicPlaying = true;
      } else {
        await _music.resume();
      }
      await _music.setVolume(musicVolume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Music play failed: $e');
      _musicPlaying = false;
    }
  }

  Future<void> pauseMusic() async {
    if (!_musicPlaying) return;
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
    _musicPlaying = false;
  }

  void applySettings({
    required bool sound,
    required bool music,
    required double sVol,
    required double mVol,
  }) {
    final musicWas = musicEnabled;
    soundEnabled = sound;
    musicEnabled = music;
    soundVolume = sVol;
    musicVolume = mVol;
    unawaited(_applyVolumes());
    if (music && _musicAsset) {
      unawaited(resumeMusic());
    } else if (!music && musicWas) {
      unawaited(stopMusic());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sfx.dispose();
    _music.dispose();
    super.dispose();
  }
}
