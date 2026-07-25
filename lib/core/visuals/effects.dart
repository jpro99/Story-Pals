import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/sound_service.dart';

/// Reusable particle effects:
///  * [TapSparkles] — wrap any screen; every touch spawns a sparkle burst.
///  * [StarBurst.show] — radial star pop at a screen position (correct answers).
///  * [ConfettiRain] — full-screen celebration confetti.

// ── Particle model ─────────────────────────────────────────────────

class _Particle {
  _Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
    required this.life,
    this.gravity = 0,
    this.spin = 0,
    this.shape = 0, // 0 circle, 1 star, 2 rect, 3 heart
  });

  Offset pos;
  Offset vel;
  final Color color;
  final double size;
  final double life; // seconds
  final double gravity;
  final double spin;
  final int shape;
  double age = 0;
  double rotation = 0;

  bool get dead => age >= life;

  void update(double dt) {
    age += dt;
    pos += vel * dt;
    vel = Offset(vel.dx, vel.dy + gravity * dt);
    rotation += spin * dt;
  }

  double get opacity => (1 - age / life).clamp(0.0, 1.0);
}

void _paintParticles(Canvas canvas, List<_Particle> particles) {
  for (final p in particles) {
    final paint = Paint()
      ..color = p.color.withValues(alpha: p.color.a * p.opacity);
    canvas.save();
    canvas.translate(p.pos.dx, p.pos.dy);
    canvas.rotate(p.rotation);
    switch (p.shape) {
      case 1:
        _star(canvas, paint, p.size);
        break;
      case 2:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero, width: p.size * 1.6, height: p.size),
                Radius.circular(p.size * 0.25)),
            paint);
        break;
      case 3:
        _heart(canvas, paint, p.size);
        break;
      default:
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
    }
    canvas.restore();
  }
}

void _star(Canvas canvas, Paint paint, double r) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final ang = -math.pi / 2 + i * math.pi / 5;
    final radius = i.isEven ? r : r * 0.45;
    final p = Offset(math.cos(ang) * radius, math.sin(ang) * radius);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  path.close();
  canvas.drawPath(path, paint);
}

void _heart(Canvas canvas, Paint paint, double r) {
  final path = Path()
    ..moveTo(0, r)
    ..cubicTo(-r * 1.6, -r * 0.4, -r * 0.7, -r * 1.4, 0, -r * 0.4)
    ..cubicTo(r * 0.7, -r * 1.4, r * 1.6, -r * 0.4, 0, r)
    ..close();
  canvas.drawPath(path, paint);
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles, this.repaintCounter);
  final List<_Particle> particles;
  final int repaintCounter;

  @override
  void paint(Canvas canvas, Size size) => _paintParticles(canvas, particles);

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── TapSparkles ────────────────────────────────────────────────────

/// Wrap a screen's body: every pointer-down spawns a small sparkle burst
/// under the finger. Purely decorative — never intercepts touches.
class TapSparkles extends StatefulWidget {
  const TapSparkles({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  State<TapSparkles> createState() => _TapSparklesState();
}

class _TapSparklesState extends State<TapSparkles>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = [];
  Ticker? _ticker;
  Duration _last = Duration.zero;
  int _frame = 0;

  static const _palette = [
    Color(0xFFFFD54F),
    Color(0xFF4FC3F7),
    Color(0xFFF06292),
    Color(0xFFAED581),
    Color(0xFFCE93D8),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    for (final p in _particles) {
      p.update(dt.clamp(0.0, 0.05));
    }
    _particles.removeWhere((p) => p.dead);
    if (_particles.isEmpty) {
      _ticker?.stop();
      _last = Duration.zero;
    }
    setState(() => _frame++);
  }

  void _spawn(Offset pos) {
    SoundFx.play('tap', volume: 0.3);
    final rnd = math.Random();
    for (var i = 0; i < 10; i++) {
      final ang = rnd.nextDouble() * math.pi * 2;
      final speed = 60 + rnd.nextDouble() * 130;
      _particles.add(_Particle(
        pos: pos,
        vel: Offset(math.cos(ang), math.sin(ang)) * speed,
        color: widget.color ?? _palette[rnd.nextInt(_palette.length)],
        size: 4 + rnd.nextDouble() * 6,
        life: 0.5 + rnd.nextDouble() * 0.4,
        gravity: 220,
        spin: (rnd.nextDouble() - 0.5) * 10,
        shape: rnd.nextInt(3) == 0 ? 1 : 0,
      ));
    }
    if (!(_ticker?.isActive ?? true)) {
      _last = Duration.zero;
      _ticker?.start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _spawn(e.localPosition),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          IgnorePointer(
            child: CustomPaint(
              painter: _ParticlePainter(_particles, _frame),
            ),
          ),
        ],
      ),
    );
  }
}

