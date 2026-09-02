import 'package:flutter/material.dart';

class RiderIllustrationWidget extends StatelessWidget {
  final double height;
  final double width;

  const RiderIllustrationWidget({
    super.key,
    this.height = 260,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: _RiderScenePainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _RiderScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate scaling system normalized around a 360x280 reference box
    final double scale = (size.width / 360).clamp(0.6, 1.4);
    final double originX = (size.width - (360 * scale)) / 2;
    final double originY = (size.height - (260 * scale)) / 2;

    canvas.save();
    canvas.translate(originX, originY);
    canvas.scale(scale);

    // ==========================================
    // 1. CITY SKYLINE SILHOUETTE (BACKGROUND)
    // ==========================================
    final bgBuildingPaint1 = Paint()
      ..color = const Color(0xFFEDF4FC)
      ..style = PaintingStyle.fill;
    final bgBuildingPaint2 = Paint()
      ..color = const Color(0xFFDDEBFA)
      ..style = PaintingStyle.fill;
    final windowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Distant light buildings
    _drawBuilding(canvas, 10, 50, 45, 170, bgBuildingPaint1, hasSpire: true);
    _drawBuilding(canvas, 60, 30, 65, 190, bgBuildingPaint1);
    _drawBuilding(canvas, 130, 60, 45, 160, bgBuildingPaint1);
    _drawBuilding(canvas, 180, 20, 60, 200, bgBuildingPaint1, hasSpire: true);
    _drawBuilding(canvas, 245, 45, 55, 175, bgBuildingPaint1);
    _drawBuilding(canvas, 305, 70, 50, 150, bgBuildingPaint1, hasSpire: true);

    // Mid-ground crisp buildings with window rows
    _drawBuildingWithWindows(canvas, 25, 75, 40, 145, bgBuildingPaint2, windowPaint);
    _drawBuildingWithWindows(canvas, 75, 45, 55, 175, bgBuildingPaint2, windowPaint);
    _drawBuildingWithWindows(canvas, 140, 80, 38, 140, bgBuildingPaint2, windowPaint);
    _drawBuildingWithWindows(canvas, 190, 40, 52, 180, bgBuildingPaint2, windowPaint);
    _drawBuildingWithWindows(canvas, 250, 65, 45, 155, bgBuildingPaint2, windowPaint);
    _drawBuildingWithWindows(canvas, 300, 85, 42, 135, bgBuildingPaint2, windowPaint);

    // Ground shadow oval
    final shadowPaint = Paint()
      ..color = const Color(0xFFD6E6F9).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      const Rect.fromLTWH(30, 216, 260, 18),
      shadowPaint,
    );

    // ==========================================
    // 2. LARGE BLUE MAP PIN MARKER (RIGHT SIDE)
    // ==========================================
    _drawMapPin(canvas);

    // ==========================================
    // 3. DELIVERY BOX (CARGO TRUNK ON BACK)
    // ==========================================
    _drawDeliveryBox(canvas);

    // ==========================================
    // 4. RIDER (BODY, CLOTHES, HEAD & CAP)
    // ==========================================
    _drawRider(canvas);

    // ==========================================
    // 5. SCOOTER (WHEELS, BODY, HEADLIGHT, TAILLIGHT)
    // ==========================================
    _drawScooter(canvas);

    canvas.restore();
  }

