import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/logging/app_logger.dart';
import 'package:partyforge/multiplayer/discovery/lan_room.dart';
import 'package:partyforge/multiplayer/discovery/lan_room_discovery.dart';
import 'package:partyforge/multiplayer/host/host_session_server.dart';

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
  test('room announcement round-trips without exposing manual fields', () {
    final now = DateTime.utc(2026, 8, 6, 10);
    final room = LanRoom(
      address: InternetAddress('192.168.1.20'),
      port: 45873,
      sessionId: 'session-1',
      sessionCode: '123456',
      joinToken: 'join-token',
      roomName: 'اتاق تست',
      playerCount: 3,
      tokenExpiresAt: now.add(const Duration(hours: 1)),
      lastSeenAt: now,
    );

    final decoded = LanRoom.tryDecode(
      room.encodeAnnouncement(),
      sourceAddress: InternetAddress('192.168.1.20'),
      receivedAt: now,
    );

    expect(decoded, isNotNull);
    final actual = decoded!;
    expect(actual.sessionId, 'session-1');
    expect(actual.sessionCode, '123456');
    expect(actual.joinToken, 'join-token');
    expect(actual.playerCount, 3);
  });

  test('health probe discovers a running host with one request', () async {
    final server = HostSessionServer(
      logger: _SilentLogger(),
      roomName: 'اتاق خودکار',
    );
    final info = await server.start(address: InternetAddress.loopbackIPv4);
    final discovery = LanRoomDiscovery();

    final room = await discovery.probeAddress(
      InternetAddress.loopbackIPv4,
      port: info.port,
    );

    expect(room, isNotNull);
    expect(room!.roomName, 'اتاق خودکار');
    expect(room.sessionId, info.sessionId);
    expect(room.sessionCode, info.sessionCode);
    expect(room.joinToken, info.joinToken.value);
    expect(
      info.joinToken.expiresAt.difference(DateTime.now().toUtc()),
      greaterThan(const Duration(hours: 7)),
    );

    await discovery.close();
    await server.close();
  });
}
