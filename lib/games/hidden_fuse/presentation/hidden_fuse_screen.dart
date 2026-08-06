import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/random/seeded_random.dart';
import '../../../shared_ui/widgets/party_scaffold.dart';
import '../domain/hidden_fuse.dart';

class HiddenFuseScreen extends StatefulWidget {
  const HiddenFuseScreen({super.key});

  @override
  State<HiddenFuseScreen> createState() => _HiddenFuseScreenState();
}

class _HiddenFuseScreenState extends State<HiddenFuseScreen> {
  final Stopwatch _clock = Stopwatch()..start();
  var _round = 1;
  late HiddenFuseState _state;
  Timer? _explosionTimer;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _state = _newState();
  }

  HiddenFuseState _newState() =>
      HiddenFuseEngine.initial(SplitMix64Random(7400 + _round));

  void _startHold() {
    if (_state.phase != HiddenFusePhase.waiting) return;
    final transition = HiddenFuseEngine.start(
      _state,
      _clock.elapsedMicroseconds,
    );
    setState(() {
      _state = transition.state;
      _score = 0;
    });
    _explosionTimer?.cancel();
    _explosionTimer = Timer(
      Duration(microseconds: _state.fuseDurationUs),
      _explode,
    );
  }

  void _releaseHold() {
    if (_state.phase != HiddenFusePhase.holding) return;
    _explosionTimer?.cancel();
    final transition = HiddenFuseEngine.release(
      _state,
      _clock.elapsedMicroseconds,
    );
    setState(() {
      _state = transition.state;
      _score = transition.score;
    });
  }

  void _explode() {
    if (!mounted || _state.phase != HiddenFusePhase.holding) return;
    final transition = HiddenFuseEngine.tick(
      _state,
      _clock.elapsedMicroseconds,
    );
    setState(() {
      _state = transition.state;
      _score = 0;
    });
  }

  void _reset() {
    _explosionTimer?.cancel();
    setState(() {
      _round++;
      _state = _newState();
      _score = 0;
    });
  }

  @override
  void dispose() {
    _explosionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finished = _state.phase == HiddenFusePhase.banked ||
        _state.phase == HiddenFusePhase.exploded;
    final exploded = _state.phase == HiddenFusePhase.exploded;

    return PartyScaffold(
      title: 'فیوز پنهان',
      fallbackLocation: '/play',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    exploded
                        ? Icons.local_fire_department_rounded
                        : _state.phase == HiddenFusePhase.holding
                            ? Icons.bolt_rounded
                            : Icons.sports_score_rounded,
                    key: ValueKey(_state.phase),
                    size: 110,
                    color: exploded
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  switch (_state.phase) {
                    HiddenFusePhase.waiting =>
                      'دکمه را نگه دار و پیش از انفجار رها کن.',
                    HiddenFusePhase.holding =>
                      'امتیاز در حال افزایش است… تا کجا ریسک می‌کنی؟',
                    HiddenFusePhase.banked => 'عالی! امتیاز دور ذخیره شد.',
                    HiddenFusePhase.exploded => 'انفجار! امتیاز این دور صفر شد.',
                  },
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                if (finished)
                  Text(
                    'امتیاز: $_score',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                const SizedBox(height: 34),
                if (!finished)
                  Listener(
                    onPointerDown: (_) => _startHold(),
                    onPointerUp: (_) => _releaseHold(),
                    onPointerCancel: (_) => _releaseHold(),
                    child: Semantics(
                      button: true,
                      label: 'نگه‌داشتن فیوز',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _state.phase == HiddenFusePhase.holding
                              ? Theme.of(context).colorScheme.errorContainer
                              : Theme.of(context).colorScheme.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: _state.phase == HiddenFusePhase.holding
                                  ? 34
                                  : 12,
                              spreadRadius: 3,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.25),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _state.phase == HiddenFusePhase.holding
                              ? 'رها کن'
                              : 'نگه دار',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('دور بعد'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
