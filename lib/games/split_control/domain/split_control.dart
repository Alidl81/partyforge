enum SplitRole { horizontal, vertical, ability, brake }

final class SplitInput {
  const SplitInput({required this.playerId, required this.sequence, required this.axis, required this.pressed, required this.hostTimeUs});
  final String playerId;
  final int sequence;
  final double axis;
  final bool pressed;
  final int hostTimeUs;
}

final class SplitControlInputState {
  const SplitControlInputState({required this.axis, required this.pressed, required this.lastSequence, required this.lastHostTimeUs});
  final double axis;
  final bool pressed;
  final int lastSequence;
  final int lastHostTimeUs;
}

abstract final class SplitControlReducer {
  static Map<String, SplitControlInputState> apply({
    required Map<String, SplitControlInputState> current,
    required SplitInput input,
  }) {
    final previous = current[input.playerId];
    if (previous != null && input.sequence <= previous.lastSequence) return current;
    return Map.unmodifiable({
      ...current,
      input.playerId: SplitControlInputState(
        axis: input.axis.clamp(-1.0, 1.0).toDouble(),
        pressed: input.pressed,
        lastSequence: input.sequence,
        lastHostTimeUs: input.hostTimeUs,
      ),
    });
  }

  static Map<String, SplitControlInputState> expire({
    required Map<String, SplitControlInputState> current,
    required int nowHostUs,
    int timeoutUs = 500000,
  }) => Map.unmodifiable(current.map((id, value) => MapEntry(
    id,
    nowHostUs - value.lastHostTimeUs > timeoutUs
        ? SplitControlInputState(axis: 0, pressed: false, lastSequence: value.lastSequence, lastHostTimeUs: value.lastHostTimeUs)
        : value,
  )));
}
