import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/domain/player/player_profile.dart';
import 'package:partyforge/data/database/app_database.dart';
import 'package:partyforge/data/repositories/drift_player_repository.dart';

void main() {
  test('database migration creates tables and repository persists profile', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = DriftPlayerRepository(database);
    final now = DateTime.utc(2026, 8, 5);
    final profile = PlayerProfile(
      id: 'p1',
      name: 'آرین',
      colorValue: 0xFF6D4AFF,
      avatarId: 'default',
      championshipPoints: 0,
      totalWins: 0,
      totalLosses: 0,
      createdAt: now,
      updatedAt: now,
    );

    await repository.save(profile);
    final rows = await repository.getAll();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'آرین');

    final tables = await database.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
      readsFrom: const {},
    ).get();
    final names = tables.map((row) => row.read<String>('name')).toSet();
    expect(names, containsAll({'players', 'matches', 'score_events'}));

    await repository.dispose();
    await database.close();
  });
}
