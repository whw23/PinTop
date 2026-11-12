#!/bin/bash
# 不依赖 Xcode 的构建脚本：swift build + 手工打包 .app
#   用法: Build/build.sh            -> 产出 Build/out/Topit.app
#   环境变量: SDK=<路径>  指定 SDK(默认 CLT 里的 MacOSX26.sdk；27 SDK 的 SwiftUI 宏插件只随 Xcode 提供，会编译失败)
#             SIGN_ID=<证书名> 指定签名身份(默认 "Topit Local Signing"，没有就用 ad-hoc)
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
SDK=${SDK:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk}
APP=Build/out/Topit.app
VERSION=$(sed -n 's/.*MARKETING_VERSION = \(.*\);/\1/p' Topit.xcodeproj/project.pbxproj | head -1)
BUNDLE_ID=${BUNDLE_ID:-com.whw23.Topit}

python3 Build/gen-shim.py
LOG=$(mktemp)
if ! swift build -c release --sdk "$SDK" >"$LOG" 2>&1; then grep -E "error" "$LOG" | head -20; echo "编译失败"; exit 1; fi
grep -E "Build complete" "$LOG"
BIN=$(swift build -c release --sdk "$SDK" --show-bin-path)/Topit

rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN" "$APP/Contents/MacOS/Topit"

# Info.plist：合并原有 Info.plist 与 Xcode 自动生成的那部分键
cp Topit/Info.plist "$APP/Contents/Info.plist"
PB=/usr/libexec/PlistBuddy
add() { $PB -c "Add :$1 $2 $3" "$APP/Contents/Info.plist" 2>/dev/null || $PB -c "Set :$1 $3" "$APP/Contents/Info.plist"; }
add CFBundleIdentifier string "$BUNDLE_ID"
add CFBundleName string Topit
add CFBundleDisplayName string Topit
add CFBundleExecutable string Topit
add CFBundlePackageType string APPL
add CFBundleShortVersionString string "$VERSION"
add CFBundleVersion string "$VERSION"
add CFBundleIconFile string AppIcon
add CFBundleDevelopmentRegion string en
add LSMinimumSystemVersion string 14.0
add LSUIElement bool true
add NSHighResolutionCapable bool true
add NSPrincipalClass string NSApplication
add NSHumanReadableCopyright string "Copyright © 2024 lihaoyun6. AGPL-3.0 fork."

R="$APP/Contents/Resources"
# 图标
IS=$(mktemp -d)/AppIcon.iconset; mkdir -p "$IS"; cp Topit/Assets.xcassets/AppIcon.appiconset/*.png "$IS/"; iconutil -c icns "$IS" -o "$R/AppIcon.icns"
# 图片：asset catalog 里的图片用同名散文件代替（NSImage(named:) / Image("name") 会在 Resources 里找）
A=Topit/Assets.xcassets
cp "$A/statusIcon.imageset/topitMenubar@1x2.png" "$R/statusIcon.png"
cp "$A/statusIcon.imageset/topitMenubar@2x2.png" "$R/statusIcon@2x.png"
cp "$A/window.select.imageset/macwindow.and.cursorarrow.svg" "$R/window.select.svg"
cp "$A/unknowScreen.imageset/unknow screen.png" "$R/unknow screen.png"
cp "$A/unknowScreen.imageset/unknow screen@2x.png" "$R/unknow screen@2x.png"
cp "$A/gear.imageset/gear@1x.png" "$R/gear.png"; cp "$A/gear.imageset/gear.png" "$R/gear@2x.png"
cp "$A/block.imageset/blacklist@1x.png" "$R/block.png"; cp "$A/block.imageset/blacklist.png" "$R/block@2x.png"
cp "$A/hotkey.imageset/hotkey@1x.png" "$R/hotkey.png"; cp "$A/hotkey.imageset/hotkey.png" "$R/hotkey@2x.png"
cp "$A/window.imageset/window@1x.png" "$R/window.png"; cp "$A/window.imageset/window.png" "$R/window@2x.png"
# 本地化 + AppleScript 词典
for l in Base zh-Hans zh-Hant; do mkdir -p "$R/$l.lproj"; cp Topit/$l.lproj/* "$R/$l.lproj/"; done
mkdir -p "$R/en.lproj"
cp Topit/Scriptable/Scriptable.sdef "$R/Scriptable.sdef"
# SPM 资源包与 Sparkle
cp -R .build/out/Products/Release/KeyboardShortcuts_KeyboardShortcuts.bundle "$R/" 2>/dev/null || cp -R "$(dirname "$BIN")/KeyboardShortcuts_KeyboardShortcuts.bundle" "$R/"
cp -R .build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework "$APP/Contents/Frameworks/"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/Topit" 2>/dev/null || true

# 签名：先签内嵌组件，再签整体（--deep 不被推荐）
ID=${SIGN_ID:-"Topit Local Signing"}
security find-identity -p codesigning | grep -q "$ID" || { echo "未找到证书 '$ID'，改用 ad-hoc 签名（每次重编译都要重新授权）"; ID=-; }
SF="$APP/Contents/Frameworks/Sparkle.framework"
for x in "$SF/Versions/B/XPCServices/"*.xpc "$SF/Versions/B/Autoupdate" "$SF/Versions/B/Updater.app"; do [ -e "$x" ] && codesign --force --sign "$ID" -o runtime "$x"; done
codesign --force --sign "$ID" "$SF"
codesign --force --sign "$ID" --entitlements Topit/Topit.entitlements --identifier "$BUNDLE_ID" "$APP"
echo "built -> $ROOT/$APP  (bundle id: $BUNDLE_ID)"
