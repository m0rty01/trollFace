import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioService {
  static const platform = MethodChannel('com.trollface/audio');
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _effectPlayers = {};
  bool _isSpeakerOn = true;
  bool _isMuted = false;

  static Future<void> setSpeakerOn(bool enabled) async {
    try {
      await platform.invokeMethod('setSpeakerOn', {'enabled': enabled});
    } on PlatformException catch (e) {
      print('Failed to set speaker: ${e.message}');
    }
  }

  static Future<bool> isSpeakerOn() async {
    try {
      final bool isOn = await platform.invokeMethod('isSpeakerOn');
      return isOn;
    } on PlatformException catch (e) {
      print('Failed to get speaker state: ${e.message}');
      return false;
    }
  }

  Future<void> setSpeaker(bool enabled) async {
    // WebRTC doesn't support direct speaker control on web
    // This is a no-op for web platform
  }

  Future<void> setVolume(double volume) async {
    try {
      // Implementation depends on the platform
      // For web, this might not be possible
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  Future<void> playRingtone() async {
    try {
      // Implementation depends on the platform
      // For web, you might use the Web Audio API
    } catch (e) {
      print('Error playing ringtone: $e');
    }
  }

  Future<void> stopRingtone() async {
    try {
      // Implementation depends on the platform
    } catch (e) {
      print('Error stopping ringtone: $e');
    }
  }

  Future<void> playEffect(String effectPath) async {
    if (_isMuted) return;

    if (!_effectPlayers.containsKey(effectPath)) {
      _effectPlayers[effectPath] = AudioPlayer();
      await _effectPlayers[effectPath]!.setAsset(effectPath);
    }

    await _effectPlayers[effectPath]!.play();
  }

  Future<void> playBackgroundMusic(String musicPath) async {
    if (_isMuted) return;

    await _backgroundPlayer.setAsset(musicPath);
    await _backgroundPlayer.setLoopMode(LoopMode.all);
    await _backgroundPlayer.play();
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    if (muted) {
      await _backgroundPlayer.pause();
      for (var player in _effectPlayers.values) {
        await player.pause();
      }
    }
  }

  void dispose() {
    _backgroundPlayer.dispose();
    for (var player in _effectPlayers.values) {
      player.dispose();
    }
    _effectPlayers.clear();
  }
} 