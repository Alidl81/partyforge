$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter SDK is required (recommended stable 3.44.7).'
}

flutter create --platforms=android,windows --org com.partyforge --project-name partyforge .
Copy-Item platform_overrides/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml -Force
New-Item -ItemType Directory -Force android/app/src/main/res/xml | Out-Null
Copy-Item platform_overrides/android/network_security_config.xml android/app/src/main/res/xml/network_security_config.xml -Force
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
