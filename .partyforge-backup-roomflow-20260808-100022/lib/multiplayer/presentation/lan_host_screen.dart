import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/logging/app_logger.dart';
import '../../games/catalog/game_catalog.dart';
import '../../games/catalog/game_definition.dart';
import '../../shared_ui/widgets/party_scaffold.dart';
import '../host/host_session_server.dart';
import '../host/room_game_start_rules.dart';

class LanHostScreen extends ConsumerStatefulWidget {
  const LanHostScreen({super.key});

  @override
  ConsumerState<LanHostScreen> createState() => _LanHostScreenState();
}

class _LanHostScreenState extends ConsumerState<LanHostScreen> {
  HostSessionServer? _server;
  Future<HostSessionInfo>? _startup;
  StreamSubscription<List<Map<String, Object?>>>? _lobbySubscription;
  List<Map<String, Object?>> _players = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startup ??= _start();
  }

  Future<HostSessionInfo> _start() async {
    await _lobbySubscription?.cancel();
    final server = HostSessionServer(
      logger: ref.read(appLoggerProvider),
      roomName: 'اتاق PartyForge',
    );
    _server = server;

    final info = await server.start(address: InternetAddress.anyIPv4);
    _players = server.currentLobbyPlayers;

    _lobbySubscription = server.lobbyChanges.listen((players) {
      if (mounted) {
        setState(() => _players = players);
      }
    });

    return info;
  }

  Future<void> _retry() async {
    await _lobbySubscription?.cancel();
    _lobbySubscription = null;
    await _server?.close();

    if (!mounted) return;
    setState(() {
      _players = const [];
      _server = null;
      _startup = _start();
    });
  }

  int get _connectedClientCount =>
      _players.where((player) => player['connected'] == true).length;

  Future<void> _startGame(GameDefinition game) async {
    final server = _server;
    if (server == null) return;

    final check = RoomGameStartRules.check(
      game: game,
      connectedClients: _connectedClientCount,
    );

    if (!check.allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(check.message(game.title)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    server.announceGameStart(game.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${game.title}» برای همه شروع شد.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    await context.push<void>(game.playRoute);
  }

  @override
  void dispose() {
    unawaited(_lobbySubscription?.cancel());
    unawaited(_server?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PartyScaffold(
      title: 'انتخاب بازی برای اتاق',
      fallbackLocation: '/multiplayer',
      body: FutureBuilder<HostSessionInfo>(
        future: _startup,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorPanel(
              message: _friendlyError(snapshot.error!),
              onRetry: () => unawaited(_retry()),
            );
          }

          final info = snapshot.data;
          if (info == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final games = GameCatalog.games
              .where((game) => game.playRoute.startsWith('/games/'))
              .toList(growable: false);
          final participantCount = _connectedClientCount + 1;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _RoomHeader(
                code: info.sessionCode,
                participantCount: participantCount,
                players: _players,
              ),
              const SizedBox(height: 18),
              Text(
                'یک بازی را انتخاب کن',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'وقتی «شروع بازی» را بزنی، تعداد بازیکن‌ها بررسی می‌شود و در صورت کافی بودن، همان بازی روی دستگاه‌های متصل باز می‌شود.',
              ),
              const SizedBox(height: 16),
              for (final game in games) ...[
                _HostedGameCard(
                  game: game,
                  connectedClients: _connectedClientCount,
                  onInfo: () => context.push('/play/${game.id}/info'),
                  onStart: () => unawaited(_startGame(game)),
                ),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is SocketException) {
      return 'ساخت اتاق ممکن نشد. اتصال شبکه و دسترسی Firewall را بررسی کن.';
    }
    return 'راه‌اندازی اتاق ناموفق بود: $error';
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.code,
    required this.participantCount,
    required this.players,
  });

  final String code;
  final int participantCount;
  final List<Map<String, Object?>> players;

  @override
  Widget build(BuildContext context) {
    final connected = players
        .where((player) => player['connected'] == true)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_tethering_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اتاق فعال است',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.groups_2_rounded, size: 18),
                  label: Text('$participantCount نفر'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'کد ورود به اتاق',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 5),
            SelectableText(
              code,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 7,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Chip(
                  avatar: Icon(Icons.star_rounded, size: 18),
                  label: Text('میزبان (شما)'),
                ),
                for (final player in connected)
                  Chip(
                    avatar: const Icon(Icons.person_rounded, size: 18),
                    label: Text(
                      player['displayName']?.toString() ?? 'بازیکن',
                    ),
                  ),
              ],
            ),
            if (connected.isEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'هنوز کسی وارد نشده. نفرات دیگر در صفحه «پیوستن» همین اتاق را انتخاب کنند.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HostedGameCard extends StatelessWidget {
  const _HostedGameCard({
    required this.game,
    required this.connectedClients,
    required this.onInfo,
    required this.onStart,
  });

  final GameDefinition game;
  final int connectedClients;
  final VoidCallback onInfo;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final check = RoomGameStartRules.check(
      game: game,
      connectedClients: connectedClients,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(game.imageAsset, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xC8000000)],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 16,
                  end: 16,
                  bottom: 14,
                  child: Text(
                    game.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.shortDescription),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.groups_2_outlined, size: 18),
                      label: Text(
                        '${check.requiredMinimum} تا ${game.maximumPlayers} نفر در اتاق',
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        check.allowed
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_bottom_rounded,
                        size: 18,
                      ),
                      label: Text(
                        check.allowed
                            ? 'آمادهٔ شروع'
                            : check.shortMessage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onInfo,
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('اطلاعات'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('شروع بازی'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش دوباره'),
            ),
          ],
        ),
      ),
    );
  }
}
