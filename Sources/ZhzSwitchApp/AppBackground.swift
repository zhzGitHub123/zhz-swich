import AppKit
import Foundation

enum AppBackground {
    enum Style: String, CaseIterable, Identifiable {
        case house
        case aurora
        case softGlow
        case custom

        var id: Self { self }

        var title: String {
            switch self {
            case .house: "林间小屋"
            case .aurora: "主题极光"
            case .softGlow: "柔光渐变"
            case .custom: "自定义图片"
            }
        }

        var subtitle: String {
            switch self {
            case .house: "默认背景"
            case .aurora: "跟随主题家族"
            case .softGlow: "低对比柔光"
            case .custom: "本地导入"
            }
        }
    }

    enum ImportError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage: "所选文件不是可读取的图片。"
            }
        }
    }

    static let styleKey = "appearance.background.style"
    static let customImagePathKey = "appearance.background.custom.path"
    static let customImageRevisionKey = "appearance.background.custom.revision"
    static let builtInStyles: [Style] = [.house, .aurora, .softGlow]

    static func bundledDefaultImage() -> NSImage? {
        guard let url = Bundle.main.url(forResource: "test", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    static func customImageURL() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: customImagePathKey) else {
            return nil
        }

        let url = URL(fileURLWithPath: path)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func customImage() -> NSImage? {
        guard let url = customImageURL() else { return nil }
        return NSImage(contentsOf: url)
    }

    static func importCustomImage(from sourceURL: URL) throws {
        let isAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard NSImage(contentsOf: sourceURL) != nil else {
            throw ImportError.invalidImage
        }

        let fileManager = FileManager.default
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupport
            .appendingPathComponent("zhz-switch", isDirectory: true)
            .appendingPathComponent("Backgrounds", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let pathExtension = sourceURL.pathExtension.isEmpty ? "image" : sourceURL.pathExtension.lowercased()
        let destination = directory.appendingPathComponent("custom-background.\(pathExtension)")
        let pending = directory.appendingPathComponent("pending-\(UUID().uuidString).\(pathExtension)")

        try fileManager.copyItem(at: sourceURL, to: pending)
        do {
            if let previous = customImageURL(), fileManager.fileExists(atPath: previous.path) {
                try fileManager.removeItem(at: previous)
            }
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: pending, to: destination)
        } catch {
            try? fileManager.removeItem(at: pending)
            throw error
        }

        UserDefaults.standard.set(destination.path, forKey: customImagePathKey)
    }
}
