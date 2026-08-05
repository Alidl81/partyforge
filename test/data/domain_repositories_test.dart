import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/domain/match/game_match.dart';
import 'package:partyforge/core/domain/player/player_game_stats.dart';
import 'package:partyforge/core/domain/player/player_profile.dart';
import 'package:partyforge/core/domain/scoring/score_event.dart';
import 'package:partyforge/core/domain/tournament/tournament.dart';
import 'package:partyforge/data/database/app_database.dart';
import 'package:partyforge/data/repositories/drift_match_repository.dart';
import 'package:partyforge/data/repositories/drift_player_repository.dart';
import 'package:partyforge/data/repositories/drift_stats_repository.dart';
import 'package:partyforge/data/repositories/drift_tournament_repository.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('persists score events, stats, and tournaments', () async {
    final now = DateTime.utc(2026, 8, 5);
    final playerRepository = DriftPlayerRepository(database);
    final matchRepository = DriftMatchRepository(database);
    final statsRepository = DriftStatsRepository(database);
    final tournamentRepository = DriftTournamentRepository(database);

    await playerRepository.save(
      PlayerProfile(
        id: 'p1',
        name: 'بازیکن',
        colorValue: 0xFF000000,
        avatarId: 'default',
        championshipPoints: 0,
        totalWins: 0,
        totalLosses: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await matchRepository.saveMatch(
      GameMatch(
        id: 'm1',
        gameId: 'chrono_lock',
        mode: 'localPassAndPlay',
        hostPlayerId: 'p1',
        seed: 42,
        status: MatchStatus.completed,
        createdAt: now,
        startedAt: now,
        endedAt: now.add(const Duration(seconds: 10)),
        settingsJson: '{}',
        protocolVersion: 1,
      ),
    );
    await matchRepository.saveRound(
      GameRound(
        id: 'r1',
        matchId: 'm1',
        roundIndex: 0,
        state: 'stopped',
        startedAt: now,
        endedAt: now.add(const Duration(seconds: 10)),
      ),
    );
    await matchRepository.appendScoreEvent(
      ScoreEvent(
        id: 's1',
        matchId: 'm1',
        roundId: 'r1',
        playerId: 'p1',
        reason: 'chrono_lock.result',
        rawPoints: 950,
        championshipPoints: 10,
        metadata: const {'errorUs': 10000},
        createdAt: now,
      ),
    );
    await statsRepository.save(
      const PlayerGameStats(
        playerId: 'p1',
        gameId: 'chrono_lock',
        matches: 1,
        wins: 1,
        losses: 0,
        bestRawScore: 950,
        totalRawScore: 950,
        recordJson: '{"bestErrorUs":10000}',
      ),
    );
    await tournamentRepository.save(
      Tournament(
        id: 't1',
        name: 'جام شب',
        status: TournamentStatus.running,
        gameOrder: const ['chrono_lock', 'signal_snap'],
        currentGameIndex: 1,
        createdAt: now,
      ),
    );

    final scores = await matchRepository.scoresForMatch('m1');
    final stats = await statsRepository.getForPlayer('p1', 'chrono_lock');
    final tournament = await tournamentRepository.getById('t1');

    expect(scores.single.rawPoints, 950);
    expect(scores.single.metadata['errorUs'], 10000);
    expect(stats?.wins, 1);
    expect(tournament?.gameOrder, ['chrono_lock', 'signal_snap']);
    await playerRepository.dispose();
  });
}
