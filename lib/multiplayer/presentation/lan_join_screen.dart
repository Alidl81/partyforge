import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../games/catalog/game_catalog.dart';
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
  final _manualCode = TextEditingController();
  final LanRoomDiscovery _discovery = LanRoomDiscovery();

  StreamSubscription<List<LanRoom>>? _roomSubscription;
  StreamSubscription<ProtocolEnvelope>? _clientSubscription;
  LanSessionClient? _client;

  List<LanRoom> _rooms = const [];
  List<Map<String, Object?>> _players = const [];
  LanRoom? _connectedRoom;
  String? _connectingRoomId;
  String? _activeGameId;
  String _status = 'در حال پیدا کردن اتاق‌های نزدیک…';
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    _roomSubscription = _discovery.rooms.listen((rooms) {
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        if (_connectedRoom == null) {
          _status = rooms.isEmpty
              ? 'هنوز اتاقی پیدا نشده است.'
              : '${rooms.length} اتاق پیدا شد.';
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
      if (mounted) {
        setState(() => _status = _friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
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
            ? 'اتاقی پیدا نشد. هر دو دستگاه باید روی یک Wi-Fi یا هات‌اسپات باشند.'
            : '${_rooms.length} اتاق پیدا شد.';
      });
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  Future<void> _join(LanRoom room) async {
    final displayName = _playerName.text.trim();
    if (displayName.isEmpty) {
      setState(() => _status = 'یک نام کوتاه برای خودت وارد کن.');
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

    final client = LanSessionClient();
    _client = client;
    _clientSubscription = client.messages.listen(
      _handleClientMessage,
      onError: (Object error) {
        if (mounted) {
          setState(() => _status = _friendlyError(error));
        }
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
        _status = 'وارد اتاق شدی؛ منتظر میزبان برای شروع بازی باش.';
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
      if (mounted) {
        setState(() => _connectingRoomId = null);
      }
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
              ? 'اتصال دوباره برقرار شد؛ منتظر میزبان باش.'
              : 'به اتاق متصل هستی؛ منتظر میزبان برای شروع بازی باش.';
        });
        break;

      case ProtocolTypes.gameStart:
        final gameId = message.payload['gameId']?.toString();
        final game = gameId == null ? null : GameCatalog.find(gameId);

        if (game == null || !game.playRoute.startsWith('/games/')) {
          setState(() {
            _status =
                'میزبان بازی‌ای را شروع کرد که این نسخه صفحهٔ اجرای آن را ندارد.';
          });
          break;
        }

        if (_activeGameId != null) break;
        _activeGameId = game.id;
        setState(() => _status = 'میزبان «${game.title}» را شروع کرد…');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _activeGameId != game.id) return;
          unawaited(
            context.push<Object?>(game.playRoute).then<void>((_) {
              if (!mounted || _activeGameId != game.id) return;
              setState(() {
                _activeGameId = null;
                _status = 'به اتاق برگشتی؛ منتظر شروع بازی بعدی باش.';
              });
            }),
          );
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
      setState(() => _status = 'اتاقی با این کد روی شبکه پیدا نشد.');
      return;
    }

    await _join(room);
  }

  Future<void> _reconnect() async {
    final client = _client;
    if (client == null) return;

    setState(() => _status = 'در حال بازیابی اتصال…');
    try {
      await client.reconnect();
      if (mounted) {
        setState(() {
          _status = 'اتصال دوباره برقرار شد؛ منتظر میزبان باش.';
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _status = _friendlyError(error));
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is LanJoinException) {
      return _friendlyJoinCode(error.code);
    }
    if (error is TimeoutException) {
      return 'میزبان پاسخ نداد. هر دو دستگاه باید روی یک Wi-Fi یا هات‌اسپات باشند.';
    }
    if (error is SocketException) {
      return 'اتصال شبکه برقرار نشد. Wi-Fi و Firewall دستگاه میزبان را بررسی کن.';
    }
    return 'اتصال ناموفق بود: $error';
  }

  String _friendlyJoinCode(String code) => switch (code) {
        'join_denied' => 'اطلاعات اتاق منقضی شده؛ فهرست را تازه‌سازی کن.',
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
    _manualCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectedRoom = _connectedRoom;

    return PartyScaffold(
      title: connectedRoom == null ? 'پیوستن به اتاق' : 'داخل اتاق',
      fallbackLocation: '/multiplayer',
      actions: [
        if (connectedRoom == null)
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
          padding: const EdgeInsets.all(18),
          children: [
            if (connectedRoom == null) ...[
              Text(
                'ورود سریع',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'اتاق را از لیست انتخاب کن. فقط اگر اتاق پیدا نشد، کد شش‌رقمی را وارد کن.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _playerName,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: 'نام شما',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              if (_scanning || _connectingRoomId != null)
                const LinearProgressIndicator(),
              const SizedBox(height: 14),
              Text(
                'اتاق‌های نزدیک',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (_rooms.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 44),
                        const SizedBox(height: 8),
                        Text(_status, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed:
                              _scanning ? null : () => unawaited(_refresh()),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('جست‌وجوی دوباره'),
                        ),
                      ],
                    ),
                  ),
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
              const SizedBox(height: 8),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.numbers_rounded),
                  title: const Text('ورود با کد'),
                  subtitle: const Text('فقط وقتی اتاق در لیست دیده نمی‌شود'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    TextField(
                      controller: _manualCode,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'کد شش‌رقمی اتاق',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _scanning ? null : () => unawaited(_joinByCode()),
                        child: const Text('پیوستن'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _ConnectedRoomCard(
                room: connectedRoom,
                players: _players,
                status: _status,
                onReconnect: () => unawaited(_reconnect()),
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
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.sports_esports_rounded),
        ),
        title: Text(room.roomName),
        subtitle: Text(
          'کد ${room.sessionCode}  •  ${room.playerCount + 1} بازیکن',
          textDirection: TextDirection.rtl,
        ),
        trailing: FilledButton(
          onPressed: connecting ? null : onJoin,
          child: Text(connecting ? '...' : 'پیوستن'),
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
    final connectedPlayers =
        players.where((player) => player['connected'] == true).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_rounded, size: 52),
            const SizedBox(height: 10),
            Text(
              room.roomName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'کد اتاق: ${room.sessionCode}',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            Text(
              status,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            Text(
              'بازیکن‌های متصل',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Chip(
                  avatar: Icon(Icons.star_rounded, size: 18),
                  label: Text('میزبان'),
                ),
                for (final player in connectedPlayers)
                  Chip(
                    avatar: const Icon(Icons.person_rounded, size: 18),
                    label: Text(
                      player['displayName']?.toString() ?? 'بازیکن',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
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
