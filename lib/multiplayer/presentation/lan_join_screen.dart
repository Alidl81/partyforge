import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../shared_ui/widgets/party_scaffold.dart';
import '../client/lan_session_client.dart';
import '../protocol/protocol_envelope.dart';

class LanJoinScreen extends StatefulWidget {
  const LanJoinScreen({super.key});

  @override
  State<LanJoinScreen> createState() => _LanJoinScreenState();
}

class _LanJoinScreenState extends State<LanJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ip = TextEditingController();
  final _port = TextEditingController();
  final _sessionId = TextEditingController();
  final _sessionCode = TextEditingController();
  final _joinToken = TextEditingController();
  final _playerName = TextEditingController(text: 'بازیکن');

  LanSessionClient? _client;
  StreamSubscription<ProtocolEnvelope>? _subscription;
  String _status = 'اطلاعات اتاق را وارد کنید.';
  bool _connecting = false;
  bool _canReconnect = false;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_client?.close());
    _ip.dispose();
    _port.dispose();
    _sessionId.dispose();
    _sessionCode.dispose();
    _joinToken.dispose();
    _playerName.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _connecting = true;
      _status = 'در حال اتصال…';
      _canReconnect = false;
    });

    await _subscription?.cancel();
    await _client?.close();
    final client = LanSessionClient();
    _client = client;
    _subscription = client.messages.listen(
      (message) {
        if (!mounted) return;
        setState(() {
          if (message.type == ProtocolTypes.lobbyJoined ||
              message.type == ProtocolTypes.reconnected) {
            _canReconnect = true;
          }
          _status = switch (message.type) {
            ProtocolTypes.lobbyJoined => 'با موفقیت وارد Lobby شدید.',
            ProtocolTypes.reconnected => 'اتصال قبلی با موفقیت بازیابی شد.',
            ProtocolTypes.lobbySnapshot =>
              'Snapshot دریافت شد: ${(message.payload['players'] as List?)?.length ?? 0} بازیکن',
            ProtocolTypes.error =>
              'Host پیام را رد کرد: ${message.payload['code'] ?? 'خطای نامشخص'}',
            _ => 'پیام دریافت شد: ${message.type}',
          };
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _status = 'ارتباط قطع شد: $error');
      },
    );

    try {
      final address = InternetAddress.tryParse(_ip.text.trim());
      if (address == null) throw const FormatException('IP نامعتبر است.');
      await client.connect(
        address: address,
        port: int.parse(_port.text.trim()),
        sessionId: _sessionId.text.trim(),
        sessionCode: _sessionCode.text.trim(),
        joinToken: _joinToken.text.trim(),
        playerId: const Uuid().v4(),
        displayName: _playerName.text.trim(),
      );
      if (mounted) {
        setState(() => _status = 'اتصال برقرار شد؛ در انتظار تأیید Host…');
      }
    } on Object catch (error) {
      await client.close();
      if (mounted) {
        setState(() {
          _canReconnect = false;
          _status = _friendlyError(error);
        });
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _reconnect() async {
    final client = _client;
    if (client == null || !_canReconnect) return;
    setState(() {
      _connecting = true;
      _status = 'در حال بازیابی اتصال…';
    });
    try {
      await client.reconnect();
      if (mounted) {
        setState(() => _status = 'در انتظار تأیید بازیابی از Host…');
      }
    } on Object catch (error) {
      if (mounted) setState(() => _status = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is SocketException) {
      return 'اتصال شبکه برقرار نشد. IP، Port، Firewall و اتصال Wi-Fi را بررسی کنید.';
    }
    if (error is FormatException) return error.message.toString();
    return 'اتصال ناموفق بود: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const PartyBackButton(fallbackLocation: '/multiplayer'),
        title: const Text('پیوستن به اتاق'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _field(_ip, 'IP خصوصی Host', hint: '192.168.1.20'),
            _field(_port, 'Port', keyboardType: TextInputType.number),
            _field(_sessionId, 'Session ID'),
            _field(
              _sessionCode,
              'کد شش‌رقمی جلسه',
              keyboardType: TextInputType.number,
            ),
            _field(_joinToken, 'Join Token'),
            _field(_playerName, 'نام نمایشی بازیکن'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _connecting ? null : _connect,
              icon: const Icon(Icons.login),
              label: Text(_connecting ? 'در حال اتصال' : 'اتصال'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _connecting || !_canReconnect
                  ? null
                  : () => unawaited(_reconnect()),
              icon: const Icon(Icons.sync),
              label: const Text('بازیابی اتصال قبلی'),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'این فیلد الزامی است.'
            : null,
      ),
    );
  }
}
