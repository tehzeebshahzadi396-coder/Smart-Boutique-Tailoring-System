íí#!/bin/bash
set -e

echo "=== Vercel Flutter Web Build Started ==="

# 1. Check if Flutter SDK is already available in PATH
if ! command -v flutter &> /dev/null; then
  # 2. Check if cached Flutter directory exists, otherwise clone stable branch
  if [ ! -d "$HOME/flutter" ] && [ ! -d "flutter" ]; then
    echo "Cloning Flutter SDK (stable branch)..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  fi

  # Add Flutter to PATH (prefer $HOME/flutter)
  if [ -d "$HOME/flutter/bin" ]; then
    export PATH="$PATH:$HOME/flutter/bin"
  elif [ -d "flutter/bin" ]; then
    export PATH="$PATH:$(pwd)/flutter/bin"
  fi
fi

echo "Flutter version:"
flutter --version

echo "Configuring Flutter for Web..."
flutter config --enable-web --no-analytics

echo "Installing project dependencies..."
flutter pub get

echo "API_KEY=$API_KEY" > .env
echo "Building Flutter Web for Release..."
flutter build web --release --web-renderer canvaskit

echo "=== Build Contents ==="
ls -la build/web/

echo "=== Vercel Flutter Web Build Finished Successfully ==="
