import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../core/logging/app_logger.dart';
import '../discovery/lan_room.dart';
import '../discovery/lan_room_broadcaster.dart';
import '../protocol/message_guard.dart';
import '../protocol/protocol_envelope.dart';
import '../reconnect/reconnect_registry.dart';
import '../security/private_address.dart';
import '../security/token_service.dart';

final class HostSessionInfo {
  const HostSessionInfo({
    required this.sessionId,
    required this.sessionCode,
    required this.joinToken,
    required this.port,
    required this.roomName,
  });

  final String sessionId;
  final String sessionCode;
  final ExpiringToken joinToken;
  final int port;
  final String roomName;
}

final class HostSessionServer {
  factory HostSessionServer({
    required AppLogger logger,
    TokenService? tokens,
    bool developmentAddressOverride = false,
    String roomName = 'اتاق PartyForge',
  }) => HostSessionServer._(
    logger,
    tokens ?? TokenService(),
    developmentAddressOverride,
    roomName.trim().isEmpty ? 'اتاق PartyForge' : roomName.trim(),
  );

  HostSessionServer._(
    this._logger,
    this._tokens,
    this._developmentAddressOverride,
    this._roomName,
  );

  static const protocolVersion = 1;

  final AppLogger _logger;
  final TokenService _tokens;
  final bool _developmentAddressOverride;
  final String _roomName;
  final Set<WebSocket> _sockets = {};
  final Map<WebSocket, StreamSubscription<dynamic>> _socketSubscriptions = {};
  final Map<WebSocket, String> _socketPlayers = {};
  final Set<String> _players = {};
  final Map<String, String> _playerNames = {};
  final Map<String, bool> _playerReady = {};
  final Stopwatch _clock = Stopwatch()..start();
  final ReconnectRegistry _reconnect = ReconnectRegistry();
  final StreamController<List<Map<String, Object?>>> _lobbyController =
      StreamController<List<Map<String, Object?>>>.broadcast();

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _httpSubscription;
  LanRoomBroadcaster? _broadcaster;
  late final String _sessionId;
  late final String _sessionCode;
  late final ExpiringToken _joinToken;
  late final MessageGuard _guard;
  final Map<String, int> _hostSequenceByPlayer = {};
  final Map<WebSocket, int> _hostSequenceBySocket = {};
  bool _closed = false;

  Stream<List<Map<String, Object?>>> get lobbyChanges =>
      _lobbyController.stream;

  List<Map<String, Object?>> get currentLobbyPlayers => _lobbyPlayers();

  int get playerCount => _socketPlayers.values.toSet().length;
  void announceGameStart(String gameId) {
    if (_server == null || _closed) {
      throw StateError('Host session is not active.');
    }
    if (gameId.trim().isEmpty) {
      throw ArgumentError.value(gameId, 'gameId', 'Game id cannot be empty.');
    }
    _broadcast(
      ProtocolTypes.gameStart,
      <String, Object?>{'gameId': gameId},
    );
  }

