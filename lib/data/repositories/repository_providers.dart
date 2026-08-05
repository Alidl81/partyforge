import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/player/player_repository.dart';
import '../database/app_database.dart';
import 'drift_player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final repository = DriftPlayerRepository(ref.watch(appDatabaseProvider));
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});
