import Foundation

public final class FileTargetAdapter: TargetAdapter {
    public let target: TargetApp

    private let configurationURL: URL
    private let backupDirectoryURL: URL
    private let fileManager: FileManager

    public init(
        target: TargetApp,
        configurationURL: URL,
        backupDirectoryURL: URL,
        fileManager: FileManager = .default
    ) {
        self.target = target
        self.configurationURL = configurationURL
        self.backupDirectoryURL = backupDirectoryURL
        self.fileManager = fileManager
    }

    public func readCurrentSubscription() throws -> CurrentSubscription {
        guard fileManager.fileExists(atPath: configurationURL.path) else {
            return CurrentSubscription(value: nil)
        }

        let value = try String(contentsOf: configurationURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return CurrentSubscription(value: value.isEmpty ? nil : value)
    }

    public func backupCurrentConfiguration() throws -> BackupRecord {
        try fileManager.createDirectory(
            at: backupDirectoryURL,
            withIntermediateDirectories: true
        )

        let backupURL = backupDirectoryURL.appendingPathComponent(
            "\(target.rawValue)-\(Self.timestamp()).bak",
            isDirectory: false
        )

        if fileManager.fileExists(atPath: configurationURL.path) {
            try fileManager.copyItem(at: configurationURL, to: backupURL)
        } else {
            try Data().write(to: backupURL, options: .atomic)
        }

        return BackupRecord(location: backupURL)
    }

    public func write(subscriptionURL: String) throws {
        let parentURL = configurationURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)
        try Data(subscriptionURL.utf8).write(to: configurationURL, options: .atomic)
    }

    public func verify(subscriptionURL: String) throws -> VerificationResult {
        let current = try readCurrentSubscription().value
        return current == subscriptionURL ? .matched : .mismatched(actual: current)
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
    }
}