  Future<HostSessionInfo> start({InternetAddress? address}) async {
    if (_server != null) throw StateError('Server already started.');
    if (_closed) throw StateError('Server is already closed.');
    _sessionId = const Uuid().v4();
    _sessionCode = (100000 + Random.secure().nextInt(900000)).toString();
    _joinToken = _tokens.issue(lifetime: const Duration(hours: 8));
    _guard = MessageGuard(
      protocolVersion: protocolVersion,
      sessionId: _sessionId,
    );

    final bindAddress = address ?? InternetAddress.anyIPv4;
    try {
      _server = await HttpServer.bind(
        bindAddress,
        LanDiscoveryProtocol.defaultHostPort,
        shared: false,
      );
    } on SocketException {
      _server = await HttpServer.bind(bindAddress, 0, shared: false);
    }

    _httpSubscription = _server!.listen(
      _handleRequest,
      onError: (Object error, StackTrace stack) =>
          _logger.error('host.http', error, stack),
    );

    final info = HostSessionInfo(
      sessionId: _sessionId,
      sessionCode: _sessionCode,
      joinToken: _joinToken,
      port: _server!.port,
      roomName: _roomName,
    );
    final broadcaster = LanRoomBroadcaster(
      room: (address) => _roomAdvertisement(address),
    );
    _broadcaster = broadcaster;
    try {
      await broadcaster.start();
    } on Object catch (error, stack) {
      _logger.warning('host.discovery.unavailable', {'error': '$error'});
      _logger.debug('host.discovery.stack', {'stack': '$stack'});
    }

    _logger.info('host.started', {
      'sessionId': _sessionId,
      'port': _server!.port,
      'roomName': _roomName,
    });
    _publishLobby();
    return info;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _broadcaster?.close();
    _broadcaster = null;
    await _httpSubscription?.cancel();
    _httpSubscription = null;

    final sockets = _sockets.toList(growable: false);
    for (final socket in sockets) {
      await socket.close(WebSocketStatus.goingAway, 'session.closed');
    }
    final subscriptions = _socketSubscriptions.values.toList(growable: false);
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await _server?.close(force: true);
    _socketSubscriptions.clear();
    _socketPlayers.clear();
    _hostSequenceByPlayer.clear();
    _hostSequenceBySocket.clear();
    _sockets.clear();
    _players.clear();
    _playerNames.clear();
    _playerReady.clear();
    _server = null;
    await _lobbyController.close();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final remote = request.connectionInfo?.remoteAddress;
    if (remote == null ||
        !PrivateAddressPolicy.isAllowed(
          remote,
          developmentOverride: _developmentAddressOverride,
        )) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    if (request.uri.path == '/health') {
      final response = <String, Object?>{
        'ok': true,
        ..._roomAdvertisement(remote).toAnnouncementJson(),
      };
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
      return;
    }
    if (request.uri.path != '/ws') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    _sockets.add(socket);
    _socketSubscriptions[socket] = socket.listen(
      (data) => _handleSocketMessage(socket, data),
      onDone: () => _removeSocket(socket),
      onError: (Object error, StackTrace stack) {
        _removeSocket(socket);
        _logger.error('host.socket', error, stack);
      },
    );
  }

  void _removeSocket(WebSocket socket) {
    _socketSubscriptions.remove(socket);
    _socketPlayers.remove(socket);
    _hostSequenceBySocket.remove(socket);
    _sockets.remove(socket);
    _publishLobby();
  }

  void _handleSocketMessage(WebSocket socket, Object? data) {
    if (data is! String) {
      _sendError(socket, 'binary_not_supported');
      return;
    }

    final hostReceiveUs = _clock.elapsedMicroseconds;
    try {
      final envelope = ProtocolEnvelope.decode(data);
      final playerId = envelope.playerId;
      final joining = envelope.type == ProtocolTypes.lobbyJoin;
      final reconnecting = envelope.type == ProtocolTypes.reconnect;

      if (joining) {
        if (playerId == null || playerId.isEmpty) {
          _sendError(socket, 'player_required');
          return;
        }
        if (!_validJoinPayload(envelope.payload)) {
          _sendError(socket, 'join_denied');
          return;
        }
      }

      if (reconnecting && (playerId == null || playerId.isEmpty)) {
        _sendError(socket, 'player_required');
        return;
      }

      final validPlayers = joining && playerId != null
          ? {..._players, playerId}
          : _players;
      final rejection = _guard.validate(
        envelope,
        validPlayerIds: validPlayers,
      );
      if (rejection != null) {
        _sendError(socket, rejection.name);
        return;
      }

      if (joining && playerId != null) {
        _players.add(playerId);
        _playerNames[playerId] = envelope.payload['displayName'] as String;
        _playerReady[playerId] = false;
        _socketPlayers[socket] = playerId;
        _publishLobby();
      }

      switch (envelope.type) {
        case ProtocolTypes.ping:
          _send(
            socket,
            ProtocolTypes.pong,
            envelope.playerId,
            {
              'echoClientTimeUs': envelope.clientTimeUs,
              'hostReceiveUs': hostReceiveUs,
              'hostSendUs': _clock.elapsedMicroseconds,
            },
          );
          break;
        case ProtocolTypes.lobbyJoin:
          final resume = _reconnect.issue(
            envelope.playerId!,
            envelope.sequence,
          );
          _send(
            socket,
            ProtocolTypes.lobbyJoined,
            envelope.playerId,
            {
              'players': _lobbyPlayers(),
              'resumeToken': resume.token.value,
              'resumeExpiresAt': resume.token.expiresAt.toIso8601String(),
            },
          );
          _broadcast(
            ProtocolTypes.lobbySnapshot,
            {'players': _lobbyPlayers()},
          );
          break;
        case ProtocolTypes.lobbyReady:
          final ready = envelope.payload['ready'];
          if (ready is! bool || envelope.playerId == null) {
            _sendError(socket, 'invalid_ready_state');
            return;
          }
          _playerReady[envelope.playerId!] = ready;
          _publishLobby();
          _broadcast(
            ProtocolTypes.lobbySnapshot,
            {'players': _lobbyPlayers()},
          );
          break;
        case ProtocolTypes.lobbyLeave:
          final leavingPlayer = envelope.playerId;
          if (leavingPlayer != null) {
            _players.remove(leavingPlayer);
            _playerNames.remove(leavingPlayer);
            _playerReady.remove(leavingPlayer);
            _reconnect.revokePlayer(leavingPlayer);
            _socketPlayers.remove(socket);
            _publishLobby();
            _broadcast(
              ProtocolTypes.lobbySnapshot,
              {'players': _lobbyPlayers()},
            );
          }
          break;
        case ProtocolTypes.reconnect:
          final token = envelope.payload['resumeToken'];
          final record = token is String ? _reconnect.consume(token) : null;
          if (record == null || record.playerId != envelope.playerId) {
            _sendError(socket, 'resume_denied');
            return;
          }
          _socketPlayers[socket] = record.playerId;
          final renewed = _reconnect.issue(
            record.playerId,
            envelope.sequence,
          );
          _publishLobby();
          _send(
            socket,
            ProtocolTypes.reconnected,
            record.playerId,
            {
              'players': _lobbyPlayers(),
              'resumeToken': renewed.token.value,
              'resumeExpiresAt': renewed.token.expiresAt.toIso8601String(),
              'lastAcknowledgedClientSequence': envelope.sequence,
            },
          );
          break;
        default:
          _logger.debug('host.message.accepted', {
            'type': envelope.type,
            'sequence': envelope.sequence,
            'playerId': envelope.playerId,
          });
          break;
      }
    } on Object catch (error, stack) {
      _logger.error('host.message.invalid', error, stack);
      _sendError(socket, 'invalid_message');
    }
  }

