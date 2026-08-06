import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../discovery/lan_address_service.dart';
import '../../shared_ui/widgets/party_scaffold.dart';
import '../host/host_session_server.dart';

class LanHostScreen extends ConsumerStatefulWidget {
  const LanHostScreen({super.key});

  @override
  ConsumerState<LanHostScreen> createState() => _LanHostScreenState();
}

class _LanHostScreenState extends ConsumerState<LanHostScreen> {
  HostSessionServer? _server;
  Future<_HostViewData>? _startup;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startup ??= _start();
  }

  Future<_HostViewData> _start() async {
    final server = HostSessionServer(logger: ref.read(appLoggerProvider));
    _server = server;
    final info = await server.start(address: InternetAddress.anyIPv4);
    final addresses = await LanAddressService.privateIpv4Addresses();
    return _HostViewData(info: info, addresses: addresses);
  }


  Future<void> _retry() async {
    await _server?.close();
    if (!mounted) return;
    setState(() => _startup = _start());
  }

  @override
  void dispose() {
    unawaited(_server?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const PartyBackButton(fallbackLocation: '/multiplayer'),
        title: const Text('ایجاد اتاق LAN'),
      ),
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
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'اتاق آماده است',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              _InfoCard(label: 'کد جلسه', value: data.info.sessionCode),
              _InfoCard(label: 'Port', value: data.info.port.toString()),
              _InfoCard(label: 'Session ID', value: data.info.sessionId),
              _InfoCard(
                label: 'Join Token موقت',
                value: data.info.joinToken.value,
              ),
              _InfoCard(
                label: 'IPهای خصوصی میزبان',
                value: data.addresses.isEmpty
                    ? 'IP خصوصی پیدا نشد؛ تنظیمات شبکه و Firewall را بررسی کنید.'
                    : data.addresses.map((e) => e.address).join('\n'),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Token فقط برای مدت کوتاهی معتبر است. برای اتصال، Client باید IP، Port، Session ID، کد جلسه و Token را وارد کند.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is SocketException) {
      return 'بازکردن Port شبکه ممکن نشد. دسترسی Firewall یا محدودیت Socket را بررسی کنید.';
    }
    return 'راه‌اندازی اتاق ناموفق بود: $error';
  }
}

final class _HostViewData {
  const _HostViewData({required this.info, required this.addresses});
  final HostSessionInfo info;
  final List<InternetAddress> addresses;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SelectableText(value, textDirection: TextDirection.ltr),
        ],
      ),
    ),
  );
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
