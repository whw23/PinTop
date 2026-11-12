// swift-tools-version:5.9
// 不依赖 Xcode 的构建入口（配合 Build/build.sh 使用）。Xcode 工程保持不变。
import PackageDescription

let package = Package(
    name: "Topit",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "Vendor/KeyboardShortcuts"),
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.6.4"),
    ],
    targets: [
        .executableTarget(
            name: "Topit",
            dependencies: ["KeyboardShortcuts", "Sparkle"],
            path: "Topit",
            exclude: ["Info.plist", "Topit.entitlements", "Assets.xcassets", "Base.lproj",
                      "zh-Hans.lproj", "zh-Hant.lproj", "Scriptable/Scriptable.sdef", "Preview Content"]
        )
    ]
)
