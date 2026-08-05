import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingDuckParticles extends StatefulWidget {
  final Widget child;
  final bool isDarkMode;

  const FloatingDuckParticles({
    super.key,
    required this.child,
    this.isDarkMode = false,
  });

  @override
  State<FloatingDuckParticles> createState() => _FloatingDuckParticlesState();
}

class _FloatingDuckParticlesState extends State<FloatingDuckParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Create 18 decorative background particles
    for (int i = 0; i < 18; i++) {
      _particles.add(_generateParticle());
    }
  }

  _Particle _generateParticle() {
    final double type = _random.nextDouble();
    return _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      speed: 0.05 + _random.nextDouble() * 0.08,
      size: 12 + _random.nextDouble() * 20,
      opacity: 0.15 + _random.nextDouble() * 0.35,
      type: type < 0.4
          ? _ParticleType.duckFootprint
          : (type < 0.7 ? _ParticleType.bubble : _ParticleType.sparkle),
      wobbleSpeed: 1 + _random.nextDouble() * 2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            isDarkMode: widget.isDarkMode,
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

enum _ParticleType { duckFootprint, bubble, sparkle }

class _Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  _ParticleType type;
  double wobbleSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.type,
    required this.wobbleSpeed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final bool isDarkMode;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate current position with smooth looping upward drift
      double currentY = (particle.y - progress * particle.speed) % 1.0;
      if (currentY < 0) currentY += 1.0;

      // Add gentle horizontal sway (wobble)
      double currentX = particle.x +
          (math.sin(progress * particle.wobbleSpeed * math.pi * 2) * 0.03);

      final double px = currentX * size.width;
      final double py = currentY * size.height;

      final Color mainColor = isDarkMode
          ? const Color(0xFFFFD54F)
          : const Color(0xFFFFB300);

      switch (particle.type) {
        case _ParticleType.duckFootprint:
          _drawDuckFootprint(canvas, Offset(px, py), particle.size,
              mainColor.withValues(alpha: particle.opacity * 0.5));
          break;
        case _ParticleType.bubble:
          final Paint bubblePaint = Paint()
            ..color = mainColor.withValues(alpha: particle.opacity * 0.25)
            ..style = PaintingStyle.fill;
          final Paint borderPaint = Paint()
            ..color = Colors.white.withValues(alpha: particle.opacity * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawCircle(Offset(px, py), particle.size / 2, bubblePaint);
          canvas.drawCircle(Offset(px, py), particle.size / 2, borderPaint);
          break;
        case _ParticleType.sparkle:
          _drawSparkle(canvas, Offset(px, py), particle.size * 0.8,
              mainColor.withValues(alpha: particle.opacity * 0.7));
          break;
      }
    }
  }

  void _drawDuckFootprint(
      Canvas canvas, Offset center, double size, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Cute 3-toed duck footprint
    final Path path = Path();
    final double s = size * 0.5;

    // Heel
    canvas.drawCircle(Offset(center.dx, center.dy + s * 0.4), s * 0.35, paint);

    // Toes (Left, Middle, Right)
    path.moveTo(center.dx - s * 0.5, center.dy - s * 0.3);
    path.lineTo(center.dx, center.dy + s * 0.2);
    path.lineTo(center.dx + s * 0.5, center.dy - s * 0.3);
    path.lineTo(center.dx, center.dy - s * 0.6);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final double s = size * 0.5;

    path.moveTo(center.dx, center.dy - s);
    path.quadraticBezierTo(
        center.dx, center.dy, center.dx + s, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy, center.dx, center.dy + s);
    path.quadraticBezierTo(
        center.dx, center.dy, center.dx - s, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy, center.dx, center.dy - s);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true;
  }
}
