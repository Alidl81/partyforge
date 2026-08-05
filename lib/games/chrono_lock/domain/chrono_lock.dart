import '../../../core/domain/game_contracts/game_contract.dart';
import '../../../core/random/seeded_random.dart';

enum ChronoLockPhase { preview, running, stopped }

final class ChronoLockState {
  const ChronoLockState({
    required this.targetUs,
    required this.phase,
    this.startedAtUs,
    this.stoppedAtUs,
  });

  final int targetUs;
  final ChronoLockPhase phase;
  final int? startedAtUs;
  final int? stoppedAtUs;

  int? get elapsedUs => startedAtUs == null || stoppedAtUs == null
      ? null
      : stoppedAtUs! - startedAtUs!;

  ChronoLockState copyWith({
    ChronoLockPhase? phase,
    int? startedAtUs,
    int? stoppedAtUs,
  }) => ChronoLockState(
    targetUs: targetUs,
    phase: phase ?? this.phase,
    startedAtUs: startedAtUs ?? this.startedAtUs,
    stoppedAtUs: stoppedAtUs ?? this.stoppedAtUs,
  );
}

sealed class ChronoLockCommand {
  const ChronoLockCommand();
}
final class StartChronoLock extends ChronoLockCommand { const StartChronoLock(); }
final class StopChronoLock extends ChronoLockCommand { const StopChronoLock(); }

enum ChronoLockEventType { started, stopped }

final class ChronoLockEvent {
  const ChronoLockEvent(this.type, this.atUs);
  final ChronoLockEventType type;
  final int atUs;
}

final class ChronoLockScore {
  const ChronoLockScore({required this.errorUs, required this.points});
  final int errorUs;
  final int points;
}

final class ChronoLockGame
    implements MiniGame<ChronoLockState, ChronoLockCommand, ChronoLockEvent, ChronoLockScore, ChronoLockScore?> {
  const ChronoLockGame();

  @override String get id => 'chrono_lock';
  @override String get displayName => 'قفل زمان';
  @override Set<GameCapability> get capabilities => {GameCapability.touch, GameCapability.mouse, GameCapability.keyboard};
  @override Set<GameMode> get supportedModes => {GameMode.localPassAndPlay, GameMode.lanHost, GameMode.lanClient};
  @override int get minimumPlayers => 1;
  @override int get maximumPlayers => 8;

  @override
  ChronoLockState createInitialState(GameContext context, SeededRandom random) {
    final targetMs = 2000 + random.nextInt(8001);
    return ChronoLockState(targetUs: targetMs * 1000, phase: ChronoLockPhase.preview);
  }

  @override
  String? validateCommand(ChronoLockState state, ChronoLockCommand command, GameContext context) {
    return switch ((state.phase, command)) {
      (ChronoLockPhase.preview, StartChronoLock()) => null,
      (ChronoLockPhase.running, StopChronoLock()) => null,
      _ => 'فرمان در وضعیت فعلی معتبر نیست.',
    };
  }

  @override
  GameTransition<ChronoLockState, ChronoLockEvent, ChronoLockScore> handleCommand(
    ChronoLockState state,
    ChronoLockCommand command,
    GameContext context,
    SeededRandom random,
    int authoritativeTimeUs,
  ) {
    final error = validateCommand(state, command, context);
    if (error != null) throw StateError(error);
    return switch (command) {
      StartChronoLock() => GameTransition(
        newState: state.copyWith(phase: ChronoLockPhase.running, startedAtUs: authoritativeTimeUs),
        events: [ChronoLockEvent(ChronoLockEventType.started, authoritativeTimeUs)],
      ),
      StopChronoLock() => GameTransition(
        newState: state.copyWith(phase: ChronoLockPhase.stopped, stoppedAtUs: authoritativeTimeUs),
        events: [ChronoLockEvent(ChronoLockEventType.stopped, authoritativeTimeUs)],
      ),
    };
  }

  static ChronoLockScore scoreFor({required int targetUs, required int elapsedUs}) {
    final error = (elapsedUs - targetUs).abs();
    final normalized = 1.0 - (error / targetUs);
    final points = (normalized.clamp(0.0, 1.0) * 1000).round();
    return ChronoLockScore(errorUs: error, points: points);
  }

  @override
  List<ChronoLockScore> calculateScores(ChronoLockState state, GameContext context) {
    final elapsed = state.elapsedUs;
    return elapsed == null ? const [] : [scoreFor(targetUs: state.targetUs, elapsedUs: elapsed)];
  }

  @override
  ChronoLockScore? determineRoundResult(ChronoLockState state, GameContext context) =>
      calculateScores(state, context).firstOrNull;

  @override
  ChronoLockScore? determineMatchResult(ChronoLockState state, GameContext context) =>
      determineRoundResult(state, context);
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
