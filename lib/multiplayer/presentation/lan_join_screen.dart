import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../shared_ui/widgets/party_scaffold.dart';
import '../client/lan_session_client.dart';
import '../discovery/lan_room.dart';
import '../discovery/lan_room_discovery.dart';
import '../protocol/protocol_envelope.dart';

class LanJoinScreen extends StatefulWidget {
  const LanJoinScreen({super.key});

  @override
  State<LanJoinScreen> createState() => _LanJoinScreenState();
}

class _LanJoinScreenState extends State<LanJoinScreen> {
  final _playerName = TextEditingController(text: 'بازیکن');
  final _manualAddress = TextEditingController();
  final _manualCode = TextEditingController();
  final LanRoomDiscovery _discovery = LanRoomDiscovery();

  StreamSubscription<List<LanRoom>>? _roomSubscription;
  StreamSubscription<ProtocolEnvelope>? _clientSubscription;
  LanSessionClient? _client;
  List<LanRoom> _rooms = const [];
  List<Map<String, Object?>> _players = const [];
  LanRoom? _connectedRoom;
  String? _connectingRoomId;
  String _status = 'در حال پیدا کردن اتاق‌های نزدیک…';
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _roomSubscription = _discovery.rooms.listen((rooms) {
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        if (rooms.isNotEmpty && _connectedRoom == null) {
          _status = '${rooms.length} اتاق پیدا شد.';
        }
      });
    });
    unawaited(_startDiscovery());
  }

  Future<void> _startDiscovery() async {
    try {
      await _discovery.start();
      if (!mounted) return;
      setState(() {
        _rooms = _discovery.currentRooms;
        _status = _rooms.isEmpty
            ? 'هنوز اتاقی پیدا نشده است.'
            : '${_rooms.length} اتاق پیدا شد.';
      });
    } on Object catch (error) {
      if (mounted) setState(() => _status = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _refresh() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _status = 'در حال جست‌وجوی دوباره…';
    });
    try {
      await _discovery.scanNow();
      if (!mounted) return;
      setState(() {
        _rooms = _discovery.currentRooms;
        _status = _rooms.isEmpty
            ? 'اتاقی پیدا نشد. اتصال Wi-Fi و Firewall میزبان را بررسی کنید.'
            : '${_rooms.length} اتاق پیدا شد.';
      });
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _join(LanRoom room) async {
    if (!mounted) return;
    final displayName = _playerName.text.trim();
    if (displayName.isEmpty) {
      setState(() => _status = 'لطفاً یک نام کوتاه برای خودت وارد کن.');
      return;
    }
    if (_connectingRoomId != null) return;

    setState(() {
      _connectingRoomId = room.id;
      _status = 'در حال ورود به ${room.roomName}…';
      _players = const [];
    });

    await _clientSubscription?.cancel();
    await _client?.close();
    if (!mounted) return;
    final client = LanSessionClient();
    _client = client;
    _clientSubscription = client.messages.listen(
      _handleClientMessage,
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _status = _friendlyError(error));
      },
    );

    try {
      await client.connect(
        address: room.address,
        port: room.port,
        sessionId: room.sessionId,
        sessionCode: room.sessionCode,
        joinToken: room.joinToken,
        playerId: const Uuid().v4(),
        displayName: displayName,
      );
      if (!mounted) return;
      setState(() {
        _connectedRoom = room;
        _status = 'با موفقیت وارد اتاق شدی.';
      });
    } on Object catch (error) {
      await _clientSubscription?.cancel();
      _clientSubscription = null;
      await client.close();
      if (!mounted) return;
      setState(() {
        _client = null;
        _connectedRoom = null;
        _status = _friendlyError(error);
      });
    } finally {
      if (mounted) setState(() => _connectingRoomId = null);
    }
  }

  void _handleClientMessage(ProtocolEnvelope message) {
    if (!mounted) return;
    switch (message.type) {
      case ProtocolTypes.lobbyJoined:
      case ProtocolTypes.lobbySnapshot:
      case ProtocolTypes.reconnected:
        setState(() {
          _players = _readPlayers(message.payload['players']);
          _status = message.type == ProtocolTypes.reconnected
              ? 'اتصال دوباره برقرار شد.'
              : 'به اتاق متصل هستی.';
        });
        break;
      case ProtocolTypes.error:
        setState(() {
          _status = _friendlyJoinCode(
            message.payload['code']?.toString() ?? 'unknown',
          );
        });
        break;
    }
  }

  List<Map<String, Object?>> _readPlayers(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _joinByCode() async {
    final code = _manualCode.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _status = 'کد اتاق باید شش رقم باشد.');
      return;
    }
    var room = _discovery.findByCode(code);
    if (room == null) {
      await _refresh();
      if (!mounted) return;
      room = _discovery.findByCode(code);
    }
    if (room == null) {
      if (mounted) {
        setState(() {
          _status = 'اتاقی با این کد در شبکه پیدا نشد.';
        });
      }
      return;
    }
    await _join(room);
  }

  Future<void> _joinByAddress() async {
    final address = InternetAddress.tryParse(_manualAddress.text.trim());
    if (address == null) {
      setState(() => _status = 'آدرس میزبان معتبر نیست.');
      return;
    }
    setState(() {
      _scanning = true;
      _status = 'در حال بررسی دستگاه میزبان…';
    });
    try {
      final room = await _discovery.probeAddress(address);
      if (room == null) {
        if (mounted) {
          setState(() {
            _status = 'روی این آدرس اتاق PartyForge پیدا نشد.';
          });
        }
        return;
      }
      final code = _manualCode.text.replaceAll(RegExp(r'\D'), '');
      if (code.isNotEmpty && code != room.sessionCode) {
        if (mounted) setState(() => _status = 'کد واردشده با این اتاق یکی نیست.');
        return;
      }
      if (!mounted) return;
      await _join(room);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _reconnect() async {
    final client = _client;
    if (client == null) return;
    setState(() => _status = 'در حال بازیابی اتصال…');
    try {
      await client.reconnect();
      if (mounted) setState(() => _status = 'اتصال دوباره برقرار شد.');
    } on Object catch (error) {
      if (mounted) setState(() => _status = _friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    if (error is LanJoinException) return _friendlyJoinCode(error.code);
    if (error is TimeoutException) {
      return 'میزبان پاسخ نداد. هر دو دستگاه باید روی یک Wi-Fi یا هات‌اسپات باشند.';
    }
    if (error is SocketException) {
      return 'اتصال شبکه برقرار نشد. Wi-Fi و Firewall دستگاه میزبان را بررسی کنید.';
    }
    return 'اتصال ناموفق بود: $error';
  }

  String _friendlyJoinCode(String code) => switch (code) {
    'join_denied' => 'اطلاعات اتاق منقضی شده است؛ فهرست را تازه‌سازی کن.',
    'invalidSession' => 'این اتاق دیگر فعال نیست؛ دوباره جست‌وجو کن.',
    'protocolMismatch' => 'نسخهٔ برنامه‌ها با هم سازگار نیست.',
    'resume_denied' => 'بازیابی اتصال ممکن نشد؛ دوباره وارد اتاق شو.',
    _ => 'میزبان اتصال را نپذیرفت ($code).',
  };

  @override
  void dispose() {
    unawaited(_roomSubscription?.cancel());
    unawaited(_clientSubscription?.cancel());
    unawaited(_client?.close());
    unawaited(_discovery.close());
    _playerName.dispose();
    _manualAddress.dispose();
    _manualCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectedRoom = _connectedRoom;
    return PartyScaffold(
      title: 'پیوستن به بازی',
      fallbackLocation: '/multiplayer',
      actions: [
        IconButton(
          tooltip: 'جست‌وجوی دوباره',
          onPressed: _scanning ? null : () => unawaited(_refresh()),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'ورود سریع به اتاق',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'هر دو دستگاه را به یک Wi-Fi یا هات‌اسپات وصل کن؛ اتاق‌ها خودکار نمایش داده می‌شوند.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _playerName,
              maxLength: 24,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'نام شما',
                prefixIcon: Icon(Icons.person_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            if (_scanning || _connectingRoomId != null) ...[
              const SizedBox(height: 4),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            if (connectedRoom != null)
              _ConnectedRoomCard(
                room: connectedRoom,
                players: _players,
                status: _status,
                onReconnect: () => unawaited(_reconnect()),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'اتاق‌های نزدیک',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('${_rooms.length} مورد'),
                ],
              ),
              const SizedBox(height: 10),
              if (_rooms.isEmpty)
                _EmptyRoomsPanel(
                  status: _status,
                  scanning: _scanning,
                  onRefresh: () => unawaited(_refresh()),
                )
              else
                for (final room in _rooms) ...[
                  _RoomCard(
                    room: room,
                    connecting: _connectingRoomId == room.id,
                    onJoin: () => unawaited(_join(room)),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 12),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('ورود با کد یا تنظیمات پیشرفته'),
                  subtitle: const Text('فقط وقتی اتاق خودکار دیده نمی‌شود'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    TextField(
                      controller: _manualCode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'کد شش‌رقمی اتاق',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _scanning
                            ? null
                            : () => unawaited(_joinByCode()),
                        icon: const Icon(Icons.numbers_rounded),
                        label: const Text('پیدا کردن با کد'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _manualAddress,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'IP میزبان (اختیاری)',
                        hintText: '192.168.1.20',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _scanning
                            ? null
                            : () => unawaited(_joinByAddress()),
                        icon: const Icon(Icons.router_rounded),
                        label: const Text('بررسی این آدرس'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.connecting,
    required this.onJoin,
  });

  final LanRoom room;
  final bool connecting;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: connecting ? null : onJoin,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.roomName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('${room.playerCount} بازیکن • آمادهٔ اتصال'),
                ],
              );
              if (constraints.maxWidth < 430) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.sports_esports_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: connecting ? null : onJoin,
                      child: Text(connecting ? 'در حال اتصال…' : 'پیوستن'),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    child: Icon(Icons.sports_esports_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: details),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: connecting ? null : onJoin,
                    child: Text(connecting ? 'اتصال…' : 'پیوستن'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyRoomsPanel extends StatelessWidget {
  const _EmptyRoomsPanel({
    required this.status,
    required this.scanning,
    required this.onRefresh,
  });

  final String status;
  final bool scanning;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              scanning ? Icons.wifi_find_rounded : Icons.wifi_off_rounded,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(status, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: scanning ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('جست‌وجوی دوباره'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedRoomCard extends StatelessWidget {
  const _ConnectedRoomCard({
    required this.room,
    required this.players,
    required this.status,
    required this.onReconnect,
  });

  final LanRoom room;
  final List<Map<String, Object?>> players;
  final String status;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_rounded, size: 64),
            const SizedBox(height: 10),
            Text(
              room.roomName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(status, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Text('بازیکن‌ها', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (players.isEmpty)
              const Text('در انتظار دریافت فهرست بازیکن‌ها…')
            else
              for (final player in players)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    player['displayName']?.toString() ?? 'بازیکن',
                  ),
                  trailing: Icon(
                    player['ready'] == true
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_bottom_rounded,
                  ),
                ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onReconnect,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('بازیابی اتصال'),
            ),
          ],
        ),
      ),
    );
  }
}
