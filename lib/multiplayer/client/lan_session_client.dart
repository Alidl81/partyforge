import 'dart:async';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../clock_sync/clock_sync_service.dart';
import '../protocol/protocol_envelope.dart';
import '../security/private_address.dart';
import 'sequence_tracker.dart';

final class LanSessionClient {
  final Stopwatch _clock = Stopwatch()..start();
  final SequenceTracker _hostSequences = SequenceTracker();
  final StreamController<ProtocolEnvelope> _messages =
      StreamController<ProtocolEnvelope>.broadcast();
  final StreamController<void> _snapshotRequests =
      StreamController<void>.broadcast();
  final StreamController<ClockEstimate> _clockEstimates =
      StreamController<ClockEstimate>.broadcast();
  final ClockSyncService _clockSync = ClockSyncService();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _heartbeat;
  var _sequence = 0;
  String? _sessionId;
  String? _playerId;
  InternetAddress? _address;
  int? _port;
  String? _resumeToken;

  Stream<ProtocolEnvelope> get messages => _messages.stream;
  Stream<void> get snapshotRequests => _snapshotRequests.stream;
  Stream<ClockEstimate> get clockEstimates => _clockEstimates.stream;
  String? get resumeToken => _resumeToken;

  Future<void> connect({
    required InternetAddress address,
    required int port,
    required String sessionId,
    required String sessionCode,
    required String joinToken,
    required String playerId,
    required String displayName,
    bool developmentOverride = false,
  }) async {
    if (!PrivateAddressPolicy.isAllowed(
      address,
      developmentOverride: developmentOverride,
    )) {
      throw StateError('Only private or loopback LAN addresses are allowed.');
    }
    _sessionId = sessionId;
    _playerId = playerId;
    _address = address;
    _port = port;
    await _openSocket(address, port);
    send(
      ProtocolTypes.lobbyJoin,
      {
        'sessionCode': sessionCode,
        'joinToken': joinToken,
        'displayName': displayName,
      },
    );
    _startHeartbeat();
  }


  Future<void> reconnect() async {
    final address = _address;
    final port = _port;
    final sessionId = _sessionId;
    final playerId = _playerId;
    final token = _resumeToken;
    if (address == null ||
        port == null ||
        sessionId == null ||
        playerId == null ||
        token == null) {
      throw StateError('No resumable LAN session is available.');
    }
    await disconnectTransport();
    await _openSocket(address, port);
    send(
      ProtocolTypes.reconnect,
      {
        'resumeToken': token,
        'lastHostSequence': _hostSequences.last,
      },
    );
    _startHeartbeat();
  }

  Future<void> _openSocket(InternetAddress address, int port) async {
    _socket = await WebSocket.connect('ws://${address.address}:$port/ws');
    _socketSubscription = _socket!.listen(
      _handleIncoming,
      onError: (Object error, StackTrace stack) =>
          _messages.addError(error, stack),
    );
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_socket != null) send(ProtocolTypes.ping, const {});
    });
  }

  Future<void> disconnectTransport() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _socket?.close(WebSocketStatus.normalClosure, 'temporary_disconnect');
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket = null;
  }

  void send(String type, Map<String, Object?> payload) {
    final socket = _socket;
    final sessionId = _sessionId;
    final playerId = _playerId;
    if (socket == null || sessionId == null || playerId == null) {
      throw StateError('Client is not connected.');
    }
    socket.add(
      ProtocolEnvelope(
        protocolVersion: 1,
        messageId: const Uuid().v4(),
        sessionId: sessionId,
        playerId: playerId,
        sequence: ++_sequence,
        clientTimeUs: _clock.elapsedMicroseconds,
        type: type,
        payload: payload,
      ).encode(),
    );
  }

  void applySnapshotSequence(int sequence) {
    _hostSequences.resetFromSnapshot(sequence);
  }

  void _handleIncoming(Object? data) {
    if (data is! String) return;
    final envelope = ProtocolEnvelope.decode(data);
    if (envelope.type == ProtocolTypes.lobbyJoined ||
        envelope.type == ProtocolTypes.reconnected) {
      final token = envelope.payload['resumeToken'];
      if (token is String && token.isNotEmpty) _resumeToken = token;
    } else if (envelope.type == ProtocolTypes.pong) {
      final clientSendUs = envelope.payload['echoClientTimeUs'];
      final hostReceiveUs = envelope.payload['hostReceiveUs'];
      final hostSendUs = envelope.payload['hostSendUs'];
      if (clientSendUs is int &&
          hostReceiveUs is int &&
          hostSendUs is int) {
        final estimate = _clockSync.addSample(
          ClockSample(
            clientSendUs: clientSendUs,
            hostReceiveUs: hostReceiveUs,
            hostSendUs: hostSendUs,
            clientReceiveUs: _clock.elapsedMicroseconds,
          ),
        );
        if (estimate != null) _clockEstimates.add(estimate);
      }
    }
    switch (_hostSequences.accept(envelope.sequence)) {
      case SequenceStatus.accepted:
        _messages.add(envelope);
        break;
      case SequenceStatus.duplicateOrOld:
        break;
      case SequenceStatus.gap:
        _snapshotRequests.add(null);
        break;
    }
  }

  Future<void> close() async {
    await disconnectTransport();
    await _messages.close();
    await _snapshotRequests.close();
    await _clockEstimates.close();
  }
}
