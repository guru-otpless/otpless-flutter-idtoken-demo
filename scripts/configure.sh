#!/usr/bin/env bash
# Sets the OTPLESS App ID for the demo app on all platforms.
#
#   ./scripts/configure.sh YOUR_APP_ID
#
# Writes:
#   config/otpless_config.json    read by Dart (lib/config/otpless_config.dart)
#                                 and by android/app/build.gradle.kts for the
#                                 deep-link scheme  otpless.<appid lowercase>
#   ios/Flutter/Otpless.xcconfig  OTPLESS_APP_ID_LOWERCASE, used by Info.plist
#                                 for the URL scheme  otpless.<appid lowercase>
set -euo pipefail

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "Usage: $0 YOUR_APP_ID" >&2
  exit 1
fi

APP_ID="$1"
if [[ ! "$APP_ID" =~ ^[A-Za-z0-9]+$ ]]; then
  echo "App ID should contain only letters and digits, got: $APP_ID" >&2
  exit 1
fi
APP_ID_LOWER="$(echo "$APP_ID" | tr '[:upper:]' '[:lower:]')"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$ROOT/config"
printf '{ "appId": "%s" }\n' "$APP_ID" > "$ROOT/config/otpless_config.json"
printf 'OTPLESS_APP_ID_LOWERCASE = %s\n' "$APP_ID_LOWER" > "$ROOT/ios/Flutter/Otpless.xcconfig"

echo "OTPLESS App ID set to $APP_ID"
echo "  Deep-link scheme: otpless.$APP_ID_LOWER://otpless"
echo "Now run: flutter run"
