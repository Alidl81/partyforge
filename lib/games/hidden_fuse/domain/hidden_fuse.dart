import '../../../core/random/seeded_random.dart';

enum HiddenFusePhase { waiting, holding, banked, exploded }

enum HiddenFuseEventType { holdStarted, holdEnded, explosion }

final class HiddenFuseEvent {
  const HiddenFuseEvent(this.type, this.atUs);
  final HiddenFuseEventType type;
  final int atUs;
}

final class HiddenFuseState {
  const HiddenFuseState({
    required this.fuseDurationUs,
    required this.phase,
    this.holdStartedAtUs,
    this.holdEndedAtUs,
  });

  final int fuseDurationUs;
  final HiddenFusePhase phase;
  final int? holdStartedAtUs;
  final int? holdEndedAtUs;

  int? get explosionAtUs => holdStartedAtUs == null ? null : holdStartedAtUs! + fuseDurationUs;
}

final class HiddenFuseTransition {
  const HiddenFuseTransition({required this.state, required this.events, required this.score});
  final HiddenFuseState state;
  final List<HiddenFuseEvent> events;
  final int score;
}

abstract final class HiddenFuseEngine {
  static HiddenFuseState initial(SeededRandom random) {
    final durationMs = 2200 + random.nextInt(4801);
    return HiddenFuseState(fuseDurationUs: durationMs * 1000, phase: HiddenFusePhase.waiting);
  }

  static HiddenFuseTransition start(HiddenFuseState state, int atUs) {
    if (state.phase != HiddenFusePhase.waiting) throw StateError('Hold can start only once.');
    return HiddenFuseTransition(
      state: HiddenFuseState(
        fuseDurationUs: state.fuseDurationUs,
        phase: HiddenFusePhase.holding,
        holdStartedAtUs: atUs,
      ),
      events: [HiddenFuseEvent(HiddenFuseEventType.holdStarted, atUs)],
      score: 0,
    );
  }

  static HiddenFuseTransition release(HiddenFuseState state, int atUs) {
    if (state.phase != HiddenFusePhase.holding || state.holdStartedAtUs == null) {
      throw StateError('No active hold.');
    }
    final explosionAt = state.explosionAtUs!;
    if (atUs >= explosionAt) {
      return HiddenFuseTransition(
        state: HiddenFuseState(
          fuseDurationUs: state.fuseDurationUs,
          phase: HiddenFusePhase.exploded,
          holdStartedAtUs: state.holdStartedAtUs,
          holdEndedAtUs: explosionAt,
        ),
        events: [HiddenFuseEvent(HiddenFuseEventType.explosion, explosionAt)],
        score: 0,
      );
    }
    final heldUs = atUs - state.holdStartedAtUs!;
    return HiddenFuseTransition(
      state: HiddenFuseState(
        fuseDurationUs: state.fuseDurationUs,
        phase: HiddenFusePhase.banked,
        holdStartedAtUs: state.holdStartedAtUs,
        holdEndedAtUs: atUs,
      ),
      events: [HiddenFuseEvent(HiddenFuseEventType.holdEnded, atUs)],
      score: scoreForHold(heldUs),
    );
  }

  static HiddenFuseTransition tick(HiddenFuseState state, int atUs) {
    if (state.phase != HiddenFusePhase.holding || state.explosionAtUs == null || atUs < state.explosionAtUs!) {
      return HiddenFuseTransition(state: state, events: const [], score: 0);
    }
    final explosionAt = state.explosionAtUs!;
    return HiddenFuseTransition(
      state: HiddenFuseState(
        fuseDurationUs: state.fuseDurationUs,
        phase: HiddenFusePhase.exploded,
        holdStartedAtUs: state.holdStartedAtUs,
        holdEndedAtUs: explosionAt,
      ),
      events: [HiddenFuseEvent(HiddenFuseEventType.explosion, explosionAt)],
      score: 0,
    );
  }

  static int scoreForHold(int heldUs) {
    if (heldUs <= 0) return 0;
    final milliseconds = heldUs ~/ 1000;
    final first = milliseconds.clamp(0, 2000).toInt();
    final second = (milliseconds - 2000).clamp(0, 2000).toInt();
    final third = (milliseconds - 4000).clamp(0, 3000).toInt();
    return first + second * 2 + third * 4;
  }
}
