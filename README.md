# PartyForge

PartyForge is a deterministic offline and LAN party-game foundation for Android and Windows, built from a shared Flutter codebase. The initial runnable slice includes local profiles, SQLite persistence, a Persian RTL shell, a fully playable and persisted Chrono Lock round, host/client WebSocket sessions, clock synchronization, reconnect handling, protocol validation, and tested rule engines for several planned games.

## Current implementation

- Pure game-domain contract with seeded random and authoritative monotonic time.
- Chrono Lock local game flow with deterministic target generation, hidden timer, scoring, Match/Round/ScoreEvent persistence, reset, and tests.
- Hidden Fuse, Signal Snap, Ghost Trace, Word Forge, Shadow Path, Sketch Imposter role/vote rules, and Split Control input reduction.
- Drift `GeneratedDatabase` using `NativeDatabase.createInBackground` and explicit SQL migrations without generated table classes.
- Player profiles, matches, rounds, immutable score events, game statistics, tournaments, and settings persisted in SQLite repositories.
- Versioned WebSocket envelope, duplicate/sequence/player/session checks, private-address policy, lobby ready state, heartbeat, sequence-gap recovery signal, expiring join/resume tokens, and clock-offset estimator.
- Material 3, Persian RTL by default, English-ready locale list, responsive controls, Windows minimum window size, and diagnostics.
- CI definitions for analyze, tests, Android release APK, and Windows release artifact.

## Environment

Use Flutter stable 3.44.7 or a compatible newer stable release with Dart 3.12 or newer. Android Studio/SDK is required for Android builds. Visual Studio 2022 with **Desktop development with C++** is required for Windows builds.

This repository intentionally keeps platform wrappers reproducible. Generate them and generated Freezed/JSON files with one command:

### Linux/macOS

```bash
chmod +x tool/bootstrap_platforms.sh
./tool/bootstrap_platforms.sh
```

### Windows PowerShell

```powershell
./tool/bootstrap_platforms.ps1
```

The scripts run `flutter create`, apply the LAN Android manifest, resolve packages, run code generation, format, analyze, and test.

## Manual setup

```bash
flutter create --platforms=android,windows --org com.partyforge --project-name partyforge .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

For Android, copy the two files under `platform_overrides/android` after `flutter create`.

## Run

```bash
flutter run -d windows
flutter run -d <android-device-id>
```

## Build

```bash
flutter build apk --release
flutter build windows --release
```

The Windows command must run on Windows. Android signing secrets must be supplied outside the repository.


## جریان رابط کاربری

صفحهٔ خانه فقط گزینهٔ اصلی «بازی» و بخش‌های چندنفره، پروفایل و عیب‌یابی را نمایش می‌دهد. با انتخاب «بازی»، فهرست ۱۲ بازی باز می‌شود. هر کارت دارای تصویر، دکمهٔ شروع/اتصال و دکمهٔ اطلاعات است. تمام صفحه‌های غیرریشه دکمهٔ بازگشت قابل‌مشاهده و مسیر بازگشت امن دارند.

بازی‌های محلی قابل‌اجرا در این نسخه: Chrono Lock، Hidden Fuse، Ghost Trace، Word Forge، Memory Grid، Color Clash، Number Rush و Tap Storm.

## Architecture

```text
lib/
  app/                       app shell, theme, router, bootstrap
  core/                      errors, logging, random, timing, capabilities, domain
  data/                      Drift database and repository implementations
  multiplayer/               protocol, host, client, clock sync, reconnect, security
  games/<game>/              domain, application, presentation, engine
  shared_ui/                 shared screens and controls
```

Important decisions are documented in `docs/architecture`. See `docs/implementation-status.md` for the exact implemented/gap matrix and `docs/build-verification.md` for release checks.

## LAN flow

1. Host starts `HostSessionServer` on a free port.
2. Host creates a session code and short-lived cryptographic join token.
3. Client connects to a private IP and `/ws`, sends `lobby.join`, and registers identity.
4. Host validates the envelope, sequence, message ID, player ID, and command.
5. Host broadcasts authoritative lobby or game snapshots.
6. Client detects a sequence gap and requests a full snapshot.
7. A temporary disconnect can resume with an expiring token and acknowledged sequence.

## Troubleshooting

- **Flutter command not found:** install Flutter and add its `bin` directory to `PATH`.
- **Windows build fails:** install Visual Studio C++ desktop workload and Windows SDK.
- **Android cannot connect to LAN:** verify local-network permission, private IP, matching port/session, Wi-Fi isolation, and host firewall rules.
- **Generated files missing:** run `dart run build_runner build --delete-conflicting-outputs`.
- **SQLite native loading issue:** clean the build, run `flutter pub get`, and rebuild so `sqlite3` native assets are bundled.

## Source-only validation

```bash
python3 tool/validate_source.py
```

This check requires only Python and verifies required files, relative references, assets, determinism guardrails, and unfinished markers.

## Scope status

This is a substantial executable foundation, not the full eight-milestone product. The current environment used to assemble it did not contain Flutter, Dart, Android SDK, or Windows build tools, so `flutter analyze`, tests, lockfile resolution, and binary builds could not be executed here. CI and bootstrap scripts perform those checks in a correctly provisioned environment.
