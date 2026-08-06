import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared_ui/widgets/party_scaffold.dart';
import '../domain/tap_storm.dart';

class TapStormScreen extends StatefulWidget {
  const TapStormScreen({super.key});

  @override
  State<TapStormScreen> createState() => _TapStormScreenState();
}

class _TapStormScreenState extends State<TapStormScreen> {
  static const _duration = Duration(seconds: 5);

  final Stopwatch _clock = Stopwatch();
  Timer? _ticker;
  var _tapCount = 0;
  bool _running = false;
  TapStormResult? _result;

  void _start() {
    _ticker?.cancel();
    setState(() {
      _tapCount = 0;
      _result = null;
      _running = true;
    });
    _clock
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      if (_clock.elapsed >= _duration) {
        _finish();
      } else {
        setState(() {});
      }
    });
  }

  void _tap() {
    if (!_running) return;
    setState(() => _tapCount++);
  }

  void _finish() {
    if (!_running) return;
    _clock.stop();
    _ticker?.cancel();
    setState(() {
      _running = false;
      _result = TapStormEngine.finish(
        tapCount: _tapCount,
        durationUs: _clock.elapsedMicroseconds,
      );
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_duration - _clock.elapsed);
    final remainingMs = remaining.isNegative ? 0 : remaining.inMilliseconds;
    final progress = _running
        ? (1 - remainingMs / _duration.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;

    return PartyScaffold(
      title: 'طوفان ضربه',
      fallbackLocation: '/play',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_running) ...[
                  Text(
                    '${(remainingMs / 1000).toStringAsFixed(1)} ثانیه',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 24),
                ],
                Text(
                  '$_tapCount',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 22),
                if (_result case final result?) ...[
                  Text(
                    'امتیاز: ${result.points}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${result.tapsPerSecond.toStringAsFixed(1)} ضربه در ثانیه',
                  ),
                  const SizedBox(height: 24),
                ],
                if (_running)
                  GestureDetector(
                    onTap: _tap,
                    child: Semantics(
                      button: true,
                      label: 'هدف ضربه',
                      child: Container(
                        width: 260,
                        height: 260,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.35),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.touch_app_rounded,
                          size: 100,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(_result == null ? 'شروع' : 'دوباره بازی کن'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
