import Foundation

public struct SkillRecord: Identifiable, Equatable, Sendable {
    public enum Origin: String, Equatable, Sendable {
        case system
        case local
        case linked
    }

    public let target: TargetApp
    public let directoryName: String
    public let name: String
    public let summary: String
    public let location: URL
    public let origin: Origin
    public let isEnabled: Bool
    public let isReadOnly: Bool

    public var id: String {
        [target.rawValue, origin.rawValue, directoryName, isEnabled.description]
            .joined(separator: ":")
    }

    public init(
        target: TargetApp,
        directoryName: String,
        name: String,
        summary: String,
        location: URL,
        origin: Origin,
        isEnabled: Bool,
        isReadOnly: Bool
    ) {
        self.target = target
        self.directoryName = directoryName
        self.name = name
        self.summary = summary
        self.location = location
        self.origin = origin
        self.isEnabled = isEnabled
        self.isReadOnly = isReadOnly
    }
}

public struct SkillSnapshot: Equatable, Sendable {
    public let skills: [SkillRecord]
    public let warnings: [String]

    public init(skills: [SkillRecord], warnings: [String]) {
        self.skills = skills
        self.warnings = warnings
    }
}

public final class SkillRepository {
    private let fileManager: FileManager
    private let homeDirectory: URL
    private let disabledRootDirectory: URL

    public init(
        fileManager: FileManager = .default,
        homeDirectory: URL? = nil,
        disabledRootDirectory: URL? = nil
    ) {
        self.fileManager = fileManager
        self.homeDirectory = homeDirectory ?? fileManager.homeDirectoryForCurrentUser
        self.disabledRootDirectory = disabledRootDirectory
            ?? (homeDirectory ?? fileManager.homeDirectoryForCurrentUser)
                .appendingPathComponent("Library/Application Support/com.zhz.swich/DisabledSkills", isDirectory: true)
    }

