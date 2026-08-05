import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/logging/app_logger.dart';
import 'package:partyforge/multiplayer/client/lan_session_client.dart';
import 'package:partyforge/multiplayer/host/host_session_server.dart';
import 'package:partyforge/multiplayer/protocol/protocol_envelope.dart';

final class _SilentLogger implements AppLogger {
  @override
  void debug(String event, [Map<String, Object?> fields = const {}]) {}

  @override
  void error(String event, Object error, StackTrace stackTrace) {}

  @override
  void info(String event, [Map<String, Object?> fields = const {}]) {}

  @override
  void warning(String event, [Map<String, Object?> fields = const {}]) {}
}

void main() {
  test('host authoritatively validates join credentials', () async {
    final server = HostSessionServer(logger: _SilentLogger());
    final info = await server.start(address: InternetAddress.loopbackIPv4);
    final client = LanSessionClient();
    final joined = client.messages
        .firstWhere((message) => message.type == ProtocolTypes.lobbyJoined)
        .timeout(const Duration(seconds: 3));

    await client.connect(
      address: InternetAddress.loopbackIPv4,
      port: info.port,
      sessionId: info.sessionId,
      sessionCode: info.sessionCode,
      joinToken: info.joinToken.value,
      playerId: 'player-1',
      displayName: 'Player One',
    );

    final message = await joined;
    expect(message.payload['players'], isA<List<Object?>>());

    await client.close();
    await server.close();
  });

  test('client resumes the same player after a temporary disconnect', () async {
    final server = HostSessionServer(logger: _SilentLogger());
    final info = await server.start(address: InternetAddress.loopbackIPv4);
    final client = LanSessionClient();
    final joined = client.messages
        .firstWhere((message) => message.type == ProtocolTypes.lobbyJoined)
        .timeout(const Duration(seconds: 3));

    await client.connect(
      address: InternetAddress.loopbackIPv4,
      port: info.port,
      sessionId: info.sessionId,
      sessionCode: info.sessionCode,
      joinToken: info.joinToken.value,
      playerId: 'player-reconnect',
      displayName: 'Reconnect Player',
    );
    await joined;
    expect(client.resumeToken, isNotEmpty);

    await client.disconnectTransport();
    final reconnected = client.messages
        .firstWhere((message) => message.type == ProtocolTypes.reconnected)
        .timeout(const Duration(seconds: 3));
    await client.reconnect();
    final message = await reconnected;

    expect(message.payload['players'], isA<List<Object?>>());
    expect(client.resumeToken, isNotEmpty);

    await client.close();
    await server.close();
  });
}
