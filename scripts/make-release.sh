#!/usr/bin/env bash
# Build a signed Android App Bundle for Google Play.
# Requires android/key.properties + the upload keystore (see docs/PLAY_RELEASE.md).
set -euo pipefail
cd "$(dirname "$0")/.."
export JAVA_HOME="${JAVA_HOME:-$HOME/jdk17/Contents/Home}"
flutter build appbundle --release
echo ""
echo "AAB ready: build/app/outputs/bundle/release/app-release.aab"
