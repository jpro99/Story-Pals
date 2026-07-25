import 'package:flutter/material.dart';

/// Hand-drawn vector dinosaur species — real shapes for real dino experts.
/// Rendered via [ItemGraphic] wherever puzzles show items.
///
/// Species tokens: '@dino:trex', '@dino:stegosaurus', '@dino:triceratops',
/// '@dino:brachiosaurus', '@dino:pterodactyl', '@dino:ankylosaurus'.

/// Renders either a plain emoji/text item or, for '@dino:...' tokens,
/// the matching vector dinosaur. Drop-in replacement for Text(emoji).
class ItemGraphic extends StatelessWidget {
  const ItemGraphic({super.key, required this.token, required this.size});

  /// Emoji string, letter, or an '@dino:species' art token.
  final String token;

  /// Roughly equivalent to the font size the emoji would have used.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (token.startsWith('@dino:')) {
      final species = token.substring(6);
      return CustomPaint(
        size: Size(size * 1.5, size * 1.1),
        painter: DinoPainter(species),
      );
    }
    return Text(token, style: TextStyle(fontSize: size));
  }
}

class DinoPainter extends CustomPainter {
  const DinoPainter(this.species);
  final String species;

  @override
  void paint(Canvas canvas, Size size) {
    // Normalized 150x110 design space.
    canvas.save();
    canvas.scale(size.width / 150, size.height / 110);
    switch (species) {
      case 'stegosaurus':
        _stegosaurus(canvas);
        break;
      case 'triceratops':
        _triceratops(canvas);
        break;
      case 'brachiosaurus':
        _brachiosaurus(canvas);
        break;
      case 'pterodactyl':
        _pterodactyl(canvas);
        break;
      case 'ankylosaurus':
        _ankylosaurus(canvas);
        break;
      default:
        _trex(canvas);
    }
    canvas.restore();
  }

  Paint _fill(Color c) => Paint()
    ..style = PaintingStyle.fill
    ..color = c;

  void _eye(Canvas canvas, Offset c) {
    canvas.drawCircle(c, 4, _fill(Colors.white));
    canvas.drawCircle(Offset(c.dx + 1, c.dy), 2.2, _fill(const Color(0xFF263238)));
  }

