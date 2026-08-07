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
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version
flutter pub get
flutter build web --release
echo "==> Build complete: build/web"