  void _drawBuilding(Canvas canvas, double x, double y, double w, double h, Paint paint, {bool hasSpire = false}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
      paint,
    );
    if (hasSpire) {
      canvas.drawLine(
        Offset(x + w / 2, y),
        Offset(x + w / 2, y - 18),
        Paint()
          ..color = paint.color
          ..strokeWidth = 2,
      );
    }
  }

  void _drawBuildingWithWindows(Canvas canvas, double x, double y, double w, double h, Paint bPaint, Paint wPaint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      bPaint,
    );
    // Draw subtle vertical window strips
    for (double r = y + 15; r < y + h - 20; r += 16) {
      for (double c = x + 8; c < x + w - 8; c += 10) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(c, r, 5, 8), const Radius.circular(1)),
          wPaint,
        );
      }
    }
  }

  void _drawMapPin(Canvas canvas) {
    const double pinCenterX = 300;
    const double pinCenterY = 120;
    const double pinRadius = 32;

    // Pin Stand / Ground Platform
    final standPaint = Paint()
      ..color = const Color(0xFF7BAEEF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(pinCenterX, 175), const Offset(pinCenterX, 225), standPaint);
    canvas.drawLine(const Offset(pinCenterX - 14, 225), const Offset(pinCenterX + 14, 225), standPaint);

    // Base building cluster under pin
    final clusterPaint = Paint()
      ..color = const Color(0xFF6B9DE8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromLTRBAndCorners(pinCenterX - 24, 185, pinCenterX - 10, 202, topLeft: const Radius.circular(2), topRight: const Radius.circular(2)), clusterPaint);
    canvas.drawRRect(RRect.fromLTRBAndCorners(pinCenterX - 8, 178, pinCenterX + 8, 202, topLeft: const Radius.circular(2), topRight: const Radius.circular(2)), clusterPaint);
    canvas.drawRRect(RRect.fromLTRBAndCorners(pinCenterX + 10, 182, pinCenterX + 24, 202, topLeft: const Radius.circular(2), topRight: const Radius.circular(2)), clusterPaint);

    // Main Vibrant Blue Pin Body
    final pinPaint = Paint()
      ..color = const Color(0xFF0066FF)
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    pinPath.moveTo(pinCenterX, pinCenterY + pinRadius + 24); // Bottom tip
    pinPath.cubicTo(
      pinCenterX - 18, pinCenterY + pinRadius + 4,
      pinCenterX - pinRadius, pinCenterY + 12,
      pinCenterX - pinRadius, pinCenterY,
    );
    pinPath.arcTo(
      Rect.fromCircle(center: const Offset(pinCenterX, pinCenterY), radius: pinRadius),
      3.14159,
      3.14159,
      false,
    );
    pinPath.cubicTo(
      pinCenterX + pinRadius, pinCenterY + 12,
      pinCenterX + 18, pinCenterY + pinRadius + 4,
      pinCenterX, pinCenterY + pinRadius + 24,
    );
    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);

    // Inner White Cutout Circle
    final cutoutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(pinCenterX, pinCenterY), 13, cutoutPaint);
  }

  void _drawDeliveryBox(Canvas canvas) {
    // Box Shadow
    final boxShadow = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(204, 110, 48, 48), const Radius.circular(6)),
      boxShadow,
    );

    // Light Grey/Silver Thermal Box
    final boxPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final boxOutline = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final boxRect = RRect.fromRectAndRadius(const Rect.fromLTWH(202, 108, 46, 46), const Radius.circular(6));
    canvas.drawRRect(boxRect, boxPaint);
    canvas.drawRRect(boxRect, boxOutline);

    // Box Handle / Latch
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(221, 126, 8, 3), const Radius.circular(1.5)),
      boxOutline,
    );
  }

  void _drawRider(Canvas canvas) {
    final outlinePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final skinPaint = Paint()
      ..color = const Color(0xFFF3C19C)
      ..style = PaintingStyle.fill;
    final hairPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final shirtPaint = Paint()
      ..color = const Color(0xFF0066FF) // Royal Balera Blue Shirt
      ..style = PaintingStyle.fill;
    final pantsPaint = Paint()
      ..color = const Color(0xFF1E3A8A) // Dark Navy Pants
      ..style = PaintingStyle.fill;
    final shoePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 1. Back/Legs (Pants)
    final legPath = Path();
    legPath.moveTo(188, 142); // Hip on seat
    legPath.lineTo(198, 160); // Thigh back
    legPath.lineTo(162, 166); // Knee forward
    legPath.lineTo(154, 204); // Shin down
    legPath.lineTo(138, 204); // Ankle
    legPath.lineTo(142, 160); // Thigh front
    legPath.lineTo(172, 138); // Waist
    legPath.close();
    canvas.drawPath(legPath, pantsPaint);
    canvas.drawPath(legPath, outlinePaint);

    // Shoe
    final shoePath = Path();
    shoePath.moveTo(136, 202);
    shoePath.lineTo(154, 202);
    shoePath.lineTo(156, 210);
    shoePath.lineTo(130, 210);
    shoePath.close();
    canvas.drawPath(shoePath, shoePaint);
    canvas.drawPath(shoePath, outlinePaint);

    // 2. Torso (Blue Shirt)
    final torsoPath = Path();
    torsoPath.moveTo(172, 138); // Lower back
    torsoPath.lineTo(192, 138); // Hip
    torsoPath.lineTo(196, 96);  // Shoulder back
    torsoPath.lineTo(176, 92);  // Collar
    torsoPath.lineTo(162, 126); // Chest
    torsoPath.close();
    canvas.drawPath(torsoPath, shirtPaint);
    canvas.drawPath(torsoPath, outlinePaint);

    // 3. Arm & Hand (Reaching handlebar)
    final armPath = Path();
    armPath.moveTo(186, 96);  // Shoulder
    armPath.lineTo(152, 122); // Elbow
    armPath.lineTo(124, 126); // Wrist
    armPath.lineTo(124, 134); // Hand bottom
    armPath.lineTo(148, 130); // Forearm bottom
    armPath.lineTo(178, 108); // Underarm
    armPath.close();
    canvas.drawPath(armPath, shirtPaint);
    canvas.drawPath(armPath, outlinePaint);

    // Hand on grip
    canvas.drawCircle(const Offset(120, 128), 5, skinPaint);
    canvas.drawCircle(const Offset(120, 128), 5, outlinePaint);

    // 4. Neck & Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(172, 78, 10, 14), const Radius.circular(2)),
      skinPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(172, 78, 10, 14), const Radius.circular(2)),
      outlinePaint,
    );

    // Head circle / face
    canvas.drawCircle(const Offset(175, 72), 12, skinPaint);
    canvas.drawCircle(const Offset(175, 72), 12, outlinePaint);

    // Hair
    canvas.drawArc(
      const Rect.fromLTWH(164, 62, 20, 18),
      1.57,
      3.14,
      true,
      hairPaint,
    );

    // 5. Rider Cap / Helmet (Royal Blue)
    final capPaint = Paint()
      ..color = const Color(0xFF0052D4)
      ..style = PaintingStyle.fill;

    final capPath = Path();
    capPath.moveTo(186, 70);
    capPath.arcTo(const Rect.fromLTWH(163, 56, 24, 20), 0, -3.14, true);
    capPath.lineTo(154, 68); // Visor tip extending forward
    capPath.lineTo(165, 73); // Visor underside
    capPath.close();
    canvas.drawPath(capPath, capPaint);
    canvas.drawPath(capPath, outlinePaint);
  }

  void _drawScooter(Canvas canvas) {
    final outlinePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final bodyPaint = Paint()
      ..color = const Color(0xFF0066FF) // Royal Blue Scooter Body
      ..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;
    final tirePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    final hubPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;
    final seatPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // 1. FRONT WHEEL
    _drawWheel(canvas, const Offset(82, 198), 24, tirePaint, rimPaint, hubPaint, outlinePaint);

    // 2. REAR WHEEL
    _drawWheel(canvas, const Offset(236, 198), 24, tirePaint, rimPaint, hubPaint, outlinePaint);

    // 3. FRONT FORK & SHOCK
    final forkPath = Path();
    forkPath.moveTo(82, 198);
    forkPath.lineTo(98, 145);
    forkPath.lineTo(112, 125);
    canvas.drawPath(forkPath, outlinePaint);

    // 4. FRONT SHIELD / APRON & MUDGUARD
    final mudguardPath = Path();
    mudguardPath.moveTo(56, 185);
    mudguardPath.cubicTo(60, 168, 86, 162, 102, 172);
    mudguardPath.lineTo(96, 185);
    mudguardPath.close();
    canvas.drawPath(mudguardPath, bodyPaint);
    canvas.drawPath(mudguardPath, outlinePaint);

    // Curved front shield
    final shieldPath = Path();
    shieldPath.moveTo(96, 138);
    shieldPath.cubicTo(82, 146, 72, 165, 88, 182);
    shieldPath.lineTo(108, 185);
    shieldPath.lineTo(116, 138);
    shieldPath.close();
    canvas.drawPath(shieldPath, bodyPaint);
    canvas.drawPath(shieldPath, outlinePaint);

    // 5. SCOOTER FLOORBOARD / UNDERBELLY
    final bellyPath = Path();
    bellyPath.moveTo(102, 184);
    bellyPath.lineTo(128, 206); // Footboard drop
    bellyPath.lineTo(178, 206); // Footboard flat
    bellyPath.lineTo(186, 174); // Engine cover rise
    bellyPath.lineTo(248, 172); // Rear tail
    bellyPath.cubicTo(260, 176, 260, 192, 238, 200); // Rear fender arc
    bellyPath.lineTo(184, 196);
    bellyPath.lineTo(170, 184);
    bellyPath.close();
    canvas.drawPath(bellyPath, bodyPaint);
    canvas.drawPath(bellyPath, outlinePaint);

    // Side Cowl Accent / Highlight
    final cowlPath = Path();
    cowlPath.moveTo(186, 174);
    cowlPath.cubicTo(200, 154, 234, 154, 252, 172);
    cowlPath.lineTo(238, 188);
    cowlPath.cubicTo(220, 174, 198, 174, 186, 174);
    cowlPath.close();
    canvas.drawPath(cowlPath, highlightPaint);
    canvas.drawPath(cowlPath, outlinePaint);

    // Chrome Exhaust Pipe
    final exhaustPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(204, 198), const Offset(246, 190), exhaustPaint);

    // 6. SADDLE SEAT
    final seatPath = Path();
    seatPath.moveTo(172, 142);
    seatPath.lineTo(214, 142);
    seatPath.cubicTo(218, 142, 218, 150, 210, 152);
    seatPath.lineTo(176, 152);
    seatPath.close();
    canvas.drawPath(seatPath, seatPaint);
    canvas.drawPath(seatPath, outlinePaint);

    // 7. HANDLEBARS & HEADLIGHT
    // Steering column
    final headStem = Path();
    headStem.moveTo(112, 126);
    headStem.lineTo(116, 116);
    canvas.drawPath(headStem, outlinePaint);

    // Headlight pod
    final podPath = Path();
    podPath.moveTo(110, 116);
    podPath.lineTo(122, 116);
    podPath.lineTo(120, 128);
    podPath.lineTo(108, 128);
    podPath.close();
    canvas.drawPath(podPath, bodyPaint);
    canvas.drawPath(podPath, outlinePaint);

    // Round Headlamp (Facing Left)
    final lampPaint = Paint()
      ..color = const Color(0xFFFEF08A) // Soft yellow glow
      ..style = PaintingStyle.fill;
    final lampRim = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(104, 122), 6, lampRim);
    canvas.drawCircle(const Offset(104, 122), 6, outlinePaint);
    canvas.drawCircle(const Offset(103, 122), 4, lampPaint);

    // Rearview Mirror
    canvas.drawLine(const Offset(118, 116), const Offset(124, 100), outlinePaint);
    canvas.drawOval(const Rect.fromLTWH(121, 95, 6, 9), Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawOval(const Rect.fromLTWH(121, 95, 6, 9), outlinePaint);

    // Taillight (Red)
    final tailPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(254, 172), 4, tailPaint);
    canvas.drawCircle(const Offset(254, 172), 4, outlinePaint);
  }

  void _drawWheel(Canvas canvas, Offset center, double radius, Paint tire, Paint rim, Paint hub, Paint outline) {
    // Outer black tire
    canvas.drawCircle(center, radius, tire);
    canvas.drawCircle(center, radius, outline);

    // Inner rim
    canvas.drawCircle(center, radius * 0.62, rim);
    canvas.drawCircle(center, radius * 0.62, outline);

    // Center hub & bolt
    canvas.drawCircle(center, radius * 0.28, hub);
    canvas.drawCircle(center, radius * 0.28, outline);
    canvas.drawCircle(center, 2, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
