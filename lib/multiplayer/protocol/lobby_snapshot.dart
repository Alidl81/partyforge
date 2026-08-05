import 'package:freezed_annotation/freezed_annotation.dart';

part 'lobby_snapshot.freezed.dart';
part 'lobby_snapshot.g.dart';

@freezed
abstract class LobbyPlayer with _$LobbyPlayer {
  const factory LobbyPlayer({
    required String playerId,
    required String displayName,
    required bool ready,
    required int seatIndex,
  }) = _LobbyPlayer;

  factory LobbyPlayer.fromJson(Map<String, Object?> json) => _$LobbyPlayerFromJson(json);
}

@freezed
abstract class LobbySnapshot with _$LobbySnapshot {
  const factory LobbySnapshot({
    required String sessionId,
    required int revision,
    required List<LobbyPlayer> players,
    required String? selectedGameId,
  }) = _LobbySnapshot;

  factory LobbySnapshot.fromJson(Map<String, Object?> json) => _$LobbySnapshotFromJson(json);
}
