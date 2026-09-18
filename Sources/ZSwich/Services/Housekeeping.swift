import Foundation

/// 一次性的磁盘整理：只在启动或写入快照时顺手执行，不引入任何后台任务。
enum Housekeeping {
    /// 早期版本用 URLSession.shared 查额度，系统把带令牌的请求写进了 Caches/Cache.db。
    /// 现在已改为不接磁盘缓存，这里把历史残留删掉。
    static func removeLeakedURLCache() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.zhz.z-swich"
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        let directory = caches.appendingPathComponent(bundleID, isDirectory: true)
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    /// 快照里都是长期有效的 refresh_token，不进 Time Machine；目录权限收紧到 0700。
    static func protectDataDirectories() {
        for directory in [Paths.appSupport, Paths.snapshotsDir] {
            try? FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        }
        var snapshots = Paths.snapshotsDir
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? snapshots.setResourceValues(values)
    }

    /// unparsed-*.json 只在"添加新账号"且 auth.json 解析失败时产生；只保留最近几份。
    static func pruneUnparsedBackups(keep: Int = 2) {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: Paths.snapshotsDir.path) else {
            return
        }
        let backups = names
            .filter { $0.hasPrefix("unparsed-") && $0.hasSuffix(".json") }
            .sorted(by: >)  // 文件名带秒级时间戳，倒序即最新在前
        for name in backups.dropFirst(keep) {
            try? FileManager.default.removeItem(at: Paths.snapshotsDir.appendingPathComponent(name))
        }
    }
}
