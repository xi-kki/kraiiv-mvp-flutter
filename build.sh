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
if [ -n "$KRAIIV_API_URL" ]; then
  echo "==> Building with KRAIIV_API_URL=$KRAIIV_API_URL"
  flutter build web --release --dart-define=KRAIIV_API_URL="$KRAIIV_API_URL"
else
  echo "==> Building without API URL (offline matcher + keyword chat)"
  flutter build web --release
fi
echo "==> Build complete: build/web"