    public func load(target: TargetApp) throws -> SkillSnapshot {
        var skills: [SkillRecord] = []
        var warnings: [String] = []
        let activeDirectory = activeDirectory(for: target)

        for directory in try childDirectories(at: activeDirectory) {
            if let skill = loadSkill(
                at: directory,
                target: target,
                isEnabled: true,
                isReadOnly: false,
                warnings: &warnings
            ) {
                skills.append(skill)
            }
        }

        if target == .codex {
            let systemDirectory = activeDirectory.appendingPathComponent(".system", isDirectory: true)
            for directory in try childDirectories(at: systemDirectory) {
                if let skill = loadSkill(
                    at: directory,
                    target: target,
                    isEnabled: true,
                    isReadOnly: true,
                    warnings: &warnings
                ) {
                    skills.append(skill)
                }
            }
        }

        let activeNames = Set(skills.map(\.directoryName))
        for directory in try childDirectories(at: disabledDirectory(for: target)) {
            guard !activeNames.contains(directory.lastPathComponent) else {
                warnings.append("技能 \(directory.lastPathComponent) 同时存在于启用与停用目录，已优先显示启用版本。")
                continue
            }
            if let skill = loadSkill(
                at: directory,
                target: target,
                isEnabled: false,
                isReadOnly: false,
                warnings: &warnings
            ) {
                skills.append(skill)
            }
        }

        skills.sort {
            if $0.isEnabled != $1.isEnabled { return $0.isEnabled && !$1.isEnabled }
            if $0.isReadOnly != $1.isReadOnly { return !$0.isReadOnly && $1.isReadOnly }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        return SkillSnapshot(skills: skills, warnings: warnings)
    }

    public func setEnabled(_ enabled: Bool, for skill: SkillRecord) throws {
        guard !skill.isReadOnly else {
            throw SkillRepositoryError.readOnlySkill(skill.name)
        }
        guard skill.isEnabled != enabled else { return }

        let destinationParent = enabled ? activeDirectory(for: skill.target) : disabledDirectory(for: skill.target)
        let destination = destinationParent.appendingPathComponent(skill.directoryName, isDirectory: true)
        guard !fileManager.fileExists(atPath: destination.path) else {
            throw SkillRepositoryError.duplicateSkill(skill.directoryName)
        }
        guard fileManager.fileExists(atPath: skill.location.path) else {
            throw SkillRepositoryError.missingSkill(skill.location.path)
        }

        try fileManager.createDirectory(at: destinationParent, withIntermediateDirectories: true)
        do {
            try fileManager.moveItem(at: skill.location, to: destination)
        } catch {
            throw SkillRepositoryError.fileOperation(
                "无法\(enabled ? "启用" : "停用")技能 \(skill.name)：\(error.localizedDescription)"
            )
        }
    }

    public func install(from sourceDirectory: URL, target: TargetApp) throws {
        let source = sourceDirectory.standardizedFileURL
        let directoryName = source.lastPathComponent
        guard !directoryName.isEmpty, directoryName != ".", directoryName != ".." else {
            throw SkillRepositoryError.invalidDirectoryName(directoryName)
        }
        guard fileManager.fileExists(
            atPath: source.appendingPathComponent("SKILL.md", isDirectory: false).path
        ) else {
            throw SkillRepositoryError.invalidSkill(source.path)
        }

        let activeDirectory = activeDirectory(for: target)
        let destination = activeDirectory.appendingPathComponent(directoryName, isDirectory: true)
        let disabledDestination = disabledDirectory(for: target)
            .appendingPathComponent(directoryName, isDirectory: true)
        guard !fileManager.fileExists(atPath: destination.path),
              !fileManager.fileExists(atPath: disabledDestination.path) else {
            throw SkillRepositoryError.duplicateSkill(directoryName)
        }

        try fileManager.createDirectory(at: activeDirectory, withIntermediateDirectories: true)
        let staging = activeDirectory.appendingPathComponent(".zhz-install-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: staging) }

        do {
            try fileManager.copyItem(at: source, to: staging)
            guard fileManager.fileExists(
                atPath: staging.appendingPathComponent("SKILL.md", isDirectory: false).path
            ) else {
                throw SkillRepositoryError.invalidSkill(source.path)
            }
            try fileManager.moveItem(at: staging, to: destination)
        } catch let error as SkillRepositoryError {
            throw error
        } catch {
            throw SkillRepositoryError.fileOperation("安装技能失败：\(error.localizedDescription)")
        }
    }

    public func activeDirectory(for target: TargetApp) -> URL {
        switch target {
        case .codex:
            homeDirectory.appendingPathComponent(".codex/skills", isDirectory: true)
        case .claude:
            homeDirectory.appendingPathComponent(".claude/skills", isDirectory: true)
        }
    }

    private func disabledDirectory(for target: TargetApp) -> URL {
        disabledRootDirectory.appendingPathComponent(target.rawValue, isDirectory: true)
    }

    private func childDirectories(at directory: URL) throws -> [URL] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        do {
            return try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            )
            .filter { isDirectory($0) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        } catch {
            throw SkillRepositoryError.fileOperation("无法读取技能目录 \(directory.path)：\(error.localizedDescription)")
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func loadSkill(
        at directory: URL,
        target: TargetApp,
        isEnabled: Bool,
        isReadOnly: Bool,
        warnings: inout [String]
    ) -> SkillRecord? {
        let skillFile = directory.appendingPathComponent("SKILL.md", isDirectory: false)
        guard fileManager.fileExists(atPath: skillFile.path) else {
            if isSymbolicLink(directory) {
                warnings.append("符号链接 \(directory.lastPathComponent) 无法解析到有效的 SKILL.md。")
            }
            return nil
        }

        do {
            let contents = try String(contentsOf: skillFile, encoding: .utf8)
            let metadata = parseFrontMatter(contents, fallbackName: directory.lastPathComponent)
            return SkillRecord(
                target: target,
                directoryName: directory.lastPathComponent,
                name: metadata.name,
                summary: metadata.summary,
                location: directory,
                origin: isReadOnly ? .system : (isSymbolicLink(directory) ? .linked : .local),
                isEnabled: isEnabled,
                isReadOnly: isReadOnly
            )
        } catch {
            warnings.append("无法读取技能 \(directory.lastPathComponent)：\(error.localizedDescription)")
            return nil
        }
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true
    }

    private func parseFrontMatter(_ contents: String, fallbackName: String) -> (name: String, summary: String) {
        let normalized = contents.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---",
              let closingIndex = lines.dropFirst().firstIndex(where: {
                  $0.trimmingCharacters(in: .whitespaces) == "---"
              }) else {
            return (fallbackName, "未提供技能说明")
        }

        let frontMatter = Array(lines[1..<closingIndex])
        let name = scalarValue(for: "name", in: frontMatter) ?? fallbackName
        let summary = scalarValue(for: "description", in: frontMatter) ?? "未提供技能说明"
        return (unquote(name), unquote(summary))
    }

    private func scalarValue(for key: String, in lines: [String]) -> String? {
        guard let index = lines.firstIndex(where: { $0.hasPrefix("\(key):") }) else { return nil }
        let rawValue = String(lines[index].dropFirst(key.count + 1)).trimmingCharacters(in: .whitespaces)
        guard rawValue == "|" || rawValue == ">" else {
            return rawValue.isEmpty ? nil : rawValue
        }

        let block = lines.dropFirst(index + 1).prefix { line in
            line.isEmpty || line.first?.isWhitespace == true
        }
        let values = block.map { $0.trimmingCharacters(in: .whitespaces) }
        let separator = rawValue == ">" ? " " : "\n"
        let value = values.joined(separator: separator).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func unquote(_ value: String) -> String {
        guard value.count >= 2,
              let first = value.first,
              let last = value.last,
              (first == "\"" && last == "\"" || first == "'" && last == "'") else {
            return value
        }
        return String(value.dropFirst().dropLast())
    }
}

public enum SkillRepositoryError: LocalizedError {
    case invalidSkill(String)
    case invalidDirectoryName(String)
    case duplicateSkill(String)
    case readOnlySkill(String)
    case missingSkill(String)
    case fileOperation(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidSkill(path):
            "所选目录不是有效技能，缺少 SKILL.md：\(path)"
        case let .invalidDirectoryName(name):
            "技能目录名称无效：\(name)"
        case let .duplicateSkill(name):
            "技能 \(name) 已存在，未覆盖现有数据。"
        case let .readOnlySkill(name):
            "系统技能 \(name) 由客户端管理，不能停用。"
        case let .missingSkill(path):
            "技能目录已不存在：\(path)"
        case let .fileOperation(message):
            message
        }
    }
}
