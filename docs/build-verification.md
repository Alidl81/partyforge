# Build verification checklist

Run from the repository root on a machine with Flutter stable installed.

```bash
flutter doctor -v
./tool/bootstrap_platforms.sh
flutter build apk --release
```

Run the Windows build on Windows with Visual Studio's **Desktop development with C++** workload:

```powershell
flutter doctor -v
./tool/bootstrap_platforms.ps1
flutter build windows --release
```

Expected generated files include `android/`, `windows/`, `pubspec.lock`, `lib/multiplayer/protocol/lobby_snapshot.freezed.dart`, and `lib/multiplayer/protocol/lobby_snapshot.g.dart`.

Before release, verify:

- Android and Windows host/client join over a private LAN.
- Firewall-denied and local-network-permission-denied paths show recoverable UI.
- Seven or more ping/pong samples produce a stable clock estimate.
- A temporary transport disconnect can consume a resume token and receive `session.reconnected`.
- Release logs do not contain join/resume tokens or private role data.
- Signing material is provided outside the repository.
