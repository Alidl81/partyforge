import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/multiplayer/reconnect/reconnect_registry.dart';

void main() {
  test('resume token can be consumed only once', () {
    final registry = ReconnectRegistry();
    final issued = registry.issue('p1', 42);
    final restored = registry.consume(issued.token.value);
    expect(restored?.playerId, 'p1');
    expect(restored?.lastAcknowledgedSequence, 42);
    expect(registry.consume(issued.token.value), isNull);
  });
}
