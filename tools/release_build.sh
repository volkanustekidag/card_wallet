#!/usr/bin/env bash
#
# Release build with Dart obfuscation.
#
# R8 already minifies Java/Kotlin in release (see android/app/build.gradle).
# But Dart source compiles to AOT bytecode that, by default, keeps every
# identifier readable in the binary — `_hasActiveSubscription`,
# `_lastSubscriptionProductId`, your premium check helpers, all visible
# to anyone with `strings` and 20 minutes. Adding `--obfuscate` rewrites
# those names; the original mapping is written to `--split-debug-info`
# so we can still symbolicate stack traces later.
#
# Symbol files MUST be retained per release. Without them, an obfuscated
# Crashlytics stack trace from a user in three months is unreadable.
# `symbols/` is gitignored — back it up to your private storage with the
# release tag, e.g. `symbols-2.0.0+30/`.
#
# Usage:
#   tools/release_build.sh android   # builds AAB
#   tools/release_build.sh ios       # builds IPA (requires --dart-define
#                                      env to be set if you also want
#                                      WALLET_EXPORT_* in the binary)
#   tools/release_build.sh both
#
# Pass any additional --dart-define flags via DART_DEFINES env var:
#   DART_DEFINES="--dart-define=WALLET_EXPORT_BASE_URL=https://...
#                 --dart-define=WALLET_EXPORT_API_KEY=..."
#   tools/release_build.sh both

set -euo pipefail

TARGET="${1:-both}"
SYMBOL_ROOT="symbols"
VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
SYMBOL_DIR="${SYMBOL_ROOT}/${VERSION}"
DART_DEFINES="${DART_DEFINES:-}"

mkdir -p "${SYMBOL_DIR}/android" "${SYMBOL_DIR}/ios"

build_android() {
  echo "==> Android AAB (obfuscated, symbols -> ${SYMBOL_DIR}/android)"
  # shellcheck disable=SC2086
  flutter build appbundle \
    --release \
    --obfuscate \
    --split-debug-info="${SYMBOL_DIR}/android" \
    ${DART_DEFINES}
  echo "    output: build/app/outputs/bundle/release/app-release.aab"
}

build_ios() {
  echo "==> iOS IPA (obfuscated, symbols -> ${SYMBOL_DIR}/ios)"
  # shellcheck disable=SC2086
  flutter build ipa \
    --release \
    --obfuscate \
    --split-debug-info="${SYMBOL_DIR}/ios" \
    ${DART_DEFINES}
  echo "    output: build/ios/ipa/*.ipa"
}

case "${TARGET}" in
  android) build_android ;;
  ios) build_ios ;;
  both) build_android; build_ios ;;
  *) echo "usage: $0 [android|ios|both]"; exit 1 ;;
esac

echo
echo "Symbols stored under: ${SYMBOL_DIR}"
echo "BACK THESE UP before shipping. Without them, obfuscated Crashlytics"
echo "stack traces from this release cannot be decoded."