  bool _validJoinPayload(Map<String, Object?> payload) {
    if (_joinToken.isExpired) return false;
    final displayName = payload['displayName'];
    return payload['sessionCode'] == _sessionCode &&
        payload['joinToken'] == _joinToken.value &&
        displayName is String &&
        displayName.trim().isNotEmpty &&
        displayName.runes.length <= 24;
  }

  LanRoom _roomAdvertisement(InternetAddress address) => LanRoom(
    address: address,
    port: _server!.port,
    sessionId: _sessionId,
    sessionCode: _sessionCode,
    joinToken: _joinToken.value,
    roomName: _roomName,
    playerCount: playerCount,
    tokenExpiresAt: _joinToken.expiresAt,
    lastSeenAt: DateTime.now(),
  );

  List<Map<String, Object?>> _lobbyPlayers() => _players
      .map(
        (id) => <String, Object?>{
          'playerId': id,
          'displayName': _playerNames[id] ?? 'بازیکن',
          'ready': _playerReady[id] ?? false,
          'connected': _socketPlayers.containsValue(id),
        },
      )
      .toList(growable: false);

  void _publishLobby() {
    if (!_lobbyController.isClosed) {
      _lobbyController.add(_lobbyPlayers());
    }
  }

  void _broadcast(String type, Map<String, Object?> payload) {
    for (final socket in _sockets.toList(growable: false)) {
      _send(socket, type, null, payload);
    }
  }

  void _sendError(WebSocket socket, String code) {
    _send(socket, ProtocolTypes.error, null, {'code': code});
  }

  void _send(
    WebSocket socket,
    String type,
    String? playerId,
    Map<String, Object?> payload,
  ) {
    final effectivePlayerId = playerId ?? _socketPlayers[socket];
    final sequence = effectivePlayerId == null
        ? (_hostSequenceBySocket[socket] ?? 0) + 1
        : (_hostSequenceByPlayer[effectivePlayerId] ?? 0) + 1;
    if (effectivePlayerId == null) {
      _hostSequenceBySocket[socket] = sequence;
    } else {
      _hostSequenceByPlayer[effectivePlayerId] = sequence;
    }
    socket.add(
      ProtocolEnvelope(
        protocolVersion: protocolVersion,
        messageId: const Uuid().v4(),
        sessionId: _sessionId,
        playerId: effectivePlayerId,
        sequence: sequence,
        clientTimeUs: _clock.elapsedMicroseconds,
        type: type,
        payload: payload,
      ).encode(),
    );
  }
}
