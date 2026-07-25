import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fully-animated vector characters drawn with CustomPaint.
/// No image assets needed — infinitely scalable, works offline.
///
/// Supported characters: 'dino' (Rex) and 'doll' (Lily).
/// Supported actions: idle, walk_in, run_forward, jump, celebrate.
class PalCharacter extends StatefulWidget {
  const PalCharacter({
    super.key,
    required this.character,
    this.action = 'idle',
    this.size = 160,
  });

  final String character;
  final String action;
  final double size;

  @override
  State<PalCharacter> createState() => _PalCharacterState();
}

class _PalCharacterState extends State<PalCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value * 60.0; // seconds
        return CustomPaint(
          size: Size(widget.size, widget.size * 1.1),
          painter: widget.character == 'doll'
              ? _DollPainter(t: t, action: widget.action)
              : _DinoPainter(t: t, action: widget.action),
        );
      },
    );
  }
}

/// Shared pose math for both characters.
class _Pose {
  _Pose(double t, String action) {
    // Breathing: gentle scale oscillation.
    breath = math.sin(t * 2 * math.pi / 2.6) * 0.018;

    // Blink: every ~3.2 s, closed for 0.12 s.
    final blinkCycle = t % 3.2;
    blink = blinkCycle > 3.08 ? 1.0 : 0.0;

    switch (action) {
      case 'jump':
        bobY = -(math.sin(t * math.pi * 2.2).abs()) * 16;
        legSwing = 0.0;
        armLift = 0.55;
        excitement = 0.6;
        break;
      case 'celebrate':
        bobY = -(math.sin(t * math.pi * 3.2).abs()) * 12;
        legSwing = 0.0;
        armLift = 1.0;
        excitement = 1.0;
        break;
      case 'walk_in':
      case 'run_forward':
        bobY = math.sin(t * math.pi * 5).abs() * -5;
        legSwing = math.sin(t * math.pi * 5) * 0.6;
        armLift = 0.15;
        excitement = 0.25;
        break;
      default: // idle
        bobY = math.sin(t * 2 * math.pi / 2.6) * -3;
        legSwing = 0.0;
        armLift = 0.0;
        excitement = 0.0;
    }

    tailWag = math.sin(t * 2 * math.pi / (excitement > 0.5 ? 0.6 : 1.8)) *
        (0.25 + excitement * 0.35);
    sparklePhase = t;
  }

  late double breath;
  late double blink;
  late double bobY;
  late double legSwing;
  late double armLift; // 0..1
  late double excitement; // 0..1
  late double tailWag;
  late double sparklePhase;
}

// ── Rex the Dino ───────────────────────────────────────────────────

class _DinoPainter extends CustomPainter {
  _DinoPainter({required this.t, required this.action});
  final double t;
  final String action;

  static const _body = Color(0xFF58C25E);
  static const _bodyDark = Color(0xFF3E9C46);
  static const _belly = Color(0xFFBFE8A8);
  static const _spike = Color(0xFF2E7D32);
  static const _blush = Color(0x55FF6F91);

