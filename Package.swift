// swift-tools-version:5.9
// 不依赖 Xcode 的构建入口（配合 Build/build.sh 使用）。Xcode 工程保持不变。
import PackageDescription

let package = Package(
    name: "PinTop",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "Vendor/KeyboardShortcuts"),
    ],
    targets: [
        .executableTarget(
            name: "PinTop",
            dependencies: ["KeyboardShortcuts"],
            path: "PinTop",
            exclude: ["Info.plist", "PinTop.entitlements", "Assets.xcassets", "Base.lproj",
                      "zh-Hans.lproj", "zh-Hant.lproj", "Scriptable/Scriptable.sdef", "Preview Content"]
        )
    ]
)
