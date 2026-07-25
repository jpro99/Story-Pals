import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated, layered scene backgrounds: drifting clouds, swaying trees,
/// shimmering rivers, twinkling fireflies — all vector, no assets.
///
/// Scenes: jungle, jungle_river, jungle_clearing, jungle_feast,
/// bedroom, tea_table, tea_party, puzzle_green, puzzle_pink, map.
class LivingBackground extends StatefulWidget {
  const LivingBackground({super.key, required this.scene, this.dim = 0.0});

  final String scene;

  /// 0..1 — darkens the scene slightly so foreground UI pops.
  final double dim;

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
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
      builder: (context, _) => CustomPaint(
        painter: _ScenePainter(
          t: _ctrl.value * 120.0,
          scene: widget.scene,
          dim: widget.dim,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SceneSpec {
  const _SceneSpec({
    required this.sky,
    this.hills = const [],
    this.ground,
    this.groundDark,
    this.night = false,
    this.trees = false,
    this.river = false,
    this.fireflies = false,
    this.butterflies = false,
    this.flowers = false,
    this.indoor = false,
    this.teaParty = false,
    this.bubbles = false,
    this.sunColor = const Color(0xFFFFE082),
  });

  final List<Color> sky;
  final List<Color> hills;
  final Color? ground;
  final Color? groundDark;
  final bool night;
  final bool trees;
  final bool river;
  final bool fireflies;
  final bool butterflies;
  final bool flowers;
  final bool indoor;
  final bool teaParty;
  final bool bubbles;
  final Color sunColor;
}

const _specs = <String, _SceneSpec>{
  'jungle': _SceneSpec(
    sky: [Color(0xFF9BE7FF), Color(0xFFDFF9E4)],
    hills: [Color(0xFF66BB6A), Color(0xFF43A047)],
    ground: Color(0xFF7CC47F),
    groundDark: Color(0xFF5BA55F),
    trees: true,
    butterflies: true,
    flowers: true,
  ),
  'jungle_river': _SceneSpec(
    sky: [Color(0xFF8FD8FF), Color(0xFFD2F4E0)],
    hills: [Color(0xFF66BB6A), Color(0xFF388E3C)],
    ground: Color(0xFF7CC47F),
    groundDark: Color(0xFF5BA55F),
    trees: true,
    river: true,
    butterflies: true,
  ),
  'jungle_clearing': _SceneSpec(
    sky: [Color(0xFFFFE9A8), Color(0xFFD9F2C4)],
    hills: [Color(0xFF81C784), Color(0xFF519657)],
    ground: Color(0xFF8FD08F),
    groundDark: Color(0xFF6DB271),
    trees: true,
    fireflies: true,
    flowers: true,
    sunColor: Color(0xFFFFCC66),
  ),
  'jungle_feast': _SceneSpec(
    sky: [Color(0xFFFFC98A), Color(0xFFFFE8C2)],
    hills: [Color(0xFF6B9E5E), Color(0xFF49773F)],
    ground: Color(0xFF7DB56E),
    groundDark: Color(0xFF5F9455),
    trees: true,
    fireflies: true,
    sunColor: Color(0xFFFFAB5C),
  ),
  'bedroom': _SceneSpec(
    sky: [Color(0xFF4A3B8C), Color(0xFF8B6BC7)],
    ground: Color(0xFFB49DDF),
    groundDark: Color(0xFF9C85CC),
    night: true,
    indoor: true,
  ),
  'tea_table': _SceneSpec(
    sky: [Color(0xFFFFC1D9), Color(0xFFFFE7F0)],
    ground: Color(0xFFF7A8C4),
    groundDark: Color(0xFFE890B2),
    indoor: true,
    teaParty: true,
  ),
  'tea_party': _SceneSpec(
    sky: [Color(0xFFE1BEE7), Color(0xFFFFD6E8)],
    ground: Color(0xFFD8A8E0),
    groundDark: Color(0xFFC493CF),
    indoor: true,
    teaParty: true,
  ),
  'puzzle_green': _SceneSpec(
    sky: [Color(0xFFE9FBEA), Color(0xFFD3F2DE)],
    bubbles: true,
  ),
  'puzzle_pink': _SceneSpec(
    sky: [Color(0xFFFFF0F6), Color(0xFFFDDCEB)],
    bubbles: true,
  ),
  'map': _SceneSpec(
    sky: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
    hills: [Color(0xFFA5D6A7), Color(0xFF81C784)],
    ground: Color(0xFFC5E8C7),
    groundDark: Color(0xFFA9D6AC),
    flowers: true,
  ),
};

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.t, required this.scene, required this.dim});
  final double t;
  final String scene;
  final double dim;

