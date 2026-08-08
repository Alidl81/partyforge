$ErrorActionPreference = 'Stop'

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'این اسکریپت باید از ریشه پروژه PartyForge اجرا شود؛ همان پوشه‌ای که pubspec.yaml داخل آن است.'
}

$payload = Join-Path $root 'patch_payload'
if (-not (Test-Path $payload)) {
    throw 'پوشه patch_payload پیدا نشد. ZIP را کامل در ریشه پروژه Extract کنید.'
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $root ".partyforge-backup-roomflow-$timestamp"
New-Item -ItemType Directory -Path $backup -Force | Out-Null

$filesToBackup = @(
    'lib\multiplayer\presentation\lan_host_screen.dart',
    'lib\multiplayer\presentation\lan_join_screen.dart',
    'lib\multiplayer\host\host_session_server.dart'
)

foreach ($relative in $filesToBackup) {
    $source = Join-Path $root $relative
    if (Test-Path $source) {
        $destination = Join-Path $backup $relative
        New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
        Copy-Item $source $destination -Force
    }
}

$payloadFiles = Get-ChildItem -Path $payload -Recurse -File
foreach ($file in $payloadFiles) {
    $relative = $file.FullName.Substring($payload.Length).TrimStart('\', '/')
    $destination = Join-Path $root $relative
    New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
    Copy-Item $file.FullName $destination -Force
}

$serverPath = Join-Path $root 'lib\multiplayer\host\host_session_server.dart'
$server = [IO.File]::ReadAllText($serverPath)

if ($server -notmatch 'void\s+announceGameStart\s*\(') {
    $needle = '  int get playerCount => _socketPlayers.values.toSet().length;'
    if (-not $server.Contains($needle)) {
        throw 'محل مورد انتظار برای patch در HostSessionServer پیدا نشد. احتمالاً نسخه پروژه با این Patch متفاوت است.'
    }

    $method = @"

  void announceGameStart(String gameId) {
    if (_server == null || _closed) {
      throw StateError('Host session is not active.');
    }
    if (gameId.trim().isEmpty) {
      throw ArgumentError.value(gameId, 'gameId', 'Game id cannot be empty.');
    }
    _broadcast(
      ProtocolTypes.gameStart,
      <String, Object?>{'gameId': gameId},
    );
  }
"@

    $server = $server.Replace($needle, $needle + $method)
    [IO.File]::WriteAllText(
        $serverPath,
        $server,
        [Text.UTF8Encoding]::new($false)
    )
}

$protocolPath = Join-Path $root 'lib\multiplayer\protocol\protocol_envelope.dart'
$protocol = [IO.File]::ReadAllText($protocolPath)
if ($protocol -notmatch "static const gameStart = 'game\.start';") {
    throw 'ProtocolTypes.gameStart در این نسخه پروژه پیدا نشد؛ Patch متوقف شد.'
}

Write-Host ''
Write-Host 'PartyForge room game-flow patch applied successfully.' -ForegroundColor Green
Write-Host "Backup: $backup"
Write-Host ''
Write-Host 'Next commands:' -ForegroundColor Cyan
Write-Host '  git add .'
Write-Host '  git commit -m "Add host game selection and synchronized room start"'
Write-Host '  git push'
Write-Host ''
Write-Host 'Then start a NEW Build PartyForge workflow run.'
