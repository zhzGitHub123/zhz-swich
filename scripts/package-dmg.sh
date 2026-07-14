#!/usr/bin/env bash
set -euo pipefail

APP_NAME="zhz swich"
VERSION="0.1.0"
PROJECT_NAME="ZhzSwitch.xcodeproj"
SCHEME_NAME="ZhzSwitchApp"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
DERIVED_DATA_DIR="$BUILD_DIR/xcode-derived"
DIST_DIR="$ROOT_DIR/dist"
XCODE_APP_BUNDLE="$DERIVED_DATA_DIR/Build/Products/Release/$APP_NAME.app"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_ROOT="$DIST_DIR/dmg-root"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

build_release() {
    xcodebuild \
        -project "$PROJECT_NAME" \
        -scheme "$SCHEME_NAME" \
        -configuration Release \
        -derivedDataPath "$DERIVED_DATA_DIR" \
        -destination "platform=macOS,arch=arm64" \
        build
}

reset_dist() {
    rm -rf "$DIST_DIR"
    mkdir -p "$DMG_ROOT"
}

assemble_app() {
    ditto "$XCODE_APP_BUNDLE" "$APP_BUNDLE"
}

sign_app() {
    codesign --force --deep --sign - "$APP_BUNDLE"
    codesign --verify --deep --strict "$APP_BUNDLE"
}

create_dmg() {
    cp -R "$APP_BUNDLE" "$DMG_ROOT/"
    ln -s /Applications "$DMG_ROOT/Applications"
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$DMG_ROOT" \
        -ov \
        -format UDZO \
        "$DMG_PATH"
    hdiutil verify "$DMG_PATH"
}

main() {
    cd "$ROOT_DIR"
    build_release
    reset_dist
    assemble_app
    sign_app
    create_dmg
    echo "$DMG_PATH"
}

main "$@"
