import Foundation
import SwiftUI

struct ConfigurationDashboard: View {
    @ObservedObject var providerStore: ProviderListStore
    let onOpenProviders: (AppThemeFamily) -> Void
    let onNavigate: (ModuleKey) -> Void

    @StateObject private var store = ActiveConfigurationStore()

    private var codexProviders: [ProviderProfile] {
        providerStore.providers.filter { $0.family == AppThemeFamily.codex.rawValue }
    }

    private var claudeProviders: [ProviderProfile] {
        providerStore.providers.filter { $0.family == AppThemeFamily.claude.rawValue }
    }

    private var activeCodexProvider: ProviderProfile? {
        codexProviders.first(where: \.isActive)
    }

    private var activeClaudeProvider: ProviderProfile? {
        claudeProviders.first(where: \.isActive)
    }

    private var healthyConfigurationCount: Int {
        [store.codex, store.claude].count(where: \.isAvailable)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ModuleActionsBar(
                actions: [ModuleAction(title: "刷新", icon: "arrow.clockwise")],
                onAction: { _ in store.reload() }
            )

            HStack(alignment: .top, spacing: 18) {
                WorkspaceFamilyCard(
                    snapshot: store.codex,
                    activeProvider: activeCodexProvider,
                    providerCount: codexProviders.count,
                    onManage: { onOpenProviders(.codex) }
                )
                WorkspaceFamilyCard(
                    snapshot: store.claude,
                    activeProvider: activeClaudeProvider,
                    providerCount: claudeProviders.count,
                    onManage: { onOpenProviders(.claude) }
                )
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4),
                spacing: 14
            ) {
                DashboardStatusCard(
                    title: "提供商",
                    value: "\(providerStore.providers.count) 个",
                    detail: "\(providerStore.providers.count(where: \.isActive)) 个已激活",
                    icon: "shippingbox.fill",
                    tint: .blue
                )
                DashboardStatusCard(
                    title: "本机工具",
                    value: store.tools.summary,
                    detail: store.tools.detail,
                    icon: "terminal.fill",
                    tint: .purple
                )
                DashboardStatusCard(
                    title: "配置健康",
                    value: "\(healthyConfigurationCount)/2 正常",
                    detail: providerStore.errorMessage ?? store.configurationHealthDetail,
                    icon: healthyConfigurationCount == 2 ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                    tint: healthyConfigurationCount == 2 ? .green : .orange
                )
                DashboardRefreshCard(date: store.lastRefreshedAt)
            }

            DashboardQuickActions(onNavigate: onNavigate)
        }
    }
}

private struct WorkspaceFamilyCard: View {
    let snapshot: ActiveConfigurationSnapshot
    let activeProvider: ProviderProfile?
    let providerCount: Int
    let onManage: () -> Void

    private var tint: Color { snapshot.family.accentColor }

    private var healthTitle: String {
        if activeProvider == nil { return "待配置" }
        return snapshot.isAvailable ? "工作正常" : "需要检查"
    }

    private var healthColor: Color {
        isHealthy ? .green : .orange
    }

    private var isHealthy: Bool {
        activeProvider != nil && snapshot.isAvailable
    }

    private var endpoint: String {
        guard let activeProvider else { return "尚未选择端点" }
        return URLComponents(string: activeProvider.normalizedBaseURL)?.host ?? activeProvider.normalizedBaseURL
    }

    var body: some View {
        NativeLiquidGlassCard(tint: tint, cornerRadius: 26) {
            VStack(alignment: .leading, spacing: 17) {
                HStack(spacing: 13) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(tint.opacity(0.16))
                        ProviderFamilyGlyph(family: snapshot.family, isSelected: false)
                    }
                    .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(snapshot.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.slate900)
                        Text("\(providerCount) 个提供商")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.slate600)
                    }

                    Spacer(minLength: 8)

                    Label(healthTitle, systemImage: isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(healthColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(healthColor.opacity(0.12), in: Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("当前提供商")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.slate600)
                    Text(activeProvider?.name ?? "尚未添加提供商")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.slate900)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    WorkspaceFact(label: "模型", value: snapshot.modelDisplay)
                    WorkspaceFact(label: "端点", value: endpoint)
                    WorkspaceFact(label: "配置", value: snapshot.isAvailable ? "可读取" : "读取失败")
                }

