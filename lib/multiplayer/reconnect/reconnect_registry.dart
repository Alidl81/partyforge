import '../security/token_service.dart';

final class ResumeRecord {
  const ResumeRecord({required this.playerId, required this.token, required this.lastAcknowledgedSequence});
  final String playerId;
  final ExpiringToken token;
  final int lastAcknowledgedSequence;
}

final class ReconnectRegistry {
  ReconnectRegistry({TokenService? tokens}) : _tokens = tokens ?? TokenService();
  final TokenService _tokens;
  final Map<String, ResumeRecord> _records = {};

  ResumeRecord issue(String playerId, int lastAcknowledgedSequence) {
    revokePlayer(playerId);
    final record = ResumeRecord(
      playerId: playerId,
      token: _tokens.issue(lifetime: const Duration(minutes: 5)),
      lastAcknowledgedSequence: lastAcknowledgedSequence,
    );
    _records[record.token.value] = record;
    return record;
  }

  void revokePlayer(String playerId) {
    _records.removeWhere((_, record) => record.playerId == playerId);
  }

  ResumeRecord? consume(String token) {
    final record = _records.remove(token);
    if (record == null || record.token.isExpired) return null;
    return record;
  }
}
