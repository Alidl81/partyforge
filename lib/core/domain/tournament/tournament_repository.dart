import 'tournament.dart';

abstract interface class TournamentRepository {
  Future<void> save(Tournament tournament);
  Future<Tournament?> getById(String id);
}