  @override
  void paint(Canvas canvas, Size size) {
    final pose = _Pose(t, action);
    final s = size.width / 200.0; // design space 200x220
    canvas.save();
    canvas.translate(0, pose.bobY * s);
    // Breathing squash & stretch around feet.
    canvas.translate(size.width / 2, size.height * 0.95);
    canvas.scale(1 + pose.breath, 1 - pose.breath);
    canvas.translate(-size.width / 2, -size.height * 0.95);
    canvas.scale(s);

    final fill = Paint()..style = PaintingStyle.fill;

    // Shadow on ground (independent of bob for depth illusion).
    fill.color = Colors.black.withValues(alpha: 0.12);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(100, 212 - pose.bobY),
            width: 120 + pose.bobY * 1.5,
            height: 16),
        fill);

    // Tail — curved, wagging.
    final tail = Path()..moveTo(58, 160);
    final wag = pose.tailWag * 22;
    tail.quadraticBezierTo(18 + wag, 150, 8 + wag * 1.6, 118 + wag * 0.4);
    tail.quadraticBezierTo(30 + wag, 152, 62, 176);
    tail.close();
    fill.color = _bodyDark;
    canvas.drawPath(tail, fill);

    // Back legs.
    fill.color = _bodyDark;
    _leg(canvas, fill, 78, 178, pose.legSwing);
    _leg(canvas, fill, 128, 178, -pose.legSwing);

    // Body.
    fill.color = _body;
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(100, 155), width: 96, height: 82),
        fill);

    // Front legs.
    fill.color = _body;
    _leg(canvas, fill, 90, 184, -pose.legSwing);
    _leg(canvas, fill, 116, 184, pose.legSwing);

    // Belly.
    fill.color = _belly;
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(104, 165), width: 58, height: 52),
        fill);

    // Neck + head.
    final neck = Path()
      ..moveTo(112, 132)
      ..quadraticBezierTo(128, 90, 132, 62)
      ..lineTo(158, 66)
      ..quadraticBezierTo(150, 104, 140, 138)
      ..close();
    fill.color = _body;
    canvas.drawPath(neck, fill);

    // Head tilt when excited.
    canvas.save();
    canvas.translate(148, 56);
    canvas.rotate(-pose.excitement * 0.12 +
        math.sin(pose.sparklePhase * 4) * pose.excitement * 0.06);
    canvas.translate(-148, -56);

    fill.color = _body;
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(150, 52), width: 62, height: 46),
        fill);
    // Snout.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(172, 60), width: 34, height: 24),
        fill);

    // Nostril.
    fill.color = _bodyDark;
    canvas.drawCircle(const Offset(180, 56), 2.2, fill);

    // Mouth — open smile when excited.
    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1B5E20);
    if (pose.excitement > 0.5) {
      fill.color = const Color(0xFF7A3B3B);
      canvas.drawArc(
          Rect.fromCenter(
              center: const Offset(168, 68), width: 26, height: 18),
          0.15,
          math.pi - 0.3,
          true,
          fill);
    } else {
      canvas.drawArc(
          Rect.fromCenter(
              center: const Offset(168, 64), width: 22, height: 12),
          0.3,
          math.pi - 0.9,
          false,
          mouth);
    }

    // Eye with blink.
    _eye(canvas, const Offset(148, 46), 9, pose.blink);

    // Blush.
    fill.color = _blush;
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(138, 60), width: 14, height: 8),
        fill);
    canvas.restore();

    // Back spikes along neck and body.
    fill.color = _spike;
    const spikes = [
      Offset(126, 74),
      Offset(118, 96),
      Offset(108, 116),
      Offset(88, 122),
      Offset(68, 132),
    ];
    for (var i = 0; i < spikes.length; i++) {
      final p = spikes[i];
      final wiggle = math.sin(pose.sparklePhase * 3 + i) * pose.excitement * 2;
      final path = Path()
        ..moveTo(p.dx - 8, p.dy + 6)
        ..lineTo(p.dx + wiggle, p.dy - 10)
        ..lineTo(p.dx + 8, p.dy + 6)
        ..close();
      canvas.drawPath(path, fill);
    }

    // Celebration sparkles orbiting the character.
    if (pose.excitement > 0.7) {
      _sparkles(canvas, pose.sparklePhase, const Offset(100, 110));
    }

    canvas.restore();
  }

  void _leg(Canvas canvas, Paint fill, double x, double y, double swing) {
    canvas.save();
    canvas.translate(x, y - 20);
    canvas.rotate(swing * 0.4);
    canvas.translate(-x, -(y - 20));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 20, height: 44),
          const Radius.circular(10)),
      fill,
    );
    canvas.restore();
  }

  void _eye(Canvas canvas, Offset c, double r, double blink) {
    final fill = Paint()..style = PaintingStyle.fill;
    if (blink >= 1.0) {
      final lid = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF1B5E20);
      canvas.drawLine(
          Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), lid);
      return;
    }
    fill.color = Colors.white;
    canvas.drawCircle(c, r, fill);
    fill.color = const Color(0xFF263238);
    canvas.drawCircle(Offset(c.dx + 2, c.dy + 1), r * 0.55, fill);
    fill.color = Colors.white;
    canvas.drawCircle(Offset(c.dx + 4, c.dy - 2), r * 0.2, fill);
  }

  void _sparkles(Canvas canvas, double t, Offset center) {
    final fill = Paint()..color = const Color(0xFFFFD54F);
    for (var i = 0; i < 6; i++) {
      final ang = t * 2.4 + i * math.pi / 3;
      final radius = 78 + math.sin(t * 3 + i) * 8;
      final p = Offset(center.dx + math.cos(ang) * radius,
          center.dy + math.sin(ang) * radius * 0.7);
      final sz = 4.5 + math.sin(t * 5 + i * 2) * 2;
      _star(canvas, fill, p, sz);
    }
  }

  static void _star(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final ang = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? r : r * 0.45;
      final p = Offset(c.dx + math.cos(ang) * radius,
          c.dy + math.sin(ang) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DinoPainter old) => old.t != t || old.action != action;
}

