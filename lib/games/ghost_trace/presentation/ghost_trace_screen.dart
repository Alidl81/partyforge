import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/random/seeded_random.dart';
import '../../../shared_ui/widgets/party_scaffold.dart';
import '../domain/ghost_trace.dart';

class GhostTraceScreen extends StatefulWidget {
  const GhostTraceScreen({super.key});

  @override
  State<GhostTraceScreen> createState() => _GhostTraceScreenState();
}

class _GhostTraceScreenState extends State<GhostTraceScreen> {
  var _round = 1;
  late List<NormalizedPoint> _reference;
  final List<NormalizedPoint> _attempt = [];
  Timer? _hideTimer;
  bool _showReference = true;
  GhostTraceScore? _score;

  @override
  void initState() {
    super.initState();
    _prepareRound();
  }

  void _prepareRound() {
    final random = SplitMix64Random(202600 + _round);
    _reference = List.generate(7, (index) {
      final x = 0.08 + index * 0.14;
      final y = 0.18 + random.nextDouble() * 0.64;
      return NormalizedPoint(x.clamp(0.05, 0.95).toDouble(), y);
    }, growable: false);
    _attempt.clear();
    _score = null;
    _showReference = true;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showReference = false);
    });
  }

  void _newRound() {
    setState(() {
      _round++;
      _prepareRound();
    });
  }

  void _addPoint(Offset local, Size size, {bool clear = false}) {
    if (_showReference || size.width <= 0 || size.height <= 0) return;
    setState(() {
      if (clear) _attempt.clear();
      _attempt.add(
        NormalizedPoint(
          (local.dx / size.width).clamp(0.0, 1.0).toDouble(),
          (local.dy / size.height).clamp(0.0, 1.0).toDouble(),
        ),
      );
      _score = null;
    });
  }

  void _calculate() {
    if (_attempt.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا یک مسیر کامل رسم کن.')),
      );
      return;
    }
    setState(() => _score = GhostTraceEngine.score(_reference, _attempt));
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PartyScaffold(
      title: 'رد شبح',
      fallbackLocation: '/play',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _showReference
                    ? 'مسیر را به خاطر بسپار…'
                    : 'حالا همان مسیر را رسم کن.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 16 / 10,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      onPanStart: (details) =>
                          _addPoint(details.localPosition, size, clear: true),
                      onPanUpdate: (details) =>
                          _addPoint(details.localPosition, size),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CustomPaint(
                            painter: _TracePainter(
                              points: _showReference ? _reference : _attempt,
                              reference: _showReference,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (_score case final score?)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text(
                          'امتیاز ${score.points} از ۱۰۰۰',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'میانگین خطا: ${score.averageDistance.toStringAsFixed(3)}  •  خطای پایان: ${score.endpointError.toStringAsFixed(3)}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showReference
                          ? null
                          : () => setState(() {
                                _attempt.clear();
                                _score = null;
                              }),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('پاک‌کردن'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _showReference ? null : _calculate,
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('محاسبهٔ امتیاز'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _newRound,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('مسیر جدید'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({
    required this.points,
    required this.reference,
    required this.color,
  });

  final List<NormalizedPoint> points;
  final bool reference;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()
      ..moveTo(points.first.x * size.width, points.first.y * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.x * size.width, point.y * size.height);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: reference ? 0.95 : 0.8)
        ..strokeWidth = reference ? 11 : 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}
