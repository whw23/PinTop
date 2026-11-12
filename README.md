# PinTop

macOS 窗口置顶工具。基于 [lihaoyun6/Topit](https://github.com/lihaoyun6/Topit)（AGPL-3.0）的个人分支，原理相同：用 ScreenCaptureKit 抓取目标窗口，在一个浮动窗口里镜像显示。

## 与上游的区别
- 不依赖 Xcode：`Build/build.sh` 只需 Command Line Tools，产出 `Build/out/PinTop.app`
- 移除 Sparkle 自动更新（原更新源和签名公钥属于上游，保留会被更新回原版）
- 合并上游 #44（副屏切换桌面）、#42（降低抓取开销），并修复 #42 引入的帧回调数据竞争（会导致崩溃）
- 重命名为 PinTop，包标识 `com.whw23.PinTop`

## 构建
```
Build/build.sh            # 需要 macOS 14+；用 CLT 里的 MacOSX26 SDK
```
首次构建前需要一个名为 `PinTop Local Signing` 的本地代码签名证书（没有则退回 ad-hoc 签名，每次重编译都要重新授权辅助功能/屏幕录制）。

## 许可
AGPL-3.0，见 LICENSE。`Vendor/KeyboardShortcuts` 为 MIT（Sindre Sorhus）。
