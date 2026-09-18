import Foundation

/// 账号快照的读写与切换编排。所有读取都由用户操作触发，空闲时不做后台工作。
@MainActor
@Observable
final class AccountStore {
    private(set) var accounts: [AccountRecord] = []
    /// 当前 auth.json 对应的身份；文件缺失或无法解析时为 nil。
    private(set) var current: AccountIdentity?
    /// 当前 auth.json 的问题说明（未登录 / 解析失败）。
    private(set) var currentProblem: String?
    private(set) var chatGPTRunning = false
    private(set) var isBusy = false
    private(set) var switchingAccountID: String?
    private(set) var status: String?
    private(set) var activityLog: [ActivityLogEntry] = []
    /// 每个账号最近一次的额度快照，按 accountID 键入。
    /// 键入而不是只存"当前账号"有两个好处：切换后不可能串号显示上一个账号的数字；
    /// 未挂载的账号也能用自己的快照令牌查额度。
    private(set) var usageByAccount: [String: UsageSnapshot] = [:]
    private(set) var usageProblemByAccount: [String: String] = [:]
    private(set) var loadingUsageAccounts: Set<String> = []
    private(set) var isRefreshingAllUsage = false
    /// 有账号窗口在展示额度时为 true；菜单栏切换等无人查看的场景不发额度请求。
    var wantsUsage = false

    /// 当前账号的套餐：优先用服务器返回值，升降级后不必等 id_token 轮转就能显示正确等级。
    var currentPlanType: String? { usage?.planType ?? current?.planType }

    var usage: UsageSnapshot? { usage(for: current?.accountID) }
    var usageProblem: String? { usageProblem(for: current?.accountID) }
    var isLoadingUsage: Bool { isLoadingUsage(for: current?.accountID) }

    func usage(for accountID: String?) -> UsageSnapshot? {
        accountID.flatMap { usageByAccount[$0] }
    }

    func usageProblem(for accountID: String?) -> String? {
        accountID.flatMap { usageProblemByAccount[$0] }
    }

    func isLoadingUsage(for accountID: String?) -> Bool {
        accountID.map { loadingUsageAccounts.contains($0) } ?? false
    }

    /// 快照里的 access_token 有效期 240 小时。按约定不自己拿 refresh_token 续期
    /// （续期会轮转 refresh_token，写回失败就得重新登录），只标记出来。
    static let expiredCredentialsNote = "凭证已过期，切换过去后 ChatGPT 会自动刷新"

    private var currentRaw: Data?
    private let usageClient: any UsageFetching
    /// 同一账号在这段时间内不重复向服务器查额度；手动刷新不受限制。
    private static let usageFreshness: TimeInterval = 60

    init(usageClient: any UsageFetching = UsageClient()) {
        self.usageClient = usageClient
        load()
    }

    // MARK: - 读取

