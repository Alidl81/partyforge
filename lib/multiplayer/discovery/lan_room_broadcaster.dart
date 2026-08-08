import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'lan_address_service.dart';
import 'lan_room.dart';

final class LanRoomBroadcaster {
  LanRoomBroadcaster({
    required this._room,
  });

  final LanRoom Function(InternetAddress address) _room;
  RawDatagramSocket? _socket;
  Timer? _timer;
  List<InternetAddress> _targets = const [];

  Future<void> start() async {
    if (_socket != null) return;
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    _socket = socket;
    _targets = await _broadcastTargets();
    _announce();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _announce());
  }

  void _announce() {
    final socket = _socket;
    if (socket == null) return;
    for (final target in _targets) {
      final room = _room(target);
      final packet = utf8.encode(room.encodeAnnouncement());
      try {
        socket.send(packet, target, LanDiscoveryProtocol.discoveryPort);
      } on Object {
        // One interface may reject broadcasts while another remains usable.
        continue;
      }
    }
  }

  Future<List<InternetAddress>> _broadcastTargets() async {
    final addresses = await LanAddressService.privateIpv4Addresses();
    final targetStrings = <String>{'255.255.255.255', '127.0.0.1'};
    for (final address in addresses) {
      final raw = address.rawAddress;
      if (raw.length == 4) {
        targetStrings.add('${raw[0]}.${raw[1]}.${raw[2]}.255');
      }
    }
    return targetStrings.map(InternetAddress.new).toList(growable: false);
  }

  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
    return Future<void>.value();
  }
}