// ── StarBurst overlay ──────────────────────────────────────────────

/// One-shot radial star burst — call on a correct answer:
/// `StarBurst.show(context, globalPosition)`.
class StarBurst {
  static void show(BuildContext context, Offset globalPosition,
      {Color color = const Color(0xFFFFD54F)}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _StarBurstWidget(
        position: globalPosition,
        color: color,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _StarBurstWidget extends StatefulWidget {
  const _StarBurstWidget({
    required this.position,
    required this.color,
    required this.onDone,
  });
  final Offset position;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_StarBurstWidget> createState() => _StarBurstWidgetState();
}

class _StarBurstWidgetState extends State<_StarBurstWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    for (var i = 0; i < 14; i++) {
      final ang = i * math.pi * 2 / 14 + rnd.nextDouble() * 0.3;
      final speed = 120 + rnd.nextDouble() * 160;
      _particles.add(_Particle(
        pos: widget.position,
        vel: Offset(math.cos(ang), math.sin(ang)) * speed,
        color: i.isEven ? widget.color : Colors.white,
        size: 6 + rnd.nextDouble() * 7,
        life: 0.8,
        gravity: 300,
        spin: (rnd.nextDouble() - 0.5) * 12,
        shape: 1,
      ));
    }
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..addListener(_step)
      ..forward().whenCompleteOrCancel(widget.onDone);
  }

  double _lastT = 0;
  void _step() {
    final t = _ctrl.value * 0.85;
    final dt = t - _lastT;
    _lastT = t;
    for (final p in _particles) {
      p.update(dt);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ParticlePainter(_particles, _ctrl.value.hashCode),
      ),
    );
  }
}

// ── ConfettiRain ───────────────────────────────────────────────────

/// Full-screen falling confetti. Place in a Stack when celebrating;
/// starts automatically and runs while mounted.
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({super.key, this.pieces = 90, this.hearts = false});
  final int pieces;
  final bool hearts;

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Particle> _particles = [];
  Duration _last = Duration.zero;
  bool _seeded = false;
  Size _size = Size.zero;
  int _frame = 0;

  static const _palette = [
    Color(0xFFFFD54F),
    Color(0xFF4FC3F7),
    Color(0xFFF06292),
    Color(0xFFAED581),
    Color(0xFFCE93D8),
    Color(0xFFFF8A65),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _seed(Size size) {
    final rnd = math.Random();
    for (var i = 0; i < widget.pieces; i++) {
      _particles.add(_Particle(
        pos: Offset(
            rnd.nextDouble() * size.width, -rnd.nextDouble() * size.height),
        vel: Offset((rnd.nextDouble() - 0.5) * 60, 120 + rnd.nextDouble() * 160),
        color: _palette[rnd.nextInt(_palette.length)],
        size: 7 + rnd.nextDouble() * 7,
        life: double.infinity,
        spin: (rnd.nextDouble() - 0.5) * 8,
        shape: widget.hearts
            ? (rnd.nextInt(3) == 0 ? 3 : 2)
            : (rnd.nextInt(4) == 0 ? 1 : 2),
      ));
    }
    _seeded = true;
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (_seeded && _size != Size.zero) {
      for (final p in _particles) {
        p.update(dt);
        // Gentle horizontal wobble.
        p.pos += Offset(math.sin(p.rotation * 2) * 20 * dt, 0);
        if (p.pos.dy > _size.height + 20) {
          p.pos = Offset(math.Random().nextDouble() * _size.width, -20);
        }
      }
    }
    setState(() => _frame++);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        if (!_seeded && _size.width > 0) _seed(_size);
        return CustomPaint(
          size: _size,
          painter: _ParticlePainter(_particles, _frame),
        );
      }),
    );
  }
}

// ── Wiggle ─────────────────────────────────────────────────────────

/// Gentle attention-grabbing wiggle for buttons/cards kids should notice.
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value * 3;
        // Wiggle for the first 0.5 s of every 3 s cycle.
        final phase = t < 0.5 ? math.sin(t * math.pi * 8) * 0.04 : 0.0;
        return Transform.rotate(angle: phase, child: child);
      },
      child: widget.child,
    );
  }
}
