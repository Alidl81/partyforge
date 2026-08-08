import 'dart:convert';
import 'dart:io';

abstract final class LanDiscoveryProtocol {
  static const kind = 'partyforge.room';
  static const version = 1;
  static const discoveryPort = 45872;
  static const defaultHostPort = 45873;
  static const roomStaleAfter = Duration(seconds: 12);
}

final class LanRoom {
  LanRoom({
    required this.address,
    required this.port,
    required this.sessionId,
    required this.sessionCode,
    required this.joinToken,
    required this.roomName,
    required this.playerCount,
    required this.tokenExpiresAt,
    required this.lastSeenAt,
  });

  final InternetAddress address;
  final int port;
  final String sessionId;
  final String sessionCode;
  final String joinToken;
  final String roomName;
  final int playerCount;
  final DateTime tokenExpiresAt;
  final DateTime lastSeenAt;

  String get id => sessionId;

  bool isAvailableAt(DateTime now) =>
      now.difference(lastSeenAt) <= LanDiscoveryProtocol.roomStaleAfter &&
      tokenExpiresAt.isAfter(now.toUtc());

  LanRoom seenAt(DateTime time) => LanRoom(
    address: address,
    port: port,
    sessionId: sessionId,
    sessionCode: sessionCode,
    joinToken: joinToken,
    roomName: roomName,
    playerCount: playerCount,
    tokenExpiresAt: tokenExpiresAt,
    lastSeenAt: time,
  );

  Map<String, Object?> toAnnouncementJson() => {
    'kind': LanDiscoveryProtocol.kind,
    'version': LanDiscoveryProtocol.version,
    'port': port,
    'sessionId': sessionId,
    'sessionCode': sessionCode,
    'joinToken': joinToken,
    'roomName': roomName,
    'playerCount': playerCount,
    'tokenExpiresAt': tokenExpiresAt.toUtc().toIso8601String(),
  };

  String encodeAnnouncement() => jsonEncode(toAnnouncementJson());

  static LanRoom? tryDecode(
    String source, {
    required InternetAddress sourceAddress,
    DateTime? receivedAt,
  }) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      return tryFromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
        sourceAddress: sourceAddress,
        receivedAt: receivedAt,
      );
    } on FormatException {
      return null;
    }
  }

  static LanRoom? tryFromJson(
    Map<String, Object?> json, {
    required InternetAddress sourceAddress,
    DateTime? receivedAt,
  }) {
    if (json['kind'] != LanDiscoveryProtocol.kind ||
        json['version'] != LanDiscoveryProtocol.version) {
      return null;
    }

    final port = json['port'];
    final sessionId = json['sessionId'];
    final sessionCode = json['sessionCode'];
    final joinToken = json['joinToken'];
    final roomName = json['roomName'];
    final playerCount = json['playerCount'];
    final expiresAtRaw = json['tokenExpiresAt'];
    if (port is! int ||
        port < 1 ||
        port > 65535 ||
        sessionId is! String ||
        sessionId.isEmpty ||
        sessionCode is! String ||
        sessionCode.isEmpty ||
        joinToken is! String ||
        joinToken.isEmpty ||
        roomName is! String ||
        roomName.trim().isEmpty ||
        playerCount is! int ||
        playerCount < 0 ||
        expiresAtRaw is! String) {
      return null;
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw)?.toUtc();
    if (expiresAt == null) return null;
    final now = receivedAt ?? DateTime.now();
    if (!expiresAt.isAfter(now.toUtc())) return null;

    return LanRoom(
      address: sourceAddress,
      port: port,
      sessionId: sessionId,
      sessionCode: sessionCode,
      joinToken: joinToken,
      roomName: roomName.trim(),
      playerCount: playerCount,
      tokenExpiresAt: expiresAt,
      lastSeenAt: now,
    );
  }
}
