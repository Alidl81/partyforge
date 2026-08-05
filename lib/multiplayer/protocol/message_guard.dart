import 'protocol_envelope.dart';

enum MessageRejection { protocolMismatch, duplicate, oldSequence, invalidSession, invalidPlayer }

final class MessageGuard {
  MessageGuard({required this.protocolVersion, required this.sessionId});

  final int protocolVersion;
  final String sessionId;
  final Set<String> _messageIds = {};
  final Map<String, int> _lastSequenceByPlayer = {};

  MessageRejection? validate(ProtocolEnvelope envelope, {required Set<String> validPlayerIds}) {
    if (envelope.protocolVersion != protocolVersion) return MessageRejection.protocolMismatch;
    if (envelope.sessionId != sessionId) return MessageRejection.invalidSession;
    if (!_messageIds.add(envelope.messageId)) return MessageRejection.duplicate;
    final playerId = envelope.playerId;
    if (playerId != null && !validPlayerIds.contains(playerId)) return MessageRejection.invalidPlayer;
    final sequenceKey = playerId ?? '<system>';
    final previous = _lastSequenceByPlayer[sequenceKey];
    if (previous != null && envelope.sequence <= previous) return MessageRejection.oldSequence;
    _lastSequenceByPlayer[sequenceKey] = envelope.sequence;
    return null;
  }
}
