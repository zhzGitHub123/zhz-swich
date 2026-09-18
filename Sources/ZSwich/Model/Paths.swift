import Foundation

/// 所有磁盘路径集中在这里，方便以后适配 ChatGPT/Codex 改目录。
enum Paths {
    /// ChatGPT（Codex 内核）的数据目录，尊重 CODEX_HOME 环境变量。
    static var codexHome: URL {
        if let custom = ProcessInfo.processInfo.environment["CODEX_HOME"], !custom.isEmpty {
            return URL(fileURLWithPath: (custom as NSString).expandingTildeInPath, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
    }

    /// 唯一决定"当前登录的是哪个账号"的文件。
    static var authFile: URL {
        codexHome.appendingPathComponent("auth.json", isDirectory: false)
    }

    static var codexConfigFile: URL {
        codexHome.appendingPathComponent("config.toml", isDirectory: false)
    }

    /// 本 App 自己的数据目录。
    static var appSupport: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Z-Swich", isDirectory: true)
    }

    /// 账号索引（邮箱、套餐、时间戳等元数据）。
    static var indexFile: URL {
        appSupport.appendingPathComponent("accounts.json", isDirectory: false)
    }

    /// 每个账号一份 auth.json 原样快照。
    static var snapshotsDir: URL {
        appSupport.appendingPathComponent("snapshots", isDirectory: true)
    }

    static func snapshot(for accountID: String) -> URL {
        snapshotsDir.appendingPathComponent("\(safeFileName(accountID)).json", isDirectory: false)
    }

    /// 无法解析的 auth.json 也不丢弃，挪到这里留底。
    static func unparsedBackup(date: Date = .now) -> URL {
        let stamp = Int(date.timeIntervalSince1970)
        return snapshotsDir.appendingPathComponent("unparsed-\(stamp).json", isDirectory: false)
    }

    private static func safeFileName(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return String(raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
    }
}