    func load() {
        Housekeeping.removeLeakedURLCache()
        Housekeeping.protectDataDirectories()
        guard let data = try? Data(contentsOf: Paths.indexFile) else {
            accounts = []
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        accounts = (try? decoder.decode([AccountRecord].self, from: data)) ?? []
        // 快照文件丢了的记录不再展示。
        accounts.removeAll { !FileManager.default.fileExists(atPath: Paths.snapshot(for: $0.id).path) }
    }

    /// 读一次 auth.json：更新当前身份，并把最新令牌同步进快照（处理 refresh_token 轮转）。
    func syncCurrent() {
        chatGPTRunning = ChatGPTApp.isRunning
        do {
            try AuthCredentialsStore.requireFileMode()
        } catch {
            current = nil
            currentRaw = nil
            currentProblem = error.localizedDescription
            recordActivity(error.localizedDescription, kind: .error)
            return
        }
        guard let data = try? Data(contentsOf: Paths.authFile) else {
            current = nil
            currentRaw = nil
            currentProblem = "ChatGPT 当前未登录"
            return
        }
        do {
            let identity = try AccountIdentity.parse(authJSON: data)
            current = identity
            currentProblem = nil
            if data != currentRaw {
                currentRaw = data
                let wasKnown = accounts.contains { $0.id == identity.accountID }
                let savedRaw = try? Data(contentsOf: Paths.snapshot(for: identity.accountID))
                if savedRaw != data {
                    try upsertSnapshot(identity: identity, raw: data)
                    recordActivity(wasKnown ? "已保存 \(identity.email) 的最新凭证" : "已收录账号 \(identity.email)")
                } else if let index = accounts.firstIndex(where: { $0.id == identity.accountID }),
                          accounts[index].accessTokenExpiry != identity.accessTokenExpiry
                            || accounts[index].lastRefresh != identity.lastRefresh {
                    accounts[index].refreshMetadata(from: identity)
                    try saveIndex()
                }
            }
        } catch {
            current = nil
            currentProblem = error.localizedDescription
            recordActivity("读取当前账号失败：\(error.localizedDescription)", kind: .error)
        }
    }

    /// 当前挂载账号的额度：保留原有的 60 秒新鲜度，手动刷新传 force。
    func refreshUsage(force: Bool = false) async {
        guard let accountID = current?.accountID else { return }
        await refreshUsage(for: accountID, force: force)
    }

    /// 任意已保存账号的额度：用该账号自己快照里的 access_token 请求，不切换、不动 auth.json。
    /// 结果只留在内存，不缓存原始响应、不记录令牌。
    func refreshUsage(for accountID: String, force: Bool = true, announce: Bool = true) async {
        guard !loadingUsageAccounts.contains(accountID) else { return }
        if !force, let snapshot = usageByAccount[accountID],
           Date.now.timeIntervalSince(snapshot.fetchedAt) < Self.usageFreshness {
            return
        }
        let isCurrent = accountID == current?.accountID
        if !isCurrent, isCredentialExpired(accountID) {
            markExpired(accountID)
            return
        }

        loadingUsageAccounts.insert(accountID)
        usageProblemByAccount[accountID] = nil
        if announce { status = "正在同步额度…" }
        defer { loadingUsageAccounts.remove(accountID) }

        do {
            let credentials = try loadCredentials(for: accountID, isCurrent: isCurrent)
            let snapshot = try await usageClient.fetchUsage(credentials: credentials)
            apply(snapshot, to: accountID, announce: announce)
        } catch {
            applyFailure(message: Self.message(for: error), to: accountID, announce: announce)
        }
    }

    /// 手动触发的全量查询：并发上限 3，避免一次性打出一串请求。
    func refreshAllUsage() async {
        guard !isRefreshingAllUsage else { return }
        let targets = accounts.map(\.id)
        guard !targets.isEmpty else { return }
        isRefreshingAllUsage = true
        defer { isRefreshingAllUsage = false }
        status = "正在查询 \(targets.count) 个账号的额度…"

        var jobs: [UsageJob] = []
        for id in targets where !loadingUsageAccounts.contains(id) {
            let isCurrent = id == current?.accountID
            if !isCurrent, isCredentialExpired(id) {
                markExpired(id)
                continue
            }
            do {
                jobs.append(UsageJob(accountID: id, credentials: try loadCredentials(for: id, isCurrent: isCurrent)))
            } catch {
                applyFailure(message: Self.message(for: error), to: id, announce: false)
            }
        }
        guard !jobs.isEmpty else {
            status = "没有可查询的账号凭证"
            return
        }

        let ids = jobs.map(\.accountID)
        loadingUsageAccounts.formUnion(ids)
        for id in ids { usageProblemByAccount[id] = nil }
        let outcomes = await Self.fetchConcurrently(jobs, client: usageClient, limit: 3)
        loadingUsageAccounts.subtract(ids)

        for outcome in outcomes {
            if let snapshot = outcome.snapshot {
                apply(snapshot, to: outcome.accountID, announce: false)
            } else {
                applyFailure(
                    message: outcome.unauthorized ? Self.expiredCredentialsNote : (outcome.message ?? "额度查询失败"),
                    to: outcome.accountID,
                    announce: false
                )
            }
        }

        let succeeded = outcomes.filter { $0.snapshot != nil }.count
        status = "已查询 \(succeeded)/\(targets.count) 个账号的额度"
        recordActivity(status ?? "", kind: succeeded == targets.count ? .success : .info)
    }

    private func loadCredentials(for accountID: String, isCurrent: Bool) throws -> UsageCredentials {
        isCurrent
            ? try AuthCredentialsStore.loadUsageCredentials()
            : try AuthCredentialsStore.usageCredentials(snapshotAt: Paths.snapshot(for: accountID))
    }

    private func isCredentialExpired(_ accountID: String) -> Bool {
        guard let expiry = record(for: accountID)?.accessTokenExpiry else { return false }
        return expiry <= .now
    }

    private func markExpired(_ accountID: String) {
        usageByAccount[accountID] = nil
        usageProblemByAccount[accountID] = Self.expiredCredentialsNote
    }

    private func apply(_ snapshot: UsageSnapshot, to accountID: String, announce: Bool) {
        usageByAccount[accountID] = snapshot
        usageProblemByAccount[accountID] = nil
        // 服务器报的套餐比令牌里的更新，顺手校正索引里的记录。
        if let planType = snapshot.planType,
           let index = accounts.firstIndex(where: { $0.id == accountID }),
           accounts[index].planType != planType {
            accounts[index].planType = planType
            try? saveIndex()
        }
        if announce {
            status = "额度状态已更新"
            if let email = record(for: accountID)?.email {
                recordActivity("已同步 \(email) 的额度状态", kind: .success)
            }
        }
    }

    private func applyFailure(message: String, to accountID: String, announce: Bool) {
        usageProblemByAccount[accountID] = message
        if announce {
            status = "额度查询失败：\(message)"
            recordActivity(status ?? "额度查询失败", kind: .error)
        }
    }

    private static func message(for error: any Error) -> String {
        if let error = error as? ZSwichError, case .usageUnauthorized = error {
            return expiredCredentialsNote
        }
        return error.localizedDescription
    }

    private struct UsageJob: Sendable {
        let accountID: String
        let credentials: UsageCredentials
    }

    private struct UsageOutcome: Sendable {
        let accountID: String
        let snapshot: UsageSnapshot?
        let unauthorized: Bool
        let message: String?
    }

    /// 并发查询，最多同时 `limit` 个在途；错误在子任务里就转成文案，避免把非 Sendable 的 error 传出来。
    private nonisolated static func fetchConcurrently(
        _ jobs: [UsageJob],
        client: any UsageFetching,
        limit: Int
    ) async -> [UsageOutcome] {
        await withTaskGroup(of: UsageOutcome.self) { group in
            var next = 0
            var outcomes: [UsageOutcome] = []
            outcomes.reserveCapacity(jobs.count)

            func schedule() {
                guard next < jobs.count else { return }
                let job = jobs[next]
                next += 1
                group.addTask {
                    do {
                        let snapshot = try await client.fetchUsage(credentials: job.credentials)
                        return UsageOutcome(
                            accountID: job.accountID, snapshot: snapshot, unauthorized: false, message: nil)
                    } catch {
                        var unauthorized = false
                        if let error = error as? ZSwichError, case .usageUnauthorized = error {
                            unauthorized = true
                        }
                        return UsageOutcome(
                            accountID: job.accountID,
                            snapshot: nil,
                            unauthorized: unauthorized,
                            message: error.localizedDescription
                        )
                    }
                }
            }

            for _ in 0..<min(limit, jobs.count) { schedule() }
            while let outcome = await group.next() {
                outcomes.append(outcome)
                schedule()
            }
            return outcomes
        }
    }

    // MARK: - 写入

    private func upsertSnapshot(identity: AccountIdentity, raw: Data) throws {
        try writeSecure(raw, to: Paths.snapshot(for: identity.accountID))
        if let index = accounts.firstIndex(where: { $0.id == identity.accountID }) {
            accounts[index].update(from: identity)
        } else {
            accounts.append(AccountRecord(identity: identity))
        }
        try saveIndex()
    }

    private func saveIndex() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try writeSecure(try encoder.encode(accounts), to: Paths.indexFile)
    }

