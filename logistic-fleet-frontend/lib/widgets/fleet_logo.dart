import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Logistic Fleet's brand mark: a gradient rounded badge containing a custom
/// painted delivery truck with motion lines, topped by a small route-pin
/// accent. Fully vector (no image assets), so it scales crisply anywhere
/// from a bottom-nav icon to a full-screen splash hero.
class LogisticFleetLogo extends StatelessWidget {
  final double size;
  final bool showPin;
  final BorderRadiusGeometry? borderRadius;

  const LogisticFleetLogo({
    super.key,
    this.size = 64,
    this.showPin = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: radius,
              boxShadow: AppShadows.brand,
            ),
            child: CustomPaint(
              size: Size(size, size),
              painter: _TruckPainter(),
            ),
          ),
          if (showPin)
            Positioned(
              right: -size * 0.08,
              top: -size * 0.08,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  gradient: AppGradients.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: size * 0.035),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentDark.withOpacity(0.4),
                      blurRadius: size * 0.12,
                      offset: Offset(0, size * 0.03),
                    ),
                  ],
                ),
                child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.2),
              ),
            ),
        ],
      ),
    );
  }
}

class _TruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final white = Paint()..color = Colors.white;
    final whiteFaint = Paint()..color = Colors.white.withOpacity(0.55);
    final glass = Paint()..color = Colors.white.withOpacity(0.35);

    // Motion lines (behind the truck), suggesting movement.
    for (var i = 0; i < 3; i++) {
      final y = h * (0.34 + i * 0.09);
      final len = w * (0.14 - i * 0.02);
      canvas.drawLine(
        Offset(w * 0.08, y),
        Offset(w * 0.08 + len, y),
        Paint()
          ..color = Colors.white.withOpacity(0.32 - i * 0.08)
          ..strokeWidth = h * 0.028
          ..strokeCap = StrokeCap.round,
      );
    }

    // Trailer (main box body).
    final trailerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.34, w * 0.40, h * 0.30),
      Radius.circular(w * 0.035),
    );
    canvas.drawRRect(trailerRect, white);

    // Cab (front of truck).
    final cabPath = Path()
      ..moveTo(w * 0.60, h * 0.64)
      ..lineTo(w * 0.60, h * 0.44)
      ..lineTo(w * 0.70, h * 0.44)
      ..lineTo(w * 0.80, h * 0.54)
      ..lineTo(w * 0.80, h * 0.64)
      ..close();
    canvas.drawPath(cabPath, white);

    // Windshield.
    final windshieldPath = Path()
      ..moveTo(w * 0.645, h * 0.48)
      ..lineTo(w * 0.685, h * 0.48)
      ..lineTo(w * 0.75, h * 0.545)
      ..lineTo(w * 0.645, h * 0.545)
      ..close();
    canvas.drawPath(windshieldPath, glass);

    // Trailer window/stripe detail.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.245, h * 0.40, w * 0.33, h * 0.045),
        Radius.circular(w * 0.02),
      ),
      whiteFaint,
    );

    // Wheels.
    final wheelPaint = Paint()..color = Colors.white;
    final hubPaint = Paint()..color = AppColors.primaryDark;
    for (final cx in [w * 0.33, w * 0.68]) {
      canvas.drawCircle(Offset(cx, h * 0.68), w * 0.068, wheelPaint);
      canvas.drawCircle(Offset(cx, h * 0.68), w * 0.032, hubPaint);
    }

    // Ground line.
    canvas.drawLine(
      Offset(w * 0.18, h * 0.72),
      Offset(w * 0.82, h * 0.72),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = h * 0.014
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wraps [LogisticFleetLogo] with a gentle entrance (scale + fade) animation,
/// useful on splash and login screens.
class AnimatedLogisticFleetLogo extends StatelessWidget {
  final double size;
  final Duration duration;

  const AnimatedLogisticFleetLogo({
    super.key,
    this.size = 88,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: 0.7 + (0.3 * value), child: child),
        );
      },
      child: LogisticFleetLogo(size: size),
    );
  }
}

/// Compact wordmark ("Logistic Fleet") that pairs with [LogisticFleetLogo] in app bars
/// and hero headers.
class LogisticFleetWordmark extends StatelessWidget {
  final Color color;
  final double fontSize;

  const LogisticFleetWordmark({super.key, this.color = Colors.white, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: color),
        children: [
          const TextSpan(text: 'Logistic'),
          TextSpan(text: 'Fleet', style: TextStyle(color: color.withOpacity(0.72))),
        ],
      ),
    );
  }
}
