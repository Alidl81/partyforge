import 'player_profile.dart';

abstract interface class PlayerRepository {
  Stream<List<PlayerProfile>> watchAll();
  Future<List<PlayerProfile>> getAll();
  Future<void> save(PlayerProfile profile);
  Future<void> delete(String id);
}
