$ErrorActionPreference = 'Stop'

$root = (Get-Location).Path

$required = @(
  'pubspec.yaml',
  'lib\multiplayer\presentation\lan_host_screen.dart',
  'lib\multiplayer\presentation\lan_join_screen.dart',
  'lib\multiplayer\host\room_game_start_rules.dart',
  'lib\multiplayer\host\host_session_server.dart',
  'test\multiplayer\room_game_start_rules_test.dart'
)

foreach ($relative in $required) {
    if (-not (Test-Path (Join-Path $root $relative))) {
        throw "Missing required file: $relative"
    }
}

$serverContent = [IO.File]::ReadAllText(
    (Join-Path $root 'lib\multiplayer\host\host_session_server.dart')
)
if ($serverContent -notmatch 'void\s+announceGameStart\s*\(') {
    throw 'HostSessionServer.announceGameStart was not applied.'
}

$joinContent = [IO.File]::ReadAllText(
    (Join-Path $root 'lib\multiplayer\presentation\lan_join_screen.dart')
)
if ($joinContent -notmatch 'ProtocolTypes\.gameStart') {
    throw 'Join screen does not listen for game.start.'
}

$hostScreenContent = [IO.File]::ReadAllText(
    (Join-Path $root 'lib\multiplayer\presentation\lan_host_screen.dart')
)
if ($hostScreenContent -notmatch 'شروع بازی') {
    throw 'Host game selection UI was not installed.'
}

if (Test-Path (Join-Path $root 'patch_payload')) {
    Write-Warning 'patch_payload هنوز در ریشه پروژه وجود دارد. قبل از git add آن را حذف کنید.'
}

Write-Host ''
Write-Host 'Room game-flow structural verification passed.' -ForegroundColor Green
Write-Host ''
Write-Host 'Next:' -ForegroundColor Cyan
Write-Host '  Remove-Item -Recurse -Force .\patch_payload -ErrorAction SilentlyContinue'
Write-Host '  git add -A'
Write-Host '  git status'