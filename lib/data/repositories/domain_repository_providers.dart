import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/match/match_repository.dart';
import '../../core/domain/player/stats_repository.dart';
import '../../core/domain/settings/settings_repository.dart';
import '../../core/domain/tournament/tournament_repository.dart';
import '../database/app_database.dart';
import '../settings/settings_repository.dart';
import 'drift_match_repository.dart';
import 'drift_stats_repository.dart';
import 'drift_tournament_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => DriftMatchRepository(ref.watch(appDatabaseProvider)),
);

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => DriftStatsRepository(ref.watch(appDatabaseProvider)),
);

final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => DriftTournamentRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
);
