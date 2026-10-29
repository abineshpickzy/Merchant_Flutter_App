import 'package:flutter/material.dart';

/// Renders the exact Android `ic_location_current_m` icon:
/// - Base green/teal shadow plate (`#A7F3CE` -> `#009E74`)
/// - Vibrant location pin with pink/red gradient (`#E91E63` -> `#FF5252`)
/// - Center circular target hole
class StoreLocationPinIcon extends StatelessWidget {
  final double size;

  const StoreLocationPinIcon({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LocationPinPainter(),
    );
  }
}

class _LocationPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw base shadow ellipse (teal/green)
    final baseRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.76,
      height: h * 0.22,
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFA7F3CE), Color(0xFF009E74)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect);

    canvas.drawOval(baseRect, basePaint);

    // Inner darker shadow ellipse
    final innerShadowRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.87),
      width: w * 0.45,
      height: h * 0.14,
    );
    final innerShadowPaint = Paint()
      ..color = const Color(0xFF008960).withValues(alpha: 0.5);
    canvas.drawOval(innerShadowRect, innerShadowPaint);

    // 2. Draw Pin Path (pink/red gradient)
    final pinRect = Rect.fromLTWH(w * 0.18, 0, w * 0.64, h * 0.82);
    final pinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE91E63), Color(0xFFFF5252), Color(0xFFBE3F45)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(pinRect)
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    final pinCenterX = w * 0.5;
    final pinHeadRadius = w * 0.31;
    final pinCenterY = pinHeadRadius + h * 0.02;
    final pinTipY = h * 0.82;

    // Outer circle arc of pin head
    pinPath.addArc(
      Rect.fromCircle(center: Offset(pinCenterX, pinCenterY), radius: pinHeadRadius),
      0.65,
      4.98,
    );
    // Line down to bottom tip
    pinPath.lineTo(pinCenterX, pinTipY);
    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);

    // 3. Draw Center white/bright circle hole
    final holeRadius = pinHeadRadius * 0.40;
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(pinCenterX, pinCenterY), holeRadius, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
