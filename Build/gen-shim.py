#!/usr/bin/env python3
"""没有 actool 时，用 Contents.json 生成等价的 Swift 资源符号（颜色 / 图片）。输出到 Topit/_AssetShim.swift"""
import json, os, sys
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
cat = os.path.join(root, "Topit", "Assets.xcassets")

def comp(c):
    v = c["components"]
    f = lambda x: (int(x, 16) if str(x).startswith("0x") else float(x) * 255 if float(x) <= 1 else float(x)) / 255
    return f(v["red"]), f(v["green"]), f(v["blue"]), float(v["alpha"])

out = ["import SwiftUI", "import AppKit", ""]
def ns(c):
    r, g, b, a = comp(c)
    return f"NSColor(displayP3Red: {r:.5f}, green: {g:.5f}, blue: {b:.5f}, alpha: {a:.3f})"

syms = []
for d in sorted(os.listdir(cat)):
    if not d.endswith(".colorset"): continue
    name = d[:-9]
    if name == "AccentColor": continue
    cs = json.load(open(os.path.join(cat, d, "Contents.json")))["colors"]
    light = next((c for c in cs if "appearances" not in c), None)
    dark = next((c for c in cs if "appearances" in c), None)
    if not light: continue
    ident = name[0].lower() + name[1:]
    if dark:
        expr = f'NSColor(name: nil) {{ $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? {ns(dark["color"])} : {ns(light["color"])} }}'
    else:
        expr = ns(light["color"])
    syms.append(f"    static var {ident}: Color {{ Color(nsColor: {expr}) }}")
out += ["extension ShapeStyle where Self == Color {"] + syms + ["}", ""]
out += ['''extension NSImage {
    static var unknowScreen: NSImage { NSImage(named: "unknow screen") ?? NSImage(size: NSSize(width: 1, height: 1)) }
}''']
open(os.path.join(root, "Topit", "_AssetShim.swift"), "w").write("\n".join(out) + "\n")
print("shim written:", len(syms), "colors")
