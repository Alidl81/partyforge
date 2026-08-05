import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/random/seeded_random.dart';
import 'package:partyforge/games/sketch_imposter/domain/sketch_imposter.dart';

void main() {
  test('same seed assigns exactly one identical imposter', () {
    final first = SketchImposterEngine.assignRoles(
      playerIds: const ['a', 'b', 'c', 'd'],
      mainPrompt: 'گربه',
      similarPrompt: 'ببر',
      random: SplitMix64Random(91),
    );
    final second = SketchImposterEngine.assignRoles(
      playerIds: const ['a', 'b', 'c', 'd'],
      mainPrompt: 'گربه',
      similarPrompt: 'ببر',
      random: SplitMix64Random(91),
    );

    expect(first.where((role) => role.isImposter), hasLength(1));
    expect(
      first.singleWhere((role) => role.isImposter).playerId,
      second.singleWhere((role) => role.isImposter).playerId,
    );
  });

  test('rejects duplicate vote and self vote', () {
    const players = {'a', 'b', 'c'};
    expect(
      SketchImposterEngine.validateVote(
        voterId: 'a',
        targetId: 'a',
        playerIds: players,
        existingVotes: const {},
      ),
      isNotNull,
    );
    expect(
      SketchImposterEngine.validateVote(
        voterId: 'a',
        targetId: 'b',
        playerIds: players,
        existingVotes: const {'a': 'c'},
      ),
      isNotNull,
    );
  });
}
