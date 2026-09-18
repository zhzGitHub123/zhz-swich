#!/bin/zsh
# 用 SwiftPM 编译并组装成 build/Z-Swich.app（ad-hoc 签名，本机可直接运行）。
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
LOG="$(mktemp)"
if ! swift build -c "$CONFIG" --product ZSwich -Xlinker -dead_strip >"$LOG" 2>&1; then
  grep -E "error:|warning:" "$LOG" | head -30
  echo "编译失败，完整日志：$LOG"
  exit 1
fi
tail -1 "$LOG"; rm -f "$LOG"

APP="build/Z-Swich.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/$CONFIG/ZSwich" "$APP/Contents/MacOS/Z-Swich"
cp Packaging/Info.plist "$APP/Contents/Info.plist"
swift scripts/generate-icon.swift >/dev/null
cp Assets/AppIcon/Z-Swich.icns "$APP/Contents/Resources/Z-Swich.icns"
strip "$APP/Contents/MacOS/Z-Swich"
codesign --force --sign - "$APP" >/dev/null
echo "已生成 $PWD/$APP"