                HStack(spacing: 10) {
                    Text(snapshot.configurationPath)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.slate500)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    HeaderButton(
                        title: "管理提供商",
                        icon: "arrow.right.circle",
                        usesLiquidGlass: true,
                        action: onManage
                    )
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 282, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(snapshot.title) 工作环境")
    }
}

private struct WorkspaceFact: View {
    let label: String
    let value: String

    var body: some View {
        NativeLiquidGlassCard(cornerRadius: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.slate600)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.slate900)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DashboardStatusCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let tint: Color

    var body: some View {
        NativeLiquidGlassCard(tint: tint, cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                    Spacer()
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.slate600)
                }
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.slate600)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
            .padding(15)
        }
    }
}

private struct DashboardRefreshCard: View {
    let date: Date

    var body: some View {
        DashboardStatusCard(
            title: "最近刷新",
            value: date.formatted(date: .omitted, time: .shortened),
            detail: "本地状态已重新检查",
            icon: "clock.arrow.circlepath",
            tint: .cyan
        )
    }
}

private struct DashboardQuickActions: View {
    let onNavigate: (ModuleKey) -> Void

    var body: some View {
        NativeLiquidGlassCard(tint: .indigo, cornerRadius: 22) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("快捷操作")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.slate900)
                    Text("直接进入常用管理模块")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.slate600)
                }
                .frame(width: 170, alignment: .leading)

                Spacer(minLength: 8)

                HeaderButton(title: "提供商", icon: "shippingbox", usesLiquidGlass: true, action: { onNavigate(.providers) })
                HeaderButton(title: "MCP", icon: "point.3.connected.trianglepath.dotted", usesLiquidGlass: true, action: { onNavigate(.mcp) })
                HeaderButton(title: "技能", icon: "bolt.badge.clock", usesLiquidGlass: true, action: { onNavigate(.skills) })
                HeaderButton(title: "提示词", icon: "text.bubble", usesLiquidGlass: true, action: { onNavigate(.prompts) })
            }
            .padding(17)
        }
    }
}

private struct ActiveConfigurationItem: Identifiable {
    let label: String
    let value: String
    var id: String { label }
}

private struct ActiveConfigurationSnapshot {
    let title: String
    let family: AppThemeFamily
    let configurationPath: String
    let items: [ActiveConfigurationItem]
    let message: String
    let isAvailable: Bool

    var modelDisplay: String {
        guard let model = items.first(where: { $0.label == "模型" })?.value else { return "默认" }
        return model.hasPrefix("未配置") ? "默认" : model
    }
}

@MainActor
private final class ActiveConfigurationStore: ObservableObject {
    @Published private(set) var codex = ActiveConfigurationStore.emptyCodex
    @Published private(set) var claude = ActiveConfigurationStore.emptyClaude
    @Published private(set) var tools = LocalToolOverview.checking
    @Published private(set) var lastRefreshedAt = Date.now

    private let toolInspector = LocalToolInspector()
    private var toolRefreshTask: Task<Void, Never>?

    init() {
        reload()
    }

    deinit {
        toolRefreshTask?.cancel()
    }

    func reload() {
        codex = loadCodexConfiguration()
        claude = loadClaudeConfiguration()
        lastRefreshedAt = .now
        refreshTools()
    }

    var configurationHealthDetail: String {
        let failures = [codex, claude]
            .filter { !$0.isAvailable }
            .map { "\($0.title)：\($0.message)" }
        return failures.isEmpty
            ? "Codex 与 Claude 配置均可读取"
            : failures.joined(separator: "；")
    }

    private func refreshTools() {
        toolRefreshTask?.cancel()
        tools = .checking
        let inspector = toolInspector
        toolRefreshTask = Task { [weak self] in
            let tools = await inspector.inspect()
            guard !Task.isCancelled else { return }
            self?.tools = tools
        }
    }