  void _legs(Canvas canvas, Color color, List<Offset> tops, double h,
      [double w = 12]) {
    for (final t in tops) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(t.dx, t.dy, w, h), Radius.circular(w / 2)),
        _fill(color),
      );
    }
  }

  // T-Rex: huge head, mighty jaw, famously tiny arms.
  void _trex(Canvas canvas) {
    const body = Color(0xFF66BB6A);
    const dark = Color(0xFF43A047);
    _legs(canvas, dark, const [Offset(52, 78), Offset(78, 78)], 28, 14);
    // Tail
    final tail = Path()
      ..moveTo(50, 62)
      ..quadraticBezierTo(14, 58, 4, 44)
      ..quadraticBezierTo(26, 66, 54, 76)
      ..close();
    canvas.drawPath(tail, _fill(dark));
    // Body (leaning forward)
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(72, 60), width: 56, height: 44),
        _fill(body));
    // Head — big!
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(108, 32), width: 52, height: 36),
        _fill(body));
    // Jaw
    final jaw = Path()
      ..moveTo(96, 42)
      ..lineTo(132, 44)
      ..lineTo(126, 54)
      ..quadraticBezierTo(106, 54, 96, 46)
      ..close();
    canvas.drawPath(jaw, _fill(dark));
    // Teeth
    for (var i = 0; i < 4; i++) {
      final x = 104.0 + i * 7;
      canvas.drawPath(
          Path()
            ..moveTo(x, 44)
            ..lineTo(x + 3, 49)
            ..lineTo(x + 6, 44)
            ..close(),
          _fill(Colors.white));
    }
    // Tiny arm
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(86, 58, 12, 6), const Radius.circular(3)),
        _fill(dark));
    _eye(canvas, const Offset(108, 26));
  }

  // Stegosaurus: arched back with a row of triangular plates + tail spikes.
  void _stegosaurus(Canvas canvas) {
    const body = Color(0xFFFF8A50);
    const plate = Color(0xFFD84315);
    // Plates along the arch
    const plateXs = [38.0, 58.0, 78.0, 98.0];
    for (var i = 0; i < plateXs.length; i++) {
      final x = plateXs[i];
      final ph = i == 1 || i == 2 ? 26.0 : 18.0;
      final baseY = 52 - (i == 1 || i == 2 ? 6 : 0);
      canvas.drawPath(
          Path()
            ..moveTo(x - 10, baseY.toDouble())
            ..lineTo(x, baseY - ph)
            ..lineTo(x + 10, baseY.toDouble())
            ..close(),
          _fill(plate));
    }
    _legs(canvas, body, const [Offset(44, 78), Offset(88, 78)], 26);
    // Arched body
    final bodyPath = Path()
      ..moveTo(16, 74)
      ..quadraticBezierTo(70, 26, 116, 68)
      ..quadraticBezierTo(70, 96, 16, 74)
      ..close();
    canvas.drawPath(bodyPath, _fill(body));
    // Small head, low
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(122, 70), width: 26, height: 18),
        _fill(body));
    // Tail with spikes
    final tail = Path()
      ..moveTo(20, 72)
      ..quadraticBezierTo(6, 66, 2, 56)
      ..quadraticBezierTo(12, 74, 26, 80)
      ..close();
    canvas.drawPath(tail, _fill(body));
    canvas.drawPath(
        Path()
          ..moveTo(6, 60)
          ..lineTo(1, 48)
          ..lineTo(12, 56)
          ..close(),
        _fill(plate));
    _eye(canvas, const Offset(124, 67));
  }

  // Triceratops: big neck frill and three horns.
  void _triceratops(Canvas canvas) {
    const body = Color(0xFF4DB6AC);
    const dark = Color(0xFF00897B);
    _legs(canvas, dark, const [Offset(40, 78), Offset(72, 78)], 26);
    // Body
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(58, 64), width: 76, height: 44),
        _fill(body));
    // Tail
    canvas.drawPath(
        Path()
          ..moveTo(24, 62)
          ..quadraticBezierTo(6, 60, 2, 52)
          ..quadraticBezierTo(14, 70, 30, 74)
          ..close(),
        _fill(body));
    // Frill
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(102, 44), width: 40, height: 46),
        _fill(dark));
    // Head/beak
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(120, 54), width: 40, height: 28),
        _fill(body));
    // Horns: two brow + one nose
    canvas.drawPath(
        Path()
          ..moveTo(112, 42)
          ..lineTo(116, 24)
          ..lineTo(122, 42)
          ..close(),
        _fill(Colors.white));
    canvas.drawPath(
        Path()
          ..moveTo(124, 44)
          ..lineTo(130, 28)
          ..lineTo(134, 46)
          ..close(),
        _fill(Colors.white));
    canvas.drawPath(
        Path()
          ..moveTo(132, 52)
          ..lineTo(142, 46)
          ..lineTo(136, 58)
          ..close(),
        _fill(Colors.white));
    _eye(canvas, const Offset(116, 50));
  }

  // Brachiosaurus: sky-high neck, small head, gentle giant.
  void _brachiosaurus(Canvas canvas) {
    const body = Color(0xFF7986CB);
    const dark = Color(0xFF5C6BC0);
    _legs(canvas, dark, const [Offset(52, 80), Offset(84, 80)], 26, 14);
    // Body
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(70, 68), width: 70, height: 40),
        _fill(body));
    // Tail
    canvas.drawPath(
        Path()
          ..moveTo(38, 64)
          ..quadraticBezierTo(16, 62, 6, 52)
          ..quadraticBezierTo(24, 74, 44, 78)
          ..close(),
        _fill(body));
    // Loooong neck
    final neck = Path()
      ..moveTo(92, 60)
      ..quadraticBezierTo(104, 40, 106, 14)
      ..lineTo(122, 16)
      ..quadraticBezierTo(116, 44, 104, 66)
      ..close();
    canvas.drawPath(neck, _fill(body));
    // Small head
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(116, 12), width: 26, height: 16),
        _fill(body));
    _eye(canvas, const Offset(120, 10));
    // Belly highlight
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(70, 76), width: 44, height: 18),
        _fill(const Color(0xFFC5CAE9)));
  }

  // Pterodactyl: wide wings, head crest, soaring.
  void _pterodactyl(Canvas canvas) {
    const body = Color(0xFFBA68C8);
    const dark = Color(0xFF9C27B0);
    // Left wing
    canvas.drawPath(
        Path()
          ..moveTo(70, 55)
          ..quadraticBezierTo(30, 20, 4, 38)
          ..quadraticBezierTo(36, 44, 66, 66)
          ..close(),
        _fill(dark));
    // Right wing
    canvas.drawPath(
        Path()
          ..moveTo(80, 55)
          ..quadraticBezierTo(116, 18, 146, 34)
          ..quadraticBezierTo(112, 42, 84, 66)
          ..close(),
        _fill(dark));
    // Body
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(75, 62), width: 30, height: 40),
        _fill(body));
    // Head with crest
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(78, 38), width: 22, height: 18),
        _fill(body));
    canvas.drawPath(
        Path()
          ..moveTo(72, 32)
          ..lineTo(58, 22)
          ..lineTo(74, 26)
          ..close(),
        _fill(dark));
    // Beak
    canvas.drawPath(
        Path()
          ..moveTo(86, 36)
          ..lineTo(104, 40)
          ..lineTo(86, 44)
          ..close(),
        _fill(const Color(0xFFFF8F00)));
    _eye(canvas, const Offset(80, 36));
  }

  // Ankylosaurus: low armored tank with a club tail.
  void _ankylosaurus(Canvas canvas) {
    const body = Color(0xFFA1887F);
    const armor = Color(0xFF6D4C41);
    _legs(canvas, armor, const [
      Offset(34, 80),
      Offset(58, 80),
      Offset(82, 80),
    ], 22, 11);
    // Wide low body
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(64, 66), width: 88, height: 40),
        _fill(body));
    // Armor bumps
    for (final b in const [
      Offset(34, 54),
      Offset(52, 48),
      Offset(72, 48),
      Offset(90, 54),
      Offset(62, 58),
    ]) {
      canvas.drawCircle(b, 6, _fill(armor));
    }
    // Head
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(110, 62), width: 28, height: 20),
        _fill(body));
    // Club tail!
    canvas.drawPath(
        Path()
          ..moveTo(24, 64)
          ..quadraticBezierTo(10, 60, 6, 54)
          ..quadraticBezierTo(16, 70, 28, 74)
          ..close(),
        _fill(body));
    canvas.drawCircle(const Offset(7, 52), 8, _fill(armor));
    _eye(canvas, const Offset(114, 58));
  }

  @override
  bool shouldRepaint(DinoPainter old) => old.species != species;
}
