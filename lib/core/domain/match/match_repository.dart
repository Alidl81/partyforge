import '../scoring/score_event.dart';
import 'game_match.dart';

abstract interface class MatchRepository {
  Future<void> saveMatch(GameMatch match);
  Future<void> saveRound(GameRound round);
  Future<void> appendScoreEvent(ScoreEvent event);
  Future<List<ScoreEvent>> scoresForMatch(String matchId);
}