    private func loadCodexConfiguration() -> ActiveConfigurationSnapshot {
        let path = "~/.codex/config.toml"
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/config.toml")

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let values = Self.parseTOML(content)
            let provider = values["model_provider"]
            let baseURL = provider.flatMap { values["model_providers.\($0).base_url"] }

            return ActiveConfigurationSnapshot(
                title: "Codex",
                family: .codex,
                configurationPath: path,
                items: Self.items([
                    ("模型", values["model"]),
                    ("模型提供商", provider),
                    ("基础地址", baseURL),
                    ("推理强度", values["model_reasoning_effort"]),
                    ("服务层级", values["service_tier"]),
                    ("人格", values["personality"]),
                    ("沙箱模式", values["sandbox_mode"])
                ]),
                message: "配置文件中没有可展示的生效字段",
                isAvailable: true
            )
        } catch {
            return Self.failureSnapshot(
                title: "Codex",
                family: .codex,
                path: path,
                error: error
            )
        }
    }

    private func loadClaudeConfiguration() -> ActiveConfigurationSnapshot {
        let path = "~/.claude/settings.json"
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")

        do {
            let data = try Data(contentsOf: url)
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ConfigurationReadError.invalidRoot
            }

            let environment = root["env"] as? [String: Any] ?? [:]
            return ActiveConfigurationSnapshot(
                title: "Claude",
                family: .claude,
                configurationPath: path,
                items: Self.claudeItems(root: root, environment: environment),
                message: "配置文件中没有可展示的生效字段",
                isAvailable: true
            )
        } catch {
            return Self.failureSnapshot(title: "Claude", family: .claude, path: path, error: error)
        }
    }

    private static func claudeItems(
        root: [String: Any],
        environment: [String: Any]
    ) -> [ActiveConfigurationItem] {
        [
            ActiveConfigurationItem(
                label: "模型",
                value: configuredValue(
                    string(root["model"]) ?? string(environment["ANTHROPIC_MODEL"])
                )
            ),
            ActiveConfigurationItem(
                label: "推理强度",
                value: configuredValue(
                    string(root["effortLevel"]) ?? string(environment["CLAUDE_CODE_EFFORT_LEVEL"])
                )
            ),
            ActiveConfigurationItem(
                label: "服务层级",
                value: configuredValue(
                    string(root["serviceTier"]) ?? string(environment["ANTHROPIC_SERVICE_TIER"])
                )
            ),
            ActiveConfigurationItem(
                label: "人格",
                value: configuredValue(string(root["outputStyle"]))
            ),
            ActiveConfigurationItem(
                label: "沙箱模式",
                value: configuredValue(sandboxDescription(root["sandbox"]))
            )
        ]
    }

    private static func configuredValue(_ value: String?) -> String {
        value ?? "未配置（使用默认值）"
    }

    private static func sandboxDescription(_ value: Any?) -> String? {
        if let enabled = bool(value) {
            return enabled ? "启用" : "停用"
        }
        guard let sandbox = value as? [String: Any] else { return nil }
        if let enabled = bool(sandbox["enabled"]) {
            return enabled ? "启用" : "停用"
        }
        return sandbox.isEmpty ? nil : "已配置"
    }

    private static func bool(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return nil
    }

    private static func parseTOML(_ content: String) -> [String: String] {
        var section = ""
        var values: [String: String] = [:]

        for rawLine in content.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }

            if line.hasPrefix("["), line.hasSuffix("]") {
                section = String(line.dropFirst().dropLast())
                continue
            }

            guard let separator = line.firstIndex(of: "=") else { continue }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            let rawValue = line[line.index(after: separator)...]
                .trimmingCharacters(in: .whitespaces)
            let value = Self.unquote(rawValue)
            values[section.isEmpty ? key : "\(section).\(key)"] = value
        }

        return values
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
            (value.hasPrefix("'") && value.hasSuffix("'")) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }

    private static func string(_ value: Any?) -> String? {
        switch value {
        case let value as String where !value.isEmpty:
            value
        case let value as NSNumber:
            value.stringValue
        default:
            nil
        }
    }

    private static func items(_ candidates: [(String, String?)]) -> [ActiveConfigurationItem] {
        candidates.compactMap { label, value in
            guard let value, !value.isEmpty else { return nil }
            return ActiveConfigurationItem(label: label, value: value)
        }
    }

    private static func failureSnapshot(
        title: String,
        family: AppThemeFamily,
        path: String,
        error: Error
    ) -> ActiveConfigurationSnapshot {
        ActiveConfigurationSnapshot(
            title: title,
            family: family,
            configurationPath: path,
            items: [],
            message: "读取失败：\(error.localizedDescription)",
            isAvailable: false
        )
    }

    private static let emptyCodex = ActiveConfigurationSnapshot(
        title: "Codex",
        family: .codex,
        configurationPath: "~/.codex/config.toml",
        items: [],
        message: "正在读取配置…",
        isAvailable: false
    )

    private static let emptyClaude = ActiveConfigurationSnapshot(
        title: "Claude",
        family: .claude,
        configurationPath: "~/.claude/settings.json",
        items: [],
        message: "正在读取配置…",
        isAvailable: false
    )
}

