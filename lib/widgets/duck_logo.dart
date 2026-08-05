import 'dart:math' as math;
import 'package:flutter/material.dart';

class DuckLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showQuackBadge;

  const DuckLogo({
    super.key,
    this.size = 140,
    this.animate = true,
    this.showQuackBadge = true,
  });

  @override
  State<DuckLogo> createState() => _DuckLogoState();
}

class _DuckLogoState extends State<DuckLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DuckLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
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
        // Sine wave interpolation for floating motion
        final double floatOffset = math.sin(_controller.value * math.pi) * 10;
        final double wingAngle = math.sin(_controller.value * math.pi * 2) * 0.08;
        final double shadowScale = 1.0 - (floatOffset / 40);

        return SizedBox(
          width: widget.size * 1.2,
          height: widget.size * 1.35,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Dynamic Floor Shadow
              Positioned(
                bottom: 4,
                child: Transform.scale(
                  scale: shadowScale,
                  child: Container(
                    width: widget.size * 0.75,
                    height: widget.size * 0.16,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(widget.size * 0.4, widget.size * 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade900.withValues(alpha: 0.12),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Duck Floating Body
              Positioned(
                top: 10 - floatOffset,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _DuckPainter(
                    wingAngle: wingAngle,
                  ),
                ),
              ),

              // Floating "Quack!" Speech Badge
              if (widget.showQuackBadge)
                Positioned(
                  top: 0 - floatOffset * 0.5,
                  right: 0,
                  child: Transform.rotate(
                    angle: 0.12 + (floatOffset * 0.005),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 1.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFFE65100),
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Quack!",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DuckPainter extends CustomPainter {
  final double wingAngle;

  _DuckPainter({required this.wingAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Duck Body Paint (Vibrant Yellow Gradient)
    final Paint bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.85,
        colors: const [
          Color(0xFFFFF176), // Bright Sunny Yellow
          Color(0xFFFFCA28), // Golden Yellow
          Color(0xFFFFB300), // Rich Amber
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // 2. Main Body Outline / Soft Shadow Paint
    final Paint bodyShadowPaint = Paint()
      ..color = const Color(0xFFF57F17).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // --- DRAW BODY (Lower oval shape) ---
    final Rect bodyRect = Rect.fromLTWH(
      w * 0.15,
      h * 0.35,
      w * 0.7,
      h * 0.55,
    );
    final RRect bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(w * 0.3),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);
    canvas.drawRRect(bodyRRect, bodyShadowPaint);

    // --- DRAW HEAD (Top circle) ---
    final Offset headCenter = Offset(w * 0.5, h * 0.32);
    final double headRadius = w * 0.32;
    canvas.drawCircle(headCenter, headRadius, bodyPaint);
    canvas.drawCircle(headCenter, headRadius, bodyShadowPaint);

    // --- HEAD FEATHER TUFT (Cute hair on top) ---
    final Path tuftPath = Path()
      ..moveTo(w * 0.46, h * 0.05)
      ..quadraticBezierTo(w * 0.5, h * 0.0, w * 0.52, h * 0.06)
      ..quadraticBezierTo(w * 0.58, h * 0.01, w * 0.55, h * 0.1)
      ..quadraticBezierTo(w * 0.48, h * 0.12, w * 0.46, h * 0.05);
    canvas.drawPath(tuftPath, bodyPaint);
    canvas.drawPath(tuftPath, bodyShadowPaint);

    // --- CHEEKS (Cute Rosy Pink) ---
    final Paint cheekPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65);
    canvas.drawCircle(Offset(w * 0.28, h * 0.36), w * 0.065, cheekPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.36), w * 0.065, cheekPaint);

    // --- EYES (Glossy Anime/Cartoon Eyes) ---
    final Paint eyePaint = Paint()..color = const Color(0xFF263238);
    final Paint eyeSparklePaint = Paint()..color = Colors.white;

    // Left Eye
    canvas.drawCircle(Offset(w * 0.38, h * 0.3), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.365, h * 0.285), w * 0.02, eyeSparklePaint);

    // Right Eye
    canvas.drawCircle(Offset(w * 0.62, h * 0.3), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.605, h * 0.285), w * 0.02, eyeSparklePaint);

    // --- BEAK (Cute Orange Beak) ---
    final Paint beakPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF9800), // Vibrant Orange
          Color(0xFFF57C00), // Deep Orange
        ],
      ).createShader(Rect.fromLTWH(w * 0.35, h * 0.33, w * 0.3, h * 0.14));

    final Path beakPath = Path()
      ..moveTo(w * 0.38, h * 0.34)
      ..quadraticBezierTo(w * 0.5, h * 0.29, w * 0.62, h * 0.34)
      ..quadraticBezierTo(w * 0.66, h * 0.42, w * 0.5, h * 0.46)
      ..quadraticBezierTo(w * 0.34, h * 0.42, w * 0.38, h * 0.34);
    canvas.drawPath(beakPath, beakPaint);

    // Beak smile curve divider
    final Paint beakLinePaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final Path smileLine = Path()
      ..moveTo(w * 0.4, h * 0.38)
      ..quadraticBezierTo(w * 0.5, h * 0.41, w * 0.6, h * 0.38);
    canvas.drawPath(smileLine, beakLinePaint);

    // --- WINGS (Left & Right Flapping Wings) ---
    canvas.save();
    // Left Wing
    canvas.translate(w * 0.2, h * 0.52);
    canvas.rotate(-0.25 - wingAngle);
    final Path leftWingPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(-w * 0.15, h * 0.05, -w * 0.15, h * 0.22, 0, h * 0.2)
      ..close();
    canvas.drawPath(leftWingPath, bodyPaint);
    canvas.drawPath(leftWingPath, bodyShadowPaint);
    canvas.restore();

    canvas.save();
    // Right Wing
    canvas.translate(w * 0.8, h * 0.52);
    canvas.rotate(0.25 + wingAngle);
    final Path rightWingPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(w * 0.15, h * 0.05, w * 0.15, h * 0.22, 0, h * 0.2)
      ..close();
    canvas.drawPath(rightWingPath, bodyPaint);
    canvas.drawPath(rightWingPath, bodyShadowPaint);
    canvas.restore();

    // --- LITTLE DUCK FEET (Cute Orange Feet under body) ---
    final Paint footPaint = Paint()..color = const Color(0xFFFF9800);

    // Left Foot
    final Path leftFoot = Path()
      ..moveTo(w * 0.38, h * 0.86)
      ..lineTo(w * 0.32, h * 0.94)
      ..quadraticBezierTo(w * 0.38, h * 0.96, w * 0.44, h * 0.94)
      ..close();
    canvas.drawPath(leftFoot, footPaint);

    // Right Foot
    final Path rightFoot = Path()
      ..moveTo(w * 0.62, h * 0.86)
      ..lineTo(w * 0.56, h * 0.94)
      ..quadraticBezierTo(w * 0.62, h * 0.96, w * 0.68, h * 0.94)
      ..close();
    canvas.drawPath(rightFoot, footPaint);
  }

  @override
  bool shouldRepaint(covariant _DuckPainter oldDelegate) {
    return oldDelegate.wingAngle != wingAngle;
  }
}
