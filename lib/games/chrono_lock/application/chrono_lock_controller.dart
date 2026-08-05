import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/game_contracts/game_contract.dart';
import '../../../core/domain/match/game_match.dart';
import '../../../core/domain/scoring/score_event.dart';
import '../../../core/random/seeded_random.dart';
import '../../../core/timing/monotonic_clock.dart';
import '../../../data/repositories/domain_repository_providers.dart';
import '../domain/chrono_lock.dart';

final chronoLockControllerProvider =
    NotifierProvider.autoDispose<ChronoLockController, ChronoLockViewState>(
  ChronoLockController.new,
);

final class ChronoLockViewState {
  const ChronoLockViewState({
    required this.gameState,
    this.score,
    this.visibleElapsedUs = 0,
    this.persistenceError,
  });

  final ChronoLockState gameState;
  final ChronoLockScore? score;
  final int visibleElapsedUs;
  final String? persistenceError;

  ChronoLockViewState copyWith({
    ChronoLockState? gameState,
    ChronoLockScore? score,
    int? visibleElapsedUs,
    String? persistenceError,
  }) => ChronoLockViewState(
    gameState: gameState ?? this.gameState,
    score: score ?? this.score,
    visibleElapsedUs: visibleElapsedUs ?? this.visibleElapsedUs,
    persistenceError: persistenceError ?? this.persistenceError,
  );
}

final class ChronoLockController extends Notifier<ChronoLockViewState> {
  final _game = const ChronoLockGame();
  final _clock = StopwatchMonotonicClock();
  Timer? _ticker;
  var _roundSeed = 20260805;
  var _roundIndex = 0;
  late String _matchId;
  late String _roundId;
  late DateTime _roundCreatedAt;

  GameContext get _context => GameContext(
    matchId: _matchId,
    roundIndex: _roundIndex,
    playerIds: const ['local-player'],
  );

  @override
  ChronoLockViewState build() {
    ref.onDispose(() => _ticker?.cancel());
    _prepareRoundIdentity();
    final initial = _game.createInitialState(
      _context,
      SplitMix64Random(_roundSeed),
    );
    return ChronoLockViewState(gameState: initial);
  }

  void start() {
    final transition = _game.handleCommand(
      state.gameState,
      const StartChronoLock(),
      _context,
      SplitMix64Random(_roundSeed),
      _clock.nowMicroseconds(),
    );
    state = state.copyWith(gameState: transition.newState);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final startedAt = state.gameState.startedAtUs;
      if (startedAt != null) {
        state = state.copyWith(
          visibleElapsedUs: _clock.nowMicroseconds() - startedAt,
        );
      }
    });
  }

  Future<void> stop() async {
    _ticker?.cancel();
    final transition = _game.handleCommand(
      state.gameState,
      const StopChronoLock(),
      _context,
      SplitMix64Random(_roundSeed),
      _clock.nowMicroseconds(),
    );
    final score = _game.determineRoundResult(transition.newState, _context);
    state = state.copyWith(gameState: transition.newState, score: score);
    if (score == null) return;

    try {
      final endedAt = DateTime.now().toUtc();
      final repository = ref.read(matchRepositoryProvider);
      await repository.saveMatch(
        GameMatch(
          id: _matchId,
          gameId: _game.id,
          mode: GameMode.localPassAndPlay.name,
          hostPlayerId: 'local-player',
          seed: _roundSeed,
          status: MatchStatus.completed,
          createdAt: _roundCreatedAt,
          startedAt: _roundCreatedAt,
          endedAt: endedAt,
          settingsJson: jsonEncode({
            'targetUs': transition.newState.targetUs,
          }),
          protocolVersion: 1,
        ),
      );
      await repository.saveRound(
        GameRound(
          id: _roundId,
          matchId: _matchId,
          roundIndex: _roundIndex,
          state: ChronoLockPhase.stopped.name,
          startedAt: _roundCreatedAt,
          endedAt: endedAt,
        ),
      );
      await repository.appendScoreEvent(
        ScoreEvent(
          id: const Uuid().v4(),
          matchId: _matchId,
          roundId: _roundId,
          playerId: 'local-player',
          reason: 'chrono_lock.round_result',
          rawPoints: score.points,
          championshipPoints: 10,
          metadata: {
            'errorUs': score.errorUs,
            'targetUs': transition.newState.targetUs,
            'elapsedUs': transition.newState.elapsedUs,
          },
          createdAt: endedAt,
        ),
      );
    } on Object {
      state = state.copyWith(
        persistenceError: 'نتیجه نمایش داده شد، اما ذخیره‌سازی ناموفق بود.',
      );
    }
  }

  void reset() {
    _ticker?.cancel();
    _roundSeed++;
    _roundIndex++;
    _prepareRoundIdentity();
    final initial = _game.createInitialState(
      _context,
      SplitMix64Random(_roundSeed),
    );
    state = ChronoLockViewState(gameState: initial);
  }

  void _prepareRoundIdentity() {
    _matchId = const Uuid().v4();
    _roundId = const Uuid().v4();
    _roundCreatedAt = DateTime.now().toUtc();
  }
}
