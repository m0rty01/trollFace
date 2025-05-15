import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class FilterEffectsService {
  static final FilterEffectsService _instance = FilterEffectsService._internal();
  factory FilterEffectsService() => _instance;
  FilterEffectsService._internal();

  final _random = math.Random();
  final List<EmojiParticle> _particles = [];
  bool _isShaking = false;
  Offset _shakeOffset = Offset.zero;
  Timer? _shakeTimer;
  Timer? _particleTimer;

  void triggerEmojiExplosion(BuildContext context, Offset center) {
    final emojis = ['😂', '🤣', '😆', '😅', '🤪', '😜', '🤡', '👻', '🎭', '🎪'];
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    for (var i = 0; i < 20; i++) {
      final emoji = emojis[_random.nextInt(emojis.length)];
      final color = colors[_random.nextInt(colors.length)];
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 5 + _random.nextDouble() * 5;
      final size = 20 + _random.nextDouble() * 20;

      _particles.add(EmojiParticle(
        emoji: emoji,
        position: center,
        velocity: Offset(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        ),
        color: color,
        size: size,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: -1 + _random.nextDouble() * 2,
      ));
    }

    _startParticleAnimation();
  }

  void triggerScreenShake() {
    if (_isShaking) return;
    _isShaking = true;
    HapticFeedback.mediumImpact();

    _shakeTimer?.cancel();
    _shakeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _shakeOffset = Offset(
        -5 + _random.nextDouble() * 10,
        -5 + _random.nextDouble() * 10,
      );
    });

    Future.delayed(const Duration(seconds: 1), () {
      _isShaking = false;
      _shakeTimer?.cancel();
      _shakeOffset = Offset.zero;
    });
  }

  void _startParticleAnimation() {
    _particleTimer?.cancel();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      for (var i = _particles.length - 1; i >= 0; i--) {
        final particle = _particles[i];
        particle.position += particle.velocity;
        particle.rotation += particle.rotationSpeed;
        particle.velocity *= 0.98; // Friction
        particle.velocity += const Offset(0, 0.1); // Gravity

        if (particle.position.dy > 1000) {
          _particles.removeAt(i);
        }
      }

      if (_particles.isEmpty) {
        _particleTimer?.cancel();
      }
    });
  }

  Offset get shakeOffset => _shakeOffset;
  List<EmojiParticle> get particles => _particles;

  void dispose() {
    _shakeTimer?.cancel();
    _particleTimer?.cancel();
  }
}

class EmojiParticle {
  final String emoji;
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;

  EmojiParticle({
    required this.emoji,
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
} 