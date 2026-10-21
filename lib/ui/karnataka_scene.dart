import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// A small, custom animated illustration inspired by Karnataka's farms and
/// Hampi stone architecture. It is drawn in Flutter so it scales cleanly.
class KarnatakaFarmScene extends StatefulWidget {
  const KarnatakaFarmScene({super.key, this.height = 178});

  final double height;

  @override
  State<KarnatakaFarmScene> createState() => _KarnatakaFarmSceneState();
}

class _KarnatakaFarmSceneState extends State<KarnatakaFarmScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: widget.height,
    decoration: BoxDecoration(
      color: paleBlue,
      borderRadius: BorderRadius.circular(22),
    ),
    clipBehavior: Clip.antiAlias,
    child: AnimatedBuilder(
      animation: motion,
      builder: (context, _) => CustomPaint(
        painter: _KarnatakaFarmPainter(motion.value),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _KarnatakaFarmPainter extends CustomPainter {
  const _KarnatakaFarmPainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sky = Paint()..color = const Color(0xffDDF2F5);
    canvas.drawRect(Offset.zero & size, sky);

    final sunY = h * (.24 + math.sin(phase * math.pi * 2) * .018);
    canvas.drawCircle(
      Offset(w * .77, sunY),
      h * .095,
      Paint()..color = const Color(0xffF3C879),
    );

    _hill(canvas, w, h, .52, const Color(0xffA6D0C8), .16, .12);
    _hill(canvas, w, h, .59, const Color(0xff78B6A7), .11, .14);

    // A compact stepped Hampi-style stone tower on the horizon.
    final stone = Paint()..color = const Color(0xffB49A79);
    final cx = w * .19;
    final baseY = h * .61;
    canvas.drawRect(
      Rect.fromLTRB(cx - w * .075, baseY - h * .12, cx + w * .075, baseY),
      stone,
    );
    for (var tier = 0; tier < 4; tier++) {
      final tierWidth = w * (.12 - tier * .022);
      final y = baseY - h * (.12 + tier * .045);
      canvas.drawRect(
        Rect.fromLTRB(cx - tierWidth / 2, y - h * .04, cx + tierWidth / 2, y),
        stone,
      );
      canvas.drawLine(
        Offset(cx - tierWidth / 2, y - h * .04),
        Offset(cx + tierWidth / 2, y - h * .04),
        Paint()
          ..color = const Color(0xffD8C29E)
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawCircle(Offset(cx, baseY - h * .30), h * .018, stone);

    // Low, terraced fields with gently moving highlights.
    final field = Paint()..color = const Color(0xff6F9C70);
    final fieldPath = Path()
      ..moveTo(0, h * .61)
      ..quadraticBezierTo(w * .52, h * .56, w, h * .63)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fieldPath, field);
    final lightField = Paint()..color = const Color(0xff86AD7A);
    final upperField = Path()
      ..moveTo(0, h * .68)
      ..quadraticBezierTo(w * .52, h * .62, w, h * .69)
      ..lineTo(w, h * .78)
      ..quadraticBezierTo(w * .52, h * .71, 0, h * .78)
      ..close();
    canvas.drawPath(upperField, lightField);

    final furrowPaint = Paint()
      ..color = const Color(0xffC3D6A0).withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 5; i++) {
      final startX = w * (.24 + i * .13);
      final offset = (phase * 10 + i * 13) % 15;
      final path = Path()
        ..moveTo(startX, h * .65)
        ..quadraticBezierTo(
          w * (.50 + (i - 2) * .07),
          h * .79,
          startX + (i - 2) * w * .18,
          h + offset,
        );
      canvas.drawPath(path, furrowPaint);
    }

    // A swaying coconut palm suggests the Karnataka coast.
    final sway = math.sin(phase * math.pi * 2) * w * .012;
    final trunk = Paint()
      ..color = const Color(0xff806B4F)
      ..strokeWidth = math.max(2, w * .012)
      ..strokeCap = StrokeCap.round;
    final root = Offset(w * .86, h * .71);
    final crown = Offset(w * .85 + sway, h * .34);
    canvas.drawLine(root, crown, trunk);
    final leafPaint = Paint()
      ..color = const Color(0xff477C58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, w * .009)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi + i * math.pi / 5;
      final end =
          crown + Offset(math.cos(angle) * w * .13, math.sin(angle) * h * .12);
      final control =
          crown + Offset(math.cos(angle) * w * .05 + sway, -h * .015);
      final leaf = Path()
        ..moveTo(crown.dx, crown.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(leaf, leafPaint);
    }

    // A few drifting birds add motion without distracting from the screen.
    final birdPaint = Paint()
      ..color = const Color(0xff3E7778)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final birdX = (phase * (w + 30)) % (w + 30) - 15;
    for (var i = 0; i < 3; i++) {
      final x = (birdX + i * w * .34) % (w + 20) - 10;
      final y = h * (.20 + (i % 2) * .065);
      final bird = Path()
        ..moveTo(x - 5, y)
        ..quadraticBezierTo(x - 2, y - 4, x, y)
        ..quadraticBezierTo(x + 3, y - 4, x + 6, y);
      canvas.drawPath(bird, birdPaint);
    }
  }

  void _hill(
    Canvas canvas,
    double width,
    double height,
    double baseline,
    Color color,
    double leftHeight,
    double rightHeight,
  ) {
    final path = Path()
      ..moveTo(0, height * baseline)
      ..quadraticBezierTo(
        width * .24,
        height * (baseline - leftHeight),
        width * .49,
        height * baseline,
      )
      ..quadraticBezierTo(
        width * .74,
        height * (baseline - rightHeight),
        width,
        height * baseline,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _KarnatakaFarmPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
