import 'dart:convert';

final class ProtocolEnvelope {
  const ProtocolEnvelope({
    required this.protocolVersion,
    required this.messageId,
    required this.sessionId,
    required this.playerId,
    required this.sequence,
    required this.clientTimeUs,
    required this.type,
    required this.payload,
  });

  final int protocolVersion;
  final String messageId;
  final String sessionId;
  final String? playerId;
  final int sequence;
  final int clientTimeUs;
  final String type;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'protocolVersion': protocolVersion,
    'messageId': messageId,
    'sessionId': sessionId,
    'playerId': playerId,
    'sequence': sequence,
    'clientTimeUs': clientTimeUs,
    'type': type,
    'payload': payload,
  };

  String encode() => jsonEncode(toJson());

  factory ProtocolEnvelope.fromJson(Map<String, Object?> json) {
    final payload = json['payload'];
    if (payload is! Map) throw const FormatException('payload must be an object');
    return ProtocolEnvelope(
      protocolVersion: json['protocolVersion'] as int,
      messageId: json['messageId'] as String,
      sessionId: json['sessionId'] as String,
      playerId: json['playerId'] as String?,
      sequence: json['sequence'] as int,
      clientTimeUs: json['clientTimeUs'] as int,
      type: json['type'] as String,
      payload: payload.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  factory ProtocolEnvelope.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('message must be an object');
    }
    return ProtocolEnvelope.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

abstract final class ProtocolTypes {
  static const hello = 'system.hello';
  static const welcome = 'system.welcome';
  static const error = 'system.error';
  static const ping = 'system.ping';
  static const pong = 'system.pong';
  static const lobbyJoin = 'lobby.join';
  static const lobbyJoined = 'lobby.joined';
  static const lobbySnapshot = 'lobby.snapshot';
  static const lobbyReady = 'lobby.ready';
  static const lobbyLeave = 'lobby.leave';
  static const gamePrepare = 'game.prepare';
  static const gameStart = 'game.start';
  static const gameInput = 'game.input';
  static const stateSnapshot = 'game.stateSnapshot';
  static const stateDelta = 'game.stateDelta';
  static const roundEnd = 'game.roundEnd';
  static const matchEnd = 'game.matchEnd';
  static const reconnect = 'session.reconnect';
  static const reconnected = 'session.reconnected';
  static const closed = 'session.closed';
}
