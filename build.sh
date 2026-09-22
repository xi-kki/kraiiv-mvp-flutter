#!/bin/bash
# Kraiiv MVP — Flutter web build script for Vercel
# Downloads the Flutter SDK (cached in /vercel/.cache between builds),
# resolves dependencies, and builds the web release.
set -e

FLUTTER_CACHE="/vercel/.cache/flutter"
FLUTTER_BIN="$FLUTTER_CACHE/bin/flutter"

if [ ! -x "$FLUTTER_BIN" ]; then
  echo "==> Installing Flutter SDK (stable)..."
  mkdir -p "$FLUTTER_CACHE"
  # Latest stable = first release entry whose channel is "stable"
  VERSION=$(curl -s https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json \
    | grep -A2 '"channel": "stable"' \
    | grep -o '"version": "[^"]*"' | head -1 | cut -d'"' -f4)
  # Fallback if version detection fails
  if [ -z "$VERSION" ]; then
    VERSION="3.44.9"
    echo "==> Version detection failed, using pinned fallback: $VERSION"
  fi
  echo "==> Latest stable Flutter: $VERSION"
  curl -s -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${VERSION}-stable.tar.xz"
  tar xf /tmp/flutter.tar.xz -C "$FLUTTER_CACHE" --strip-components=1
  rm -f /tmp/flutter.tar.xz
else
  echo "==> Flutter SDK found in cache, reusing"
fi

export PATH="$FLUTTER_CACHE/bin:$PATH"
# Flutter SDK ships as a git repo; allow git to operate on it
if command -v git >/dev/null 2>&1; then
  git config --global --add safe.directory "$FLUTTER_CACHE" || true
fi
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version
flutter pub get
DEFINES=""
if [ -n "$KRAIIV_API_URL" ]; then
  echo "==> Building with KRAIIV_API_URL"
  DEFINES="$DEFINES --dart-define=KRAIIV_API_URL=$KRAIIV_API_URL"
fi
if [ -n "$STITCH_API_KEY" ]; then
  echo "==> Building with STITCH_API_KEY"
  DEFINES="$DEFINES --dart-define=STITCH_API_KEY=$STITCH_API_KEY"
fi
if [ -n "$ZBD_API_KEY" ]; then
  echo "==> Building with ZBD_API_KEY"
  DEFINES="$DEFINES --dart-define=ZBD_API_KEY=$ZBD_API_KEY"
fi
if [ -n "$BLINK_API_KEY" ]; then
  echo "==> Building with BLINK_API_KEY"
  DEFINES="$DEFINES --dart-define=BLINK_API_KEY=$BLINK_API_KEY"
fi
if [ -n "$BLINK_BTC_WALLET_ID" ]; then
  echo "==> Building with BLINK_BTC_WALLET_ID"
  DEFINES="$DEFINES --dart-define=BLINK_BTC_WALLET_ID=$BLINK_BTC_WALLET_ID"
fi
if [ -n "$BLINK_USD_WALLET_ID" ]; then
  echo "==> Building with BLINK_USD_WALLET_ID"
  DEFINES="$DEFINES --dart-define=BLINK_USD_WALLET_ID=$BLINK_USD_WALLET_ID"
fi
if [ -n "$VTPASS_API_KEY" ]; then
  echo "==> Building with VTPASS_API_KEY"
  DEFINES="$DEFINES --dart-define=VTPASS_API_KEY=$VTPASS_API_KEY"
fi
if [ -n "$BITREFILL_API_KEY" ]; then
  echo "==> Building with BITREFILL_API_KEY"
  DEFINES="$DEFINES --dart-define=BITREFILL_API_KEY=$BITREFILL_API_KEY"
fi

flutter build web --release $DEFINES
echo "==> Build complete: build/web"