private struct LocalToolOverview: Sendable {
    let tools: [LocalToolSnapshot]
    let isChecking: Bool

    static let checking = LocalToolOverview(tools: [], isChecking: true)

    var summary: String {
        guard !isChecking else { return "检查中" }
        return "\(tools.count(where: \.isAvailable))/\(tools.count) 就绪"
    }

    var detail: String {
        guard !isChecking else { return "正在检查 Codex 与 Claude CLI" }
        return tools.map { tool in
            if let version = tool.version {
                return "\(tool.name) \(version)"
            }
            return "\(tool.name) 未找到"
        }.joined(separator: " · ")
    }
}

private struct LocalToolSnapshot: Sendable {
    let name: String
    let version: String?

    var isAvailable: Bool { version != nil }
}

private actor LocalToolInspector {
    func inspect() -> LocalToolOverview {
        LocalToolOverview(
            tools: [
                inspect(name: "Codex", command: "codex"),
                inspect(name: "Claude", command: "claude")
            ],
            isChecking: false
        )
    }

    private func inspect(name: String, command: String) -> LocalToolSnapshot {
        guard let executableURL = executableURL(for: command) else {
            return LocalToolSnapshot(name: name, version: nil)
        }

        let process = Process()
        let output = Pipe()
        process.executableURL = executableURL
        process.arguments = ["--version"]
        process.standardOutput = output
        process.standardError = output

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                return LocalToolSnapshot(name: name, version: nil)
            }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            let version = String(data: data, encoding: .utf8)?
                .split(whereSeparator: \.isNewline)
                .first
                .map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return LocalToolSnapshot(name: name, version: version?.isEmpty == false ? version : nil)
        } catch {
            return LocalToolSnapshot(name: name, version: nil)
        }
    }

    private func executableURL(for command: String) -> URL? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let nvmVersionsDirectory = home.appendingPathComponent(".nvm/versions/node", isDirectory: true)
        let nvmDirectories = (try? fileManager.contentsOfDirectory(
            at: nvmVersionsDirectory,
            includingPropertiesForKeys: nil
        ))?
            .sorted {
                $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedDescending
            }
            .map { $0.appendingPathComponent("bin", isDirectory: true) } ?? []
        let fixedDirectories = [
            home.appendingPathComponent(".local/bin", isDirectory: true),
            home.appendingPathComponent(".volta/bin", isDirectory: true),
            home.appendingPathComponent(".bun/bin", isDirectory: true),
            home.appendingPathComponent(".asdf/shims", isDirectory: true),
            home.appendingPathComponent("bin", isDirectory: true),
            URL(fileURLWithPath: "/opt/homebrew/bin", isDirectory: true),
            URL(fileURLWithPath: "/usr/local/bin", isDirectory: true),
            URL(fileURLWithPath: "/usr/bin", isDirectory: true)
        ]
        let environmentDirectories = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map { URL(fileURLWithPath: String($0), isDirectory: true) }

        for directory in fixedDirectories + nvmDirectories + environmentDirectories {
            let candidate = directory.appendingPathComponent(command, isDirectory: false)
            if fileManager.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}

private enum ConfigurationReadError: LocalizedError {
    case invalidRoot

    var errorDescription: String? {
        switch self {
        case .invalidRoot:
            "配置文件根节点不是对象"
        }
    }
}