  _SceneSpec get spec => _specs[scene] ?? _specs['jungle']!;

  @override
  void paint(Canvas canvas, Size size) {
    final sp = spec;
    final w = size.width;
    final h = size.height;
    final fill = Paint()..style = PaintingStyle.fill;

    // Sky.
    fill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: sp.sky,
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, fill);
    fill.shader = null;

    if (sp.night) {
      _stars(canvas, w, h);
      _moon(canvas, Offset(w * 0.8, h * 0.14), 26);
    } else if (!sp.indoor && !sp.bubbles) {
      _sun(canvas, Offset(w * 0.82, h * 0.12), 30, sp.sunColor);
    }

    // Clouds (outdoor day scenes) — drift and wrap.
    if (!sp.indoor && !sp.night) {
      _cloud(canvas, _wrapX(w * 0.2 + t * 9, w, 140), h * 0.10, 1.0);
      _cloud(canvas, _wrapX(w * 0.6 + t * 6, w, 180), h * 0.18, 1.35);
      _cloud(canvas, _wrapX(w * 0.9 + t * 12, w, 110), h * 0.06, 0.75);
    }

    // Distant hills.
    if (sp.hills.isNotEmpty) {
      fill.color = sp.hills[0].withValues(alpha: 0.55);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(w * 0.25, h * 0.68), width: w * 1.1, height: h * 0.32),
          fill);
      if (sp.hills.length > 1) {
        fill.color = sp.hills[1].withValues(alpha: 0.5);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(w * 0.85, h * 0.7), width: w * 0.9, height: h * 0.3),
            fill);
      }
    }

    // Ground.
    if (sp.ground != null) {
      fill.color = sp.ground!;
      final ground = Path()
        ..moveTo(0, h * 0.72)
        ..quadraticBezierTo(w * 0.5, h * 0.66, w, h * 0.72)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(ground, fill);
      // Ground shading band.
      fill.color = (sp.groundDark ?? sp.ground!).withValues(alpha: 0.6);
      final band = Path()
        ..moveTo(0, h * 0.88)
        ..quadraticBezierTo(w * 0.5, h * 0.84, w, h * 0.88)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(band, fill);
    }

    if (sp.river) _river(canvas, w, h);
    if (sp.trees) {
      _tree(canvas, w * 0.1, h * 0.7, 1.1, 0.0);
      _tree(canvas, w * 0.88, h * 0.68, 1.35, 1.7);
      _tree(canvas, w * 0.72, h * 0.72, 0.8, 3.1);
    }
    if (sp.flowers && sp.ground != null) _flowers(canvas, w, h);
    if (sp.indoor && !sp.night) _bunting(canvas, w, h);
    if (sp.teaParty) _teaTable(canvas, w, h);
    if (sp.night) _bedroomWindowGlow(canvas, w, h);
    if (sp.fireflies) _fireflies(canvas, w, h);
    if (sp.butterflies) _butterfly(canvas, w, h);
    if (sp.bubbles) _floatingBubbles(canvas, w, h);
    if (sp.teaParty) _floatingHearts(canvas, w, h);

    if (dim > 0) {
      fill.color = Colors.black.withValues(alpha: dim);
      canvas.drawRect(Offset.zero & size, fill);
    }
  }

  double _wrapX(double x, double w, double margin) =>
      ((x + margin) % (w + margin * 2)) - margin;

  void _sun(Canvas canvas, Offset c, double r, Color color) {
    final pulse = 1 + math.sin(t * 2 * math.pi / 4) * 0.06;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(c, r * 1.7 * pulse, glow);
    canvas.drawCircle(c, r * pulse, Paint()..color = color);
    // Rotating rays.
    final ray = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final ang = t * 0.25 + i * math.pi / 4;
      canvas.drawLine(
        c + Offset(math.cos(ang), math.sin(ang)) * (r * 1.35),
        c + Offset(math.cos(ang), math.sin(ang)) * (r * 1.65 * pulse),
        ray,
      );
    }
  }

  void _moon(Canvas canvas, Offset c, double r) {
    final glow = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(c, r * 1.6, glow);
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFF59D));
    canvas.drawCircle(Offset(c.dx - r * 0.35, c.dy - r * 0.15), r * 0.82,
        Paint()..color = const Color(0xFF5D4E9E).withValues(alpha: 0.35));
  }

  void _stars(Canvas canvas, double w, double h) {
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h * 0.5;
      final phase = rnd.nextDouble() * math.pi * 2;
      final tw = 0.35 + (math.sin(t * 2 + phase) + 1) / 2 * 0.65;
      canvas.drawCircle(
          Offset(x, y),
          1.2 + rnd.nextDouble() * 1.4,
          Paint()..color = Colors.white.withValues(alpha: tw));
    }
  }

  void _cloud(Canvas canvas, double x, double y, double scale) {
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.85);
    void puff(double dx, double dy, double r) =>
        canvas.drawCircle(Offset(x + dx * scale, y + dy * scale), r * scale, fill);
    puff(0, 0, 22);
    puff(24, -8, 18);
    puff(48, 0, 20);
    puff(24, 8, 22);
  }

  void _tree(Canvas canvas, double x, double baseY, double scale, double phase) {
    final sway = math.sin(t * 2 * math.pi / 5 + phase) * 4 * scale;
    final trunk = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, baseY - 28 * scale),
              width: 14 * scale,
              height: 70 * scale),
          const Radius.circular(7)),
      trunk,
    );
    final canopy = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(
        Offset(x + sway, baseY - 78 * scale), 34 * scale, canopy);
    canopy.color = const Color(0xFF4CAF50);
    canvas.drawCircle(
        Offset(x - 22 * scale + sway * 0.7, baseY - 62 * scale), 26 * scale, canopy);
    canvas.drawCircle(
        Offset(x + 24 * scale + sway * 0.7, baseY - 60 * scale), 24 * scale, canopy);
    canopy.color = const Color(0xFF66BB6A);
    canvas.drawCircle(
        Offset(x + sway * 1.2, baseY - 58 * scale), 22 * scale, canopy);
  }

  void _river(Canvas canvas, double w, double h) {
    final water = Paint()..color = const Color(0xFF64B5F6);
    final path = Path()
      ..moveTo(0, h * 0.8)
      ..quadraticBezierTo(w * 0.3, h * 0.76, w * 0.55, h * 0.82)
      ..quadraticBezierTo(w * 0.8, h * 0.88, w, h * 0.84)
      ..lineTo(w, h * 0.96)
      ..quadraticBezierTo(w * 0.6, h * 1.0, w * 0.3, h * 0.95)
      ..quadraticBezierTo(w * 0.1, h * 0.92, 0, h * 0.94)
      ..close();
    canvas.drawPath(path, water);
    // Shimmer waves.
    final shimmer = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final x = _wrapX(w * 0.15 * i + t * 20 + i * 30, w, 40);
      final y = h * (0.84 + 0.025 * (i % 3));
      final wob = math.sin(t * 3 + i) * 2;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y + wob), width: 26, height: 8),
          math.pi * 0.15, math.pi * 0.7, false, shimmer);
    }
  }

  void _flowers(Canvas canvas, double w, double h) {
    final rnd = math.Random(12);
    for (var i = 0; i < 9; i++) {
      final x = rnd.nextDouble() * w;
      final y = h * (0.78 + rnd.nextDouble() * 0.16);
      final phase = rnd.nextDouble() * math.pi * 2;
      final sway = math.sin(t * 2 + phase) * 2;
      final colors = [
        const Color(0xFFF48FB1),
        const Color(0xFFFFF176),
        const Color(0xFFCE93D8),
        const Color(0xFFFF8A65),
      ];
      final petal = Paint()..color = colors[i % colors.length];
      for (var p = 0; p < 5; p++) {
        final ang = p * math.pi * 2 / 5 + sway * 0.05;
        canvas.drawCircle(
            Offset(x + sway + math.cos(ang) * 5, y + math.sin(ang) * 5),
            3.4, petal);
      }
      canvas.drawCircle(
          Offset(x + sway, y), 3, Paint()..color = const Color(0xFFFFD54F));
    }
  }

  void _bunting(Canvas canvas, double w, double h) {
    final rope = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final sag = math.sin(t * 1.5) * 3;
    final path = Path()
      ..moveTo(0, h * 0.06)
      ..quadraticBezierTo(w * 0.5, h * 0.14 + sag, w, h * 0.06);
    canvas.drawPath(path, rope);
    final colors = [
      const Color(0xFFF06292),
      const Color(0xFFFFD54F),
      const Color(0xFF4FC3F7),
      const Color(0xFFAED581),
    ];
    for (var i = 0; i < 8; i++) {
      final ft = (i + 0.5) / 8;
      final x = ft * w;
      final y = _quad(h * 0.06, h * 0.14 + sag, h * 0.06, ft);
      final flagSway = math.sin(t * 2.2 + i) * 2;
      final flag = Path()
        ..moveTo(x - 9, y)
        ..lineTo(x + 9, y)
        ..lineTo(x + flagSway, y + 16)
        ..close();
      canvas.drawPath(flag, Paint()..color = colors[i % colors.length]);
    }
  }

  double _quad(double a, double b, double c, double f) =>
      (1 - f) * (1 - f) * a + 2 * (1 - f) * f * b + f * f * c;

  void _teaTable(Canvas canvas, double w, double h) {
    // Table.
    final table = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.8), width: w * 0.62, height: 44),
        table);
    final cloth = Paint()..color = const Color(0xFFF8BBD0);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.86), width: w * 0.58, height: h * 0.1),
        cloth);
    // Teapot silhouette with steam.
    final pot = Paint()..color = const Color(0xFF8E5B9E);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.77), width: 46, height: 34),
        pot);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(w * 0.5, h * 0.755), width: 14, height: 10),
            const Radius.circular(4)),
        pot);
    // Spout.
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.5 + 28, h * 0.765), width: 22, height: 18),
        -math.pi / 2, math.pi * 0.8, false,
        Paint()
          ..color = const Color(0xFF8E5B9E)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    // Steam curls.
    final steam = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 2; i++) {
      final phase = t * 1.4 + i * 1.6;
      final rise = (phase % 3) / 3; // 0..1
      final sx = w * 0.5 + 26 + i * 8;
      final sy = h * 0.74 - rise * 42;
      final steamPath = Path()
        ..moveTo(sx, sy + 14)
        ..quadraticBezierTo(sx + math.sin(phase * 2) * 6, sy + 7, sx, sy);
      steam.color = Colors.white.withValues(alpha: 0.55 * (1 - rise));
      canvas.drawPath(steamPath, steam);
    }
    // Cups.
    final cup = Paint()..color = const Color(0xFFF06292);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(w * 0.32, h * 0.785), width: 22, height: 16),
            const Radius.circular(5)),
        cup);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(w * 0.68, h * 0.785), width: 22, height: 16),
            const Radius.circular(5)),
        cup);
  }

  void _bedroomWindowGlow(Canvas canvas, double w, double h) {
    // Window frame with moonlight.
    final frame = Paint()..color = const Color(0xFF3A2E75);
    final glass = Paint()..color = const Color(0xFF9FA8DA).withValues(alpha: 0.4);
    final r = Rect.fromCenter(
        center: Offset(w * 0.22, h * 0.3), width: w * 0.26, height: h * 0.26);
    canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(10)), frame);
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(6)), glass);
    final bar = Paint()
      ..color = const Color(0xFF3A2E75)
      ..strokeWidth = 4;
    canvas.drawLine(r.topCenter, r.bottomCenter, bar);
    canvas.drawLine(r.centerLeft, r.centerRight, bar);
    // Rug.
    final rug = Paint()..color = const Color(0xFFCE93D8).withValues(alpha: 0.6);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.88), width: w * 0.6, height: 50),
        rug);
    // Floating dream sparkles.
    for (var i = 0; i < 8; i++) {
      final phase = t * 0.8 + i * 1.3;
      final rise = (phase % 5) / 5;
      final x = w * (0.15 + (i * 0.11) % 0.75) + math.sin(phase) * 12;
      final y = h * 0.75 - rise * h * 0.5;
      canvas.drawCircle(
          Offset(x, y),
          1.8 + math.sin(phase * 3) * 0.8,
          Paint()
            ..color = const Color(0xFFFFF59D)
                .withValues(alpha: (1 - rise) * 0.7));
    }
  }

  void _fireflies(Canvas canvas, double w, double h) {
    for (var i = 0; i < 10; i++) {
      final phase = i * 0.97;
      final x = w * (0.1 + 0.8 * ((math.sin(t * 0.35 + phase * 3) + 1) / 2));
      final y = h * (0.45 + 0.35 * ((math.cos(t * 0.28 + phase * 2) + 1) / 2));
      final glow = (math.sin(t * 3 + phase * 5) + 1) / 2;
      final paint = Paint()
        ..color = const Color(0xFFFFF176).withValues(alpha: 0.25 + glow * 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), 2.6 + glow * 2, paint);
    }
  }

  void _butterfly(Canvas canvas, double w, double h) {
    final x = _wrapX(t * 26, w, 60);
    final y = h * 0.32 + math.sin(t * 1.7) * h * 0.08;
    final flap = math.sin(t * 14).abs();
    final wing = Paint()..color = const Color(0xFFFF8A65);
    canvas.save();
    canvas.translate(x, y);
    // Left wing.
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(-7, 0), width: 14 * (0.4 + flap * 0.6), height: 12),
        wing);
    // Right wing.
    wing.color = const Color(0xFFFFAB91);
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(7, 0), width: 14 * (0.4 + flap * 0.6), height: 12),
        wing);
    // Body.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 4, height: 14),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFF5D4037));
    canvas.restore();
  }

  void _floatingBubbles(Canvas canvas, double w, double h) {
    final rnd = math.Random(21);
    for (var i = 0; i < 12; i++) {
      final baseX = rnd.nextDouble() * w;
      final speed = 8 + rnd.nextDouble() * 10;
      final phase = rnd.nextDouble() * 40;
      final size = 10 + rnd.nextDouble() * 26;
      final rise = ((t * speed + phase * 30) % (h + 120)) - 60;
      final x = baseX + math.sin(t * 0.8 + phase) * 16;
      final y = h - rise;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), size, paint);
      canvas.drawCircle(
          Offset(x - size * 0.3, y - size * 0.3),
          size * 0.22,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
  }

  void _floatingHearts(Canvas canvas, double w, double h) {
    for (var i = 0; i < 6; i++) {
      final phase = i * 1.7;
      final rise = ((t * 12 + phase * 40) % (h * 0.7)) / (h * 0.7);
      final x = w * (0.12 + (i * 0.16) % 0.8) + math.sin(t + phase) * 14;
      final y = h * 0.7 - rise * h * 0.55;
      final paint = Paint()
        ..color = const Color(0xFFF06292).withValues(alpha: (1 - rise) * 0.5);
      _heart(canvas, paint, Offset(x, y), 6 + math.sin(t * 2 + phase) * 1.5);
    }
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
  bool shouldRepaint(_ScenePainter old) =>
      old.t != t || old.scene != scene || old.dim != dim;
}
