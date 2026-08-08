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

$server = [IO.File]::ReadAllText((Join-Path $root 'lib\multiplayer\host\host_session_server.dart'))
if ($server -notmatch 'void\s+announceGameStart\s*\(') {
    throw 'HostSessionServer.announceGameStart was not applied.'
}

$join = [IO.File]::ReadAllText((Join-Path $root 'lib\multiplayer\presentation\lan_join_screen.dart'))
if ($join -notmatch 'ProtocolTypes\.gameStart') {
    throw 'Join screen does not listen for game.start.'
}

$host = [IO.File]::ReadAllText((Join-Path $root 'lib\multiplayer\presentation\lan_host_screen.dart'))
if ($host -notmatch 'شروع بازی') {
    throw 'Host game selection UI was not installed.'
}

Write-Host 'Room game-flow structural verification passed.' -ForegroundColor Green
