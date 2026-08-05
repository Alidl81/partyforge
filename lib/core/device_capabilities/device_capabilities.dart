import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceCapabilitiesProvider = Provider<DeviceCapabilities>(
  (_) => throw StateError('DeviceCapabilities not initialized'),
);

final class DeviceCapabilities {
  const DeviceCapabilities({
    required this.touch,
    required this.mouse,
    required this.keyboard,
    required this.audio,
    required this.vibration,
    required this.camera,
    required this.localNetwork,
    required this.isWindows,
  });

  final bool touch;
  final bool mouse;
  final bool keyboard;
  final bool audio;
  final bool vibration;
  final bool camera;
  final bool localNetwork;
  final bool isWindows;
}

abstract final class DeviceCapabilitiesService {
  static Future<DeviceCapabilities> detect() async {
    final android = Platform.isAndroid;
    final windows = Platform.isWindows;
    return DeviceCapabilities(
      touch: android,
      mouse: windows,
      keyboard: windows,
      audio: true,
      vibration: android,
      camera: android,
      localNetwork: android || windows,
      isWindows: windows,
    );
  }
}
