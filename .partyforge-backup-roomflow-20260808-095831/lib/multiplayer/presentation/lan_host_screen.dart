import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../shared_ui/widgets/party_scaffold.dart';
import '../discovery/lan_address_service.dart';
import '../host/host_session_server.dart';

class LanHostScreen extends ConsumerStatefulWidget {
  const LanHostScreen({super.key});

  @override
  ConsumerState<LanHostScreen> createState() => _LanHostScreenState();
}

class _LanHostScreenState extends ConsumerState<LanHostScreen> {
  HostSessionServer? _server;
  Future<_HostViewData>? _startup;
  StreamSubscription<List<Map<String, Object?>>>? _lobbySubscription;
  List<Map<String, Object?>> _players = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startup ??= _start();
  }

  Future<_HostViewData> _start() async {
    await _lobbySubscription?.cancel();
    final server = HostSessionServer(
      logger: ref.read(appLoggerProvider),
      roomName: 'اتاق PartyForge',
    );
    _server = server;
    final info = await server.start(address: InternetAddress.anyIPv4);
    _players = server.currentLobbyPlayers;
    _lobbySubscription = server.lobbyChanges.listen((players) {
      if (mounted) setState(() => _players = players);
    });
    final addresses = await LanAddressService.privateIpv4Addresses();
    return _HostViewData(info: info, addresses: addresses);
  }

  Future<void> _retry() async {
    await _lobbySubscription?.cancel();
    _lobbySubscription = null;
    await _server?.close();
    if (!mounted) return;
    setState(() {
      _players = const [];
      _startup = _start();
    });
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کد اتاق کپی شد.')),
    );
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
      title: 'اتاق من',
      fallbackLocation: '/multiplayer',
      body: FutureBuilder<_HostViewData>(
        future: _startup,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorPanel(
              message: _friendlyError(snapshot.error!),
              onRetry: () => unawaited(_retry()),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_tethering_rounded, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'اتاق آماده است',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'در دستگاه‌های دیگر فقط «پیوستن» را بزنید؛ این اتاق خودکار نمایش داده می‌شود.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        data.info.sessionCode,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('کد پشتیبان اتاق'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => unawaited(
                          _copyCode(data.info.sessionCode),
                        ),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('کپی کد'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'بازیکن‌ها',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('${_players.length} نفر'),
                ],
              ),
              const SizedBox(height: 8),
              if (_players.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48),
                        SizedBox(height: 10),
                        Text(
                          'در انتظار بازیکن‌ها…',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'همهٔ دستگاه‌ها باید روی یک Wi-Fi یا هات‌اسپات باشند.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final player in _players)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          player['connected'] == true
                              ? Icons.person_rounded
                              : Icons.person_off_rounded,
                        ),
                      ),
                      title: Text(
                        player['displayName']?.toString() ?? 'بازیکن',
                      ),
                      subtitle: Text(
                        player['connected'] == true
                            ? 'متصل'
                            : 'اتصال موقتاً قطع شده',
                      ),
                      trailing: Icon(
                        player['ready'] == true
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_bottom_rounded,
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.settings_ethernet_rounded),
                  title: const Text('جزئیات فنی'),
                  subtitle: const Text('معمولاً به این بخش نیازی نیست'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _TechnicalRow(
                      label: 'IP میزبان',
                      value: data.addresses.isEmpty
                          ? 'پیدا نشد'
                          : data.addresses.map((e) => e.address).join('، '),
                    ),
                    _TechnicalRow(
                      label: 'Port',
                      value: data.info.port.toString(),
                    ),
                    _TechnicalRow(
                      label: 'Session ID',
                      value: data.info.sessionId,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'در Windows ممکن است بار اول پنجرهٔ Firewall نمایش داده شود؛ گزینهٔ Allow access برای شبکهٔ خصوصی را تأیید کنید.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is SocketException) {
      return 'ساخت اتاق ممکن نشد. اتصال شبکه و دسترسی Firewall را بررسی کنید.';
    }
    return 'راه‌اندازی اتاق ناموفق بود: $error';
  }
}

final class _HostViewData {
  const _HostViewData({required this.info, required this.addresses});

  final HostSessionInfo info;
  final List<InternetAddress> addresses;
}

class _TechnicalRow extends StatelessWidget {
  const _TechnicalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: SelectableText(
              value,
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش دوباره'),
          ),
        ],
      ),
    ),
  );
}
