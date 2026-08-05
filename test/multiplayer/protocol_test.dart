import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/multiplayer/client/sequence_tracker.dart';
import 'package:partyforge/multiplayer/protocol/message_guard.dart';
import 'package:partyforge/multiplayer/protocol/protocol_envelope.dart';

ProtocolEnvelope message({String id = 'm1', int sequence = 1, String? player = 'p'}) => ProtocolEnvelope(
  protocolVersion: 1,
  messageId: id,
  sessionId: 's',
  playerId: player,
  sequence: sequence,
  clientTimeUs: 100,
  type: ProtocolTypes.gameInput,
  payload: const {'x': 1},
);

void main() {
  test('protocol envelope round-trips', () {
    final original = message();
    final decoded = ProtocolEnvelope.decode(original.encode());
    expect(decoded.messageId, original.messageId);
    expect(decoded.payload['x'], 1);
  });

  test('duplicate and old sequence are rejected', () {
    final guard = MessageGuard(protocolVersion: 1, sessionId: 's');
    expect(guard.validate(message(), validPlayerIds: {'p'}), isNull);
    expect(guard.validate(message(), validPlayerIds: {'p'}), MessageRejection.duplicate);
    expect(guard.validate(message(id: 'm2', sequence: 1), validPlayerIds: {'p'}), MessageRejection.oldSequence);
  });

  test('sequence tracker detects gap and snapshot recovery', () {
    final tracker = SequenceTracker();
    expect(tracker.accept(1), SequenceStatus.accepted);
    expect(tracker.accept(3), SequenceStatus.gap);
    tracker.resetFromSnapshot(3);
    expect(tracker.accept(4), SequenceStatus.accepted);
  });
}
