#!/bin/bash
# DARB — iOS Release IPA Build Script
set -e

echo "🚗 [DARB] Starting iOS Release IPA Build..."

cd "$(dirname "$0")"

# 1. Clean and fetch dependencies
echo "📦 Resolving Flutter dependencies..."
flutter clean
flutter pub get

# 2. Build Release Bundle and Archive
echo "🔨 Building Flutter iOS Release Bundle..."
flutter build ios --release --no-codesign

# 3. Create Payload and package IPA
echo "📦 Packaging DARB.ipa..."
mkdir -p build/ios/ipa/Payload
if [ -d "build/ios/iphoneos/Runner.app" ]; then
    cp -r build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
elif [ -d "build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app" ]; then
    cp -r build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app build/ios/ipa/Payload/
fi

cd build/ios/ipa
zip -qr DARB.ipa Payload

echo "✅ [DARB] DARB.ipa successfully generated at apps/mobile/build/ios/ipa/DARB.ipa!"
echo "📲 Ready for installation via Sideloadly / AltStore / TrollStore or Apple Developer signing."
