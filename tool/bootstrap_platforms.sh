#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required (recommended stable 3.44.7)." >&2
  exit 1
fi

flutter create --platforms=android,windows --org com.partyforge --project-name partyforge .
cp platform_overrides/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
mkdir -p android/app/src/main/res/xml
cp platform_overrides/android/network_security_config.xml android/app/src/main/res/xml/network_security_config.xml
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
