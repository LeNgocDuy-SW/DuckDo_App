import 'dart:math' as math;
import 'package:flutter/material.dart';

class DuckLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showQuackBadge;
  final String equippedHat; // 'none', 'grad_cap', 'sunglasses', 'crown', 'top_hat'

  const DuckLogo({
    super.key,
    this.size = 140,
    this.animate = true,
    this.showQuackBadge = true,
    this.equippedHat = 'none',
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
        final double floatOffset = widget.animate
            ? math.sin(_controller.value * math.pi) * 10
            : 0;
        final double wingAngle = widget.animate
            ? math.sin(_controller.value * math.pi * 2) * 0.08
            : 0;
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
                    equippedHat: widget.equippedHat,
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
  final String equippedHat;

  _DuckPainter({
    required this.wingAngle,
    required this.equippedHat,
  });

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
          Color(0xFFFFF176),
          Color(0xFFFFCA28),
          Color(0xFFFFB300),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // 2. Main Body Outline / Soft Shadow Paint
    final Paint bodyShadowPaint = Paint()
      ..color = const Color(0xFFF57F17).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // --- DRAW BODY ---
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

    // --- DRAW HEAD ---
    final Offset headCenter = Offset(w * 0.5, h * 0.32);
    final double headRadius = w * 0.32;
    canvas.drawCircle(headCenter, headRadius, bodyPaint);
    canvas.drawCircle(headCenter, headRadius, bodyShadowPaint);

    // --- HEAD FEATHER TUFT (If no hat) ---
    if (equippedHat == 'none') {
      final Path tuftPath = Path()
        ..moveTo(w * 0.46, h * 0.05)
        ..quadraticBezierTo(w * 0.5, h * 0.0, w * 0.52, h * 0.06)
        ..quadraticBezierTo(w * 0.58, h * 0.01, w * 0.55, h * 0.1)
        ..quadraticBezierTo(w * 0.48, h * 0.12, w * 0.46, h * 0.05);
      canvas.drawPath(tuftPath, bodyPaint);
      canvas.drawPath(tuftPath, bodyShadowPaint);
    }

    // --- CHEEKS ---
    final Paint cheekPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65);
    canvas.drawCircle(Offset(w * 0.28, h * 0.36), w * 0.065, cheekPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.36), w * 0.065, cheekPaint);

    // --- EYES ---
    final Paint eyePaint = Paint()..color = const Color(0xFF263238);
    final Paint eyeSparklePaint = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(w * 0.38, h * 0.3), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.365, h * 0.285), w * 0.02, eyeSparklePaint);

    canvas.drawCircle(Offset(w * 0.62, h * 0.3), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.605, h * 0.285), w * 0.02, eyeSparklePaint);

    // --- ACCESSORY: SUNGLASSES 🕶️ ---
    if (equippedHat == 'sunglasses') {
      final Paint glassPaint = Paint()..color = const Color(0xFF1E293B);
      final Path glassPath = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.25, h * 0.24, w * 0.23, h * 0.11),
          const Radius.circular(6),
        ))
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.52, h * 0.24, w * 0.23, h * 0.11),
          const Radius.circular(6),
        ));
      canvas.drawPath(glassPath, glassPaint);

      // Glass bridge
      final Paint bridgePaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.48, h * 0.28), Offset(w * 0.52, h * 0.28), bridgePaint);

      // Glass reflection shine line
      final Paint shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(w * 0.27, h * 0.32), Offset(w * 0.35, h * 0.26), shinePaint);
      canvas.drawLine(Offset(w * 0.54, h * 0.32), Offset(w * 0.62, h * 0.26), shinePaint);
    }

    // --- BEAK ---
    final Paint beakPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF9800),
          Color(0xFFF57C00),
        ],
      ).createShader(Rect.fromLTWH(w * 0.35, h * 0.33, w * 0.3, h * 0.14));

    final Path beakPath = Path()
      ..moveTo(w * 0.38, h * 0.34)
      ..quadraticBezierTo(w * 0.5, h * 0.29, w * 0.62, h * 0.34)
      ..quadraticBezierTo(w * 0.66, h * 0.42, w * 0.5, h * 0.46)
      ..quadraticBezierTo(w * 0.34, h * 0.42, w * 0.38, h * 0.34);
    canvas.drawPath(beakPath, beakPaint);

    final Paint beakLinePaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final Path smileLine = Path()
      ..moveTo(w * 0.4, h * 0.38)
      ..quadraticBezierTo(w * 0.5, h * 0.41, w * 0.6, h * 0.38);
    canvas.drawPath(smileLine, beakLinePaint);

    // --- ACCESSORIES ON HEAD ---
    if (equippedHat == 'grad_cap') {
      // 🎓 Graduation Cap
      final Paint capPaint = Paint()..color = const Color(0xFF1E293B);
      final Path capDiamond = Path()
        ..moveTo(w * 0.5, h * -0.02)
        ..lineTo(w * 0.8, h * 0.08)
        ..lineTo(w * 0.5, h * 0.18)
        ..lineTo(w * 0.2, h * 0.08)
        ..close();
      canvas.drawPath(capDiamond, capPaint);

      // Skull cap base
      canvas.drawRect(Rect.fromLTWH(w * 0.35, h * 0.08, w * 0.3, h * 0.06), capPaint);

      // Tassel
      final Paint tasselPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 2.5;
      canvas.drawLine(Offset(w * 0.5, h * 0.08), Offset(w * 0.75, h * 0.16), tasselPaint);
      canvas.drawCircle(Offset(w * 0.75, h * 0.18), 3.5, Paint()..color = const Color(0xFFFFD54F));
    } else if (equippedHat == 'crown') {
      // 👑 Royal Crown
      final Paint crownPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
        ).createShader(Rect.fromLTWH(w * 0.3, h * -0.05, w * 0.4, h * 0.16));

      final Path crownPath = Path()
        ..moveTo(w * 0.28, h * 0.12)
        ..lineTo(w * 0.24, h * -0.02)
        ..lineTo(w * 0.4, h * 0.05)
        ..lineTo(w * 0.5, h * -0.06)
        ..lineTo(w * 0.6, h * 0.05)
        ..lineTo(w * 0.76, h * -0.02)
        ..lineTo(w * 0.72, h * 0.12)
        ..close();
      canvas.drawPath(crownPath, crownPaint);

      // Rubies on Crown
      final Paint ruby = Paint()..color = const Color(0xFFEF4444);
      canvas.drawCircle(Offset(w * 0.24, h * -0.02), 3, ruby);
      canvas.drawCircle(Offset(w * 0.5, h * -0.06), 4, ruby);
      canvas.drawCircle(Offset(w * 0.76, h * -0.02), 3, ruby);
    } else if (equippedHat == 'top_hat') {
      // 🎩 Magic Top Hat
      final Paint hatPaint = Paint()..color = const Color(0xFF0F172A);
      final Paint ribbonPaint = Paint()..color = const Color(0xFFEF4444);

      // Brim
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.08, w * 0.56, h * 0.05),
          const Radius.circular(3),
        ),
        hatPaint,
      );

      // Top cylinder
      canvas.drawRect(Rect.fromLTWH(w * 0.32, h * -0.1, w * 0.36, h * 0.18), hatPaint);
      // Ribbon band
      canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.04, w * 0.36, h * 0.04), ribbonPaint);
    }

    // --- WINGS ---
    canvas.save();
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
    canvas.translate(w * 0.8, h * 0.52);
    canvas.rotate(0.25 + wingAngle);
    final Path rightWingPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(w * 0.15, h * 0.05, w * 0.15, h * 0.22, 0, h * 0.2)
      ..close();
    canvas.drawPath(rightWingPath, bodyPaint);
    canvas.drawPath(rightWingPath, bodyShadowPaint);
    canvas.restore();

    // --- FEET ---
    final Paint footPaint = Paint()..color = const Color(0xFFFF9800);

    final Path leftFoot = Path()
      ..moveTo(w * 0.38, h * 0.86)
      ..lineTo(w * 0.32, h * 0.94)
      ..quadraticBezierTo(w * 0.38, h * 0.96, w * 0.44, h * 0.94)
      ..close();
    canvas.drawPath(leftFoot, footPaint);

    final Path rightFoot = Path()
      ..moveTo(w * 0.62, h * 0.86)
      ..lineTo(w * 0.56, h * 0.94)
      ..quadraticBezierTo(w * 0.62, h * 0.96, w * 0.68, h * 0.94)
      ..close();
    canvas.drawPath(rightFoot, footPaint);
  }

  @override
  bool shouldRepaint(covariant _DuckPainter oldDelegate) {
    return oldDelegate.wingAngle != wingAngle ||
        oldDelegate.equippedHat != equippedHat;
  }
}
