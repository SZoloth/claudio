#!/bin/bash
# Build script for Claudio

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

echo "🔨 Building Claudio..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the project
xcodebuild \
    -project "$PROJECT_DIR/Claudio.xcodeproj" \
    -scheme Claudio \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    build

# Find the built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "Claudio.app" -type d | head -1)

if [ -n "$APP_PATH" ]; then
    echo "✅ Build successful: $APP_PATH"

    # Copy to build directory
    cp -R "$APP_PATH" "$BUILD_DIR/"
    echo "📦 App copied to: $BUILD_DIR/Claudio.app"
else
    echo "❌ Build failed - app not found"
    exit 1
fi
