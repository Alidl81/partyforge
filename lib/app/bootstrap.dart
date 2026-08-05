import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../core/device_capabilities/device_capabilities.dart';
import '../core/logging/app_logger.dart';
import '../data/database/app_database.dart';
import 'app.dart';

Future<void> bootstrap() async {
  final logger = DebugAppLogger();
  final capabilities = await DeviceCapabilitiesService.detect();

  if (capabilities.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      minimumSize: Size(960, 640),
      center: true,
      title: 'PartyForge',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final database = await AppDatabase.open();
  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [
          appLoggerProvider.overrideWithValue(logger),
          appDatabaseProvider.overrideWithValue(database),
          deviceCapabilitiesProvider.overrideWithValue(capabilities),
        ],
        child: const PartyForgeApp(),
      ),
    ),
    (error, stackTrace) => logger.error('uncaught', error, stackTrace),
  );
}