// ── Lily the Doll ──────────────────────────────────────────────────

class _DollPainter extends CustomPainter {
  _DollPainter({required this.t, required this.action});
  final double t;
  final String action;

  static const _skin = Color(0xFFFFE0C2);
  static const _hair = Color(0xFF7B4B2A);
  static const _dress = Color(0xFFF06292);
  static const _dressDark = Color(0xFFD84A7F);
  static const _bow = Color(0xFFFFD54F);
  static const _blush = Color(0x66FF6F91);

  @override
  void paint(Canvas canvas, Size size) {
    final pose = _Pose(t, action);
    final s = size.width / 200.0;
    canvas.save();
    canvas.translate(0, pose.bobY * s);
    canvas.translate(size.width / 2, size.height * 0.95);
    canvas.scale(1 + pose.breath, 1 - pose.breath);
    canvas.translate(-size.width / 2, -size.height * 0.95);
    canvas.scale(s);

    final fill = Paint()..style = PaintingStyle.fill;

    // Ground shadow.
    fill.color = Colors.black.withValues(alpha: 0.12);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(100, 212 - pose.bobY), width: 90, height: 14),
        fill);

    // Legs with little shoes.
    fill.color = _skin;
    _limb(canvas, fill, 88, 186, pose.legSwing, 14, 34);
    _limb(canvas, fill, 112, 186, -pose.legSwing, 14, 34);
    fill.color = _dressDark;
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(88, 205), width: 22, height: 12),
        fill);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(112, 205), width: 22, height: 12),
        fill);

    // Dress — trapezoid with scalloped hem, sways with tailWag.
    final sway = pose.tailWag * 4;
    final dress = Path()
      ..moveTo(86, 128)
      ..lineTo(114, 128)
      ..quadraticBezierTo(132 + sway, 168, 138 + sway, 186)
      ..lineTo(62 + sway, 186)
      ..quadraticBezierTo(70 + sway, 168, 86, 128)
      ..close();
    fill.color = _dress;
    canvas.drawPath(dress, fill);
    // Scallops.
    fill.color = _dressDark;
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
          Offset(68 + sway + i * 16.5, 186), 8, fill);
    }
    // Dress pocket heart.
    fill.color = Colors.white.withValues(alpha: 0.85);
    _heart(canvas, fill, Offset(100 + sway * 0.4, 160), 9);

    // Arms — lift when celebrating, gentle sway otherwise.
    final armAngle = -0.3 - pose.armLift * 1.6 +
        math.sin(pose.sparklePhase * 4) * pose.excitement * 0.15;
    fill.color = _skin;
    _arm(canvas, fill, const Offset(84, 132), armAngle);
    _arm(canvas, fill, const Offset(116, 132), math.pi - armAngle, flip: true);

    // Head.
    canvas.save();
    canvas.translate(100, 96);
    canvas.rotate(math.sin(pose.sparklePhase * 2) * 0.04 +
        pose.excitement * -0.06);
    canvas.translate(-100, -96);

    fill.color = _skin;
    canvas.drawCircle(const Offset(100, 92), 38, fill);

    // Hair cap + buns with bows.
    fill.color = _hair;
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(100, 90), radius: 39),
        math.pi, math.pi, true, fill);
    canvas.drawCircle(const Offset(64, 68), 15, fill);
    canvas.drawCircle(const Offset(136, 68), 15, fill);
    fill.color = _bow;
    _bowShape(canvas, fill, const Offset(64, 58));
    _bowShape(canvas, fill, const Offset(136, 58));

    // Eyes.
    _dollEye(canvas, const Offset(86, 92), pose.blink);
    _dollEye(canvas, const Offset(114, 92), pose.blink);

    // Blush.
    fill.color = _blush;
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(76, 104), width: 13, height: 7),
        fill);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(124, 104), width: 13, height: 7),
        fill);

    // Smile — open when excited.
    if (pose.excitement > 0.5) {
      fill.color = const Color(0xFFB94A5E);
      canvas.drawArc(
          Rect.fromCenter(
              center: const Offset(100, 108), width: 20, height: 14),
          0.1, math.pi - 0.2, true, fill);
    } else {
      final smile = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB94A5E);
      canvas.drawArc(
          Rect.fromCenter(
              center: const Offset(100, 105), width: 20, height: 12),
          0.3, math.pi - 0.6, false, smile);
    }
    canvas.restore();

    // Celebration sparkles.
    if (pose.excitement > 0.7) {
      final sp = Paint()..color = const Color(0xFFF48FB1);
      for (var i = 0; i < 6; i++) {
        final ang = pose.sparklePhase * 2.4 + i * math.pi / 3;
        final radius = 74 + math.sin(pose.sparklePhase * 3 + i) * 8;
        final p = Offset(100 + math.cos(ang) * radius,
            120 + math.sin(ang) * radius * 0.7);
        _heart(canvas, sp, p, 5 + math.sin(pose.sparklePhase * 5 + i) * 1.5);
      }
    }

    canvas.restore();
  }

  void _limb(Canvas canvas, Paint fill, double x, double y, double swing,
      double w, double h) {
    canvas.save();
    canvas.translate(x, y - h / 2);
    canvas.rotate(swing * 0.35);
    canvas.translate(-x, -(y - h / 2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h),
          Radius.circular(w / 2)),
      fill,
    );
    canvas.restore();
  }

  void _arm(Canvas canvas, Paint fill, Offset shoulder, double angle,
      {bool flip = false}) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(flip ? -angle + math.pi : angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, 0, 12, 34), const Radius.circular(6)),
      fill,
    );
    // Hand.
    canvas.drawCircle(const Offset(0, 36), 7, fill);
    canvas.restore();
  }

  void _dollEye(Canvas canvas, Offset c, double blink) {
    final fill = Paint()..style = PaintingStyle.fill;
    if (blink >= 1.0) {
      final lid = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF5D4037);
      canvas.drawLine(Offset(c.dx - 7, c.dy), Offset(c.dx + 7, c.dy), lid);
      return;
    }
    fill.color = Colors.white;
    canvas.drawOval(
        Rect.fromCenter(center: c, width: 16, height: 18), fill);
    fill.color = const Color(0xFF4E342E);
    canvas.drawCircle(Offset(c.dx + 1, c.dy + 1.5), 5.5, fill);
    fill.color = Colors.white;
    canvas.drawCircle(Offset(c.dx + 3, c.dy - 1.5), 2, fill);
    // Lashes.
    final lash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5D4037);
    canvas.drawLine(
        Offset(c.dx - 8, c.dy - 8), Offset(c.dx - 11, c.dy - 11), lash);
    canvas.drawLine(
        Offset(c.dx + 8, c.dy - 8), Offset(c.dx + 11, c.dy - 11), lash);
  }

  void _bowShape(Canvas canvas, Paint fill, Offset c) {
    final path = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx - 10, c.dy - 6)
      ..lineTo(c.dx - 10, c.dy + 6)
      ..close()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx + 10, c.dy - 6)
      ..lineTo(c.dx + 10, c.dy + 6)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawCircle(c, 3.2, fill);
  }

  static void _heart(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r)
      ..cubicTo(c.dx - r * 1.6, c.dy - r * 0.4, c.dx - r * 0.7, c.dy - r * 1.4,
          c.dx, c.dy - r * 0.4)
      ..cubicTo(c.dx + r * 0.7, c.dy - r * 1.4, c.dx + r * 1.6, c.dy - r * 0.4,
          c.dx, c.dy + r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DollPainter old) => old.t != t || old.action != action;
}
