import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'lan_address_service.dart';
import 'lan_room.dart';

final class LanRoomDiscovery {
  final StreamController<List<LanRoom>> _roomsController =
      StreamController<List<LanRoom>>.broadcast();
  final Map<String, LanRoom> _rooms = {};

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _socketSubscription;
  Timer? _pruneTimer;
  bool _started = false;
  bool _scanning = false;
  DateTime? _lastSubnetScan;

  Stream<List<LanRoom>> get rooms => _roomsController.stream;

  List<LanRoom> get currentRooms => _sortedRooms();

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        LanDiscoveryProtocol.discoveryPort,
        reuseAddress: true,
      );
      _socketSubscription = _socket!.listen(_handleSocketEvent);
    } on SocketException {
      // Active subnet probing remains available when the UDP port is occupied.
      _socket = null;
    }
    _pruneTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _prune();
      final lastScan = _lastSubnetScan;
      if (_rooms.isEmpty &&
          !_scanning &&
          (lastScan == null ||
              DateTime.now().difference(lastScan) >
                  const Duration(seconds: 8))) {
        unawaited(scanNow());
      }
    });
    await scanNow();
  }

  Future<void> scanNow() async {
    if (_scanning) return;
    _scanning = true;
    _lastSubnetScan = DateTime.now();
    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 250);
    try {
      final addresses = await LanAddressService.privateIpv4Addresses();
      final candidates = <String>{'127.0.0.1'};
      for (final address in addresses) {
        final raw = address.rawAddress;
        if (raw.length != 4) continue;
        for (var host = 1; host < 255; host++) {
          final candidate = '${raw[0]}.${raw[1]}.${raw[2]}.$host';
          if (candidate != address.address) candidates.add(candidate);
        }
      }

      final all = candidates.toList(growable: false);
      const batchSize = 48;
      for (var offset = 0; offset < all.length; offset += batchSize) {
        final end = offset + batchSize < all.length
            ? offset + batchSize
            : all.length;
        await Future.wait(
          all
              .sublist(offset, end)
              .map((address) => _probe(client, InternetAddress(address))),
        );
      }
    } finally {
      client.close(force: true);
      _scanning = false;
      _prune();
    }
  }

  Future<LanRoom?> probeAddress(
    InternetAddress address, {
    int port = LanDiscoveryProtocol.defaultHostPort,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 1);
    try {
      return await _probe(client, address, port: port);
    } finally {
      client.close(force: true);
    }
  }

  LanRoom? findByCode(String code) {
    final normalized = code.replaceAll(RegExp(r'\D'), '');
    for (final room in _rooms.values) {
      if (room.sessionCode == normalized) return room;
    }
    return null;
  }

  Future<LanRoom?> _probe(
    HttpClient client,
    InternetAddress address, {
    int port = LanDiscoveryProtocol.defaultHostPort,
  }) async {
    try {
      final request = await client
          .getUrl(
            Uri(
              scheme: 'http',
              host: address.address,
              port: port,
              path: '/health',
            ),
          )
          .timeout(const Duration(milliseconds: 300));
      final response = await request.close().timeout(
        const Duration(milliseconds: 300),
      );
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(milliseconds: 300));
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final room = LanRoom.tryFromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
        sourceAddress: address,
      );
      if (room != null) _remember(room);
      return room;
    } on Object {
      return null;
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    Datagram? datagram;
    while ((datagram = _socket?.receive()) != null) {
      final current = datagram!;
      final room = LanRoom.tryDecode(
        utf8.decode(current.data, allowMalformed: true),
        sourceAddress: current.address,
      );
      if (room != null) _remember(room);
    }
  }

  void _remember(LanRoom room) {
    _rooms[room.id] = room;
    _emit();
  }

  void _prune() {
    final now = DateTime.now();
    final before = _rooms.length;
    _rooms.removeWhere((_, room) => !room.isAvailableAt(now));
    if (_rooms.length != before) _emit();
  }

  List<LanRoom> _sortedRooms() {
    final result = _rooms.values.toList(growable: false)
      ..sort((a, b) {
        final byName = a.roomName.compareTo(b.roomName);
        if (byName != 0) return byName;
        return a.address.address.compareTo(b.address.address);
      });
    return result;
  }

  void _emit() {
    if (!_roomsController.isClosed) {
      _roomsController.add(_sortedRooms());
    }
  }

  Future<void> close() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.close();
    _socket = null;
    await _roomsController.close();
  }
}
