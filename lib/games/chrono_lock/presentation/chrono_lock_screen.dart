import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/chrono_lock_controller.dart';
import '../domain/chrono_lock.dart';
import '../../../shared_ui/widgets/party_scaffold.dart';
import '../engine/chrono_lock_flame_game.dart';

class ChronoLockScreen extends ConsumerStatefulWidget {
  const ChronoLockScreen({super.key});

  @override
  ConsumerState<ChronoLockScreen> createState() => _ChronoLockScreenState();
}

class _ChronoLockScreenState extends ConsumerState<ChronoLockScreen> {
  late final ChronoLockFlameGame _backdrop;

  @override
  void initState() {
    super.initState();
    _backdrop = ChronoLockFlameGame();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(chronoLockControllerProvider);
    final controller = ref.read(chronoLockControllerProvider.notifier);
    final state = view.gameState;
    final targetSeconds = state.targetUs / 1000000;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const PartyBackButton(fallbackLocation: '/play'),
        title: const Text('قفل زمان'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: GameWidget<ChronoLockFlameGame>(game: _backdrop),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        state.phase == ChronoLockPhase.running
                            ? Icons.timer_off_outlined
                            : Icons.timer_outlined,
                        size: 96,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        switch (state.phase) {
                          ChronoLockPhase.preview =>
                            'هدف: ${targetSeconds.toStringAsFixed(3)} ثانیه',
                          ChronoLockPhase.running =>
                            'زمان پنهان است؛ در لحظهٔ مناسب توقف کن.',
                          ChronoLockPhase.stopped =>
                            'زمان ثبت شد: ${(state.elapsedUs! / 1000000).toStringAsFixed(3)} ثانیه',
                        },
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 18),
                      if (view.score case final score?)
                        Semantics(
                          label: 'امتیاز ${score.points}',
                          child: Text(
                            'امتیاز: ${score.points} از ۱۰۰۰\n'
                            'خطا: ${(score.errorUs / 1000).toStringAsFixed(0)} میلی‌ثانیه',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      if (view.persistenceError case final error?) ...[
                        const SizedBox(height: 12),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      FilledButton.icon(
                        onPressed: switch (state.phase) {
                          ChronoLockPhase.preview => controller.start,
                          ChronoLockPhase.running =>
                            () => unawaited(controller.stop()),
                          ChronoLockPhase.stopped => controller.reset,
                        },
                        icon: Icon(
                          state.phase == ChronoLockPhase.running
                              ? Icons.stop
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          state.phase == ChronoLockPhase.running
                              ? 'توقف'
                              : state.phase == ChronoLockPhase.stopped
                                  ? 'دور بعد'
                                  : 'شروع',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
