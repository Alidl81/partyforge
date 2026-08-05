import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/domain/scoring/championship_scoring.dart';
import 'package:partyforge/core/domain/scoring/score_event.dart';

void main() {
  test('ties share the pooled rank points', () {
    final result = ChampionshipScoring.allocate(const [
      RankedScore(playerId: 'a', rawScore: 100),
      RankedScore(playerId: 'b', rawScore: 100),
      RankedScore(playerId: 'c', rawScore: 50),
    ]);
    expect(result['a'], 8);
    expect(result['b'], 8);
    expect(result['c'], 4);
  });
}
