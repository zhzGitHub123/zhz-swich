#!/usr/bin/env swift
import AppKit
import CoreGraphics

// Generates the classic macOS icon set used by the macOS 15+ SwiftPM build.
// Keep the canvas square and unmasked; macOS applies the final icon mask.
let fileManager = FileManager.default
let projectRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let assetDirectory = projectRoot.appendingPathComponent("Assets/AppIcon", isDirectory: true)
let logoURL = assetDirectory.appendingPathComponent("logo-transparent.png")
let masterURL = assetDirectory.appendingPathComponent("master.png")
let iconsetURL = assetDirectory.appendingPathComponent("Z-Swich.iconset", isDirectory: true)
let icnsURL = assetDirectory.appendingPathComponent("Z-Swich.icns")
let canvas = CGSize(width: 1024, height: 1024)

guard let logo = NSImage(contentsOf: logoURL) else {
    fatalError("无法读取透明 Logo：\(logoURL.path)")
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func pngData(for image: NSImage) -> Data {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("无法编码图标 PNG")
    }
    return png
}

func resized(_ image: NSImage, pixels: Int) -> NSImage {
    let size = NSSize(width: pixels, height: pixels)
    return NSImage(size: size, flipped: false) { rect in
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
        return true
    }
}

let master = NSImage(size: canvas, flipped: false) { rect in
    guard let context = NSGraphicsContext.current?.cgContext else { return false }
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    // Opaque, full-bleed field. The selected Z mark stays visually dominant
    // while retaining enough contrast in Finder, Spotlight, and dark mode.
    context.setFillColor(color(0x080C24).cgColor)
    context.fill(rect)

    let background = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [color(0x132B68).cgColor, color(0x17133F).cgColor, color(0x35105C).cgColor] as CFArray,
        locations: [0, 0.55, 1]
    )!
    context.drawLinearGradient(
        background,
        start: CGPoint(x: 120, y: 960),
        end: CGPoint(x: 920, y: 70),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    let cyanGlow = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [color(0x00D9FF, alpha: 0.20).cgColor, color(0x00D9FF, alpha: 0).cgColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        cyanGlow,
        startCenter: CGPoint(x: 720, y: 760),
        startRadius: 20,
        endCenter: CGPoint(x: 720, y: 760),
        endRadius: 500,
        options: []
    )

    let violetGlow = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [color(0xA232FF, alpha: 0.22).cgColor, color(0xA232FF, alpha: 0).cgColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawRadialGradient(
        violetGlow,
        startCenter: CGPoint(x: 300, y: 250),
        startRadius: 20,
        endCenter: CGPoint(x: 300, y: 250),
        endRadius: 480,
        options: []
    )

    NSGraphicsContext.current?.imageInterpolation = .high
    logo.draw(
        in: CGRect(x: 32, y: 32, width: 960, height: 960),
        from: .zero,
        operation: .sourceOver,
        fraction: 1
    )
    return true
}

try fileManager.createDirectory(at: assetDirectory, withIntermediateDirectories: true)
try pngData(for: master).write(to: masterURL, options: .atomic)

if fileManager.fileExists(atPath: iconsetURL.path) {
    try fileManager.removeItem(at: iconsetURL)
}
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconFiles: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for iconFile in iconFiles {
    let destination = iconsetURL.appendingPathComponent(iconFile.name)
    try pngData(for: resized(master, pixels: iconFile.pixels)).write(to: destination, options: .atomic)
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else {
    fatalError("iconutil 生成失败：\(iconutil.terminationStatus)")
}

print("已生成 \(masterURL.path)")
print("已生成 \(icnsURL.path)")
