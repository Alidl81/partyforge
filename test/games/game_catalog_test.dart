import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/games/catalog/game_catalog.dart';

void main() {
  test('catalog contains expanded unique games with artwork', () {
    expect(GameCatalog.games.length, greaterThanOrEqualTo(12));
    expect(GameCatalog.games.map((game) => game.id).toSet().length,
        GameCatalog.games.length);
    expect(GameCatalog.games.where((game) => game.isNew).length,
        greaterThanOrEqualTo(4));

    for (final game in GameCatalog.games) {
      expect(File(game.imageAsset).existsSync(), isTrue, reason: game.id);
      expect(game.instructions, isNotEmpty, reason: game.id);
      expect(game.playRoute, isNotEmpty, reason: game.id);
    }
  });
}
