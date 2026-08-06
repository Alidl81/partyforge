import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device_capabilities/device_capabilities.dart';
import '../widgets/party_scaffold.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(deviceCapabilitiesProvider);
    final entries = {
      'لمس': c.touch,
      'ماوس': c.mouse,
      'صفحه‌کلید': c.keyboard,
      'صدا': c.audio,
      'لرزش': c.vibration,
      'دوربین': c.camera,
      'شبکهٔ محلی': c.localNetwork,
    };
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const PartyBackButton(fallbackLocation: '/'),
        title: const Text('عیب‌یابی'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: entries.entries.map((entry) => ListTile(
          leading: Icon(entry.value ? Icons.check_circle : Icons.cancel_outlined),
          title: Text(entry.key),
          trailing: Text(entry.value ? 'در دسترس' : 'در دسترس نیست'),
        )).toList(growable: false),
      ),
    );
  }
}
