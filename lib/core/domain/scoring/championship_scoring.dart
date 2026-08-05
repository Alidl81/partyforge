import 'score_event.dart';

abstract final class ChampionshipScoring {
  static const List<int> _rankPoints = [10, 6, 4, 2];

  static Map<String, int> allocate(List<RankedScore> sortedDescending) {
    final result = <String, int>{};
    var index = 0;
    while (index < sortedDescending.length) {
      var end = index + 1;
      while (end < sortedDescending.length &&
          sortedDescending[end].rawScore == sortedDescending[index].rawScore) {
        end++;
      }
      var pool = 0;
      for (var rank = index; rank < end; rank++) {
        pool += rank < _rankPoints.length ? _rankPoints[rank] : 1;
      }
      final calculated = (pool / (end - index)).round();
      final shared = calculated < 1 ? 1 : calculated;
      for (var i = index; i < end; i++) {
        result[sortedDescending[i].playerId] = shared;
      }
      index = end;
    }
    return result;
  }
}
