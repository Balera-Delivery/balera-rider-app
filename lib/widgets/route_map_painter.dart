import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RouteMapWidget extends StatefulWidget {
  final bool isInteractive;
  final VoidCallback? onEndTrip;

  const RouteMapWidget({
    super.key,
    this.isInteractive = true,
    this.onEndTrip,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          painter: _MapCanvasPainter(progress: _animController.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final double progress;

  _MapCanvasPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background map terrain (soft cool tint)
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City Blocks / Parks
    final blockPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final parkPaint = Paint()
      ..color = const Color(0xFFE8F5E9).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Draw some city block rectangles
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.15, size.width * 0.35, size.height * 0.22),
        const Radius.circular(12),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.12, size.width * 0.38, size.height * 0.18),
        const Radius.circular(12),
      ),
      parkPaint, // Park
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.48, size.width * 0.32, size.height * 0.25),
        const Radius.circular(12),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.42, size.width * 0.35, size.height * 0.28),
        const Radius.circular(12),
      ),
      blockPaint,
    );

    // 3. Road Grids (White main streets with subtle grey outlines)
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Secondary streets
    final List<Path> roads = [
      // Main Vertical road
      Path()
        ..moveTo(size.width * 0.5, 0)
        ..lineTo(size.width * 0.5, size.height),
      // Main Horizontal road
      Path()
        ..moveTo(0, size.height * 0.4)
        ..lineTo(size.width, size.height * 0.4),
      // Diagonal Connector
      Path()
        ..moveTo(size.width * 0.1, size.height * 0.8)
        ..lineTo(size.width * 0.9, size.height * 0.2),
      // Bottom street
      Path()
        ..moveTo(0, size.height * 0.75)
        ..lineTo(size.width, size.height * 0.75),
    ];

    for (var r in roads) {
      canvas.drawPath(r, roadBorderPaint);
      canvas.drawPath(r, roadPaint);
    }

    // 4. Navigation Route Polyline (Exact delivery route shown on Screen 06)
    final routePath = Path();
    final startPt = Offset(size.width * 0.48, size.height * 0.78); // Rider start
    final p1 = Offset(size.width * 0.52, size.height * 0.58);
    final p2 = Offset(size.width * 0.45, size.height * 0.45);
    final p3 = Offset(size.width * 0.56, size.height * 0.32);
    final endPt = Offset(size.width * 0.54, size.height * 0.26); // Destination

    routePath.moveTo(startPt.dx, startPt.dy);
    routePath.lineTo(p1.dx, p1.dy);
    routePath.lineTo(p2.dx, p2.dy);
    routePath.lineTo(p3.dx, p3.dy);
    routePath.lineTo(endPt.dx, endPt.dy);

    // Route Outer Glow
    final routeGlowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routeGlowPaint);

    // Route Line Solid Blue
    final routeSolidPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routeSolidPaint);

    // 5. Destination Pin Marker with Ripple Pulse
    final pulseRadius = 14 + (progress * 10);
    final pulseAlpha = (1.0 - progress).clamp(0.0, 1.0) * 0.6;
    final ripplePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPt, pulseRadius, ripplePaint);

    final destPinPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(endPt, 9, destPinPaint);
    final destPinCenter = Paint()..color = Colors.white;
    canvas.drawCircle(endPt, 4, destPinCenter);

    // 6. Rider Navigation Pointer (Blue Arrow / Triangle)
    final riderPos = Offset(
      startPt.dx + (p1.dx - startPt.dx) * 0.4,
      startPt.dy + (p1.dy - startPt.dy) * 0.4,
    );

    final riderHalo = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(riderPos, 22, riderHalo);

    final riderBg = Paint()..color = Colors.white;
    canvas.drawCircle(riderPos, 16, riderBg);

    final riderIconPaint = Paint()..color = AppColors.primary;
    final riderArrow = Path();
    riderArrow.moveTo(riderPos.dx, riderPos.dy - 10);
    riderArrow.lineTo(riderPos.dx + 8, riderPos.dy + 8);
    riderArrow.lineTo(riderPos.dx, riderPos.dy + 4);
    riderArrow.lineTo(riderPos.dx - 8, riderPos.dy + 8);
    riderArrow.close();
    canvas.drawPath(riderArrow, riderIconPaint);

    // 7. Map Landmark Labels
    _drawText(canvas, 'Bole Medhanialem\nChurch', Offset(size.width * 0.65, size.height * 0.28), isBold: true);
    _drawText(canvas, 'Bole', Offset(size.width * 0.12, size.height * 0.72));
    _drawText(canvas, 'Bole Road', Offset(size.width * 0.52, size.height * 0.65));
  }

  void _drawText(Canvas canvas, String text, Offset offset, {bool isBold = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0xFF64748B),
        fontSize: isBold ? 11 : 10,
        fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) => true;
}
