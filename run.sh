#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$PROJECT_DIR/PDFFusion.xcodeproj"
SCHEME="PDFFusion"
CONFIG="Debug"

echo "🔨 Building PDF Fusion..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" build 2>&1 | tail -5

# Find the built app in DerivedData
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/PDFFusion-*/Build/Products/$CONFIG -name "PDF Fusion.app" -maxdepth 1 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Build failed — app not found"
    exit 1
fi

echo "🚀 Launching PDF Fusion..."
open "$APP_PATH"
echo "✅ Done!"
