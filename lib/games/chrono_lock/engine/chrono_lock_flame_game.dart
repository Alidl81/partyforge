import 'dart:ui';

import 'package:flame/game.dart';

final class ChronoLockFlameGame extends FlameGame {
  double _phase = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void update(double dt) {
    super.update(dt);
    _phase = (_phase + dt * 0.35) % 1.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final base = size.x < size.y ? size.x : size.y;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x336D4AFF);
    for (var i = 0; i < 4; i++) {
      final progress = (_phase + i / 4) % 1.0;
      canvas.drawCircle(center, base * (0.12 + progress * 0.42), paint);
    }
  }
}