    /// 原子写入并把权限收紧到 0600，与 ChatGPT 自己写 auth.json 的方式一致。
    private func writeSecure(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    // MARK: - 操作

    /// 切换到指定账号：保存当前 → 退出 ChatGPT → 再保存一次 → 写入目标凭证 → 启动。
    func switchTo(accountID: String) async {
        guard !isBusy else { return }
        isBusy = true
        switchingAccountID = accountID
        // 写 auth.json 期间不允许系统直接杀进程。
        ProcessInfo.processInfo.disableSuddenTermination()
        defer {
            ProcessInfo.processInfo.enableSuddenTermination()
            isBusy = false
            switchingAccountID = nil
        }
        do {
            try AuthCredentialsStore.requireFileMode()
            let snapshotURL = Paths.snapshot(for: accountID)
            guard let data = try? Data(contentsOf: snapshotURL) else {
                throw ZSwichError.snapshotMissing(accountID)
            }
            let target = try AccountIdentity.parse(authJSON: data)

            status = "正在保存当前账号…"
            syncCurrent()
            if ChatGPTApp.isRunning {
                status = "正在退出 ChatGPT…"
                try await ChatGPTApp.quit()
                // 退出过程中 ChatGPT 可能最后刷新了一次令牌，再同步一遍。
                syncCurrent()
            }

            status = "正在写入 \(target.email) 的凭证…"
            try writeSecure(data, to: Paths.authFile)
            currentRaw = data
            current = target
            currentProblem = nil
            if let index = accounts.firstIndex(where: { $0.id == accountID }) {
                accounts[index].lastUsedAt = .now
                try saveIndex()
            }

            status = "正在启动 ChatGPT…"
            try await ChatGPTApp.launch()
            status = "已切换到 \(target.email)"
            recordActivity("已切换到 \(target.email)", kind: .success)
        } catch {
            status = "切换失败：\(error.localizedDescription)"
            recordActivity(status ?? "切换失败", kind: .error)
        }
        syncCurrent()
        if wantsUsage, current?.accountID == accountID {
            await refreshUsage(force: true)
        }
    }

    /// 保存当前账号后清掉凭证并重启 ChatGPT，让它进入登录页。
    func startNewLogin() async {
        guard !isBusy else { return }
        isBusy = true
        ProcessInfo.processInfo.disableSuddenTermination()
        defer {
            ProcessInfo.processInfo.enableSuddenTermination()
            isBusy = false
        }
        do {
            try AuthCredentialsStore.requireFileMode()
            status = "正在保存当前账号…"
            syncCurrent()
            if ChatGPTApp.isRunning {
                status = "正在退出 ChatGPT…"
                try await ChatGPTApp.quit()
                syncCurrent()
            }
            let authPath = Paths.authFile.path
            if FileManager.default.fileExists(atPath: authPath) {
                if current == nil {
                    // 解析不了也不丢，留底后再移走。
                    try FileManager.default.moveItem(at: Paths.authFile, to: Paths.unparsedBackup())
                    Housekeeping.pruneUnparsedBackups()
                } else {
                    try FileManager.default.removeItem(at: Paths.authFile)
                }
            }
            currentRaw = nil
            current = nil
            status = "正在启动 ChatGPT…"
            try await ChatGPTApp.launch()
            status = "请在 ChatGPT 中登录新账号；之后打开菜单或窗口即可收录"
            recordActivity("已打开 ChatGPT 新账号登录页", kind: .success)
        } catch {
            status = "操作失败：\(error.localizedDescription)"
            recordActivity(status ?? "添加账号失败", kind: .error)
        }
        syncCurrent()
    }

    func launchChatGPT() async {
        do {
            try await ChatGPTApp.launch()
            status = "已启动 ChatGPT"
        } catch {
            status = "启动失败：\(error.localizedDescription)"
            recordActivity(status ?? "启动 ChatGPT 失败", kind: .error)
        }
        syncCurrent()
    }

    /// 只删本 App 的快照，不动 ChatGPT 的任何文件；当前正在使用的账号不允许删。
    func delete(accountID: String) {
        guard current?.accountID != accountID else { return }
        guard let record = record(for: accountID) else { return }
        do {
            try FileManager.default.removeItem(at: Paths.snapshot(for: accountID))
            accounts.removeAll { $0.id == accountID }
            usageByAccount[accountID] = nil
            usageProblemByAccount[accountID] = nil
            try saveIndex()
            status = "已移除 \(record.email)"
            recordActivity("已移除账号 \(record.email)")
        } catch {
            status = "删除失败：\(error.localizedDescription)"
            recordActivity(status ?? "删除账号失败", kind: .error)
        }
    }

    func record(for accountID: String) -> AccountRecord? {
        accounts.first { $0.id == accountID }
    }

    private func recordActivity(_ message: String, kind: ActivityLogEntry.Kind = .info) {
        guard activityLog.first?.message != message else { return }
        activityLog.insert(ActivityLogEntry(message: message, kind: kind), at: 0)
        if activityLog.count > 100 {
            activityLog.removeLast(activityLog.count - 100)
        }
    }

}
