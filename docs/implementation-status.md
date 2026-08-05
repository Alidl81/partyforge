# Implementation status

This repository is an executable architectural slice of PartyForge. It intentionally distinguishes implemented behavior from planned product scope.

## Implemented

- Shared Flutter application shell with Material 3, Persian RTL default, responsive navigation, Windows window sizing, and capability diagnostics.
- Drift/SQLite schema creation and versioned migration entry point for all requested MVP tables.
- Concrete player, match, score-event, statistics, tournament, and settings repositories.
- Pure game contract, deterministic SplitMix64 random source, monotonic clocks, championship tie pooling, and seed-plus-command-log replay.
- Fully interactive local Chrono Lock screen with Flame rendering and deterministic scoring.
- Pure, tested rule engines for Hidden Fuse, Signal Snap, Ghost Trace, Word Forge, Shadow Path, Sketch Imposter, and Split Control.
- LAN host/client transport using `HttpServer` and WebSocket, private-address restriction, versioned envelopes, duplicate/sequence validation, expiring join tokens, lobby ready state, heartbeat, clock samples, sequence-gap notification, and one-time reconnect tokens.
- Android LAN manifest/network-security overrides and scripts that generate Android and Windows platform wrappers.
- Unit, repository, widget, integration, host/client loopback, reconnect, and artificial jitter tests.
- GitHub Actions jobs for analysis, tests, Android release APK, Windows release build, and artifact upload.

## Not yet product-complete

- Chrono Lock is the only mini-game with a complete presentation/application flow. The other seven games currently provide deterministic domain engines and tests, not finished game screens, assets, audio, or full match orchestration.
- Signal Snap has clock synchronization, host-side result resolution, and network simulation tests, but it is not yet wired into a complete LAN match screen.
- QR scanning/payload UI, mDNS, camera permission flow, tournaments/records/settings screens, audio mixing, vibration, reduced motion, golden tests, MSIX packaging, and release signing remain future work.
- Generated Android/Windows wrappers, Freezed output, and `pubspec.lock` must be produced with the bootstrap script in a provisioned Flutter environment.

## Verification performed in this workspace

`python3 tool/validate_source.py` passed and checked required files, relative references, assets, unfinished markers, wall-clock use in game code, and unseeded random constructors.

The workspace did not contain Flutter, Dart, Android SDK, or Windows build tools. Consequently, `dart format`, `flutter analyze`, `flutter test`, Android build, Windows build, and lockfile resolution were not executed here. CI and the bootstrap scripts are the authoritative build verification path.
