import '../../random/seeded_random.dart';

enum GameMode { localPassAndPlay, localSharedScreen, lanHost, lanClient }

enum GameCapability {
  touch,
  mouse,
  keyboard,
  multiTouch,
  audio,
  vibration,
  camera,
  accelerometer,
  gyroscope,
  localNetwork,
}

final class GameContext {
  const GameContext({
    required this.matchId,
    required this.roundIndex,
    required this.playerIds,
  });

  final String matchId;
  final int roundIndex;
  final List<String> playerIds;
}

final class GameTransition<S, E, P> {
  const GameTransition({
    required this.newState,
    this.events = const [],
    this.scoreEvents = const [],
  });

  final S newState;
  final List<E> events;
  final List<P> scoreEvents;
}

abstract interface class MiniGame<S, C, E, P, R> {
  String get id;
  String get displayName;
  Set<GameCapability> get capabilities;
  Set<GameMode> get supportedModes;
  int get minimumPlayers;
  int get maximumPlayers;

  S createInitialState(GameContext context, SeededRandom random);
  String? validateCommand(S currentState, C command, GameContext context);
  GameTransition<S, E, P> handleCommand(
    S currentState,
    C command,
    GameContext context,
    SeededRandom random,
    int authoritativeTimeUs,
  );
  List<P> calculateScores(S state, GameContext context);
  R determineRoundResult(S state, GameContext context);
  R determineMatchResult(S state, GameContext context);
}
