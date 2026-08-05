import 'game_contract.dart';
import '../../random/seeded_random.dart';

final class ReplayCommand<C> {
  const ReplayCommand({
    required this.sequence,
    required this.authoritativeTimeUs,
    required this.command,
  });

  final int sequence;
  final int authoritativeTimeUs;
  final C command;
}

final class ReplayDescriptor<C> {
  const ReplayDescriptor({
    required this.matchId,
    required this.seed,
    required this.commands,
  });

  final String matchId;
  final int seed;
  final List<ReplayCommand<C>> commands;

  void validate() {
    var previous = 0;
    for (final entry in commands) {
      if (entry.sequence <= previous) {
        throw StateError('Replay sequences must be strictly increasing.');
      }
      previous = entry.sequence;
    }
  }
}

abstract final class ReplayRunner {
  static S replay<S, C, E, P>({
    required ReplayDescriptor<C> descriptor,
    required S Function(GameContext context, SeededRandom random)
        createInitialState,
    required GameContext context,
    required GameTransition<S, E, P> Function(
      S state,
      C command,
      GameContext context,
      SeededRandom random,
      int authoritativeTimeUs,
    ) handleCommand,
  }) {
    descriptor.validate();
    final random = SplitMix64Random(descriptor.seed);
    var state = createInitialState(context, random);
    for (final entry in descriptor.commands) {
      state = handleCommand(
        state,
        entry.command,
        context,
        random,
        entry.authoritativeTimeUs,
      ).newState;
    }
    return state;
  }
}
